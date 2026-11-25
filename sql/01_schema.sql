-- =====================================================================
-- База данных централизованного хранения игровых элементов RPG
-- Пример: «Эхо кода» (Echoes of the Code)
-- СУБД: PostgreSQL 18
-- Файл 1. Схема: типы, домены, таблицы, ограничения целостности, комментарии
-- =====================================================================

DROP SCHEMA IF EXISTS game CASCADE;
CREATE SCHEMA game;
COMMENT ON SCHEMA game IS 'Игровые элементы RPG «Эхо кода»';
SET search_path TO game, public;

-- ---------- Перечислимые типы ----------
CREATE TYPE rarity_t AS ENUM ('common', 'rare', 'epic', 'legendary');
CREATE TYPE item_category_t AS ENUM ('weapon', 'armor', 'implant', 'consumable', 'quest', 'material');
CREATE TYPE quest_status_t AS ENUM ('active', 'completed', 'failed', 'abandoned');
CREATE TYPE equip_slot_t AS ENUM ('head', 'body', 'hands', 'weapon', 'implant1', 'implant2', 'implant3');
CREATE TYPE npc_role_t AS ENUM ('quest_giver', 'vendor', 'enemy', 'neutral');
CREATE TYPE tx_kind_t AS ENUM ('buy', 'sell', 'trade', 'quest_reward', 'loot', 'repair');
CREATE TYPE objective_kind_t AS ENUM ('hack', 'collect', 'reach', 'defeat', 'talk', 'stealth');

-- ---------- Домены ----------
CREATE DOMAIN d_code AS varchar(48) CHECK (VALUE ~ '^[a-z0-9_]+$');
CREATE DOMAIN d_name AS varchar(64) CHECK (length(btrim(VALUE)) > 0);
CREATE DOMAIN d_login AS varchar(32) CHECK (VALUE ~ '^[A-Za-z0-9_.-]{3,32}$');
CREATE DOMAIN d_money AS bigint CHECK (VALUE >= 0);
CREATE DOMAIN d_level AS smallint CHECK (VALUE BETWEEN 1 AND 100);

-- ---------- Учётные записи ----------
CREATE TABLE players (
    player_id      bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    login          d_login      NOT NULL,
    email          varchar(254) NOT NULL,
    password_hash  text         NOT NULL,
    region         varchar(8)   NOT NULL DEFAULT 'RU',
    is_banned      boolean      NOT NULL DEFAULT false,
    created_at     timestamptz  NOT NULL DEFAULT now(),
    last_login_at  timestamptz,
    CONSTRAINT players_email_chk CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    CONSTRAINT players_last_login_chk CHECK (last_login_at IS NULL OR last_login_at >= created_at)
);
CREATE UNIQUE INDEX players_login_uq ON players (lower(login));
CREATE UNIQUE INDEX players_email_uq ON players (lower(email));
COMMENT ON TABLE players IS 'Учётные записи игроков';
COMMENT ON COLUMN players.password_hash IS 'Хеш пароля (bcrypt/argon2), открытый пароль не хранится';

CREATE TABLE player_settings (
    player_id  bigint PRIMARY KEY REFERENCES players (player_id) ON DELETE CASCADE,
    settings   jsonb  NOT NULL DEFAULT '{}'::jsonb,
    updated_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT player_settings_obj_chk CHECK (jsonb_typeof(settings) = 'object')
);
COMMENT ON TABLE player_settings IS 'Настройки клиента (громкость, масштаб, сложность) в формате JSONB';

CREATE TABLE sessions (
    session_id     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id      bigint NOT NULL REFERENCES players (player_id) ON DELETE CASCADE,
    started_at     timestamptz NOT NULL DEFAULT now(),
    ended_at       timestamptz,
    ip             inet,
    client_version varchar(16) NOT NULL,
    CONSTRAINT sessions_period_chk CHECK (ended_at IS NULL OR ended_at >= started_at)
);
COMMENT ON TABLE sessions IS 'Игровые сессии: используется для аналитики и мониторинга';

