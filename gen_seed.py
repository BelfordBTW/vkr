# -*- coding: utf-8 -*-
"""Генерирует sql/04_seed.sql — справочные данные игры «Эхо кода» отдельными операторами INSERT."""
import json, math, os

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sql', '04_seed.sql')
L = []
def q(s): return "'" + str(s).replace("'", "''") + "'"
def js(o): return q(json.dumps(o, ensure_ascii=False)) + '::jsonb'
def ins(table, cols, vals):
    L.append(f"INSERT INTO {table} ({', '.join(cols)}) VALUES ({', '.join(vals)});")

L += ['-- =====================================================================',
      '-- Файл 4. Справочные данные (наполнение базы игровыми элементами)',
      '-- Сгенерирован скриптом gen_seed.py',
      '-- =====================================================================',
      'SET search_path TO game, public;', '']

L.append('-- Фракции')
for c, n, d in [('nexus', 'Корпорация «Нексус»', 'Владелец виртуальной реальности и ИИ-стража'),
                ('ghosts', 'Призраки сети', 'Подпольное сообщество хакеров'),
                ('sentinels', 'Стражи ИИ', 'Охранные программы ядра'),
                ('freelancers', 'Вольные хакеры', 'Наёмники, торгующие данными')]:
    ins('factions', ['code', 'name', 'description'], [q(c), q(n), q(d)])

L.append('\n-- Локации (сектор, мин. уровень, безопасная зона, координаты)')
LOC = [('neon_rooftops', 'Неоновые крыши', 1, 1, True, (10, 40)), ('market_alley', 'Рыночный переулок', 1, 2, True, (18, 44)),
       ('antenna_field', 'Поле антенн', 1, 3, False, (25, 38)), ('data_bridge', 'Мост данных', 1, 5, False, (34, 40)),
       ('server_farms', 'Серверные фермы', 2, 8, False, (45, 30)), ('cooling_tunnels', 'Туннели охлаждения', 2, 10, False, (52, 22)),
       ('archive_vault', 'Хранилище архива', 2, 12, False, (60, 28)), ('backup_hub', 'Резервный узел', 2, 14, True, (58, 35)),
       ('firewall_gate', 'Врата файрвола', 3, 16, False, (70, 30)), ('ai_core', 'Ядро ИИ', 3, 20, False, (80, 32)),
       ('core_node_a', 'Узел защиты A', 3, 18, False, (76, 26)), ('core_node_b', 'Узел защиты B', 3, 18, False, (84, 26))]
for c, n, s, lv, safe, (x, y) in LOC:
    ins('locations', ['code', 'name', 'sector', 'min_level', 'is_safe', 'pos', 'description'],
        [q(c), q(n), str(s), str(lv), 'true' if safe else 'false', f"point({x},{y})", q(f'Сектор {s}: {n.lower()}')])
LINKS = [(1, 2, 20), (2, 1, 20), (1, 3, 30), (3, 1, 30), (3, 4, 25), (4, 3, 25), (4, 5, 60), (5, 4, 60), (5, 6, 30), (6, 5, 30),
         (5, 8, 20), (8, 5, 20), (6, 7, 35), (7, 6, 35), (7, 8, 25), (8, 7, 25), (8, 9, 70), (9, 8, 70), (9, 11, 30), (9, 12, 30),
         (11, 10, 20), (12, 10, 20)]
L.append('\n-- Переходы между локациями')
for a, b, t in LINKS:
    ins('location_links', ['from_location_id', 'to_location_id', 'travel_seconds'], [str(a), str(b), str(t)])

L.append('\n-- Классы персонажей')
CLS = [('hacker', 'Хакер', 'Взлом и замедление времени', 5, 100), ('infiltrator', 'Инфильтратор', 'Скрытность и скорость', 5, 90),
       ('technician', 'Техник', 'Дроны и ловушки', 6, 80), ('operator', 'Оператор', 'Выносливость и контроль', 7, 70)]
for c, n, d, hp, en in CLS:
    ins('character_classes', ['code', 'name', 'description', 'base_hp', 'base_energy'], [q(c), q(n), q(d), str(hp), str(en)])
L.append('\n-- Характеристики')
ATTR = [('hack', 'Взлом'), ('stealth', 'Скрытность'), ('agility', 'Ловкость'), ('tech', 'Техника'), ('reflex', 'Реакция'), ('will', 'Воля')]
for c, n in ATTR:
    ins('attributes', ['code', 'name'], [q(c), q(n)])
