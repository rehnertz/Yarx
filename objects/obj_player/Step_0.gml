if (input_check("suicide")) {
    die();
}

if (collide_at(x, y, CollisionTag.Obstacle)) {
    die();
}

var move_left = input_check("move_left");
var move_right = input_check("move_right");
var xdir = real(move_right) - real(move_left);

var vine_left = probe(-1, 0, CollisionTag.Vine, true) && move_left;
var vine_right = probe(1, 0, CollisionTag.Vine, true) && move_right;

if (vine_left || vine_right) {
    #region Vine.
    var jump_action;
    if (vine_left) {
        jump_action = "move_right";
        face = 1;
    } else {
        jump_action = "move_left";
        face = -1;
    }
    velocity.y = slide_fall_speed;
    
    if (input_check("shoot")) {
        shoot();
    }
    
    if (input_check(jump_action, InputType.Pressed)) {
        play_sound(snd_vine_jump);
        velocity.x = face * slide_jump_x;
        velocity.y = -slide_jump_y;
        face = -face;
        sprite_index = skin.jump;
        event_inherited();
    } else {
        event_inherited();
        sprite_index = skin.slide;
    }
    #endregion
} else {
    #region Normal move.
    if (xdir != 0) {
        face = xdir;
    }
    velocity.x = xdir * move_speed;

    if (velocity.y > max_fall_speed) {
        velocity.y = max_fall_speed;
    }

    var on_floor = (velocity.y >= 0) && probe(0, 1, CollisionTag.Obstacle, true);
    if (on_floor) {
        jump_level = 0;
    } else {
        if (jump_level == 0) {
            jump_level = 1;
        }
    }

    if (input_check("jump")) {
        jump();
        on_floor = false;
    }
    if (velocity.y < 0 && input_check("jump", InputType.Released)) {
        velocity.y *= 0.45;
    }

    if (input_check("shoot")) {
        shoot();
    }

    event_inherited();

    if (velocity.y == 0) {
        sprite_index = (xdir == 0 ? skin.idle : skin.run);
    } else {
        sprite_index = (velocity.y < 0 ? skin.jump : skin.fall);
    }
    #endregion
}
