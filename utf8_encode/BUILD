load(":def.bzl", "write_attribute", "write_filename")

write_attribute(
    name = "attribute",
    # U+41, U+2117, U+4E16, U+1F63F  (1,2,3,4-byte UTF-8 encodings), 10 bytes.
    text = "A©世😿",
    n_chars = 4,
    n_utf8_bytes = 10,
    out = "attr.txt",
)

write_filename(
    name = "filename",
    file = glob(["*.file"]),
    n_chars = 9,
    n_utf8_bytes = 15,
    out = "filename.txt",
)
