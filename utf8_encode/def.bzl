"""Demonstrate encoding mismatch from utf-8 encoded BUILD files."""

def _write_attribute_impl(ctx):
    content = [
        '|%s|\n' % ctx.attr.text,
        'starlark length: %d\n' % len(ctx.attr.text),
        'n_chars: %d\n' % ctx.attr.n_chars,
        'n_utf8_bytes: %d\n' % ctx.attr.n_utf8_bytes,
    ]
    if len(ctx.attr.text) == ctx.attr.n_chars:
      content.append('# Unexpeted: BUILD file is parsed as UTF-8\n')
    elif len(ctx.attr.text) == ctx.attr.n_utf8_bytes:
      content.append('# Expected: BUILD file is parsed as Latin1\n')
    else:
      content.append('# FAIL: Unexpected Starlark length\n')
    ctx.actions.write(
        output = ctx.outputs.out,
        content = ''.join(content)
    )
    return []

write_attribute = rule(
    implementation = _write_attribute_impl,
    attrs = {
        "text": attr.string(mandatory = True),
        "n_chars": attr.int(doc="expected length in visible characters"),
        "n_utf8_bytes": attr.int(doc="expected length of UTF-8 encoding"),
        "out": attr.output(),
    },
)

def _write_filename_impl(ctx):
    if len(ctx.attr.file) != 1:
        fail('expected exactly 1 file for file. got %d' % len(ctx.attr.file))
    name = ctx.attr.file[0].label.name
    content = [
        '|%s|\n' % name,
        'starlark length: %d\n' % len(name),
        'n_chars: %d\n' % ctx.attr.n_chars,
        'n_utf8_bytes: %d\n' % ctx.attr.n_utf8_bytes,
    ]
    if len(name) == ctx.attr.n_chars:
      content.append('# Unexpected: glob targets parsed as UTF-8\n')
    elif len(name) == ctx.attr.n_utf8_bytes:
      content.append('# Expected: glob targets parsed as Latin1\n')
    else:
      content.append('# FAIL: Unexpected Starlark length\n')
    ctx.actions.write(
        output = ctx.outputs.out,
        content = ''.join(content)
    )
    return []

write_filename = rule(
    implementation = _write_filename_impl,
    attrs = {
        "file": attr.label_list(allow_files=True),
        "n_chars": attr.int(doc="expected length in visible characters"),
        "n_utf8_bytes": attr.int(doc="expected length of UTF-8 encoding"),
        "out": attr.output(),
    },
)
