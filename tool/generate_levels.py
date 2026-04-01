#!/usr/bin/env python3
#!/usr/bin/env python3
import json
from pathlib import Path

ROOT_DIR = Path(__file__).resolve().parent.parent
LEVEL_DIR = ROOT_DIR / "assets" / "levels"


def build_snake_path(size: int, start_left: bool):
    rows = [["#"] * size for _ in range(size)]
    path = []
    current_col = 1 if start_left else size - 2
    horizontal_rows = list(range(size - 2, 0, -2))

    for i, row in enumerate(horizontal_rows):
        heading_right = (i % 2 == 0) == start_left
        if heading_right:
            target_options = [size - 2, max(2, size - 4), size - 3]
        else:
            target_options = [1, min(size - 3, 3), 2]
        target_col = target_options[i % len(target_options)]

        step = 1 if target_col >= current_col else -1
        for col in range(current_col, target_col + step, step):
            if not path or path[-1] != (row, col):
                path.append((row, col))

        current_col = target_col

        connector_row = row - 1
        if connector_row >= 1:
            path.append((connector_row, current_col))

    for row, col in path:
        rows[row][col] = "."

    start = path[0]
    goal = path[-1]
    rows[start[0]][start[1]] = "S"
    rows[goal[0]][goal[1]] = "G"
    return rows, path


def add_alcoves(rows, path, count):
    size = len(rows)
    used = []

    for index in range(2, len(path) - 2):
        if len(used) >= count:
            break
        if any(abs(index - other) < 4 for other in used):
            continue

        prev_cell = path[index - 1]
        cell = path[index]
        next_cell = path[index + 1]

        if prev_cell[0] == next_cell[0]:
            candidates = [(cell[0] - 1, cell[1]), (cell[0] + 1, cell[1])]
        elif prev_cell[1] == next_cell[1]:
            candidates = [(cell[0], cell[1] - 1), (cell[0], cell[1] + 1)]
        else:
            continue

        for rr, cc in candidates:
            if not (1 <= rr < size - 1 and 1 <= cc < size - 1):
                continue
            if rows[rr][cc] != "#":
                continue
            rows[rr][cc] = "."
            used.append(index)
            break


def choose_gate_positions(path, gate_count):
    usable = []
    for index in range(1, len(path) - 1):
        prev_row, prev_col = path[index - 1]
        row, col = path[index]
        next_row, next_col = path[index + 1]
        prev_delta = (row - prev_row, col - prev_col)
        next_delta = (next_row - row, next_col - col)
        if prev_delta != next_delta:
            usable.append(path[index])

    if len(usable) < gate_count:
        usable = path[2:-2]

    if gate_count >= len(usable):
        return usable[:gate_count]

    positions = []
    chosen_cells = []

    for gate_index in range(gate_count):
        target = round((gate_index + 1) * len(usable) / (gate_count + 1))
        target = max(0, min(len(usable) - 1, target))

        candidate_order = list(range(target, len(usable))) + list(range(target - 1, -1, -1))
        chosen_index = None
        for candidate in candidate_order:
            if any(abs(candidate - other) < 1 for other in positions):
                continue
            chosen_index = candidate
            break

        if chosen_index is None:
            chosen_index = next(
                candidate for candidate in range(len(usable)) if candidate not in positions
            )

        positions.append(chosen_index)
        chosen_cells.append(usable[chosen_index])

    return chosen_cells


def par_for_sequence(sequence: str):
    rotation = 0
    total = 0
    target_map = {"N": 0, "E": 90, "T": 180, "W": 270}

    for gate in sequence:
        target = target_map[gate]
        delta = abs(rotation - target) % 360
        total += min(delta // 90, (360 - delta) // 90)
        rotation = target
    return total


def make_level(level_id, name, hint, size, gate_code, start_left, alcoves):
    rows, path = build_snake_path(size, start_left=start_left)
    add_alcoves(rows, path, alcoves)

    for gate, (row, col) in zip(gate_code, choose_gate_positions(path, len(gate_code))):
        rows[row][col] = gate

    return {
        "id": level_id,
        "name": name,
        "hint": hint,
        "parRotations": par_for_sequence(gate_code),
        "rows": ["".join(row) for row in rows],
    }


def tutorial_level():
    return {
        "id": "level_00_tutorial",
        "name": "Tutorial: First Shift",
        "hint": "Rotate once to open the gate, then finish.",
        "parRotations": 1,
        "rows": [
            "#####",
            "S.E.G",
            "#####",
            "#####",
            "#####",
        ],
    }


def level_specs():
    return [
        ("level_01", "Forked Entry", "One turn opens the first choke point. Stay on the corridor.", 6, "E", True, 0),
        ("level_02", "Back Corner", "Rotate the other way this time. The route is tighter now.", 6, "W", False, 0),
        ("level_03", "Twin Corridors", "Two gates, two rotations. Don’t spend them too early.", 7, "ET", True, 0),
        ("level_04", "Cross Current", "The route doubles back. Set the next gate before the bend.", 7, "WT", False, 0),
        ("level_05", "Gatehouse", "Three gates along one weave. Read the full chain before moving.", 8, "ETW", True, 0),
        ("level_06", "Backtrack Bloom", "No wasted space here. Every bend exists for the sequence.", 8, "WTE", False, 0),
        ("level_07", "Split Decision", "The corridor is longer now. Think about gate three from gate one.", 9, "ETE", True, 0),
        ("level_08", "Full Cycle", "This route needs the full orientation loop to stay open.", 9, "ETWN", False, 0),
        ("level_09", "Broken Ring", "A long weave with one correct rhythm. Guessing won’t get you through.", 9, "WTNW", True, 0),
        ("level_10", "Drift Maze", "The weave is longer, not wider. Keep your rotation state under control.", 10, "ETWN", False, 0),
        ("level_11", "Pressure Lanes", "Five rotations minimum. Count the whole sequence before you commit.", 10, "ETWNE", True, 0),
        ("level_12", "Pinwheel", "The gates keep shifting demands. Recovering late is expensive.", 10, "WTNWE", False, 0),
        ("level_13", "Offset Spiral", "The route is strict enough that one sloppy turn echoes forward.", 11, "ETWNE", True, 0),
        ("level_14", "Labyrinth Shift", "A longer corridor with very little forgiveness in the sequence.", 11, "ETWNET", False, 0),
        ("level_15", "Final Convergence", "A final long-form chain. Read the entire path before the first move.", 11, "TEWN", True, 0),
    ]


def main():
    levels = [tutorial_level()]
    index = ["assets/levels/level_00_tutorial.json"]

    for level_id, name, hint, size, gate_code, start_left, alcoves in level_specs():
        levels.append(make_level(level_id, name, hint, size, gate_code, start_left, alcoves))
        index.append(f"assets/levels/{level_id}.json")

    for level in levels:
        path = LEVEL_DIR / f"{level['id']}.json"
        path.write_text(json.dumps(level, indent=2) + "\n")

    (LEVEL_DIR / "index.json").write_text(json.dumps({"levels": index}, indent=2) + "\n")


if __name__ == "__main__":
    main()
