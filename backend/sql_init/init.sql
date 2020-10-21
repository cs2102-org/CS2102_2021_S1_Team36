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
DROP TABLE IF EXISTS PartTimeAvail CASCADE;
DROP TABLE IF EXISTS FullTimeAvail CASCADE;

DROP TYPE IF EXISTS transfer_type;
DROP TYPE IF EXISTS payment_type;
CREATE TYPE transfer_type AS ENUM('1', '2', '3');
CREATE TYPE payment_type AS ENUM('1', '2', '3');

CREATE TABLE Users (
    name VARCHAR(30),
    email VARCHAR(30) PRIMARY KEY,
    description VARCHAR(255),
    password VARCHAR(30)
);

CREATE TABLE Caretakers (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE,
    is_fulltime BOOLEAN,
    rating INTEGER,
    CHECK (0 <= rating AND rating <= 5)
);

CREATE TABLE PartTimeAvail ( -- records the part time availability
    email VARCHAR(30) PRIMARY KEY REFERENCES Caretakers(email) ON DELETE CASCADE,
    work_date TIMESTAMP
); -- check that user is actually a part timer

CREATE TABLE FullTimeAvail ( -- records the full time availability
    email VARCHAR(30) PRIMARY KEY REFERENCES Caretakers(email) ON DELETE CASCADE,
    leave_date TIMESTAMP
); -- check that user is actually a full timer

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
    submission_time TIMESTAMP,
    bid_date TIMESTAMP,
    number_of_days INTEGER,
    price DECIMAL(10,2),
    amount_bidded DECIMAL(10,2),
    is_confirmed BOOLEAN,
    is_paid BOOLEAN,
    payment_type payment_type,
    transfer_type transfer_type,
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

INSERT INTO Users VALUES ('alice', 'alice@gmail.com', 'alice is a petowner of pcs', 'pwalice');
INSERT INTO PetOwners VALUES ('alice@gmail.com');
INSERT INTO Users VALUES ('bob', 'bob@gmail.com', 'bob is a petowner of pcs', 'pwbob');
INSERT INTO PetOwners VALUES ('bob@gmail.com');
INSERT INTO Users VALUES ('charlie', 'charlie@gmail.com', 'charlie is a petowner of pcs', 'pwcharlie');
INSERT INTO PetOwners VALUES ('charlie@gmail.com');
INSERT INTO Users VALUES ('dickson', 'dickson@gmail.com', 'dickson is a petowner of pcs', 'pwdickson');
INSERT INTO PetOwners VALUES ('dickson@gmail.com');
INSERT INTO Users VALUES ('farquard', 'farquard@gmail.com', 'farquard is a petowner of pcs', 'pwfarquard');
INSERT INTO PetOwners VALUES ('farquard@gmail.com');
INSERT INTO Users VALUES ('gaston', 'gaston@gmail.com', 'gaston is a petowner of pcs', 'pwgaston');
INSERT INTO PetOwners VALUES ('gaston@gmail.com');
INSERT INTO Users VALUES ('hassan', 'hassan@gmail.com', 'hassan is a petowner of pcs', 'pwhassan');
INSERT INTO PetOwners VALUES ('hassan@gmail.com');
INSERT INTO Users VALUES ('ignatius', 'ignatius@gmail.com', 'ignatius is a petowner of pcs', 'pwignatius');
INSERT INTO PetOwners VALUES ('ignatius@gmail.com');
INSERT INTO Users VALUES ('jospeh', 'jospeh@gmail.com', 'jospeh is a petowner of pcs', 'pwjospeh');
INSERT INTO PetOwners VALUES ('jospeh@gmail.com');
INSERT INTO Users VALUES ('kamaru', 'kamaru@gmail.com', 'kamaru is a petowner of pcs', 'pwkamaru');
INSERT INTO PetOwners VALUES ('kamaru@gmail.com');
INSERT INTO Users VALUES ('lexus', 'lexus@gmail.com', 'lexus is a petowner of pcs', 'pwlexus');
INSERT INTO PetOwners VALUES ('lexus@gmail.com');
INSERT INTO Users VALUES ('moses', 'moses@gmail.com', 'moses is a petowner of pcs', 'pwmoses');
INSERT INTO PetOwners VALUES ('moses@gmail.com');
INSERT INTO Users VALUES ('naruto', 'naruto@gmail.com', 'naruto is a petowner of pcs', 'pwnaruto');
INSERT INTO PetOwners VALUES ('naruto@gmail.com');
INSERT INTO Users VALUES ('obito', 'obito@gmail.com', 'obito is a petowner of pcs', 'pwobito');
INSERT INTO PetOwners VALUES ('obito@gmail.com');
INSERT INTO Users VALUES ('peter', 'peter@gmail.com', 'peter is a petowner of pcs', 'pwpeter');
INSERT INTO PetOwners VALUES ('peter@gmail.com');
INSERT INTO Users VALUES ('quillo', 'quillo@gmail.com', 'quillo is a petowner of pcs', 'pwquillo');
INSERT INTO PetOwners VALUES ('quillo@gmail.com');
INSERT INTO Users VALUES ('ramirez', 'ramirez@gmail.com', 'ramirez is a petowner of pcs', 'pwramirez');
INSERT INTO PetOwners VALUES ('ramirez@gmail.com');
INSERT INTO Users VALUES ('stefan', 'stefan@gmail.com', 'stefan is a petowner of pcs', 'pwstefan');
INSERT INTO PetOwners VALUES ('stefan@gmail.com');

