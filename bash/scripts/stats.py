#!/usr/bin/env python3

import math
import sys
import re

USAGE = r'''Usage: stats.py ARGS

ARGS:
   -h|--help         This information

   dedupe_col=NUM    If given, ensure values in the column are unique; print
                     separate stats for dupes
   ifs_re=RE         Regex to use for column splitting; default='\s+'
   has_headers=0|1   Whether input has headers to be skipped or not; default=0
   dedupe_file=PATH  If given, dedupe_col is required and 'PATH.uniq' /
                     'PATH.dupes' will be written for reference
'''


def sd_calc(data):
    n = len(data)

    if n <= 1:
        return 0.0

    mean, sd = avg_calc(data), 0.0

    # calculate stan. dev.
    for el in data:
        sd += (float(el) - mean)**2
    sd = math.sqrt(sd / float(n-1))

    return sd


def avg_calc(ls):
    n, mean = len(ls), 0.0

    if n == 0:
        return 0
    if n <= 1:
        return ls[0]

    for el in ls:
        mean = mean + float(el)
    mean = mean / float(n)

    return mean


def print_stats(col_num, headers, nums, skipped, filtered):
    sys.stdout.write('%d. ' % (col_num + 1))
    if headers:
        sys.stdout.write('%s = ' % (headers[col_num]))
    sys.stdout.write("count: %d, avg: %.2f, stddev: %.2f, range: %s - %s, sum: %.2f (skipped: %s, filtered %s)\n" % (
        len(nums),
        avg_calc(nums),
        sd_calc(nums),
        min(nums) if nums else None,
        max(nums) if nums else None,
        sum(nums),
        skipped,
        filtered,
    ))


def main(dedupe_col=None, ifs_re=r'\s+', has_headers=False, to_skip='', dedupe_file=None):
    headers = []
    grid = dupes_grid = skipped = filtered = None  # all to become arrays based on # of columns
    if dedupe_col is not None:
        dedupe_col = int(dedupe_col) - 1
    seen = set()
    num_cols = None
    if to_skip:
        to_skip = map(int, to_skip.split(','))
    else:
        to_skip = []

    rows = 0
    if dedupe_file:
        if not dedupe_col:
            raise Exception("You must specify a column to key de-duplication to provide a dedupe_file")
        fh_uniq = open(dedupe_file + '.uniq', 'w')
        fh_dupes = open(dedupe_file + '.dupes', 'w')

    for line in sys.stdin.readlines():
        line = line.strip()
        if ifs_re:
            line_parts = re.split(ifs_re, line, 0 if not num_cols else num_cols - 1)
        else:
            line_parts = [line]
        if grid is None:
            num_cols = len(line_parts)
            grid = []
            dupes_grid = []
            for i in range(0, num_cols):
                grid.append([])
                dupes_grid.append([])
            skipped = [0] * num_cols
            filtered = [0] * num_cols
        if bool(int(has_headers)):
            headers = line_parts
            has_headers = False
            if dedupe_file:
                fh_uniq.write(line + '\n')
                fh_dupes.write(line + '\n')
            continue
        dedupe_key = line_parts[dedupe_col] if dedupe_col is not None else None

        # convert to numerical values where we can
        nums = []
        for i, num in enumerate(line_parts):
            try:
                nums.append(float(num))
            except Exception as e:
                try:
                    nums.append(float(
                        ''.join(filter(
                            lambda a: a if a else None,
                            re.split('[^-.0-9]', num)
                        ))
                    ))
                    filtered[i] += 1
                except Exception as e:
                    nums.append(None)
                    skipped[i] += 1
                    continue
        # dedupe if needed, otherwise track in the grid
        if dedupe_key is not None and dedupe_key in seen:
            for i, num in enumerate(nums):
                if num is not None and i not in to_skip:
                    dupes_grid[i].append(num)
            if dedupe_file:
                fh_dupes.write(line + '\n')
        else:
            if dedupe_key is not None:
                seen.add(dedupe_key)
            for i, num in enumerate(nums):
                if num is not None and i not in to_skip:
                    grid[i].append(num)
            if dedupe_file:
                fh_uniq.write(line + '\n')
        rows += 1

    # and print our report
    for i, nums in enumerate(grid):
        print_stats(i, headers, nums, skipped[i], filtered[i])
    if dedupe_col:
        sys.stdout.write("\n--- DUPES ---\n")
        for i, nums in enumerate(dupes_grid):
            print_stats(i, headers, nums, skipped[i], filtered[i])
    if dedupe_file:
        fh_uniq.close()
        fh_dupes.close()
        sys.stdout.write("\n- wrote %s.uniq and %s.dupes\n" % (
            dedupe_file, dedupe_file
        ))



if __name__ == '__main__':
    args = {}
    while len(sys.argv) > 1:
        arg = sys.argv.pop()
        if arg.startswith('-'):
            if arg in ('-h', '--help'):
                sys.stderr.write(USAGE + '\n');
                sys.exit()
            else:
                raise Exception('Invalid arg: %s' % arg)
        else:
            parts = arg.split('=')
            args[parts[0]] = parts[1]
    main(**args)
