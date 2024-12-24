event_inherited();
image_index = irandom(image_number - 1);
attached_instance = undefined;
attached_displacement = new Vec2(0, 0);

move = function(dx, dy) {
    if (attached_instance == undefined) {
        var obstacles = get_probed(dx, dy, CollisionTag.Obstacle, false, true);
        if (array_length(obstacles) == 0) {
            x += dx;
            y += dy;
        } else {
            translate(dx, dy);
            attached_instance = obstacles[0];
            attached_displacement = new Vec2(x - attached_instance.x, y - attached_instance.y);
        }
    }
    
    if (attached_instance != undefined) {
        x = attached_instance.x + attached_displacement.x;
        y = attached_instance.y + attached_displacement.y;
    }
};
