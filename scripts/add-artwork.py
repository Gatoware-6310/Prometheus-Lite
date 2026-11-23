import argparse
from pathlib import Path

import gdstk
from PIL import Image


GLYPHS = {
    'P': [30, 17, 17, 30, 16, 16, 16],
    'R': [30, 17, 17, 30, 20, 18, 17],
    'O': [14, 17, 17, 17, 17, 17, 14],
    'M': [17, 27, 21, 21, 17, 17, 17],
    'E': [31, 16, 16, 30, 16, 16, 31],
    'T': [31, 4, 4, 4, 4, 4, 4],
    'H': [17, 17, 17, 31, 17, 17, 17],
    'U': [17, 17, 17, 17, 17, 17, 14],
    'S': [15, 16, 16, 14, 1, 1, 30],
    'L': [16, 16, 16, 16, 16, 16, 31],
    'I': [31, 4, 4, 4, 4, 4, 31],
    ' ': [0] * 7,
}

TOP_ART = (1, 2, 3, 4, 5, 6, 7, 8, 11, 12, 13, 14)
CELL_PREFIX = 'gf180mcu_fd_sc_mcu7t5v0__'


def rectangle(x, y, width, height):
    return tuple(round(v, 3) for v in (x, y, x + width, y + height))


def image_pixels(path):
    with Image.open(path) as image:
        alpha = image.convert('RGBA').getchannel('A')
    return [(x, alpha.height - 1 - y) for y in range(alpha.height)
            for x in range(alpha.width) if alpha.getpixel((x, y)) >= 128]


def draw(pixels, x, y, pitch_x, pitch_y, gap):
    return [rectangle(x + dx * pitch_x, y + dy * pitch_y, pitch_x - gap, pitch_y - gap)
            for dx, dy in pixels]


def layout(top, assets):
    (x1, y1), (x2, y2) = top.bounding_box()
    obstacles = {}
    for polygon in top.get_polygons(layer=46, datatype=0):
        add_obstacle(obstacles, polygon.bounding_box(), 1)
    for ref in top.references:
        name = ref.cell_name.removeprefix(CELL_PREFIX)
        if name != ref.cell_name and not name.startswith(('fill', 'endcap', 'tap')):
            add_obstacle(obstacles, ref.bounding_box(), 0.5)

    def clear(box):
        left, bottom, right, upper = box
        if not (x1 + 4 < left and y1 + 4 < bottom and right < x2 - 4 and upper < y2 - 4):
            return False
        return not any(left < r and right > l and bottom < t and upper > b
                       for col in range(int(left // 40), int(right // 40) + 1)
                       for l, b, r, t in obstacles.get(col, ()))

    mask = {i: image_pixels(assets / f'approved_{i:02}.png') for i in range(1, 15)}
    letters = [[(col, 6-row) for row, bits in enumerate(GLYPHS[letter])
                for col in range(5) if bits & (16 >> col)]
               for letter in 'PROMETHEUS LITE']
    bottom = None
    for pitch_x, pitch_y in ((5.2, 6.6), (4.8, 6.6), (4.4, 6.6), (4, 6.6), (3.6, 6.6), (5.2, 6), (4.8, 6),
                             (4.4, 6), (5.6, 5.6), (5.2, 5.2), (4.8, 4.8), (4.4, 4.4)):
        for y in range(8, 31, 2):
            for anchor in range(480, 500, 2):
                shapes = []
                for i, pixels in enumerate(letters):
                    target = anchor + 38.87 * i
                    right_edge = max((r[2] for r in shapes), default=0)
                    glyph = None
                    for dx in (0, -2, 2, -4, 4, -6, 6, -8, 8, -10, 10, -12, 12, -14, 14, -16, 16):
                        rectangles = draw(pixels, target + dx, y, pitch_x, pitch_y, .42)
                        if (not rectangles or min(r[0] for r in rectangles) > right_edge + .42) and all(map(clear, rectangles)):
                            glyph = rectangles
                            break
                    if glyph is None:
                        break
                    shapes.extend(glyph)
                else:
                    icons = []
                    left_edge = min(r[0] for r in shapes)
                    for idx in (10, 9):
                        icon = find_icon(mask[idx], (left_edge-89, y-3, left_edge-4, y+48),
                                         (left_edge-18, y+16), clear)
                        if icon is None:
                            break
                        icons.append((f'prometheus_art_{idx:02}', icon))
                        left_edge = min(r[0] for r in icon)
                    else:
                        bottom = [('prometheus_lite_wordmark', shapes), *icons]
                        break
            if bottom:
                break
        if bottom:
            break
    if bottom is None:
        raise SystemExit('No clear placement for the wordmark')

    designs = list(bottom)
    for row in range(2):
        for col in range(6):
            idx = TOP_ART[row * 6 + col]
            left = 790 + col * 46
            bottom_edge = 678 - row * 53
            target = (left+15, bottom_edge+24)
            icon = find_icon(mask[idx], (left-8, bottom_edge, left+38, bottom_edge+50), target, clear)
            if icon is None:
                icon = find_icon(mask[idx], (748, 600, 1068, 730), target, clear)
            if icon is None:
                raise SystemExit(f'No clear placement for artwork {idx:02}')
            designs.append((f'prometheus_art_{idx:02}', icon))
            add_obstacle(obstacles, ((min(r[0] for r in icon), min(r[1] for r in icon)),
                                     (max(r[2] for r in icon), max(r[3] for r in icon))), 3)
    return designs


def add_obstacle(obstacles, bounds, clearance):
    (l, b), (r, t) = bounds
    box = (l - clearance, b - clearance, r + clearance, t + clearance)
    for col in range(int(box[0] // 40), int(box[2] // 40) + 1):
        obstacles.setdefault(col, []).append(box)


def find_icon(pixels, bounds, target, clear):
    left, bottom, right, upper = bounds
    for pitch_x, pitch_y in ((1.8, 2.5), (1.75, 2.3), (1.65, 2), (1.5, 1.75), (1.35, 1.5)):
        width = (max(x for x, _ in pixels) + 1) * pitch_x
        height = (max(y for _, y in pixels) + 1) * pitch_y
        origins = sorted(((x, y) for x in range(round(left), int(right-width)+1)
                          for y in range(round(bottom), int(upper-height)+1)),
                         key=lambda p: abs(p[0]+width/2-target[0]) + abs(p[1]+height/2-target[1]))
        for x, y in origins:
            shapes = draw(pixels, x, y, pitch_x, pitch_y, .42)
            if all(map(clear, shapes)):
                return shapes


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('gds', type=Path)
    args = parser.parse_args()

    library = gdstk.read_gds(args.gds)
    top, = library.top_level()
    assets = Path(__file__).resolve().parents[1] / 'artwork'
    for name, shapes in layout(top, assets):
        cell = library.new_cell(name)
        for left, bottom, right, upper in shapes:
            cell.add(gdstk.rectangle((left, bottom), (right, upper), layer=46, datatype=0))
        top.add(gdstk.Reference(cell))

    temporary = args.gds.with_suffix('.tmp.gds')
    library.write_gds(temporary)
    temporary.replace(args.gds)


if __name__ == '__main__':
    main()
