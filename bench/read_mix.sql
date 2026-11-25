-- Смешанная нагрузка чтения: типичные запросы клиента во время игры
\set pid random(3, 10000)
\set cid random(1, 10000)
SET search_path TO game, public;
SELECT player_id, password_hash FROM players WHERE lower(login) = lower('player_' || :pid);
SELECT character_id, name, level FROM characters WHERE player_id = :pid AND NOT is_deleted;
SELECT slot_no, code, quantity, stats FROM v_inventory WHERE character_id = :cid ORDER BY slot_no;
SELECT q.name, o.description, p.progress FROM character_quests cq JOIN quests q USING (quest_id) JOIN quest_objectives o ON o.quest_id = cq.quest_id LEFT JOIN quest_progress p ON p.character_id = cq.character_id AND p.objective_id = o.objective_id WHERE cq.character_id = :cid AND cq.status = 'active';
SELECT created_at, kind, amount FROM transactions WHERE character_id = :cid ORDER BY created_at DESC LIMIT 20;
