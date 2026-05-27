# MySQL to PostgreSQL Migration

This project is now configured to use PostgreSQL by default through the `DB_*` environment variables in `.env`.

## 1. Back up the current MySQL database

Run this before changing production configuration:

```bash
mysqldump --single-transaction --routines --triggers --default-character-set=utf8mb4 \
  -u <mysql_user> -p <mysql_database> > mysql_backup.sql
```

Keep this file until the PostgreSQL migration has been verified.

## 2. Export Django data from the current MySQL-backed app

While the app is still pointed at MySQL, create a Django fixture:

```bash
python manage.py dumpdata \
  --natural-foreign --natural-primary \
  --exclude contenttypes --exclude auth.permission \
  --indent 2 > mysql_data.json
```

This preserves application data in a database-neutral format and avoids loading duplicated Django permission/content-type rows into PostgreSQL.

## 3. Create the PostgreSQL database

```sql
CREATE DATABASE jr_system;
CREATE USER jr_system_user WITH PASSWORD 'change_this_password';
GRANT ALL PRIVILEGES ON DATABASE jr_system TO jr_system_user;
```

## 4. Configure `.env` for PostgreSQL

```env
DB_ENGINE=postgresql
DB_NAME=jr_system
DB_USER=jr_system_user
DB_PASSWORD=change_this_password
DB_HOST=localhost
DB_PORT=5432
```

You can also use `DATABASE_URL=postgresql://jr_system_user:change_this_password@localhost:5432/jr_system`.

## 5. Install dependencies and apply schema

```bash
pip install -r requirements.txt
python manage.py migrate
```

## 6. Load the preserved data

```bash
python manage.py loaddata mysql_data.json
```

## 7. Verify the migration

```bash
python manage.py check
python manage.py shell
```

In the shell, verify important row counts:

```python
from register.models import user_detail, Employee, Job, application
print(user_detail.objects.count(), Employee.objects.count(), Job.objects.count(), application.objects.count())
```

Also verify login, candidate registration, job listing, applications, MCQ results, machine-test submissions, interview records, and uploaded media links.

## Notes

- Do not delete the MySQL database or `mysql_backup.sql` until PostgreSQL has been tested.
- Uploaded files in `media/` are not stored inside the database; keep the `media/` directory when moving servers.
- If the old MySQL database has invalid dates, zero dates, or non-UTF-8 text, fix those rows before running `dumpdata`.