INSERT INTO Users VALUES ('alex', 'alex@gmail.com', 'alex is a caretaker of pcs', 'pwalex');
INSERT INTO Caretakers VALUES ('alex@gmail.com', true, 4);
INSERT INTO Users VALUES ('bernie', 'bernie@gmail.com', 'bernie is a caretaker of pcs', 'pwbernie');
INSERT INTO Caretakers VALUES ('bernie@gmail.com', true, 0);
INSERT INTO Users VALUES ('cassie', 'cassie@gmail.com', 'cassie is a caretaker of pcs', 'pwcassie');
INSERT INTO Caretakers VALUES ('cassie@gmail.com', true, 0);
INSERT INTO Users VALUES ('diggory', 'diggory@gmail.com', 'diggory is a caretaker of pcs', 'pwdiggory');
INSERT INTO Caretakers VALUES ('diggory@gmail.com', true, 1);
INSERT INTO Users VALUES ('familia', 'familia@gmail.com', 'familia is a caretaker of pcs', 'pwfamilia');
INSERT INTO Caretakers VALUES ('familia@gmail.com', true, 1);
INSERT INTO Users VALUES ('gordan', 'gordan@gmail.com', 'gordan is a caretaker of pcs', 'pwgordan');
INSERT INTO Caretakers VALUES ('gordan@gmail.com', true, 0);
INSERT INTO Users VALUES ('hammy', 'hammy@gmail.com', 'hammy is a caretaker of pcs', 'pwhammy');
INSERT INTO Caretakers VALUES ('hammy@gmail.com', true, 5);
INSERT INTO Users VALUES ('jackson', 'jackson@gmail.com', 'jackson is a caretaker of pcs', 'pwjackson');
INSERT INTO Caretakers VALUES ('jackson@gmail.com', true, 1);
INSERT INTO Users VALUES ('konstance', 'konstance@gmail.com', 'konstance is a caretaker of pcs', 'pwkonstance');
INSERT INTO Caretakers VALUES ('konstance@gmail.com', true, 3);
INSERT INTO Users VALUES ('lokister', 'lokister@gmail.com', 'lokister is a caretaker of pcs', 'pwlokister');
INSERT INTO Caretakers VALUES ('lokister@gmail.com', true, 2);
INSERT INTO Users VALUES ('monsta', 'monsta@gmail.com', 'monsta is a caretaker of pcs', 'pwmonsta');
INSERT INTO Caretakers VALUES ('monsta@gmail.com', true, 0);
INSERT INTO Users VALUES ('natasha', 'natasha@gmail.com', 'natasha is a caretaker of pcs', 'pwnatasha');
INSERT INTO Caretakers VALUES ('natasha@gmail.com', true, 1);
INSERT INTO Users VALUES ('oranus', 'oranus@gmail.com', 'oranus is a caretaker of pcs', 'pworanus');
INSERT INTO Caretakers VALUES ('oranus@gmail.com', true, 0);
INSERT INTO Users VALUES ('percy', 'percy@gmail.com', 'percy is a caretaker of pcs', 'pwpercy');
INSERT INTO Caretakers VALUES ('percy@gmail.com', true, 5);
INSERT INTO Users VALUES ('patrick', 'patrick@gmail.com', 'patrick is a caretaker of pcs', 'pwpatrick');
INSERT INTO Caretakers VALUES ('patrick@gmail.com', true, 1);

INSERT INTO PetTypes VALUES ('Dog');
INSERT INTO PetTypes VALUES ('Cat');
INSERT INTO PetTypes VALUES ('Horse');
INSERT INTO PetTypes VALUES ('Monkey');
INSERT INTO PetTypes VALUES ('Lion');
INSERT INTO PetTypes VALUES ('Hamster');
INSERT INTO PetTypes VALUES ('Mouse');
INSERT INTO PetTypes VALUES ('Turtle');
INSERT INTO PetTypes VALUES ('Budgie');
INSERT INTO PetTypes VALUES ('Chicken');
INSERT INTO PetTypes VALUES ('Snake');

