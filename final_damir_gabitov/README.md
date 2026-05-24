Introduction

This project is a Music Streaming Database Management System developed using PostgreSQL.
The database is designed to manage music streaming operations such as users, artists, albums, songs, playlists, subscriptions, and genres.

The database name is music_streaming_db and all tables are stored inside the music_streaming_schema schema.

The project demonstrates:

Database and schema creation
Table creation
Primary and foreign keys
One-to-many and many-to-many relationships
Constraints and validations
Generated columns
INSERT, UPDATE, and DELETE operations
Role and permission management
Re-runnable SQL scripts
First Part — Create Database and Schema

In the first part of the script, the database music_streaming_db is created.

A DO $$ ... $$ block with IF NOT EXISTS is used to make the script re-runnable and prevent errors if the database already exists.

After that, the schema music_streaming_schema is created.
The schema helps organize all database objects in one logical namespace.

Second Part — Create Tables

This section creates all tables required for the music streaming system.

users

Stores platform user information.

Columns:

user_id
full_name
email
gender
birth_date
country
created_at

Constraints:

Email must be unique
Gender must be:
M
F
Other
created_at automatically stores the current timestamp

Relationships:

One user can create many playlists
One user can have many subscriptions
artists

Stores artist information.

Columns:

artist_id
stage_name
real_name
country
debut_year

Constraints:

Stage names must be unique
Debut year cannot be negative

Relationships:

One artist can release many albums
genres

Stores music genres.

Examples:

Hip-Hop
Pop
Rock
Jazz
Electronic

Relationships:

One genre can contain many albums
albums

Stores album information.

Columns:

album_id
title
artist_id
genre_id
release_date
album_type

Constraints:

Album type must be:
Single
EP
Album

Relationships:

One artist can release many albums
One genre can contain many albums
One album can contain many songs
songs

Stores song information.

Columns:

song_id
album_id
title
duration_seconds
plays
is_explicit

Constraints:

Duration cannot be negative
Plays cannot be negative

Relationships:

One album can contain many songs
One song can appear in many playlists
playlists

Stores user-created playlists.

Columns:

playlist_id
user_id
playlist_name
created_at
is_public

Relationships:

One user can create many playlists
playlist_song

Bridge table between playlists and songs.

Meaning:

One playlist can contain many songs
One song can appear in many playlists

Columns:

playlist_song_id
playlist_id
song_id
added_at

Constraints:

Duplicate songs inside the same playlist are not allowed
subscriptions

Stores user subscription information.

Columns:

subscription_id
user_id
plan_name
start_date
end_date
price
status

Constraints:

Price cannot be negative
Status must be:
ACTIVE
EXPIRED
CANCELLED

Relationships:

One user can have many subscriptions over time
Third Part — Many-to-Many Relationship Tables
playlist_song

Connects playlists and songs.

Meaning:

One playlist can contain many songs
One song can appear in many playlists

This table resolves the many-to-many relationship between playlists and songs.

Fourth Part — ALTER TABLE and Constraints

This section adds additional constraints after table creation.

Added Constraints
Release Date Check

Ensures albums are released after a valid year.

Subscription Date Check

Ensures subscription end dates are later than start dates.

Song Duration Check

Prevents negative song durations.

Playlist Unique Song Constraint

Prevents duplicate songs inside the same playlist.

User Birth Date Check

Prevents future birth dates.

Fifth Part — Insert Data

This section inserts realistic sample data into all tables.

Inserted data includes:

Users
Artists
Genres
Albums
Songs
Playlists
Playlist-song relationships
Subscriptions

The script uses:

WHERE NOT EXISTS

This prevents duplicate inserts when the script is executed multiple times.

Foreign keys are inserted using subqueries instead of hard-coded IDs.

Sixth Part — UPDATE Operations

This section demonstrates updating existing data.

First UPDATE

Updates subscription status for expired subscriptions.

Business reason:

Expired subscriptions should automatically receive the EXPIRED status.

Second UPDATE

Updates song play counts using aggregated playlist data.

Business reason:

Popular songs should reflect updated streaming activity.

Seventh Part — DELETE Operations

This section demonstrates deleting expired subscriptions.

The DELETE operation is wrapped inside:

BEGIN;
ROLLBACK;

This means the deletion is only demonstrated and not permanently saved.

If ROLLBACK is replaced with COMMIT, the deleted rows would be permanently removed.

Eighth Part — GRANT and Role Management

This section demonstrates PostgreSQL security and permissions.

Role Creation

Two roles are created:

music_streaming_readonly
music_streaming_writer
Granted Permissions
Readonly Role

Receives:

CONNECT permission
USAGE on schema
SELECT on all tables

This role can only view data.

Writer Role

Receives:

INSERT permission
UPDATE permission

on selected tables.

REVOKE Example

The writer role initially receives UPDATE permissions on subscriptions.

Later, UPDATE is revoked for security reasons.

Business reason:

Subscription modifications should only be performed by administrators.

Database Relationships
One-to-Many Relationships
Artists → Albums
Genres → Albums
Albums → Songs
Users → Playlists
Users → Subscriptions
Many-to-Many Relationships
Playlists ↔ Songs

Implemented using:

playlist_song
Third Normal Form (3NF)

The database is designed according to Third Normal Form (3NF).

1NF
All values are atomic
No repeating groups
No comma-separated values
2NF
All non-key attributes fully depend on the primary key
3NF
No transitive dependencies exist
Genre names are separated into the genres table
Artist information is separated from albums
Playlist-song relationships are stored in a bridge table
Conclusion

This project demonstrates a complete relational database system for a music streaming platform using PostgreSQL.

The project includes:

Normalized database structure
Data integrity constraints
Relationships between entities
Generated columns
Secure role management
Re-runnable SQL scripts
Realistic music streaming business logic

The database can be extended in the future with:

Podcast support
User listening history
Artist followers
Music recommendations
Analytics and reporting
Premium family plans
