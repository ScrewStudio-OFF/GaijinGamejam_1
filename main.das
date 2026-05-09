require engine.core

[export]
def on_initialize() {

    // Спавним игрока и сохраняем NodeId
    let player_prefab = request_prefab("Project/Core/Player/P_Player.prefab")
    let player = instantiate_prefab(player_prefab, NodeData(
        name = "Player",
        position = float3(0.0, 1.0, 0.0)
    ))

    // Спавним камеру
    let cam_prefab = request_prefab("Project/Core/Player/P_FollowCamera.prefab")
    let cam = instantiate_prefab(cam_prefab, NodeData(
        name = "MainCamera",
        position = player.localPosition + float3(0.0, 20, -5)
    ))

    // Получаем компонент SCameraFollow и передаём ссылку на игрока
    get_component(cam) $(var follow : SCameraFollow?) {
        if (follow != null) {
            follow.target = player
            follow.offset = float3(0.0, 15, -7.5)
        }
    }

    // NEW: Найти Camera на дочерней ноде и передать её в S_Player
    var inscope cam_children = cam.get_children()
    for (cam_node in cam_children) {
        get_component(cam_node) $(var camera : Camera?) {
            if (camera != null) {
                get_component(player) $(var splayer : SPlayer?) {
                    if (splayer != null) {
                        splayer.camera = camera
                        
                    }
                }
            }
        }
        break
    }
}