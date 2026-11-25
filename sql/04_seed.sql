-- =====================================================================
-- Файл 4. Справочные данные (наполнение базы игровыми элементами)
-- Сгенерирован скриптом gen_seed.py
-- =====================================================================
SET search_path TO game, public;

-- Фракции
INSERT INTO factions (code, name, description) VALUES ('nexus', 'Корпорация «Нексус»', 'Владелец виртуальной реальности и ИИ-стража');
INSERT INTO factions (code, name, description) VALUES ('ghosts', 'Призраки сети', 'Подпольное сообщество хакеров');
INSERT INTO factions (code, name, description) VALUES ('sentinels', 'Стражи ИИ', 'Охранные программы ядра');
INSERT INTO factions (code, name, description) VALUES ('freelancers', 'Вольные хакеры', 'Наёмники, торгующие данными');

-- Локации (сектор, мин. уровень, безопасная зона, координаты)
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('neon_rooftops', 'Неоновые крыши', 1, 1, true, point(10,40), 'Сектор 1: неоновые крыши');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('market_alley', 'Рыночный переулок', 1, 2, true, point(18,44), 'Сектор 1: рыночный переулок');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('antenna_field', 'Поле антенн', 1, 3, false, point(25,38), 'Сектор 1: поле антенн');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('data_bridge', 'Мост данных', 1, 5, false, point(34,40), 'Сектор 1: мост данных');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('server_farms', 'Серверные фермы', 2, 8, false, point(45,30), 'Сектор 2: серверные фермы');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('cooling_tunnels', 'Туннели охлаждения', 2, 10, false, point(52,22), 'Сектор 2: туннели охлаждения');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('archive_vault', 'Хранилище архива', 2, 12, false, point(60,28), 'Сектор 2: хранилище архива');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('backup_hub', 'Резервный узел', 2, 14, true, point(58,35), 'Сектор 2: резервный узел');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('firewall_gate', 'Врата файрвола', 3, 16, false, point(70,30), 'Сектор 3: врата файрвола');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('ai_core', 'Ядро ИИ', 3, 20, false, point(80,32), 'Сектор 3: ядро ии');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('core_node_a', 'Узел защиты A', 3, 18, false, point(76,26), 'Сектор 3: узел защиты a');
INSERT INTO locations (code, name, sector, min_level, is_safe, pos, description) VALUES ('core_node_b', 'Узел защиты B', 3, 18, false, point(84,26), 'Сектор 3: узел защиты b');

-- Переходы между локациями
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (1, 2, 20);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (2, 1, 20);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (1, 3, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (3, 1, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (3, 4, 25);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (4, 3, 25);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (4, 5, 60);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (5, 4, 60);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (5, 6, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (6, 5, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (5, 8, 20);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (8, 5, 20);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (6, 7, 35);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (7, 6, 35);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (7, 8, 25);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (8, 7, 25);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (8, 9, 70);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (9, 8, 70);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (9, 11, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (9, 12, 30);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (11, 10, 20);
INSERT INTO location_links (from_location_id, to_location_id, travel_seconds) VALUES (12, 10, 20);

-- Классы персонажей
INSERT INTO character_classes (code, name, description, base_hp, base_energy) VALUES ('hacker', 'Хакер', 'Взлом и замедление времени', 5, 100);
INSERT INTO character_classes (code, name, description, base_hp, base_energy) VALUES ('infiltrator', 'Инфильтратор', 'Скрытность и скорость', 5, 90);
INSERT INTO character_classes (code, name, description, base_hp, base_energy) VALUES ('technician', 'Техник', 'Дроны и ловушки', 6, 80);
INSERT INTO character_classes (code, name, description, base_hp, base_energy) VALUES ('operator', 'Оператор', 'Выносливость и контроль', 7, 70);

-- Характеристики
INSERT INTO attributes (code, name) VALUES ('hack', 'Взлом');
INSERT INTO attributes (code, name) VALUES ('stealth', 'Скрытность');
INSERT INTO attributes (code, name) VALUES ('agility', 'Ловкость');
INSERT INTO attributes (code, name) VALUES ('tech', 'Техника');
INSERT INTO attributes (code, name) VALUES ('reflex', 'Реакция');
INSERT INTO attributes (code, name) VALUES ('will', 'Воля');

-- Стартовые характеристики классов
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 1, 8);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 2, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 3, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 4, 4);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 5, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (1, 6, 3);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 1, 4);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 2, 9);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 3, 7);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 4, 3);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 5, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (2, 6, 2);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 1, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 2, 3);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 3, 4);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 4, 9);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 5, 4);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (3, 6, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 1, 3);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 2, 4);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 3, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 4, 5);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 5, 6);
INSERT INTO class_base_attributes (class_id, attr_id, value) VALUES (4, 6, 7);

