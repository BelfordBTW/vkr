# -*- coding: utf-8 -*-
"""Сборка текста ВКР в .docx по требованиям листа соответствия:
TNR 14, по ширине, абзацный отступ 1,5 см, интервал 1,5; поля 30/10/20/20 мм;
главы с новой страницы, 16 жирный по центру; разделы 14 жирный по центру;
таблицы: «Таблица N» справа, название по центру сверху, шапка 12 жирный, текст 12;
рисунки: подпись снизу по центру, 14 жирный. Нумерация страниц с «Содержания»."""
import json, os, re, sys, copy
import docx
from docx.shared import Pt, Cm, Mm, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn

HERE = os.path.dirname(os.path.abspath(__file__))
VKR = os.path.dirname(HERE)
ROOT = os.path.dirname(VKR)
sys.path.insert(0, HERE)
from t1_intro_ch1 import TEXT as T1
from t2_ch2 import TEXT as T2
from t3_ch3 import TEXT as T3, REFS
from t_extra import EXTRA, TABLES_EXTRA

R = json.load(open(os.path.join(VKR, 'bench', 'results.json'), encoding='utf-8'))
RX = json.load(open(os.path.join(VKR, 'bench', 'results_extra.json'), encoding='utf-8'))
SQL = {n: open(os.path.join(VKR, 'sql', n), encoding='utf-8').read() for n in os.listdir(os.path.join(VKR, 'sql')) if n.endswith('.sql')}

TOPIC = 'Проектирование и реализация базы данных для централизованного хранения игровых элементов (на примере RPG игры)'
FIO = 'Зубович Александр Игоревич'
SUPERVISOR = 'Терехова Л. А.'
START_PAGE = 6          # титул (1) + задание (4 стр.) → «Содержание» на стр. 6
INDENT = Cm(1.5)

# ------------------------------------------------------------------ данные таблиц
def ms(v): return f'{v:.3f}'.replace('.', ',') if v < 10 else f'{v:.1f}'.replace('.', ',')
WI, WO = R['with_indexes'], R['without_indexes']
QK = [f'Q{i}' for i in range(1, 16)]

