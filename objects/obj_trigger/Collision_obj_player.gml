if (index < 0 || (prereq < 0 || (global.triggered_index >= prereq))) {
    if (index >= 0) {
        global.triggered_index = index;
    }
    if (audio_exists(sound)) {
        play_sound(sound);
    }
    on_trigger();
    instance_destroy();
}
