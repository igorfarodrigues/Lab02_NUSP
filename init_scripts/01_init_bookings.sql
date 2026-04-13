-- Script de inicialização do banco de dados para o Lab02
-- Cria o schema bookings e as tabelas necessárias com dados de exemplo

CREATE SCHEMA IF NOT EXISTS bookings;

-- Tabela de Reservas
CREATE TABLE IF NOT EXISTS bookings.bookings (
    book_ref    CHAR(6) PRIMARY KEY,
    book_date   TIMESTAMPTZ NOT NULL,
    total_amount NUMERIC(10, 2) NOT NULL
);

-- Tabela de Passageiros/Bilhetes
CREATE TABLE IF NOT EXISTS bookings.tickets (
    ticket_no       CHAR(13) PRIMARY KEY,
    book_ref        CHAR(6) NOT NULL REFERENCES bookings.bookings(book_ref),
    passenger_id    VARCHAR(20) NOT NULL,
    passenger_name  TEXT NOT NULL,
    contact_data    JSONB
);

-- Tabela de Aeronaves
CREATE TABLE IF NOT EXISTS bookings.aircrafts (
    aircraft_code   CHAR(3) PRIMARY KEY,
    model           TEXT NOT NULL,
    range           INT NOT NULL
);

-- Tabela de Aeroportos
CREATE TABLE IF NOT EXISTS bookings.airports (
    airport_code    CHAR(3) PRIMARY KEY,
    airport_name    TEXT NOT NULL,
    city            TEXT NOT NULL,
    coordinates     POINT,
    timezone        TEXT NOT NULL
);

-- Tabela de Voos
CREATE TABLE IF NOT EXISTS bookings.flights (
    flight_id           SERIAL PRIMARY KEY,
    flight_no           CHAR(6) NOT NULL,
    scheduled_departure TIMESTAMPTZ NOT NULL,
    scheduled_arrival   TIMESTAMPTZ NOT NULL,
    departure_airport   CHAR(3) NOT NULL REFERENCES bookings.airports(airport_code),
    arrival_airport     CHAR(3) NOT NULL REFERENCES bookings.airports(airport_code),
    status              VARCHAR(20) NOT NULL,
    aircraft_code       CHAR(3) NOT NULL REFERENCES bookings.aircrafts(aircraft_code),
    actual_departure    TIMESTAMPTZ,
    actual_arrival      TIMESTAMPTZ
);

-- Tabela de Segmentos de Voo (muitos-para-muitos entre tickets e voos)
CREATE TABLE IF NOT EXISTS bookings.ticket_flights (
    ticket_no       CHAR(13) NOT NULL REFERENCES bookings.tickets(ticket_no),
    flight_id       INT NOT NULL REFERENCES bookings.flights(flight_id),
    fare_conditions VARCHAR(10) NOT NULL CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business')),
    amount          NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (ticket_no, flight_id)
);

-- Tabela de Assentos
CREATE TABLE IF NOT EXISTS bookings.boarding_passes (
    ticket_no       CHAR(13) NOT NULL REFERENCES bookings.tickets(ticket_no),
    flight_id       INT NOT NULL REFERENCES bookings.flights(flight_id),
    boarding_no     INT NOT NULL,
    seat_no         VARCHAR(4) NOT NULL,
    PRIMARY KEY (ticket_no, flight_id)
);

-- ============================================================
-- DADOS DE EXEMPLO
-- ============================================================

-- Aeronaves
INSERT INTO bookings.aircrafts (aircraft_code, model, range) VALUES
    ('319', 'Airbus A319-100', 6700),
    ('320', 'Airbus A320-200', 5700),
    ('321', 'Airbus A321-200', 5600),
    ('733', 'Boeing 737-300', 4200),
    ('763', 'Boeing 767-300', 7900),
    ('773', 'Boeing 777-300', 11100),
    ('CN1', 'Cessna 208 Caravan', 1200),
    ('CR2', 'Bombardier CRJ-200', 2700),
    ('SU9', 'Sukhoi Superjet-100', 3000)
