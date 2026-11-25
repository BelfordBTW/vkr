-- =====================================================================
-- Файл 2. Функции, процедуры, триггеры и представления
-- У каждой функции зафиксирован search_path: функция работает одинаково
-- независимо от настроек вызывающего сеанса и защищена от подмены объектов.
-- =====================================================================
SET search_path TO game, public;

-- ---------- Служебные триггеры ----------
CREATE OR REPLACE FUNCTION trg_set_updated_at() RETURNS trigger
LANGUAGE plpgsql SET search_path = game, public AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END $$;

CREATE TRIGGER characters_updated_at
    BEFORE UPDATE ON characters
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

CREATE TRIGGER player_settings_updated_at
    BEFORE UPDATE ON player_settings
    FOR EACH ROW EXECUTE FUNCTION trg_set_updated_at();

-- Уровень персонажа вычисляется из опыта по таблице level_thresholds
CREATE OR REPLACE FUNCTION trg_character_level() RETURNS trigger
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_new_level smallint;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.experience = OLD.experience THEN
        RETURN NEW;
    END IF;
    SELECT max(level) INTO v_new_level
      FROM level_thresholds
     WHERE xp_required <= NEW.experience;
    v_new_level := coalesce(v_new_level, 1);
    IF TG_OP = 'UPDATE' AND v_new_level > OLD.level THEN
        NEW.skill_points := NEW.skill_points + (
            SELECT coalesce(sum(skill_points), 0)::smallint
              FROM level_thresholds
             WHERE level > OLD.level AND level <= v_new_level);
        NEW.hp := NEW.max_hp;              -- при повышении уровня здоровье восстанавливается
    END IF;
    NEW.level := v_new_level;
    RETURN NEW;
END $$;

CREATE TRIGGER characters_level
    BEFORE INSERT OR UPDATE OF experience ON characters
    FOR EACH ROW EXECUTE FUNCTION trg_character_level();

-- Аудит изменения кредитов и уровня
CREATE OR REPLACE FUNCTION trg_audit_character() RETURNS trigger
LANGUAGE plpgsql SET search_path = game, public AS $$
BEGIN
    IF NEW.credits IS DISTINCT FROM OLD.credits OR NEW.level IS DISTINCT FROM OLD.level THEN
        INSERT INTO audit_log (table_name, operation, row_pk, old_data, new_data)
        VALUES ('characters', 'U', OLD.character_id::text,
                jsonb_build_object('credits', OLD.credits, 'level', OLD.level),
                jsonb_build_object('credits', NEW.credits, 'level', NEW.level));
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER characters_audit
    AFTER UPDATE OF credits, level ON characters
    FOR EACH ROW EXECUTE FUNCTION trg_audit_character();

-- Не больше трёх имплантов: ограничение реализуется ENUM-слотами implant1..3,
-- а здесь проверяется, что в слот надевается предмет подходящего типа и уровня
CREATE OR REPLACE FUNCTION trg_equipment_check() RETURNS trigger
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_slot  equip_slot_t;
    v_owner bigint;
    v_req   smallint;
    v_lvl   smallint;
BEGIN
    SELECT t.equip_slot, i.owner_id, t.level_req
      INTO v_slot, v_owner, v_req
      FROM item_instances i JOIN item_templates t USING (item_id)
     WHERE i.instance_id = NEW.instance_id;
    IF v_owner IS DISTINCT FROM NEW.character_id THEN
        RAISE EXCEPTION 'Предмет % не принадлежит персонажу %', NEW.instance_id, NEW.character_id;
    END IF;
    IF v_slot IS NULL OR (v_slot <> NEW.slot AND NOT (v_slot::text LIKE 'implant%' AND NEW.slot::text LIKE 'implant%')) THEN
        RAISE EXCEPTION 'Предмет нельзя надеть в слот %', NEW.slot;
    END IF;
    SELECT level INTO v_lvl FROM characters WHERE character_id = NEW.character_id;
    IF v_lvl < v_req THEN
        RAISE EXCEPTION 'Требуется уровень %', v_req;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER equipment_check
    BEFORE INSERT OR UPDATE ON equipment
    FOR EACH ROW EXECUTE FUNCTION trg_equipment_check();