TABLES = {
 'models': ('Сравнение моделей данных для хранения игровых элементов',
   ['Критерий', 'Реляционная', 'Документная', 'Графовая', 'Ключ — значение'],
   [['Структура данных', 'Таблицы с фиксированной схемой', 'Документы JSON с гибкой схемой', 'Узлы и рёбра со свойствами', 'Пары ключ — значение'],
    ['Целостность связей', 'Внешние ключи, CHECK, UNIQUE', 'Обеспечивает приложение', 'Связи — часть модели, ограничения слабее', 'Нет'],
    ['Транзакции ACID', 'Полная поддержка', 'Многодокументные — с ограничениями', 'Поддерживаются', 'Ограниченно (атомарные команды)'],
    ['Сложные запросы и аналитика', 'SQL: соединения, агрегаты, окна', 'Конвейер агрегации, соединения ограничены', 'Обход графа, пути', 'Только по ключу'],
    ['Гибкость схемы', 'Средняя (с JSONB — высокая)', 'Высокая', 'Высокая', 'Высокая'],
    ['Горизонтальное масштабирование', 'Сложнее (реплики, секционирование)', 'Встроенное шардирование', 'Сложное', 'Простое'],
    ['Применимость в RPG', 'Основное хранилище', 'Прототипы, профили', 'Социальные связи, цепочки', 'Кэш, рейтинги, сессии']]),
 'dbms': ('Сравнение СУБД для игровой базы данных',
   ['Критерий', 'PostgreSQL', 'MySQL', 'MS SQL / Oracle', 'MongoDB', 'Redis'],
   [['Модель', 'Объектно-реляционная', 'Реляционная', 'Реляционная', 'Документная', 'Ключ — значение'],
    ['Лицензия', 'PostgreSQL (свободная)', 'GPL / коммерческая', 'Коммерческая', 'SSPL', 'Свободная / коммерческая'],
    ['Транзакции ACID', 'Да, MVCC', 'Да (InnoDB)', 'Да', 'Ограниченно', 'Нет'],
    ['JSON и индексы по нему', 'JSONB, GIN', 'JSON, через генерируемые столбцы', 'Есть', 'Нативно', 'Модуль'],
    ['Пространственные данные', 'point, GiST, PostGIS', 'Spatial', 'Есть', 'GeoJSON', 'GEO-команды'],
    ['Процедурный язык, триггеры', 'PL/pgSQL и др.', 'Хранимые процедуры', 'T-SQL / PL/SQL', 'Нет (JS-агрегации)', 'Lua-скрипты'],
    ['Частичные индексы и по выражению', 'Да', 'Только по выражению', 'Да', 'Да', '—'],
    ['Роль в игровом проекте', 'Основное хранилище', 'Основное хранилище', 'Основное хранилище', 'Профили, прототипы', 'Кэш, рейтинги']]),
 'entities': ('Основные сущности предметной области и их атрибуты',
   ['Сущность (таблица)', 'Назначение', 'Основные атрибуты'],
   [['Игрок (players)', 'Учётная запись', 'логин, e-mail, хеш пароля, регион, блокировка, даты регистрации и входа'],
    ['Сессия (sessions)', 'Игровой сеанс', 'игрок, начало, окончание, IP-адрес, версия клиента'],
    ['Класс (character_classes)', 'Класс персонажа', 'код, название, базовое здоровье и энергия'],
    ['Характеристика (attributes)', 'Справочник характеристик', 'код, название, максимум'],
    ['Таблица опыта (level_thresholds)', 'Опыт для уровня', 'уровень, требуемый опыт, очки навыков'],
    ['Персонаж (characters)', 'Игровой персонаж', 'игрок, класс, имя, уровень, опыт, здоровье, энергия, кредиты, локация, размер инвентаря'],
    ['Шаблон предмета (item_templates)', 'Справочник предметов', 'код, название, категория, редкость, уровень, размер стека, цена, слот, характеристики (JSONB)'],
    ['Экземпляр предмета (item_instances)', 'Уникальный предмет', 'шаблон, владелец, прочность, уровень улучшения, привязка, бонусы'],
    ['Инвентарь (inventory)', 'Содержимое ячеек', 'персонаж, ячейка, предмет, экземпляр, количество'],
    ['Экипировка (equipment)', 'Надетые предметы', 'персонаж, слот, экземпляр'],
    ['Навык (skills)', 'Справочник умений', 'код, название, класс, макс. ранг, затраты энергии, перезарядка'],
    ['Локация (locations)', 'Место игрового мира', 'код, название, сектор, мин. уровень, безопасная зона, координаты'],
    ['Фракция (factions)', 'Группировка мира', 'код, название, описание'],
    ['NPC (npcs)', 'Неигровой персонаж', 'код, имя, локация, фракция, роль, уровень, реплики'],
    ['Квест (quests)', 'Задание', 'код, название, описание, квестодатель, локация, мин. уровень, тип, награды'],
    ['Цель квеста (quest_objectives)', 'Шаг задания', 'квест, порядок, вид, цель, количество'],
    ['Журнал квестов (character_quests)', 'Квесты персонажа', 'персонаж, квест, статус, даты'],
    ['Достижение (achievements)', 'Награда за успехи', 'код, название, описание, очки, скрытность'],
    ['Фрагмент памяти (memory_fragments)', 'Коллекционный объект', 'локация, номер, текст'],
    ['Транзакция (transactions)', 'Экономическая операция', 'персонаж, вид, сумма, предмет, количество, время'],
    ['Аудит (audit_log)', 'История изменений', 'таблица, операция, ключ, старые и новые данные, время']]),
 't_characters': ('Структура таблицы characters (персонажи)',
   ['Поле', 'Тип', 'Ограничения', 'Описание'],
   [['character_id', 'bigint', 'PK, IDENTITY', 'Идентификатор персонажа'], ['player_id', 'bigint', 'FK → players, NOT NULL, ON DELETE CASCADE', 'Владелец'],
    ['class_id', 'smallint', 'FK → character_classes, NOT NULL', 'Класс'], ['name', 'd_name', 'NOT NULL; уникально без учёта регистра среди неудалённых', 'Имя'],
    ['level', 'd_level', '1…100, по умолчанию 1, вычисляется триггером', 'Уровень'], ['experience', 'bigint', '≥ 0', 'Накопленный опыт'],
    ['hp, max_hp', 'smallint', 'hp ≥ 0, max_hp > 0, hp ≤ max_hp', 'Здоровье'], ['energy', 'smallint', '0…100', 'Энергия замедления времени'],
    ['credits', 'd_money', '≥ 0', 'Игровая валюта'], ['skill_points', 'smallint', '≥ 0', 'Свободные очки навыков'],
    ['location_id', 'integer', 'FK → locations, NOT NULL', 'Текущая локация'], ['inventory_size', 'smallint', '10…100, по умолчанию 25', 'Число ячеек инвентаря'],
    ['is_deleted', 'boolean', 'по умолчанию false', 'Признак удаления'], ['created_at, updated_at', 'timestamptz', 'NOT NULL', 'Даты создания и изменения']]),
 't_items': ('Структура таблицы item_templates (шаблоны предметов)',
   ['Поле', 'Тип', 'Ограничения', 'Описание'],
   [['item_id', 'integer', 'PK, IDENTITY', 'Идентификатор'], ['code', 'd_code', 'UNIQUE, NOT NULL', 'Код для игрового сервера'],
    ['name', 'd_name', 'NOT NULL', 'Название'], ['category', 'item_category_t', 'NOT NULL', 'Категория'], ['rarity', 'rarity_t', 'по умолчанию common', 'Редкость'],
    ['level_req', 'd_level', '1…100', 'Требуемый уровень'], ['max_stack', 'smallint', '1…999; > 1 только для расходников, материалов и квестовых', 'Размер стека'],
    ['base_price', 'd_money', '≥ 0', 'Базовая цена'], ['is_tradeable', 'boolean', 'NOT NULL', 'Можно ли передавать'],
    ['equip_slot', 'equip_slot_t', 'задан тогда и только тогда, когда категория — экипировка', 'Слот экипировки'],
    ['stats', 'jsonb', 'JSON-объект', 'Характеристики предмета'], ['description', 'text', '—', 'Описание']]),
 't_inventory': ('Структура таблицы inventory (инвентарь)',
   ['Поле', 'Тип', 'Ограничения', 'Описание'],
   [['character_id', 'bigint', 'PK (1), FK → characters, ON DELETE CASCADE', 'Персонаж'], ['slot_no', 'smallint', 'PK (2), 0…99; < размера инвентаря (триггер)', 'Номер ячейки'],
    ['item_id', 'integer', 'FK → item_templates, NOT NULL', 'Предмет'], ['instance_id', 'bigint', 'UNIQUE, FK → item_instances', 'Экземпляр (для экипировки)'],
    ['quantity', 'smallint', '1…999; ≤ max_stack (триггер); = 1 для экземпляра', 'Количество'], ['acquired_at', 'timestamptz', 'NOT NULL', 'Время получения']]),
 't_quests': ('Структура таблиц quests и character_quests (квесты и журнал)',
   ['Поле', 'Тип', 'Ограничения', 'Описание'],
   [['quests.quest_id', 'integer', 'PK, IDENTITY', 'Идентификатор квеста'], ['quests.code', 'd_code', 'UNIQUE', 'Код'],
    ['quests.giver_npc_id', 'integer', 'FK → npcs', 'Квестодатель'], ['quests.location_id', 'integer', 'FK → locations, NOT NULL', 'Локация'],
    ['quests.min_level', 'd_level', '1…100', 'Минимальный уровень'], ['quests.is_main, is_repeatable', 'boolean', 'NOT NULL', 'Сюжетный, повторяемый'],
    ['quests.xp_reward, credits_reward', 'integer, d_money', '≥ 0', 'Награды'],
    ['character_quests.(character_id, quest_id)', 'bigint, integer', 'PK; FK → characters, quests', 'Персонаж и квест'],
    ['character_quests.status', 'quest_status_t', 'по умолчанию active', 'Статус'],
    ['character_quests.finished_at', 'timestamptz', 'NULL тогда и только тогда, когда статус active', 'Время завершения']]),
 'types': ('Соответствие логических типов данных типам PostgreSQL',
   ['Логический тип', 'Тип PostgreSQL', 'Где применяется', 'Обоснование'],
   [['Суррогатный ключ', 'bigint / integer / smallint GENERATED ALWAYS AS IDENTITY', 'Все сущности', 'Стандарт SQL, размер по ожидаемому объёму'],
    ['Код, имя', 'домены d_code, d_name на varchar', 'Справочники', 'Единые правила формата'],
    ['Перечисление', 'ENUM', 'Редкость, категория, статус, слот', '4 байта, порядок значений'],
    ['Небольшое число', 'smallint', 'Уровень, здоровье, характеристики', 'Экономия места'],
    ['Опыт, валюта', 'bigint, домен d_money', 'Персонажи, журналы', 'Без переполнения и округления'],
    ['Вероятность', 'numeric(5,4)', 'Добыча', 'Точное десятичное значение'],
    ['Гибкие свойства', 'jsonb', 'Характеристики, настройки, реплики', 'Разнородная структура, индекс GIN'],
    ['Координаты', 'point', 'Локации, сохранения', 'Оператор расстояния, индекс GiST'],
    ['Дата и время', 'timestamptz', 'Все журналы', 'Учёт часовых поясов игроков'],
    ['IP-адрес', 'inet', 'Сессии', 'Проверка формата, операции с подсетями'],
    ['Идентификатор сессии', 'uuid (gen_random_uuid)', 'Сессии', 'Непредсказуемый ключ']]),
 'checks': ('Примеры проверочных ограничений',
   ['Ограничение', 'Таблица', 'Условие', 'Бизнес-правило'],
   [['characters_hp_chk', 'characters', 'hp <= max_hp', 'Здоровье не больше максимума'],
    ['домен d_money', 'characters, vendor_stock, quests', 'VALUE >= 0', 'Валюта и цены не отрицательны'],
    ['item_templates_stack_chk', 'item_templates', "category IN (…) OR max_stack = 1", 'Экипировка не складывается'],
    ['item_templates_slot_chk', 'item_templates', 'экипировка ⇔ слот задан', 'Слот только у экипировки'],
    ['inventory_instance_qty_chk', 'inventory', 'instance_id IS NULL OR quantity = 1', 'Экземпляр — всегда один'],
    ['character_quests_finish_chk', 'character_quests', "(status = 'active') = (finished_at IS NULL)", 'Дата завершения у завершённых'],
    ['location_links_self_chk', 'location_links', 'from_location_id <> to_location_id', 'Нет перехода в себя'],
    ['enemy_loot_qty_chk', 'enemy_loot', 'max_qty >= min_qty', 'Корректный диапазон добычи'],
    ['players_last_login_chk', 'players', 'last_login_at >= created_at', 'Вход не раньше регистрации'],
    ['players_email_chk', 'players', "email ~ '^[^@]+@[^@]+\\.[^@]+$'", 'Корректный e-mail']]),
 'indexes': ('Дополнительные индексы и обслуживаемые ими запросы',
   ['Вид индекса', 'Индексы (таблица, столбцы)', 'Назначение'],
   [['B-дерево по внешним ключам', 'characters(player_id), item_instances(owner_id), inventory(item_id), npcs(location_id), quests(giver_npc_id), sessions(player_id, started_at DESC) и др.', 'Соединения, выборки по владельцу, каскадное удаление'],
    ['Составные B-деревья', 'item_templates(category, rarity, level_req), transactions(character_id, created_at DESC), characters(class_id, experience DESC)', 'Поиск предметов по критериям, история операций, рейтинги без сортировки'],
    ['Частичные', 'character_quests(character_id) WHERE status = active; characters(...) WHERE NOT is_deleted', 'Только «живые» строки — меньше размер'],
    ['По выражению', 'players(lower(login)), item_templates(((stats->>damage)::int))', 'Поиск без учёта регистра, по числовой характеристике'],
    ['GIN, GiST, BRIN', 'item_templates USING gin(stats), locations USING gist(pos), transactions USING brin(created_at)', 'JSONB-поиск, ближайшие локации, компактный индекс журнала']]),
 'scripts': ('Состав SQL-скриптов базы данных',
   ['Скрипт', 'Содержание', 'Операторов'],
   [['01_schema.sql', 'Схема game, 7 перечислений, 5 доменов, 37 таблиц, ограничения, комментарии', '100'],
    ['02_functions.sql', 'Триггерные функции и триггеры, функции и процедуры игровых операций, представления', '29'],
    ['03_indexes.sql', 'Дополнительные индексы', '23'],
    ['04_seed.sql', 'Справочные данные игры', '387'],
    ['05_loadtest.sql', 'Генерация тестового набора данных', '20'],
    ['06_queries.sql', 'Запросы игровых операций и транзакции', '26'],
    ['Итого', '', '585']]),
 'seed': ('Справочные данные игры «Эхо кода»',
   ['Справочник', 'Записей', 'Примеры'],
   [['Фракции', '4', 'Корпорация «Нексус», Призраки сети, Стражи ИИ'], ['Локации / переходы', '12 / 22', 'Неоновые крыши, Серверные фермы, Ядро ИИ'],
    ['Классы / характеристики', '4 / 6', 'Хакер, Инфильтратор; Взлом, Скрытность'], ['Уровни', '50', 'Опыт = 100 · (L − 1)^1,8'],
    ['Предметы', '56', 'Нейро-кабель, Крипто-модуль, Визор, Дрон, Голо-дек, Ионный клинок'],
    ['Навыки / условия', '20 / 12', 'Быстрый взлом → Цепной взлом → Перехват системы'],
    ['NPC / товары / добыча', '25 / 25 / 20', 'Торговка Лин, Дрон-патрульный, ИИ-страж'],
    ['Квесты / цели / цепочки / награды', '20 / 25 / 13 / 10', '«Первый взлом», «Перезагрузка ядра»'],
    ['Достижения', '15', '«Призрак», «Повелитель времени»'], ['Фрагменты памяти', '22', '7 + 9 + 6 по секторам прототипа']]),
 'volumes': ('Объём тестового набора данных',
   ['Таблица', 'Записей', 'Таблица', 'Записей'],
   [['players', '10 000', 'transactions', '200 000'], ['characters', '10 000', 'item_instances', '100 000'],
    ['character_attributes', '60 000', 'inventory', '49 990'], ['character_quests', '49 989', 'character_skills', '47 033'],
    ['sessions', '30 000', 'quest_progress', '9 331']]),
 'queries': ('Запросы основных игровых операций',
   ['№', 'Операция', 'Приёмы SQL'],
   [['Q1', 'Авторизация игрока', 'Индекс по выражению lower(login)'], ['Q2', 'Список персонажей игрока', 'JOIN со справочниками'],
    ['Q3', 'Инвентарь персонажа', 'Представление, LEFT JOIN, конкатенация JSONB'], ['Q4', 'Владельцы предмета', 'Агрегаты COUNT DISTINCT, SUM'],
    ['Q5', 'Поиск предметов по критериям', 'Составное условие, IN, сортировка'], ['Q6', 'Поиск по свойствам', 'Оператор JSONB @>'],
    ['Q7', 'Экипировка персонажа', 'JOIN, сортировка по ENUM'], ['Q8', 'Доступные квесты', 'Вложенные NOT EXISTS'],
    ['Q9', 'Активные квесты с прогрессом', 'LEFT JOIN, вычисляемый процент'], ['Q10', 'Таблица лидеров класса', 'Оконная функция rank()'],
    ['Q11', 'История операций персонажа', 'Диапазон дат, LIMIT'], ['Q12', 'Оборот экономики за неделю', 'date_trunc, GROUP BY'],
    ['Q13', 'Ближайшие локации', 'Оператор расстояния <->'], ['Q14', 'Последние сессии игрока', 'Интервалы времени'],
    ['Q15', 'Статистика экипировки', 'avg, percentile_cont']]),
 'variants': ('Сравнение формулировок запроса «квесты, которые персонаж ещё не брал»',
   ['Формулировка', 'Время (медиана), мс', 'План выполнения'],
   [[k, ms(R['variants_not_taken'][k]['median_ms']), R['variants_not_taken'][k]['nodes']] for k in R['variants_not_taken']]),
 'bench': ('Время выполнения запросов без дополнительных индексов и с ними',
   ['№', 'Операция', 'Без индексов, мс', 'С индексами, мс', 'Ускорение, раз', 'Доступ к данным (с индексами)'],
   [[k, WI[k]['title'], ms(WO[k]['median_ms']), ms(WI[k]['median_ms']),
     (f"{WO[k]['median_ms'] / WI[k]['median_ms']:.0f}" if WO[k]['median_ms'] / WI[k]['median_ms'] >= 1.5 else '≈ 1'), WI[k]['nodes']] for k in QK]),
 'tps_read': ('Нагрузочное тестирование: сценарий чтения (pgbench, 10 с)',
   ['Клиентов', 'TPS с индексами', 'Задержка, мс', 'TPS без индексов', 'Задержка, мс'],
   [[str(x['clients']), f"{x['tps']:.0f}", ms(x['latency_ms']),
     next((f"{y['tps']:.0f}" for y in R['pgbench_read_noidx'] if y['clients'] == x['clients']), '—'),
     next((ms(y['latency_ms']) for y in R['pgbench_read_noidx'] if y['clients'] == x['clients']), '—')] for x in R['pgbench_read']]),
 'tps_write': ('Нагрузочное тестирование: транзакции передачи предметов',
   ['Клиентов', 'TPS (synchronous_commit = on)', 'Задержка, мс', 'TPS (synchronous_commit = off)', 'Задержка, мс', 'Ошибок'],
   [[str(a['clients']), f"{a['tps']:.0f}", ms(a['latency_ms']), f"{b['tps']:.0f}", ms(b['latency_ms']), str(a['failed'] + b['failed'])]
    for a, b in zip(R['pgbench_write'], RX['write_async'])]),
 'optim': ('Эксперименты по оптимизации отчёта об экономике (Q12)',
   ['Вариант', 'Время, мс', 'Комментарий'],
   [['Исходный (BRIN на неупорядоченной таблице)', ms(RX['q12_base']['Q12']['median_ms']), 'Seq Scan: BRIN не используется'],
    ['BRIN на таблице, упорядоченной по времени', ms(RX['q12_brin_sorted']['Q12']['median_ms']), 'Bitmap Index Scan'],
    ['B-дерево по created_at', ms(RX['q12_btree']['Q12']['median_ms']), 'Оптимизатор выбрал Seq Scan (≈ 8 % строк)'],
    ['Материализованное представление дневных итогов', ms(RX['q12_mv']['Q12']['median_ms']), f"Обновление ≈ {RX['mv_refresh_wall_ms']/1000:.2f} с".replace('.', ',')]]),
 'sizes': ('Размеры наиболее крупных таблиц базы данных',
   ['Таблица', 'Записей', 'Данные, МБ', 'Индексы, МБ'],
   [[s['table'], f"{s['rows']:,}".replace(',', ' '), f"{s['data_bytes']/1048576:.1f}".replace('.', ','), f"{s['index_bytes']/1048576:.1f}".replace('.', ',')] for s in R['sizes_with'][:8]]),
}

