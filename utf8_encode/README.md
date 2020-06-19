# Improper encoding to UTF-8 on ctx.actions.write

Filed as: https://github.com/bazelbuild/bazel/issues/10174

## Repo

```
bazel build :*
more bazel-bin/*.txt
```

## Repo for ctx.actions.write issue
```
$ od -c -t x1 bazel-bin/attr.txt
```

The result is
```
0000000   |   A 303 202 302 251 303 244 302 270 302 226 303 260 302 237
         7c  41  c3  82  c2  a9  c3  a4  c2  b8  c2  96  c3  b0  c2  9f
0000020 302 230 302 277   |  \n   s   t   a   r   l   a   r   k       l
         c2  98  c2  bf  7c  0a  73  74  61  72  6c  61  72  6b  20  6c
0000040   ...

```

Which shows a double encoding. It should begin with

```
# U+41, U+2117, U+4E16, U+1F63F
0000000   A 302 251 344 270 226 360 237 230 277 ...
```

## Analysis

Known problem. Bazel parses input as Latin1. ctx.actions.write, is
taking that end encoding as UTF-8.

## Potential fixes

### Parse BUILD files are UTF-8

-   Pro: Easy to understand.
-   Con: Invasive change.
-   Con: A breaking change, but probably not an issue. (Reasoning: encodings are
    broken anyway, so who could be using anything beyond ASCII successfully)


### Allow BUILD files to specify an encoding

We could borrow from (PEP-263)[https://www.python.org/dev/peps/pep-0263/]
and use:

```
# -*- coding: <encoding name> -*-
```

-   Pro: Not a breaking change.
-   Con: Feature bloat.


### Byte are bytes

ctx.actions.write() should not assume an encoding for the output. It
would emit exactly what it is given.

-   Pro: Easy to implement.
-   Con: Breaking change.
-   Con: Hard to defend as the most useful option.


### More switches and bells.

ctx.actions.write() could have an encoding attribute. Use 'none' for this case.

-   Con: Feature bloat.
-   Con: Dubious value. 
-   Con: Still does not fix the bug.
