## Зависимости

```bash
pip install psycopg2-binary faker
```

## Настройка

```bash
docker compose up -d
docker exec -i samokatka_db psql -U postgres -d samokatka < ../schema.sql
```

## Запуск

```bash
docker compose up -d
python generate_test_data.py
```
