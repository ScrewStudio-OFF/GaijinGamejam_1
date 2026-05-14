require engine.core
require engine.math.math_utils


class SCameraFollow : Component {
    @export target : NodeId = NodeId()
    @export offset : float3 = float3(0.0, 10.0, -5.0)
    @export follow_halflife : float = 0.15
    @export rotation_halflife : float = 0.08
    @export rotateSensitivity : float = 0.01
    @export yaw : float = 0.0
    @export rotateWithRightMouse : bool = true
    @export enableWheelHeight : bool = true
    @export wheelHeightSensitivity : float = 0.6
    @export minCameraHeight : float = 8.0
    @export maxCameraHeight : float = 14.0

    @no_export targetYaw : float = 0.0

    def override on_initialize() : void {
        targetYaw = yaw
        offset.y = clamp(offset.y, minCameraHeight, maxCameraHeight)
        self->init_camera_input()
    }

    def override on_update() : void {
        if (!target.isAlive) {
            return
        }

        let dt = get_delta_time()

        if (rotateWithRightMouse && is_action_pressed("cameraRotate")) {
            let mouseDelta = get_action_vector2("cameraLook")
            targetYaw = targetYaw + mouseDelta.x * rotateSensitivity
        }

        yaw = approach(yaw, targetYaw, dt, rotation_halflife)

        if (enableWheelHeight) {
            let wheelAxis = get_action_axis("cameraZoom")
            if (abs(wheelAxis) > 0.0001) {
                offset.y = clamp(offset.y - wheelAxis * wheelHeightSensitivity, minCameraHeight, maxCameraHeight)
            }
        }

        let yawRotation = quat4(0.0, yaw, 0.0)
        let desiredPos = target.localPosition + yawRotation * offset
        let currentPos = nodeId.localPosition
        let newPos = approach(currentPos, desiredPos, dt, follow_halflife)

        nodeId.localPosition = newPos
        nodeId.localRotation = yawRotation
    }

    def override on_destroy() : void {
        pass
    }

    def private init_camera_input() : void {
        if (has_action_set("followCameraInput")) {
            activate_action_set("followCameraInput", true)
            return
        }

        add_and_activate_action_set("followCameraInput", {
            "cameraLook" => Action(
                pointerActions = PointerAction(
                    valueType = ValueType.Delta,
                    mouse = MouseInput(active = true)
                )
            ),
            "cameraRotate" => Action(
                buttonActions = ButtonAction(
                    mouseButtons = [MouseButtonInput(idx = MouseButton.Right)]
                )
            ),
            "cameraZoom" => Action(
                axisActions = AxisAction(
                    mouseAxis = [
                        MouseBtnAxisInput(
                            positiveIdx = MouseButton.WheelUp,
                            negativeIdx = MouseButton.WheelDown,
                            sensitivity = 1.0
                        )
                    ]
                )
            )
        })
    }
}
