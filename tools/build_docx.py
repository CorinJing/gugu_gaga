#!/usr/bin/env python3
"""Build the three-chapter Word document from the canonical Markdown copy."""
from __future__ import annotations

import re
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_ALIGN_VERTICAL
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Pt, RGBColor, Inches

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "游戏文本" / "06_三章版文案.md"
OUT = ROOT / "游戏文本" / "盐月旅馆_三章版文案_v0.1.docx"

INK = RGBColor(0x16, 0x2B, 0x2B)
DEEP = RGBColor(0x10, 0x1A, 0x1B)
RUST = RGBColor(0xA3, 0x4B, 0x3F)
AMBER = RGBColor(0xC9, 0xA2, 0x4E)
GRAY = RGBColor(0x66, 0x66, 0x60)
LIGHT_GRAY = RGBColor(0x8A, 0x86, 0x7A)
PAPER = "F7F3EA"
HEADER_FILL = "162B2B"
ROW_FILL = "F2EEE4"
BORDER = "D8CDB0"

BODY_FONT = "Songti SC"
HEAD_FONT = "Songti SC"

SPEAKERS = [
    "Madam Egret",
    "Mr. Mole",
    "Mr. Hare",
    "The Boy (behind the door)",
    "Mother (salt record)",
    "Ferryman",
    "Mother",
    "Chao",
    "Lan",
]


# ---------------------------------------------------------------------------
# low-level helpers
# ---------------------------------------------------------------------------

def set_run_font(run, size=11, bold=None, color=None, font=BODY_FONT, italic=None):
    run.font.name = font
    run.font.size = Pt(size)
    if bold is not None:
        run.font.bold = bold
    if italic is not None:
        run.font.italic = italic
    if color is not None:
        run.font.color.rgb = color
    rpr = run._element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), font)
    rfonts.set(qn("w:hAnsi"), font)
    rfonts.set(qn("w:eastAsia"), font)


def style_font(style, size, bold=False, color=INK, font=BODY_FONT):
    style.font.name = font
    style.font.size = Pt(size)
    style.font.bold = bold
    style.font.color.rgb = color
    rpr = style.element.get_or_add_rPr()
    rfonts = rpr.find(qn("w:rFonts"))
    if rfonts is None:
        rfonts = OxmlElement("w:rFonts")
        rpr.append(rfonts)
    rfonts.set(qn("w:ascii"), font)
    rfonts.set(qn("w:hAnsi"), font)
    rfonts.set(qn("w:eastAsia"), font)