TABLES.update(TABLES_EXTRA)
PLANS = {}
for blk in open(os.path.join(VKR, 'bench', 'plans.txt'), encoding='utf-8').read().split('===')[1:]:
    name, body_ = blk.split(chr(10), 1)
    PLANS[name.strip()] = chr(10).join(l for l in body_.rstrip().split(chr(10)) if not re.match(r'^\s*(QUERY PLAN|-+|\(\d+ rows\))\s*$', l)).rstrip()

def extract(sqlfile, start, end_pat=r';\s*$'):
    s = SQL[sqlfile]; i = s.index(start)
    m = re.compile(end_pat, re.M).search(s, i)
    return s[i:m.end()].rstrip()

CODE = {
 'domains': ('Объявление доменов', '\n'.join(l for l in SQL['01_schema.sql'].splitlines() if l.startswith('CREATE DOMAIN'))),
 'characters': ('Создание таблицы персонажей', extract('01_schema.sql', 'CREATE TABLE characters') + '\n' + extract('01_schema.sql', 'CREATE UNIQUE INDEX characters_name_uq')),
 'inventory': ('Создание таблицы инвентаря', extract('01_schema.sql', 'CREATE TABLE inventory')),
 'add_item': ('Функция добавления предмета в инвентарь (фрагмент)', extract('02_functions.sql', '    -- 1. досыпаем', r'^    RETURN p_qty;')),
 'q8': ('Запрос доступных квестов', extract('06_queries.sql', 'SELECT q.quest_id, q.name, q.min_level')),
 'transfer': ('Процедура передачи предмета (фрагмент)', extract('02_functions.sql', 'CREATE OR REPLACE PROCEDURE transfer_item', r'^    SELECT code, is_tradeable') + '\n    ...\n' + extract('02_functions.sql', '    INSERT INTO item_transfers', r'^END \$\$;')),
 'tx': ('Явное управление транзакцией при передаче предмета', extract('06_queries.sql', '-- T2.', r'^COMMIT;')),
 'plan_q11_no': ('План запроса Q11 без индекса (EXPLAIN ANALYZE, BUFFERS)', PLANS['Q11_WITHOUT']),
 'plan_q11': ('План запроса Q11 с составным индексом', PLANS['Q11_WITH']),
 'plan_q10': ('План запроса Q10 с частичным индексом', PLANS['Q10_WITH']),
}
FIGS = {
 'er1': (os.path.join(VKR, 'figures', 'er_1_accounts.png'), 'ER-диаграмма: учётные записи, персонажи, мир'),
 'er2': (os.path.join(VKR, 'figures', 'er_2_items.png'), 'ER-диаграмма: предметы, инвентарь, экономика'),
 'er3': (os.path.join(VKR, 'figures', 'er_3_quests.png'), 'ER-диаграмма: квесты, NPC, навыки, достижения'),
 'chart_idx': (os.path.join(VKR, 'figures', 'chart_indexes.png'), 'Время выполнения запросов без индексов и с индексами'),
 'chart_read': (os.path.join(VKR, 'figures', 'chart_tps_read.png'), 'Пропускная способность сценария чтения'),
 'chart_write': (os.path.join(VKR, 'figures', 'chart_tps_write.png'), 'Пропускная способность транзакций записи'),
}