ON CONFLICT (aircraft_code) DO NOTHING;

-- Aeroportos
INSERT INTO bookings.airports (airport_code, airport_name, city, timezone) VALUES
    ('GRU', 'Aeroporto Internacional de São Paulo/Guarulhos', 'São Paulo', 'America/Sao_Paulo'),
    ('GIG', 'Aeroporto Internacional do Rio de Janeiro/Galeão', 'Rio de Janeiro', 'America/Sao_Paulo'),
    ('BSB', 'Aeroporto Internacional de Brasília', 'Brasília', 'America/Sao_Paulo'),
    ('SSA', 'Aeroporto Internacional de Salvador', 'Salvador', 'America/Bahia'),
    ('FOR', 'Aeroporto Internacional de Fortaleza', 'Fortaleza', 'America/Fortaleza'),
    ('MAN', 'Aeroporto Internacional Eduardo Gomes', 'Manaus', 'America/Manaus'),
    ('POA', 'Aeroporto Internacional Salgado Filho', 'Porto Alegre', 'America/Sao_Paulo'),
    ('REC', 'Aeroporto Internacional do Recife', 'Recife', 'America/Recife'),
    ('CWB', 'Aeroporto Internacional Afonso Pena', 'Curitiba', 'America/Sao_Paulo'),
    ('BEL', 'Aeroporto Internacional de Belém', 'Belém', 'America/Belem')
ON CONFLICT (airport_code) DO NOTHING;

-- Reservas
INSERT INTO bookings.bookings (book_ref, book_date, total_amount) VALUES
    ('000012', '2024-01-10 08:00:00+00', 15600.00),
    ('00030D', '2024-01-11 09:15:00+00', 8200.50),
    ('0003AB', '2024-01-12 10:30:00+00', 32100.00),
    ('0004CE', '2024-01-13 11:45:00+00', 5400.00),
    ('000521', '2024-01-14 12:00:00+00', 18900.00),
    ('00063F', '2024-01-15 13:30:00+00', 9700.00),
    ('000712', '2024-01-16 14:00:00+00', 42000.00),
    ('000890', '2024-01-17 15:15:00+00', 11200.00),
    ('000ABC', '2024-01-18 16:30:00+00', 6800.00),
    ('000BDE', '2024-01-19 17:45:00+00', 23500.00)
ON CONFLICT (book_ref) DO NOTHING;

-- Bilhetes
INSERT INTO bookings.tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data) VALUES
    ('0005432000987', '000012', '8149 604011', 'IVAN IVANOV', '{"phone": "+70123456789"}'),
    ('0005432000988', '000012', '8013 620891', 'IRINA PETROVA', '{"phone": "+70223456789"}'),
    ('0005432001003', '00030D', '1011 752484', 'MIKHAIL SIDOROV', '{"email": "m.sidorov@example.com"}'),
    ('0005432001004', '0003AB', '4849 400049', 'ELENA KUZNETSOVA', '{"phone": "+70323456789"}'),
    ('0005432001005', '0003AB', '6615 976589', 'DMITRI POPOV', '{"email": "d.popov@example.com"}'),
    ('0005432001006', '0004CE', '2374 645102', 'ANNA SOKOLOVA', '{"phone": "+70423456789"}'),
    ('0005432001007', '000521', '5820 013418', 'ALEXEI VOLKOV', '{"email": "a.volkov@example.com"}'),
    ('0005432001008', '00063F', '9012 345678', 'NATALIA MOROZOVA', '{"phone": "+70523456789"}'),
    ('0005432001009', '000712', '3456 789012', 'SERGEI LEBEDEV', '{"email": "s.lebedev@example.com"}'),
    ('0005432001010', '000890', '7890 123456', 'OLGA KOZLOVA', '{"phone": "+70623456789"}')
