--CREATE DATABASE music_streaming_db;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_database
        WHERE datname = 'music_streaming_db'
    ) THEN
        EXECUTE 'CREATE DATABASE music_streaming_db';
    END IF;
END $$;

CREATE SCHEMA IF NOT EXISTS music_streaming;

-- PART 2: CREATE TABLE

CREATE TABLE IF NOT EXISTS music_streaming.users (
    user_id SERIAL PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    full_name VARCHAR(150)
    GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED,

    email VARCHAR(120) NOT NULL UNIQUE,

    gender VARCHAR(10) NOT NULL,

    birth_date DATE,

    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS music_streaming.artists (
    artist_id SERIAL PRIMARY KEY,

    stage_name VARCHAR(100) NOT NULL UNIQUE,

    country VARCHAR(80) NOT NULL,

    debut_year INT NOT NULL
);

CREATE TABLE IF NOT EXISTS music_streaming.genres (
    genre_id SERIAL PRIMARY KEY,

    genre_name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS music_streaming.albums (
    album_id SERIAL PRIMARY KEY,

    artist_id INT NOT NULL
    REFERENCES music_streaming.artists(artist_id)
    ON DELETE CASCADE,

    genre_id INT NOT NULL
    REFERENCES music_streaming.genres(genre_id)
    ON DELETE RESTRICT,

    title VARCHAR(120) NOT NULL UNIQUE,

    release_date DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS music_streaming.songs (
    song_id SERIAL PRIMARY KEY,

    album_id INT NOT NULL
    REFERENCES music_streaming.albums(album_id)
    ON DELETE CASCADE,

    title VARCHAR(120) NOT NULL,

    duration_seconds INT NOT NULL,

    play_count INT DEFAULT 0,

    is_explicit BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS music_streaming.playlists (
    playlist_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL
    REFERENCES music_streaming.users(user_id)
    ON DELETE CASCADE,

    playlist_name VARCHAR(120) NOT NULL,

    created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS music_streaming.playlist_song (
    playlist_song_id SERIAL PRIMARY KEY,

    playlist_id INT NOT NULL
    REFERENCES music_streaming.playlists(playlist_id)
    ON DELETE CASCADE,

    song_id INT NOT NULL
    REFERENCES music_streaming.songs(song_id)
    ON DELETE CASCADE,

    added_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS music_streaming.subscriptions (
    subscription_id SERIAL PRIMARY KEY,

    user_id INT NOT NULL
    REFERENCES music_streaming.users(user_id)
    ON DELETE RESTRICT,

    plan_name VARCHAR(50) NOT NULL,

    monthly_price NUMERIC(10,2) NOT NULL,

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    status VARCHAR(20) DEFAULT 'active'
);

-- PART 3: ALTER TABLE

ALTER TABLE music_streaming.users
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(15);

ALTER TABLE music_streaming.users
ALTER COLUMN phone_number TYPE VARCHAR(20);

ALTER TABLE music_streaming.playlists
RENAME COLUMN playlist_name TO title;

ALTER TABLE music_streaming.subscriptions
ALTER COLUMN status SET DEFAULT 'active';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'unique_song_title'
    ) THEN
        ALTER TABLE music_streaming.songs
        ADD CONSTRAINT unique_song_title UNIQUE(title);
    END IF;
END $$;

-- CHECK CONSTRAINTS

DO $$
BEGIN

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_gender'
    ) THEN
        ALTER TABLE music_streaming.users
        DROP CONSTRAINT check_gender;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_duration'
    ) THEN
        ALTER TABLE music_streaming.songs
        DROP CONSTRAINT check_duration;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_play_count'
    ) THEN
        ALTER TABLE music_streaming.songs
        DROP CONSTRAINT check_play_count;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_subscription_date'
    ) THEN
        ALTER TABLE music_streaming.subscriptions
        DROP CONSTRAINT check_subscription_date;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_constraint
        WHERE conname = 'check_subscription_status'
    ) THEN
        ALTER TABLE music_streaming.subscriptions
        DROP CONSTRAINT check_subscription_status;
    END IF;

END $$;

ALTER TABLE music_streaming.users
ADD CONSTRAINT check_gender
CHECK (gender IN ('M', 'F', 'Other'));

ALTER TABLE music_streaming.songs
ADD CONSTRAINT check_duration
CHECK (duration_seconds > 0);

ALTER TABLE music_streaming.songs
ADD CONSTRAINT check_play_count
CHECK (play_count >= 0);

ALTER TABLE music_streaming.subscriptions
ADD CONSTRAINT check_subscription_date
CHECK (start_date > DATE '2026-01-01');

ALTER TABLE music_streaming.subscriptions
ADD CONSTRAINT check_subscription_status
CHECK (status IN ('active', 'expired', 'cancelled'));

-- PART 4: INSERT

TRUNCATE TABLE
music_streaming.playlist_song,
music_streaming.playlists,
music_streaming.subscriptions,
music_streaming.songs,
music_streaming.albums,
music_streaming.genres,
music_streaming.artists,
music_streaming.users
RESTART IDENTITY CASCADE;

-- USERS

INSERT INTO music_streaming.users (
    first_name,
    last_name,
    email,
    gender,
    birth_date,
    phone_number
)
VALUES
('Damir', 'Gabitov', 'damir@gmail.com', 'M', '2005-03-14', '+77071234567'),
('Ilya', 'Osipov', 'monesy@gmail.com', 'M', '2001-06-20', '+77081234567'),
('Maxim', 'Lukin', 'kyousuke@gmail.com', 'M', '1999-11-11', '+77091234567');