# ------------------------------------------------------------------ документ
TEMPLATE = os.path.join(ROOT, 'source_zip', '6_obrazec_titulnogo_lista (2).docx')
doc = docx.Document(TEMPLATE)

def txt(el): return ''.join(t.text or '' for t in el.iter(qn('w:t')))
def set_cell_text(tc, text, size=None, bold=None):
    ps = list(tc.iter(qn('w:p'))); p = ps[0]
    runs = list(p.iter(qn('w:r')))
    if runs:
        ts = runs[0].findall(qn('w:t'))
        if not ts: t = OxmlElement('w:t'); runs[0].append(t); ts = [t]
        ts[0].text = text; ts[0].set('{http://www.w3.org/XML/1998/namespace}space', 'preserve')
        for r in runs[1:]:
            for t in r.findall(qn('w:t')): t.text = ''
    else:
        r = OxmlElement('w:r'); rpr = OxmlElement('w:rPr'); f = OxmlElement('w:rFonts')
        for a in ('w:ascii', 'w:hAnsi', 'w:cs'): f.set(qn(a), 'Times New Roman')
        rpr.append(f); sz = OxmlElement('w:sz'); sz.set(qn('w:val'), str(size or 28)); rpr.append(sz)
        if bold: rpr.append(OxmlElement('w:b'))
        r.append(rpr); t = OxmlElement('w:t'); t.text = text; r.append(t); p.append(r)

