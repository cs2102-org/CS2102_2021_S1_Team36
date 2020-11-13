-- sql for Petowner with a lot of bids
-- names used: alan, ricky, roger, rocky

-- Alan the swanky owner of three pets
-- digger the dog
-- biscuit the bird
-- cookie the cat

-- He always ask ricky to take care his dog
-- roger take care his cat
-- rocky take care his bird



INSERT INTO Users(name, email, description, password) VALUES ('alan', 'alan@gmail.com', 'alan is a User of PCS', 'alanpw');
INSERT INTO Petowners(email) VALUES ('alan@gmail.com');

INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alan@gmail.com', 'digger', 'digger needs love!', 'digger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alan@gmail.com', 'cookie', 'cookie needs love!', 'cookie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alan@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('ricky', 'ricky@gmail.com', 'ricky is a User of PCS', 'rickypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ricky@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ricky@gmail.com', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('roger', 'roger@gmail.com', 'roger is a User of PCS', 'rogerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roger@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'roger@gmail.com', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('rocky', 'rocky@gmail.com', 'rocky is a User of PCS', 'rockypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rocky@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rocky@gmail.com', 'Bird');

INSERT INTO BidsFor VALUES ('alan@gmail.com', 'ricky@gmail.com', 'digger',
'2020-10-01 00:00:01', '2020-10-25', '2020-10-28',
50, 50,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-10-01 00:00:02', '2020-10-27', '2020-10-30',
60, 60,
True, True, '1', '1', 3
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'ricky@gmail.com', 'digger',
'2020-10-15 00:00:01', '2020-11-01', '2020-11-03',
50, 50,
True, True, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-10-15 00:00:02', '2020-11-03', '2020-11-06',
60, 60,
True, True, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'ricky@gmail.com', 'digger',
'2020-11-13 00:00:01', '2020-12-01', '2020-12-05',
50, 50,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-11-13 00:00:02', '2020-12-01', '2020-12-05',
60, 60,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'rocky@gmail.com', 'biscuit',
'2020-11-13 00:00:03', '2020-12-01', '2020-12-05',
90, 90,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'ricky@gmail.com', 'digger',
'2020-11-13 00:00:11', '2020-12-10', '2020-12-14',
50, 50,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-11-13 00:00:12', '2020-12-15', '2020-12-19',
60, 60,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'rocky@gmail.com', 'biscuit',
'2020-11-13 00:00:13', '2020-12-17', '2020-12-21',
90, 90,
True, False, '1', '1', NULL
);

INSERT INTO BidsFor VALUES ('alan@gmail.com', 'rocky@gmail.com', 'biscuit',
'2020-11-13 00:00:14', '2020-12-25', '2020-12-31',
90, 90,
True, False, '1', '1', NULL
);

INSERT INTO BidsFor VALUES ('alan@gmail.com', 'ricky@gmail.com', 'digger',
'2020-11-13 00:00:04', '2021-01-01', '2021-01-05',
50, 50,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-11-13 00:00:05', '2021-01-01', '2021-01-05',
60, 60,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'rocky@gmail.com', 'biscuit',
'2020-11-13 00:00:06', '2021-01-01', '2021-01-05',
90, 90,
True, False, '1', '1', NULL
);




-- parttime caretaker with a lot of jobs 
-- Cain can take care of
-- Dog 100
-- Cat 100
-- Hamster 80
-- Mouse 80
-- Bird 90

-- He gets jobs from Petowners
-- Apple Dog digger
-- Pearl Dog digger, Cat cookie
-- Carmen Hamster harry, Mouse mickey
-- Butch Bird biscuit
-- Billy Bird biscuit

INSERT INTO Users(name, email, description, password) VALUES ('cain', 'cain@gmail.com', 'cain is a User of PCS', 'cainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cain@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cain@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cain@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cain@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cain@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cain@gmail.com', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('apple', 'apple@gmail.com', 'apple is a User of PCS', 'applepw');
INSERT INTO Petowners(email) VALUES ('apple@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('apple@gmail.com', 'digger', 'digger needs love!', 'digger is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('pearl', 'pearl@gmail.com', 'pearl is a User of PCS', 'pearlpw');
INSERT INTO Petowners(email) VALUES ('pearl@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pearl@gmail.com', 'digger', 'digger needs love!', 'digger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pearl@gmail.com', 'cookie', 'cookie needs love!', 'cookie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('carmen', 'carmen@gmail.com', 'carmen is a User of PCS', 'carmenpw');
INSERT INTO Petowners(email) VALUES ('carmen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmen@gmail.com', 'harry', 'harry needs love!', 'harry is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmen@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('butch', 'butch@gmail.com', 'butch is a User of PCS', 'butchpw');
INSERT INTO Petowners(email) VALUES ('butch@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('butch@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('billy', 'billy@gmail.com', 'billy is a User of PCS', 'billypw');
INSERT INTO Petowners(email) VALUES ('billy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('billy@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Bird', 'Bird');

INSERT INTO BidsFor VALUES ('apple@gmail.com', 'cain@gmail.com', 'digger',
'2020-09-01 00:00:01', '2020-10-01', '2020-10-07',
100, 110,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'digger',
'2020-09-01 00:00:02', '2020-10-02', '2020-10-08',
100, 100,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'cookie',
'2020-09-01 00:00:03', '2020-10-03', '2020-10-09',
100, 100,
False, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('carmen@gmail.com', 'cain@gmail.com', 'harry',
'2020-09-01 00:00:04', '2020-10-05', '2020-10-10',
80, 80,
False, False, '1', '1', NULL
);

INSERT INTO BidsFor VALUES ('butch@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-10-15 00:00:01', '2020-10-16', '2020-10-20',
90, 100,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('billy@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-10-15 00:00:02', '2020-10-17', '2020-10-21',
90, 90,
True, True, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('carmen@gmail.com', 'cain@gmail.com', 'mickey',
'2020-10-15 00:00:03', '2020-10-21', '2020-10-25',
80, 100,
True, True, '1', '1', 5
);

-- cain has high rating now, so can take 5 pets
INSERT INTO BidsFor VALUES ('apple@gmail.com', 'cain@gmail.com', 'digger',
'2020-10-31 00:00:01', '2020-11-01', '2020-11-05',
100, 120,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'digger',
'2020-10-31 00:00:02', '2020-11-01', '2020-11-05',
100, 110,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'cookie',
'2020-10-31 00:00:03', '2020-11-01', '2020-11-05',
100, 100,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('carmen@gmail.com', 'cain@gmail.com', 'harry',
'2020-10-31 00:00:04', '2020-11-01', '2020-11-05',
80, 80,
False, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('carmen@gmail.com', 'cain@gmail.com', 'mickey',
'2020-10-31 00:00:05', '2020-11-01', '2020-11-05',
80, 81,
False, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('butch@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-10-31 00:00:06', '2020-11-01', '2020-11-03',
90, 105,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('billy@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-10-31 00:00:07', '2020-11-01', '2020-11-03',
90, 100,
True, True, '1', '1', 4
);

-- future bids
INSERT INTO BidsFor VALUES ('apple@gmail.com', 'cain@gmail.com', 'digger',
'2020-11-03 00:00:01', '2020-12-01', '2020-12-05',
100, 100,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'digger',
'2020-11-03 00:00:02', '2020-12-01', '2020-12-05',
100, 110,
True, True, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('butch@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-11-03 00:00:03', '2020-12-01', '2020-12-03',
90, 100,
True, False, '1', '1', NULL
);
INSERT INTO BidsFor VALUES ('billy@gmail.com', 'cain@gmail.com', 'biscuit',
'2020-11-03 00:00:03', '2020-12-01', '2020-12-07',
90, 95,
True, True, '1', '1', NULL
);
