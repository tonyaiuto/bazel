"""Usage

bazel cquery --output=starlark --starlark:file=<path_to>/show_rule.bzl //some:target
"""

def has_one_output(target):
    return len(providers(target)["DefaultInfo"].files.to_list()) == 1

def format(target):
    return "\n".join([
        str(dir(target)),
        str(target.label) + ": " + str(dir(target.label)),
        "Providers: %s" % providers(target).keys(),
    ] + [
        "  %s: %s" % (pname, value) for pname, value in providers(target).items()
    ])
