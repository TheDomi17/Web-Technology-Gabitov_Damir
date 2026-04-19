CREATE TABLE IF NOT EXISTS Genre (
    genre_id SERIAL PRIMARY KEY,
    genre_name VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS SeatType (
    seat_type_id SERIAL PRIMARY KEY,
    type_name VARCHAR(20) NOT NULL,
    seat_type_price NUMERIC(8,2) NOT NULL CHECK (seat_type_price >= 0)
);

CREATE TABLE IF NOT EXISTS Theater (
    theater_id SERIAL PRIMARY KEY,
    name VARCHAR(30) NOT NULL,
    address VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS Customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(30) NOT NULL,
    last_name VARCHAR(30) NOT NULL,
    email VARCHAR(40) NOT NULL,
    phone VARCHAR(20),
    date_of_birth DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Film (
    film_id SERIAL PRIMARY KEY,
    title VARCHAR(50) NOT NULL,
    genre_id INT REFERENCES Genre(genre_id),
    duration_min SMALLINT NOT NULL CHECK (duration_min > 0),
    rating DECIMAL(3,1) NOT NULL CHECK (rating >= 0),
    release_date DATE NOT NULL CHECK (release_date > '2026-01-01')
);

CREATE TABLE IF NOT EXISTS Auditorium (
    auditorium_id SERIAL PRIMARY KEY,
    theater_id INT NOT NULL REFERENCES Theater(theater_id),
    name VARCHAR(30) NOT NULL,
    screen_type VARCHAR(30) NOT NULL,
    total_seats SMALLINT CHECK (total_seats > 0)
);

CREATE TABLE IF NOT EXISTS Seat (
    seat_id SERIAL PRIMARY KEY,
    auditorium_id INT NOT NULL REFERENCES Auditorium(auditorium_id),
    row_label CHAR(2) NOT NULL,
    seat_number SMALLINT NOT NULL,
    seat_type_id INT NOT NULL REFERENCES SeatType(seat_type_id),
    UNIQUE (auditorium_id, row_label, seat_number)
);

CREATE TABLE IF NOT EXISTS Screening (
    screening_id SERIAL PRIMARY KEY,
    film_id INT NOT NULL REFERENCES Film(film_id),
    auditorium_id INT NOT NULL REFERENCES Auditorium(auditorium_id),
    start_time TIMESTAMP,
    end_time TIMESTAMP,
    format VARCHAR(20) NOT NULL,
    is_active BOOLEAN,
    CHECK (format IN ('2D', '3D', 'IMAX'))
);

CREATE TABLE IF NOT EXISTS Booking (
    booking_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES Customers(customer_id),
    booked_at TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'paid', 'cancelled')),
    total_amount DECIMAL(10,2) CHECK (total_amount >= 0),
    payment_method VARCHAR(30) NOT NULL
);

CREATE TABLE IF NOT EXISTS Ticket (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL REFERENCES Booking(booking_id),
    screening_id INT NOT NULL REFERENCES Screening(screening_id),
    seat_id INT NOT NULL REFERENCES Seat(seat_id),
    price_paid NUMERIC(8,2) CHECK (price_paid >= 0),
    status VARCHAR(20) NOT NULL CHECK (status IN ('valid', 'used', 'cancelled'))
);

-- email was not marked unique initially
ALTER TABLE Customers
ADD CONSTRAINT uq_customers_email UNIQUE (email);

-- ensure phone numbers are unique
ALTER TABLE Customers
ADD CONSTRAINT uq_customers_phone UNIQUE (phone);

-- booking time should default to now
ALTER TABLE Booking
ALTER COLUMN booked_at SET DEFAULT CURRENT_TIMESTAMP;

-- ensure screening end_time is after start_time
ALTER TABLE Screening
ADD CONSTRAINT chk_time CHECK (end_time > start_time);

-- prevent duplicate seat booking per screening
ALTER TABLE Ticket
ADD CONSTRAINT uq_ticket UNIQUE (screening_id, seat_id);

TRUNCATE TABLE Ticket, Booking, Screening, Seat, Auditorium,
Film, Customers, Theater, Genre, SeatType RESTART IDENTITY CASCADE;

INSERT INTO Genre (genre_name) VALUES
('Action'),
('Comedy');

INSERT INTO SeatType (type_name, seat_type_price) VALUES
('Standard', 10.00),
('VIP', 20.00);

INSERT INTO Theater (name, address) VALUES
('Cinema City', 'Abay 12'),
('Grand Cinema', 'Kurmangazy 5');

INSERT INTO Customers (first_name, last_name, email, phone, date_of_birth) VALUES
('Ilya', 'Osipov', 'monesy@gmail.com', '123456789', '2000-05-10'),
('Maxim', 'Lukin', 'kyousuke@gmail.com', '987654321', '1998-08-22');

INSERT INTO Film (title, genre_id, duration_min, rating, release_date) VALUES
('Fast Action', 1, 120, 8.5, '2026-02-01'),
('Funny Movie', 2, 90, 7.2, '2026-03-10');

INSERT INTO Auditorium (theater_id, name, screen_type, total_seats) VALUES
(1, 'Hall 1', 'IMAX', 100),
(2, 'Hall 2', 'Standard', 80);

INSERT INTO Seat (auditorium_id, row_label, seat_number, seat_type_id) VALUES
(1, 'A', 1, 1),
(2, 'B', 2, 2);

INSERT INTO Screening (film_id, auditorium_id, start_time, end_time, format, is_active) VALUES
(1, 1, '2026-04-01 18:00', '2026-04-01 20:00', 'IMAX', TRUE),
(2, 2, '2026-04-02 19:00', '2026-04-02 20:30', '2D', TRUE);

INSERT INTO Booking (customer_id, booked_at, status, total_amount, payment_method) VALUES
(1, NOW(), 'paid', 20.00, 'card'),
(2, NOW(), 'pending', 10.00, 'cash');

INSERT INTO Ticket (booking_id, screening_id, seat_id, price_paid, status) VALUES
(1, 1, 1, 10.00, 'valid'),
(2, 2, 2, 20.00, 'valid');

