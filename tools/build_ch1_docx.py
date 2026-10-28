#!/usr/bin/env python3
"""Build the Chapter One puzzle-first design document."""
from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Pt, RGBColor

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = Path("/Users/shiqi/Desktop/盐月旅馆_剧情改写_v0.3_序章与前两夜(1).docx")
SRC = ROOT / "游戏文本" / "12_第一章_红线_谜题优先稿.md"
OUT = ROOT / "游戏文本" / "盐月旅馆_第一章_红线_谜题优先稿_v0.1.docx"

INK = RGBColor(0x33, 0x44, 0x3D)
BROWN = RGBColor(0x6C, 0x58, 0x48)
MUTED = RGBColor(0x82, 0x7E, 0x73)
BODY = RGBColor(0x2E, 0x30, 0x2C)
RUST = RGBColor(0xA3, 0x4B, 0x3F)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)
HEADER_FILL = "33443D"
ROW_FILL = "F7F3EA"
BORDER = "D8CDB0"

PAGE_BREAKS = {
    "三、大厅与前台的谜题",
    "四、101 号房",
    "五、走廊与 107",
    "八、文本与声音",
}


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


def shade(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def cell_borders(cell):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.find(qn("w:tcBorders"))
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), "4")
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), BORDER)
        borders.append(el)


def cell_margins(cell, top=50, bottom=50, left=90, right=90):
    tc_pr = cell._tc.get_or_add_tcPr()
    mar = OxmlElement("w:tcMar")
    for side, value in (("top", top), ("bottom", bottom), ("left", left), ("right", right)):
        el = OxmlElement(f"w:{side}")
        el.set(qn("w:w"), str(value))
        el.set(qn("w:type"), "dxa")
        mar.append(el)
    tc_pr.append(mar)


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


def setup(doc):
    sec = doc.sections[0]
    header = sec.header.paragraphs[0]
    header.text = ""
    header.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = header.add_run("盐月旅馆  /  第一章设计稿 v0.1")
    set_run_font(r, "Noto Sans CJK SC", 8.5, False, MUTED)

    footer = sec.footer.paragraphs[0]
    footer.text = ""
    footer.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = footer.add_run("THE SALT MOON HOTEL   ·   ")
    set_run_font(r, "Noto Sans CJK SC", 8.5, False, MUTED)
    add_page_field(footer)

    doc.core_properties.title = "盐月旅馆｜第一章 · 红线：谜题优先稿 v0.1"
    doc.core_properties.subject = "第一章谜题设计、交互文本与 NPC 台词预算"
    doc.core_properties.author = "DeepSeek Harness"
    doc.core_properties.comments = "NPC 只做提示；不写环境音；谜题承担叙事"


def add_cover(doc):
    for _ in range(5):
        doc.add_paragraph()
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("盐月旅馆"); set_run_font(r, "Noto Sans CJK SC", 32, True, INK)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("THE SALT MOON HOTEL"); set_run_font(r, "Noto Sans CJK SC", 12, False, RGBColor(0x7D, 0x6C, 0x5A))
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(18)
    r = p.add_run("第一章 · 红线"); set_run_font(r, "Noto Sans CJK SC", 24, True, BROWN)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(8)
    r = p.add_run("谜题优先稿 v0.1"); set_run_font(r, "Noto Sans CJK SC", 15, False, RUST)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(10)
    r = p.add_run("序章已定稿｜15–20 分钟"); set_run_font(r, "Noto Serif CJK SC", 10.5, False, MUTED)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(38)
    r = p.add_run("NPC 是提示器，不是讲解员。"); set_run_font(r, "Noto Serif CJK SC", 13, False, BROWN)
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("不写环境音。谜题承担叙事。"); set_run_font(r, "Noto Serif CJK SC", 13, False, BROWN)
    doc.add_page_break()


def add_h1(doc, text, break_before=False):
    if break_before:
        doc.add_page_break()
    p = doc.add_paragraph(style="Heading 1")
    r = p.add_run(text); set_run_font(r, "Noto Serif CJK SC", 19, True, INK)


def add_h2(doc, text):
    p = doc.add_paragraph(style="Heading 2")
    r = p.add_run(text); set_run_font(r, "Noto Serif CJK SC", 14, True, BROWN)


def add_h3(doc, text):
    p = doc.add_paragraph(style="Heading 3")
    r = p.add_run(text); set_run_font(r, "Noto Serif CJK SC", 11.5, True, INK)


