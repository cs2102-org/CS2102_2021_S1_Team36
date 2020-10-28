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
DROP TABLE IF EXISTS FullTimeLeave CASCADE;

DROP TYPE IF EXISTS transfer_type;
DROP TYPE IF EXISTS payment_type;
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
    is_fulltime BOOLEAN NOT NULL,
    rating INTEGER,
    CHECK (0 <= rating AND rating <= 5)
);

CREATE TABLE PartTimeAvail ( -- records the part time availability
    email VARCHAR(30) REFERENCES Caretakers(email) ON DELETE CASCADE,
    work_date DATE,
    PRIMARY KEY (email, work_date)
);
-- todo: check that user is actually a part timer

CREATE TABLE FullTimeLeave ( -- records the full time availability
    email VARCHAR(30) REFERENCES Caretakers(email) ON DELETE CASCADE,
    leave_date DATE NOT NULL,
    PRIMARY KEY (email, leave_date)
); -- todo: check that user is actually a full timer

CREATE TABLE PetOwners (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE
);

CREATE TABLE PetTypes ( -- enumerates the types of pets there are, like Dog, Cat, etc
    species VARCHAR(30) PRIMARY KEY NOT NULL
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
    start_date DATE,
    end_date DATE,
    price DECIMAL(10,2),
    amount_bidded DECIMAL(10,2),
    is_confirmed BOOLEAN,
    is_paid BOOLEAN,
    payment_type payment_type,
    transfer_type transfer_type,
    rating DECIMAL(10, 1) CHECK (rating >= 0 AND rating <= 5), --can add text for the review
    FOREIGN KEY (owner_email, pet_name) REFERENCES Pets(email, pet_name),
    PRIMARY KEY (caretaker_email, owner_email, pet_name, submission_time)
); -- todo: there should be check that submission_time < start_date <= end_date, but i think leave out this check for now

CREATE TABLE TakecarePrice (
    base_price DECIMAL(10,2),
    daily_price DECIMAL(10,2),
    email varchar(30) REFERENCES Caretakers(email) ON DELETE cascade, -- references the caretaker
    species varchar(30) REFERENCES PetTypes(species),
    PRIMARY KEY (email, species)
);