BASE = [[8, 5, 5, 4, 5, 3], [4, 9, 7, 3, 5, 2], [5, 3, 4, 9, 4, 5], [3, 4, 5, 5, 6, 7]]
L.append('\n-- Стартовые характеристики классов')
for ci, row in enumerate(BASE, 1):
    for ai, v in enumerate(row, 1):
        ins('class_base_attributes', ['class_id', 'attr_id', 'value'], [str(ci), str(ai), str(v)])

L.append('\n-- Таблица опыта (50 уровней)')
for lv in range(1, 51):
    xp = 0 if lv == 1 else int(round(100 * (lv - 1) ** 1.8))
    ins('level_thresholds', ['level', 'xp_required', 'skill_points'], [str(lv), str(xp), str(2 if lv % 5 == 0 else 1)])

L.append('\n-- Предметы')
ITEMS = [
    # code, name, category, rarity, lvl, stack, price, tradeable, slot, stats, desc
    ('neuro_cable', 'Нейро-кабель', 'implant', 'rare', 1, 1, 400, True, 'implant1', {'hack_time': 0.4}, 'Прямое подключение к терминалу'),
    ('crypto_module', 'Крипто-модуль', 'implant', 'epic', 5, 1, 1200, True, 'implant1', {'hack_len': -1}, 'Подбирает часть ключа заранее'),
    ('visor', 'Визор', 'implant', 'rare', 3, 1, 600, True, 'implant1', {'detect_delay': 0.4}, 'Глушит сканеры противника'),
    ('companion_drone', 'Дрон', 'implant', 'epic', 8, 1, 1500, True, 'implant1', {'energy_regen': 0.5}, 'Компаньон-аккумулятор'),
    ('holo_deck', 'Голо-дек', 'implant', 'legendary', 15, 1, 5000, False, 'implant1', {'max_hp': 2}, 'Резервная копия сознания'),
    ('reflex_booster', 'Ускоритель рефлексов', 'implant', 'rare', 6, 1, 700, True, 'implant1', {'slow_drain': -0.2}, 'Экономит энергию замедления'),
    ('ghost_skin', 'Призрачная кожа', 'implant', 'epic', 10, 1, 1800, True, 'implant1', {'stealth': 3}, 'Оптический камуфляж'),
    ('jump_servo', 'Прыжковый сервопривод', 'implant', 'rare', 4, 1, 650, True, 'implant1', {'jump': 0.1}, 'Повышает прыжок'),
    ('overclock_chip', 'Чип разгона', 'implant', 'epic', 12, 1, 2100, True, 'implant1', {'hack': 2, 'max_hp': -1}, 'Мощнее взлом, хрупче тело'),
    ('mirror_core', 'Зеркальное ядро', 'implant', 'legendary', 18, 1, 7000, False, 'implant1', {'reflect': 0.25}, 'Отражает снаряды'),
    ('pulse_pistol', 'Импульсный пистолет', 'weapon', 'common', 1, 1, 150, True, 'weapon', {'damage': 6, 'rate': 2.0}, 'Стандартное оружие'),
    ('ion_blade', 'Ионный клинок', 'weapon', 'rare', 4, 1, 520, True, 'weapon', {'damage': 12, 'rate': 1.5}, 'Ближний бой'),
    ('emp_launcher', 'ЭМИ-пускатель', 'weapon', 'epic', 9, 1, 1600, True, 'weapon', {'damage': 18, 'emp': True}, 'Отключает дронов'),
    ('glitch_rifle', 'Глитч-винтовка', 'weapon', 'rare', 7, 1, 900, True, 'weapon', {'damage': 15, 'rate': 1.2}, 'Пробивает щиты'),
    ('nano_whip', 'Нано-хлыст', 'weapon', 'epic', 11, 1, 1900, True, 'weapon', {'damage': 20, 'range': 3}, 'Дальний ближний бой'),
    ('null_pointer', 'Нулевой указатель', 'weapon', 'legendary', 20, 1, 9000, False, 'weapon', {'damage': 35, 'crit': 0.2}, 'Легенда сети'),
    ('stun_baton', 'Шоковая дубинка', 'weapon', 'common', 2, 1, 200, True, 'weapon', {'damage': 8, 'stun': 1.0}, 'Оглушение'),
    ('arc_caster', 'Дуговой излучатель', 'weapon', 'rare', 6, 1, 800, True, 'weapon', {'damage': 14, 'chain': 2}, 'Цепная молния'),
    ('static_hood', 'Статический капюшон', 'armor', 'common', 1, 1, 120, True, 'head', {'armor': 2}, 'Базовая защита'),
    ('neon_jacket', 'Неоновая куртка', 'armor', 'common', 1, 1, 180, True, 'body', {'armor': 3}, 'Куртка хакера'),
    ('grip_gloves', 'Цепкие перчатки', 'armor', 'common', 2, 1, 110, True, 'hands', {'armor': 1, 'hack': 1}, 'Удобны для взлома'),
    ('shadow_mask', 'Теневая маска', 'armor', 'rare', 5, 1, 640, True, 'head', {'armor': 3, 'stealth': 2}, 'Скрывает лицо от камер'),
    ('carbon_vest', 'Карбоновый жилет', 'armor', 'rare', 6, 1, 750, True, 'body', {'armor': 6}, 'Лёгкая броня'),
    ('signal_gloves', 'Сигнальные перчатки', 'armor', 'rare', 7, 1, 690, True, 'hands', {'armor': 2, 'hack': 2}, 'Усилитель сигнала'),
    ('nexus_helm', 'Шлем «Нексуса»', 'armor', 'epic', 12, 1, 2200, True, 'head', {'armor': 6, 'reflex': 2}, 'Трофейный шлем охраны'),
    ('phase_coat', 'Фазовый плащ', 'armor', 'epic', 13, 1, 2600, True, 'body', {'armor': 8, 'stealth': 3}, 'Сдвигает силуэт'),
    ('core_gauntlets', 'Рукавицы ядра', 'armor', 'legendary', 19, 1, 6500, False, 'hands', {'armor': 5, 'hack': 5}, 'Созданы ИИ'),
    ('sentinel_plate', 'Броня стража', 'armor', 'legendary', 20, 1, 8000, False, 'body', {'armor': 14}, 'Броня ИИ-стража'),
    ('stim_pack', 'Стимулятор', 'consumable', 'common', 1, 20, 40, True, None, {'heal': 2}, 'Восстанавливает 2 здоровья'),
    ('energy_cell', 'Энергоячейка', 'consumable', 'common', 1, 20, 50, True, None, {'energy': 40}, 'Восстанавливает энергию'),
    ('smoke_grenade', 'Дымовая граната', 'consumable', 'rare', 3, 10, 120, True, None, {'stealth_zone': 4}, 'Создаёт тень'),
    ('decoy_beacon', 'Маяк-приманка', 'consumable', 'rare', 5, 10, 150, True, None, {'distract': 5}, 'Отвлекает дронов'),
    ('overclock_shot', 'Инъекция разгона', 'consumable', 'epic', 9, 5, 400, True, None, {'slow_free': 3}, 'Бесплатное замедление 3 с'),
    ('repair_kit', 'Ремкомплект', 'consumable', 'common', 2, 10, 90, True, None, {'durability': 30}, 'Чинит снаряжение'),
    ('hack_script', 'Скрипт взлома', 'consumable', 'rare', 4, 10, 200, True, None, {'auto_key': 1}, 'Вводит одну клавишу'),
    ('firewall_patch', 'Заплатка файрвола', 'consumable', 'epic', 14, 5, 650, True, None, {'alarm_clear': True}, 'Сбрасывает тревогу'),
    ('ram_chip', 'Чип памяти', 'consumable', 'common', 1, 50, 25, True, None, {'xp': 50}, 'Немного опыта'),
    ('cooling_gel', 'Охлаждающий гель', 'consumable', 'common', 3, 20, 60, True, None, {'energy_regen': 0.3}, 'Временный бонус'),
    ('data_shard', 'Осколок данных', 'quest', 'common', 1, 99, 0, False, None, {}, 'Фрагмент чужих данных'),
    ('access_key_a', 'Ключ доступа A', 'quest', 'rare', 1, 1, 0, False, None, {}, 'Открывает узел A'),
    ('access_key_b', 'Ключ доступа B', 'quest', 'rare', 1, 1, 0, False, None, {}, 'Открывает узел B'),
    ('ghost_memory', 'Воспоминание Призрака', 'quest', 'epic', 1, 1, 0, False, None, {}, 'Сюжетный предмет'),
    ('nexus_badge', 'Пропуск «Нексуса»', 'quest', 'rare', 1, 1, 0, False, None, {}, 'Служебный пропуск'),
    ('core_fragment', 'Фрагмент ядра', 'quest', 'legendary', 1, 3, 0, False, None, {}, 'Часть ядра ИИ'),
    ('encrypted_log', 'Зашифрованный журнал', 'quest', 'common', 1, 10, 0, False, None, {}, 'Требует расшифровки'),
    ('broken_drone', 'Сломанный дрон', 'quest', 'common', 1, 5, 0, False, None, {}, 'Для техника'),
    ('copper_wire', 'Медный провод', 'material', 'common', 1, 99, 5, True, None, {}, 'Материал для крафта'),
    ('silicon_wafer', 'Кремниевая пластина', 'material', 'common', 1, 99, 12, True, None, {}, 'Материал'),
    ('neon_tube', 'Неоновая трубка', 'material', 'common', 1, 99, 8, True, None, {}, 'Материал'),
    ('quantum_bit', 'Квантовый бит', 'material', 'rare', 5, 99, 60, True, None, {}, 'Редкий материал'),
    ('ai_residue', 'Остаток ИИ', 'material', 'epic', 10, 99, 220, True, None, {}, 'Остаётся после стражей'),
    ('carbon_fiber', 'Углеволокно', 'material', 'common', 2, 99, 15, True, None, {}, 'Материал'),
    ('optic_lens', 'Оптическая линза', 'material', 'rare', 4, 99, 45, True, None, {}, 'Материал'),
    ('plasma_cell', 'Плазменная ячейка', 'material', 'rare', 6, 99, 70, True, None, {}, 'Материал'),
    ('nexus_alloy', 'Сплав «Нексуса»', 'material', 'epic', 12, 99, 300, True, None, {}, 'Материал'),
    ('legacy_code', 'Устаревший код', 'material', 'legendary', 18, 99, 900, True, None, {}, 'Очень редкий материал'),
]
ICOLS = ['code', 'name', 'category', 'rarity', 'level_req', 'max_stack', 'base_price', 'is_tradeable', 'equip_slot', 'stats', 'description']
for c, n, cat, r, lv, st, pr, tr, slot, stats, d in ITEMS:
    ins('item_templates', ICOLS, [q(c), q(n), q(cat), q(r), str(lv), str(st), str(pr), 'true' if tr else 'false',
                                  q(slot) if slot else 'NULL', js(stats), q(d)])