def add_inline(p, text, size=10.5, color=BODY):
    parts = re.split(r"(\*\*.*?\*\*)", text)
    for part in parts:
        if not part:
            continue
        if part.startswith("**") and part.endswith("**"):
            r = p.add_run(part[2:-2]); set_run_font(r, "Noto Serif CJK SC", size, True, INK)
        else:
            r = p.add_run(part); set_run_font(r, "Noto Serif CJK SC", size, False, color)


def add_body(doc, text):
    p = doc.add_paragraph(style="Normal")
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.3
    add_inline(p, text)


def add_stage(doc, text):
    m = re.match(r"^【([^】]+)】(.*)$", text)
    if not m:
        add_body(doc, text)
        return
    tag, rest = m.group(1), m.group(2)
    p = doc.add_paragraph(style="Normal")
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.left_indent = Pt(10)
    r = p.add_run(f"【{tag}】"); set_run_font(r, "Noto Serif CJK SC", 10.2, True, RUST)
    if rest:
        r = p.add_run(rest); set_run_font(r, "Noto Serif CJK SC", 10.2, False, MUTED)


def add_dialogue(doc, speaker, text):
    p = doc.add_paragraph(style="Normal")
    p.paragraph_format.left_indent = Pt(18)
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run(speaker + "："); set_run_font(r, "Noto Serif CJK SC", 10.5, True, RUST)
    add_inline(p, text, 10.5, BODY)


def add_quote(doc, lines):
    for line in lines:
        p = doc.add_paragraph(style="Story Quote")
        p.paragraph_format.space_after = Pt(8)
        r = p.add_run(line); set_run_font(r, "Noto Serif CJK SC", 10, False, RGBColor(0x67, 0x5D, 0x4F))


def add_table(doc, rows):
    if not rows:
        return
    ncols = max(len(r) for r in rows)
    table = doc.add_table(rows=len(rows), cols=ncols)
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = True
    table.style = "Table Grid"
    for i, row in enumerate(rows):
        for j in range(ncols):
            text = row[j] if j < len(row) else ""
            cell = table.cell(i, j)
            cell.text = ""
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.15
            add_inline(p, text.strip(), 8.9, WHITE if i == 0 else BODY)
            if i == 0:
                for r in p.runs:
                    r.font.bold = True
                    r.font.color.rgb = WHITE
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            cell_margins(cell)
            cell_borders(cell)
            if i == 0:
                shade(cell, HEADER_FILL)
            elif i % 2 == 0:
                shade(cell, ROW_FILL)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def parse(doc, text):
    lines = text.splitlines()
    start = next(i for i, l in enumerate(lines) if l.startswith("# 一、本章原则"))
    lines = lines[start:]
    i = 0
    first = True
    while i < len(lines):
        line = lines[i].rstrip()
        if not line.strip() or line.strip() == "---":
            i += 1
            continue
        if line.startswith("# ") and not line.startswith("## "):
            title = line[2:].strip()
            add_h1(doc, title, break_before=(not first and title in PAGE_BREAKS))
            first = False
            i += 1
            continue
        if line.startswith("## "):
            add_h2(doc, line[3:].strip()); i += 1; continue
        if line.startswith("### "):
            add_h3(doc, line[4:].strip()); i += 1; continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", c) for c in cells):
                    rows.append(cells)
                i += 1
            add_table(doc, rows)
            continue
        if line.startswith(">"):
            qlines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                q = lines[i].strip()[1:].strip()
                if q:
                    qlines.append(q)
                i += 1
            add_quote(doc, qlines)
            continue
        if line.startswith("- "):
            while i < len(lines) and lines[i].strip().startswith("- "):
                p = doc.add_paragraph(style="List Bullet")
                p.paragraph_format.space_after = Pt(2)
                add_inline(p, lines[i].strip()[2:].strip())
                i += 1
            continue
        if line.startswith("【"):
            add_stage(doc, line); i += 1; continue
        # dialogue lines like "Madam Egret：..."
        m = re.match(r"^(Madam Egret|Mother|Chao|Ferryman|玩家)：\s*(.*)$", line)
        if m:
            add_dialogue(doc, m.group(1), m.group(2)); i += 1; continue
        add_body(doc, line.strip()); i += 1


def main():
    doc = Document(TEMPLATE)
    clear_body(doc)
    setup(doc)
    add_cover(doc)
    parse(doc, SRC.read_text(encoding="utf-8"))
    doc.save(OUT)
    print(f"saved {OUT}")


if __name__ == "__main__":
    main()
