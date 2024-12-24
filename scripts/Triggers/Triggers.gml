global.triggered_index = -1;

/**
 * 设置绑定的触发器。
 * 可以是单个触发器配置或多个触发器配置的数组，其中数组表示触发器顺序执行。
 * @param {Struct} options
 */
function set_trigger(options) {
    trigger = _resolve_trigger_options(options);
}

function _resolve_trigger_options(options) {
    if (is_array(options)) {
        var n = array_length(options);
        var triggers = array_create(n);
        for (var i = 0; i < n; i++) {
            triggers[i] = _resolve_trigger_options(options[i]);
        }
        return new TriggerSequence(triggers);
    } else {
        options.target = self;
        var konstructor = options.trigger;
        var delay = options[$ "delay"];
        var trigger = new konstructor(options);
        if (delay != undefined) {
            trigger = new TriggerDelay(trigger, delay);
        }
        return trigger;
    }
}

enum TriggerState {
    Inactive,
    Pending,
    Running,
    Finished,
}

/**
 * 触发器类。
 * @param {Struct} [options] 触发器配置，具体配置由具体继承的子类决定，其中固定有：
 *   - index（可选）：触发编号，当 global.triggered_index >= index 时触发，默认值为 -1，将无条件触发；
 *   - target：受控实例。
 */
function Trigger(options = {}) constructor {
    _index = options[$ "index"] ?? -1;
    target = options.target;
    _state = TriggerState.Inactive;
    
    /**
     * 触发器编号。
     * @returns {Real}
     */
    static index = function() {
        return _index;
    };
    
    /**
     * 触发器状态。
     * @returns {Enum.TriggerState}
     */
    static state = function() {
        return _state;
    };
    
    static on_start = nop;
    static on_update = nop;
    
    static update = function() {
        if (_state == TriggerState.Inactive) {
            if (_index < 0 || global.triggered_index >= _index) {
                on_start();
                _state = TriggerState.Running;
            }
        }
        if (_state == TriggerState.Running) {
            on_update();
        }
    };
    
    static finish = function() {
        _state = TriggerState.Finished;
    }
}

/**
 * 顺序触发器序列。
 * @param {Array<Struct.Trigger>} triggers
 */
function TriggerSequence(triggers) constructor {
    _triggers = triggers;
    _idx = 0;  // Array index of triggers.
    
    static index = function() {
        var n = array_length(_triggers);
        if (_idx < n) {
            return _triggers[_idx].index();
        }
        return -1;
    };
    
    static state = function() {
        var n = array_length(_triggers);
        if (_idx >= n) {
            return TriggerState.Finished;
        }
        var substate = _triggers[_idx].state();
        if (substate == TriggerState.Inactive) {
            return _idx == 0 ? TriggerState.Inactive : TriggerState.Pending;
        }
        if (substate == TriggerState.Finished) {
            return TriggerState.Pending;
        }
        return substate;
    };
    
    static update = function() {
        var n = array_length(_triggers);
        if (_idx >= n) {
            return
        }
        var trigger = _triggers[_idx];
        trigger.update();
        if (trigger.state() == TriggerState.Finished) {
            _idx++;
        }
    }
}

/**
 * 延迟触发器。
 * @param {Struct.Trigger} trigger 要延迟的触发器。
 * @param {Real} delay 延迟时间（秒）。
 */
function TriggerDelay(trigger, delay) constructor {
    _trigger = trigger;
    _delay = delay;
    _started = false;
    _pending = false;
    
    static index = function() {
        return _trigger.index();
    };
    
    static state = function() {
        if (_pending) {
            return TriggerState.Pending;
        }
        return _trigger.state();
    };
    
    static update = function() {
        if (!_started) {
            var idx = index();
            if (idx < 0 || global.triggered_index >= idx) {
                _pending = true;
                _started = true;
                call_later(_delay, time_source_units_seconds, function() {
                    _pending = false;
                });
            }
        } else if (!_pending) {
            _trigger.update();
        }
    };
}

/**
 * 平移触发器。
 * @param {Struct} options 触发器配置。除了公用配置，还包括：
 *   - disp：位移；
 *   - duration：完成位移的时间（秒）；
 *   - reverse（可选）：完成位移后是否反转路径，默认否；
 *   - loop（可选）：完成位移后是否回到开始状态重新执行，默认否。与 reverse 配合使用可无限循环；
 *   - easing（可选）：缓动函数，默认为恒等函数。
 */
function TriggerTranslate(options) : Trigger(options) constructor {
    disp = options.disp;
    duration = options.duration;
    reverse = options[$ "reverse"] ?? false;
    loop = options[$ "loop"] ?? false;
    easing = options[$ "easing"] ?? (function(t) { return t; });
    timer = 0;
    
    static on_start = function() {
        start_x = target.x;
        start_y = target.y;
        end_x = start_x + disp.x;
        end_y = start_y + disp.y;
    };
    
    static on_update = function() {
        timer += delta_time / 1000000;
        var progress = clamp(timer / duration, 0, 1);
        var t = progress;
        if (reverse) {
            t = 1 - abs(2 * t - 1);
        }
        t = easing(t);
        var next_x = lerp(start_x, end_x, t);
        var next_y = lerp(start_y, end_y, t);
        target.move(next_x - target.x, next_y - target.y);
        if (progress == 1) {
            if (loop) {
                timer = 0;
            } else {
                finish();
            }
        }
    }
}