-- ---------- Мир ----------
CREATE TABLE factions (
    faction_id  smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        d_code NOT NULL UNIQUE,
    name        d_name NOT NULL,
    description text
);
COMMENT ON TABLE factions IS 'Фракции (корпорация «Нексус», сопротивление и др.)';

CREATE TABLE locations (
    location_id  integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code         d_code NOT NULL UNIQUE,
    name         d_name NOT NULL,
    sector       smallint NOT NULL CHECK (sector BETWEEN 1 AND 20),
    min_level    d_level NOT NULL DEFAULT 1,
    is_safe      boolean NOT NULL DEFAULT false,
    pos          point NOT NULL,
    description  text
);
COMMENT ON TABLE locations IS 'Локации игрового мира';
COMMENT ON COLUMN locations.pos IS 'Координаты локации на карте мира (тип point, индекс GiST)';

CREATE TABLE location_links (
    from_location_id integer NOT NULL REFERENCES locations (location_id) ON DELETE CASCADE,
    to_location_id   integer NOT NULL REFERENCES locations (location_id) ON DELETE CASCADE,
    requires_item_id integer,
    travel_seconds   smallint NOT NULL DEFAULT 0 CHECK (travel_seconds >= 0),
    PRIMARY KEY (from_location_id, to_location_id),
    CONSTRAINT location_links_self_chk CHECK (from_location_id <> to_location_id)
);
COMMENT ON TABLE location_links IS 'Переходы между локациями (ориентированный граф)';

-- ---------- Классы, уровни, характеристики ----------
CREATE TABLE character_classes (
    class_id     smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code         d_code NOT NULL UNIQUE,
    name         d_name NOT NULL,
    description  text,
    base_hp      smallint NOT NULL CHECK (base_hp > 0),
    base_energy  smallint NOT NULL CHECK (base_energy > 0)
);
COMMENT ON TABLE character_classes IS 'Классы персонажей (хакер, инфильтратор, техник, оператор)';

CREATE TABLE attributes (
    attr_id   smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code      d_code NOT NULL UNIQUE,
    name      d_name NOT NULL,
    max_value smallint NOT NULL DEFAULT 100 CHECK (max_value > 0)
);
COMMENT ON TABLE attributes IS 'Справочник характеристик (взлом, скрытность, ловкость…)';

CREATE TABLE class_base_attributes (
    class_id smallint NOT NULL REFERENCES character_classes (class_id) ON DELETE CASCADE,
    attr_id  smallint NOT NULL REFERENCES attributes (attr_id),
    value    smallint NOT NULL CHECK (value >= 0),
    PRIMARY KEY (class_id, attr_id)
);
COMMENT ON TABLE class_base_attributes IS 'Стартовые значения характеристик для класса';

CREATE TABLE level_thresholds (
    level        d_level PRIMARY KEY,
    xp_required  bigint NOT NULL UNIQUE CHECK (xp_required >= 0),
    skill_points smallint NOT NULL DEFAULT 1 CHECK (skill_points >= 0)
);
COMMENT ON TABLE level_thresholds IS 'Таблица опыта: суммарный опыт для достижения уровня';

