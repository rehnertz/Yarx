/**
 * 二维实向量（x, y）。
 * @param {Real} x
 * @param {Real} y
 */
function Vec2(x, y) constructor {
    self.x = x;
    self.y = y;
    
    /**
     * 当前向量的副本。
     * @returns {Struct.Vec2}
     */
    static clone = function() {
        return new Vec2(self.x, self.y);
    };
    
    /**
     * 向量的模长（2-范数）。
     * @returns {Struct.Vec2}
     */
    static magnitude = function() {
        return point_distance(0, 0, self.x, self.y);
    };
    
    /**
     * 单位化向量。
     * @returns {Struct.Vec2}
     */
    static normalize = function() {
        var mag = magnitude();
        return new Vec2(self.x / mag, self.y / mag);
    };
    
    /**
     * 单位化向量，返回自身引用。
     * @returns {Struct.Vec2}
     */
    static normalize_ = function() {
        var mag = magnitude();
        self.x /= mag;
        self.y /= mag;
        return self;
    };
    
    /**
     * 旋转向量。
     * @param {Real} deg 逆时针旋转的角度。
     * @returns {Struct.Vec2}
     */
    static rotate = function(deg) {
        var c = dcos(deg), s = dsin(deg);
        var x_rotated = dot_product(c, s, self.x, self.y);
        var y_rotated = dot_product(-s, c, self.x, self.y);
        return new Vec2(x_rotated, y_rotated);
    };
    
    /**
     * 旋转向量，返回自身引用。
     * @param {Real} deg 逆时针旋转的角度。
     * @returns {Struct.Vec2}
     */
    static rotate_ = function(deg) {
        var c = dcos(deg), s = dsin(deg);
        var x_rotated = dot_product(c, s, self.x, self.y);
        var y_rotated = dot_product(-s, c, self.x, self.y);
        self.x = x_rotated;
        self.y = y_rotated;
        return self;
    };
    
    /**
     * 向量加法。
     * @param {Real} x
     * @param {Real} y
     * @returns {Struct.Vec2}
     */
    static add = function(x, y) {
        return new Vec2(self.x + x, self.y + y);
    };
    
    /**
     * 向量加法，返回自身引用。
     * @param {Real} x
     * @param {Real} y
     * @returns {Struct.Vec2}
     */
    static add_ = function(x, y) {
        self.x += x;
        self.y += y;
        return self;
    };
    
    /**
     * 向量加法。
     * @param {Struct.Vec2} vec
     * @returns {Struct.Vec2}
     */
    static add_v = function(vec) {
        return new Vec2(self.x + vec.x, self.y + vec.y);
    };
    /**
     * 向量加法，返回自身引用。
     * @param {Struct.Vec2} vec
     * @returns {Struct.Vec2}
     */
    static add_v_ = function(vec) {
        self.x += vec.x;
        self.y += vec.y;
        return self;
    };
    
    /**
     * 向量减法。
     * @param {Real} x
     * @param {Real} y
     * @returns {Struct.Vec2}
     */
    static sub = function(x, y) {
        return new Vec2(self.x - x, self.y - y);
    };
    
    /**
     * 向量减法。
     * @param {Struct.Vec2} vec
     * @returns {Struct.Vec2}
     */
    static sub_v = function(vec) {
        return new Vec2(self.x - vec.x, self.y - vec.y);
    };
    
    /**
     * 向量减法，返回自身引用。
     * @param {Real} x
     * @param {Real} y
     * @returns {Struct.Vec2}
     */
    static sub_ = function(x, y) {
        self.x -= x;
        self.y -= y;
        return self;
    };
    
    /**
     * 向量减法，返回自身引用。
     * @param {Struct.Vec2} vec
     * @returns {Struct.Vec2}
     */
    static sub_v_ = function(vec) {
        self.x -= vec.x;
        self.y -= vec.y;
        return self;
    };
    
    /**
     * 标量乘法。
     * @param {Real} scalar
     * @returns {Struct.Vec2}
     */
    static smul = function(scalar) {
        return new Vec2(self.x * scalar, self.y * scalar);
    };
    
    /**
     * 标量乘法，返回自身引用。
     * @param {Real} scalar
     * @returns {Struct.Vec2}
     */
    static smul_ = function(scalar) {
        self.x *= scalar;
        self.y *= scalar;
        return self;
    };
}
