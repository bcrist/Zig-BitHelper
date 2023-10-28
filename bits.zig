const std = @import("std");
const expectEqual = std.testing.expectEqual;

/// Unlike the @bitCast builtin, this supports casting to/from enums, and is easier to read when used inline;
/// instead of `@as(T, @bitCast(x))` you can just do `bits.as(T, x)`
pub fn as(comptime T: type, i: anytype) T {
    const I = @TypeOf(i);
    if (@bitSizeOf(T) != @bitSizeOf(I)) {
        @compileError("Can't cast between types of different sizes");
    }
    return switch (@typeInfo(I)) {
        .Enum => switch (@typeInfo(T)) {
            .Enum => |info| @enumFromInt(@as(info.tag_type, @bitCast(@intFromEnum(i)))),
            else => @bitCast(@intFromEnum(i)),
        },
        else => switch (@typeInfo(T)) {
            .Enum => |info| @enumFromInt(@as(info.tag_type, @bitCast(i))),
            else => @bitCast(i),
        },
    };
}
test "as" {
    const TestEnum = enum (u8) {
        ff = 0xFF,
    };

    try expectEqual(@as(u32, 0xFF), as(u32, @as(i32, 0xFF)));
    try expectEqual(@as(i32, 0xFF), as(i32, @as(u32, 0xFF)));
    try expectEqual(@as(u8, 0xFF), as(u8, TestEnum.ff));
    try expectEqual(TestEnum.ff, as(TestEnum, @as(i8, -1)));
}

