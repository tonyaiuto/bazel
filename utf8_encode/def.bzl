"""Demonstrate encoding mismatch from utf-8 encoded BUILD files."""

LicenseInfo = provider(
    fields = {
        "copyright_notice": "Short copyright notice",
    },
)

def _license_impl(ctx):
    l = LicenseInfo(copyright_notice = ctx.attr.copyright_notice)
    print(l)
    ctx.actions.write(
        output = ctx.outputs.out,
        content = '%s\n' % ctx.attr.copyright_notice,
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
