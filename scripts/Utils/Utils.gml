/** 空操作。*/
function nop() {}

/**
 * 碰撞标签。
 * 通常实体的 collision_tag 成员的取值为以下任意一者枚举。
 * 碰撞检测函数中可以接受以下任意枚举的按位或，并与实例的 collision_tag 做按位与是否为 0 判断检测结果。
 * 例如，当碰撞检测函数输入标签 CollisionTag.Block | CollisionTag.Platform 时，任何 Block 或 Platform 实例都会被检测。
 * 部分碰撞标签存在特殊检测逻辑，例如 Platform 需要在发起碰撞检测的实例的正下方。
 */
enum CollisionTag {
    None = 0,
    Block = 1,
    Platform = 2,
    Obstacle = 3,  // Block | Platform
    Killer = 4,
    Box = 8,
    Vine = 16,
}

/**
 * 检测实例 inst 在 master 眼中是否具有碰撞标签 tag。
 * @param {Id.Instance} master 检测的发起实例。
 * @param {Id.Instance} inst 待检测的实例。
 * @param {Enum.CollisionTag} tag 要检测的碰撞标签。
 * @returns {Bool}
 */
function instance_satisfies_collision_tag(master, inst, tag) {
    if (!object_is_ancestor(inst.object_index, obj_entity)) {
        return false;
    }
    var mask = tag & inst.collision_tag;
    if ((mask & CollisionTag.Platform) != 0) {
        if (master.collide_at(master.x, master.y, inst)) {
            mask &= ~CollisionTag.Platform;
        } else {
            // 如果 inst 在 master 正下方，则 master 至多移动以下距离会与 platform 碰撞。
            var dist = point_distance(
                min(master.bbox_left, inst.bbox_left),
                min(master.bbox_top, inst.bbox_top),
                max(master.bbox_right, inst.bbox_right),
                max(master.bbox_bottom, inst.bbox_bottom)
            );
            if (!master.probe(0, dist, inst, true)) {
                mask &= ~CollisionTag.Platform;
            }
        }
    }
    return mask != 0
}

/**
 * 播放音效。
 * @param {Asset.GMSound} sound
 * @returns {Id.Sound}
 */
function play_sound(sound) {
    return audio_play_sound(sound, 0, false, global.sound_volume);
}

/**
 * @param {String} error_message
 */
function panic(error_message) {
    show_error(error_message, false);
}
