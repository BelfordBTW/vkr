# -*- coding: utf-8 -*-
"""Нагрузочное тестирование БД: время запросов с индексами и без, сравнение
вариантов запроса, параллельная нагрузка pgbench, размеры таблиц.
Результат: bench/results.json"""
import json, os, re, subprocess, statistics, sys

BIN = r'D:\Tools\pgsql\bin'
for _a in sys.argv[1:]:                      # путь к bin PostgreSQL можно передать аргументом
    if os.path.isfile(os.path.join(_a, 'psql.exe')): BIN = _a
CONN = ['-h', '127.0.0.1', '-p', '5441', '-U', 'postgres', '-d', 'rpg_vkr']
HERE = os.path.dirname(os.path.abspath(__file__))
ENV = dict(os.environ, PGCLIENTENCODING='UTF8')
N = 25

def psql(sql, *extra):
    r = subprocess.run([os.path.join(BIN, 'psql.exe'), *CONN, '-v', 'ON_ERROR_STOP=1', '-At', *extra, '-c', sql],
                       capture_output=True, text=True, encoding='utf-8', env=ENV)
    if r.returncode:
        raise RuntimeError(r.stderr)
    return r.stdout.strip()

def psql_file(path):
    r = subprocess.run([os.path.join(BIN, 'psql.exe'), *CONN, '-v', 'ON_ERROR_STOP=1', '-q', '-f', path],
                       capture_output=True, text=True, encoding='utf-8', env=ENV)
    if r.returncode:
        raise RuntimeError(r.stderr)

QUERIES = {
    'Q1':  ('Авторизация игрока', "SELECT player_id, password_hash, is_banned FROM players WHERE lower(login) = lower('player_5000')"),
    'Q2':  ('Список персонажей игрока', "SELECT c.character_id, c.name, cl.name, c.level, l.name FROM characters c JOIN character_classes cl USING (class_id) JOIN locations l USING (location_id) WHERE c.player_id = 5000 AND NOT c.is_deleted ORDER BY c.created_at"),
    'Q3':  ('Инвентарь персонажа', "SELECT slot_no, code, name, category, rarity, quantity, upgrade_level, stats, equipped_in FROM v_inventory WHERE character_id = 5000 ORDER BY slot_no"),
    'Q4':  ('Владельцы предмета', "SELECT count(DISTINCT character_id), sum(quantity) FROM inventory WHERE item_id = 30"),
    'Q5':  ('Поиск предметов по критериям', "SELECT code, name, rarity, level_req, base_price FROM item_templates WHERE category = 'weapon' AND rarity IN ('rare','epic') AND level_req <= 10 ORDER BY level_req DESC, base_price"),
    'Q6':  ('Поиск по свойствам JSONB', "SELECT code, name, stats FROM item_templates WHERE stats @> '{\"emp\": true}'"),
    'Q7':  ('Экипировка персонажа', "SELECT i.instance_id, t.name, t.rarity, i.upgrade_level, i.durability FROM item_instances i JOIN item_templates t USING (item_id) WHERE i.owner_id = 5000 ORDER BY i.upgrade_level DESC, t.rarity DESC"),
    'Q8':  ('Доступные квесты', """SELECT q.quest_id, q.name FROM quests q JOIN characters c ON c.character_id = 5000 WHERE q.min_level <= c.level
          AND NOT EXISTS (SELECT 1 FROM character_quests cq WHERE cq.character_id = c.character_id AND cq.quest_id = q.quest_id AND (cq.status = 'active' OR NOT q.is_repeatable))
          AND NOT EXISTS (SELECT 1 FROM quest_prerequisites qp WHERE qp.quest_id = q.quest_id AND NOT EXISTS (SELECT 1 FROM character_quests d WHERE d.character_id = c.character_id AND d.quest_id = qp.requires_quest_id AND d.status = 'completed'))
          ORDER BY q.is_main DESC, q.min_level"""),
    'Q9':  ('Активные квесты с прогрессом', "SELECT q.name, o.description, p.progress, o.required_count FROM character_quests cq JOIN quests q USING (quest_id) JOIN quest_objectives o ON o.quest_id = cq.quest_id LEFT JOIN quest_progress p ON p.character_id = cq.character_id AND p.objective_id = o.objective_id WHERE cq.character_id = 5000 AND cq.status = 'active' ORDER BY q.quest_id, o.ord"),
    'Q10': ('Таблица лидеров класса', "SELECT name, level, experience, rank() OVER (ORDER BY experience DESC) FROM characters WHERE class_id = 2 AND NOT is_deleted ORDER BY experience DESC LIMIT 10"),
    'Q11': ('История операций персонажа', "SELECT created_at, kind, amount FROM transactions WHERE character_id = 5000 AND created_at > now() - interval '30 days' ORDER BY created_at DESC LIMIT 50"),
    'Q12': ('Оборот экономики за неделю', "SELECT date_trunc('day', created_at), kind, count(*), sum(amount) FROM transactions WHERE created_at > now() - interval '7 days' GROUP BY 1, 2 ORDER BY 1, 2"),
    'Q13': ('Ближайшие локации', "SELECT code, name FROM locations ORDER BY pos <-> point(50, 30) LIMIT 3"),
    'Q14': ('Последние сессии игрока', "SELECT started_at, ended_at - started_at, client_version FROM sessions WHERE player_id = 5000 ORDER BY started_at DESC LIMIT 10"),
    'Q15': ('Статистика экипировки по редкости', "SELECT t.rarity, count(*), avg(i.upgrade_level) FROM item_instances i JOIN item_templates t USING (item_id) GROUP BY t.rarity"),
}

