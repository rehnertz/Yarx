set_trigger({
    index: 1,
    trigger: TriggerTranslate,
    disp: new Vec2(300, 0),
    duration: 3,
    easing: function(t) { return t * t * t * (6 * t * t - 15 * t + 10); }
});