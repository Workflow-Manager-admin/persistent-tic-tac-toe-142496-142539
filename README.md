# persistent-tic-tac-toe-142496-142539

## Tic Tac Toe Database - PostgreSQL

- The database schema and seed data are provided at:
  - `tic_tac_toe_database/schema.sql`

### Usage

1. Ensure PostgreSQL is running with the settings in `db_visualizer/postgres.env` or as created by `startup.sh`.
2. Apply the schema and seed data:
   ```
   psql -h localhost -U <DB_USER> -d <DB_NAME> -p <DB_PORT> -f tic_tac_toe_database/schema.sql
   ```
   Replace `<DB_USER>`, `<DB_NAME>`, and `<DB_PORT>` with the actual values from your environment or `db_connection.txt`.

- The schema includes tables for players, games, moves, and game history.
- Suitable for persistent, turn-based, multiplayer Tic Tac Toe with user profiles and match tracking.