-- ---------- Персонажи ----------
CREATE TABLE characters (
    character_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id    bigint   NOT NULL REFERENCES players (player_id) ON DELETE CASCADE,
    class_id     smallint NOT NULL REFERENCES character_classes (class_id),
    name         d_name   NOT NULL,
    level        d_level  NOT NULL DEFAULT 1,
    experience   bigint   NOT NULL DEFAULT 0 CHECK (experience >= 0),
    hp           smallint NOT NULL CHECK (hp >= 0),
    max_hp       smallint NOT NULL CHECK (max_hp > 0),
    energy       smallint NOT NULL DEFAULT 100 CHECK (energy BETWEEN 0 AND 100),
    credits      d_money  NOT NULL DEFAULT 0,
    skill_points smallint NOT NULL DEFAULT 0 CHECK (skill_points >= 0),
    location_id  integer  NOT NULL REFERENCES locations (location_id),
    inventory_size smallint NOT NULL DEFAULT 25 CHECK (inventory_size BETWEEN 10 AND 100),
    is_deleted   boolean  NOT NULL DEFAULT false,
    created_at   timestamptz NOT NULL DEFAULT now(),
    updated_at   timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT characters_hp_chk CHECK (hp <= max_hp)
);
CREATE UNIQUE INDEX characters_name_uq ON characters (lower(name)) WHERE NOT is_deleted;
COMMENT ON TABLE characters IS 'Игровые персонажи; у игрока может быть несколько персонажей';
COMMENT ON COLUMN characters.inventory_size IS 'Число ячеек инвентаря (в клиенте 5×5 = 25)';

CREATE TABLE character_attributes (
    character_id bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    attr_id      smallint NOT NULL REFERENCES attributes (attr_id),
    value        smallint NOT NULL CHECK (value >= 0),
    PRIMARY KEY (character_id, attr_id)
);
COMMENT ON TABLE character_attributes IS 'Текущие значения характеристик персонажа';

CREATE TABLE character_reputation (
    character_id bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    faction_id   smallint NOT NULL REFERENCES factions (faction_id),
    value        integer  NOT NULL DEFAULT 0 CHECK (value BETWEEN -10000 AND 10000),
    PRIMARY KEY (character_id, faction_id)
);
COMMENT ON TABLE character_reputation IS 'Репутация персонажа у фракций';

-- ---------- Предметы ----------
CREATE TABLE item_templates (
    item_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code         d_code   NOT NULL UNIQUE,
    name         d_name   NOT NULL,
    category     item_category_t NOT NULL,
    rarity       rarity_t NOT NULL DEFAULT 'common',
    level_req    d_level  NOT NULL DEFAULT 1,
    max_stack    smallint NOT NULL DEFAULT 1 CHECK (max_stack BETWEEN 1 AND 999),
    base_price   d_money  NOT NULL DEFAULT 0,
    is_tradeable boolean  NOT NULL DEFAULT true,
    equip_slot   equip_slot_t,
    stats        jsonb    NOT NULL DEFAULT '{}'::jsonb,
    description  text,
    CONSTRAINT item_templates_stats_chk CHECK (jsonb_typeof(stats) = 'object'),
    CONSTRAINT item_templates_stack_chk CHECK (category IN ('consumable', 'material', 'quest') OR max_stack = 1),
    CONSTRAINT item_templates_slot_chk CHECK ((category IN ('weapon', 'armor', 'implant')) = (equip_slot IS NOT NULL))
);
COMMENT ON TABLE item_templates IS 'Справочник (шаблоны) предметов: общие свойства всех экземпляров';
COMMENT ON COLUMN item_templates.stats IS 'Характеристики предмета в JSONB: {"damage":12,"hack_time":0.4,...}';

ALTER TABLE location_links
    ADD CONSTRAINT location_links_item_fk FOREIGN KEY (requires_item_id) REFERENCES item_templates (item_id);

