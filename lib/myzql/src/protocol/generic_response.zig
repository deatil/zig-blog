const std = @import("std");
const constants = @import("../constants.zig");
const Packet = @import("./packet.zig").Packet;
const PacketReader = @import("./packet_reader.zig").PacketReader;

// https://dev.mysql.com/doc/dev/mysql-server/latest/page_protocol_basic_err_packet.html
pub const ErrorPacket = struct {
    error_code: u16,
    sql_state_marker: u8,
    sql_state: *const [5]u8,
    error_message: []const u8,

    pub fn initFirst(packet: *const Packet) ErrorPacket {
        var reader = packet.reader();
        const header = reader.readByte();
        std.debug.assert(header == constants.ERR);

        var error_packet: ErrorPacket = undefined;
        error_packet.error_code = reader.readInt(u16);
        error_packet.error_message = reader.readRefRemaining();
        return error_packet;
    }

    pub fn init(packet: *const Packet) ErrorPacket {
        var reader = packet.reader();
        const header = reader.readByte();
        std.debug.assert(header == constants.ERR);

        var error_packet: ErrorPacket = undefined;
        error_packet.error_code = reader.readInt(u16);

        // CLIENT_PROTOCOL_41
        error_packet.sql_state_marker = reader.readByte();
        error_packet.sql_state = reader.readRefComptime(5);

        error_packet.error_message = reader.readRefRemaining();
        return error_packet;
    }

    pub fn asError(err: *const ErrorPacket) error{ErrorPacket} {
        // TODO: better way to do this?
        std.log.warn(
            "error packet: (code: {d}, message: {s})",
            .{ err.error_code, err.error_message },
        );
        return error.ErrorPacket;
    }
};

//https://dev.mysql.com/doc/dev/mysql-server/latest/page_protocol_basic_ok_packet.html
pub const OkPacket = struct {
    affected_rows: u64,
    last_insert_id: u64,
    status_flags: ?u16,
    warnings: ?u16,
    info: ?[]const u8,
    session_state_info: ?[]const u8,

    pub fn init(packet: *const Packet, capabilities: u32) OkPacket {
        var ok_packet: OkPacket = undefined;

        var reader = packet.reader();
        const header = reader.readByte();
        std.debug.assert(header == constants.OK or header == constants.EOF);

        ok_packet.affected_rows = reader.readLengthEncodedInteger();
        ok_packet.last_insert_id = reader.readLengthEncodedInteger();

        // CLIENT_PROTOCOL_41
        ok_packet.status_flags = reader.readInt(u16);
        ok_packet.warnings = reader.readInt(u16);

        ok_packet.session_state_info = null;
        if (capabilities & constants.CLIENT_SESSION_TRACK > 0) {
            ok_packet.info = reader.readLengthEncodedString();
            if (ok_packet.status_flags) |sf| {
                if (sf & constants.SERVER_SESSION_STATE_CHANGED > 0) {
                    ok_packet.session_state_info = reader.readLengthEncodedString();
                }
            }
        } else {
            ok_packet.info = reader.readRefRemaining();
        }

        std.debug.assert(reader.finished());
        return ok_packet;
    }
};
