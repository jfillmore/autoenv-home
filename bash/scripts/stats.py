#!/usr/bin/env python

import math  
import sys  
import re
  

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
  
    if n <= 1:  
        return ls[0]  
  
    for el in ls:  
        mean = mean + float(el)  
    mean = mean / float(n)  
  
    return mean  


def main():
    nums = []
    skipped = 0
    filtered = 0
    num_re = re.compile('[^-.0-9]')
    for line in sys.stdin.readlines():
        try:
            nums.append(float(line))
        except Exception as e:
            try:
                nums.append(float(
                    ''.join(filter(
                        lambda a: a if a else None,
                        re.split('[^-.0-9]', line)
                    ))
                ))
                filtered += 1
            except Exception as e:
                skipped += 1
                continue
    print "count: %d (skipped: %d, filtered %d), avg: %.2f, stddev: %.2f, range: %s - %s, sum: %.2f" % (
        len(nums),
        skipped,
        filtered,
        avg_calc(nums),
        sd_calc(nums),
        min(nums),
        max(nums),
        sum(nums)
    )


if __name__ == '__main__':
    main()
