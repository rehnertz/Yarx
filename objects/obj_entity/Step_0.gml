var dt = delta_time / 1000000;
velocity.y += dt * grav;
var disp = global_vec_to_local(velocity.x, velocity.y).smul_(dt);
var mask = move(disp.x, disp.y) ?? 0;
if ((mask & 1) != 0) {
    velocity.x = 0;
}
if ((mask & 2) != 0) {
    velocity.y = 0;
}
trigger.update();
