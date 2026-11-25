# -*- coding: utf-8 -*-
"""Презентация к защите ВКР на шаблоне Университета «Синергия» (python-pptx).
Слайды шаблона 1, 2, 3, 5, 6, 13 заполняются; новые слайды строятся на макете
«1-СТРОЧНЫЙ ЗАГОЛОВОК» с заголовком и линией, скопированными со слайда 2 шаблона."""
import copy, json, os
from pptx import Presentation
from pptx.util import Inches, Pt, Emu
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.oxml.ns import qn

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
FIG = os.path.join(HERE, 'figures')
SHOTS = os.path.join(ROOT, 'screens')
R = json.load(open(os.path.join(HERE, 'bench', 'results.json'), encoding='utf-8'))
RX = json.load(open(os.path.join(HERE, 'bench', 'results_extra.json'), encoding='utf-8'))
RED, DARK, GREY = RGBColor(0xFF, 0x00, 0x40), RGBColor(0x1E, 0x1E, 0x1E), RGBColor(0x6B, 0x6B, 0x6B)
TOPIC = '«Проектирование и реализация базы данных для централизованного хранения игровых элементов (на примере RPG игры)»'

prs = Presentation(os.path.join(ROOT, 'source_zip', 'shablon_oformleniya_prezentacii (1).pptx'))
T = list(prs.slides)                     # слайды шаблона по порядку (0-based)

def shape(slide, sid):
    def walk(shapes):
        for sh in shapes:
            if sh.shape_id == sid: return sh
            if sh.shape_type == 6:
                r = walk(sh.shapes)
                if r is not None: return r
        return None
    r = walk(slide.shapes)
    if r is None: raise KeyError(sid)
    return r

def fill(tf, lines, size=None, color=DARK, bold=False, align=None):
    """Заменить текст, сохранив оформление первого абзаца и первого прогона."""
    paras = tf.paragraphs
    proto_p = copy.deepcopy(paras[0]._p)
    for p in list(paras)[1:]: p._p.getparent().remove(p._p)
    first = True
    for line in lines:
        if first: p_el = paras[0]._p
        else:
            p_el = copy.deepcopy(proto_p); tf._txBody.append(p_el)
        first = False
        for child in list(p_el):
            if child.tag in (qn('a:r'), qn('a:br'), qn('a:fld'), qn('a:endParaRPr')): p_el.remove(child)
        from pptx.text.text import _Paragraph
        para = _Paragraph(p_el, tf)
        if align is not None: para.alignment = align
        r = para.add_run(); r.text = line
        if size: r.font.size = Pt(size)
        r.font.color.rgb = color; r.font.bold = bold
    return tf

def title(shp, a, b, size=40):
    tf = shp.text_frame
    p = tf.paragraphs[0]
    for child in list(p._p):
        if child.tag in (qn('a:r'), qn('a:br')): p._p.remove(child)
    r1 = p.add_run(); r1.text = a + ' '; r1.font.size = Pt(size); r1.font.color.rgb = DARK
    p._p.append(copy.deepcopy(p._p.makeelement(qn('a:br'), {})))
    r2 = p.add_run(); r2.text = b; r2.font.size = Pt(size); r2.font.color.rgb = RED
    for p2 in list(tf.paragraphs)[1:]: p2._p.getparent().remove(p2._p)

def text_box(slide, x, y, w, h, items, size=16, bullet=True, gap=8, color=DARK):
    tb = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = tb.text_frame; tf.word_wrap = True
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = 0
    for i, it in enumerate(items):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(gap)
        bold_part = None
        if isinstance(it, tuple): bold_part, it = it
        if bullet:
            r = p.add_run(); r.text = '■  '; r.font.size = Pt(size - 4); r.font.color.rgb = RED
        if bold_part:
            r = p.add_run(); r.text = bold_part + ' '; r.font.size = Pt(size); r.font.bold = True; r.font.color.rgb = color
        r = p.add_run(); r.text = it; r.font.size = Pt(size); r.font.color.rgb = color
    return tb

def picture(slide, path, x, y, w=None, h=None):
    return slide.shapes.add_picture(path, Inches(x), Inches(y), Inches(w) if w else None, Inches(h) if h else None)

def fit_picture(slide, path, x, y, wmax, hmax):
    from PIL import Image
    W, H = Image.open(path).size
    w = wmax; h = w * H / W
    if h > hmax: h = hmax; w = h * W / H
    return picture(slide, path, x + (wmax - w) / 2, y, w, h)

