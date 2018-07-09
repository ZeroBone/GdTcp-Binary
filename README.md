# GdTcp Binary
TCP binary protocol handling functions written in GdScript.
# Usage
This is a boilerplate for creating custom TCP binary protocol-based multiplayer games with the Godot Engine.
The client can send a custom big endian encoded message with the help of the `OutBuffer` class.
We recommend that the server responds with a little endian encoded `Variant` or a combination of them/some other data type. In that case, the networking will be closer to native and therefore much faster. On the client stream, the library supports integers, varints, shorts and bytes. If you need to write a string, you can use the Godot `put_utf8_string` or implement your own utf/ascii encoder.