pub fn zx(comptime T: type, n: anytype) T {
    const N = @TypeOf(n);
    expectInt(T);
    expectInt(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return n;
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NU = std.meta.Int(.unsigned, @bitSizeOf(N));
    const TU = std.meta.Int(.unsigned, @bitSizeOf(T));

    const nu: NU = @bitCast(n);
    const tu: TU = nu;
    return @bitCast(tu);
}
test "zx" {
    try expectEqual(@as(u32, 0xFF), zx(u32, @as(u8, 0xFF)));
    try expectEqual(@as(i32, 0xFF), zx(i32, @as(u8, 0xFF)));
    try expectEqual(@as(u32, 0xFF), zx(u32, @as(i8, -1)));
    try expectEqual(@as(u32, 0x7F), zx(u32, @as(i7, -1)));
    try expectEqual(@as(i32, 0x7F), zx(i32, @as(i7, -1)));
}

pub fn sx(comptime T: type, n: anytype) T {
    const N = @TypeOf(n);
    expectInt(T);
    expectInt(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return @bitCast(n);
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NS = std.meta.Int(.signed, @bitSizeOf(N));
    const TS = std.meta.Int(.signed, @bitSizeOf(T));

    const ns: NS = @bitCast(n);
    const ts: TS = ns;
    return @bitCast(ts);
}
test "sx" {
    try expectEqual(@as(i32, -1), sx(i32, @as(i8, -1)));
    try expectEqual(@as(i32, -1), sx(i32, @as(u8, 0xFF)));
    try expectEqual(@as(i32, -1), sx(i32, @as(i7, -1)));
    try expectEqual(@as(i32, -1), sx(i32, @as(u7, 0x7F)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), sx(u32, @as(i8, -1)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), sx(u32, @as(u8, 0xFF)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), sx(u32, @as(i7, -1)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), sx(u32, @as(u7, 0x7F)));

    try expectEqual(@as(i32, 0x7F), sx(i32, @as(i8, 0x7F)));
    try expectEqual(@as(i32, 0x7F), sx(i32, @as(u8, 0x7F)));
    try expectEqual(@as(i32, 0x3F), sx(i32, @as(i7, 0x3F)));
    try expectEqual(@as(i32, 0x3F), sx(i32, @as(u7, 0x3F)));
    try expectEqual(@as(u32, 0x7F), sx(u32, @as(i8, 0x7F)));
    try expectEqual(@as(u32, 0x7F), sx(u32, @as(u8, 0x7F)));
    try expectEqual(@as(u32, 0x3F), sx(u32, @as(i7, 0x3F)));
    try expectEqual(@as(u32, 0x3F), sx(u32, @as(u7, 0x3F)));
}

pub fn _1x(comptime T: type, n: anytype) T {
    const N = @TypeOf(n);
    expectInt(T);
    expectInt(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return n;
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NU = std.meta.Int(.unsigned, @bitSizeOf(N));
    const TU = std.meta.Int(.unsigned, @bitSizeOf(T));

    const upper = ~@as(TU, 0) ^ ~@as(NU, 0);

    const nu: NU = @bitCast(n);
    const tu: TU = nu;
    return @bitCast(upper | tu);
}
test "1x" {
    try expectEqual(@as(i32, -1), _1x(i32, @as(i8, -1)));
    try expectEqual(@as(i32, -1), _1x(i32, @as(u8, 0xFF)));
    try expectEqual(@as(i32, -1), _1x(i32, @as(i7, -1)));
    try expectEqual(@as(i32, -1), _1x(i32, @as(u7, 0x7F)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), _1x(u32, @as(i8, -1)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), _1x(u32, @as(u8, 0xFF)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), _1x(u32, @as(i7, -1)));
    try expectEqual(@as(u32, 0xFFFF_FFFF), _1x(u32, @as(u7, 0x7F)));

    try expectEqual(@as(i32, @bitCast(@as(u32, 0xFFFF_FF7F))), _1x(i32, @as(i8, 0x7F)));
    try expectEqual(@as(i32, @bitCast(@as(u32, 0xFFFF_FF7F))), _1x(i32, @as(u8, 0x7F)));
    try expectEqual(@as(i32, @bitCast(@as(u32, 0xFFFF_FFBF))), _1x(i32, @as(i7, 0x3F)));
    try expectEqual(@as(i32, @bitCast(@as(u32, 0xFFFF_FFBF))), _1x(i32, @as(u7, 0x3F)));
    try expectEqual(@as(u32, 0xFFFF_FF7F), _1x(u32, @as(i8, 0x7F)));
    try expectEqual(@as(u32, 0xFFFF_FF7F), _1x(u32, @as(u8, 0x7F)));
    try expectEqual(@as(u32, 0xFFFF_FFBF), _1x(u32, @as(i7, 0x3F)));
    try expectEqual(@as(u32, 0xFFFF_FFBF), _1x(u32, @as(u7, 0x3F)));
}

pub fn concat(tuple: anytype) ConcatResultType(@TypeOf(tuple)) {
    const R = ConcatResultType(@TypeOf(tuple));

    var result: R = 0;
    var shift_bits: std.math.Log2Int(R) = 0;

    inline for (tuple) |part| {
        const wide_part: R = part;
        result |= @shlExact(wide_part, shift_bits);
        shift_bits +%= @bitSizeOf(@TypeOf(part));
    }

    return result;
}
fn ConcatResultType(comptime T: type) type {
    comptime var bits = 0;
    const info = @typeInfo(T).Struct;
    if (!info.is_tuple) {
        @compileError("Expected tuple");
    }
    inline for (info.fields) |field| {
        expectSignedness(field.type, .unsigned);
        bits += @bitSizeOf(field.type);
    }
    return std.meta.Int(.unsigned, bits);
}
test "concat" {
    try expectEqual(@as(u16, 0x9901), concat(.{
        @as(u8, 0x01),
        @as(u8, 0x99),
    }));

    try expectEqual(@as(u34, 0x2_0000_2133), concat(.{
        @as(u1, 1),
        @as(u32, 0x1099),
        @as(u1, 1),
    }));
}

pub fn swapHalves(comptime T: type, n: T) T {
    expectSignedness(T, .unsigned);
    if ((@bitSizeOf(T) & 1) == 1) @compileError("Expected even bit width");

    const h_bits = @bitSizeOf(T) / 2;
    const H = std.meta.Int(.unsigned, h_bits);

    const low: H = @truncate(n);
    const high: H = @truncate(n >> h_bits);

    return @shlExact(@as(T, low), h_bits) | high;
}
test "swapHalves" {
    try expectEqual(@as(u32, 0xFFFF), swapHalves(u32, 0xFFFF0000));
    try expectEqual(@as(u32, 0x56781234), swapHalves(u32, 0x12345678));
    try expectEqual(@as(u6, 0x8), swapHalves(u6, 0x1));
}

//////////////////////////////////////////////////////////////////////////////

fn expectSignedness(comptime T: type, comptime signedness: std.builtin.Signedness) void {
    switch (@typeInfo(T)) {
        .Int => |info| if (info.signedness == signedness) return,
        else => {},
    }

    if (signedness == .unsigned) {
        @compileError("Expected unsigned integer");
    } else {
        @compileError("Expected signed integer");
    }
}

fn expectInt(comptime T: type) void {
    if (@typeInfo(T) != .Int) @compileError("Expected integer");
}
