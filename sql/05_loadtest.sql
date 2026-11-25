-- =====================================================================
-- Файл 5. Генерация тестового набора данных для нагрузочного тестирования
-- 10 000 игроков и персонажей, 100 000 экземпляров предметов,
-- 50 000 записей инвентаря, 40 000 записей журнала квестов,
-- 200 000 экономических транзакций, 30 000 сессий.
-- =====================================================================
SET search_path TO game, public;
SELECT setseed(0.42);
BEGIN;

INSERT INTO players (login, email, password_hash, region, created_at, last_login_at)
SELECT 'player_' || g, 'player' || g || '@example.com', md5('pw' || g),
       (ARRAY['RU','KZ','BY','UZ','AM'])[1 + (g % 5)],
       now() - (30 + g % 365) * interval '1 day',
       now() - (g % 30) * interval '1 day'
  FROM generate_series(1, 10000) g;

INSERT INTO characters (player_id, class_id, name, experience, hp, max_hp, credits, location_id, created_at)
SELECT p.player_id,
       1 + (p.player_id % 4),
       'Hero_' || p.player_id,
       floor(power(random(), 2) * 120000)::bigint,
       5, 5,
       floor(random() * 20000)::bigint,
       1 + (p.player_id % 12),
       p.created_at
  FROM players p
 WHERE p.login LIKE 'player\_%';

INSERT INTO character_attributes (character_id, attr_id, value)
SELECT c.character_id, b.attr_id, b.value + (c.level / 5)
  FROM characters c JOIN class_base_attributes b ON b.class_id = c.class_id
ON CONFLICT DO NOTHING;

-- 100 000 экземпляров экипировки, распределённых по персонажам
INSERT INTO item_instances (item_id, owner_id, durability, upgrade_level, rolled_stats, created_at)
SELECT t.item_id,
       c.character_id,
       20 + floor(random() * 81)::int,
       floor(power(random(), 3) * 16)::int,
       jsonb_build_object('bonus', floor(random() * 5)::int),
       now() - floor(random() * 300) * interval '1 day'
  FROM generate_series(1, 100000) g
  JOIN LATERAL (SELECT item_id FROM item_templates
                 WHERE category IN ('weapon', 'armor', 'implant')
                 ORDER BY item_id OFFSET (g % 28) LIMIT 1) t ON true
  JOIN characters c ON c.character_id = 1 + (g * 7919) % (SELECT max(character_id) FROM characters);

ANALYZE players; ANALYZE characters; ANALYZE item_instances;   -- статистика для планировщика внутри транзакции

-- 50 000 записей инвентаря: по 5 ячеек на персонажа (часть — экипировка, часть — стеки)
INSERT INTO inventory (character_id, slot_no, item_id, instance_id, quantity)
SELECT c.character_id, s.slot,
       CASE WHEN s.slot < 2 THEN ii.item_id ELSE st.item_id END,
       CASE WHEN s.slot < 2 THEN ii.instance_id END,
       CASE WHEN s.slot < 2 THEN 1 ELSE 1 + floor(random() * least(st.max_stack, 20))::int END
  FROM characters c
 CROSS JOIN generate_series(0, 4) AS s(slot)
  LEFT JOIN LATERAL (SELECT i.instance_id, i.item_id FROM item_instances i
                      WHERE i.owner_id = c.character_id ORDER BY i.instance_id OFFSET s.slot LIMIT 1) ii ON s.slot < 2
  LEFT JOIN LATERAL (SELECT item_id, max_stack FROM item_templates
                      WHERE category IN ('consumable', 'material')
                      ORDER BY item_id OFFSET ((c.character_id + s.slot * 3) % 20) LIMIT 1) st ON s.slot >= 2
 WHERE c.player_id > 2
   AND (s.slot >= 2 OR ii.instance_id IS NOT NULL);

ANALYZE inventory;

-- Журнал квестов: ~4 квеста на персонажа
INSERT INTO character_quests (character_id, quest_id, status, started_at, finished_at)
SELECT c.character_id, q.quest_id,
       CASE WHEN q.quest_id <= 3 + (c.character_id % 5) THEN 'completed'::quest_status_t ELSE 'active' END,
       now() - interval '10 days',
       CASE WHEN q.quest_id <= 3 + (c.character_id % 5) THEN now() - interval '5 days' END
  FROM characters c
  JOIN quests q ON q.quest_id <= 4 + (c.character_id % 3)
 WHERE c.player_id > 2
ON CONFLICT DO NOTHING;

INSERT INTO quest_progress (character_id, quest_id, objective_id, progress)
SELECT cq.character_id, cq.quest_id, o.objective_id, floor(random() * o.required_count)::int
  FROM character_quests cq JOIN quest_objectives o USING (quest_id)
 WHERE cq.status = 'active'
ON CONFLICT DO NOTHING;

INSERT INTO character_skills (character_id, skill_id, rank)
SELECT c.character_id, s.skill_id, 1 + floor(random() * s.max_rank)::int
  FROM characters c JOIN skills s ON (s.class_id = c.class_id OR s.class_id IS NULL) AND s.level_req <= c.level
 WHERE random() < 0.5;

INSERT INTO transactions (character_id, kind, amount, item_id, quantity, created_at)
SELECT 1 + floor(random() * 10000)::int,
       (ARRAY['buy','sell','loot','quest_reward','repair']::tx_kind_t[])[1 + floor(random() * 5)::int],
       floor(random() * 2000)::int - 1000,
       1 + floor(random() * 56)::int,
       1 + floor(random() * 5)::int,
       now() - random() * interval '90 days'
  FROM generate_series(1, 200000);

INSERT INTO sessions (player_id, started_at, ended_at, ip, client_version)
SELECT 1 + floor(random() * 10000)::int, t, t + random() * interval '2 hours',
       ('10.' || floor(random() * 255) || '.' || floor(random() * 255) || '.' || floor(random() * 255))::inet,
       (ARRAY['0.9.0', '1.0.0'])[1 + floor(random() * 2)::int]
  FROM (SELECT now() - random() * interval '60 days' AS t FROM generate_series(1, 30000)) s;

COMMIT;
REFRESH MATERIALIZED VIEW mv_leaderboard;
ANALYZE;
