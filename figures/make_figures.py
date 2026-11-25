# -*- coding: utf-8 -*-
"""ER-диаграммы (по живой схеме БД) и графики результатов тестирования. Только Pillow."""
import json, math, os, subprocess
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
BIN = r'D:\Tools\pgsql\bin\psql.exe'
import sys
for _a in sys.argv[1:]:                      # путь к bin PostgreSQL можно передать аргументом
    if os.path.isfile(os.path.join(_a, 'psql.exe')): BIN = os.path.join(_a, 'psql.exe')
CONN = ['-h', '127.0.0.1', '-p', '5441', '-U', 'postgres', '-d', 'rpg_vkr', '-At', '-F', '\t']
ENV = dict(os.environ, PGCLIENTENCODING='UTF8')
F = r'C:\Windows\Fonts'
def font(name, size): return ImageFont.truetype(os.path.join(F, name), size)
FT, FB, FM, FS = font('arialbd.ttf', 26), font('arialbd.ttf', 19), font('consola.ttf', 17), font('arial.ttf', 16)

def q(sql):
    r = subprocess.run([BIN, *CONN, '-c', sql], capture_output=True, text=True, encoding='utf-8', env=ENV)
    assert r.returncode == 0, r.stderr
    return [l.split('\t') for l in r.stdout.strip().splitlines()]

COLS = {}
for t, c, typ, pos in q("""SELECT c.table_name, c.column_name, CASE WHEN c.data_type='USER-DEFINED' THEN c.udt_name ELSE c.data_type END, c.ordinal_position
                             FROM information_schema.columns c JOIN information_schema.tables t USING (table_schema, table_name)
                            WHERE c.table_schema='game' AND t.table_type='BASE TABLE' ORDER BY 1, 4"""):
    typ = {'character varying': 'varchar', 'timestamp with time zone': 'timestamptz', 'integer': 'int', 'boolean': 'bool'}.get(typ, typ)
    COLS.setdefault(t, []).append((c, typ))
PK = {}
for t, c in q("""SELECT tc.table_name, kcu.column_name FROM information_schema.table_constraints tc
                   JOIN information_schema.key_column_usage kcu USING (constraint_schema, constraint_name)
                  WHERE tc.table_schema='game' AND tc.constraint_type='PRIMARY KEY'"""):
    PK.setdefault(t, set()).add(c)
FKS = []  # (from_table, from_col, to_table)
for t, c, rt in q("""SELECT cl.relname, a.attname, rc.relname FROM pg_constraint co
                      JOIN pg_class cl ON cl.oid = co.conrelid JOIN pg_namespace n ON n.oid = cl.relnamespace
                      JOIN pg_class rc ON rc.oid = co.confrelid
                      JOIN LATERAL unnest(co.conkey) k(att) ON true JOIN pg_attribute a ON a.attrelid = cl.oid AND a.attnum = k.att
                     WHERE co.contype='f' AND n.nspname='game'"""):
    FKS.append((t, c, rt))
FKCOL = {(t, c) for t, c, _ in FKS}

BOXW, LH, HEAD = 330, 22, 34
def box_h(t, stub): return HEAD + (0 if stub else LH * len(COLS[t]) + 8)

