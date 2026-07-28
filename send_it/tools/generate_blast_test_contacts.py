#!/usr/bin/env python3
"""Generate mock contacts and Blast JSON payloads for scale testing.

Uses NANP fictional numbers +1-555-0100 through +1-555-0299 (safe for testing).

Examples:
  python tools/generate_blast_test_contacts.py vcf -o tools/fixtures/blast_test_200.vcf
  python tools/generate_blast_test_contacts.py vcf --count 50 -o tools/fixtures/blast_test_50.vcf
  python tools/generate_blast_test_contacts.py payload --count 200 -o tools/fixtures/payload_200.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# NANP 555-01XX is reserved for fictional use.
_BASE_NUMBER = 100
_MAX_NUMBER = 299


def _phone_for_index(index: int) -> str:
    number = _BASE_NUMBER + index
    if number > _MAX_NUMBER:
        raise ValueError(
            f"index {index} exceeds fictional range "
            f"(+155501{_BASE_NUMBER:02d} – +1555{_MAX_NUMBER:02d})"
        )
    return f"+1555{number:04d}"


def _display_name(index: int) -> str:
    # First token becomes {firstname} in the app (displayName.split(' ').first).
    return f"Scale{index + 1:03d} Tester"


def generate_vcf(count: int) -> str:
    cards: list[str] = []
    for i in range(count):
        name = _display_name(i)
        phone = _phone_for_index(i)
        # Split for N: Family;Given;Additional;Prefix;Suffix
        cards.append(
            "\n".join(
                [
                    "BEGIN:VCARD",
                    "VERSION:3.0",
                    f"FN:{name}",
                    f"N:Contact;Test;{i + 1:03d};;",
                    f"TEL;TYPE=CELL:{phone}",
                    "END:VCARD",
                ]
            )
        )
    return "\n".join(cards) + "\n"


def generate_payload(
    count: int,
    *,
    message_template: str = "Hi {firstname}, scale test.",
    include_media: bool = False,
    media_file: str = "blast_media.jpg",
) -> list[dict[str, str]]:
    items: list[dict[str, str]] = []
    for i in range(count):
        name = _display_name(i)
        first_name = name.split(" ")[0]
        message = message_template.replace("{firstname}", first_name)
        item: dict[str, str] = {
            "number": _phone_for_index(i),
            "message": message,
        }
        if include_media:
            item["mediaFile"] = media_file
        items.append(item)
    return items


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    vcf = sub.add_parser("vcf", help="Write a .vcf contact import file")
    vcf.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("tools/fixtures/blast_test_200.vcf"),
        help="Output .vcf path",
    )
    vcf.add_argument(
        "--count",
        type=int,
        default=200,
        help="Number of contacts (default: 200)",
    )

    payload = sub.add_parser("payload", help="Write a Blast JSON payload file")
    payload.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("tools/fixtures/payload_200.json"),
        help="Output .json path",
    )
    payload.add_argument("--count", type=int, default=200, help="Recipient count")
    payload.add_argument(
        "--message",
        default="Hi {firstname}, scale test.",
        help="Message template (supports {firstname})",
    )
    payload.add_argument(
        "--media",
        action="store_true",
        help="Include mediaFile key in each item",
    )

    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(argv or sys.argv[1:])

    if args.command == "vcf":
        if args.count < 1:
            print("count must be >= 1", file=sys.stderr)
            return 1
        content = generate_vcf(args.count)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(content, encoding="utf-8")
        print(f"Wrote {args.count} contacts to {args.output}")
        return 0

    if args.command == "payload":
        if args.count < 1:
            print("count must be >= 1", file=sys.stderr)
            return 1
        data = generate_payload(
            args.count,
            message_template=args.message,
            include_media=args.media,
        )
        args.output.parent.mkdir(parents=True, exist_ok=True)
        encoded = json.dumps(data, ensure_ascii=False)
        args.output.write_text(encoded, encoding="utf-8")
        print(
            f"Wrote {args.count}-recipient payload to {args.output} "
            f"({len(encoded.encode('utf-8'))} bytes)"
        )
        return 0

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
