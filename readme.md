# Zig-BitHelper

Provides some helper functions for dealing with integers as bit fields:

  - bits.as: Similar to @bitCast, but works with enums as well
  - bits.zx: Casts as unsigned and zero-extends to the requested size
  - bits._1x: Casts as unsigned and one-extends to the requested size
  - bits.sx: Casts as signed and then extends to the requested size
  - bits.concat: Concatenates unsigned integers (little endian)
  - bits.swapHalves: Swaps the high and low halves of an integer with event bit count