-- Таблица опыта (50 уровней)
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (1, 0, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (2, 100, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (3, 348, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (4, 722, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (5, 1213, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (6, 1812, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (7, 2516, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (8, 3320, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (9, 4222, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (10, 5220, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (11, 6310, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (12, 7490, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (13, 8760, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (14, 10118, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (15, 11562, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (16, 13091, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (17, 14703, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (18, 16399, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (19, 18176, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (20, 20033, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (21, 21971, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (22, 23988, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (23, 26083, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (24, 28256, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (25, 30506, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (26, 32832, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (27, 35233, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (28, 37710, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (29, 40261, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (30, 42886, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (31, 45585, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (32, 48356, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (33, 51200, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (34, 54116, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (35, 57103, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (36, 60162, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (37, 63291, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (38, 66491, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (39, 69761, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (40, 73100, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (41, 76508, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (42, 79985, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (43, 83531, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (44, 87145, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (45, 90827, 2);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (46, 94576, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (47, 98393, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (48, 102277, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (49, 106227, 1);
INSERT INTO level_thresholds (level, xp_required, skill_points) VALUES (50, 110243, 2);

-- Предметы
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('neuro_cable', 'Нейро-кабель', 'implant', 'rare', 1, 1, 400, true, 'implant1', '{"hack_time": 0.4}'::jsonb, 'Прямое подключение к терминалу');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('crypto_module', 'Крипто-модуль', 'implant', 'epic', 5, 1, 1200, true, 'implant1', '{"hack_len": -1}'::jsonb, 'Подбирает часть ключа заранее');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('visor', 'Визор', 'implant', 'rare', 3, 1, 600, true, 'implant1', '{"detect_delay": 0.4}'::jsonb, 'Глушит сканеры противника');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('companion_drone', 'Дрон', 'implant', 'epic', 8, 1, 1500, true, 'implant1', '{"energy_regen": 0.5}'::jsonb, 'Компаньон-аккумулятор');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('holo_deck', 'Голо-дек', 'implant', 'legendary', 15, 1, 5000, false, 'implant1', '{"max_hp": 2}'::jsonb, 'Резервная копия сознания');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('reflex_booster', 'Ускоритель рефлексов', 'implant', 'rare', 6, 1, 700, true, 'implant1', '{"slow_drain": -0.2}'::jsonb, 'Экономит энергию замедления');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('ghost_skin', 'Призрачная кожа', 'implant', 'epic', 10, 1, 1800, true, 'implant1', '{"stealth": 3}'::jsonb, 'Оптический камуфляж');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('jump_servo', 'Прыжковый сервопривод', 'implant', 'rare', 4, 1, 650, true, 'implant1', '{"jump": 0.1}'::jsonb, 'Повышает прыжок');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('overclock_chip', 'Чип разгона', 'implant', 'epic', 12, 1, 2100, true, 'implant1', '{"hack": 2, "max_hp": -1}'::jsonb, 'Мощнее взлом, хрупче тело');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('mirror_core', 'Зеркальное ядро', 'implant', 'legendary', 18, 1, 7000, false, 'implant1', '{"reflect": 0.25}'::jsonb, 'Отражает снаряды');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('pulse_pistol', 'Импульсный пистолет', 'weapon', 'common', 1, 1, 150, true, 'weapon', '{"damage": 6, "rate": 2.0}'::jsonb, 'Стандартное оружие');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('ion_blade', 'Ионный клинок', 'weapon', 'rare', 4, 1, 520, true, 'weapon', '{"damage": 12, "rate": 1.5}'::jsonb, 'Ближний бой');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('emp_launcher', 'ЭМИ-пускатель', 'weapon', 'epic', 9, 1, 1600, true, 'weapon', '{"damage": 18, "emp": true}'::jsonb, 'Отключает дронов');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('glitch_rifle', 'Глитч-винтовка', 'weapon', 'rare', 7, 1, 900, true, 'weapon', '{"damage": 15, "rate": 1.2}'::jsonb, 'Пробивает щиты');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('nano_whip', 'Нано-хлыст', 'weapon', 'epic', 11, 1, 1900, true, 'weapon', '{"damage": 20, "range": 3}'::jsonb, 'Дальний ближний бой');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('null_pointer', 'Нулевой указатель', 'weapon', 'legendary', 20, 1, 9000, false, 'weapon', '{"damage": 35, "crit": 0.2}'::jsonb, 'Легенда сети');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('stun_baton', 'Шоковая дубинка', 'weapon', 'common', 2, 1, 200, true, 'weapon', '{"damage": 8, "stun": 1.0}'::jsonb, 'Оглушение');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('arc_caster', 'Дуговой излучатель', 'weapon', 'rare', 6, 1, 800, true, 'weapon', '{"damage": 14, "chain": 2}'::jsonb, 'Цепная молния');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('static_hood', 'Статический капюшон', 'armor', 'common', 1, 1, 120, true, 'head', '{"armor": 2}'::jsonb, 'Базовая защита');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('neon_jacket', 'Неоновая куртка', 'armor', 'common', 1, 1, 180, true, 'body', '{"armor": 3}'::jsonb, 'Куртка хакера');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('grip_gloves', 'Цепкие перчатки', 'armor', 'common', 2, 1, 110, true, 'hands', '{"armor": 1, "hack": 1}'::jsonb, 'Удобны для взлома');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('shadow_mask', 'Теневая маска', 'armor', 'rare', 5, 1, 640, true, 'head', '{"armor": 3, "stealth": 2}'::jsonb, 'Скрывает лицо от камер');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('carbon_vest', 'Карбоновый жилет', 'armor', 'rare', 6, 1, 750, true, 'body', '{"armor": 6}'::jsonb, 'Лёгкая броня');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('signal_gloves', 'Сигнальные перчатки', 'armor', 'rare', 7, 1, 690, true, 'hands', '{"armor": 2, "hack": 2}'::jsonb, 'Усилитель сигнала');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('nexus_helm', 'Шлем «Нексуса»', 'armor', 'epic', 12, 1, 2200, true, 'head', '{"armor": 6, "reflex": 2}'::jsonb, 'Трофейный шлем охраны');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('phase_coat', 'Фазовый плащ', 'armor', 'epic', 13, 1, 2600, true, 'body', '{"armor": 8, "stealth": 3}'::jsonb, 'Сдвигает силуэт');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('core_gauntlets', 'Рукавицы ядра', 'armor', 'legendary', 19, 1, 6500, false, 'hands', '{"armor": 5, "hack": 5}'::jsonb, 'Созданы ИИ');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('sentinel_plate', 'Броня стража', 'armor', 'legendary', 20, 1, 8000, false, 'body', '{"armor": 14}'::jsonb, 'Броня ИИ-стража');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('stim_pack', 'Стимулятор', 'consumable', 'common', 1, 20, 40, true, NULL, '{"heal": 2}'::jsonb, 'Восстанавливает 2 здоровья');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('energy_cell', 'Энергоячейка', 'consumable', 'common', 1, 20, 50, true, NULL, '{"energy": 40}'::jsonb, 'Восстанавливает энергию');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('smoke_grenade', 'Дымовая граната', 'consumable', 'rare', 3, 10, 120, true, NULL, '{"stealth_zone": 4}'::jsonb, 'Создаёт тень');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('decoy_beacon', 'Маяк-приманка', 'consumable', 'rare', 5, 10, 150, true, NULL, '{"distract": 5}'::jsonb, 'Отвлекает дронов');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('overclock_shot', 'Инъекция разгона', 'consumable', 'epic', 9, 5, 400, true, NULL, '{"slow_free": 3}'::jsonb, 'Бесплатное замедление 3 с');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('repair_kit', 'Ремкомплект', 'consumable', 'common', 2, 10, 90, true, NULL, '{"durability": 30}'::jsonb, 'Чинит снаряжение');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('hack_script', 'Скрипт взлома', 'consumable', 'rare', 4, 10, 200, true, NULL, '{"auto_key": 1}'::jsonb, 'Вводит одну клавишу');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('firewall_patch', 'Заплатка файрвола', 'consumable', 'epic', 14, 5, 650, true, NULL, '{"alarm_clear": true}'::jsonb, 'Сбрасывает тревогу');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('ram_chip', 'Чип памяти', 'consumable', 'common', 1, 50, 25, true, NULL, '{"xp": 50}'::jsonb, 'Немного опыта');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('cooling_gel', 'Охлаждающий гель', 'consumable', 'common', 3, 20, 60, true, NULL, '{"energy_regen": 0.3}'::jsonb, 'Временный бонус');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('data_shard', 'Осколок данных', 'quest', 'common', 1, 99, 0, false, NULL, '{}'::jsonb, 'Фрагмент чужих данных');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('access_key_a', 'Ключ доступа A', 'quest', 'rare', 1, 1, 0, false, NULL, '{}'::jsonb, 'Открывает узел A');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('access_key_b', 'Ключ доступа B', 'quest', 'rare', 1, 1, 0, false, NULL, '{}'::jsonb, 'Открывает узел B');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('ghost_memory', 'Воспоминание Призрака', 'quest', 'epic', 1, 1, 0, false, NULL, '{}'::jsonb, 'Сюжетный предмет');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('nexus_badge', 'Пропуск «Нексуса»', 'quest', 'rare', 1, 1, 0, false, NULL, '{}'::jsonb, 'Служебный пропуск');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('core_fragment', 'Фрагмент ядра', 'quest', 'legendary', 1, 3, 0, false, NULL, '{}'::jsonb, 'Часть ядра ИИ');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('encrypted_log', 'Зашифрованный журнал', 'quest', 'common', 1, 10, 0, false, NULL, '{}'::jsonb, 'Требует расшифровки');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('broken_drone', 'Сломанный дрон', 'quest', 'common', 1, 5, 0, false, NULL, '{}'::jsonb, 'Для техника');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('copper_wire', 'Медный провод', 'material', 'common', 1, 99, 5, true, NULL, '{}'::jsonb, 'Материал для крафта');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('silicon_wafer', 'Кремниевая пластина', 'material', 'common', 1, 99, 12, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('neon_tube', 'Неоновая трубка', 'material', 'common', 1, 99, 8, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('quantum_bit', 'Квантовый бит', 'material', 'rare', 5, 99, 60, true, NULL, '{}'::jsonb, 'Редкий материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('ai_residue', 'Остаток ИИ', 'material', 'epic', 10, 99, 220, true, NULL, '{}'::jsonb, 'Остаётся после стражей');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('carbon_fiber', 'Углеволокно', 'material', 'common', 2, 99, 15, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('optic_lens', 'Оптическая линза', 'material', 'rare', 4, 99, 45, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('plasma_cell', 'Плазменная ячейка', 'material', 'rare', 6, 99, 70, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('nexus_alloy', 'Сплав «Нексуса»', 'material', 'epic', 12, 99, 300, true, NULL, '{}'::jsonb, 'Материал');
INSERT INTO item_templates (code, name, category, rarity, level_req, max_stack, base_price, is_tradeable, equip_slot, stats, description) VALUES ('legacy_code', 'Устаревший код', 'material', 'legendary', 18, 99, 900, true, NULL, '{}'::jsonb, 'Очень редкий материал');
UPDATE location_links SET requires_item_id = 40 WHERE from_location_id = 9 AND to_location_id = 11;
UPDATE location_links SET requires_item_id = 41 WHERE from_location_id = 9 AND to_location_id = 12;

-- Навыки
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('quick_hack', 'Быстрый взлом', 1, 5, 0, 0, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('time_dilation', 'Замедление времени', 1, 5, 35, 0, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('double_jump', 'Двойной прыжок', NULL, 1, 0, 0, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('chain_hack', 'Цепной взлом', 1, 3, 20, 8000, 8);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('system_override', 'Перехват системы', 1, 3, 50, 30000, 15);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('shadow_step', 'Шаг в тень', 2, 5, 15, 5000, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('silent_run', 'Бесшумный бег', 2, 5, 0, 0, 3);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('vanish', 'Исчезновение', 2, 3, 40, 20000, 10);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('drone_deploy', 'Запуск дрона', 3, 5, 25, 10000, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('emp_trap', 'ЭМИ-ловушка', 3, 3, 30, 12000, 6);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('overcharge', 'Перегрузка', 3, 3, 45, 25000, 12);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('fortify', 'Укрепление', 4, 5, 20, 15000, 1);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('taunt_protocol', 'Протокол приманки', 4, 3, 25, 18000, 6);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('adrenal_surge', 'Выброс адреналина', 4, 3, 40, 30000, 12);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('scanner', 'Сканер', NULL, 3, 10, 6000, 2);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('lockpick', 'Отмычка', NULL, 3, 0, 0, 2);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('first_aid', 'Первая помощь', NULL, 3, 20, 20000, 4);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('wall_cling', 'Цепкость', NULL, 1, 0, 0, 6);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('data_mining', 'Добыча данных', NULL, 5, 0, 0, 5);
INSERT INTO skills (code, name, class_id, max_rank, energy_cost, cooldown_ms, level_req) VALUES ('trade_sense', 'Чутьё торговца', NULL, 5, 0, 0, 3);

-- Дерево навыков
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (4, 1, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (5, 4, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (5, 2, 3);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (8, 6, 3);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (8, 7, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (10, 9, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (11, 10, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (14, 12, 3);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (13, 12, 1);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (18, 3, 1);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (19, 15, 2);
INSERT INTO skill_prerequisites (skill_id, requires_skill_id, min_rank) VALUES (17, 15, 1);

-- Неигровые персонажи
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('ghost_echo', 'Эхо', 1, 2, 'quest_giver', 1, '["Ты снова здесь, Призрак?", "Твои воспоминания разбросаны по секторам."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('vendor_lin', 'Торговка Лин', 2, 4, 'vendor', 5, '["Импланты, стимуляторы, всё по-честному."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('patrol_drone_1', 'Дрон-патрульный', 3, 3, 'enemy', 3, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('patrol_drone_2', 'Дрон-патрульный', 4, 3, 'enemy', 5, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('bridge_keeper', 'Смотритель моста', 4, 1, 'quest_giver', 6, '["Мост закрыт. Нужен пропуск «Нексуса»."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('rooftop_rat', 'Крышная Крыса', 1, 4, 'vendor', 2, '["Дымовые гранаты, дёшево!"]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('farm_admin', 'Администратор фермы', 5, 1, 'quest_giver', 9, '["Серверы перегреваются. Помоги — и я помогу."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('cooling_bot', 'Бот охлаждения', 6, 1, 'neutral', 8, '["ТЕМПЕРАТУРА: КРИТИЧЕСКАЯ."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('camera_unit', 'Камера наблюдения', 5, 3, 'enemy', 9, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('hunter_drone', 'Дрон-охотник', 6, 3, 'enemy', 11, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('archivist', 'Архивариус', 7, 2, 'quest_giver', 12, '["Архив помнит всё. Даже то, что ты забыл."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('vendor_kade', 'Барыга Кейд', 8, 4, 'vendor', 14, '["Редкие материалы. Плати кредитами."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('vault_guard', 'Страж архива', 7, 3, 'enemy', 13, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('hub_medic', 'Медик узла', 8, 2, 'quest_giver', 14, '["Подлатаю, если поможешь."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('firewall_warden', 'Надзиратель файрвола', 9, 3, 'enemy', 17, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('rebel_lead', 'Лидер сопротивления', 8, 2, 'quest_giver', 15, '["Ядро можно перезагрузить. Нужны три ключа."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('node_sentinel_a', 'Страж узла A', 11, 3, 'enemy', 19, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('node_sentinel_b', 'Страж узла B', 12, 3, 'enemy', 19, '[]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('ai_guardian', 'ИИ-страж', 10, 3, 'enemy', 25, '["ДОСТУП ЗАПРЕЩЁН.", "ТЫ — ОШИБКА."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('market_oracle', 'Оракул рынка', 2, 4, 'neutral', 4, '["Цены растут, когда растёт тревога."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('antenna_tech', 'Техник антенн', 3, 2, 'quest_giver', 3, '["Антенны сбоят. Нужны медные провода."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('vendor_nova', 'Нова', 5, 4, 'vendor', 9, '["Оружие для тех, кто не прячется."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('tunnel_ghost', 'Тоннельный призрак', 6, 2, 'neutral', 10, '["Здесь холодно... и тихо."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('nexus_clerk', 'Клерк «Нексуса»', 4, 1, 'vendor', 6, '["Служебные пропуска — только для своих."]'::jsonb);
INSERT INTO npcs (code, name, location_id, faction_id, role, level, dialog) VALUES ('core_echo', 'Отголосок ядра', 10, 3, 'neutral', 20, '["Я был создан защищать."]'::jsonb);

-- Ассортимент торговцев
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (2, 1, 450, 3);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (2, 3, 650, 2);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (2, 29, 45, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (2, 30, 55, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (2, 8, 700, 2);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (6, 31, 130, 20);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (6, 32, 160, 10);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (6, 29, 40, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (6, 47, 6, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (6, 19, 130, 3);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (12, 50, 70, 30);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (12, 54, 80, 30);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (12, 53, 50, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (12, 55, 340, 5);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (12, 51, 250, 5);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (22, 11, 160, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (22, 12, 560, 4);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (22, 14, 950, 2);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (22, 18, 850, 2);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (22, 17, 210, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (24, 20, 190, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (24, 21, 120, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (24, 23, 780, 3);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (24, 34, 95, NULL);
INSERT INTO vendor_stock (npc_id, item_id, price, stock) VALUES (24, 35, 210, 10);

-- Добыча с противников
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (3, 47, 0.6, 1, 3);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (3, 29, 0.15, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (4, 49, 0.5, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (4, 30, 0.2, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (9, 53, 0.4, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (9, 48, 0.5, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (10, 54, 0.35, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (10, 46, 0.25, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (13, 45, 0.5, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (13, 50, 0.3, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (15, 55, 0.25, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (15, 36, 0.1, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (17, 40, 1.0, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (17, 51, 0.4, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (18, 41, 1.0, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (18, 51, 0.4, 1, 2);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (19, 44, 1.0, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (19, 56, 0.2, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (19, 28, 0.05, 1, 1);
INSERT INTO enemy_loot (npc_id, item_id, chance, min_qty, max_qty) VALUES (10, 52, 0.5, 1, 3);

-- Квесты
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('wake_up', 'Пробуждение', 'Осмотреться на неоновых крышах и найти Эхо.', 1, 1, 1, true, false, 100, 50);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('first_hack', 'Первый взлом', 'Взломать терминал двери на крышах.', 1, 1, 1, true, false, 150, 80);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('shadow_lesson', 'Урок тени', 'Пройти мимо дрона, не подняв тревогу.', 1, 1, 2, true, false, 200, 100);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('antenna_fix', 'Сбойные антенны', 'Собрать медные провода для техника.', 21, 3, 3, false, false, 180, 150);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('bridge_pass', 'Пропуск на мост', 'Добыть пропуск «Нексуса».', 5, 4, 5, true, false, 300, 200);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('market_rumors', 'Слухи рынка', 'Узнать у оракула о Призраке.', 1, 2, 2, false, false, 120, 60);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('overheat', 'Перегрев', 'Охладить три стойки серверной фермы.', 7, 5, 8, true, false, 500, 300);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('tunnel_run', 'Бег по туннелям', 'Пройти туннели охлаждения за 2 минуты.', 7, 6, 10, false, true, 250, 120);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('broken_wings', 'Сломанные крылья', 'Собрать обломки дронов-охотников.', 14, 8, 10, false, true, 220, 150);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('archive_secrets', 'Тайны архива', 'Расшифровать журналы хранилища.', 11, 7, 12, true, false, 700, 400);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('lost_memory', 'Утерянная память', 'Найти воспоминание Призрака в архиве.', 11, 7, 12, true, false, 800, 0);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('medic_supply', 'Поставки медика', 'Принести стимуляторы в резервный узел.', 14, 8, 13, false, true, 200, 250);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('rebel_contact', 'Связь с сопротивлением', 'Встретиться с лидером сопротивления.', 16, 8, 14, true, false, 400, 200);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('firewall_breach', 'Пролом файрвола', 'Прорваться через врата файрвола.', 16, 9, 16, true, false, 1000, 500);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('node_a', 'Узел A', 'Взломать узел защиты A.', 16, 11, 18, true, false, 1200, 600);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('node_b', 'Узел B', 'Взломать узел защиты B.', 16, 12, 18, true, false, 1200, 600);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('core_reboot', 'Перезагрузка ядра', 'Взломать центральный узел и перезагрузить ИИ-стража.', 16, 10, 20, true, false, 3000, 2000);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('ghost_protocol', 'Протокол «Призрак»', 'Пройти сектор без единого обнаружения.', 1, 4, 6, false, true, 400, 300);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('data_hoarder', 'Собиратель данных', 'Собрать 20 осколков данных.', 12, 8, 10, false, true, 300, 400);
INSERT INTO quests (code, name, description, giver_npc_id, location_id, min_level, is_main, is_repeatable, xp_reward, credits_reward) VALUES ('echo_farewell', 'Прощание с Эхо', 'Вернуться к Эхо после перезагрузки ядра.', 1, 1, 20, true, false, 500, 0);

-- Цели квестов
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (1, 1, 'reach', 'neon_rooftops', 1, 'Добраться до Эхо');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (1, 2, 'talk', 'ghost_echo', 1, 'Поговорить с Эхо');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (2, 1, 'hack', 'terminal_a', 1, 'Взломать терминал A');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (3, 1, 'stealth', 'patrol_drone_1', 1, 'Пройти незамеченным');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (4, 1, 'collect', 'copper_wire', 10, 'Собрать 10 медных проводов');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (5, 1, 'collect', 'nexus_badge', 1, 'Добыть пропуск');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (5, 2, 'talk', 'bridge_keeper', 1, 'Показать пропуск смотрителю');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (6, 1, 'talk', 'market_oracle', 1, 'Поговорить с оракулом');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (7, 1, 'hack', 'cooling_terminal', 3, 'Взломать 3 терминала охлаждения');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (8, 1, 'reach', 'cooling_tunnels', 1, 'Пройти туннели');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (9, 1, 'collect', 'broken_drone', 3, 'Собрать 3 сломанных дрона');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (10, 1, 'collect', 'encrypted_log', 3, 'Найти 3 журнала');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (10, 2, 'hack', 'archive_console', 1, 'Расшифровать на консоли');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (11, 1, 'collect', 'ghost_memory', 1, 'Найти воспоминание');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (12, 1, 'collect', 'stim_pack', 5, 'Принести 5 стимуляторов');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (13, 1, 'talk', 'rebel_lead', 1, 'Поговорить с лидером');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (14, 1, 'defeat', 'firewall_warden', 1, 'Победить надзирателя');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (14, 2, 'reach', 'firewall_gate', 1, 'Пройти врата');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (15, 1, 'hack', 'core_node_a', 1, 'Взломать узел A');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (16, 1, 'hack', 'core_node_b', 1, 'Взломать узел B');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (17, 1, 'hack', 'core_node_c', 1, 'Взломать узел C');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (17, 2, 'reach', 'ai_core', 1, 'Войти в ядро');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (18, 1, 'stealth', 'sector_any', 1, 'Пройти сектор незамеченным');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (19, 1, 'collect', 'data_shard', 20, 'Собрать 20 осколков');
INSERT INTO quest_objectives (quest_id, ord, kind, target_code, required_count, description) VALUES (20, 1, 'talk', 'ghost_echo', 1, 'Поговорить с Эхо');

-- Цепочки квестов
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (2, 1);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (3, 2);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (5, 3);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (7, 5);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (10, 7);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (11, 10);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (13, 11);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (14, 13);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (15, 14);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (16, 14);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (17, 15);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (17, 16);
INSERT INTO quest_prerequisites (quest_id, requires_quest_id) VALUES (20, 17);

-- Награды предметами
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (2, 1, 1);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (4, 34, 2);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (7, 2, 1);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (8, 38, 3);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (9, 29, 5);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (10, 3, 1);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (14, 4, 1);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (17, 5, 1);
INSERT INTO quest_reward_items (quest_id, item_id, quantity) VALUES (18, 31, 3);

-- Достижения
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('first_blood', 'Первый взлом', 'Взломать первый терминал', 10, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('ghost', 'Призрак', 'Пройти сектор без обнаружений', 30, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('collector', 'Коллекционер', 'Собрать все фрагменты памяти сектора', 20, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('time_lord', 'Повелитель времени', 'Провести 10 минут в замедлении', 20, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('no_damage', 'Без единой царапины', 'Пройти сектор без урона', 40, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('speedrun', 'Спидран', 'Пройти сектор 1 быстрее 90 секунд', 30, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('hoarder', 'Барахольщик', 'Заполнить весь инвентарь', 10, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('implanted', 'Киборг', 'Активировать 3 импланта', 15, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('legend', 'Легенда', 'Получить легендарный предмет', 25, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('rich', 'Богач', 'Накопить 10 000 кредитов', 20, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('reboot', 'Перезагрузка', 'Перезагрузить ядро ИИ', 50, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('alarm_master', 'Шумный гость', 'Поднять тревогу 50 раз', 10, true);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('pacifist', 'Пацифист', 'Пройти игру, не победив ни одного врага', 50, true);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('trader', 'Торговец', 'Совершить 100 сделок', 15, false);
INSERT INTO achievements (code, name, description, points, is_hidden) VALUES ('memory_whole', 'Целостность', 'Собрать все фрагменты памяти игры', 60, true);

-- Фрагменты памяти (совпадают с прототипом: 7 + 9 + 6)
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 1, 'Воспоминание 1: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 2, 'Воспоминание 2: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 3, 'Воспоминание 3: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 4, 'Воспоминание 4: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 5, 'Воспоминание 5: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 6, 'Воспоминание 6: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (1, 7, 'Воспоминание 7: обрывок прошлого Призрака (локация 1)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 1, 'Воспоминание 1: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 2, 'Воспоминание 2: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 3, 'Воспоминание 3: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 4, 'Воспоминание 4: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 5, 'Воспоминание 5: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 6, 'Воспоминание 6: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 7, 'Воспоминание 7: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 8, 'Воспоминание 8: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (5, 9, 'Воспоминание 9: обрывок прошлого Призрака (локация 5)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 1, 'Воспоминание 1: обрывок прошлого Призрака (локация 10)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 2, 'Воспоминание 2: обрывок прошлого Призрака (локация 10)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 3, 'Воспоминание 3: обрывок прошлого Призрака (локация 10)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 4, 'Воспоминание 4: обрывок прошлого Призрака (локация 10)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 5, 'Воспоминание 5: обрывок прошлого Призрака (локация 10)');
INSERT INTO memory_fragments (location_id, ord, lore_text) VALUES (10, 6, 'Воспоминание 6: обрывок прошлого Призрака (локация 10)');

