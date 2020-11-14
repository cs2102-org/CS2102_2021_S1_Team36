-- contains the manually added sql data
-- used to put in very specific things
-- to be fully independent from sql_init, need to initialize petowners and caretakers yourself
-- can assume that PetTypes table is initialized
-- also, avoid using names that have been used in sql_init
-- record the names (of Users) used here, so I can exclude from the sql_init data generation:
-- apple, pearl, carmen, butch, billy, ricky, roger, rocky, panter, peter, patty, patrick, patricia, nala, bob, buddy, brutus



-- sql for Petowner with a lot of bids
-- Alan the swanky owner of three pets
-- digger the dog
-- biscuit the bird
-- cookie the cat
-- He always ask :
    -- ricky to take care his dog
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



-- recommended caretakers for alan, owner of 3 pets
-- nala, similar pet owner to alan. owns:
    -- doobs the dog
    -- cauchy the cat
    -- barbie the bird
-- 3 common caretakers: ricky, roger, rocky
-- recommended cts: bob, buddy, brutus

-- make nala
INSERT INTO Users(name, email, description, password) VALUES ('nala', 'nala@gmail.com', 'nala is a User of PCS', 'nalapw');
INSERT INTO Petowners(email) VALUES ('nala@gmail.com');

INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nala@gmail.com', 'doobs', 'doobs needs love!', 'doobs is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nala@gmail.com', 'cauchy', 'cauchy needs love!', 'cauchy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nala@gmail.com', 'barbie', 'barbie needs love!', 'barbie is a Bird', 'Bird');

-- boost rating with roger (cat ct) for alan
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-09-01 00:00:02', '2020-09-02', '2020-09-03',
60, 60,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'roger@gmail.com', 'cookie',
'2020-09-02 00:00:02', '2020-09-05', '2020-09-06',
60, 60,
True, True, '1', '1', 5
);
-- boost rating with rocky (bird ct) for alan
INSERT INTO BidsFor VALUES ('alan@gmail.com', 'rocky@gmail.com', 'biscuit',
'2020-09-13 00:00:03', '2020-09-14', '2020-09-15',
90, 90,
True, True, '1', '1', 5
);
--make nala similar to alan
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'ricky@gmail.com', 'doobs',
'2020-08-01 00:00:01', '2020-08-25', '2020-08-28',
50, 50,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'roger@gmail.com', 'cauchy',
'2020-08-15 00:00:02', '2020-08-20', '2020-08-22',
60, 60,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'rocky@gmail.com', 'barbie',
'2020-08-13 00:00:03', '2020-08-23', '2020-08-24',
90, 90,
True, True, '1', '1', 5
);
--make recommended cts: 
INSERT INTO Users(name, email, description, password) VALUES ('bob', 'bob@gmail.com', 'bob is a User of PCS', 'bobpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bob@gmail.com', True, 0);--??rating should be 0 or NULL?
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'bob@gmail.com', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('buddy', 'buddy@gmail.com', 'buddy is a User of PCS', 'buddypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('buddy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'buddy@gmail.com', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('brutus', 'brutus@gmail.com', 'brutus is a User of PCS', 'brutuspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brutus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'brutus@gmail.com', 'Bird');
-- nala hire the 3 recommended cts before
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'bob@gmail.com', 'doobs',
'2020-07-01 00:00:01', '2020-07-25', '2020-07-28',
50, 50,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'buddy@gmail.com', 'cauchy',
'2020-08-15 00:00:02', '2020-08-20', '2020-08-22',
60, 60,
True, True, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('nala@gmail.com', 'brutus@gmail.com', 'barbie',
'2020-08-13 00:00:03', '2020-08-23', '2020-08-24',
90, 90,
True, True, '1', '1', 5
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



-- Forum
-- panter, peter, patty, patrick, patricia are discussing stuff
INSERT INTO Users(name, email, description, password) VALUES ('panter', 'panter@gmail.com', 'panter is a User of PCS', 'panterpw');
INSERT INTO Petowners(email) VALUES ('panter@gmail.com');

INSERT INTO Users(name, email, description, password) VALUES ('peter', 'peter@gmail.com', 'peter is a User of PCS', 'peterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('peter@gmail.com', True, 0);

INSERT INTO Users(name, email, description, password) VALUES ('patty', 'patty@gmail.com', 'patty is a User of PCS', 'pattypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patty@gmail.com', False, 0);

INSERT INTO Users(name, email, description, password) VALUES ('patrick', 'patrick@gmail.com', 'patrick is a User of PCS', 'patrickpw');
INSERT INTO Petowners(email) VALUES ('patrick@gmail.com');

INSERT INTO Users(name, email, description, password) VALUES ('patricia', 'patricia@gmail.com', 'patricia is a User of PCS', 'patriciapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patricia@gmail.com', True, 0);

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
    1, 'patrick@gmail.com', '2020-09-26',
    'dickson dont be mean to people everyoen has to start somewhere'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'patricia@gmail.com', '2020-09-27',
    'have you tried giving him treats every time your dog does it correctly?'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'peter@gmail.com', '2020-09-27',
    'have you tried beating him with a slipper???'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'panter@gmail.com', '2020-09-27',
    'noo...i would never hurt my precious dog'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'patty@gmail.com', '2020-09-27',
    'you need to be dominant so your dog knows you are pack leader'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    1, 'patrick@gmail.com', '2020-09-27',
    'eh pm me i am expert because i watch youtube'
);

INSERT INTO Posts(post_id, email, title, cont) VALUES (2, 'patty@gmail.com', 'How to make cat like me',
'why does my cat hate me so much??');

INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'peter@gmail.com', '2020-09-26',
    'either it likes you or it doesnt, you can only accept the outcome'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'patricia@gmail.com', '2020-09-26',
    'I think you need to give her some space'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'panter@gmail.com', '2020-09-26',
    'hey i have the same problem too'
);
INSERT INTO Comments(post_id, email, date_time, cont) VALUES (
    2, 'peter@gmail.com', '2020-09-27',
    'Does this work for dogs also?'
);