INSERT INTO Pets VALUES ('alice@gmail.com', 'roger', 'needs blanket to sleep', 'roger is a Dog owned by alice', 'Dog');
INSERT INTO Pets VALUES ('alice@gmail.com', 'boomer', 'needs more water', 'boomer is a Cat owned by alice', 'Cat');
INSERT INTO Pets VALUES ('bob@gmail.com', 'jerry', 'hates cats', 'jerry is a Cat owned by bob', 'Cat');
INSERT INTO Pets VALUES ('bob@gmail.com', 'tom', 'allergic to grass', 'tom is a Horse owned by bob', 'Horse');
INSERT INTO Pets VALUES ('charlie@gmail.com', 'felix', 'needs a lot of care', 'felix is a Horse owned by charlie', 'Horse');
INSERT INTO Pets VALUES ('charlie@gmail.com', 'roscoe', 'needs alone time', 'roscoe is a Monkey owned by charlie', 'Monkey');
INSERT INTO Pets VALUES ('dickson@gmail.com', 'sammy', 'needs a lot of care', 'sammy is a Monkey owned by dickson', 'Monkey');
INSERT INTO Pets VALUES ('dickson@gmail.com', 'cloud', 'needs a lot of care', 'cloud is a Lion owned by dickson', 'Lion');
INSERT INTO Pets VALUES ('farquard@gmail.com', 'millie', 'scared of thunder', 'millie is a Lion owned by farquard', 'Lion');
INSERT INTO Pets VALUES ('farquard@gmail.com', 'rufus', 'needs alone time', 'rufus is a Hamster owned by farquard', 'Hamster');
INSERT INTO Pets VALUES ('gaston@gmail.com', 'axa', 'hates dogs', 'axa is a Hamster owned by gaston', 'Hamster');
INSERT INTO Pets VALUES ('gaston@gmail.com', 'abby', 'needs blanket to sleep', 'abby is a Mouse owned by gaston', 'Mouse');
INSERT INTO Pets VALUES ('hassan@gmail.com', 'alfie', 'needs more water', 'alfie is a Mouse owned by hassan', 'Mouse');
INSERT INTO Pets VALUES ('hassan@gmail.com', 'bandit', 'needs a lot of care', 'bandit is a Turtle owned by hassan', 'Turtle');
INSERT INTO Pets VALUES ('ignatius@gmail.com', 'biscuit', 'scared of vaccumm', 'biscuit is a Turtle owned by ignatius', 'Turtle');
INSERT INTO Pets VALUES ('ignatius@gmail.com', 'buster', 'scared of thunder', 'buster is a Budgie owned by ignatius', 'Budgie');
INSERT INTO Pets VALUES ('jospeh@gmail.com', 'chad', 'needs blanket to sleep', 'chad is a Budgie owned by jospeh', 'Budgie');
INSERT INTO Pets VALUES ('jospeh@gmail.com', 'charlie', 'needs alone time', 'charlie is a Chicken owned by jospeh', 'Chicken');
INSERT INTO Pets VALUES ('kamaru@gmail.com', 'chewie', 'needs a lot of care', 'chewie is a Chicken owned by kamaru', 'Chicken');
INSERT INTO Pets VALUES ('kamaru@gmail.com', 'chippy', 'needs a lot of care', 'chippy is a Snake owned by kamaru', 'Snake');
INSERT INTO Pets VALUES ('lexus@gmail.com', 'choco', 'needs blanket to sleep', 'choco is a Snake owned by lexus', 'Snake');
INSERT INTO Pets VALUES ('lexus@gmail.com', 'daisy', 'needs blanket to sleep', 'daisy is a Dog owned by lexus', 'Dog');
INSERT INTO Pets VALUES ('moses@gmail.com', 'digger', 'needs more water', 'digger is a Dog owned by moses', 'Dog');
INSERT INTO Pets VALUES ('moses@gmail.com', 'fergie', 'needs more water', 'fergie is a Cat owned by moses', 'Cat');
INSERT INTO Pets VALUES ('naruto@gmail.com', 'fido', 'needs blanket to sleep', 'fido is a Cat owned by naruto', 'Cat');
INSERT INTO Pets VALUES ('naruto@gmail.com', 'freddie', 'needs alone time', 'freddie is a Horse owned by naruto', 'Horse');
INSERT INTO Pets VALUES ('obito@gmail.com', 'ginger', 'needs more water', 'ginger is a Horse owned by obito', 'Horse');
INSERT INTO Pets VALUES ('obito@gmail.com', 'gizmo', 'needs blanket to sleep', 'gizmo is a Monkey owned by obito', 'Monkey');
INSERT INTO Pets VALUES ('peter@gmail.com', 'gus', 'hates cats', 'gus is a Monkey owned by peter', 'Monkey');
INSERT INTO Pets VALUES ('peter@gmail.com', 'hugo', 'hates dogs', 'hugo is a Lion owned by peter', 'Lion');
INSERT INTO Pets VALUES ('quillo@gmail.com', 'jacky', 'needs more water', 'jacky is a Lion owned by quillo', 'Lion');
INSERT INTO Pets VALUES ('quillo@gmail.com', 'jake', 'needs blanket to sleep', 'jake is a Hamster owned by quillo', 'Hamster');
INSERT INTO Pets VALUES ('ramirez@gmail.com', 'jaxson', 'needs alone time', 'jaxson is a Hamster owned by ramirez', 'Hamster');
INSERT INTO Pets VALUES ('ramirez@gmail.com', 'logan', 'needs a lot of care', 'logan is a Mouse owned by ramirez', 'Mouse');
INSERT INTO Pets VALUES ('stefan@gmail.com', 'lucky', 'needs more water', 'lucky is a Mouse owned by stefan', 'Mouse');
INSERT INTO Pets VALUES ('stefan@gmail.com', 'maddie', 'needs a lot of care', 'maddie is a Turtle owned by stefan', 'Turtle');

