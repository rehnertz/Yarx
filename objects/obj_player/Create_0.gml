event_inherited();
collision_tag = CollisionTag.Box;
/** 移动速度（像素/秒）。*/
move_speed = 150;
/** 最大下落速度（像素/秒）。*/
max_fall_speed = 450;
/** 重力加速度（像素/秒²）。*/
grav = 1000;
/** 各级跳跃初速度（像素/秒）。*/
jumps = [425, 350];
/** 藤蔓下落速度（像素/秒）。*/
slide_fall_speed = 100;
/** 藤蔓跳跃初速度（像素/秒）。*/
slide_jump_x = 750
slide_jump_y = 450;

skin = {
    idle: spr_player_idle,
    run: spr_player_run,
    jump: spr_player_jump,
    fall: spr_player_fall,
    slide: spr_player_slide,
};

/** 当前跳跃级别。*/
jump_level = 1;
/** 横向朝向。*/
face = 1;

move = box_move;

/** 跳跃。*/
jump = function() {
    var n = array_length(jumps);
    if (jump_level < n) {
        play_sound(jump_level == 0 ? snd_jump : snd_double_jump);
        velocity.y = -jumps[jump_level++];
    }
};

/** 射击。*/
shoot = function() {
    if (instance_number(obj_bullet) < 4) {
        var bullet = instance_create_depth(x, y, depth, obj_bullet);
        bullet.local_down = local_down;
        bullet.velocity.x = face * 800;
        play_sound(snd_shoot);
        call_later(0.8, time_source_units_seconds, method(bullet, instance_destroy));
    }
};

/** 死亡。*/
die = function() {
    /** 生成一次血迹。*/
    var generate_blood = function() {
        repeat (40) {
            var blood = instance_create_depth(x, y, depth, obj_blood);
            blood.local_down = local_down;
            blood.grav = random_range(100, 300);
            var spd = random_range(100, 300);
            var dir = random(360);
            blood.velocity.x = lengthdir_x(spd, dir);
            blood.velocity.y = lengthdir_y(spd, dir);
        }
    };
    
    generate_blood();
    // 每 0.02 秒生成一次血迹，0.4 秒后停止。
    var ts = call_later(0.02, time_source_units_seconds, generate_blood, true);
    call_later(0.4, time_source_units_seconds, method({ ts }, function() {
        call_cancel(ts);
    }));
    
    play_sound(snd_death);
    instance_destroy();
};
