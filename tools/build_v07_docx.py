#!/usr/bin/env python3
"""Build the v0.5 narrative rewrite using the v0.3 Word styles as a template."""
from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = Path("/Users/shiqi/Desktop/盐月旅馆_剧情改写_v0.3_序章与前两夜(1).docx")
SRC = ROOT / "游戏文本" / "10_剧情改写_v0.7_玩家视角_序章与第一夜.md"
OUT = ROOT / "游戏文本" / "盐月旅馆_剧情改写_v0.7_玩家视角_序章与第一夜.docx"

INK = RGBColor(0x33, 0x44, 0x3D)
BROWN = RGBColor(0x6C, 0x58, 0x48)
MUTED = RGBColor(0x82, 0x7E, 0x73)
BODY = RGBColor(0x2E, 0x30, 0x2C)


def set_run_font(run, name, size=None, bold=None, color=None):
    run.font.name = name
    if size is not None:
        run.font.size = Pt(size)
    if bold is not None:
        run.font.bold = bold
    if color is not None:
        run.font.color.rgb = color
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), name)
    rfonts.set(qn("w:hAnsi"), name)
    rfonts.set(qn("w:eastAsia"), name)


def clear_body(doc):
    body = doc.element.body
    for child in list(body):
        if child.tag == qn("w:sectPr"):
            continue
        body.remove(child)


def add_page_field(paragraph):
    run = paragraph.add_run()
    set_run_font(run, "Noto Sans CJK SC", 8.5, False, MUTED)
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.append(begin)
    run._r.append(instr)
    run._r.append(end)


def setup_header_footer(doc):
    section = doc.sections[0]
    header = section.header.paragraphs[0]
    header.text = ""
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = header.add_run("盐月旅馆  /  剧情文案 v0.7")
    set_run_font(r, "Noto Sans CJK SC", 8.5, False, MUTED)

    footer = section.footer.paragraphs[0]
    footer.text = ""
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = footer.add_run("THE SALT MOON HOTEL   ·   ")
    set_run_font(r, "Noto Sans CJK SC", 8.5, False, MUTED)
    add_page_field(footer)


def add_cover(doc):
    for _ in range(5):
        doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("盐月旅馆")
    set_run_font(r, "Noto Sans CJK SC", 32, True, INK)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("THE SALT MOON HOTEL")
    set_run_font(r, "Noto Sans CJK SC", 12, False, RGBColor(0x7D, 0x6C, 0x5A))

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(18)
    r = p.add_run("剧情改写 v0.7")
    set_run_font(r, "Noto Sans CJK SC", 17, False, BROWN)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    r = p.add_run("序章 · 第一夜")
    set_run_font(r, "Noto Serif CJK SC", 12, False, RGBColor(0x50, 0x53, 0x4C))

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(18)
    r = p.add_run("2D 超现实悬疑冒险｜玩家视角叙事底稿")
    set_run_font(r, "Noto Serif CJK SC", 10, False, MUTED)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("少对白 · 重环境 · 由物件与行动传递故事")
    set_run_font(r, "Noto Serif CJK SC", 10, False, MUTED)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("玩家即主人公 · 不出现主人公形象/配音")
    set_run_font(r, "Noto Serif CJK SC", 10, False, MUTED)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(50)
    r = p.add_run("潮水退去时，别忘了数一数家里的人。")
    set_run_font(r, "Noto Serif CJK SC", 12, False, BROWN)

    doc.add_page_break()


def add_h1(doc, text, page_break=True):
    if page_break:
        doc.add_page_break()
    p = doc.add_paragraph(style="Heading 1")
    r = p.add_run(text)
    set_run_font(r, "Noto Serif CJK SC", 19, True, INK)


def add_h2(doc, text):
    p = doc.add_paragraph(style="Heading 2")
    r = p.add_run(text)
    set_run_font(r, "Noto Serif CJK SC", 14, True, BROWN)


def add_body(doc, text):
    p = doc.add_paragraph(style="Normal")
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.3
    # Inline bold for the "改写说明" numbered points
    parts = re.split(r"(\*\*.*?\*\*)", text)
    if len(parts) == 1:
        r = p.add_run(text)
        set_run_font(r, "Noto Serif CJK SC", 10.5, False, BODY)
    else:
        for part in parts:
            if not part:
                continue
            if part.startswith("**") and part.endswith("**"):
                r = p.add_run(part[2:-2])
                set_run_font(r, "Noto Serif CJK SC", 10.5, True, INK)
            else:
                r = p.add_run(part)
                set_run_font(r, "Noto Serif CJK SC", 10.5, False, BODY)


def add_quote(doc, lines):
    for line in lines:
        p = doc.add_paragraph(style="Story Quote")
        p.paragraph_format.line_spacing = 1.3
        p.paragraph_format.space_before = Pt(4)
        p.paragraph_format.space_after = Pt(8)
        r = p.add_run(line)
        set_run_font(r, "Noto Serif CJK SC", 10, False, RGBColor(0x67, 0x5D, 0x4F))


def parse_and_add(doc, text):
    lines = text.splitlines()
    # Start at the first chapter heading; cover is built separately.
    start = 0
    for i, line in enumerate(lines):
        if line.startswith("# 序章"):
            start = i
            break
    lines = lines[start:]

    i = 0
    first_h1 = True
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip():
            i += 1
            continue
        if line == "---":
            i += 1
            continue
        if line.startswith("# ") and not line.startswith("## "):
            add_h1(doc, line[2:].strip(), page_break=not first_h1)
            first_h1 = False
            i += 1
            continue
        if line.startswith("## "):
            add_h2(doc, line[3:].strip())
            i += 1
            continue
        if line.startswith("### "):
            # Subtitle lines are only in the cover block, but keep safe.
            p = doc.add_paragraph(style="Normal")
            r = p.add_run(line[4:].strip())
            set_run_font(r, "Noto Serif CJK SC", 11, False, MUTED)
            i += 1
            continue
        if line.startswith(">"):
            qlines = []
            while i < len(lines) and lines[i].lstrip().startswith(">"):
                q = lines[i].lstrip()[1:].strip()
                if q:
                    qlines.append(q)
                i += 1
            add_quote(doc, qlines)
            continue
        add_body(doc, line.strip())
        i += 1


def main():
    doc = Document(TEMPLATE)
    clear_body(doc)
    setup_header_footer(doc)
    doc.core_properties.title = "盐月旅馆｜剧情改写 v0.7：序章与第一夜"
    doc.core_properties.subject = "玩家视角叙事底稿：序章与第一夜"
    doc.core_properties.author = "DeepSeek Harness"
    doc.core_properties.comments = "v0.7；玩家视角，不出现主人公形象与配音；序章止于进入旅馆"

    add_cover(doc)
    text = SRC.read_text(encoding="utf-8")
    parse_and_add(doc, text)
    doc.save(OUT)
    print(f"saved {OUT}")


if __name__ == "__main__":
    main()
