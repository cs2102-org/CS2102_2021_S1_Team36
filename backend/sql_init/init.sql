DROP DATABASE IF EXISTS pcs;

CREATE DATABASE pcs;

\c pcs;

DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS CareTakers CASCADE;
DROP TABLE IF EXISTS PetOwners CASCADE;
DROP TABLE IF EXISTS Pets CASCADE;
DROP TABLE IF EXISTS PcsAdmins CASCADE;
DROP TABLE IF EXISTS BidsFor CASCADE;
DROP TABLE IF EXISTS TakecarePrice CASCADE;
DROP TABLE IF EXISTS PetTypes CASCADE;
DROP TABLE IF EXISTS Posts CASCADE;
DROP TABLE IF EXISTS Comments CASCADE;

CREATE TYPE transfer_type AS ENUM('1', '2', '3');
CREATE TYPE payment_type AS ENUM('1', '2', '3');

CREATE TABLE Users (
    name VARCHAR(30) NOT NULL,
    email VARCHAR(30) PRIMARY KEY,
    description VARCHAR(255),
    password VARCHAR(60) NOT NULL
);

CREATE TABLE Caretakers (
     email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE,
     days_available CHAR(366),
     is_fulltime BOOLEAN,
     rating INTEGER,
     CHECK (0 <= rating AND rating <= 5)
);

CREATE TABLE PetOwners (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE
);

CREATE TABLE PetTypes ( -- enumerates the types of pets there are, like Dog, Cat, etc
    species VARCHAR(30) PRIMARY KEY
);

CREATE TABLE Pets (
    email VARCHAR(30) REFERENCES PetOwners(email),
    pet_name VARCHAR(30),
    special_requirements VARCHAR(255),
    description VARCHAR(255),
    species VARCHAR(30) REFERENCES PetTypes(species) ON DELETE SET NULL,
    PRIMARY KEY (pet_name, email)
);

CREATE TABLE PcsAdmins (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE
);

CREATE TABLE BidsFor (
    owner_email VARCHAR(30),
    caretaker_email VARCHAR(30) REFERENCES CareTakers(email),
    pet_name VARCHAR(30),
    price DECIMAL(10,2),
    bid_date TIMESTAMP,
    transfer_type transfer_type,
    is_confirmed BOOLEAN,
    number_of_days INTEGER,
    submission_time TIMESTAMP,
    is_paid BOOLEAN,
    payment_type payment_type,
    amount_bidded DECIMAL(10,2),
    rating DECIMAL(10, 1) CHECK (rating >= 0 AND rating <= 5), --can add text for the review
    FOREIGN KEY (owner_email, pet_name) REFERENCES Pets(email, pet_name),
    PRIMARY KEY (caretaker_email, owner_email, pet_name, submission_time)
);

CREATE TABLE TakecarePrice (
    base_price DECIMAL(10,2),
    daily_price DECIMAL(10,2),
    email varchar(30) REFERENCES Caretakers(email) ON DELETE cascade, -- references the caretaker
    species varchar(30) REFERENCES PetTypes(species),
    PRIMARY KEY (email, species)
);

CREATE TABLE Posts (
    email VARCHAR(30) NOT NULL REFERENCES Users(email) ON DELETE SET NULL,
    title VARCHAR(255) PRIMARY KEY,
    content TEXT,
    last_modified TIMESTAMP
);

CREATE TABLE Comments (
    content TEXT,
    date_time TIMESTAMP,
    title TEXT REFERENCES Posts(title),
    email VARCHAR(30) REFERENCES Users(email) ON DELETE SET NULL,
    PRIMARY KEY(title, email, date_time)
);

INSERT INTO Users values ('Tom', 'tom@gmail.com', '123');
INSERT INTO Users values ('Jane', 'jane@gmail.com', '321');
