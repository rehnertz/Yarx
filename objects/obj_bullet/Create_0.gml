event_inherited();

move = function(dx, dy) {
    if (probe(dx, dy, CollisionTag.Obstacle)) {
        instance_destroy();
    }
    x += dx;
    y += dy;
};
