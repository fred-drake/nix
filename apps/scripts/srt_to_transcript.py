#!/usr/bin/env python3
"""Convert rolling-caption SRT files into a plain transcript."""

from __future__ import annotations

import argparse
import re
import sys
import textwrap
from pathlib import Path

TIMESTAMP_RE = re.compile(r"^\d{2}:\d{2}:\d{2},\d{3}\s+-->\s+\d{2}:\d{2}:\d{2},\d{3}")
NUMBER_RE = re.compile(r"^\d+$")


def iter_caption_text(srt_text: str):
    """Yield subtitle text blocks with SRT numbering/timestamps removed."""
    block_lines: list[str] = []

    for raw_line in srt_text.splitlines() + [""]:
        line = raw_line.strip()
        if not line:
            if block_lines:
                text = " ".join(block_lines)
                text = re.sub(r"\s+", " ", text).strip()
                if text:
                    yield text
                block_lines = []
            continue

        if NUMBER_RE.match(line) or TIMESTAMP_RE.match(line):
            continue

        block_lines.append(line)


def append_new_words(transcript_words: list[str], caption: str) -> None:
    """Append only the non-overlapping suffix of a caption."""
    caption_words = caption.split()
    if not caption_words:
        return

    max_overlap = min(len(transcript_words), len(caption_words))
    overlap = 0

    for size in range(max_overlap, 0, -1):
        if transcript_words[-size:] == caption_words[:size]:
            overlap = size
            break

    transcript_words.extend(caption_words[overlap:])


def srt_to_transcript(srt_text: str) -> str:
    """Return a de-duplicated plain transcript from SRT contents."""
    transcript_words: list[str] = []

    for caption in iter_caption_text(srt_text):
        append_new_words(transcript_words, caption)

    return " ".join(transcript_words).strip()


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Convert an SRT file, including rolling captions, to plain transcript text."
    )
    parser.add_argument("srt_file", type=Path, help="Path to the .srt file")
    parser.add_argument(
        "--width",
        type=int,
        default=100,
        help="wrap output to this width; use 0 for one long line (default: 100)",
    )
    args = parser.parse_args(argv)

    transcript = srt_to_transcript(args.srt_file.read_text(encoding="utf-8-sig"))
    if args.width > 0:
        transcript = textwrap.fill(transcript, width=args.width)

    sys.stdout.write(transcript)
    if transcript:
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