def er(name, title, layout, stubs=()):
    # layout: {table: (col, row)}; высота ряда = максимум высот в ряду
    rows = {}
    for t, (cx, cy) in layout.items():
        rows[cy] = max(rows.get(cy, 0), box_h(t, t in stubs))
    gapx, gapy, top = 120, 70, 90
    ys, acc = {}, top
    for r in sorted(rows): ys[r] = acc; acc += rows[r] + gapy
    ncol = max(c for c, _ in layout.values()) + 1
    W, H = 60 + ncol * (BOXW + gapx), acc + 20
    img = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(img)
    d.text((30, 25), title, font=FT, fill='black')
    rect = {}
    for t, (cx, cy) in layout.items():
        x, y = 40 + cx * (BOXW + gapx), ys[cy]
        rect[t] = (x, y, x + BOXW, y + box_h(t, t in stubs))
    # связи (рисуем под таблицами)
    for ft, fc, tt in FKS:
        if ft not in rect or tt not in rect or ft == tt: continue
        a, b = rect[ft], rect[tt]
        acx, acy, bcx, bcy = (a[0]+a[2])/2, (a[1]+a[3])/2, (b[0]+b[2])/2, (b[1]+b[3])/2
        # точки на границах
        def edge(r, tx, ty):
            cx, cy = (r[0]+r[2])/2, (r[1]+r[3])/2
            dx, dy = tx - cx, ty - cy
            if dx == 0 and dy == 0: return cx, cy
            sx = (r[2]-r[0])/2 / abs(dx) if dx else 1e9
            sy = (r[3]-r[1])/2 / abs(dy) if dy else 1e9
            s = min(sx, sy)
            return cx + dx*s, cy + dy*s
        p1, p2 = edge(a, bcx, bcy), edge(b, acx, acy)
        d.line([p1, p2], fill='#555555', width=2)
        # «многие» — вилка у FK, «1» — черта у PK
        ang = math.atan2(p2[1]-p1[1], p2[0]-p1[0])
        ux, uy = math.cos(ang), math.sin(ang)
        apex = (p1[0] + 18*ux, p1[1] + 18*uy)
        for k in (-1, 0, 1):      # «воронья лапка»: сторона «многие»
            d.line([apex, (p1[0] - uy*9*k, p1[1] + ux*9*k)], fill='#555555', width=2)
        px, py = p2[0] - 12*math.cos(ang), p2[1] - 12*math.sin(ang)
        nx, ny = -math.sin(ang)*8, math.cos(ang)*8
        d.line([(px+nx, py+ny), (px-nx, py-ny)], fill='#555555', width=2)
    for t, r in rect.items():
        stub = t in stubs
        d.rectangle(r, fill='#f4f4f4' if stub else 'white', outline='black', width=2)
        d.rectangle((r[0], r[1], r[2], r[1] + HEAD), fill='#d9d9d9' if not stub else '#eeeeee', outline='black', width=2)
        d.text((r[0] + 10, r[1] + 7), t + (' (см. др. схему)' if stub else ''), font=FB, fill='black')
        if stub: continue
        y = r[1] + HEAD + 4
        for c, typ in COLS[t]:
            tag = 'PK' if c in PK.get(t, ()) else ''
            if (t, c) in FKCOL: tag = (tag + ',FK') if tag else 'FK'
            d.text((r[0] + 8, y), f'{tag:<5}', font=FM, fill='#000000')
            d.text((r[0] + 62, y), c, font=FM, fill='black' if not tag else '#000000')
            tw = d.textlength(typ, font=FS)
            d.text((r[2] - 8 - tw, y + 1), typ, font=FS, fill='#444444')
            if 'PK' in tag: d.line([(r[0] + 62, y + LH - 4), (r[0] + 62 + d.textlength(c, font=FM), y + LH - 4)], fill='black')
            y += LH
    img.save(os.path.join(HERE, name), dpi=(200, 200))
    print('saved', name, img.size)

er('er_1_accounts.png', 'Схема 1. Учётные записи, персонажи, мир', {
    'players': (0, 0), 'characters': (1, 0), 'character_classes': (2, 0), 'class_base_attributes': (3, 0),
    'player_settings': (0, 1), 'character_attributes': (1, 1), 'attributes': (2, 1), 'level_thresholds': (3, 1),
    'sessions': (0, 2), 'locations': (1, 2), 'location_links': (2, 2), 'factions': (3, 2),
    'game_saves': (0, 3), 'character_fragments': (1, 3), 'memory_fragments': (2, 3), 'character_reputation': (3, 3)})
er('er_2_items.png', 'Схема 2. Предметы, инвентарь, экономика', {
    'characters': (0, 0), 'item_templates': (1, 0), 'vendor_stock': (2, 0), 'npcs': (3, 0),
    'inventory': (0, 1), 'item_instances': (1, 1), 'enemy_loot': (2, 1), 'audit_log': (3, 1),
    'equipment': (0, 2), 'item_transfers': (1, 2), 'transactions': (2, 2)}, stubs={'characters', 'npcs'})
er('er_3_quests.png', 'Схема 3. Квесты, NPC, навыки, достижения', {
    'locations': (0, 0), 'npcs': (1, 0), 'factions': (2, 0), 'item_templates': (3, 0),
    'quest_prerequisites': (0, 1), 'quests': (1, 1), 'quest_objectives': (2, 1), 'quest_reward_items': (3, 1),
    'characters': (0, 2), 'character_quests': (1, 2), 'quest_progress': (2, 2), 'skills': (3, 2),
    'achievements': (0, 3), 'character_achievements': (1, 3), 'character_skills': (2, 3), 'skill_prerequisites': (3, 3)},
   stubs={'locations', 'factions', 'item_templates', 'characters'})

# ------------------------------------------------------------------ графики
R = json.load(open(os.path.join(HERE, '..', 'bench', 'results.json'), encoding='utf-8'))
RX = json.load(open(os.path.join(HERE, '..', 'bench', 'results_extra.json'), encoding='utf-8'))
FA, FAB = font('arial.ttf', 22), font('arialbd.ttf', 24)

