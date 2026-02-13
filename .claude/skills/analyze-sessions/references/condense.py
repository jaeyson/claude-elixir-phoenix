#!/usr/bin/env python3
"""
Condense analysis reports into key sections for synthesis.

Usage:
    python3 condense.py <reports-dir> <output-file>
"""
import os
import re
import json
import sys

TARGET_SECTIONS = [
    "Pain Points",
    "Plugin Opportunities",
    "Workflow Patterns",
    "Tool Usage",
    "Key Observations",
    "Recommendations",
]


def extract_sections(content, filename):
    """Extract target sections from a report."""
    sections = {}
    current_section = None
    current_lines = []

    for line in content.split('\n'):
        header_match = re.match(r'^#{1,3}\s+(.+)', line)
        if header_match:
            header_text = header_match.group(1).strip()
            matched = None
            for target in TARGET_SECTIONS:
                if target.lower() in header_text.lower():
                    matched = target
                    break

            if matched:
                if current_section and current_lines:
                    sections[current_section] = '\n'.join(current_lines).strip()
                current_section = matched
                current_lines = []
                continue
            elif current_section:
                if current_lines:
                    sections[current_section] = '\n'.join(current_lines).strip()
                current_section = None
                current_lines = []
                continue

        if current_section:
            current_lines.append(line)

    if current_section and current_lines:
        sections[current_section] = '\n'.join(current_lines).strip()

    return sections


def get_project_from_filename(filename):
    """Extract project name from report filename."""
    parts = filename.replace('analysis_', '').replace('.md', '')
    match = re.match(r'^([a-z_-]+?)_(?:[0-9a-f]{8,}|group\d+|small_batch\w+)$', parts)
    if match:
        return match.group(1)
    if 'batch' in parts:
        return 'mixed'
    return 'unknown'


def condense(reports_dir, output_file):
    """Process all reports and write condensed output."""
    by_project = {}
    total_reports = 0
    total_sections = 0

    for filename in sorted(os.listdir(reports_dir)):
        if not filename.endswith('.md'):
            continue

        filepath = os.path.join(reports_dir, filename)
        with open(filepath, 'r') as f:
            content = f.read()

        sections = extract_sections(content, filename)
        if not sections:
            continue

        project = get_project_from_filename(filename)
        if project not in by_project:
            by_project[project] = []

        by_project[project].append({
            'filename': filename,
            'sections': sections
        })
        total_reports += 1
        total_sections += len(sections)

    with open(output_file, 'w') as f:
        f.write(f"# Condensed Analysis\n\n")
        f.write(f"**Reports processed**: {total_reports}\n")
        f.write(f"**Sections extracted**: {total_sections}\n")
        f.write(f"**Projects**: {', '.join(sorted(by_project.keys()))}\n\n")

        for project in sorted(by_project.keys()):
            reports = by_project[project]
            f.write(f"---\n\n## Project: {project} ({len(reports)} sessions)\n\n")

            for target in TARGET_SECTIONS:
                entries = []
                for report in reports:
                    if target in report['sections']:
                        entries.append((report['filename'], report['sections'][target]))

                if entries:
                    f.write(f"### {target} ({len(entries)} reports)\n\n")
                    for fname, content in entries:
                        if len(content) > 800:
                            content = content[:800] + "\n[...truncated]"
                        f.write(f"**{fname}**:\n{content}\n\n")

    print(f"Condensed {total_reports} reports into {output_file}")
    print(f"Projects: {json.dumps({k: len(v) for k, v in by_project.items()}, indent=2)}")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 condense.py <reports-dir> <output-file>")
        sys.exit(1)

    condense(sys.argv[1], sys.argv[2])
