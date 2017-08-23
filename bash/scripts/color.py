#!/usr/bin/env python

import re
import sys
import math
import string
import colorsys


def int2base(x, base):
    pool = string.digits + string.letters
    x = int(x)
    if x < 0:
        sign = -1
    elif x == 0:
        return pool[0]
    else:
        sign = 1
    x *= sign
    digits = []
    while x:
        digits.append(pool[x % base])
        x /= base
    if sign < 0:
        digits.append('-')
    digits.reverse()
    return ''.join(digits)


def get_color(color, encoding='hex'):
    '''
    Returns a color in the specified encoding. Color can be hex, RGB, or HSV
    '''
    if not encoding:
        encoding = 'hex'
    if isinstance(color, basestring):
        if re.match(r'^#?[a-f0-9]{6}$', color, re.IGNORECASE):
            # e.g. 0099FF, #996600
            # add the # if it isn't there
            if color[0:1] != '#':
                color = '#' + color
            # no conversion needed
            if encoding == 'hex':
                return color
    elif type(color) == dict:
        result = '#'
        if 'r' in color and 'g' in color and 'b' in color:
            # no conversion needed
            if encoding == 'rgb':
                return color
            # make sure our colors are in order
            for hue in ['r', 'g', 'b']:
                base16 = int2base(color[hue], 16)
                if len(base16) == 1:
                    result += '0'
                result += base16
        elif 'h' in color and 's' in color and 'v' in color:
            # no conversion needed
            if encoding == 'hsv':
                return color
            else:
                # normalize 0-255 to 0-1
                rgb_color = colorsys.hsv_to_rgb(color['h'] / 360.0, color['s'], color['v'])
                # now convert back to hex for further conversion
                result = '#'
                for hue in rgb_color:
                    base16 = int2base(hue * 255, 16)
                    if len(base16) == 1:
                        result += '0' + base16
                    else:
                        result += base16
        else:
            raise Exception("Unrecognized color object.")
        color = result
    else:
        raise Exception("Unrecognized color type: " + color + '.')
    # and return as the requested encoding - we're in hex at this point
    if encoding == 'hsv':
        # convert to RBG [0,1] first
        rgb_clr = {
            'r': int(color[1:3], 16) / 255.0,
            'g': int(color[3:5], 16) / 255.0,
            'b': int(color[5:7], 16) / 255.0
        }
        max_val = max(rgb_clr['r'], rgb_clr['g'], rgb_clr['b'])
        min_val = min(rgb_clr['r'], rgb_clr['g'], rgb_clr['b'])
        delta = float(max_val - min_val)
        color = {
            'h': 0.0,
            's': 0.0,
            'v': max_val
        }
        if max_val != 0:
            color['s'] = delta / max_val
        else:
            return {'s': 0.0, 'h': 360, 'v': color['v']}
        if rgb_clr['r'] == max_val:  # yellow/magenta range
            if delta:
                color['h'] = (rgb_clr['g'] - rgb_clr['b']) / delta
            else:
                color['h'] = (rgb_clr['g'] - rgb_clr['b'])
        elif rgb_clr['g'] == max_val:  # cyan/yellow range
            if delta:
                color['h'] = 2.0 + (rgb_clr['b'] - rgb_clr['r']) / delta
            else:
                color['h'] = 2.0 + (rgb_clr['b'] - rgb_clr['r'])
        else:  # yellow/magenta range
            if delta:
                color['h'] = 4.0 + (rgb_clr['r'] - rgb_clr['g']) / delta
            else:
                color['h'] = 4.0 + (rgb_clr['r'] - rgb_clr['g'])
        color['h'] *= 60
        if color['h'] < 0:
            color['h'] += 360
        color['h'] = int(color['h'])
    elif encoding == 'rgb':
        color = {
            'r': int(color[1:3], 16),
            'g': int(color[3:5], 16),
            'b': int(color[5:7], 16)
        }
    elif encoding != 'hex':
        # we're in hex by default
        raise Exception("Invalid color encoding: '" + encoding + "'.")
    return color