INSERT INTO TakecarePrice VALUES (40, 80, 'alex@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (40, 80, 'alex@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (60, 60, 'bernie@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (60, 60, 'bernie@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (60, 60, 'cassie@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (60, 60, 'cassie@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (70, 80, 'diggory@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (70, 80, 'diggory@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (70, 80, 'familia@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (70, 80, 'familia@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (60, 60, 'gordan@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (60, 60, 'gordan@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (50, 100, 'hammy@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (50, 100, 'hammy@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (70, 80, 'jackson@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (70, 80, 'jackson@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (90, 120, 'konstance@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (90, 120, 'konstance@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (80, 100, 'lokister@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (80, 100, 'lokister@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (60, 60, 'monsta@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (60, 60, 'monsta@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (70, 80, 'natasha@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (70, 80, 'natasha@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (60, 60, 'oranus@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (60, 60, 'oranus@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (50, 100, 'percy@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (50, 100, 'percy@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (70, 80, 'patrick@gmail.com', 'Dog');
INSERT INTO TakecarePrice VALUES (70, 80, 'patrick@gmail.com', 'Cat');
INSERT INTO TakecarePrice VALUES (40, 80, 'alex@gmail.com', 'Horse');
INSERT INTO TakecarePrice VALUES (60, 60, 'bernie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice VALUES (60, 60, 'cassie@gmail.com', 'Lion');
INSERT INTO TakecarePrice VALUES (70, 80, 'diggory@gmail.com', 'Hamster');
INSERT INTO TakecarePrice VALUES (70, 80, 'familia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice VALUES (60, 60, 'gordan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice VALUES (50, 100, 'hammy@gmail.com', 'Budgie');
INSERT INTO TakecarePrice VALUES (70, 80, 'jackson@gmail.com', 'Chicken');
INSERT INTO TakecarePrice VALUES (90, 120, 'konstance@gmail.com', 'Snake');
INSERT INTO TakecarePrice VALUES (80, 100, 'lokister@gmail.com', 'Horse');
INSERT INTO TakecarePrice VALUES (60, 60, 'monsta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice VALUES (70, 80, 'natasha@gmail.com', 'Lion');
INSERT INTO TakecarePrice VALUES (60, 60, 'oranus@gmail.com', 'Hamster');
INSERT INTO TakecarePrice VALUES (50, 100, 'percy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice VALUES (70, 80, 'patrick@gmail.com', 'Turtle');


INSERT INTO BidsFor VALUES ('alice@gmail.com', 'bernie@gmail.com', 'roger',
'2020-10-25', '2020-10-26', 5,
90, 100,
false, false, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('bob@gmail.com', 'bernie@gmail.com', 'jerry',
'2020-10-26', '2020-10-26', 3,
90, 100,
false, false, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'bernie@gmail.com', 'felix',
'2020-10-24', '2020-10-27', 3,
90, 100,
false, false, '1', '1', NULL
);

INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'gordan@gmail.com', 'roscoe',
'2020-10-24', '2020-10-25', 3,
90, 100,
false, false, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'gordan@gmail.com', 'roscoe',
'2020-10-25', '2020-10-27', 3,
90, 100,
false, false, '1', '2', NULL
);
INSERT INTO BidsFor VALUES ('dickson@gmail.com', 'gordan@gmail.com', 'sammy',
'2020-10-24', '2020-10-26', 4,
90, 100,
false, false, '2', '2', NULL
);