def table(slide, x, y, w, rows, col_w, size=13, row_h=0.42):
    nr, nc = len(rows), len(rows[0])
    gt = slide.shapes.add_table(nr, nc, Inches(x), Inches(y), Inches(w), Inches(row_h * nr)).table
    for j, cw in enumerate(col_w): gt.columns[j].width = Inches(cw)
    for i, row in enumerate(rows):
        for j, v in enumerate(row):
            c = gt.cell(i, j); c.text = ''
            p = c.text_frame.paragraphs[0]; r = p.add_run(); r.text = str(v)
            r.font.size = Pt(size); r.font.bold = (i == 0)
            r.font.color.rgb = RGBColor(0xFF, 0xFF, 0xFF) if i == 0 else DARK
            c.fill.solid(); c.fill.fore_color.rgb = RED if i == 0 else (RGBColor(0xF4, 0xF4, 0xF4) if i % 2 else RGBColor(0xFF, 0xFF, 0xFF))
            c.margin_left = c.margin_right = Inches(0.08); c.vertical_anchor = MSO_ANCHOR.MIDDLE
    return gt

# --- элементы для новых слайдов (со слайда 2 шаблона)
TITLE_XML = copy.deepcopy(shape(T[1], 21)._element)
LINE_XML = copy.deepcopy(shape(T[1], 4)._element)
NUM_XML = copy.deepcopy(shape(T[1], 9)._element)
LAYOUT = prs.slide_layouts[12]

def new_slide(a, b, tsize=40):
    s = prs.slides.add_slide(LAYOUT)
    for ph in list(s.placeholders): ph._element.getparent().remove(ph._element)
    tree = s.shapes._spTree
    for el in (TITLE_XML, LINE_XML, NUM_XML): tree.append(copy.deepcopy(el))
    title(s.shapes[0], a, b, tsize)
    return s

# ================================================================ 1. Титул
s = T[0]
fill(shape(s, 7).text_frame, ['Выпускная квалификационная работа'], size=30)
tf = shape(s, 7).text_frame
p = tf.add_paragraph(); r = p.add_run(); r.text = 'на тему'; r.font.size = Pt(20); r.font.color.rgb = GREY
p = tf.add_paragraph(); r = p.add_run(); r.text = TOPIC; r.font.size = Pt(24); r.font.color.rgb = RED
fill(shape(s, 8).text_frame, ['Обучающийся: Зубович Александр Игоревич', 'Руководитель: Терехова Л. А.'], size=16)
fill(shape(s, 3).text_frame, ['Направление подготовки: 09.03.03 Прикладная информатика', 'Профиль: Геймдизайн и разработка игр'], size=16)

# ================================================================ 2. Актуальность
s = T[1]
title(shape(s, 21), 'Актуальность', 'темы')
cards = ['Рост масштаба RPG: тысячи взаимосвязанных игровых элементов на каждого игрока и постоянные обновления контента',
         'Файловое хранение ведёт к дублированию данных, рассогласованию справочников и сохранений, потере прогресса',
         'Операции с предметами и игровой валютой требуют транзакций и защиты от дублирования и мошенничества']
for sid, t in zip((76, 49, 19), cards):
    fill(shape(s, sid).text_frame, [t], size=15)

# ================================================================ 3. Цель и задачи
s = T[2]
title(shape(s, 39), 'Цель и задачи', 'работы')
sub = shape(s, 44); sub.left, sub.top, sub.width, sub.height = Inches(0.54), Inches(1.62), Inches(11.6), Inches(0.75)
sub.text_frame.word_wrap = True
fill(sub.text_frame, ['Цель: разработать и реализовать реляционную базу данных для централизованного хранения игровых элементов RPG, обеспечивающую целостность, производительность и масштабируемость'], size=15)
tasks = ['Анализ предметной области RPG', 'Выбор модели данных и СУБД', 'ER-модель, логическая и физическая схема',
         'Реализация БД и запросов на SQL', 'Нагрузочное тестирование и оптимизация']
for sid, t in zip((18, 23, 28, 33, 38), tasks):
    sh = shape(s, sid); sh.width = Inches(5.2); fill(sh.text_frame, [t], size=15)

# ================================================================ 4. Объект, предмет, методы
s = T[4]
title(shape(s, 8), 'Объект, предмет', 'и методы')
fill(shape(s, 30).text_frame, [
    'Объект: база данных для RPG-игры',
    'Предмет: процесс проектирования и реализации базы данных для централизованного хранения игровых элементов',
    'Пример: «Эхо кода» — 2D-платформер с элементами RPG и стелса (прототип разработан на практике)',
    'Методы: анализ предметной области, ER-моделирование, нормализация до 3НФ',
    'Реализация: PostgreSQL 18, SQL, PL/pgSQL',
    'Эксперимент: EXPLAIN ANALYZE, нагрузочное тестирование pgbench'], size=16)