def blend(color, target, **args):
    # if there are no steps or the offset is zero take the easy way out
    encoding = args.get('encoding', 'hex')
    ratio = float(args.get('ratio', 0.5))
    source = get_color(color, encoding='rgb')
    target = get_color(target, encoding='rgb')
    # easy cases
    if ratio == 0:
        color = source
    elif ratio == 1:
        color = target
    else:
        # and blend each part
        color = {
            'r': int((source['r'] * (1 - ratio)) + (target['r'] * ratio)),
            'g': int((source['g'] * (1 - ratio)) + (target['g'] * ratio)),
            'b': int((source['b'] * (1 - ratio)) + (target['b'] * ratio))
        }
        # limit values to 0-255, in case the ratio is > 1 or < 0
        for part in color:
            if int(color[part]) > 255:
                color[part] = 255
            elif int(color[part]) < 0:
                color[part] = 0
    return get_color(color, encoding=encoding)


def mix(color, **args):
    #args = {
    #    encoding: 'hex', # or any other encoding supported by "get_color"
    #    hue: 0 - 360,
    #    hue_mult: 0.0 - 1.0,
    #    hue_shift: 0 - 360,
    #    saturation: 0.0 - 1.0,
    #    saturation_mult: 0.0 - 1.0,
    #    saturation_shift: 0 - 360,
    #    value: 0.0 - 1.0,
    #    value_mult: 0.0 - 1.0,
    #    value_shift: 0 - 360
    #}
    color = get_color(color, encoding='hsv')
    if args.get('hue'):
        color['h'] = int(args['hue'])
    if args.get('hue_mult'):
        color['h'] *= float(args['hue_mult'])
    if args.get('hue_shift'):
        color['h'] += int(args['hue_shift'])
    if args.get('saturation'):
        color['s'] = float(args['saturation'])
    if args.get('saturation_mult'):
        color['s'] *= float(args['saturation_mult'])
    if args.get('saturation_shift'):
        color['s'] += int(args['saturation_shift'])
    if args.get('value'):
        color['v'] = float(args['value'])
    if args.get('value_mult'):
        color['v'] *= float(args['value_mult'])
    if args.get('value_shift'):
        color['v'] += int(args['value_shift'])
    if color['h'] < 0:
        color['h'] = 360 + (color['h'] % 360)
    if color['h'] > 360:
        color['h'] = color['h'] % 360
    if color['s'] > 1:
        color['s'] = 1
    if color['s'] < 0:
        color['s'] = 0
    if color['v'] > 1:
        color['v'] = 1
    if color['v'] < 0:
        color['v'] = 0
    return get_color(color, encoding=args.get('encoding'))


def print_result(result):
    if isinstance(result, basestring):
        print result
    else:
        for key in result:
            print "%s=%s" % (key, result[key])


def __test():
    # weak-sauce testing!
    print get_color('#005599')
    for encoding in ['hex', 'rgb', 'hsv']:
        print "%s: %s" % (encoding, str(get_color('#005599', encoding=encoding)))
    print mix('#005599', saturation=1)
    print mix('#005599', saturation=0.5)
    print mix('#005599', hue=180)
    print mix('#005599', hue=30)
    print mix('#005599', value_mult=0.5)
    print blend('#005599', '#000000')


if __name__ == '__main__':
    '''quick'n'dirty execution'''
    args = {}
    if len(sys.argv) < 3:
        sys.stderr.write('Usage: %s CMD arg1=val1 arg2=val2\n' % sys.argv[0])
        sys.exit(1)
    cmd = sys.argv[1]
    for arg in sys.argv[2:]:
        if not '=' in arg:
            sys.stderr.write('Usage: %s CMD arg1=val1 arg2=val2\n' % sys.argv[0])
            sys.stderr.write('Invalid arg format: %s\n' % arg)
            sys.exit(1)
        key, value = arg.split('=', 1)
        args[key] = value
    if cmd == 'mix':
        print_result(mix(**args))
    elif cmd == 'blend':
        print_result(blend(**args))
    elif cmd == 'get':
        print_result(get_color(**args))
    else:
        sys.stderr.write('Usage: %s CMD arg1=val1 arg2=val2\n' % sys.argv[0])
        sys.stderr.write('Invalid command: %s\n' % cmd)
        sys.exit(1)
    sys.exit(0)
