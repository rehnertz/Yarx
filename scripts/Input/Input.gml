enum InputType {
    Down,        // keyboard_check
    DirectDown,  // keyboard_check_direct
    Pressed,     // keyboard_check_pressed
    Released,    // keyboard_check_released
}

global.input = {
    // 是否响应输入。
    enabled: false,
    // 是否反转输入，仅对设置了 reverse 的输入动作有效。
    reversed: false,
    // 输入映射。
    mapping: {
        move_left: {
            key: vk_left,
            type: InputType.DirectDown,
            reverse: "move_right",
        },
        move_right: {
            key: vk_right,
            type: InputType.DirectDown,
            reverse: "move_left",
        },
        jump: {
            key: vk_shift,
            type: InputType.Pressed,
        },
        shoot: {
            key: ord("Z"),
            type: InputType.Pressed,
        },
        suicide: {
            key: ord("Q"),
            type: InputType.Pressed,
        },
    },
};

/**
 * 检车输入动作是否触发。
 * @param {String} action 输入动作名。
 * @param {Enum.InputType} [type] 输入动作类型，若未提供则使用映射中的默认类型。
 * @returns {Bool}
 */
function input_check(action, type = undefined) {
    /**
     * @param {Constant.VirtualKey, Real} key
     * @param {Enum.InputType} type
     * @returns {Bool}
     */
    static check = function(key, type) {
        switch (type) {
            case InputType.Down:
                return keyboard_check(key);
            case InputType.DirectDown:
                return keyboard_check_direct(key);
            case InputType.Pressed:
                return keyboard_check_pressed(key);
            case InputType.Released:
                return keyboard_check_released(key);
            default:
                panic($"Unkown input type {type}.");
        }
    };
    
    var mapping = global.input.mapping[$ action];
    if (global.input.reversed && struct_exists(mapping, "reverse")) {
        mapping = global.input.mapping[$ mapping.reverse];
    }
    
    if (!is_array(mapping.key)) {
        return check(mapping.key, type ?? mapping.type);
    }
    
    var keys = mapping.key;
    var n = array_length(keys);
    for (var i = 0; i < n; i++) {
        if (check(keys[i], type ?? mapping.type)) {
            return true;
        }
    }
    return false;
}