# ================================================================ 5. Раздел
s = T[5]
fill(shape(s, 7).text_frame, ['Проектирование и реализация'], size=40)
fill(shape(s, 8).text_frame, ['PostgreSQL 18 · 37 таблиц · 3НФ · 585 SQL-операторов'], size=18)

# ================================================================ новые слайды
n1 = new_slide('Выбор модели', 'данных и СУБД')
table(n1, 0.55, 1.95, 8.4, [
    ['Критерий', 'Реляционная + JSONB', 'Документная', 'Ключ — значение'],
    ['Целостность связей', 'Внешние ключи, CHECK', 'В приложении', 'Нет'],
    ['Транзакции ACID', 'Полностью', 'С ограничениями', 'Ограниченно'],
    ['Сложные запросы', 'SQL, окна, агрегаты', 'Конвейер агрегации', 'Только по ключу'],
    ['Гибкость схемы', 'Высокая (JSONB)', 'Высокая', 'Высокая'],
    ['Роль в RPG', 'Основное хранилище', 'Прототипы, профили', 'Кэш, рейтинги']],
    [2.1, 2.2, 2.1, 2.0], size=13, row_h=0.6)
text_box(n1, 9.4, 1.95, 4.9, 5.5, [
    ('PostgreSQL 18:', 'свободная лицензия'),
    'MVCC и транзакции ACID для инвентаря и экономики',
    'JSONB + GIN — гибкие свойства предметов',
    'point + GiST — координаты локаций',
    'Частичные индексы и индексы по выражению',
    'PL/pgSQL — игровая логика рядом с данными'], size=16)

n2 = new_slide('ER-модель:', 'предметы и инвентарь')
fit_picture(n2, os.path.join(FIG, 'er_2_items.png'), 0.55, 1.75, 10.3, 6.0)
text_box(n2, 11.05, 1.95, 3.3, 5.5, [
    '3 схемы, 37 сущностей, нотация «воронья лапка»',
    'Шаблон предмета ≠ экземпляр: стеки и уникальная экипировка',
    'Инвентарь — связь M:N с ячейкой и количеством',
    'Схема приведена к 3НФ'], size=14)

n3 = new_slide('Физическая', 'модель данных')
kpi = [('37', 'таблиц'), ('54', 'внешних ключа'), ('60', 'проверочных ограничений'),
       ('77', 'индексов (22 доп.)'), ('8', 'функций игровых операций'), ('585', 'SQL-операторов')]