ITEM_ID = {it[0]: i for i, it in enumerate(ITEMS, 1)}
L.append(f"UPDATE location_links SET requires_item_id = {ITEM_ID['access_key_a']} WHERE from_location_id = 9 AND to_location_id = 11;")
L.append(f"UPDATE location_links SET requires_item_id = {ITEM_ID['access_key_b']} WHERE from_location_id = 9 AND to_location_id = 12;")

L.append('\n-- Навыки')
SK = [('quick_hack', 'Быстрый взлом', 1, 5, 0, 0, 1), ('time_dilation', 'Замедление времени', 1, 5, 35, 0, 1),
      ('double_jump', 'Двойной прыжок', None, 1, 0, 0, 1), ('chain_hack', 'Цепной взлом', 1, 3, 20, 8000, 8),
      ('system_override', 'Перехват системы', 1, 3, 50, 30000, 15), ('shadow_step', 'Шаг в тень', 2, 5, 15, 5000, 1),
      ('silent_run', 'Бесшумный бег', 2, 5, 0, 0, 3), ('vanish', 'Исчезновение', 2, 3, 40, 20000, 10),
      ('drone_deploy', 'Запуск дрона', 3, 5, 25, 10000, 1), ('emp_trap', 'ЭМИ-ловушка', 3, 3, 30, 12000, 6),
      ('overcharge', 'Перегрузка', 3, 3, 45, 25000, 12), ('fortify', 'Укрепление', 4, 5, 20, 15000, 1),
      ('taunt_protocol', 'Протокол приманки', 4, 3, 25, 18000, 6), ('adrenal_surge', 'Выброс адреналина', 4, 3, 40, 30000, 12),
      ('scanner', 'Сканер', None, 3, 10, 6000, 2), ('lockpick', 'Отмычка', None, 3, 0, 0, 2),
      ('first_aid', 'Первая помощь', None, 3, 20, 20000, 4), ('wall_cling', 'Цепкость', None, 1, 0, 0, 6),
      ('data_mining', 'Добыча данных', None, 5, 0, 0, 5), ('trade_sense', 'Чутьё торговца', None, 5, 0, 0, 3)]