-- Размер стека не превышает max_stack шаблона
CREATE OR REPLACE FUNCTION trg_inventory_stack() RETURNS trigger
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_max smallint;
    v_size smallint;
BEGIN
    SELECT max_stack INTO v_max FROM item_templates WHERE item_id = NEW.item_id;
    IF NEW.quantity > v_max THEN
        RAISE EXCEPTION 'Превышен размер стека (% > %)', NEW.quantity, v_max;
    END IF;
    SELECT inventory_size INTO v_size FROM characters WHERE character_id = NEW.character_id;
    IF NEW.slot_no >= v_size THEN
        RAISE EXCEPTION 'Ячейка % вне инвентаря (размер %)', NEW.slot_no, v_size;
    END IF;
    RETURN NEW;
END $$;

CREATE TRIGGER inventory_stack
    BEFORE INSERT OR UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION trg_inventory_stack();

-- ---------- Игровые операции ----------

-- Создание персонажа: строка персонажа + характеристики класса + стартовый набор
CREATE OR REPLACE FUNCTION create_character(p_player bigint, p_name text, p_class_code text)
RETURNS bigint
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_class  character_classes%ROWTYPE;
    v_loc    integer;
    v_id     bigint;
BEGIN
    SELECT * INTO STRICT v_class FROM character_classes WHERE code = p_class_code;
    SELECT location_id INTO STRICT v_loc FROM locations WHERE code = 'neon_rooftops';
    INSERT INTO characters (player_id, class_id, name, hp, max_hp, location_id)
    VALUES (p_player, v_class.class_id, p_name, v_class.base_hp, v_class.base_hp, v_loc)
    RETURNING character_id INTO v_id;
    INSERT INTO character_attributes (character_id, attr_id, value)
    SELECT v_id, attr_id, value FROM class_base_attributes WHERE class_id = v_class.class_id;
    INSERT INTO character_reputation (character_id, faction_id)
    SELECT v_id, faction_id FROM factions;
    PERFORM add_item(v_id, 'stim_pack', 3);
    PERFORM add_item(v_id, 'data_shard', 1);
    RETURN v_id;
END $$;
COMMENT ON FUNCTION create_character IS 'Создание персонажа со стартовыми характеристиками и предметами';

-- Добавление предмета: досыпает в существующие стеки, затем занимает свободные ячейки
CREATE OR REPLACE FUNCTION add_item(p_character bigint, p_item_code text, p_qty integer)
RETURNS integer
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_item  item_templates%ROWTYPE;
    v_left  integer := p_qty;
    v_slot  record;
    v_free  smallint;
    v_take  integer;
    v_size  smallint;
    v_inst  bigint;
BEGIN
    IF p_qty <= 0 THEN
        RAISE EXCEPTION 'Количество должно быть положительным';
    END IF;
    SELECT * INTO STRICT v_item FROM item_templates WHERE code = p_item_code;
    SELECT inventory_size INTO v_size FROM characters WHERE character_id = p_character FOR UPDATE;
    -- 1. досыпаем в неполные стеки
    IF v_item.max_stack > 1 THEN
        FOR v_slot IN
            SELECT slot_no, quantity FROM inventory
             WHERE character_id = p_character AND item_id = v_item.item_id AND quantity < v_item.max_stack
             ORDER BY slot_no
             FOR UPDATE
        LOOP
            v_take := least(v_left, v_item.max_stack - v_slot.quantity);
            UPDATE inventory SET quantity = quantity + v_take
             WHERE character_id = p_character AND slot_no = v_slot.slot_no;
            v_left := v_left - v_take;
            EXIT WHEN v_left = 0;
        END LOOP;
    END IF;
    -- 2. новые ячейки
    WHILE v_left > 0 LOOP
        SELECT min(s) INTO v_free
          FROM generate_series(0, v_size - 1) AS s
         WHERE NOT EXISTS (SELECT 1 FROM inventory i WHERE i.character_id = p_character AND i.slot_no = s);
        IF v_free IS NULL THEN
            RAISE EXCEPTION 'Инвентарь заполнен' USING ERRCODE = 'P0001';
        END IF;
        v_take := least(v_left, v_item.max_stack);
        v_inst := NULL;
        IF v_item.max_stack = 1 AND v_item.category IN ('weapon', 'armor', 'implant') THEN
            INSERT INTO item_instances (item_id, owner_id) VALUES (v_item.item_id, p_character)
            RETURNING instance_id INTO v_inst;
        END IF;
        INSERT INTO inventory (character_id, slot_no, item_id, instance_id, quantity)
        VALUES (p_character, v_free, v_item.item_id, v_inst, v_take);
        v_left := v_left - v_take;
    END LOOP;
    RETURN p_qty;