# --- титульный лист
body = list(doc.element.body)
for r in body[2].iter(qn('w:r')):
    if 'Геймдизайна' in txt(r):
        r.find(qn('w:t')).text = 'Игровой индустрии и киберспорта'
t3 = body[3]
for tc in t3.iter(qn('w:tc')):
    if txt(tc) == 'ИиЦТ': set_cell_text(tc, 'ИИиК')
    if txt(tc) == 'Геймдизайн и разработки игр': set_cell_text(tc, 'Геймдизайн и разработка игр')
topic_tbl = body[6]
cells = list(topic_tbl.iter(qn('w:tc')))
set_cell_text(cells[1], '«' + TOPIC + '»', 28, True)
ppl = body[11]
rows = list(ppl.iter(qn('w:tr')))
set_cell_text(rows[0].findall(qn('w:tc'))[1], FIO)
set_cell_text(rows[2].findall(qn('w:tc'))[1], SUPERVISOR)
for r in body[22].iter(qn('w:r')):
    t = r.find(qn('w:t'))
    if t is not None and '20__' in t.text: t.text = t.text.replace('20__', '2027')

# --- стили
st = doc.styles
normal = st['Normal']
normal.font.name = 'Times New Roman'; normal.font.size = Pt(14)
normal.element.rPr.rFonts.set(qn('w:eastAsia'), 'Times New Roman')
pf = normal.paragraph_format
pf.line_spacing = 1.5; pf.space_after = Pt(0); pf.space_before = Pt(0)
for name, size, before in (('Heading 1', 16, 0), ('Heading 2', 14, 12)):
    s = st[name]
    s.font.name = 'Times New Roman'; s.font.size = Pt(size); s.font.bold = True; s.font.italic = False
    s.font.color.rgb = RGBColor(0, 0, 0)
    rpr = s.element.get_or_add_rPr(); rf = rpr.find(qn('w:rFonts'))
    if rf is None: rf = OxmlElement('w:rFonts'); rpr.append(rf)
    for a in ('w:ascii', 'w:hAnsi', 'w:cs', 'w:eastAsia'): rf.set(qn(a), 'Times New Roman')
    for a in ('w:asciiTheme', 'w:hAnsiTheme', 'w:eastAsiaTheme', 'w:cstheme'):
        if rf.get(qn(a)) is not None: del rf.attrib[qn(a)]
    p = s.paragraph_format
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER; p.line_spacing = 1.0; p.space_before = Pt(before); p.space_after = Pt(12)
    p.first_line_indent = Cm(0); p.keep_with_next = True
    p.page_break_before = (name == 'Heading 1')