def hbar_log(name, title, labels, series, colors, legend, unit='мс'):
    W, rowh = 1800, 64
    H = 160 + rowh * len(labels) + 90
    img = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(img)
    d.text((40, 24), title, font=FAB, fill='black')
    x0, x1 = 560, W - 180
    vals = [v for s in series for v in s if v > 0]
    lo, hi = math.floor(math.log10(min(vals))), math.ceil(math.log10(max(vals)))
    def X(v): return x0 + (math.log10(max(v, 10 ** lo)) - lo) / (hi - lo) * (x1 - x0)
    ytop = 120
    for e in range(lo, hi + 1):
        x = X(10 ** e); d.line([(x, ytop - 10), (x, ytop + rowh * len(labels))], fill='#cccccc')
        lab = f'{10**e:g} {unit}'; d.text((x - d.textlength(lab, font=FA) / 2, ytop + rowh * len(labels) + 8), lab, font=FA, fill='black')
    bh = (rowh - 18) / len(series)
    for i, lab in enumerate(labels):
        y = ytop + i * rowh
        d.text((x0 - 16 - d.textlength(lab, font=FA), y + rowh / 2 - 14), lab, font=FA, fill='black')
        for k, s in enumerate(series):
            yy = y + 6 + k * bh
            d.rectangle((x0, yy, X(s[i]), yy + bh - 3), fill=colors[k], outline='black')
            txt = f'{s[i]:.3f}' if s[i] < 1 else f'{s[i]:.1f}'
            d.text((X(s[i]) + 8, yy + bh / 2 - 12), txt, font=FA, fill='black')
    lx = x0
    for k, lg in enumerate(legend):
        d.rectangle((lx, 78, lx + 30, 100), fill=colors[k], outline='black'); d.text((lx + 40, 75), lg, font=FA, fill='black')
        lx += 60 + d.textlength(lg, font=FA)
    img.save(os.path.join(HERE, name), dpi=(200, 200)); print('saved', name)

keys = [f'Q{i}' for i in range(1, 16)]
hbar_log('chart_indexes.png', 'Время выполнения запросов (медиана 25 запусков, логарифмическая шкала)',
         [f"{k}. {R['with_indexes'][k]['title']}" for k in keys],
         [[R['without_indexes'][k]['median_ms'] for k in keys], [R['with_indexes'][k]['median_ms'] for k in keys]],
         ['#bdbdbd', '#3a3a3a'], ['Без дополнительных индексов', 'С индексами'])

def vbars(name, title, groups, series, colors, legend, ylab):
    W, H = 1600, 900
    img = Image.new('RGB', (W, H), 'white'); d = ImageDraw.Draw(img)
    d.text((40, 24), title, font=FAB, fill='black')
    x0, y0, x1, y1 = 160, 140, W - 60, H - 120
    mx = max(v for s in series for v in s) * 1.15
    step = 10 ** math.floor(math.log10(mx / 5)); step *= 5 if mx / step > 25 else (2 if mx / step > 10 else 1)
    v = 0
    while v <= mx:
        y = y1 - v / mx * (y1 - y0); d.line([(x0, y), (x1, y)], fill='#dddddd'); lab = f'{v:g}'
        d.text((x0 - 12 - d.textlength(lab, font=FA), y - 13), lab, font=FA, fill='black'); v += step
    d.text((40, y0 - 50), ylab, font=FA, fill='black')
    gw = (x1 - x0) / len(groups); bw = gw * 0.7 / len(series)
    for i, g in enumerate(groups):
        gx = x0 + i * gw + gw * 0.15
        for k, s in enumerate(series):
            x = gx + k * bw; y = y1 - s[i] / mx * (y1 - y0)
            d.rectangle((x, y, x + bw - 6, y1), fill=colors[k], outline='black')
            lab = f'{s[i]:.0f}'; d.text((x + (bw - 6) / 2 - d.textlength(lab, font=FA) / 2, y - 30), lab, font=FA, fill='black')
        d.text((gx + gw * 0.35 - d.textlength(g, font=FA) / 2, y1 + 14), g, font=FA, fill='black')
    d.line([(x0, y1), (x1, y1)], fill='black', width=2)
    lx = x0
    for k, lg in enumerate(legend):
        d.rectangle((lx, 82, lx + 30, 104), fill=colors[k], outline='black'); d.text((lx + 40, 79), lg, font=FA, fill='black')
        lx += 60 + d.textlength(lg, font=FA)
    img.save(os.path.join(HERE, name), dpi=(200, 200)); print('saved', name)

cl = [str(x['clients']) + ' клиент.' for x in R['pgbench_read']]
noidx = {x['clients']: x['tps'] for x in R['pgbench_read_noidx']}
vbars('chart_tps_read.png', 'Пропускная способность: смешанная нагрузка чтения (pgbench, 10 с)', cl,
      [[noidx.get(x['clients'], 0) for x in R['pgbench_read']], [x['tps'] for x in R['pgbench_read']]],
      ['#bdbdbd', '#3a3a3a'], ['Без индексов (измерено для 1 и 16 клиентов)', 'С индексами'], 'транзакций в секунду (TPS)')
vbars('chart_tps_write.png', 'Пропускная способность: транзакции записи (передача предметов)', cl,
      [[x['tps'] for x in R['pgbench_write']], [x['tps'] for x in RX['write_async']]],
      ['#bdbdbd', '#3a3a3a'], ['synchronous_commit = on', 'synchronous_commit = off'], 'транзакций в секунду (TPS)')