VARIANTS = {
    'NOT EXISTS': "SELECT q.quest_id FROM quests q WHERE q.min_level <= 20 AND NOT EXISTS (SELECT 1 FROM character_quests cq WHERE cq.character_id = 5000 AND cq.quest_id = q.quest_id)",
    'NOT IN': "SELECT q.quest_id FROM quests q WHERE q.min_level <= 20 AND q.quest_id NOT IN (SELECT cq.quest_id FROM character_quests cq WHERE cq.character_id = 5000)",
    'LEFT JOIN / IS NULL': "SELECT q.quest_id FROM quests q LEFT JOIN character_quests cq ON cq.quest_id = q.quest_id AND cq.character_id = 5000 WHERE q.min_level <= 20 AND cq.quest_id IS NULL",
    'EXCEPT': "SELECT quest_id FROM quests WHERE min_level <= 20 EXCEPT SELECT quest_id FROM character_quests WHERE character_id = 5000",
}
VARIANTS2 = {
    'Подзапрос в SELECT': "SELECT c.character_id, (SELECT count(*) FROM inventory i WHERE i.character_id = c.character_id) FROM characters c WHERE c.class_id = 1",
    'JOIN + GROUP BY': "SELECT c.character_id, count(i.slot_no) FROM characters c LEFT JOIN inventory i USING (character_id) WHERE c.class_id = 1 GROUP BY c.character_id",
    'LATERAL': "SELECT c.character_id, x.n FROM characters c CROSS JOIN LATERAL (SELECT count(*) AS n FROM inventory i WHERE i.character_id = c.character_id) x WHERE c.class_id = 1",
}

BENCH_FN = r"""
CREATE OR REPLACE FUNCTION public.bench_query(q text, n int)
RETURNS TABLE (med numeric, mn numeric, mx numeric, plan_total numeric, nodes text, rows bigint)
LANGUAGE plpgsql AS $$
DECLARE j json; t numeric[] := '{}'; i int;
BEGIN
  SET LOCAL search_path TO game, public;
  EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || q INTO j;           -- прогрев кэша
  FOR i IN 1..n LOOP
    EXECUTE 'EXPLAIN (ANALYZE, FORMAT JSON) ' || q INTO j;
    t := t || (j->0->>'Execution Time')::numeric;
  END LOOP;
  SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY x), min(x), max(x) INTO med, mn, mx FROM unnest(t) x;
  plan_total := (j->0->'Plan'->>'Total Cost')::numeric;
  rows := round((j->0->'Plan'->>'Actual Rows')::numeric)::bigint;
  SELECT string_agg(DISTINCT m[1] || coalesce(' ' || m[2], ''), '; ')
    INTO nodes
    FROM regexp_matches(j::text, '"Node Type": "((?:Index Only Scan|Index Scan|Bitmap Index Scan|Seq Scan))"(?:, "Parallel Aware": \w+, "Async Capable": \w+, "Scan Direction": "\w+")?(?:, "Index Name": "(\w+)")?', 'g') m;
  RETURN NEXT;
END $$;
"""