CREATE TABLE item_instances (
    instance_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id       integer NOT NULL REFERENCES item_templates (item_id),
    owner_id      bigint  REFERENCES characters (character_id) ON DELETE SET NULL,
    durability    smallint NOT NULL DEFAULT 100 CHECK (durability BETWEEN 0 AND 100),
    upgrade_level smallint NOT NULL DEFAULT 0 CHECK (upgrade_level BETWEEN 0 AND 15),
    is_bound      boolean NOT NULL DEFAULT false,
    rolled_stats  jsonb   NOT NULL DEFAULT '{}'::jsonb,
    created_at    timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE item_instances IS 'Уникальные экземпляры предметов (оружие, броня, импланты) с индивидуальными свойствами';

CREATE TABLE inventory (
    character_id bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    slot_no      smallint NOT NULL CHECK (slot_no BETWEEN 0 AND 99),
    item_id      integer  NOT NULL REFERENCES item_templates (item_id),
    instance_id  bigint   UNIQUE REFERENCES item_instances (instance_id) ON DELETE CASCADE,
    quantity     smallint NOT NULL DEFAULT 1 CHECK (quantity BETWEEN 1 AND 999),
    acquired_at  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, slot_no),
    CONSTRAINT inventory_instance_qty_chk CHECK (instance_id IS NULL OR quantity = 1)
);
COMMENT ON TABLE inventory IS 'Инвентарь: связь персонажа и предмета с указанием ячейки и количества';

CREATE TABLE equipment (
    character_id bigint       NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    slot         equip_slot_t NOT NULL,
    instance_id  bigint       NOT NULL UNIQUE REFERENCES item_instances (instance_id) ON DELETE CASCADE,
    equipped_at  timestamptz  NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, slot)
);
COMMENT ON TABLE equipment IS 'Надетые предметы и активные импланты (не более 3 имплантов)';

-- ---------- Навыки ----------
CREATE TABLE skills (
    skill_id     smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code         d_code NOT NULL UNIQUE,
    name         d_name NOT NULL,
    class_id     smallint REFERENCES character_classes (class_id),
    max_rank     smallint NOT NULL DEFAULT 5 CHECK (max_rank BETWEEN 1 AND 10),
    energy_cost  smallint NOT NULL DEFAULT 0 CHECK (energy_cost BETWEEN 0 AND 100),
    cooldown_ms  integer  NOT NULL DEFAULT 0 CHECK (cooldown_ms >= 0),
    level_req    d_level  NOT NULL DEFAULT 1,
    description  text
);
COMMENT ON TABLE skills IS 'Навыки и умения; class_id = NULL — общий навык';

CREATE TABLE skill_prerequisites (
    skill_id          smallint NOT NULL REFERENCES skills (skill_id) ON DELETE CASCADE,
    requires_skill_id smallint NOT NULL REFERENCES skills (skill_id) ON DELETE CASCADE,
    min_rank          smallint NOT NULL DEFAULT 1 CHECK (min_rank >= 1),
    PRIMARY KEY (skill_id, requires_skill_id),
    CONSTRAINT skill_prereq_self_chk CHECK (skill_id <> requires_skill_id)
);
COMMENT ON TABLE skill_prerequisites IS 'Дерево навыков: какие навыки нужно изучить раньше';

CREATE TABLE character_skills (
    character_id bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    skill_id     smallint NOT NULL REFERENCES skills (skill_id),
    rank         smallint NOT NULL DEFAULT 1 CHECK (rank >= 1),
    learned_at   timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, skill_id)
);
COMMENT ON TABLE character_skills IS 'Изученные персонажем навыки (связь многие-ко-многим)';

-- ---------- NPC ----------
CREATE TABLE npcs (
    npc_id      integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code        d_code NOT NULL UNIQUE,
    name        d_name NOT NULL,
    location_id integer NOT NULL REFERENCES locations (location_id),
    faction_id  smallint REFERENCES factions (faction_id),
    role        npc_role_t NOT NULL,
    level       d_level NOT NULL DEFAULT 1,
    dialog      jsonb NOT NULL DEFAULT '[]'::jsonb,
    CONSTRAINT npcs_dialog_chk CHECK (jsonb_typeof(dialog) = 'array')
);
COMMENT ON TABLE npcs IS 'Неигровые персонажи: квестодатели, торговцы, противники';