def shade_cell(cell, fill: str):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_borders(cell, color=BORDER, sz="4"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.find(qn("w:tcBorders"))
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        el = OxmlElement(f"w:{edge}")
        el.set(qn("w:val"), "single")
        el.set(qn("w:sz"), sz)
        el.set(qn("w:space"), "0")
        el.set(qn("w:color"), color)
        borders.append(el)


def set_cell_margins(cell, top=60, bottom=60, left=100, right=100):
    tc_pr = cell._tc.get_or_add_tcPr()
    mar = OxmlElement("w:tcMar")
    for side, value in (("top", top), ("bottom", bottom), ("left", left), ("right", right)):
        el = OxmlElement(f"w:{side}")
        el.set(qn("w:w"), str(value))
        el.set(qn("w:type"), "dxa")
        mar.append(el)
    tc_pr.append(mar)


def add_paragraph_border(paragraph, edge="bottom", color="C9A24E", sz="8", space="4"):
    p_pr = paragraph._p.get_or_add_pPr()
    p_bdr = p_pr.find(qn("w:pBdr"))
    if p_bdr is None:
        p_bdr = OxmlElement("w:pBdr")
        p_pr.append(p_bdr)
    el = OxmlElement(f"w:{edge}")
    el.set(qn("w:val"), "single")
    el.set(qn("w:sz"), sz)
    el.set(qn("w:space"), space)
    el.set(qn("w:color"), color)
    p_bdr.append(el)


def shade_paragraph(paragraph, fill: str):
    p_pr = paragraph._p.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:val"), "clear")
    shd.set(qn("w:color"), "auto")
    shd.set(qn("w:fill"), fill)
    p_pr.append(shd)


def add_page_number_footer(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    run = paragraph.add_run()
    set_run_font(run, 9, color=LIGHT_GRAY)
    fld_begin = OxmlElement("w:fldChar")
    fld_begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    fld_end = OxmlElement("w:fldChar")
    fld_end.set(qn("w:fldCharType"), "end")
    run._r.append(fld_begin)
    run._r.append(instr)
    run._r.append(fld_end)


def add_inline_runs(paragraph, text: str, size=11, color=DEEP, bold=False):
    """Very small Markdown inline parser: **bold** and `code`."""
    text = text.replace("`", "")
    parts = re.split(r"(\*\*.*?\*\*)", text)
    for part in parts:
        if not part:
            continue
        if part.startswith("**") and part.endswith("**") and len(part) >= 4:
            run = paragraph.add_run(part[2:-2])
            set_run_font(run, size, True, color)
        else:
            run = paragraph.add_run(part)
            set_run_font(run, size, bold, color)


# ---------------------------------------------------------------------------
# document setup
# ---------------------------------------------------------------------------

def setup_document() -> Document:
    doc = Document()
    section = doc.sections[0]
    section.page_height = Cm(29.7)
    section.page_width = Cm(21.0)
    section.top_margin = Cm(2.2)
    section.bottom_margin = Cm(2.0)
    section.left_margin = Cm(2.4)
    section.right_margin = Cm(2.4)
    section.different_first_page_header_footer = True

    # Normal style
    normal = doc.styles["Normal"]
    style_font(normal, 10.8, False, DEEP)
    normal.paragraph_format.line_spacing = 1.45
    normal.paragraph_format.space_after = Pt(5)

    # Heading styles
    h1 = doc.styles["Heading 1"]
    style_font(h1, 21, True, INK, HEAD_FONT)
    h1.paragraph_format.space_before = Pt(14)
    h1.paragraph_format.space_after = Pt(10)
    h1.paragraph_format.keep_with_next = True

    h2 = doc.styles["Heading 2"]
    style_font(h2, 14.5, True, RUST, HEAD_FONT)
    h2.paragraph_format.space_before = Pt(12)
    h2.paragraph_format.space_after = Pt(5)
    h2.paragraph_format.keep_with_next = True

    h3 = doc.styles["Heading 3"]
    style_font(h3, 12, True, INK, HEAD_FONT)
    h3.paragraph_format.space_before = Pt(8)
    h3.paragraph_format.space_after = Pt(4)

    # Header
    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    hr = hp.add_run("盐月旅馆 · 三章版文案")
    set_run_font(hr, 8.5, color=LIGHT_GRAY)

    # Footer
    footer = section.footer
    add_page_number_footer(footer.paragraphs[0])

    # Document properties
    cp = doc.core_properties
    cp.title = "盐月旅馆 · 三章版文案"
    cp.subject = "序章至第三夜的游戏文案"
    cp.author = "DeepSeek Harness"
    cp.keywords = "盐月旅馆, 游戏文案, 点击式解谜, Rusty Lake"
    cp.comments = "v0.1 工作稿"

    return doc


# ---------------------------------------------------------------------------
# cover / preface / toc
# ---------------------------------------------------------------------------

def add_cover(doc: Document):
    for _ in range(4):
        doc.add_paragraph()

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    r = p.add_run("RUSTY LAKE–INSPIRED 2D PUZZLE ADVENTURE")
    set_run_font(r, 9, False, AMBER)
    r.font.letter_spacing = Pt(1.5) if False else None

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run("盐月旅馆")
    set_run_font(r, 46, True, INK)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(10)
    r = p.add_run("三章版文案")
    set_run_font(r, 24, False, RUST)

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(4)
    p.paragraph_format.space_after = Pt(20)
    r = p.add_run("序章 ＋ 第一夜 ＋ 第二夜 ＋ 第三夜")
    set_run_font(r, 11, False, GRAY)
    add_paragraph_border(p, "bottom", "C9A24E", "10", "10")

    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(20)
    r = p.add_run("潮水退去时，别忘了数一数家里的人。")
    set_run_font(r, 15, False, INK)

    for _ in range(8):
        doc.add_paragraph()

    info = doc.add_table(rows=3, cols=2)
    info.alignment = WD_TABLE_ALIGNMENT.CENTER
    info.autofit = False
    rows = [
        ("版本", "v0.1 工作稿"),
        ("日期", "2026-10-27"),
        ("范围", "序章至第三夜 · 45–60 分钟"),
    ]
    for i, (k, v) in enumerate(rows):
        for j, text in enumerate((k, v)):
            cell = info.cell(i, j)
            cell.text = ""
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if j == 0 else WD_ALIGN_PARAGRAPH.RIGHT
            r = p.add_run(text)
            set_run_font(r, 9.5, j == 0, GRAY if j == 0 else INK)
            shade_cell(cell, "F7F3EA")
            set_cell_borders(cell, "E4DCC9", "4")
            set_cell_margins(cell, 40, 40, 80, 80)

    doc.add_page_break()


def add_preface(doc: Document):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(12)
    r = p.add_run("文档说明")
    set_run_font(r, 22, True, INK)
    add_paragraph_border(p, "bottom", "C9A24E", "8", "6")

    intro = [
        "本文件是《盐月旅馆》前三章的制作文案。",
        "范围：序章 + 第一夜 + 第二夜 + 第三夜。",
        "角色：Lan、Madam Egret、Mr. Mole、Mr. Hare、Mother、Chao、Ferryman。",
        "完整七夜规划保留在《01_主线剧本.md》，本文件为当前三章版口径。",
    ]
    for line in intro:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.2)
        add_inline_runs(p, line, 10.8, DEEP)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("文本记号")
    set_run_font(r, 12.5, True, RUST)

    markers = [
        ("【画面】", "舞台指示，不直接显示给玩家。"),
        ("【玩家可见】", "游戏内旁白、调查文本或界面文本。"),
        ("【获得】", "道具/线索获得提示。"),
        ("【选择】", "玩家选择节点。"),
    ]
    for marker, desc in markers:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.3)
        r = p.add_run(marker)
        set_run_font(r, 10.5, True, AMBER)
        r = p.add_run("  " + desc)
        set_run_font(r, 10.5, False, GRAY)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(14)
    p.paragraph_format.left_indent = Cm(0.2)
    p.paragraph_format.right_indent = Cm(0.2)
    shade_paragraph(p, "F7F3EA")
    r = p.add_run("本稿只写到第三夜。107 的门已经出现，但门后的人还没有被完全看见。")
    set_run_font(r, 10.5, False, INK)

    doc.add_page_break()


