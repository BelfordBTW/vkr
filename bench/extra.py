# -*- coding: utf-8 -*-
"""Дополнительные эксперименты по оптимизации (п. 3.3)"""
import json, os, subprocess
from bench import psql, pgbench, run_queries, QUERIES, BIN, CONN, ENV
res = {}
q12 = {'Q12': QUERIES['Q12']}
res['q12_base'] = run_queries(q12)
# 1. BRIN эффективен только при физической упорядоченности по времени: кластеризуем копию
psql("SET search_path TO game; DROP TABLE IF EXISTS tx_sorted; CREATE TABLE tx_sorted AS SELECT * FROM transactions ORDER BY created_at; CREATE INDEX tx_sorted_brin ON tx_sorted USING brin (created_at); ANALYZE tx_sorted")
res['q12_brin_sorted'] = run_queries({'Q12': ('BRIN на упорядоченной таблице', QUERIES['Q12'][1].replace('FROM transactions', 'FROM tx_sorted'))})
psql("DROP TABLE game.tx_sorted")
# 2. B-tree по времени
psql("CREATE INDEX ix_tmp_tx_time ON game.transactions (created_at); ANALYZE game.transactions")
res['q12_btree'] = run_queries({'Q12': ('B-tree по created_at', QUERIES['Q12'][1])})
psql("DROP INDEX game.ix_tmp_tx_time")
# 3. Материализованное представление дневных итогов
psql("""SET search_path TO game; DROP MATERIALIZED VIEW IF EXISTS mv_daily_economy;
CREATE MATERIALIZED VIEW mv_daily_economy AS SELECT date_trunc('day', created_at) AS day, kind, count(*) AS ops, sum(amount) AS balance FROM transactions GROUP BY 1, 2;
CREATE INDEX ON mv_daily_economy (day); ANALYZE mv_daily_economy""")
res['q12_mv'] = run_queries({'Q12': ('Материализованное представление', "SELECT day, kind, ops, balance FROM mv_daily_economy WHERE day > now() - interval '7 days' ORDER BY 1, 2")})
res['mv_refresh_ms'] = run_queries({'R': ('REFRESH', "SELECT 1")}, 1)  # заглушка для формата
import time
t = time.time(); psql("REFRESH MATERIALIZED VIEW game.mv_daily_economy"); res['mv_refresh_wall_ms'] = (time.time() - t) * 1000
# 4. Асинхронная фиксация транзакций для записи
env = dict(ENV, PGOPTIONS='-c synchronous_commit=off')
import bench
bench.ENV = env
res['write_async'] = [pgbench('write_mix.sql', c) for c in (1, 4, 16, 32)]
for x in res['write_async']: print('  async', x['clients'], x['tps'], x['latency_ms'], x['failed'])
bench.ENV = ENV
res['fsync_test'] = psql("SELECT current_setting('wal_sync_method')")
json.dump(res, open('results_extra.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
