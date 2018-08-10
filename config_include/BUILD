# This tree demonstrates the kind of strange things that can happen when two
# configure based projects both emit a plain "config.h" and then #include that
# in their public interface. I would argue that this is poor code hygiene, but
# I have seen it happen in reality. The workaround I use is to vendor in one
# or both libraries and rename config.h to <pkg>_config.h.

# The build ends up doing
#   -isystem aiuto/bazel/config_include/a/includes
#   -isystem bazel-out/k8-fastbuild/genfiles/aiuto/bazel/config_include/a/includes
#   -isystem bazel-out/k8-fastbuild/bin/aiuto/bazel/config_include/a/includes
#   -isystem aiuto/bazel/config_include/b/includes
#   -isystem bazel-out/k8-fastbuild/genfiles/aiuto/bazel/config_include/b/includes
#   -isystem bazel-out/k8-fastbuild/bin/aiuto/bazel/config_include/b/includes
#
# The output is what we expect.
#     a=a and b=b
#     The real config is a
#
# but that is just by luck. The reality is that b.h is including
# a/include/config.h when used in the source file here. Each library builds
# correctly on its own.

cc_binary(
    name = "config_hell",
    srcs = ["config_hell.cc"],
    deps = [
        "//experimental/users/aiuto/bazel/config_include/a",
        "//experimental/users/aiuto/bazel/config_include/b",
    ],
)

cc_binary(
    name = "config_hell_2",
    srcs = ["config_hell.cc"],
    copts = ["-DSHOW_THE_PROBLEM"],
    deps = [
        "//experimental/users/aiuto/bazel/config_include/a",
        "//experimental/users/aiuto/bazel/config_include/b",
    ],
)