for i, (num, lab) in enumerate(kpi):
    x = 0.55 + (i % 3) * 4.6; y = 1.9 + (i // 3) * 1.75
    box = n3.shapes.add_shape(5, Inches(x), Inches(y), Inches(4.3), Inches(1.5))   # скруглённый прямоугольник
    box.fill.solid(); box.fill.fore_color.rgb = RGBColor(0xF4, 0xF4, 0xF4); box.line.fill.background()
    tf = box.text_frame; tf.clear()
    p = tf.paragraphs[0]; p.alignment = PP_ALIGN.LEFT
    r = p.add_run(); r.text = num + '  '; r.font.size = Pt(40); r.font.color.rgb = RED; r.font.bold = True
    r = p.add_run(); r.text = lab; r.font.size = Pt(16); r.font.color.rgb = DARK
    tf.margin_left = Inches(0.25)
text_box(n3, 0.55, 5.55, 13.6, 2.2, [
    ('Целостность:', 'домены (валюта ≥ 0), CHECK (здоровье ≤ максимума), уникальность экземпляра в инвентаре'),
    ('Триггеры:', 'уровень по опыту, размер стека и инвентаря, проверка экипировки, аудит валюты'),
    ('Функции:', 'создание персонажа, добавление и передача предмета, покупка, квесты')], size=15, gap=6)

n4 = new_slide('Эффект', 'индексов')
fit_picture(n4, os.path.join(FIG, 'chart_indexes.png'), 0.45, 1.7, 8.9, 6.1)
WI, WO = R['with_indexes'], R['without_indexes']
def sp(k): return WO[k]['median_ms'] / WI[k]['median_ms']
def f(v): return (f'{v:.3f}' if v < 1 else f'{v:.1f}').replace('.', ',')
text_box(n4, 9.6, 1.95, 4.7, 5.6, [
    ('История операций:', f"{f(WO['Q11']['median_ms'])} → {f(WI['Q11']['median_ms'])} мс (×{sp('Q11'):,.0f})".replace(f"{sp('Q11'):,.0f}", f"{sp('Q11'):,.0f}".replace(',', ' '))),
    ('Экипировка:', f"×{sp('Q7'):.0f}"), ('Сессии игрока:', f"×{sp('Q14'):.0f}"), ('Лидеры класса:', f"×{sp('Q10'):.0f}"),
    'Все оперативные запросы — быстрее 1 мс',
    'Справочники малы: оптимизатор верно выбирает Seq Scan'], size=15)

n5 = new_slide('Нагрузочное', 'тестирование')
picture(n5, os.path.join(FIG, 'chart_tps_read.png'), 0.55, 1.75, 6.6)
picture(n5, os.path.join(FIG, 'chart_tps_write.png'), 7.55, 1.75, 6.6)
rd = {x['clients']: x for x in R['pgbench_read']}; nr = {x['clients']: x for x in R['pgbench_read_noidx']}
text_box(n5, 0.55, 5.6, 13.6, 2.2, [
    ('Чтение:', f"{rd[16]['tps']:.0f} транзакций/с при 16 клиентах, задержка {f(rd[16]['latency_ms'])} мс (без индексов — {nr[16]['tps']:.0f})"),
    ('Запись:', 'передача предметов без ошибок и взаимоблокировок; асинхронная фиксация — ×7–19'),
    ('Защита от дублирования:', '20 одновременных передач одного предмета → 1 успешная, 19 отклонены')], size=15, gap=6)

n6 = new_slide('Оптимизация', 'аналитики')
q = lambda k: f(RX[k]['Q12']['median_ms'])
table(n6, 0.55, 1.95, 8.2, [
    ['Вариант отчёта «оборот за неделю»', 'Время, мс'],
    ['Исходный (полное чтение 200 000 операций)', q('q12_base')],
    ['BRIN-индекс на упорядоченном журнале', q('q12_brin_sorted')],
    ['B-дерево по времени (оптимизатор отказался)', q('q12_btree')],
    ['Материализованное представление', q('q12_mv')]], [6.4, 1.8], size=14, row_h=0.62)
text_box(n6, 9.2, 1.95, 5.1, 5.6, [
    'Секционирование журналов по месяцам',
    'Материализованные представления для отчётов',
    'Пул соединений PgBouncer',
    'Кэш справочников (Redis)',
    'Реплики для аналитики',
    'Мониторинг pg_stat_statements'], size=16)

n7 = new_slide('Связь с игрой', '«Эхо кода»')
picture(n7, os.path.join(SHOTS, '07_inventory.jpg'), 0.55, 1.8, 6.6)
picture(n7, os.path.join(SHOTS, '06_sector3_core.jpg'), 7.55, 1.8, 6.6)
text_box(n7, 0.55, 5.75, 13.6, 2.0, [
    'Инвентарь 5×5 и импланты (не более трёх) → таблицы inventory, item_instances, equipment',
    'Уровень, репутация, фрагменты памяти, квесты → characters, character_reputation, character_fragments, character_quests',
    'Справочные данные БД построены на контенте прототипа: 5 имплантов, 22 фрагмента памяти, 3 сектора'], size=15, gap=6)

n8 = new_slide('Результаты', 'работы')
text_box(n8, 0.55, 1.9, 13.6, 5.8, [
    ('1.', 'Определён состав игровых элементов RPG для централизованного хранения: 37 сущностей'),
    ('2.', 'Обоснован выбор реляционной модели с JSONB и СУБД PostgreSQL'),
    ('3.', 'Разработаны ER-модель, логическая (3НФ) и физическая схемы, ограничения и индексы'),
    ('4.', 'База реализована: 585 SQL-операторов, триггеры, функции игровых операций'),
    ('5.', 'Запросы 15 игровых операций выполняются быстрее 1 мс, транзакции защищены от дублирования'),
    ('6.', 'Нагрузочное тестирование: ускорение до 1 000 раз, более 3 000 транзакций/с')], size=18, bullet=False, gap=12)

# ================================================================ финал
s = T[12]
fill(shape(s, 7).text_frame, ['Спасибо за внимание!', 'Готов ответить на вопросы'], size=36)
rm = shape(s, 3); rm._element.getparent().remove(rm._element)

# ================================================================ порядок слайдов
lst = prs.slides._sldIdLst
ids = list(lst)
keep_tpl = [0, 1, 2, 4, 5]                      # титул, актуальность, цель, объект, раздел
drop_tpl = [3, 6, 7, 8, 9, 10, 11]
new_ids = ids[13:]
final = [ids[i] for i in keep_tpl] + new_ids + [ids[12]]
for el in ids: lst.remove(el)
for el in final: lst.append(el)
for i in drop_tpl:
    prs.part.drop_rel(ids[i].get(qn('r:id')))

out = os.path.join(HERE, 'docs', 'Презентация_ВКР_Зубович_АИ.pptx')
prs.save(out)
print('saved', out, 'slides', len(prs.slides))
