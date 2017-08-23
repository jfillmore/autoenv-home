#!/usr/bin/env python

import sys
import re
import csv


def main(filename, count=0, offset=0, match=None):
    fh = open(filename, 'r')
    headers = []
    rows = 0
    printed = 0
    count = int(count)
    offset = int(offset)
    for row in csv.reader(fh):
        rows += 1
        if rows == 1:
            headers = row
        else:
            if offset and rows <= offset:
                continue
            if match is not None and match not in row:
                continue
            print "--- row %d ---" % (rows - 1)
            printed += 1
            for i, col in enumerate(row):
                print "  %d: %s = %s" % (i, headers[i], col)
        if count and printed >= count:
            break
    return 0


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print "Usage: csv-flatten.py FILE [ROWS] [OFFSET] [FILTER]"
        sys.exit(1)
    sys.exit(main(*sys.argv[1:]))