for c, n, cl, mr, en, cd, lv in SK:
    ins('skills', ['code', 'name', 'class_id', 'max_rank', 'energy_cost', 'cooldown_ms', 'level_req'],
        [q(c), q(n), str(cl) if cl else 'NULL', str(mr), str(en), str(cd), str(lv)])
SKID = {s[0]: i for i, s in enumerate(SK, 1)}
L.append('\n-- Дерево навыков')
for a, b, r in [('chain_hack', 'quick_hack', 2), ('system_override', 'chain_hack', 2), ('system_override', 'time_dilation', 3),
                ('vanish', 'shadow_step', 3), ('vanish', 'silent_run', 2), ('emp_trap', 'drone_deploy', 2),
                ('overcharge', 'emp_trap', 2), ('adrenal_surge', 'fortify', 3), ('taunt_protocol', 'fortify', 1),
                ('wall_cling', 'double_jump', 1), ('data_mining', 'scanner', 2), ('first_aid', 'scanner', 1)]:
    ins('skill_prerequisites', ['skill_id', 'requires_skill_id', 'min_rank'], [str(SKID[a]), str(SKID[b]), str(r)])

L.append('\n-- Неигровые персонажи')
NPC = [('ghost_echo', 'Эхо', 1, 2, 'quest_giver', 1, ['Ты снова здесь, Призрак?', 'Твои воспоминания разбросаны по секторам.']),
       ('vendor_lin', 'Торговка Лин', 2, 4, 'vendor', 5, ['Импланты, стимуляторы, всё по-честному.']),
       ('patrol_drone_1', 'Дрон-патрульный', 3, 3, 'enemy', 3, []), ('patrol_drone_2', 'Дрон-патрульный', 4, 3, 'enemy', 5, []),
       ('bridge_keeper', 'Смотритель моста', 4, 1, 'quest_giver', 6, ['Мост закрыт. Нужен пропуск «Нексуса».']),
       ('rooftop_rat', 'Крышная Крыса', 1, 4, 'vendor', 2, ['Дымовые гранаты, дёшево!']),
       ('farm_admin', 'Администратор фермы', 5, 1, 'quest_giver', 9, ['Серверы перегреваются. Помоги — и я помогу.']),
       ('cooling_bot', 'Бот охлаждения', 6, 1, 'neutral', 8, ['ТЕМПЕРАТУРА: КРИТИЧЕСКАЯ.']),
       ('camera_unit', 'Камера наблюдения', 5, 3, 'enemy', 9, []), ('hunter_drone', 'Дрон-охотник', 6, 3, 'enemy', 11, []),
       ('archivist', 'Архивариус', 7, 2, 'quest_giver', 12, ['Архив помнит всё. Даже то, что ты забыл.']),
       ('vendor_kade', 'Барыга Кейд', 8, 4, 'vendor', 14, ['Редкие материалы. Плати кредитами.']),
       ('vault_guard', 'Страж архива', 7, 3, 'enemy', 13, []), ('hub_medic', 'Медик узла', 8, 2, 'quest_giver', 14, ['Подлатаю, если поможешь.']),
       ('firewall_warden', 'Надзиратель файрвола', 9, 3, 'enemy', 17, []),
       ('rebel_lead', 'Лидер сопротивления', 8, 2, 'quest_giver', 15, ['Ядро можно перезагрузить. Нужны три ключа.']),
       ('node_sentinel_a', 'Страж узла A', 11, 3, 'enemy', 19, []), ('node_sentinel_b', 'Страж узла B', 12, 3, 'enemy', 19, []),
       ('ai_guardian', 'ИИ-страж', 10, 3, 'enemy', 25, ['ДОСТУП ЗАПРЕЩЁН.', 'ТЫ — ОШИБКА.']),
       ('market_oracle', 'Оракул рынка', 2, 4, 'neutral', 4, ['Цены растут, когда растёт тревога.']),
       ('antenna_tech', 'Техник антенн', 3, 2, 'quest_giver', 3, ['Антенны сбоят. Нужны медные провода.']),
       ('vendor_nova', 'Нова', 5, 4, 'vendor', 9, ['Оружие для тех, кто не прячется.']),
       ('tunnel_ghost', 'Тоннельный призрак', 6, 2, 'neutral', 10, ['Здесь холодно... и тихо.']),
       ('nexus_clerk', 'Клерк «Нексуса»', 4, 1, 'vendor', 6, ['Служебные пропуска — только для своих.']),
       ('core_echo', 'Отголосок ядра', 10, 3, 'neutral', 20, ['Я был создан защищать.'])]