END $$;
COMMENT ON FUNCTION add_item IS 'Добавление предмета в инвентарь с учётом стеков и свободных ячеек';

-- Удаление предмета из ячейки
CREATE OR REPLACE FUNCTION remove_item(p_character bigint, p_slot smallint, p_qty integer)
RETURNS void
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_qty smallint;
BEGIN
    SELECT quantity INTO v_qty FROM inventory
     WHERE character_id = p_character AND slot_no = p_slot FOR UPDATE;
    IF NOT FOUND OR v_qty < p_qty THEN
        RAISE EXCEPTION 'Недостаточно предметов в ячейке %', p_slot;
    END IF;
    IF v_qty = p_qty THEN
        DELETE FROM inventory WHERE character_id = p_character AND slot_no = p_slot;
    ELSE
        UPDATE inventory SET quantity = quantity - p_qty WHERE character_id = p_character AND slot_no = p_slot;
    END IF;
END $$;

-- Передача предмета между персонажами: атомарная процедура.
-- Строки блокируются в порядке возрастания id, чтобы исключить взаимоблокировки.
CREATE OR REPLACE PROCEDURE transfer_item(p_from bigint, p_to bigint, p_slot smallint, p_qty integer)
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_inv  inventory%ROWTYPE;
    v_code text;
    v_trade boolean;
BEGIN
    PERFORM 1 FROM characters WHERE character_id IN (p_from, p_to) ORDER BY character_id FOR UPDATE;
    SELECT * INTO v_inv FROM inventory WHERE character_id = p_from AND slot_no = p_slot FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ячейка % пуста', p_slot;
    END IF;
    SELECT code, is_tradeable INTO v_code, v_trade FROM item_templates WHERE item_id = v_inv.item_id;
    IF NOT v_trade THEN
        RAISE EXCEPTION 'Предмет % нельзя передать', v_code;
    END IF;
    IF v_inv.instance_id IS NOT NULL THEN
        IF EXISTS (SELECT 1 FROM item_instances WHERE instance_id = v_inv.instance_id AND is_bound) THEN
            RAISE EXCEPTION 'Предмет привязан к персонажу';
        END IF;
        DELETE FROM equipment WHERE instance_id = v_inv.instance_id;
        DELETE FROM inventory WHERE character_id = p_from AND slot_no = p_slot;
        UPDATE item_instances SET owner_id = p_to WHERE instance_id = v_inv.instance_id;
        INSERT INTO inventory (character_id, slot_no, item_id, instance_id, quantity)
        SELECT p_to, min(s), v_inv.item_id, v_inv.instance_id, 1
          FROM generate_series(0, (SELECT inventory_size - 1 FROM characters WHERE character_id = p_to)) s
         WHERE NOT EXISTS (SELECT 1 FROM inventory i WHERE i.character_id = p_to AND i.slot_no = s)
        HAVING min(s) IS NOT NULL;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Инвентарь получателя заполнен';
        END IF;
    ELSE
        PERFORM remove_item(p_from, p_slot, p_qty);
        PERFORM add_item(p_to, v_code, p_qty);
    END IF;
    INSERT INTO item_transfers (from_character, to_character, item_id, instance_id, quantity)
    VALUES (p_from, p_to, v_inv.item_id, v_inv.instance_id, p_qty);
