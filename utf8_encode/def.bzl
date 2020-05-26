"""Demonstrate encoding mismatch from utf-8 encoded BUILD files."""

LicenseInfo = provider(
    fields = {
        "copyright_notice": "Short copyright notice",
    },
)

def _license_impl(ctx):
    l = LicenseInfo(copyright_notice = ctx.attr.copyright_notice)
    # if the length is 28, then we are seeing 2 octets for the
    # copyright character, which would mean it is already unicode.
    content = [
        ctx.attr.copyright_notice,
        'length: %d' % len(ctx.attr.copyright_notice),
        'expected: 27\n',
    ]
    ctx.actions.write(
        output = ctx.outputs.out,
        content = '\n'.join(content)
    )
    return [l]

license = rule(
    implementation = _license_impl,
    attrs = {
        "copyright_notice": attr.string(
            mandatory = True,
            doc = "Copyright notice.",
        ),
        "out": attr.output(mandatory = True),
    },
)