INDEX_NAMES = re.findall(r'CREATE (?:UNIQUE )?INDEX (\w+)', open(os.path.join(HERE, '..', 'sql', '03_indexes.sql'), encoding='utf-8').read())

def run_queries(qs, n=N):
    out = {}
    for k, (title, sql) in qs.items():
        r = psql(f"SELECT * FROM public.bench_query($q${sql}$q$, {n})").split('|')
        out[k] = {'title': title, 'median_ms': float(r[0]), 'min_ms': float(r[1]), 'max_ms': float(r[2]),
                  'cost': float(r[3]), 'nodes': r[4], 'rows': int(r[5] or 0)}
        print(f"  {k:4} {title:38} {float(r[0]):9.3f} ms   {r[4][:70]}", flush=True)
    return out

def pgbench(script, clients, seconds=10):
    path = os.path.join(HERE, script)
    r = subprocess.run([os.path.join(BIN, 'pgbench.exe'), *CONN, '-n', '-f', path, '-c', str(clients), '-j', str(min(clients, 8)),
                        '-T', str(seconds), '-r'], capture_output=True, text=True, encoding='utf-8', env=ENV)
    txt = r.stdout + r.stderr
    tps = float(re.search(r'tps = ([\d.]+)', txt).group(1))
    lat = float(re.search(r'latency average = ([\d.]+) ms', txt).group(1))
    failed = re.search(r'number of failed transactions: (\d+)', txt)
    return {'clients': clients, 'tps': tps, 'latency_ms': lat, 'failed': int(failed.group(1)) if failed else 0, 'raw': txt[-1500:]}

def sizes():
    rows = psql("""SELECT c.relname, pg_relation_size(c.oid), pg_indexes_size(c.oid), c.reltuples::bigint
                     FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
                    WHERE n.nspname = 'game' AND c.relkind = 'r' ORDER BY pg_total_relation_size(c.oid) DESC LIMIT 10""")
    return [dict(zip(['table', 'data_bytes', 'index_bytes', 'rows'], [x.split('|')[0]] + [int(v) for v in x.split('|')[1:]])) for x in rows.splitlines()]

def main():
    res = {}
    psql(BENCH_FN)
    psql('ANALYZE')
    print('== С индексами')
    res['with_indexes'] = run_queries(QUERIES)
    res['variants_not_taken'] = run_queries({k: (k, v) for k, v in VARIANTS.items()})
    res['variants_count'] = run_queries({k: (k, v) for k, v in VARIANTS2.items()})
    res['sizes_with'] = sizes()
    res['db_size_with'] = int(psql("SELECT pg_database_size('rpg_vkr')"))
    print('== pgbench (чтение)')
    res['pgbench_read'] = [pgbench('read_mix.sql', c) for c in (1, 4, 16, 32)]
    for x in res['pgbench_read']: print('  ', x['clients'], x['tps'], x['latency_ms'])
    print('== pgbench (запись: передача предметов и покупки)')
    res['pgbench_write'] = [pgbench('write_mix.sql', c) for c in (1, 4, 16, 32)]
    for x in res['pgbench_write']: print('  ', x['clients'], x['tps'], x['latency_ms'], 'failed', x['failed'])
    print('== Без индексов из 03_indexes.sql:', len(INDEX_NAMES))
    psql('SET search_path TO game; ' + ' '.join(f'DROP INDEX IF EXISTS game.{n};' for n in INDEX_NAMES))
    psql('ANALYZE')
    res['without_indexes'] = run_queries(QUERIES)
    res['db_size_without'] = int(psql("SELECT pg_database_size('rpg_vkr')"))
    res['pgbench_read_noidx'] = [pgbench('read_mix.sql', c) for c in (1, 16)]
    for x in res['pgbench_read_noidx']: print('  noidx', x['clients'], x['tps'], x['latency_ms'])
    psql_file(os.path.join(HERE, '..', 'sql', '03_indexes.sql'))
    psql('REFRESH MATERIALIZED VIEW game.mv_leaderboard; ANALYZE')
    res['index_names'] = INDEX_NAMES
    res['pg_version'] = psql('SHOW server_version')
    json.dump(res, open(os.path.join(HERE, 'results.json'), 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print('saved results.json')

if __name__ == '__main__':
    main()