END $$;
COMMENT ON PROCEDURE transfer_item IS 'Передача предмета: всё или ничего (ACID)';

-- Покупка у торговца
CREATE OR REPLACE FUNCTION buy_item(p_character bigint, p_npc integer, p_item_code text, p_qty integer)
RETURNS bigint
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_price  bigint;
    v_stock  smallint;
    v_item   integer;
    v_credits bigint;
BEGIN
    SELECT vs.price, vs.stock, vs.item_id INTO v_price, v_stock, v_item
      FROM vendor_stock vs JOIN item_templates t USING (item_id)
     WHERE vs.npc_id = p_npc AND t.code = p_item_code
       FOR UPDATE OF vs;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Торговец не продаёт %', p_item_code;
    END IF;
    IF v_stock IS NOT NULL AND v_stock < p_qty THEN
        RAISE EXCEPTION 'Недостаточно товара';
    END IF;
    UPDATE characters SET credits = credits - v_price * p_qty
     WHERE character_id = p_character
    RETURNING credits INTO v_credits;          -- CHECK (credits >= 0) не даст уйти в минус
    IF v_stock IS NOT NULL THEN
        UPDATE vendor_stock SET stock = stock - p_qty WHERE npc_id = p_npc AND item_id = v_item;
    END IF;
    PERFORM add_item(p_character, p_item_code, p_qty);
    INSERT INTO transactions (character_id, kind, amount, item_id, quantity)
    VALUES (p_character, 'buy', -v_price * p_qty, v_item, p_qty);
    RETURN v_credits;
END $$;

-- Взять квест: проверка уровня, цепочки и повторного взятия
CREATE OR REPLACE FUNCTION accept_quest(p_character bigint, p_quest integer)
RETURNS void
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_lvl smallint;
    v_q   quests%ROWTYPE;
BEGIN
    SELECT * INTO STRICT v_q FROM quests WHERE quest_id = p_quest;
    SELECT level INTO v_lvl FROM characters WHERE character_id = p_character;
    IF v_lvl < v_q.min_level THEN
        RAISE EXCEPTION 'Квест доступен с уровня %', v_q.min_level;
    END IF;
    IF EXISTS (SELECT 1 FROM quest_prerequisites qp
                WHERE qp.quest_id = p_quest
                  AND NOT EXISTS (SELECT 1 FROM character_quests cq
                                   WHERE cq.character_id = p_character
                                     AND cq.quest_id = qp.requires_quest_id
                                     AND cq.status = 'completed')) THEN
        RAISE EXCEPTION 'Не выполнены предыдущие квесты цепочки';
    END IF;
    INSERT INTO character_quests (character_id, quest_id)
    VALUES (p_character, p_quest)
    ON CONFLICT (character_id, quest_id) DO UPDATE
       SET status = 'active', started_at = now(), finished_at = NULL
     WHERE v_q.is_repeatable AND character_quests.status <> 'active';
    INSERT INTO quest_progress (character_id, quest_id, objective_id, progress)
    SELECT p_character, p_quest, objective_id, 0 FROM quest_objectives WHERE quest_id = p_quest
    ON CONFLICT (character_id, objective_id) DO UPDATE SET progress = 0;
END $$;

-- Сдать квест: все цели выполнены → награды
CREATE OR REPLACE FUNCTION complete_quest(p_character bigint, p_quest integer)
RETURNS void
LANGUAGE plpgsql SET search_path = game, public AS $$
DECLARE
    v_q   quests%ROWTYPE;
    v_r   record;
