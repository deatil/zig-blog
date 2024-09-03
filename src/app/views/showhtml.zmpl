<!-- Zig mode for template logic -->
@zig {
  if (std.mem.eql(u8, "zmpl is simple", "zmpl" ++ " is " ++ "simple")) {
    <span>Zmpl is simple!</span>
  }
}

<!-- Easy data lookup syntax -->
<div>Email: {{.user.email}}</div>