CREATE TABLE vendor_stock (
    npc_id   integer NOT NULL REFERENCES npcs (npc_id) ON DELETE CASCADE,
    item_id  integer NOT NULL REFERENCES item_templates (item_id),
    price    d_money NOT NULL,
    stock    smallint CHECK (stock IS NULL OR stock >= 0),
    PRIMARY KEY (npc_id, item_id)
);
COMMENT ON TABLE vendor_stock IS 'Ассортимент торговцев; stock = NULL — неограниченно';

CREATE TABLE enemy_loot (
    npc_id   integer NOT NULL REFERENCES npcs (npc_id) ON DELETE CASCADE,
    item_id  integer NOT NULL REFERENCES item_templates (item_id),
    chance   numeric(5,4) NOT NULL CHECK (chance > 0 AND chance <= 1),
    min_qty  smallint NOT NULL DEFAULT 1 CHECK (min_qty >= 1),
    max_qty  smallint NOT NULL DEFAULT 1,
    PRIMARY KEY (npc_id, item_id),
    CONSTRAINT enemy_loot_qty_chk CHECK (max_qty >= min_qty)
);
COMMENT ON TABLE enemy_loot IS 'Таблица добычи с противников';

-- ---------- Квесты ----------
CREATE TABLE quests (
    quest_id       integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code           d_code NOT NULL UNIQUE,
    name           d_name NOT NULL,
    description    text NOT NULL,
    giver_npc_id   integer REFERENCES npcs (npc_id),
    location_id    integer NOT NULL REFERENCES locations (location_id),
    min_level      d_level NOT NULL DEFAULT 1,
    is_main        boolean NOT NULL DEFAULT false,
    is_repeatable  boolean NOT NULL DEFAULT false,
    xp_reward      integer NOT NULL DEFAULT 0 CHECK (xp_reward >= 0),
    credits_reward d_money NOT NULL DEFAULT 0
);
COMMENT ON TABLE quests IS 'Квесты (задания)';

CREATE TABLE quest_prerequisites (
    quest_id          integer NOT NULL REFERENCES quests (quest_id) ON DELETE CASCADE,
    requires_quest_id integer NOT NULL REFERENCES quests (quest_id) ON DELETE CASCADE,
    PRIMARY KEY (quest_id, requires_quest_id),
    CONSTRAINT quest_prereq_self_chk CHECK (quest_id <> requires_quest_id)
);
COMMENT ON TABLE quest_prerequisites IS 'Цепочки квестов: квест доступен после выполнения предыдущих';

CREATE TABLE quest_objectives (
    objective_id   integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quest_id       integer NOT NULL REFERENCES quests (quest_id) ON DELETE CASCADE,
    ord            smallint NOT NULL CHECK (ord >= 1),
    kind           objective_kind_t NOT NULL,
    target_code    d_code NOT NULL,
    required_count smallint NOT NULL DEFAULT 1 CHECK (required_count >= 1),
    description    text NOT NULL,
    UNIQUE (quest_id, ord)
);
COMMENT ON TABLE quest_objectives IS 'Цели квеста (взломать, собрать, дойти…)';

CREATE TABLE quest_reward_items (
    quest_id integer NOT NULL REFERENCES quests (quest_id) ON DELETE CASCADE,
    item_id  integer NOT NULL REFERENCES item_templates (item_id),
    quantity smallint NOT NULL DEFAULT 1 CHECK (quantity >= 1),
    PRIMARY KEY (quest_id, item_id)
);
COMMENT ON TABLE quest_reward_items IS 'Предметы-награды за квест';

CREATE TABLE character_quests (
    character_id bigint  NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    quest_id     integer NOT NULL REFERENCES quests (quest_id),
    status       quest_status_t NOT NULL DEFAULT 'active',
    started_at   timestamptz NOT NULL DEFAULT now(),
    finished_at  timestamptz,
    PRIMARY KEY (character_id, quest_id),
    CONSTRAINT character_quests_finish_chk CHECK ((status = 'active') = (finished_at IS NULL))
);
COMMENT ON TABLE character_quests IS 'Журнал квестов персонажа и их статус';

