/// Unlike the @bitCast builtin, this supports casting to/from enums, and is easier to read when used inline;
/// instead of `@as(T, @bitCast(x))` you can just do `bits.as(T, x)`
pub fn as(comptime T: type, i: anytype) T {
    const I = @TypeOf(i);
    if (@bitSizeOf(T) != @bitSizeOf(I)) {
        @compileError("Can't cast between types of different sizes");
    }
    return switch (@typeInfo(I)) {
        .@"enum" => switch (@typeInfo(T)) {
            .@"enum" => |info| @enumFromInt(@as(info.tag_type, @bitCast(@intFromEnum(i)))),
            else => @bitCast(@intFromEnum(i)),
        },
        else => switch (@typeInfo(T)) {
            .@"enum" => |info| @enumFromInt(@as(info.tag_type, @bitCast(i))),
            else => @bitCast(i),
        },
    };
}
test as {
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
    expect_int(T);
    expect_int(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return n;
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NU = @Int(.unsigned, @bitSizeOf(N));
    const TU = @Int(.unsigned, @bitSizeOf(T));

    const nu: NU = @bitCast(n);
    const tu: TU = nu;
    return @bitCast(tu);
}
test zx {
    try expectEqual(@as(u32, 0xFF), zx(u32, @as(u8, 0xFF)));
    try expectEqual(@as(i32, 0xFF), zx(i32, @as(u8, 0xFF)));
    try expectEqual(@as(u32, 0xFF), zx(u32, @as(i8, -1)));
    try expectEqual(@as(u32, 0x7F), zx(u32, @as(i7, -1)));
    try expectEqual(@as(i32, 0x7F), zx(i32, @as(i7, -1)));
}

pub fn sx(comptime T: type, n: anytype) T {
    const N = @TypeOf(n);
    expect_int(T);
    expect_int(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return @bitCast(n);
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NS = @Int(.signed, @bitSizeOf(N));
    const TS = @Int(.signed, @bitSizeOf(T));

    const ns: NS = @bitCast(n);
    const ts: TS = ns;
    return @bitCast(ts);
}
test sx {
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
    expect_int(T);
    expect_int(N);

    if (@bitSizeOf(T) == @bitSizeOf(N)) return n;
    if (@bitSizeOf(T) < @bitSizeOf(N)) @compileError("Cannot reduce width; use @truncate() instead");

    const NU = @Int(.unsigned, @bitSizeOf(N));
    const TU = @Int(.unsigned, @bitSizeOf(T));

    const upper = ~@as(TU, 0) ^ ~@as(NU, 0);

    const nu: NU = @bitCast(n);
    const tu: TU = nu;
    return @bitCast(upper | tu);
}
test _1x {
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
    const info = @typeInfo(T).@"struct";
    if (!info.is_tuple) {
        @compileError("Expected tuple");
    }
    inline for (info.fields) |field| {
        expect_signedness(field.type, .unsigned);
        bits += @bitSizeOf(field.type);
    }
    return @Int(.unsigned, bits);
}
test concat {
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

pub fn swap_halves(comptime T: type, n: T) T {
    expect_signedness(T, .unsigned);
    if ((@bitSizeOf(T) & 1) == 1) @compileError("Expected even bit width");

    const h_bits = @bitSizeOf(T) / 2;
    const H = @Int(.unsigned, h_bits);

    const low: H = @truncate(n);
    const high: H = @truncate(n >> h_bits);

    return @shlExact(@as(T, low), h_bits) | high;
}
test swap_halves {
    try expectEqual(@as(u32, 0xFFFF), swap_halves(u32, 0xFFFF0000));
    try expectEqual(@as(u32, 0x56781234), swap_halves(u32, 0x12345678));
    try expectEqual(@as(u6, 0x8), swap_halves(u6, 0x1));
}

pub fn undefined_bits_iterator(undefined_bits: anytype, constant_bits: anytype) Undefined_Bits_Iterator(@TypeOf(undefined_bits, constant_bits)) {
    return .{
        .undefined_bits = undefined_bits,
        .constant_bits = constant_bits,
    };
}

pub fn Undefined_Bits_Iterator(comptime T: type) type {
    std.debug.assert(@typeInfo(T) == .int);
    return struct {
        undefined_bits: T, // for each set bit in this mask, we'll generate permutations for both states of that bit
        constant_bits: T, // any bits that are set here will also be set in each result value
        last_permutation: ?T = null,

        pub fn next(self: *@This()) ?T {
            if (self.last_permutation) |last| {
                const mask = self.undefined_bits;
                const remaining_bits = mask ^ last;
                if (remaining_bits == 0) return null;
                const bits_to_toggle = (remaining_bits ^ (remaining_bits - 1)) & mask;
                const next_value = last ^ bits_to_toggle;
                self.last_permutation = next_value;
                return next_value | self.constant_bits;
            } else {
                self.last_permutation = 0;
                return self.constant_bits;
            }
        }
    };
}

test undefined_bits_iterator {
    var iter = undefined_bits_iterator(@as(u32, 0xFFFF), 0);
    for (0..0x10000) |expected| {
        try std.testing.expectEqual(expected, iter.next().?);
    }
    try std.testing.expectEqual(null, iter.next());

    iter = .{
        .undefined_bits = 0b0000_0011_0100_1001,
        .constant_bits  = 0b1111_0000_0011_0000,
    };
    try std.testing.expectEqual(0b1111_0000_0011_0000, iter.next());
    try std.testing.expectEqual(0b1111_0000_0011_0001, iter.next());
    try std.testing.expectEqual(0b1111_0000_0011_1000, iter.next());
    try std.testing.expectEqual(0b1111_0000_0011_1001, iter.next());
    try std.testing.expectEqual(0b1111_0000_0111_0000, iter.next());
    try std.testing.expectEqual(0b1111_0000_0111_0001, iter.next());
    try std.testing.expectEqual(0b1111_0000_0111_1000, iter.next());
    try std.testing.expectEqual(0b1111_0000_0111_1001, iter.next());
    try std.testing.expectEqual(0b1111_0001_0011_0000, iter.next());
    try std.testing.expectEqual(0b1111_0001_0011_0001, iter.next());
    try std.testing.expectEqual(0b1111_0001_0011_1000, iter.next());
    try std.testing.expectEqual(0b1111_0001_0011_1001, iter.next());
    try std.testing.expectEqual(0b1111_0001_0111_0000, iter.next());
    try std.testing.expectEqual(0b1111_0001_0111_0001, iter.next());
    try std.testing.expectEqual(0b1111_0001_0111_1000, iter.next());
    try std.testing.expectEqual(0b1111_0001_0111_1001, iter.next());
    try std.testing.expectEqual(0b1111_0010_0011_0000, iter.next());
    try std.testing.expectEqual(0b1111_0010_0011_0001, iter.next());
    try std.testing.expectEqual(0b1111_0010_0011_1000, iter.next());
    try std.testing.expectEqual(0b1111_0010_0011_1001, iter.next());
    try std.testing.expectEqual(0b1111_0010_0111_0000, iter.next());
    try std.testing.expectEqual(0b1111_0010_0111_0001, iter.next());
    try std.testing.expectEqual(0b1111_0010_0111_1000, iter.next());
    try std.testing.expectEqual(0b1111_0010_0111_1001, iter.next());
    try std.testing.expectEqual(0b1111_0011_0011_0000, iter.next());
    try std.testing.expectEqual(0b1111_0011_0011_0001, iter.next());
    try std.testing.expectEqual(0b1111_0011_0011_1000, iter.next());
    try std.testing.expectEqual(0b1111_0011_0011_1001, iter.next());
    try std.testing.expectEqual(0b1111_0011_0111_0000, iter.next());
    try std.testing.expectEqual(0b1111_0011_0111_0001, iter.next());
    try std.testing.expectEqual(0b1111_0011_0111_1000, iter.next());
    try std.testing.expectEqual(0b1111_0011_0111_1001, iter.next());
    try std.testing.expectEqual(null, iter.next());
}

//////////////////////////////////////////////////////////////////////////////

fn expect_signedness(comptime T: type, comptime signedness: std.builtin.Signedness) void {
    switch (@typeInfo(T)) {
        .int => |info| if (info.signedness == signedness) return,
        else => {},
    }

    if (signedness == .unsigned) {
        @compileError("Expected unsigned integer");
    } else {
        @compileError("Expected signed integer");
    }
}

fn expect_int(comptime T: type) void {
    if (@typeInfo(T) != .int) @compileError("Expected integer");
}

const expectEqual = std.testing.expectEqual;
const std = @import("std");
