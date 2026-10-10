# External py_binary can't import its own packages with import_all=false

When a build sets

```
--@rules_python//python/config_settings:experimental_python_import_all_repositories=false
```

a `py_binary` defined in an **external** repository cannot import modules
from its own repository by their repo-root-relative name. A
`py_zipapp_binary` that wraps it fails the same way. The identical target
works when built inside its own repository, or when the flag is left at its
default (`true`).

Seen with rules_python 2.4.1 and Bazel 9.1.0 on macOS arm64.

## Layout

- `cool_tools/` - a tiny repository.
  - `nifty/main.py` does `from nifty import helper`.
  - `//nifty:nifty_tool_bin` is a `py_binary`.
  - `//nifty:nifty_tool` is a `py_zipapp_binary` that wraps it.
  - `//nifty:nifty_tool2` is the same, except its binary sets
    `imports = [".."]`.
- `consumer/` - uses `cool_tools` via `local_repository`. `repro.sh` builds
  and runs the tools end to end.

The repository rule doesn't matter. `http_archive` behaves the same way.

## Reproduce

```
cd consumer
./repro.sh
```

For each case, the script builds the target, copies the `.pyz` from
`$(bazel info bazel-bin)/external/+local_repository+cool_tools/nifty/` to
`/tmp`, and runs it there.

| Target | `experimental_python_import_all_repositories` | Result |
|---|---|---|
| `nifty_tool` | default (`true`) | works |
| `nifty_tool` | `false` | `ModuleNotFoundError` |
| `nifty_tool2` (`imports = [".."]`) | `false` | works |

The failing case:

```
  File ".../runfiles/+local_repository+cool_tools/nifty/main.py", line 5, in <module>
    from nifty import helper as h
ModuleNotFoundError: No module named 'nifty'
```

The zipapp isn't needed to show the bug. This fails the same way:

```
bazel run --@rules_python//python/config_settings:experimental_python_import_all_repositories=false \
    @cool_tools//nifty:nifty_tool_bin
```

## Analysis

With `RULES_PYTHON_BOOTSTRAP_VERBOSE=1`, the two runs differ in a single
`sys.path` entry.

Default flag:

```
bazel_site_init: append sys.path: import-all : .../runfiles/+local_repository+cool_tools
bazel_site_init: append sys.path: import-all : .../runfiles/rules_python++python+python_3_12_aarch64-apple-darwin
```

Flag set to `false`:

```
bazel_site_init: append sys.path: workspace-root : .../runfiles/_main
```

The generated `_bazel_site_init.py` (from
`python/private/site_init_template.py`) contains

```python
_IMPORT_ALL = "False" == "True"
_WORKSPACE_NAME = "_main"
...
    if _IMPORT_ALL:
        ...  # add every runfiles/<repo> directory
    else:
        _maybe_add_path(os.path.join(_RUNFILES_ROOT, _WORKSPACE_NAME), "workspace-root")
```

`py_executable.bzl` fills `%workspace_name%` with `ctx.workspace_name`. That
is always the name of the **main** repository (`_main`), no matter which
repository defines the binary. The binary's own sources are in
`runfiles/+local_repository+cool_tools/`, so nothing on `sys.path` can resolve
`import nifty`.

Inside `cool_tools` itself, the main repository *is* the binary's
repository, so `runfiles/_main` is correct and the same code works.

---

## Bug 1: rules_python (bazel-contrib/rules_python)

**Title:** With `experimental_python_import_all_repositories=false`, a
py_binary from an external repo cannot import its own repo's packages

**Body:**

> The docs for `experimental_python_import_all_repositories` recommend
> setting it to `false` "to avoid external dependencies unexpectedly
> interferring with import searching". But with it set to `false`, any
> `py_binary` defined in an external repository loses its own repository
> root from `sys.path`, so repo-root-relative imports (`from pkg import mod`)
> fail with `ModuleNotFoundError`. The same import works when the binary is
> in the main repository.
>
> **Cause:** in the `else` branch of `site_init_template.py`, rules_python
> adds `runfiles/<%workspace_name%>`, and `py_executable.bzl` sets
> `%workspace_name%` from `ctx.workspace_name`. That is the main repository
> (`_main`), not the repository that owns the binary.
>
> **Expected:** the fallback adds the binary's own repository root, e.g.
> the runfiles directory for `ctx.label.repo_name` (or `ctx.workspace_name`
> when that is empty). That keeps the flag's purpose (other repos are not
> on the path) while letting the binary import its own code.
>
> **Repro:** <link to this directory> - `consumer/repro.sh` builds the same
> target with and without the flag. It works with the default and fails with
> `false`.
> rules_python 2.4.1, Bazel 9.1.0, macOS arm64. Reproduces with `bazel run`
> of the plain `py_binary`, not only `py_zipapp_binary`.
>
> **Workaround:** give the binary an explicit import root, e.g.
> `imports = [".."]` (`//nifty:nifty_tool2` in the repro). This requires every external
> tool author to anticipate that a consumer might set this flag.

---

## Bug 2: datadog-agent

**Title:** `experimental_python_import_all_repositories=false` breaks Python
tools consumed from external modules (e.g. `@better_gitlab//run_actions`)

**Body:**

> `.bazelrc` line 18 sets
>
> ```
> common --@rules_python//python/config_settings:experimental_python_import_all_repositories=false # avoid interferences
> ```
>
> This came in with commit `1f5b72abea` (#57660, "Update dependency
> rules_python to v2.4.1") on 2026-10-07, even though that PR is titled as a
> patch-level version bump.
>
> Because of a rules_python bug (<link to Bug 1>), that setting means any
> `py_binary` or `py_zipapp_binary` we build from an external repository
> cannot import its own packages. For example,
> `bazel build @better_gitlab//run_actions:run_actions` produces a
> `run_actions.pyz` that fails with
>
> ```
> File ".../runfiles/+http_archive+better_gitlab/run_actions/main.py", line 21, in <module>
>     from run_actions import action as action_lib
> ModuleNotFoundError: No module named 'run_actions'
> ```
>
> With `RULES_PYTHON_BOOTSTRAP_VERBOSE=1`, the only repository entry on
> `sys.path` is `runfiles/_main`, the datadog-agent root, not
> `runfiles/+http_archive+better_gitlab`.
>
> **Options:**
> 1. Drop the flag (back to the rules_python default, `true`) until Bug 1
>    is fixed.
> 2. Keep it, and require every external Python tool we depend on to set
>    `imports` on its libraries.
>
> A flag that changes import semantics for every Python target should be
> its own PR, with the reason for it (what "interferences" were seen)
> written down, rather than bundled into a dependency bump.
>
> Minimal repro: <link to this directory>.