# --- новый раздел: основная часть
sec = doc.add_section(WD_SECTION.NEW_PAGE)
sec.left_margin, sec.right_margin, sec.top_margin, sec.bottom_margin = Mm(30), Mm(10), Mm(20), Mm(20)
sec.footer.is_linked_to_previous = False
pg = OxmlElement('w:pgNumType'); pg.set(qn('w:start'), str(START_PAGE)); sec._sectPr.append(pg)
fp = sec.footer.paragraphs[0]; fp.alignment = WD_ALIGN_PARAGRAPH.CENTER
def add_field(par, instr, size=12):
    r = par.add_run(); f1 = OxmlElement('w:fldChar'); f1.set(qn('w:fldCharType'), 'begin'); r._r.append(f1)
    r2 = par.add_run(); it = OxmlElement('w:instrText'); it.set('{http://www.w3.org/XML/1998/namespace}space', 'preserve'); it.text = instr; r2._r.append(it)
    r3 = par.add_run(); f2 = OxmlElement('w:fldChar'); f2.set(qn('w:fldCharType'), 'separate'); r3._r.append(f2)
    r4 = par.add_run('1' if 'PAGE' in instr else 'Обновите оглавление: правый щелчок → «Обновить поле»')
    r5 = par.add_run(); f3 = OxmlElement('w:fldChar'); f3.set(qn('w:fldCharType'), 'end'); r5._r.append(f3)
    for rr in (r, r2, r3, r4, r5): rr.font.size = Pt(size); rr.font.name = 'Times New Roman'
add_field(fp, 'PAGE')
# первый раздел (титул) — без номера
s0 = doc.sections[0]
s0.footer.is_linked_to_previous = False
for p in s0.footer.paragraphs: p.text = ''

# Word обновит поля (оглавление) при открытии
settings = doc.settings.element
uf = OxmlElement('w:updateFields'); uf.set(qn('w:val'), 'true'); settings.append(uf)

cnt = {'table': 0, 'fig': 0, 'code': 0}

def para(text, bold=False, align=WD_ALIGN_PARAGRAPH.JUSTIFY, indent=True, size=14, spacing=1.5, keep=False):
    p = doc.add_paragraph()
    p.alignment = align
    p.paragraph_format.first_line_indent = INDENT if indent else Cm(0)
    p.paragraph_format.line_spacing = spacing
    if keep: p.paragraph_format.keep_with_next = True
    add_runs(p, text, bold, size)
    return p

