-- Tic Tac Toe Database Schema (PostgreSQL)
-- Tables: players, games, moves, game_history
-- Designed for persistent multiplayer turn-based matches, profiles, and game history

-- Players Table: Stores player profiles
CREATE TABLE IF NOT EXISTS players (
    id SERIAL PRIMARY KEY,
    username VARCHAR(32) UNIQUE NOT NULL,
    display_name VARCHAR(64),
    email VARCHAR(100) UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP WITH TIME ZONE,
    stats JSONB DEFAULT '{}' -- For stats like win/loss count (optional)
);

-- Games Table: Stores Tic Tac Toe matches (active & completed)
CREATE TABLE IF NOT EXISTS games (
    id SERIAL PRIMARY KEY,
    player_x_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    player_o_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_move_at TIMESTAMP WITH TIME ZONE,
    status VARCHAR(16) NOT NULL DEFAULT 'ongoing', -- 'ongoing', 'finished'
    winner_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    current_turn CHAR(1) NOT NULL DEFAULT 'X', -- 'X' or 'O'
    board_state CHAR(9) NOT NULL DEFAULT '         ', -- 3x3 flat as 9 chars (e.g., "XO X  O  ")
    CONSTRAINT player_distinct CHECK (player_x_id IS NULL OR player_o_id IS NULL OR player_x_id != player_o_id)
);

-- Moves Table: Move history for each game (chronological)
CREATE TABLE IF NOT EXISTS moves (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    move_index SMALLINT NOT NULL, -- 0-8 (0=top-left, 8=bottom-right)
    move_number SMALLINT NOT NULL, -- incrementing, 1=first move
    symbol CHAR(1) NOT NULL, -- 'X' or 'O'
    made_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (game_id, move_number),
    UNIQUE (game_id, move_index)
);

-- Game History Table: Summary of completed games
CREATE TABLE IF NOT EXISTS game_history (
    id SERIAL PRIMARY KEY,
    game_id INTEGER NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_x_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    player_o_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    winner_id INTEGER REFERENCES players(id) ON DELETE SET NULL,
    final_board CHAR(9) NOT NULL,
    total_moves SMALLINT NOT NULL,
    outcome VARCHAR(12) NOT NULL -- 'draw', 'x_win', 'o_win', etc.
);

-- Indexes for quick lookup
CREATE INDEX IF NOT EXISTS idx_moves_game_id ON moves(game_id);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);

-- Sample Players
INSERT INTO players (username, display_name, email) VALUES
    ('alice', 'Alice', 'alice@example.com'),
    ('bob', 'Bob', 'bob@example.com'),
    ('guest', 'Guest', NULL)
ON CONFLICT (username) DO NOTHING;

-- Sample Games & Moves
-- Create an example finished game between Alice and Bob
INSERT INTO games (player_x_id, player_o_id, status, winner_id, current_turn, board_state, last_move_at)
SELECT
    px.id, po.id, 'finished', px.id, 'X', 'XOXOX    ', NOW()
FROM players px, players po
WHERE px.username = 'alice' AND po.username = 'bob'
ON CONFLICT DO NOTHING;

-- Use CTE to get the sample game & player IDs for seeding moves & history
WITH gx AS (
    SELECT g.id AS game_id, px.id AS player_x_id, po.id AS player_o_id
    FROM games g
    JOIN players px ON g.player_x_id = px.id
    JOIN players po ON g.player_o_id = po.id
    WHERE px.username = 'alice' AND po.username = 'bob'
    ORDER BY g.id DESC LIMIT 1
)
INSERT INTO moves (game_id, player_id, move_index, move_number, symbol)
SELECT gx.game_id, gx.player_x_id, 0, 1, 'X' FROM gx
UNION ALL SELECT gx.game_id, gx.player_o_id, 1, 2, 'O' FROM gx
UNION ALL SELECT gx.game_id, gx.player_x_id, 2, 3, 'X' FROM gx
UNION ALL SELECT gx.game_id, gx.player_o_id, 4, 4, 'O' FROM gx
UNION ALL SELECT gx.game_id, gx.player_x_id, 5, 5, 'X' FROM gx
ON CONFLICT DO NOTHING;

-- Seed game_history for above match
INSERT INTO game_history (game_id, player_x_id, player_o_id, started_at, ended_at, winner_id, final_board, total_moves, outcome)
SELECT
    gx.game_id, gx.player_x_id, gx.player_o_id,
    NOW() - interval '5 minutes', NOW(),
    gx.player_x_id, 'XOXOX    ', 5, 'x_win'
FROM gx
ON CONFLICT DO NOTHING;

-- The database is now ready for use by the Tic Tac Toe backend.
-- See backend code for migration strategy if schema changes are required in the future.
