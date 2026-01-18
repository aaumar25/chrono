const std = @import("std");
const chrono = @import("chrono");

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    const gpa = init.gpa;
    const environ = init.minimal.environ;

    var tzdb = try chrono.tz.DataBase.init(gpa, io, environ);
    defer tzdb.deinit();

    const timezone = try tzdb.getLocalTimeZone();
    const clock: std.Io.Clock = .real;
    const timestamp_nano = try clock.now(io);
    const timestamp_utc = timestamp_nano.toSeconds();
    const local_offset = timezone.offsetAtTimestamp(timestamp_utc) orelse {
        std.debug.print("Could not convert the current time to local time.", .{});
        return error.ConversionFailed;
    };
    const timestamp_local = timestamp_utc + local_offset;

    const designation = timezone.designationAtTimestamp(timestamp_utc);

    const date = chrono.date.YearMonthDay.fromDaysSinceUnixEpoch(@intCast(@divFloor(timestamp_local, std.time.s_per_day)));
    const time = chrono.Time{ .secs = @intCast(@mod(timestamp_local, std.time.s_per_day)), .frac = 0 };

    std.debug.print("The current date is {}, and the time is {} in the {?s} timezone\n", .{ date, time, designation });

    if (timezone.identifier()) |identifier| {
        std.debug.print("The IANA time zone identifier = \"{}\"\n", .{std.zig.fmtString(identifier.string)});
    } else {
        std.debug.print("The IANA time zone identifier is unknown\n", .{});
    }
}