for c, n, loc, fac, role, lv, dlg in NPC:
    ins('npcs', ['code', 'name', 'location_id', 'faction_id', 'role', 'level', 'dialog'],
        [q(c), q(n), str(loc), str(fac), q(role), str(lv), js(dlg)])
NPCID = {x[0]: i for i, x in enumerate(NPC, 1)}

L.append('\n-- Ассортимент торговцев')
STOCK = {'vendor_lin': [('neuro_cable', 450, 3), ('visor', 650, 2), ('stim_pack', 45, None), ('energy_cell', 55, None), ('jump_servo', 700, 2)],
         'rooftop_rat': [('smoke_grenade', 130, 20), ('decoy_beacon', 160, 10), ('stim_pack', 40, None), ('copper_wire', 6, None), ('static_hood', 130, 3)],
         'vendor_kade': [('quantum_bit', 70, 30), ('plasma_cell', 80, 30), ('optic_lens', 50, None), ('nexus_alloy', 340, 5), ('ai_residue', 250, 5)],
         'vendor_nova': [('pulse_pistol', 160, None), ('ion_blade', 560, 4), ('glitch_rifle', 950, 2), ('arc_caster', 850, 2), ('stun_baton', 210, None)],
         'nexus_clerk': [('neon_jacket', 190, None), ('grip_gloves', 120, None), ('carbon_vest', 780, 3), ('repair_kit', 95, None), ('hack_script', 210, 10)]}
