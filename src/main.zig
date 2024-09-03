const std = @import("std");
const httpz = @import("httpz");
const zmpl = @import("zmpl");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // More advance cases will use a custom "Handler" instead of "void".
    // The last parameter is our handler instance, since we have a "void"
    // handler, we passed a void ({}) value.
    var server = try httpz.Server(void).init(allocator, .{.port = 5882}, {});

    var router = server.router(.{});
    router.get("/api/user/:id", getUser, .{});
    router.get("/html", showHtml, .{});

    // blocks
    try server.listen(); 
}

fn getUser(req: *httpz.Request, res: *httpz.Response) !void {
    res.status = 200;
    try res.json(.{.id = req.param("id").?, .name = "Teg"}, .{});
}

fn showHtml(req: *httpz.Request, res: *httpz.Response) !void {
    _ = req;

    var data = zmpl.Data.init(std.heap.page_allocator);
    defer data.deinit();

    var body = try data.object();
    var user = try data.object();

    try user.put("email", data.string("user@example.com"));

    try body.put("user", user);
    try data.addConst("blog_view", data.string("test"));

    if (zmpl.find("showhtml")) |template| {
        const output = try template.render(&data);

        res.status = 200;
        res.body = output;
    } else {
        res.status = 200;
        try res.json(.{.err = "html not exists"}, .{});
    }
}


