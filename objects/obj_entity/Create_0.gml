// 所有需要移动和碰撞交互的物体的根父对象。

/**
 * 局部坐标系的正下方向向量。
 * 取值可为向量或函数，对于后者，将实时的返回值作为方向向量。
 */
local_down = function() { return global.down_direction; };
/**
 * 长距离移动中，移动会被拆分为若干小段位移，每段的长度不超过该变量值（像素）。
 * 默认为 bbox 的宽高中最小值的一半。
 */
substep = max(1, min((bbox_right - bbox_left) / 2, (bbox_bottom - bbox_top) / 2));
/**
 * 当移动遇到障碍物阻碍时，该变量控制物体与障碍物之间的最大间隙（像素）。
 */
collision_gap = 0.5;
/**
 * 碰撞标签。
 */
collision_tag = CollisionTag.None;
/**
 * 绑定的触发器。
 */
trigger = { update: nop };
/**
 * 重力加速度（像素/秒²）。
 */
grav = 0;
/**
 * 局部坐标系下的速度（像素/秒）。
 */
velocity = new Vec2(0, 0);

/**
 * 将局部向量转换为全局向量。
 * @param {Real} x
 * @param {Real} y
 * @returns {Struct.Vec2}
 */
local_vec_to_global = function(x, y) {
    var down = is_callable(local_down) ? local_down() : local_down;
    return new Vec2(
        dot_product(down.y, down.x, x, y),
        dot_product(-down.x, down.y, x, y)
    );
};


/**
 * 将全局向量转换为局部向量。
 * @param {Real} x
 * @param {Real} y
 * @returns {Struct.Vec2}
 */
global_vec_to_local = function(x, y) {
    var down = is_callable(local_down) ? local_down() : local_down;
    return new Vec2(
        dot_product(down.y, -down.x, x, y),
        dot_product(down.x, down.y, x, y)
    );
};

/**
 * 假设自身位于全局坐标 (x, y) 处，检测是否与给定实例或具有给定碰撞标签的实例碰撞。
 * @param {Real} x
 * @param {Real} y
 * @param {Id.Instance, Enum.CollisionTag, Array} target 要检测的实例或者碰撞标签。
 * @returns {Bool}
 */
collide_at = function(x, y, target) {
    /**
     * 检测实例。
     * @param {Real} x
     * @param {Real} y
     * @param {Id.Instance, Array} obj
     * @returns {Bool}
     */
    static obj_impl = function(x, y, obj) {
        return place_meeting(x, y, obj);
    };
    
    /**
     * 检测标签。
     * @param {Real} x
     * @param {Real} y
     * @param {Enum.CollisionTag} tag
     * @returns {Bool}
     */
    static tag_impl = function(x, y, tag) {
        var list = ds_list_create();
        var n = instance_place_list(x, y, obj_entity, list, false);
        var has_collided = false;
        for (var i = 0; i < n; i++) {
            var inst = list[| i];
            if (instance_satisfies_collision_tag(self, inst, tag)) {
                has_collided = true;
                break;
            }
        }
        ds_list_destroy(list);
        return has_collided;
    };
    
    // 枚举值都是 int64。
    if (is_int64(target)) {
        return tag_impl(x, y, target);
    } else {
        return obj_impl(x, y, target);
    }
};

/**
 * 假设自身位于全局坐标 (x, y) 处，获取碰撞到的给定实例或具有给定碰撞标签的实例。
 * @param {Real} x
 * @param {Real} y
 * @param {Id.Instance, Enum.CollisionTag, Array} target 要检测的实例或者碰撞标签。
 * @param {Bool} [ordered] 是否按照距离远近排序获取到的实例，默认不排序。
 * @returns {Array}
 */
get_collided = function(x, y, target, ordered = false) {
    /**
     * 检测实例。
     * @param {Real} x
     * @param {Real} y
     * @param {Id.Instance, Array} obj
     * @param {Bool} ordered
     * @returns {Bool}
     */
    static obj_impl = function(x, y, obj, ordered) {
        var list = ds_list_create();
        var n = instance_place_list(x, y, obj, list, ordered);
        var collided_insts = array_create(n);
        for (var i = 0; i < n; i++) {
            collided_insts[i] = list[| i];
        }
        ds_list_destroy(list);
        return collided_insts;
    };
    
    /**
     * 检测标签。
     * @param {Real} x
     * @param {Real} y
     * @param {Enum.CollisionTag} tag
     * @param {Bool} ordered
     * @returns {Bool}
     */
    static tag_impl = function(x, y, tag, ordered) {
        var list = ds_list_create();
        var n = instance_place_list(x, y, obj_entity, list, ordered);
        var collided_insts = [];
        for (var i = 0; i < n; i++) {
            var inst = list[| i];
            if (instance_satisfies_collision_tag(self, inst, tag)) {
                array_push(collided_insts, inst);
            }
        }
        ds_list_destroy(list);
        return collided_insts;
    };
    
    // 枚举值都是 int64。
    if (is_int64(target)) {
        return tag_impl(x, y, target, ordered);
    } else {
        return obj_impl(x, y, target, ordered);
    }
}

