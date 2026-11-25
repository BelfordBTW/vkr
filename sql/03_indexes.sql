-- =====================================================================
-- Файл 3. Индексы для ускорения частых запросов.
-- Вынесены отдельно, чтобы измерить производительность с ними и без них.
-- Первичные ключи и UNIQUE-ограничения создаются в 01_schema.sql.
-- =====================================================================
SET search_path TO game, public;

-- Внешние ключи (PostgreSQL не создаёт индексы для FK автоматически)
CREATE INDEX ix_characters_player       ON characters (player_id) WHERE NOT is_deleted;
CREATE INDEX ix_characters_location     ON characters (location_id);
CREATE INDEX ix_item_instances_owner    ON item_instances (owner_id);
CREATE INDEX ix_inventory_item          ON inventory (item_id);
CREATE INDEX ix_npcs_location           ON npcs (location_id);
CREATE INDEX ix_quests_giver            ON quests (giver_npc_id);
CREATE INDEX ix_quests_location         ON quests (location_id);
CREATE INDEX ix_sessions_player_started ON sessions (player_id, started_at DESC);
CREATE INDEX ix_item_transfers_from     ON item_transfers (from_character, transferred_at DESC);
CREATE INDEX ix_item_transfers_to       ON item_transfers (to_character, transferred_at DESC);

-- Поиск предметов по критериям: составной индекс по типу, редкости и уровню
CREATE INDEX ix_items_cat_rarity_lvl ON item_templates (category, rarity, level_req);
-- Поиск по характеристикам в JSONB (оператор @>)
CREATE INDEX ix_items_stats_gin ON item_templates USING gin (stats jsonb_path_ops);
-- Числовые характеристики: индекс по выражению
CREATE INDEX ix_items_damage ON item_templates (((stats ->> 'damage')::int)) WHERE stats ? 'damage';

-- Журнал квестов: частичный индекс только по активным квестам
CREATE INDEX ix_char_quests_active ON character_quests (character_id) WHERE status = 'active';
CREATE INDEX ix_char_quests_quest_status ON character_quests (quest_id, status);

-- Таблица лидеров и рейтинги по классу
CREATE INDEX ix_characters_class_xp ON characters (class_id, experience DESC) WHERE NOT is_deleted;
CREATE INDEX ix_characters_xp ON characters (experience DESC) WHERE NOT is_deleted;
CREATE UNIQUE INDEX ix_mv_leaderboard_id ON mv_leaderboard (character_id);

-- Экономика: выборки по персонажу и по периоду
CREATE INDEX ix_transactions_char_time ON transactions (character_id, created_at DESC);
CREATE INDEX ix_transactions_time_brin ON transactions USING brin (created_at);

-- Геоданные локаций: поиск ближайших (оператор <->)
CREATE INDEX ix_locations_pos_gist ON locations USING gist (pos);

-- Аудит
CREATE INDEX ix_audit_table_pk ON audit_log (table_name, row_pk, changed_at DESC);
