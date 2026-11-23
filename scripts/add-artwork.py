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

POSITIONS = [
    (608, 699), (648, 699), (724.5, 699), (763.5, 699),
    (802.5, 699), (841.5, 699), (880.5, 699), (959, 699),
    (413.5, 9), (452.5, 9),
]


def rectangle(x, y, size):
    return round(x, 3), round(y, 3), round(x + size, 3), round(y + size, 3)


def wordmark():
    for index, letter in enumerate("PROMETHEUS LITE"):
        for row, bits in enumerate(GLYPHS[letter]):
            for column in range(5):
                if bits & (16 >> column):
                    x = 497.22 + index * 38.87 + column * 4.8
                    y = 9 + (6 - row) * 4.8
                    yield rectangle(x, y, 4.15)


def artwork(path, x, y):
    with Image.open(path) as image:
        alpha = image.convert('RGBA').getchannel('A')
    for row in range(alpha.height):
        for column in range(alpha.width):
            if alpha.getpixel((column, row)) >= 128:
                left = x + column * 1.7 + 0.25
                bottom = y + (alpha.height - 1 - row) * 1.7 + 0.25
                yield rectangle(left, bottom, 1.2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('gds', type=Path)
    args = parser.parse_args()

    library = gdstk.read_gds(args.gds)
    top, = library.top_level()
    (x1, y1), (x2, y2) = top.bounding_box()
    obstacles = [polygon.bounding_box() for polygon in top.get_polygons(layer=46, datatype=0)]
    assets = Path(__file__).resolve().parents[1] / 'artwork'
    designs = [('prometheus_lite_wordmark', wordmark())]
    for index, (x, y) in enumerate(POSITIONS, 1):
        designs.append((f'prometheus_art_{index:02}', artwork(assets / f'approved_{index:02}.png', x, y)))

    for name, rectangles in designs:
        cell = library.new_cell(name)
        for left, bottom, right, upper in rectangles:
            if not (x1 < left < right < x2 and y1 < bottom < upper < y2):
                raise SystemExit(f'{name} is outside the die')
            if any(left < r + 1 and right > l - 1 and bottom < t + 1 and upper > b - 1
                   for (l, b), (r, t) in obstacles):
                raise SystemExit(f'{name} is too close to Metal4 at ({left}, {bottom})')
            cell.add(gdstk.rectangle((left, bottom), (right, upper), layer=46, datatype=0))
        top.add(gdstk.Reference(cell))

    temporary = args.gds.with_suffix('.tmp.gds')
    library.write_gds(temporary)
    temporary.replace(args.gds)


if __name__ == '__main__':
    main()