def add_toc(doc: Document):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(10)
    p.paragraph_format.space_after = Pt(12)
    r = p.add_run("目录")
    set_run_font(r, 22, True, INK)
    add_paragraph_border(p, "bottom", "C9A24E", "8", "6")

    entries = [
        ("一、角色", ""),
        ("序章 · 最后一班渡船", ""),
        ("第一夜 · 红线", ""),
        ("第二夜 · 空棺", ""),
        ("第三夜 · 合影", ""),
        ("附录一：关键交互文本", ""),
        ("附录二：章节卡与界面", ""),
        ("附录三：选择与文本变体", ""),
        ("附录四：本版不出现", ""),
    ]
    for title, note in entries:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.2)
        p.paragraph_format.space_after = Pt(8)
        r = p.add_run(title)
        set_run_font(r, 11.5, False, INK)
        if note:
            r = p.add_run("  " + note)
            set_run_font(r, 9, False, GRAY)

    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(18)
    r = p.add_run("说明：本目录为手工目录，便于快速翻阅；页脚有页码。")
    set_run_font(r, 9, False, LIGHT_GRAY)

    doc.add_page_break()


# ---------------------------------------------------------------------------
# markdown conversion
# ---------------------------------------------------------------------------

def is_separator_row(cells):
    return all(re.fullmatch(r":?-{2,}:?", c.strip()) for c in cells)


def add_table(doc: Document, rows):
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
            add_inline_runs(p, text.strip(), 9.2, RGBColor(0xFF, 0xFF, 0xFF) if i == 0 else DEEP, i == 0)
            cell.vertical_alignment = WD_ALIGN_VERTICAL.CENTER
            set_cell_margins(cell, 50, 50, 90, 90)
            set_cell_borders(cell, BORDER, "4")
            if i == 0:
                shade_cell(cell, HEADER_FILL)
            elif i % 2 == 0:
                shade_cell(cell, ROW_FILL)
    # small spacer after table
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(2)
    p.paragraph_format.line_spacing = 1.0
    r = p.add_run("")
    set_run_font(r, 4)


def add_stage_paragraph(doc: Document, text: str):
    m = re.match(r"^【([^】]+)】(.*)$", text)
    if not m:
        p = doc.add_paragraph()
        add_inline_runs(p, text, 10.8, DEEP)
        return
    tag, rest = m.group(1), m.group(2)
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.left_indent = Cm(0.2)
    tag_color = GRAY
    if tag in ("玩家可见", "获得", "选择", "交互"):
        tag_color = AMBER if tag == "获得" else (RUST if tag == "选择" else INK)
    r = p.add_run(f"【{tag}】")
    set_run_font(r, 10.2, True, tag_color)
    if rest:
        r = p.add_run(rest)
        set_run_font(r, 10.2, False, GRAY if tag in ("画面", "交互") else DEEP)


