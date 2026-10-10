"""nifty_tool: a minimal app that imports a module from its own package."""

import sys

from nifty import helper


def main():
    print(helper.greet())
    return 0


if __name__ == "__main__":
    sys.exit(main())