for npc, lst in STOCK.items():
    for code, price, stock in lst:
        ins('vendor_stock', ['npc_id', 'item_id', 'price', 'stock'], [str(NPCID[npc]), str(ITEM_ID[code]), str(price), str(stock) if stock is not None else 'NULL'])

L.append('\n-- Добыча с противников')
LOOT = [('patrol_drone_1', 'copper_wire', 0.6, 1, 3), ('patrol_drone_1', 'stim_pack', 0.15, 1, 1), ('patrol_drone_2', 'neon_tube', 0.5, 1, 2),
        ('patrol_drone_2', 'energy_cell', 0.2, 1, 1), ('camera_unit', 'optic_lens', 0.4, 1, 1), ('camera_unit', 'silicon_wafer', 0.5, 1, 2),
        ('hunter_drone', 'plasma_cell', 0.35, 1, 2), ('hunter_drone', 'broken_drone', 0.25, 1, 1), ('vault_guard', 'encrypted_log', 0.5, 1, 1),
        ('vault_guard', 'quantum_bit', 0.3, 1, 2), ('firewall_warden', 'nexus_alloy', 0.25, 1, 1), ('firewall_warden', 'firewall_patch', 0.1, 1, 1),
        ('node_sentinel_a', 'access_key_a', 1.0, 1, 1), ('node_sentinel_a', 'ai_residue', 0.4, 1, 2), ('node_sentinel_b', 'access_key_b', 1.0, 1, 1),
        ('node_sentinel_b', 'ai_residue', 0.4, 1, 2), ('ai_guardian', 'core_fragment', 1.0, 1, 1), ('ai_guardian', 'legacy_code', 0.2, 1, 1),
        ('ai_guardian', 'sentinel_plate', 0.05, 1, 1), ('hunter_drone', 'carbon_fiber', 0.5, 1, 3)]
for npc, code, ch, a, b in LOOT:
    ins('enemy_loot', ['npc_id', 'item_id', 'chance', 'min_qty', 'max_qty'], [str(NPCID[npc]), str(ITEM_ID[code]), str(ch), str(a), str(b)])