def add_runs(p, text, bold=False, size=14):
    r = p.add_run(text); r.bold = bold; r.font.size = Pt(size)
    return r

def heading(text, level):
    p = doc.add_paragraph(text, style=f'Heading {level}')
    return p

def set_cell_borders(table):
    tblPr = table._tbl.tblPr
    b = OxmlElement('w:tblBorders')
    for e in ('top', 'left', 'bottom', 'right', 'insideH', 'insideV'):
        x = OxmlElement(f'w:{e}'); x.set(qn('w:val'), 'single'); x.set(qn('w:sz'), '4'); x.set(qn('w:color'), '000000'); b.append(x)
    tblPr.append(b)

def add_table(key):
    title, head, rows = TABLES[key]
    cnt['table'] += 1
    para(f'Таблица {cnt["table"]}', bold=True, align=WD_ALIGN_PARAGRAPH.RIGHT, indent=False, spacing=1.0, keep=True)
    para(title, bold=True, align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, spacing=1.0, keep=True)
    t = doc.add_table(rows=1 + len(rows), cols=len(head))
    t.alignment = WD_TABLE_ALIGNMENT.CENTER
    set_cell_borders(t)
    for j, h in enumerate(head):
        c = t.rows[0].cells[j]; p = c.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER; p.paragraph_format.first_line_indent = Cm(0); p.paragraph_format.line_spacing = 1.0
        add_runs(p, h, True, 12)
    # шапка повторяется на каждой странице
    trPr = t.rows[0]._tr.get_or_add_trPr(); th = OxmlElement('w:tblHeader'); th.set(qn('w:val'), 'true'); trPr.append(th)
    for i, row in enumerate(rows, 1):
        for j, v in enumerate(row):
            c = t.rows[i].cells[j]; p = c.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT if j == 0 else WD_ALIGN_PARAGRAPH.JUSTIFY
            p.paragraph_format.first_line_indent = Cm(0); p.paragraph_format.line_spacing = 1.0
            add_runs(p, str(v), False, 12)
    doc.add_paragraph().paragraph_format.line_spacing = 1.0

def add_fig(path, caption, width=Cm(16.5)):
    cnt['fig'] += 1
    p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.first_line_indent = Cm(0); p.paragraph_format.keep_with_next = True; p.paragraph_format.line_spacing = 1.0
    p.add_run().add_picture(path, width=width)
    para(f'Рисунок {cnt["fig"]} – {caption}', bold=True, align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, spacing=1.0)

def add_code(title, code, size=10):
    cnt['code'] += 1
    para(f'Листинг {cnt["code"]} – {title}', bold=True, align=WD_ALIGN_PARAGRAPH.LEFT, indent=False, spacing=1.0, keep=True)
    code_block(code, size)

def code_block(code, size=10):
    for line in code.split('\n'):
        p = doc.add_paragraph(); p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        pf_ = p.paragraph_format; pf_.first_line_indent = Cm(0); pf_.line_spacing = 1.0
        r = p.add_run(line.replace('\t', '    ') if line else ' ')
        r.font.name = 'Courier New'; r.font.size = Pt(size)
        r._element.rPr.rFonts.set(qn('w:eastAsia'), 'Courier New'); r._element.rPr.rFonts.set(qn('w:cs'), 'Courier New')
    doc.add_paragraph().paragraph_format.line_spacing = 1.0

def render(text):
    blocks = [b.strip('\n') for b in re.split(r'\n\s*\n', text.strip())]
    for b in blocks:
        lines = b.split('\n')
        for line in lines:
            line = line.rstrip()
            if not line: continue
            if line.startswith('## '): heading(line[3:], 2)
            elif line.startswith('# '): heading(line[2:], 1)
            elif line.startswith('@table '): add_table(line.split()[1])
            elif line.startswith('@fig '): k = line.split()[1]; add_fig(*FIGS[k])
            elif line.startswith('@code '): k = line.split()[1]; add_code(*CODE[k])
            elif line.startswith('@refs'):
                for i, ref in enumerate(REFS, 1): para(f'{i}. {ref}', indent=True)
            elif line.startswith('- '): para('– ' + line[2:])
            else: para(line)

# --- содержание
p = doc.add_paragraph('СОДЕРЖАНИЕ'); p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.first_line_indent = Cm(0); p.paragraph_format.line_spacing = 1.0; p.paragraph_format.space_after = Pt(12)
p.runs[0].bold = True; p.runs[0].font.size = Pt(16)
tp = doc.add_paragraph(); tp.paragraph_format.first_line_indent = Cm(0)
add_field(tp, 'TOC \\o "1-2" \\h \\z \\u', 14)

def expand(text):
    return re.sub(r'^@extra (\w+)\s*$', lambda m: expand(EXTRA[m.group(1)]), text, flags=re.M)
FULL = expand(T1 + chr(10) + T2 + chr(10) + T3)
NUM = {}
_c = {'table': 0, 'fig': 0, 'code': 0}
for m in re.finditer(r'^@(table|fig|code) (\w+)', FULL, re.M):
    _c[m.group(1)] += 1; NUM[(m.group(1), m.group(2))] = _c[m.group(1)]
def _tok(m):
    kind = {'T': 'table', 'F': 'fig', 'L': 'code'}[m.group(1)]
    return str(NUM[(kind, m.group(2))])
FULL = re.sub(r'\{([TFL]):(\w+)\}', _tok, FULL)
assert '{T:' not in FULL and '{F:' not in FULL and '{L:' not in FULL
render(FULL)

