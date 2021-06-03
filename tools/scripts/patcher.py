#!/usr/bin/env python
import argparse
import os
import re
from pathlib import Path


if __name__ == "__main__":

    parser = argparse.ArgumentParser()
    parser.add_argument("--include", nargs=1, type=str, required=True,
                        help="Search only files that match filename pattern")
    parser.add_argument("--regexp", nargs=1, type=str, required=True,
                        help="Content pattern for matching")
    parser.add_argument("--replace", nargs=1, type=str, required=True,
                        help="Pattern to replace")
    parser.add_argument("--string", nargs=1, type=str, required=True,
                        help="New string content for which to replace")
    parser.add_argument("DIRECTORY", type=str, help="Directory to search recursively")
    parser.add_argument("--verbose","-v", action="store_true", help="Verbose output")

    args = parser.parse_args()

    if args.verbose:
        print("Patcher called with args: {}".format(args))
        print("Path to search {}".format(os.path.abspath(args.DIRECTORY)))

    # list all files matching include pattern
    files = Path(os.path.abspath(args.DIRECTORY)).rglob(args.include[0])

    count = 0

    content_re = re.compile(args.regexp[0])

    for path in files:
        overwrite = False
        with open(path) as f:
            count += 1
            oldText = f.read()

            # file containing pattern
            match = content_re.search(oldText)
            if match:
                # for each file, replace pattern with string
                newText = oldText.replace(args.replace[0], args.string[0])
                overwrite = True

        if overwrite:
            with open(path, "w") as f:
                f.write(newText)
                if args.verbose:
                    print("Replaced in file: {}".format(path))

    if args.verbose:
        print("Checked {} files".format(count))
