event_inherited();
collision_tag = CollisionTag.Block;

// 砖块移动时会与具有 Box 标签的实例有两种交互。
// 位于砖块上方的物体会被带动（drive），以此模仿摩擦力。
// 砖块移动后若与其他实例重叠，会推动（push）它。

/**
 * 当砖块沿着全局位移 (dx, dy) 移动时，获取所有要被带动的实例。
 * 该函数应当在实际移动前调用。
 * @param {Real} dx
 * @param {Real} dy
 * @returns {Array}
 */
get_drivables = function(dx, dy) {
    // 由于每个实例可能有不同的重力方向，
    // 需要获取周围的实例后逐个判断其是否位于砖块上方。
    var list = ds_list_create();
    var n = collision_rectangle_list(
        bbox_left - 1, bbox_top - 1, bbox_right + 1, bbox_bottom + 1,
        obj_entity, true, true, list, false
    );
    var drivables = [];
    for (var i = 0; i < n; i++) {
        var inst = list[| i];
        if (!instance_satisfies_collision_tag(self, inst, CollisionTag.Box)) {
            continue;
        }
        if (!probe(dx, dy, inst) && inst.probe(0, 1, self, true)) {
            array_push(drivables, inst);
        }
    }
    return drivables;
};

/**
 * 当砖块沿着全局位移 (dx, dy) 移动时，获取所有要被推动的实例。
 * 该函数应当在实际移动前调用。
 * @param {Real} dx
 * @param {Real} dy
 * @returns {Array}
 */
get_pushables = function(dx, dy) {
    return get_probed(dx, dy, CollisionTag.Box);
};

/**
 * 当砖块沿着全局位移 (dx, dy) 移动时，带动相应的实例。
 * 该函数应当在实际移动后调用。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Id.Instance} inst
 */
drive = function(dx, dy, inst) {
    // TODO: 防止多个砖块在同一方向上叠加位移。
    // 多移动一点防止误差导致 Box 腾空。
    var down = (is_callable(inst.local_down) ? inst.local_down() : inst.local_down);
    inst.move(dx + down.x, dy + down.y);
};

/**
 * 当砖块沿着全局位移 (dx, dy) 移动时，推动相应的实例。
 * 该函数应当在实际移动后调用。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Id.Instance} inst
 */
push = function(dx, dy, inst) {
    // 我们暂时只考虑推动 player 一个实例，因此不处理多个 Box 级联推动的情形。
    
    var dist = point_distance(0, 0, dx, dy);
    if (dist == 0) {
        return;
    }
    var ux = dx / dist;
    var uy = dy / dist;
    // 将 Box 移出自身范围。
    while (inst.collide_at(inst.x, inst.y, self)) {
        instance_deactivate_object(self);
        var x0 = inst.x, y0 = inst.y;
        inst.move(inst.collision_gap * ux, inst.collision_gap * uy);
        instance_activate_object(self);
        if (inst.x == x0 && inst.y == y0) {
            // 推动被阻挡。
            break;
        }
    }
};

move = function(dx, dy) {
    if (dx == 0 && dy == 0) {
        return 0;
    }
    var drivables = get_drivables(dx, dy);
    var pushables = get_pushables(dx, dy);
    x += dx;
    y += dy;
    var n = array_length(drivables);
    for (var i = 0; i < n; i++) {
        drive(dx, dy, drivables[i]);
    }
    n = array_length(pushables);
    for (var i = 0; i < n; i++) {
        push(dx, dy, pushables[i]);
    }
    return 0;
};
