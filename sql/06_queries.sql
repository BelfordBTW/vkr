-- =====================================================================
-- Файл 6. Запросы для основных игровых операций
-- Параметры обозначены как :name (переменные psql)
-- =====================================================================
SET search_path TO game, public;

-- Q1. Авторизация игрока (уникальный индекс по lower(login))
SELECT player_id, password_hash, is_banned
  FROM players
 WHERE lower(login) = lower(:'login');

-- Q2. Список персонажей игрока для экрана выбора
SELECT c.character_id, c.name, cl.name AS class_name, c.level, l.name AS location
  FROM characters c
  JOIN character_classes cl USING (class_id)
  JOIN locations l USING (location_id)
 WHERE c.player_id = :player AND NOT c.is_deleted
 ORDER BY c.created_at;

-- Q3. Инвентарь персонажа с итоговыми характеристиками предметов
SELECT slot_no, code, name, category, rarity, quantity, upgrade_level, stats, equipped_in
  FROM v_inventory
 WHERE character_id = :character
 ORDER BY slot_no;

-- Q4. Сколько персонажей владеют предметом (аналитика баланса)
SELECT count(DISTINCT character_id) AS owners, sum(quantity) AS total
  FROM inventory
 WHERE item_id = :item;

-- Q5. Поиск предметов по критериям (тип, редкость, уровень)
SELECT code, name, rarity, level_req, base_price
  FROM item_templates
 WHERE category = 'weapon' AND rarity IN ('rare', 'epic') AND level_req <= :level
 ORDER BY level_req DESC, base_price;

-- Q6. Поиск по свойствам в JSONB: предметы с ЭМИ-эффектом
SELECT code, name, stats
  FROM item_templates
 WHERE stats @> '{"emp": true}';

-- Q7. Экипировка персонажа, отсортированная по уровню улучшения
SELECT i.instance_id, t.name, t.rarity, i.upgrade_level, i.durability
  FROM item_instances i
  JOIN item_templates t USING (item_id)
 WHERE i.owner_id = :character
 ORDER BY i.upgrade_level DESC, t.rarity DESC;

-- Q8. Доступные квесты: уровень подходит, квест не взят, цепочка выполнена
SELECT q.quest_id, q.name, q.min_level, n.name AS giver
  FROM quests q
  JOIN characters c ON c.character_id = :character
  LEFT JOIN npcs n ON n.npc_id = q.giver_npc_id
 WHERE q.min_level <= c.level
   AND NOT EXISTS (SELECT 1 FROM character_quests cq
                    WHERE cq.character_id = c.character_id AND cq.quest_id = q.quest_id
                      AND (cq.status = 'active' OR NOT q.is_repeatable))
   AND NOT EXISTS (SELECT 1 FROM quest_prerequisites qp
                    WHERE qp.quest_id = q.quest_id
                      AND NOT EXISTS (SELECT 1 FROM character_quests d
                                       WHERE d.character_id = c.character_id
                                         AND d.quest_id = qp.requires_quest_id
                                         AND d.status = 'completed'))
 ORDER BY q.is_main DESC, q.min_level;

-- Q9. Активные квесты с прогрессом по целям
SELECT q.name, o.description, p.progress, o.required_count,
       round(100.0 * p.progress / o.required_count) AS pct
  FROM character_quests cq
  JOIN quests q USING (quest_id)
  JOIN quest_objectives o ON o.quest_id = cq.quest_id
  LEFT JOIN quest_progress p ON p.character_id = cq.character_id AND p.objective_id = o.objective_id
 WHERE cq.character_id = :character AND cq.status = 'active'
 ORDER BY q.quest_id, o.ord;

-- Q10. Таблица лидеров класса (оконная функция)
SELECT name, level, experience,
       rank() OVER (ORDER BY experience DESC) AS place
  FROM characters
 WHERE class_id = :class AND NOT is_deleted
 ORDER BY experience DESC
 LIMIT 10;

-- Q11. История операций персонажа за 30 дней
SELECT created_at, kind, amount, item_id, quantity
  FROM transactions
 WHERE character_id = :character AND created_at > now() - interval '30 days'
 ORDER BY created_at DESC
 LIMIT 50;

-- Q12. Экономика: оборот по дням и типам операций за неделю
SELECT date_trunc('day', created_at) AS day, kind,
       count(*) AS ops, sum(amount) AS balance
  FROM transactions
 WHERE created_at > now() - interval '7 days'
 GROUP BY 1, 2
 ORDER BY 1, 2;

-- Q13. Ближайшие к точке локации (геоданные, индекс GiST)
SELECT code, name, pos <-> point(:x, :y) AS dist
  FROM locations
 ORDER BY pos <-> point(:x, :y)
 LIMIT 3;

-- Q14. Последние сессии игрока (мониторинг)
SELECT started_at, ended_at - started_at AS duration, client_version
  FROM sessions
 WHERE player_id = :player
 ORDER BY started_at DESC
 LIMIT 10;

-- Q15. Средний уровень улучшения экипировки по редкости (агрегаты)
SELECT t.rarity, count(*) AS items, round(avg(i.upgrade_level), 2) AS avg_upgrade,
       percentile_cont(0.9) WITHIN GROUP (ORDER BY i.durability) AS p90_durability
  FROM item_instances i JOIN item_templates t USING (item_id)
 GROUP BY t.rarity
 ORDER BY t.rarity;

-- ---------- Транзакционные операции ----------

-- T1. Передача предмета (процедура блокирует строки в фиксированном порядке)
BEGIN;
CALL transfer_item(:from_char, :to_char, :slot::smallint, 1);
COMMIT;

-- T2. Та же операция «вручную»: при ошибке — откат всех изменений
BEGIN;
SELECT 1 FROM characters WHERE character_id IN (:from_char, :to_char) ORDER BY character_id FOR UPDATE;
SELECT quantity FROM inventory WHERE character_id = :from_char AND slot_no = :slot FOR UPDATE;
UPDATE inventory SET quantity = quantity - 1 WHERE character_id = :from_char AND slot_no = :slot AND quantity > 1;
-- если UPDATE не изменил ни одной строки, приложение выполняет ROLLBACK
SELECT add_item(:to_char, :item_code, 1);
COMMIT;

-- T3. Покупка у торговца: списание кредитов, уменьшение склада, выдача, запись в журнал
SELECT buy_item(:character, :npc, :item_code, 1);