/**
 * 假设自身沿着位移 (dx, dy) 移动，检测是否与给定实例或具有给定碰撞标签的实例碰撞。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Id.Instance, Enum.CollisionTag, Array} target 要检测的实例或者碰撞标签。
 * @param {Bool} [local] 位移 (dx, dy) 是否是局部坐标，默认为全局坐标。
 * @returns {Bool}
 */
probe = function(dx, dy, target, local = false) {
    // 若当前位置已经碰撞，直接返回。
    if (collide_at(x, y, target)) {
        return true;
    }
    
    // 对于局部坐标输入，将 (dx, dy) 转换为全局坐标。
    if (local) {
        var disp_global = local_vec_to_global(dx, dy);
        dx = disp_global.x;
        dy = disp_global.y;
    }
    
    var dist = point_distance(0, 0, dx, dy);
    if (dist == 0) {
        return false;
    }
    
    // 移动方向向量。
    var ux = dx / dist;
    var uy = dy / dist;
    // 虚拟的实例位置。
    var probe_x = x;
    var probe_y = y;
    while (dist > 0) {
        var step = min(substep, dist);
        probe_x += step * ux;
        probe_y += step * uy;
        if (collide_at(probe_x, probe_y, target)) {
            return true;
        }
        dist -= step;
    }
    return false;
};

/**
 * 假设自身沿着位移 (dx, dy) 移动，获取沿途碰撞到的给定实例或具有给定碰撞标签的实例。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Id.Instance, Enum.CollisionTag, Array} target 要检测的实例或者碰撞标签。
 * @param {Bool} [local] 位移 (dx, dy) 是否是局部坐标，默认为全局坐标。
 * @param {Bool} [ordered] 是否按照距离远近排序获取到的实例，默认不排序。
 * @returns {Bool}
 */
get_probed = function(dx, dy, target, local = false, ordered = false) {
    // 对于局部坐标输入，将 (dx, dy) 转换为全局坐标。
    if (local) {
        var disp_global = local_vec_to_global(dx, dy);
        dx = disp_global.x;
        dy = disp_global.y;
    }
    
    var probed_insts = get_collided(x, y, target, ordered);
    
    var dist = point_distance(0, 0, dx, dy);
    if (dist == 0) {
        return probed_insts;
    }
    
    // 为防止重复检测，已经检测过的实例要被禁用。
    array_foreach(probed_insts, instance_deactivate_object);
    
    // 移动方向向量。
    var ux = dx / dist;
    var uy = dy / dist;
    // 虚拟的实例位置。
    var probe_x = x;
    var probe_y = y;
    while (dist > 0) {
        var step = min(substep, dist);
        probe_x += step * ux;
        probe_y += step * uy;
        var insts = get_collided(probe_x, probe_y, target, ordered);
        var n = array_length(insts);
        for (var i = 0; i < n; i++) {
            array_push(probed_insts, insts[i]);
            instance_deactivate_object(insts[i]);
        }
        dist -= step;
    }
    
    array_foreach(probed_insts, instance_activate_object);
    return probed_insts;
};

/**
 * 沿着给定位移 (dx, dy) 移动，返回移动是否被障碍物阻碍。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Bool} [local] 位移 (dx, dy) 是否是局部坐标，默认为全局坐标。
 * @param {Id.Instance, Enum.CollisionTag, Array} obstacle 障碍物的实例或者碰撞标签，默认为 CollisionTag.Obstacle。
 * @returns {Bool}
 */
translate = function(dx, dy, local = false, obstacle = CollisionTag.Obstacle) {
    // 对于局部坐标输入，将 (dx, dy) 转换为全局坐标。
    if (local) {
        var disp_global = local_vec_to_global(dx, dy);
        dx = disp_global.x;
        dy = disp_global.y;
    }
    
    if (collide_at(x, y, obstacle)) {
        return true;
    }
    
    var dist = point_distance(0, 0, dx, dy);
    if (dist == 0) {
        return false;
    }
    
    // 移动方向向量。
    var ux = dx / dist;
    var uy = dy / dist;
    var has_collided = false;
    while (dist > 0) {
        var step = min(substep, dist);
        var probe_x = x + step * ux;
        var probe_y = y + step * uy;
        if (collide_at(probe_x, probe_y, obstacle)) {
            has_collided = true;
            break;
        }
        x = probe_x;
        y = probe_y;
        dist -= step;
    }
    
    // 若移动被阻碍，则每次以一半的距离贴近障碍物。 
    if (has_collided) {
        var step = dist / 2;
        while (step > collision_gap) {
            var probe_x = x + step * ux;
            var probe_y = y + step * uy;
            if (!collide_at(probe_x, probe_y, obstacle)) {
                x = probe_x;
                y = probe_y;
            }
            step /= 2;
        }
    }
    
    return has_collided;
};

