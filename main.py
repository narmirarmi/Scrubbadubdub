#!/usr/bin/env python3
"""

"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def ensure_exiftool() -> None:
    if shutil.which("exiftool") is None:
        sys.exit("Error: exiftool not found. Install it from https://exiftool.org/.")


def scrub(path: Path, *, overwrite: bool) -> None:
    cmd: list[str] = ["exiftool", "-all="]
    if overwrite:
        cmd.append("-overwrite_original")
    else:
        clean = path.with_name(f"{path.stem}_clean{path.suffix}")
        cmd.extend(["-o", str(clean)])
    cmd.append(str(path))
    subprocess.run(cmd, check=True)


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Strip metadata tags from specified files."
    )
    parser.add_argument("--files", nargs="+", type=Path, help="Files to clean")
    parser.add_argument(
        "-o",
        "--overwrite",
        action="store_true",
        help="Overwrite originals instead of writing clean copies",
    )
    args = parser.parse_args(argv)

    ensure_exiftool()

    for file_path in args.files:
        if not file_path.is_file():
            print(f"Skipping '{file_path}' (not a file)")
            continue
        print(f"Cleaning {file_path} …")
        try:
            scrub(file_path, overwrite=args.overwrite)
        except subprocess.CalledProcessError as exc:
            print(f"[error] {file_path}: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
