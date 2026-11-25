#!/bin/sh
# Полная пересборка учебной БД: схема, функции, индексы, справочники, нагрузочные данные
P="/d/Tools/pgsql/bin/psql.exe -h 127.0.0.1 -p 5441 -U postgres -d rpg_vkr -v ON_ERROR_STOP=1 -q"
export PGCLIENTENCODING=UTF8
cd "$(dirname "$0")"
for f in sql/01_schema.sql sql/02_functions.sql sql/03_indexes.sql sql/04_seed.sql sql/05_loadtest.sql; do
  echo "== $f"; $P -f "$f" || exit 1
done