BEGIN
    SELECT * INTO STRICT v_q FROM quests WHERE quest_id = p_quest;
    PERFORM 1 FROM character_quests
      WHERE character_id = p_character AND quest_id = p_quest AND status = 'active' FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Квест не активен';
    END IF;
    IF EXISTS (SELECT 1 FROM quest_objectives o
                 LEFT JOIN quest_progress p ON p.objective_id = o.objective_id AND p.character_id = p_character
                WHERE o.quest_id = p_quest AND coalesce(p.progress, 0) < o.required_count) THEN
        RAISE EXCEPTION 'Не все цели квеста выполнены';
    END IF;
    UPDATE character_quests SET status = 'completed', finished_at = now()
     WHERE character_id = p_character AND quest_id = p_quest;
    UPDATE characters
       SET experience = experience + v_q.xp_reward,
           credits = credits + v_q.credits_reward
     WHERE character_id = p_character;
    FOR v_r IN SELECT t.code, r.quantity FROM quest_reward_items r JOIN item_templates t USING (item_id)
                WHERE r.quest_id = p_quest LOOP
        PERFORM add_item(p_character, v_r.code, v_r.quantity);
    END LOOP;
    IF v_q.credits_reward > 0 THEN
        INSERT INTO transactions (character_id, kind, amount) VALUES (p_character, 'quest_reward', v_q.credits_reward);
    END IF;
END $$;

-- Начисление прогресса по цели (вызывается игровым сервером при событии)
CREATE OR REPLACE FUNCTION report_progress(p_character bigint, p_kind objective_kind_t, p_target text, p_amount integer DEFAULT 1)
RETURNS integer
LANGUAGE sql SET search_path = game, public AS $$
    WITH upd AS (
        UPDATE quest_progress p
           SET progress = least(o.required_count, p.progress + p_amount)
          FROM quest_objectives o, character_quests cq
         WHERE p.objective_id = o.objective_id
           AND p.character_id = p_character
           AND o.kind = p_kind AND o.target_code = p_target
           AND cq.character_id = p.character_id AND cq.quest_id = p.quest_id AND cq.status = 'active'
        RETURNING 1)
    SELECT count(*)::integer FROM upd;
$$;

-- ---------- Представления ----------
CREATE OR REPLACE VIEW v_character_sheet AS
SELECT c.character_id, c.name, cl.name AS class_name, c.level, c.experience,
       lt_next.xp_required AS next_level_xp, c.hp, c.max_hp, c.credits, l.name AS location,
       (SELECT jsonb_object_agg(a.code, ca.value)
          FROM character_attributes ca JOIN attributes a USING (attr_id)
         WHERE ca.character_id = c.character_id) AS attributes
  FROM characters c
  JOIN character_classes cl USING (class_id)
  JOIN locations l USING (location_id)
  LEFT JOIN level_thresholds lt_next ON lt_next.level = c.level + 1
 WHERE NOT c.is_deleted;
COMMENT ON VIEW v_character_sheet IS 'Карточка персонажа для клиента';

CREATE OR REPLACE VIEW v_inventory AS
SELECT i.character_id, i.slot_no, t.code, t.name, t.category, t.rarity, i.quantity,
       ii.upgrade_level, ii.durability, t.stats || coalesce(ii.rolled_stats, '{}'::jsonb) AS stats,
       e.slot AS equipped_in
  FROM inventory i
  JOIN item_templates t USING (item_id)
  LEFT JOIN item_instances ii ON ii.instance_id = i.instance_id
  LEFT JOIN equipment e ON e.instance_id = i.instance_id;
COMMENT ON VIEW v_inventory IS 'Инвентарь с итоговыми характеристиками предметов';

CREATE MATERIALIZED VIEW mv_leaderboard AS
SELECT c.character_id, c.name, cl.code AS class_code, c.level, c.experience,
       rank() OVER (ORDER BY c.experience DESC) AS global_rank,
       rank() OVER (PARTITION BY c.class_id ORDER BY c.experience DESC) AS class_rank
  FROM characters c JOIN character_classes cl USING (class_id)
 WHERE NOT c.is_deleted
WITH NO DATA;
COMMENT ON MATERIALIZED VIEW mv_leaderboard IS 'Таблица лидеров, обновляется по расписанию';