ON CONFLICT (ticket_no) DO NOTHING;

-- Voos
INSERT INTO bookings.flights (flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code, actual_departure, actual_arrival) VALUES
    ('PG0013', '2024-02-01 08:00:00+00', '2024-02-01 10:00:00+00', 'GRU', 'GIG', 'Arrived', '319', '2024-02-01 08:10:00+00', '2024-02-01 10:15:00+00'),
    ('PG0014', '2024-02-01 10:30:00+00', '2024-02-01 13:00:00+00', 'GIG', 'BSB', 'Arrived', '320', '2024-02-01 10:35:00+00', '2024-02-01 13:10:00+00'),
    ('PG0015', '2024-02-02 07:00:00+00', '2024-02-02 09:30:00+00', 'BSB', 'SSA', 'Arrived', '321', '2024-02-02 07:05:00+00', '2024-02-02 09:40:00+00'),
    ('PG0016', '2024-02-02 11:00:00+00', '2024-02-02 14:00:00+00', 'GRU', 'FOR', 'Arrived', '763', '2024-02-02 11:15:00+00', '2024-02-02 14:20:00+00'),
    ('PG0017', '2024-02-03 06:00:00+00', '2024-02-03 09:00:00+00', 'GIG', 'MAN', 'Arrived', '773', '2024-02-03 06:00:00+00', '2024-02-03 09:00:00+00'),
    ('PG0018', '2024-02-03 13:00:00+00', '2024-02-03 15:00:00+00', 'GRU', 'POA', 'Arrived', '319', '2024-02-03 13:05:00+00', '2024-02-03 15:10:00+00'),
    ('PG0019', '2024-02-04 08:30:00+00', '2024-02-04 10:30:00+00', 'BSB', 'REC', 'Arrived', '320', '2024-02-04 08:35:00+00', '2024-02-04 10:40:00+00'),
    ('PG0020', '2024-02-04 12:00:00+00', '2024-02-04 13:30:00+00', 'GRU', 'CWB', 'Arrived', '733', '2024-02-04 12:00:00+00', '2024-02-04 13:30:00+00'),
    ('PG0021', '2024-02-05 07:30:00+00', '2024-02-05 11:00:00+00', 'GRU', 'BEL', 'Arrived', '321', '2024-02-05 07:40:00+00', '2024-02-05 11:15:00+00'),
    ('PG0022', '2024-02-05 15:00:00+00', '2024-02-05 16:30:00+00', 'SSA', 'REC', 'Arrived', 'CR2', '2024-02-05 15:10:00+00', '2024-02-05 16:45:00+00')
ON CONFLICT DO NOTHING;

-- Segmentos de Voo (ticket_flights)
INSERT INTO bookings.ticket_flights (ticket_no, flight_id, fare_conditions, amount)
SELECT t.ticket_no, f.flight_id, fc.fare_conditions, fc.amount
FROM (
    VALUES
        ('0005432000987', 1, 'Business', 7800.00),
        ('0005432000988', 1, 'Economy',  3200.00),
        ('0005432001003', 2, 'Economy',  4100.25),
        ('0005432001004', 3, 'Business', 16050.00),
        ('0005432001005', 3, 'Comfort',   8500.00),
        ('0005432001006', 4, 'Economy',   2700.00),
        ('0005432001007', 5, 'Business', 12300.00),
        ('0005432001008', 6, 'Economy',   4850.00),
        ('0005432001009', 7, 'Business', 21000.00),
        ('0005432001010', 8, 'Economy',   5600.00)
) AS fc(ticket_no, fid, fare_conditions, amount)
JOIN bookings.tickets t ON t.ticket_no = fc.ticket_no
JOIN bookings.flights f ON f.flight_id = fc.fid
ON CONFLICT (ticket_no, flight_id) DO NOTHING;