CREATE TABLE Posts (
	post_id SERIAL PRIMARY KEY,
    email VARCHAR(30) NOT NULL REFERENCES Users(email) ON DELETE SET NULL,
    title VARCHAR(255),
    cont TEXT,
    last_modified TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Comments (
	post_id INTEGER REFERENCES Posts(post_id),
    email VARCHAR(30) REFERENCES Users(email) ON DELETE SET NULL,
    date_time TIMESTAMP DEFAULT NOW(),
    cont TEXT,
    PRIMARY KEY (post_id, email, date_time)
);

INSERT INTO Users(name, email, description, password) VALUES ('panter', 'panter@gmail.com', 'panter is a petowner of pcs', 'pwpanter');
INSERT INTO PetOwners(email) VALUES ('panter@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('peter', 'peter@gmail.com', 'peter is a petowner of pcs', 'pwpeter');
INSERT INTO PetOwners(email) VALUES ('peter@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('patty', 'patty@gmail.com', 'patty is a petowner of pcs', 'pwpatty');
INSERT INTO PetOwners(email) VALUES ('patty@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('pattison', 'pattison@gmail.com', 'pattison is a petowner of pcs', 'pwpattison');
INSERT INTO PetOwners(email) VALUES ('pattison@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('parthia', 'parthia@gmail.com', 'parthia is a petowner of pcs', 'pwparthia');
INSERT INTO PetOwners(email) VALUES ('parthia@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('parthus', 'parthus@gmail.com', 'parthus is a petowner of pcs', 'pwparthus');
INSERT INTO PetOwners(email) VALUES ('parthus@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('paragon', 'paragon@gmail.com', 'paragon is a petowner of pcs', 'pwparagon');
INSERT INTO PetOwners(email) VALUES ('paragon@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('parata', 'parata@gmail.com', 'parata is a petowner of pcs', 'pwparata');
INSERT INTO PetOwners(email) VALUES ('parata@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('pistachio', 'pistachio@gmail.com', 'pistachio is a petowner of pcs', 'pwpistachio');
INSERT INTO PetOwners(email) VALUES ('pistachio@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('peran', 'peran@gmail.com', 'peran is a petowner of pcs', 'pwperan');
INSERT INTO PetOwners(email) VALUES ('peran@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('perry', 'perry@gmail.com', 'perry is a petowner of pcs', 'pwperry');
INSERT INTO PetOwners(email) VALUES ('perry@gmail.com');
INSERT INTO Users(name, email, description, password) VALUES ('pearl', 'pearl@gmail.com', 'pearl is a petowner of pcs', 'pwpearl');
INSERT INTO PetOwners(email) VALUES ('pearl@gmail.com');

INSERT INTO Users(name, email, description, password) VALUES ('cassie', 'cassie@gmail.com', 'cassie is a full time caretaker of pcs', 'pwcassie');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassie@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('carrie', 'carrie@gmail.com', 'carrie is a full time caretaker of pcs', 'pwcarrie');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrie@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('carl', 'carl@gmail.com', 'carl is a full time caretaker of pcs', 'pwcarl');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carl@gmail.com', true, 4);
INSERT INTO Users(name, email, description, password) VALUES ('carlos', 'carlos@gmail.com', 'carlos is a full time caretaker of pcs', 'pwcarlos');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlos@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('caren', 'caren@gmail.com', 'caren is a full time caretaker of pcs', 'pwcaren');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caren@gmail.com', true, 5);
INSERT INTO Users(name, email, description, password) VALUES ('canneth', 'canneth@gmail.com', 'canneth is a full time caretaker of pcs', 'pwcanneth');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('canneth@gmail.com', true, 1);
INSERT INTO Users(name, email, description, password) VALUES ('cain', 'cain@gmail.com', 'cain is a full time caretaker of pcs', 'pwcain');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cain@gmail.com', true, 4);
INSERT INTO Users(name, email, description, password) VALUES ('carmen', 'carmen@gmail.com', 'carmen is a full time caretaker of pcs', 'pwcarmen');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carmen@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('cejudo', 'cejudo@gmail.com', 'cejudo is a full time caretaker of pcs', 'pwcejudo');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cejudo@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('celine', 'celine@gmail.com', 'celine is a full time caretaker of pcs', 'pwceline');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celine@gmail.com', true, 0);
INSERT INTO Users(name, email, description, password) VALUES ('cevan', 'cevan@gmail.com', 'cevan is a full time caretaker of pcs', 'pwcevan');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cevan@gmail.com', true, 5);
INSERT INTO Users(name, email, description, password) VALUES ('catarth', 'catarth@gmail.com', 'catarth is a full time caretaker of pcs', 'pwcatarth');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('catarth@gmail.com', true, 1);
INSERT INTO Users(name, email, description, password) VALUES ('columbus', 'columbus@gmail.com', 'columbus is a full time caretaker of pcs', 'pwcolumbus');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('columbus@gmail.com', true, 2);

INSERT INTO Users(name, email, description, password) VALUES ('xiaoping', 'xiaoping@gmail.com', 'xiaoping is a part time caretaker of pcs', 'pwxiaoping');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaoping@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaoming', 'xiaoming@gmail.com', 'xiaoming is a part time caretaker of pcs', 'pwxiaoming');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaoming@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaodong', 'xiaodong@gmail.com', 'xiaodong is a part time caretaker of pcs', 'pwxiaodong');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaodong@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaolong', 'xiaolong@gmail.com', 'xiaolong is a part time caretaker of pcs', 'pwxiaolong');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaolong@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaobao', 'xiaobao@gmail.com', 'xiaobao is a part time caretaker of pcs', 'pwxiaobao');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaobao@gmail.com', false, 1);
INSERT INTO Users(name, email, description, password) VALUES ('xiaorong', 'xiaorong@gmail.com', 'xiaorong is a part time caretaker of pcs', 'pwxiaorong');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaorong@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaohong', 'xiaohong@gmail.com', 'xiaohong is a part time caretaker of pcs', 'pwxiaohong');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaohong@gmail.com', false, 2);
INSERT INTO Users(name, email, description, password) VALUES ('xiaozong', 'xiaozong@gmail.com', 'xiaozong is a part time caretaker of pcs', 'pwxiaozong');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaozong@gmail.com', false, 2);

INSERT INTO PetTypes(species) VALUES ('Dog');
INSERT INTO PetTypes(species) VALUES ('Cat');
INSERT INTO PetTypes(species) VALUES ('Hamster');
INSERT INTO PetTypes(species) VALUES ('Mouse');
INSERT INTO PetTypes(species) VALUES ('Bird');
INSERT INTO PetTypes(species) VALUES ('Horse');
INSERT INTO PetTypes(species) VALUES ('Turtle');
INSERT INTO PetTypes(species) VALUES ('Snake');
INSERT INTO PetTypes(species) VALUES ('Monkey');
INSERT INTO PetTypes(species) VALUES ('Lion');

INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('panter@gmail.com', 'roger', 'needs a lot of care', 'roger is a Dog owned by panter', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peter@gmail.com', 'boomer', 'needs alone time', 'boomer is a Cat owned by peter', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patty@gmail.com', 'jerry', 'scared of thunder', 'jerry is a Hamster owned by patty', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pattison@gmail.com', 'tom', 'scared of vaccumm', 'tom is a Mouse owned by pattison', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthia@gmail.com', 'felix', 'likes apples', 'felix is a Bird owned by parthia', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthus@gmail.com', 'roscoe', 'allergic to peanuts', 'roscoe is a Horse owned by parthus', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paragon@gmail.com', 'sammy', 'allergic to grass', 'sammy is a Turtle owned by paragon', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parata@gmail.com', 'cloud', 'scared of snakes', 'cloud is a Snake owned by parata', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pistachio@gmail.com', 'millie', 'hates cats', 'millie is a Monkey owned by pistachio', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peran@gmail.com', 'rufus', 'hates dogs', 'rufus is a Lion owned by peran', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('perry@gmail.com', 'axa', 'needs blanket to sleep', 'axa is a Dog owned by perry', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pearl@gmail.com', 'abby', 'needs to drink 100 plus', 'abby is a Cat owned by pearl', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('panter@gmail.com', 'alfie', 'needs a lot of care', 'alfie is a Hamster owned by panter', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peter@gmail.com', 'bandit', 'needs alone time', 'bandit is a Mouse owned by peter', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patty@gmail.com', 'biscuit', 'scared of thunder', 'biscuit is a Bird owned by patty', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pattison@gmail.com', 'buster', 'scared of vaccumm', 'buster is a Horse owned by pattison', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthia@gmail.com', 'chad', 'likes apples', 'chad is a Turtle owned by parthia', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthus@gmail.com', 'charlie', 'allergic to peanuts', 'charlie is a Snake owned by parthus', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paragon@gmail.com', 'chewie', 'allergic to grass', 'chewie is a Monkey owned by paragon', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parata@gmail.com', 'chippy', 'scared of snakes', 'chippy is a Lion owned by parata', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pistachio@gmail.com', 'choco', 'hates cats', 'choco is a Dog owned by pistachio', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peran@gmail.com', 'daisy', 'hates dogs', 'daisy is a Cat owned by peran', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('perry@gmail.com', 'digger', 'needs blanket to sleep', 'digger is a Hamster owned by perry', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pearl@gmail.com', 'fergie', 'needs to drink 100 plus', 'fergie is a Mouse owned by pearl', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('panter@gmail.com', 'fido', 'needs a lot of care', 'fido is a Bird owned by panter', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peter@gmail.com', 'freddie', 'needs alone time', 'freddie is a Horse owned by peter', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patty@gmail.com', 'ginger', 'scared of thunder', 'ginger is a Turtle owned by patty', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pattison@gmail.com', 'gizmo', 'scared of vaccumm', 'gizmo is a Snake owned by pattison', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthia@gmail.com', 'gus', 'likes apples', 'gus is a Monkey owned by parthia', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parthus@gmail.com', 'hugo', 'allergic to peanuts', 'hugo is a Lion owned by parthus', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paragon@gmail.com', 'jacky', 'allergic to grass', 'jacky is a Dog owned by paragon', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parata@gmail.com', 'jake', 'scared of snakes', 'jake is a Cat owned by parata', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pistachio@gmail.com', 'jaxson', 'hates cats', 'jaxson is a Hamster owned by pistachio', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peran@gmail.com', 'logan', 'hates dogs', 'logan is a Mouse owned by peran', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('perry@gmail.com', 'lucky', 'needs blanket to sleep', 'lucky is a Bird owned by perry', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pearl@gmail.com', 'maddie', 'needs to drink 100 plus', 'maddie is a Horse owned by pearl', 'Horse');

INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'cassie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'cassie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 80, 'cassie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'carrie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'carrie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 90, 'carrie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (40, 80, 'carl@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (50, 90, 'carl@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 120, 'carl@gmail.com', 'Bird');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'carlos@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'carlos@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (110, 110, 'carlos@gmail.com', 'Horse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (50, 100, 'caren@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 110, 'caren@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (110, 160, 'caren@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 80, 'canneth@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 90, 'canneth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (140, 150, 'canneth@gmail.com', 'Snake');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (40, 80, 'cain@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (50, 90, 'cain@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (120, 160, 'cain@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'carmen@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'carmen@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (150, 150, 'carmen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'cejudo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'cejudo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 80, 'cejudo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 60, 'celine@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 70, 'celine@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 90, 'celine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (50, 100, 'cevan@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (60, 110, 'cevan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 140, 'cevan@gmail.com', 'Bird');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 80, 'catarth@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 90, 'catarth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (120, 130, 'catarth@gmail.com', 'Horse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'columbus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'columbus@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (140, 160, 'columbus@gmail.com', 'Turtle');

INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaoping@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaoping@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (100, 120, 'xiaoping@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaoming@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaoming@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (110, 130, 'xiaoming@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaodong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaodong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (120, 140, 'xiaodong@gmail.com', 'Bird');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaolong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaolong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (130, 150, 'xiaolong@gmail.com', 'Horse');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (70, 80, 'xiaobao@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 90, 'xiaobao@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (130, 140, 'xiaobao@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaorong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaorong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (150, 170, 'xiaorong@gmail.com', 'Snake');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaohong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaohong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (160, 180, 'xiaohong@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (80, 100, 'xiaozong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (90, 110, 'xiaozong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(base_price, daily_price, email, species) VALUES (170, 190, 'xiaozong@gmail.com', 'Lion');

INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-01-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2020-04-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-01-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2020-04-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-01-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carl@gmail.com', '2020-04-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-01-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlos@gmail.com', '2020-04-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-01-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-01-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-01-31');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-02-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-04-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-04-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caren@gmail.com', '2020-05-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-02-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('canneth@gmail.com', '2020-05-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-02-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cain@gmail.com', '2020-05-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-02-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmen@gmail.com', '2020-05-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-02-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-02-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-02-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-02-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-03-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-03-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-03-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-03-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-03-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-05-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-05-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-05-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-05-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-05-31');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cejudo@gmail.com', '2020-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-03-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-08');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('celine@gmail.com', '2020-06-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-03-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cevan@gmail.com', '2020-06-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-03-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('catarth@gmail.com', '2020-06-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-03-31');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-04-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-04-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-06-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('columbus@gmail.com', '2020-07-02');

INSERT INTO BidsFor VALUES ('panter@gmail.com', 'cassie@gmail.com', 'roger',
'2020-10-25', '2020-01-01', '2020-01-01',
100, 110,
false, false, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'cassie@gmail.com', 'alfie',
'2020-10-25', '2020-01-01', '2020-01-05',
80, 130,
false, false, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'carl@gmail.com', 'fido',
'2020-10-26', '2020-01-01', '2020-01-05',
80, 110,
false, false, '1', '1', 5
);



INSERT INTO Posts(post_id, email, title, cont) VALUES (1, 'panter@gmail.com', 'How to teach dog to sit',
'Im trying to teach my dog roger how to sit but he just doesnt get it, any tips?');

INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'peter@gmail.com', '2020-09-26',
    'you need to do progressive training, like in NS'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'patty@gmail.com', '2020-09-26',
    'i think you shouldnt own pets if you dont even know this basic stuff'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'pattison@gmail.com', '2020-09-26',
    'dickson dont be mean to people everyoen has to start somewhere'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'parthia@gmail.com', '2020-09-27',
    'have you tried giving him treats every time your dog does it correctly?'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'parthus@gmail.com', '2020-09-27',
    'have you tried beating him with a slipper???'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'paragon@gmail.com', '2020-09-27',
    'noo...i would never hurt my precious dog'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'parata@gmail.com', '2020-09-27',
    'you need to be dominant so your dog knows you are pack leader'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'xiaoming@gmail.com', '2020-09-27',
    'eh pm me i am expert because i watch youtube'
);


INSERT INTO Posts(post_id, email, title, cont) VALUES (2, 'cassie@gmail.com', 'How to make cat like me',
'why does my cat hate me so much??');

INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'peter@gmail.com', '2020-09-26',
    'either it likes you or it doesnt, you can only accept the outcome'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'patty@gmail.com', '2020-09-26',
    'I think you need to give her some space'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'pattison@gmail.com', '2020-09-26',
    'hey i have the same problem too'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'parthia@gmail.com', '2020-09-27',
    'Does this work for dogs also?'
);



-- test get available ft caretakers
INSERT into fulltimeleave (email, leave_date) values ('cassie@gmail.com', '2022-01-01');
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'cassie@gmail.com', 'fido',
'2020-01-01', '2022-01-05', '2022-01-010',
80, 110,
true, true, '1', '1', 5
);

-- test get available pt caretakers
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-01');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-02');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-03');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-04');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-05');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-06');
INSERT into parttimeavail (email, work_date) values ('xiaoming@gmail.com', '2022-01-07');
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'xiaoming@gmail.com', 'fido',
'2020-01-02', '2022-01-05', '2022-01-010',
80, 110,
true, true, '1', '1', 5
);