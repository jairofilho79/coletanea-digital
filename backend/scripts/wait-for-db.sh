#!/bin/sh
# Wait for PostgreSQL to be ready

set -e

host="$1"
shift
cmd="$@"

# Use POSTGRES_DB environment variable, default to coletanea_db
db_name="${POSTGRES_DB:-coletanea_db}"
user="${POSTGRES_USER:-coletanea_user}"
password="${POSTGRES_PASSWORD:-coletanea_password}"

echo "⏳ Aguardando PostgreSQL em ${host}..."
echo "   Database: ${db_name}"
echo "   User: ${user}"

# First, wait for PostgreSQL to be ready using pg_isready
until pg_isready -h "$host" -U "$user" > /dev/null 2>&1; do
  >&2 echo "   PostgreSQL ainda não está pronto - aguardando..."
  sleep 1
done

# Then, verify we can connect to the specific database
until PGPASSWORD="$password" psql -h "$host" -U "$user" -d "$db_name" -c '\q' > /dev/null 2>&1; do
  >&2 echo "   Banco de dados ${db_name} ainda não está disponível - aguardando..."
  sleep 1
done

>&2 echo "✅ PostgreSQL está pronto!"
exec $cmd