def add_dialogue(doc: Document, speaker: str, text: str):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(2)
    p.paragraph_format.space_after = Pt(3)
    p.paragraph_format.left_indent = Cm(0.5)
    p.paragraph_format.first_line_indent = Cm(-0.5)
    r = p.add_run(speaker)
    set_run_font(r, 10.8, True, RUST)
    r = p.add_run("：")
    set_run_font(r, 10.8, True, RUST)
    add_inline_runs(p, text, 10.8, DEEP)


def add_quote_lines(doc: Document, lines):
    for line in lines:
        p = doc.add_paragraph()
        p.paragraph_format.left_indent = Cm(0.55)
        p.paragraph_format.right_indent = Cm(0.3)
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(2)
        p.paragraph_format.line_spacing = 1.3
        shade_paragraph(p, "F7F3EA")
        add_paragraph_border(p, "left", "C9A24E", "12", "6")
        add_inline_runs(p, line, 10.5, INK)
        r = p.add_run("")
        set_run_font(r, 1)


def add_bullet(doc: Document, text: str):
    p = doc.add_paragraph(style="List Bullet")
    p.paragraph_format.left_indent = Cm(0.7)
    p.paragraph_format.space_after = Pt(3)
    add_inline_runs(p, text, 10.8, DEEP)


def add_h1(doc: Document, text: str, first=False):
    if not first:
        doc.add_page_break()
    p = doc.add_paragraph(style="Heading 1")
    p.paragraph_format.space_before = Pt(12)
    p.paragraph_format.space_after = Pt(12)
    r = p.add_run(text)
    set_run_font(r, 22, True, INK)
    add_paragraph_border(p, "bottom", "C9A24E", "10", "8")


def add_h2(doc: Document, text: str):
    p = doc.add_paragraph(style="Heading 2")
    r = p.add_run(text)
    set_run_font(r, 14.5, True, RUST)


def add_h3(doc: Document, text: str):
    p = doc.add_paragraph(style="Heading 3")
    r = p.add_run(text)
    set_run_font(r, 12, True, INK)


def parse_markdown(doc: Document, text: str):
    lines = text.splitlines()
    # Drop the top title + metadata block; cover/preface already covers it.
    start = 0
    for i, line in enumerate(lines):
        if line.strip() == "## 一、角色":
            start = i
            break
    lines = lines[start:]

    i = 0
    first_h1 = True
    while i < len(lines):
        raw = lines[i].rstrip()
        line = raw.strip()
        if not line:
            i += 1
            continue
        if line == "---":
            i += 1
            continue
        if line.startswith("# ") and not line.startswith("## "):
            add_h1(doc, line[2:].strip(), first=first_h1)
            first_h1 = False
            i += 1
            continue
        if line.startswith("## "):
            add_h2(doc, line[3:].strip())
            i += 1
            continue
        if line.startswith("### "):
            add_h3(doc, line[4:].strip())
            i += 1
            continue
        if line.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not is_separator_row(cells):
                    rows.append(cells)
                i += 1
            add_table(doc, rows)
            continue
        if line.startswith("> "):
            qlines = []
            while i < len(lines) and lines[i].strip().startswith(">"):
                q = lines[i].strip()[1:].strip()
                if q:
                    qlines.append(q)
                i += 1
            add_quote_lines(doc, qlines)
            continue
        if line.startswith("- "):
            while i < len(lines) and lines[i].strip().startswith("- "):
                add_bullet(doc, lines[i].strip()[2:].strip())
                i += 1
            continue
        # dialogue
        speaker_match = None
        for s in SPEAKERS:
            if line.startswith(s + ":"):
                speaker_match = (s, line[len(s) + 1 :].strip())
                break
        if speaker_match:
            add_dialogue(doc, speaker_match[0], speaker_match[1])
            i += 1
            continue
        # stage direction
        if line.startswith("【"):
            add_stage_paragraph(doc, line)
            i += 1
            continue
        # ordinary paragraph
        p = doc.add_paragraph()
        p.paragraph_format.space_before = Pt(2)
        p.paragraph_format.space_after = Pt(5)
        add_inline_runs(p, line, 10.8, DEEP)
        i += 1


def main():
    text = SRC.read_text(encoding="utf-8")
    doc = setup_document()
    add_cover(doc)
    add_preface(doc)
    add_toc(doc)
    parse_markdown(doc, text)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(f"saved {OUT}")


if __name__ == "__main__":
    main()