L.append('\n-- Квесты')
QS = [('wake_up', 'Пробуждение', 'Осмотреться на неоновых крышах и найти Эхо.', 'ghost_echo', 1, 1, True, False, 100, 50,
       [('reach', 'neon_rooftops', 1, 'Добраться до Эхо'), ('talk', 'ghost_echo', 1, 'Поговорить с Эхо')], []),
      ('first_hack', 'Первый взлом', 'Взломать терминал двери на крышах.', 'ghost_echo', 1, 1, True, False, 150, 80,
       [('hack', 'terminal_a', 1, 'Взломать терминал A')], [('neuro_cable', 1)]),
      ('shadow_lesson', 'Урок тени', 'Пройти мимо дрона, не подняв тревогу.', 'ghost_echo', 1, 2, True, False, 200, 100,
       [('stealth', 'patrol_drone_1', 1, 'Пройти незамеченным')], []),
      ('antenna_fix', 'Сбойные антенны', 'Собрать медные провода для техника.', 'antenna_tech', 3, 3, False, False, 180, 150,
       [('collect', 'copper_wire', 10, 'Собрать 10 медных проводов')], [('repair_kit', 2)]),
      ('bridge_pass', 'Пропуск на мост', 'Добыть пропуск «Нексуса».', 'bridge_keeper', 4, 5, True, False, 300, 200,
       [('collect', 'nexus_badge', 1, 'Добыть пропуск'), ('talk', 'bridge_keeper', 1, 'Показать пропуск смотрителю')], []),
      ('market_rumors', 'Слухи рынка', 'Узнать у оракула о Призраке.', 'ghost_echo', 2, 2, False, False, 120, 60,
       [('talk', 'market_oracle', 1, 'Поговорить с оракулом')], []),
      ('overheat', 'Перегрев', 'Охладить три стойки серверной фермы.', 'farm_admin', 5, 8, True, False, 500, 300,
       [('hack', 'cooling_terminal', 3, 'Взломать 3 терминала охлаждения')], [('crypto_module', 1)]),
      ('tunnel_run', 'Бег по туннелям', 'Пройти туннели охлаждения за 2 минуты.', 'farm_admin', 6, 10, False, True, 250, 120,
       [('reach', 'cooling_tunnels', 1, 'Пройти туннели')], [('cooling_gel', 3)]),
      ('broken_wings', 'Сломанные крылья', 'Собрать обломки дронов-охотников.', 'hub_medic', 8, 10, False, True, 220, 150,
       [('collect', 'broken_drone', 3, 'Собрать 3 сломанных дрона')], [('stim_pack', 5)]),
      ('archive_secrets', 'Тайны архива', 'Расшифровать журналы хранилища.', 'archivist', 7, 12, True, False, 700, 400,
       [('collect', 'encrypted_log', 3, 'Найти 3 журнала'), ('hack', 'archive_console', 1, 'Расшифровать на консоли')], [('visor', 1)]),
      ('lost_memory', 'Утерянная память', 'Найти воспоминание Призрака в архиве.', 'archivist', 7, 12, True, False, 800, 0,
       [('collect', 'ghost_memory', 1, 'Найти воспоминание')], []),
      ('medic_supply', 'Поставки медика', 'Принести стимуляторы в резервный узел.', 'hub_medic', 8, 13, False, True, 200, 250,
       [('collect', 'stim_pack', 5, 'Принести 5 стимуляторов')], []),
      ('rebel_contact', 'Связь с сопротивлением', 'Встретиться с лидером сопротивления.', 'rebel_lead', 8, 14, True, False, 400, 200,
       [('talk', 'rebel_lead', 1, 'Поговорить с лидером')], []),
      ('firewall_breach', 'Пролом файрвола', 'Прорваться через врата файрвола.', 'rebel_lead', 9, 16, True, False, 1000, 500,
       [('defeat', 'firewall_warden', 1, 'Победить надзирателя'), ('reach', 'firewall_gate', 1, 'Пройти врата')], [('companion_drone', 1)]),
      ('node_a', 'Узел A', 'Взломать узел защиты A.', 'rebel_lead', 11, 18, True, False, 1200, 600,
       [('hack', 'core_node_a', 1, 'Взломать узел A')], []),
      ('node_b', 'Узел B', 'Взломать узел защиты B.', 'rebel_lead', 12, 18, True, False, 1200, 600,
       [('hack', 'core_node_b', 1, 'Взломать узел B')], []),
      ('core_reboot', 'Перезагрузка ядра', 'Взломать центральный узел и перезагрузить ИИ-стража.', 'rebel_lead', 10, 20, True, False, 3000, 2000,
       [('hack', 'core_node_c', 1, 'Взломать узел C'), ('reach', 'ai_core', 1, 'Войти в ядро')], [('holo_deck', 1)]),
      ('ghost_protocol', 'Протокол «Призрак»', 'Пройти сектор без единого обнаружения.', 'ghost_echo', 4, 6, False, True, 400, 300,
       [('stealth', 'sector_any', 1, 'Пройти сектор незамеченным')], [('smoke_grenade', 3)]),
      ('data_hoarder', 'Собиратель данных', 'Собрать 20 осколков данных.', 'vendor_kade', 8, 10, False, True, 300, 400,
       [('collect', 'data_shard', 20, 'Собрать 20 осколков')], []),
      ('echo_farewell', 'Прощание с Эхо', 'Вернуться к Эхо после перезагрузки ядра.', 'ghost_echo', 1, 20, True, False, 500, 0,
       [('talk', 'ghost_echo', 1, 'Поговорить с Эхо')], [])]