-- ARTISTS

INSERT INTO music_streaming.artists (
    stage_name,
    country,
    debut_year
)
VALUES
('Travis Scott', 'USA', 2008),
('Markul', 'Latvia', 2013),
('The Weeknd', 'Canada', 2010);

-- GENRES

INSERT INTO music_streaming.genres (
    genre_name
)
VALUES
('Hip-Hop'),
('R&B'),
('Pop');

-- ALBUMS

INSERT INTO music_streaming.albums (
    artist_id,
    genre_id,
    title,
    release_date
)
VALUES
(
    (SELECT artist_id
     FROM music_streaming.artists
     WHERE stage_name = 'Travis Scott'),

    (SELECT genre_id
     FROM music_streaming.genres
     WHERE genre_name = 'Hip-Hop'),

    'UTOPIA',
    '2026-02-01'
),

(
    (SELECT artist_id
     FROM music_streaming.artists
     WHERE stage_name = 'Markul'),

    (SELECT genre_id
     FROM music_streaming.genres
     WHERE genre_name = 'Hip-Hop'),

    'MAKE DEPRESSION GREAT AGAIN',
    '2026-11-22'
),

(
    (SELECT artist_id
     FROM music_streaming.artists
     WHERE stage_name = 'The Weeknd'),

    (SELECT genre_id
     FROM music_streaming.genres
     WHERE genre_name = 'R&B'),

    'Starboy',
    '2026-04-10'
);

-- SONGS

INSERT INTO music_streaming.songs (
    album_id,
    title,
    duration_seconds,
    is_explicit
)
VALUES
(
    (SELECT album_id
     FROM music_streaming.albums
     WHERE title = 'UTOPIA'),

    'FE!N',
    210,
    TRUE
),

(
    (SELECT album_id
     FROM music_streaming.albums
     WHERE title = 'MAKE DEPRESSION GREAT AGAIN'),

    'MDGA',
    245,
    TRUE
),

(
    (SELECT album_id
     FROM music_streaming.albums
     WHERE title = 'Starboy'),

    'Starboy',
    230,
    FALSE
);

-- PLAYLISTS

INSERT INTO music_streaming.playlists (
    user_id,
    title
)
VALUES
(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'damir@gmail.com'),

    'DomiLand'
),

(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'monesy@gmail.com'),

    'Always Second'
),

(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'kyousuke@gmail.com'),

    'Chill Vibes'
);

-- PLAYLIST SONG

INSERT INTO music_streaming.playlist_song (
    playlist_id,
    song_id
)
SELECT
    p.playlist_id,
    s.song_id
FROM music_streaming.playlists p
JOIN music_streaming.songs s
ON s.title IN ('FE!N', 'Starboy')
WHERE p.title = 'DomiLand';

-- SUBSCRIPTIONS

INSERT INTO music_streaming.subscriptions (
    user_id,
    plan_name,
    monthly_price,
    start_date,
    end_date,
    status
)
VALUES
(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'damir@gmail.com'),

    'Premium',
    2990.00,
    '2026-02-01',
    '2026-12-31',
    'active'
),

(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'monesy@gmail.com'),

    'Student',
    1990.00,
    '2026-03-01',
    '2026-09-01',
    'active'
),

(
    (SELECT user_id
     FROM music_streaming.users
     WHERE email = 'kyousuke@gmail.com'),

    'Free',
    0.00,
    '2026-04-01',
    '2026-08-01',
    'expired'
);

-- PART 5: UPDATE

UPDATE music_streaming.subscriptions
SET status = 'expired'
WHERE end_date < CURRENT_DATE;

UPDATE music_streaming.songs s
SET play_count = sub.total_count
FROM (
    SELECT
        song_id,
        COUNT(*) * 100 AS total_count
    FROM music_streaming.playlist_song
    GROUP BY song_id
) sub
WHERE s.song_id = sub.song_id;

-- PART 5: DELETE

BEGIN;

DELETE FROM music_streaming.playlists
WHERE created_at < CURRENT_DATE - INTERVAL '2 years'
RETURNING playlist_id, title;

ROLLBACK;

-- PART 6: GRANT / REVOKE

DO $$
BEGIN

    IF EXISTS (
        SELECT FROM pg_roles
        WHERE rolname = 'music_readonly'
    ) THEN
        REASSIGN OWNED BY music_readonly TO CURRENT_USER;
        DROP OWNED BY music_readonly;
        DROP ROLE music_readonly;
    END IF;

    IF EXISTS (
        SELECT FROM pg_roles
        WHERE rolname = 'music_editor'
    ) THEN
        REASSIGN OWNED BY music_editor TO CURRENT_USER;
        DROP OWNED BY music_editor;
        DROP ROLE music_editor;
    END IF;

END $$;

CREATE ROLE music_readonly;

CREATE ROLE music_editor;

GRANT USAGE ON SCHEMA music_streaming
TO music_readonly, music_editor;

GRANT SELECT
ON ALL TABLES IN SCHEMA music_streaming
TO music_readonly;

GRANT INSERT, UPDATE
ON music_streaming.playlists
TO music_editor;

REVOKE UPDATE
ON music_streaming.playlists
FROM music_editor;
