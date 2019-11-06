# Improper encoding to UTF-8 on ctx.actions.write

Filed as: https://github.com/bazelbuild/bazel/issues/10174

## Repo

```
bazel build :example
od -c -t x1 bazel-bin/copyright.txt
```

The result is
```
0000000   C   o   p   y   r   i   g   h   t     303 202 302 251       2
         43  6f  70  79  72  69  67  68  74  20  c3  82  c2  a9  20  32
0000020   0   1   9       T   o   n   y       A   i   u   t   o  \n
         30  31  39  20  54  6f  6e  79  20  41  69  75  74  6f  0a
```

But it should be:

```
0000000   C   o   p   y   r   i   g   h   t     302 251       2   0   1
         43  6f  70  79  72  69  67  68  74  20  c2  a9  20  32  30  31
0000020   9       T   o   n   y       A   i   u   t   o  \n
         39  20  54  6f  6e  79  20  41  69  75  74  6f  0a
0000035
```

## Analysis

The iso8859-Latin-1 copyright symbol is 0xA9. The UTF-8 encoding of that
is the two bytes [c2, a9]. What we see in the output file is clearly
those two bytes again encoded as utf-8.

The BUILD file is in UTF-8 format:

```
grep copyright_notice BUILD | od -c -t x1
0000000                   c   o   p   y   r   i   g   h   t   _   n   o
         20  20  20  20  63  6f  70  79  72  69  67  68  74  5f  6e  6f
0000020   t   i   c   e       =       "   C   o   p   y   r   i   g   h
         74  69  63  65  20  3d  20  22  43  6f  70  79  72  69  67  68
0000040   t     302 251       2   0   1   9       T   o   n   y       A
         74  20  c2  a9  20  32  30  31  39  20  54  6f  6e  79  20  41
0000060   i   u   t   o   "   ,  \n
         69  75  74  6f  22  2c  0a
0000067
```

We can see the signature of the encoded copyright symbol as 302 251.

It would seem that
-   the BUILD file is parsed as a stream of octets, each one becoming a
    distinct character [0xc2, 0xa9].
-   write() presumes the file should be UTF-8 encoded and converts the 2
    characters into the 4 need for their UTF-8 representation.

## Potential fixes

### BUILD files are UTF-8

-   Pro: Easy to implement and understand.
-   Con: A breaking change, but probably little used. (Reasoning: encodings are
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