QID = {x[0]: i for i, x in enumerate(QS, 1)}
for (c, n, d, giver, loc, lv, main, rep, xp, cr, objs, rew) in QS:
    ins('quests', ['code', 'name', 'description', 'giver_npc_id', 'location_id', 'min_level', 'is_main', 'is_repeatable', 'xp_reward', 'credits_reward'],
        [q(c), q(n), q(d), str(NPCID[giver]), str(loc), str(lv), 'true' if main else 'false', 'true' if rep else 'false', str(xp), str(cr)])
L.append('\n-- Цели квестов')
for (c, *_rest) in QS:
    objs = _rest[9]
    for k, (kind, tgt, cnt, desc) in enumerate(objs, 1):
        ins('quest_objectives', ['quest_id', 'ord', 'kind', 'target_code', 'required_count', 'description'],
            [str(QID[c]), str(k), q(kind), q(tgt), str(cnt), q(desc)])
L.append('\n-- Цепочки квестов')
for a, b in [('first_hack', 'wake_up'), ('shadow_lesson', 'first_hack'), ('bridge_pass', 'shadow_lesson'), ('overheat', 'bridge_pass'),
             ('archive_secrets', 'overheat'), ('lost_memory', 'archive_secrets'), ('rebel_contact', 'lost_memory'),
             ('firewall_breach', 'rebel_contact'), ('node_a', 'firewall_breach'), ('node_b', 'firewall_breach'),
             ('core_reboot', 'node_a'), ('core_reboot', 'node_b'), ('echo_farewell', 'core_reboot')]:
    ins('quest_prerequisites', ['quest_id', 'requires_quest_id'], [str(QID[a]), str(QID[b])])
L.append('\n-- Награды предметами')
for (c, *_rest) in QS:
    for code, qty in _rest[10]:
        ins('quest_reward_items', ['quest_id', 'item_id', 'quantity'], [str(QID[c]), str(ITEM_ID[code]), str(qty)])

L.append('\n-- Достижения')
ACH = [('first_blood', 'Первый взлом', 'Взломать первый терминал', 10, False), ('ghost', 'Призрак', 'Пройти сектор без обнаружений', 30, False),
       ('collector', 'Коллекционер', 'Собрать все фрагменты памяти сектора', 20, False), ('time_lord', 'Повелитель времени', 'Провести 10 минут в замедлении', 20, False),
       ('no_damage', 'Без единой царапины', 'Пройти сектор без урона', 40, False), ('speedrun', 'Спидран', 'Пройти сектор 1 быстрее 90 секунд', 30, False),
       ('hoarder', 'Барахольщик', 'Заполнить весь инвентарь', 10, False), ('implanted', 'Киборг', 'Активировать 3 импланта', 15, False),
       ('legend', 'Легенда', 'Получить легендарный предмет', 25, False), ('rich', 'Богач', 'Накопить 10 000 кредитов', 20, False),
       ('reboot', 'Перезагрузка', 'Перезагрузить ядро ИИ', 50, False), ('alarm_master', 'Шумный гость', 'Поднять тревогу 50 раз', 10, True),
       ('pacifist', 'Пацифист', 'Пройти игру, не победив ни одного врага', 50, True), ('trader', 'Торговец', 'Совершить 100 сделок', 15, False),
       ('memory_whole', 'Целостность', 'Собрать все фрагменты памяти игры', 60, True)]
for c, n, d, p, h in ACH:
    ins('achievements', ['code', 'name', 'description', 'points', 'is_hidden'], [q(c), q(n), q(d), str(p), 'true' if h else 'false'])

L.append('\n-- Фрагменты памяти (совпадают с прототипом: 7 + 9 + 6)')
FR = {1: 7, 5: 9, 10: 6}
for loc, n in FR.items():
    for k in range(1, n + 1):
        ins('memory_fragments', ['location_id', 'ord', 'lore_text'], [str(loc), str(k), q(f'Воспоминание {k}: обрывок прошлого Призрака (локация {loc})')])

L.append('')
open(OUT, 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
print('statements:', sum(1 for x in L if x.startswith(('INSERT', 'UPDATE'))))
