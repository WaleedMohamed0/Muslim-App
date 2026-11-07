"""Generate small, original flat-vector Lottie scenes for worship lessons."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / 'assets' / 'animations'


def shape_layer(name, shapes, index, motion=0):
    position = {'a': 0, 'k': [180, 180, 0]}
    if motion:
        position = {'a': 1, 'k': [
            {'t': 0, 's': [180, 180, 0], 'e': [180, 180 - motion, 0], 'o': {'x': [0.33], 'y': [0]}, 'i': {'x': [0.67], 'y': [1]}},
            {'t': 18, 's': [180, 180 - motion, 0], 'e': [180, 180, 0], 'o': {'x': [0.33], 'y': [0]}, 'i': {'x': [0.67], 'y': [1]}},
            {'t': 36, 's': [180, 180, 0], 'e': [180, 180 - motion, 0], 'o': {'x': [0.33], 'y': [0]}, 'i': {'x': [0.67], 'y': [1]}},
            {'t': 54, 's': [180, 180 - motion, 0], 'e': [180, 180, 0], 'o': {'x': [0.33], 'y': [0]}, 'i': {'x': [0.67], 'y': [1]}},
            {'t': 71, 's': [180, 180, 0], 'h': 1},
        ]}
    return {
        'ddd': 0, 'ind': index, 'ty': 4, 'nm': name, 'sr': 1,
        'ks': {'o': {'a': 0, 'k': 100}, 'r': {'a': 0, 'k': 0},
               'p': position, 'a': {'a': 0, 'k': [0, 0, 0]},
               's': {'a': 0, 'k': [100, 100, 100]}},
        'ao': 0, 'shapes': shapes, 'ip': 0, 'op': 72, 'st': 0, 'bm': 0,
        'completed': True,
    }


def fill(color):
    return {'ty': 'fl', 'c': {'a': 0, 'k': color}, 'o': {'a': 0, 'k': 100},
            'r': 1, 'bm': 0, 'nm': 'flat color'}


def ellipse(name, x, y, rx, ry, color):
    return {'ty': 'gr', 'it': [
        {'ty': 'el', 'p': {'a': 0, 'k': [x, y]}, 's': {'a': 0, 'k': [rx * 2, ry * 2]}, 'nm': name},
        fill(color), {'ty': 'tr', 'p': {'a': 0, 'k': [0, 0]}, 'a': {'a': 0, 'k': [0, 0]},
                      's': {'a': 0, 'k': [100, 100]}, 'r': {'a': 0, 'k': 0},
                      'o': {'a': 0, 'k': 100}, 'nm': 'transform'}], 'nm': name}


def rect(name, x, y, w, h, radius, color):
    return {'ty': 'gr', 'it': [
        {'ty': 'rc', 'p': {'a': 0, 'k': [x, y]}, 's': {'a': 0, 'k': [w, h]},
         'r': {'a': 0, 'k': radius}, 'nm': name}, fill(color),
        {'ty': 'tr', 'p': {'a': 0, 'k': [0, 0]}, 'a': {'a': 0, 'k': [0, 0]},
         's': {'a': 0, 'k': [100, 100]}, 'r': {'a': 0, 'k': 0},
         'o': {'a': 0, 'k': 100}, 'nm': 'transform'}], 'nm': name}


def path(name, points, color, width=12):
    verts = [[x, y] for x, y in points]
    return {'ty': 'gr', 'it': [
        {'ty': 'sh', 'ks': {'a': 0, 'k': {'i': [[0, 0]] * len(verts), 'o': [[0, 0]] * len(verts),
                              'v': verts, 'c': False}}, 'nm': name},
        {'ty': 'st', 'c': {'a': 0, 'k': color}, 'o': {'a': 0, 'k': 100}, 'w': {'a': 0, 'k': width},
         'lc': 2, 'lj': 2, 'ml': 4, 'bm': 0, 'nm': 'rounded stroke'},
        {'ty': 'tr', 'p': {'a': 0, 'k': [0, 0]}, 'a': {'a': 0, 'k': [0, 0]},
         's': {'a': 0, 'k': [100, 100]}, 'r': {'a': 0, 'k': 0}, 'o': {'a': 0, 'k': 100}, 'nm': 'transform'}],
        'nm': name}


def scene(kind):
    navy, teal, skin, water, ground = [c + [1] for c in ([.16,.27,.35], [.19,.58,.54], [.78,.57,.43], [.26,.65,.83], [.84,.88,.84])]
    layers = []
    layers.append(shape_layer('soft ground', [ellipse('ground', 0, 114, 105, 10, ground)], 1))
    # The pose is deliberately varied by lesson action; no facial detail or gender markers.
    poses = {
      'intention': ([(0, 30), (-35, 15), (35, 15)], False),
      'wash_hands': ([(-24, 34), (22, 34), (0, 12)], False),
      'rinse_mouth': ([(-27, 18), (26, 18), (3, -5)], False),
      'rinse_nose': ([(-22, 15), (24, 12), (8, -10)], False),
      'wash_face': ([(-28, 15), (28, 15), (0, -5)], False),
      'wash_arms': ([(-38, 5), (38, 5), (0, 8)], False),
      'wipe_head_ears': ([(-23, 0), (23, 0), (0, -25)], False),
      'wash_feet': ([(-20, 34), (32, -8), (20, 32)], True),
      'opening_takbir': ([(-33, -20), (33, -20), (0, 0)], False),
      'standing_recitation': ([(-20, 22), (20, 22), (0, 0)], False),
      'bowing': ([(-30, 16), (32, 16), (10, -8)], True),
      'rise_from_bowing': ([(-20, 20), (20, 20), (0, 0)], False),
      'prostration': ([(-35, 35), (34, 32), (20, 25)], True),
      'sitting_between_prostrations': ([(-28, 24), (28, 24), (0, 18)], True),
      'second_prostration': ([(-35, 35), (34, 32), (20, 25)], True),
      'tashahhud': ([(-28, 24), (28, 24), (0, 18)], True),
      'taslim': ([(-18, 22), (18, 22), (0, 0)], False),
    }
    hands, crouched = poses[kind]
    if kind in {'prostration', 'second_prostration'}:
      figure = [
        rect('modest body', 0, 43, 76, 29, 13, teal),
        ellipse('head touching floor', 0, 80, 15, 15, skin),
        rect('simple cap', 0, 67, 25, 7, 4, navy),
        path('arms to palms', [(-24, 35), (-42, 69), (-28, 93)], teal, 11),
        path('other arm to palm', [(24, 35), (42, 69), (28, 93)], teal, 11),
        ellipse('left palm', -28, 94, 8, 4, skin), ellipse('right palm', 28, 94, 8, 4, skin),
        path('bent legs', [(-28, 44), (-36, 65), (-24, 89)], navy, 12),
        path('other bent leg', [(28, 44), (36, 65), (24, 89)], navy, 12),
        path('feet toes folded', [(-24, 89), (-12, 91), (24, 89), (12, 91)], skin, 8),
      ]
    elif kind == 'bowing':
      figure = [
        rect('inclined modest body', 16, 18, 70, 26, 12, teal),
        ellipse('head', 57, 16, 16, 17, skin), rect('simple cap', 57, 1, 26, 7, 4, navy),
        path('arms resting near knees', [(0, 8), (19, 34), (37, 44)], teal, 11),
        path('other arm', [(3, 6), (25, 29), (45, 41)], teal, 9),
        ellipse('hands at knees', 39, 44, 6, 6, skin),
        path('legs upright', [(-15, 31), (-17, 70), (-4, 98)], navy, 12),
        path('other leg', [(4, 31), (9, 70), (19, 98)], navy, 12),
      ]
    elif kind in {'sitting_between_prostrations', 'tashahhud'}:
      figure = [
        rect('upright modest body', 0, 20, 48, 62, 16, teal),
        ellipse('head', 0, -20, 18, 20, skin), rect('simple cap', 0, -38, 30, 7, 4, navy),
        path('hands resting on thighs', [(-16, 8), (-22, 44), (-7, 56)], teal, 10),
        path('other hand', [(16, 8), (22, 44), (7, 56)], teal, 10),
        ellipse('left hand', -7, 57, 6, 5, skin), ellipse('right hand', 7, 57, 6, 5, skin),
        path('folded legs', [(-12, 47), (-37, 75), (-12, 81), (12, 67), (36, 78)], navy, 12),
      ]
    elif kind == 'wash_feet':
      figure = [
        rect('bent modest body', 9, 20, 52, 64, 15, teal),
        ellipse('head', 35, -22, 18, 20, skin), rect('simple cap', 35, -40, 30, 7, 4, navy),
        path('arm reaching toward foot', [(27, 4), (44, 43), (29, 82)], teal, 11),
        ellipse('washing hand', 28, 83, 7, 7, skin),
        path('other arm', [(-15, 4), (-28, 37), (-26, 65)], teal, 11),
        path('bent legs', [(-12, 49), (-20, 78), (-4, 88)], navy, 12),
        path('foot extended', [(-4, 88), (25, 90), (34, 86)], skin, 10),
      ]
    else:
      figure = [
        rect('long modest tunic', 0, 31, 52, 79, 18, teal),
        ellipse('head', 0, -29, 21, 23, skin), rect('simple cap', 0, -47, 35, 9, 5, navy),
        path('left sleeve', [(-18, 2), hands[0]], teal, 18),
        path('right sleeve', [(18, 2), hands[1]], teal, 18),
        ellipse('left hand', *hands[0], 8, 8, skin), ellipse('right hand', *hands[1], 8, 8, skin),
        path('legs', [(-12, 69), (-18, 100), (18, 100), (12, 69)], navy, 12),
      ]
    layers.append(shape_layer('modest gender-neutral figure', figure, 2, 2))
    # water cues show the relevant action without depicting excessive water.
    if kind in {'wash_hands','rinse_mouth','rinse_nose','wash_face','wash_arms','wipe_head_ears','wash_feet'}:
      for i, x in enumerate((-65, -48, 51, 67)):
        layers.append(shape_layer('water droplet', [ellipse('drop', x, -5 + (i % 2) * 18, 4, 8, water)], 3 + i, 12))
    if kind in {'bowing','prostration','second_prostration','sitting_between_prostrations','tashahhud'}:
      layers.append(shape_layer('prayer mat', [rect('woven mat', 0, 108, 130, 9, 4, [teal[0],teal[1],teal[2],.38])], 9))
    return {'v':'5.7.4','fr':30,'ip':0,'op':72,'w':360,'h':360,'nm':'Worship step flat illustration',
            'ddd':0,'assets':[],'layers':layers,'markers':[]}


WUDU = ['intention','wash_hands','rinse_mouth','rinse_nose','wash_face','wash_arms','wipe_head_ears','wash_feet']
SALAH = ['opening_takbir','standing_recitation','bowing','rise_from_bowing','prostration','sitting_between_prostrations','second_prostration','tashahhud','taslim']
for folder, names in [('wudu', WUDU), ('salah', SALAH)]:
    target = ROOT / folder
    target.mkdir(parents=True, exist_ok=True)
    for name in names:
        (target / f'{name}.json').write_text(json.dumps(scene(name), separators=(',', ':')), encoding='utf-8')