CREATE TABLE quest_progress (
    character_id bigint  NOT NULL,
    quest_id     integer NOT NULL,
    objective_id integer NOT NULL REFERENCES quest_objectives (objective_id) ON DELETE CASCADE,
    progress     smallint NOT NULL DEFAULT 0 CHECK (progress >= 0),
    PRIMARY KEY (character_id, objective_id),
    FOREIGN KEY (character_id, quest_id) REFERENCES character_quests (character_id, quest_id) ON DELETE CASCADE
);
COMMENT ON TABLE quest_progress IS 'Прогресс по целям активных квестов';

-- ---------- Достижения и фрагменты памяти ----------
CREATE TABLE achievements (
    achievement_id smallint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code           d_code NOT NULL UNIQUE,
    name           d_name NOT NULL,
    description    text NOT NULL,
    points         smallint NOT NULL DEFAULT 10 CHECK (points > 0),
    is_hidden      boolean NOT NULL DEFAULT false
);
COMMENT ON TABLE achievements IS 'Достижения';

CREATE TABLE character_achievements (
    character_id   bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    achievement_id smallint NOT NULL REFERENCES achievements (achievement_id),
    unlocked_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, achievement_id)
);
COMMENT ON TABLE character_achievements IS 'Полученные персонажем достижения';

CREATE TABLE memory_fragments (
    fragment_id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id integer NOT NULL REFERENCES locations (location_id),
    ord         smallint NOT NULL,
    lore_text   text NOT NULL,
    UNIQUE (location_id, ord)
);
COMMENT ON TABLE memory_fragments IS 'Фрагменты памяти Призрака — коллекционные предметы уровней';

CREATE TABLE character_fragments (
    character_id bigint  NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    fragment_id  integer NOT NULL REFERENCES memory_fragments (fragment_id),
    found_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, fragment_id)
);

-- ---------- Экономика и журналы ----------
CREATE TABLE transactions (
    tx_id        bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    character_id bigint NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    kind         tx_kind_t NOT NULL,
    amount       bigint NOT NULL,
    item_id      integer REFERENCES item_templates (item_id),
    quantity     smallint CHECK (quantity IS NULL OR quantity > 0),
    created_at   timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE transactions IS 'Журнал экономических операций (amount < 0 — расход)';

CREATE TABLE item_transfers (
    transfer_id    bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    from_character bigint NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    to_character   bigint NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    item_id        integer NOT NULL REFERENCES item_templates (item_id),
    instance_id    bigint,
    quantity       smallint NOT NULL CHECK (quantity > 0),
    transferred_at timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT item_transfers_self_chk CHECK (from_character <> to_character)
);
COMMENT ON TABLE item_transfers IS 'Журнал передач предметов между персонажами';

CREATE TABLE audit_log (
    audit_id   bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name text NOT NULL,
    operation  char(1) NOT NULL CHECK (operation IN ('I', 'U', 'D')),
    row_pk     text NOT NULL,
    old_data   jsonb,
    new_data   jsonb,
    changed_by text NOT NULL DEFAULT current_user,
    changed_at timestamptz NOT NULL DEFAULT now()
);
COMMENT ON TABLE audit_log IS 'Аудит изменений критичных данных (кредиты, уровень)';

CREATE TABLE game_saves (
    character_id bigint   NOT NULL REFERENCES characters (character_id) ON DELETE CASCADE,
    slot         smallint NOT NULL CHECK (slot BETWEEN 0 AND 4),
    sector       smallint NOT NULL,
    checkpoint   point    NOT NULL,
    state        jsonb    NOT NULL DEFAULT '{}'::jsonb,
    saved_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (character_id, slot)
);
COMMENT ON TABLE game_saves IS 'Сохранения: сектор, точка восстановления, состояние уровня';