# ------------------------------------------------------------------ приложения
def appendix(letter, title):
    heading(f'ПРИЛОЖЕНИЕ {letter}', 1)
    para(title, bold=True, align=WD_ALIGN_PARAGRAPH.CENTER, indent=False, spacing=1.0)

appendix('А', 'Листинги DDL-скриптов создания базы данных')
for i, (f, t) in enumerate([('01_schema.sql', 'схема: типы, домены, таблицы, ограничения'), ('02_functions.sql', 'функции, процедуры, триггеры, представления'),
                            ('03_indexes.sql', 'индексы'), ('04_seed.sql', 'справочные данные')], 1):
    para(f'А.{i}. Скрипт {f} — {t}', bold=True, align=WD_ALIGN_PARAGRAPH.LEFT, indent=False, spacing=1.0, keep=True)
    code_block(SQL[f].rstrip(), 8)

appendix('Б', 'ER-диаграммы базы данных в увеличенном виде')
for k in ('er1', 'er2', 'er3'):
    add_fig(FIGS[k][0], FIGS[k][1] + ' (полный вид)', Cm(17))

appendix('В', 'Результаты нагрузочного тестирования')
para('Подробные результаты измерения времени запросов (25 запусков EXPLAIN ANALYZE после прогрева, время в миллисекундах). Тестовый стенд: AMD EPYC 7451, 8 vCPU, 48 ГБ ОЗУ, Windows Server 2022, PostgreSQL ' + R['pg_version'] + '.')
TABLES['bench_full'] = ('Подробные результаты измерений времени запросов',
    ['№', 'Конфигурация', 'Медиана', 'Минимум', 'Максимум', 'Стоимость плана', 'Строк'],
    [[k, cfg, ms(D[k]['median_ms']), ms(D[k]['min_ms']), ms(D[k]['max_ms']), f"{D[k]['cost']:.1f}".replace('.', ','), str(D[k]['rows'])]
     for k in QK for cfg, D in (('без индексов', WO), ('с индексами', WI))])
add_table('bench_full')
TABLES['variants2'] = ('Сравнение формулировок подсчёта занятых ячеек инвентаря (2 500 персонажей)',
    ['Формулировка', 'Медиана, мс', 'План выполнения'],
    [[k, ms(v['median_ms']), v['nodes']] for k, v in R['variants_count'].items()])
add_table('variants2')
para('Итог работы утилиты pgbench для сценария чтения (32 клиента, с индексами):', keep=True)
code_block(R['pgbench_read'][-1]['raw'].strip(), 9)
para('Итог работы утилиты pgbench для сценария записи (32 клиента, synchronous_commit = on):', keep=True)
code_block(R['pgbench_write'][-1]['raw'].strip(), 9)
para('Сценарии нагрузки pgbench:', keep=True)
code_block(open(os.path.join(VKR, 'bench', 'read_mix.sql'), encoding='utf-8').read().strip(), 9)
code_block(open(os.path.join(VKR, 'bench', 'write_mix.sql'), encoding='utf-8').read().strip(), 9)

appendix('Г', 'Заполнение базы тестовыми данными и запросы игровых операций')
para('Г.1. Скрипт 05_loadtest.sql — генерация тестового набора данных', bold=True, align=WD_ALIGN_PARAGRAPH.LEFT, indent=False, spacing=1.0, keep=True)
code_block(SQL['05_loadtest.sql'].rstrip(), 8)
para('Г.2. Скрипт 06_queries.sql — запросы основных игровых операций', bold=True, align=WD_ALIGN_PARAGRAPH.LEFT, indent=False, spacing=1.0, keep=True)
code_block(SQL['06_queries.sql'].rstrip(), 8)

appendix('Д', 'Краткое описание игровой механики «Эхо кода»')
for t in [
    '«Эхо кода» (Echoes of the Code) — 2D-платформер с элементами головоломки, стелса и ролевой игры в сеттинге киберпанк. Прототип реализован на HTML5 Canvas и JavaScript и содержит три сектора: «Неоновые крыши», «Серверные фермы» и «Ядро ИИ».',
    'Управление: бег, прыжок и двойной прыжок, спрыгивание с платформ. Взлом терминалов выполняется мини-игрой: игрок повторяет последовательность стрелок за ограниченное время; успешный взлом открывает двери и отключает лазеры, провал поднимает тревогу. Замедление времени расходует энергию: мир замедляется до 35 %, игрок — до 80 %.',
    'Стелс: дроны и камеры наблюдения имеют конусы обзора; линию видимости перекрывают стены, тени скрывают игрока. Пока игрок в конусе, растёт шкала подозрения; при её заполнении включается тревога, и дроны начинают стрелять.',
    'Ролевые элементы, данные которых хранятся в разработанной базе: уровень и репутация персонажа, класс, здоровье и энергия, инвентарь на 25 ячеек, пять предметов-имплантов различной редкости (Нейро-кабель, Крипто-модуль, Визор, Дрон, Голо-дек), из которых одновременно активны не более трёх, фрагменты памяти на уровнях (7, 9 и 6 по секторам), сюжетные диалоги, точки восстановления и статистика прохождения.']:
    para(t)
SH = os.path.join(ROOT, 'screens')
for f, c in (('06_sector3_core.jpg', 'Прототип: финальный сектор «Ядро ИИ»'), ('07_inventory.jpg', 'Прототип: экран инвентаря'), ('04_alarm.jpg', 'Прототип: стелс и тревога')):
    add_fig(os.path.join(SH, f), c, Cm(15))

out = os.path.join(VKR, 'ВКР_Зубович_АИ_текст.docx')
doc.save(out)
print('saved', out, cnt)