/**
 * 沿着给定位移 (dx, dy) 移动。
 * 若移动被障碍物阻拦，则将剩余位移在局部坐标系下沿着 x 和 y 轴分解，
 * 并分别移动剩下的距离。
 * 返回 2-bit 掩码，低位为 1 表示局部 x 轴上遭遇阻碍，高位为 1 表示局部 y 轴上遭遇阻碍。
 * @param {Real} dx
 * @param {Real} dy
 * @param {Bool} [local] 位移 (dx, dy) 是否是局部坐标，默认为全局坐标。
 * @param {Id.Instance, Enum.CollisionTag, Array} obstacle 障碍物的实例或者碰撞标签，默认为 CollisionTag.Obstacle。
 * @returns {Real}
 */
translate_orthogonal = function(dx, dy, local = false, obstacle = CollisionTag.Obstacle) {
    var x0 = x, y0 = y;
    if (!translate(dx, dy, local, obstacle)) {
        return int64(0);
    }
    
    // 将剩余位移分解到局部坐标系上。
    var local_disp = global_vec_to_local(dx - (x - x0), dy - (y - y0));
    var mask_x = int64(translate(local_disp.x, 0, true, obstacle));
    var mask_y = int64(translate(0, local_disp.y, true, obstacle));
    return (mask_y << 1) | mask_x;
};

/**
 * 在地面上移动，并考虑斜坡。返回移动是否被阻碍。
 * 调用前必须保证实例已经位于障碍物的正上方。
 * @param {Real} local_dx 局部 x 轴上的位移。
 * @param {Id.Instance, Enum.CollisionTag, Array} obstacle 障碍物的实例或者碰撞标签，默认为 CollisionTag.Obstacle。
 * @returns {Bool}
 */
_move_on_slope = function(local_dx, obstacle = CollisionTag.Obstacle) {
    if (local_dx == 0) {
        return collide_at(x, y, obstacle);
    }
    
    var xdir = sign(local_dx);
    var dist = abs(local_dx);
    var disp = local_vec_to_global(local_dx, 0);
    var udisp = disp.normalize();
    
    static _move_without_probe = function(xdir, disp, obstacle) {
        var floor_snap = disp.magnitude() * 2;  // 抓地距离。
        var prev_down_disp = disp;
        var prev_up_collision = probe(disp.x, disp.y, obstacle);
        var prev_down_collision = prev_up_collision;
    
        for (var angle = 3; angle < 90; angle += 3) {
            var up_disp = disp.rotate(xdir * angle);
            var down_disp = disp.rotate(-xdir * angle);
            var up_collision = probe(up_disp.x, up_disp.y, obstacle);
            var down_collision = probe(down_disp.x, down_disp.y, obstacle);
            
            // 下坡。
            if (down_collision && !prev_down_collision) {
                var x0 = x, y0 = y;
                x += prev_down_disp.x;
                y += prev_down_disp.y;
                // 虽然下坡的位置未被阻碍，但可能下方是悬崖，此时不应当做下坡处理。
                if (translate(0, floor_snap, true, obstacle)) {
                    return;
                }
                x = x0;
                y = y0;
            }
        
            // 上坡。
            if (!up_collision && prev_up_collision) {
                x += up_disp.x;
                y += up_disp.y;
                translate(0, floor_snap, true, obstacle);
                return;
            }
        
            prev_down_disp = down_disp;
            prev_up_collision = up_collision;
            prev_down_collision = down_collision;
        }
        
        translate(disp.x, disp.y, false, obstacle);
    };
    
    while (dist > 0) {
        var step = min(substep, dist);
        var x0 = x, y0 = y;
        _move_without_probe(xdir, udisp.smul(step), obstacle);
        if (x == x0 && y == y0) {
            // 无法上坡或下坡，尝试直接横向移动。
            return translate(xdir * dist, 0, true, obstacle);
        }
        dist -= step;
    }
    return false;
};

/**
 * 对玩家、箱子这类对象的默认移动实现。
 * 返回 2-bit 掩码，低位为 1 表示局部 x 轴上遭遇阻碍，高位为 1 表示局部 y 轴上遭遇阻碍。
 * @param {Real} dx 位移的全局 x 坐标。
 * @param {Real} dy 位移的全局 y 坐标。
 * @returns {Real}
 */
box_move = function(dx, dy) {
    if (dx == 0 && dy == 0) {
        return 0;
    }
    
    var local_disp = global_vec_to_local(dx, dy);
    if (local_disp.y >= 0 && probe(0, 1, CollisionTag.Obstacle, true)) {
        // 地面移动。
        var mask_x = int64(_move_on_slope(local_disp.x));
        var mask_y = int64(local_disp.y > 0);
        return (mask_y << 1) | mask_x;
    } else {
        // 空中移动。
        return translate_orthogonal(dx, dy);
    }
};

/**
 * 每帧的移动行为，默认直接移动且不检测任何障碍物。
 * 返回 2-bit 掩码，低位为 1 表示局部 x 轴上遭遇阻碍，高位为 1 表示局部 y 轴上遭遇阻碍。
 * @param {Real} dx 位移的全局 x 坐标。
 * @param {Real} dy 位移的全局 y 坐标。
 * @returns {Real}
 */
move = function(dx, dy) {
    x += dx;
    y += dy;
    return 0;
};
