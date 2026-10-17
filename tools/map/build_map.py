#!/usr/bin/env python3
"""Builds data/map/lands.json from Natural Earth admin-1 boundaries (prototyp-plan.md section 8).

One-off tool; the game itself does not need Python. Uses only the standard library.

Source data (public domain, no attribution required):
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/v5.1.2/geojson/ne_10m_admin_1_states_provinces.geojson
  SHA-256 22d0e3ad85eb3e27f17cabf8ba2d50e554fbc27a87796ff891d958185da62fb5

Usage:
  python3 -I tools/map/build_map.py <ne_10m_admin_1_states_provinces.geojson> [output.json]

The output contains the 16 lands as simplified polygons in a projected plane
(width 1000 units, y pointing down) and the institutions from tools/map/places.json
projected into the same plane.
"""

import json
import math
import pathlib
import sys

WIDTH = 1000.0
# Reference latitude of the equirectangular projection, roughly the centre of Germany.
REFERENCE_LATITUDE = 51.0
# Douglas-Peucker tolerance in output units; 1.0 keeps the shapes recognizable at small size.
SIMPLIFY_TOLERANCE = 1.0
# Rings smaller than this area (output units squared) are dropped (tiny islands).
MIN_RING_AREA = 3.0
SCRIPT_DIR = pathlib.Path(__file__).resolve().parent
DEFAULT_OUTPUT = SCRIPT_DIR.parent.parent / "data" / "map" / "lands.json"


def german_lands(geojson):
    """Returns {land id: list of exterior rings as (lon, lat) lists} for the 16 German lands."""
    lands = {}
    for feature in geojson["features"]:
        properties = feature["properties"]
        if properties.get("adm0_a3") != "DEU":
            continue
        land_id = "land." + properties["iso_3166_2"].split("-")[1].lower()
        geometry = feature["geometry"]
        polygons = geometry["coordinates"] if geometry["type"] == "MultiPolygon" else [geometry["coordinates"]]
        # Holes are ignored: lands are drawn and hit-tested smallest first, so a land
        # inside another (Berlin in Brandenburg) still wins.
        lands[land_id] = [polygon[0] for polygon in polygons]
    if len(lands) != 16:
        raise SystemExit(f"Expected 16 German lands, found {len(lands)}")
    return lands


def make_projection(lands):
    """Returns a function mapping (lon, lat) to the output plane, and the plane's height."""
    points = [point for rings in lands.values() for ring in rings for point in ring]
    min_lon = min(p[0] for p in points)
    max_lon = max(p[0] for p in points)
    min_lat = min(p[1] for p in points)
    max_lat = max(p[1] for p in points)
    x_factor = math.cos(math.radians(REFERENCE_LATITUDE))
    scale = WIDTH / ((max_lon - min_lon) * x_factor)

    def project(lon, lat):
        return ((lon - min_lon) * x_factor * scale, (max_lat - lat) * scale)

    return project, (max_lat - min_lat) * scale


def simplify(points, tolerance):
    """Douglas-Peucker simplification of an open polyline."""
    if len(points) < 3:
        return points
    start, end = points[0], points[-1]
    max_distance, index = 0.0, 0
    for i in range(1, len(points) - 1):
        distance = point_line_distance(points[i], start, end)
        if distance > max_distance:
            max_distance, index = distance, i
    if max_distance <= tolerance:
        return [start, end]
    left = simplify(points[: index + 1], tolerance)
    right = simplify(points[index:], tolerance)
    return left[:-1] + right


def point_line_distance(point, start, end):
    dx, dy = end[0] - start[0], end[1] - start[1]
    if dx == 0 and dy == 0:
        return math.dist(point, start)
    return abs(dy * point[0] - dx * point[1] + end[0] * start[1] - end[1] * start[0]) / math.hypot(dx, dy)


def ring_area(points):
    return abs(sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(points, points[1:] + points[:1]))) / 2.0


def simplify_ring(ring):
    """Simplifies a closed ring by splitting it at its farthest point from the start."""
    if ring[0] == ring[-1]:
        ring = ring[:-1]
    far = max(range(len(ring)), key=lambda i: math.dist(ring[0], ring[i]))
    first = simplify(ring[: far + 1], SIMPLIFY_TOLERANCE)
    second = simplify(ring[far:] + [ring[0]], SIMPLIFY_TOLERANCE)
    return first[:-1] + second[:-1]


def main():
    if len(sys.argv) not in (2, 3):
        raise SystemExit(__doc__)
    source = pathlib.Path(sys.argv[1])
    output = pathlib.Path(sys.argv[2]) if len(sys.argv) == 3 else DEFAULT_OUTPUT
    lands = german_lands(json.loads(source.read_text(encoding="utf-8")))
    project, height = make_projection(lands)
    result_lands = {}
    for land_id in sorted(lands):
        rings = []
        for ring in lands[land_id]:
            simplified = simplify_ring([project(lon, lat) for lon, lat in ring])
            if len(simplified) >= 3 and ring_area(simplified) >= MIN_RING_AREA:
                rings.append([round(value, 1) for point in simplified for value in point])
        result_lands[land_id] = rings
    places = json.loads((SCRIPT_DIR / "places.json").read_text(encoding="utf-8"))
    result_places = {
        place_id: [round(value, 1) for value in project(place["lon"], place["lat"])]
        for place_id, place in sorted(places.items())
    }
    result = {
        "source": "Natural Earth 1:10m admin-1 states and provinces v5.1.2 (public domain)",
        "width": WIDTH,
        "height": round(height, 1),
        "lands": result_lands,
        "places": result_places,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    points = sum(len(ring) // 2 for rings in result_lands.values() for ring in rings)
    print(f"Wrote {output} with {points} points in {len(result_lands)} lands, height {result['height']}")


if __name__ == "__main__":
    main()
