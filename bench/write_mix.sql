-- Смешанная нагрузка записи: передача стека расходников и покупка у торговца.
-- Персонажи выбираются случайно, поэтому возможны конкурирующие блокировки.
\set a random(3, 10000)
\set b random(3, 10000)
SET search_path TO game, public;
BEGIN;
SELECT 1 FROM characters WHERE character_id IN (:a, :b) ORDER BY character_id FOR UPDATE;
UPDATE inventory SET quantity = quantity - 1 WHERE character_id = :a AND slot_no = 2 AND quantity > 1;
UPDATE inventory SET quantity = least(quantity + 1, 20) WHERE character_id = :b AND slot_no = 2;
INSERT INTO item_transfers (from_character, to_character, item_id, quantity) SELECT :a, :b, item_id, 1 FROM inventory WHERE character_id = :a AND slot_no = 2 AND :a <> :b;
UPDATE characters SET credits = credits + 5 WHERE character_id = :b;
INSERT INTO transactions (character_id, kind, amount) VALUES (:b, 'trade', 5);
COMMIT;
