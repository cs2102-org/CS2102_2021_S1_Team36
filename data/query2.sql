INSERT INTO PetTypes(species, base_price) VALUES ('Dog', 50);
INSERT INTO PetTypes(species, base_price) VALUES ('Cat', 60);
INSERT INTO PetTypes(species, base_price) VALUES ('Hamster', 70);
INSERT INTO PetTypes(species, base_price) VALUES ('Mouse', 80);
INSERT INTO PetTypes(species, base_price) VALUES ('Bird', 90);
INSERT INTO PetTypes(species, base_price) VALUES ('Horse', 100);
INSERT INTO PetTypes(species, base_price) VALUES ('Turtle', 110);
INSERT INTO PetTypes(species, base_price) VALUES ('Snake', 120);
INSERT INTO PetTypes(species, base_price) VALUES ('Monkey', 130);
INSERT INTO PetTypes(species, base_price) VALUES ('Lion', 140);

INSERT INTO Users(name, email, description, password) VALUES ('madison', 'madison@gmail.com', 'A user of PCS', 'madisonpw');
INSERT INTO PetOwners(email) VALUES ('madison@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madison@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madison@gmail.com', 'butch', 'butch needs love!', 'butch is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madison@gmail.com', 'kelsey', 'kelsey needs love!', 'kelsey is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madison@gmail.com', 'misha', 'misha needs love!', 'misha is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('miof mela', 'miof mela@gmail.com', 'A user of PCS', 'miof melapw');
INSERT INTO PetOwners(email) VALUES ('miof mela@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('miof mela@gmail.com', 'jethro', 'jethro needs love!', 'jethro is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('francklyn', 'francklyn@gmail.com', 'A user of PCS', 'francklynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francklyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'francklyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'francklyn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'francklyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'francklyn@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francklyn@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francklyn@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('siusan', 'siusan@gmail.com', 'A user of PCS', 'siusanpw');
INSERT INTO PetOwners(email) VALUES ('siusan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('siusan@gmail.com', 'chessie', 'chessie needs love!', 'chessie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('siusan@gmail.com', 'capone', 'capone needs love!', 'capone is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('siusan@gmail.com', 'chiquita', 'chiquita needs love!', 'chiquita is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('siusan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'siusan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'siusan@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('karlik', 'karlik@gmail.com', 'A user of PCS', 'karlikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlik@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'karlik@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'karlik@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'karlik@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'karlik@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'karlik@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlik@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ange', 'ange@gmail.com', 'A user of PCS', 'angepw');
INSERT INTO PetOwners(email) VALUES ('ange@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ange@gmail.com', 'mojo', 'mojo needs love!', 'mojo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ange@gmail.com', 'camille', 'camille needs love!', 'camille is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ange@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ange@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ange@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('finn', 'finn@gmail.com', 'A user of PCS', 'finnpw');
INSERT INTO PetOwners(email) VALUES ('finn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('finn@gmail.com', 'daisey-mae', 'daisey-mae needs love!', 'daisey-mae is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('finn@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('kissee', 'kissee@gmail.com', 'A user of PCS', 'kisseepw');
INSERT INTO PetOwners(email) VALUES ('kissee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'itsy', 'itsy needs love!', 'itsy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'chucky', 'chucky needs love!', 'chucky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'mitch', 'mitch needs love!', 'mitch is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kissee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kissee@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'kissee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'kissee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'kissee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'kissee@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kissee@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kissee@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('joline', 'joline@gmail.com', 'A user of PCS', 'jolinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'joline@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'joline@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'joline@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joline@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joline@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('charin', 'charin@gmail.com', 'A user of PCS', 'charinpw');
INSERT INTO PetOwners(email) VALUES ('charin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charin@gmail.com', 'chico', 'chico needs love!', 'chico is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charin@gmail.com', 'clifford', 'clifford needs love!', 'clifford is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('jenilee', 'jenilee@gmail.com', 'A user of PCS', 'jenileepw');
INSERT INTO PetOwners(email) VALUES ('jenilee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenilee@gmail.com', 'rags', 'rags needs love!', 'rags is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenilee@gmail.com', 'annie', 'annie needs love!', 'annie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('merilyn', 'merilyn@gmail.com', 'A user of PCS', 'merilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merilyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'merilyn@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merilyn@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('petr', 'petr@gmail.com', 'A user of PCS', 'petrpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('petr@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'petr@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'petr@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'petr@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'petr@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'petr@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('petr@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('grace', 'grace@gmail.com', 'A user of PCS', 'gracepw');
INSERT INTO PetOwners(email) VALUES ('grace@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'jenny', 'jenny needs love!', 'jenny is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'angus', 'angus needs love!', 'angus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('wilhelmine', 'wilhelmine@gmail.com', 'A user of PCS', 'wilhelminepw');
INSERT INTO PetOwners(email) VALUES ('wilhelmine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'chauncey', 'chauncey needs love!', 'chauncey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'jade', 'jade needs love!', 'jade is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilhelmine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'wilhelmine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'wilhelmine@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('farah', 'farah@gmail.com', 'A user of PCS', 'farahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'farah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'farah@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farah@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farah@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('addy', 'addy@gmail.com', 'A user of PCS', 'addypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('addy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'addy@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('flynn', 'flynn@gmail.com', 'A user of PCS', 'flynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('flynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'flynn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'flynn@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('foss', 'foss@gmail.com', 'A user of PCS', 'fosspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('foss@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'foss@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'foss@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'foss@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('foss@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('foss@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('jeffry', 'jeffry@gmail.com', 'A user of PCS', 'jeffrypw');
INSERT INTO PetOwners(email) VALUES ('jeffry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'gator', 'gator needs love!', 'gator is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'fonzie', 'fonzie needs love!', 'fonzie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeffry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'jeffry@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'jeffry@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (242, 'jeffry@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'jeffry@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeffry@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeffry@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('dagmar', 'dagmar@gmail.com', 'A user of PCS', 'dagmarpw');
INSERT INTO PetOwners(email) VALUES ('dagmar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'binky', 'binky needs love!', 'binky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'bo', 'bo needs love!', 'bo is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('humbert', 'humbert@gmail.com', 'A user of PCS', 'humbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humbert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'humbert@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('humbert@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('humbert@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('manda', 'manda@gmail.com', 'A user of PCS', 'mandapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('manda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'manda@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('manda@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('manda@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('pia', 'pia@gmail.com', 'A user of PCS', 'piapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'pia@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pia@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('michaela', 'michaela@gmail.com', 'A user of PCS', 'michaelapw');
INSERT INTO PetOwners(email) VALUES ('michaela@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michaela@gmail.com', 'kid', 'kid needs love!', 'kid is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michaela@gmail.com', 'abel', 'abel needs love!', 'abel is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michaela@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michaela@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'michaela@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'michaela@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'michaela@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'michaela@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'michaela@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michaela@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michaela@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('tyler', 'tyler@gmail.com', 'A user of PCS', 'tylerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tyler@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'tyler@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'tyler@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'tyler@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'tyler@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'tyler@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyler@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyler@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('constance', 'constance@gmail.com', 'A user of PCS', 'constancepw');
INSERT INTO PetOwners(email) VALUES ('constance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'alex', 'alex needs love!', 'alex is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'macy', 'macy needs love!', 'macy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'bunky', 'bunky needs love!', 'bunky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'lexi', 'lexi needs love!', 'lexi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('constance@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'constance@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'constance@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'constance@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'constance@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'constance@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('constance@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('constance@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('collen', 'collen@gmail.com', 'A user of PCS', 'collenpw');
INSERT INTO PetOwners(email) VALUES ('collen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('collen@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('collen@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('collen@gmail.com', 'doc', 'doc needs love!', 'doc is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('collen@gmail.com', 'barclay', 'barclay needs love!', 'barclay is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('collen@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('claudie', 'claudie@gmail.com', 'A user of PCS', 'claudiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'claudie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'claudie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('fawn', 'fawn@gmail.com', 'A user of PCS', 'fawnpw');
INSERT INTO PetOwners(email) VALUES ('fawn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fawn@gmail.com', 'capone', 'capone needs love!', 'capone is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fawn@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fawn@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('trudie', 'trudie@gmail.com', 'A user of PCS', 'trudiepw');
INSERT INTO PetOwners(email) VALUES ('trudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'alf', 'alf needs love!', 'alf is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'paco', 'paco needs love!', 'paco is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'holly', 'holly needs love!', 'holly is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trudie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'trudie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'trudie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'trudie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('rosmunda', 'rosmunda@gmail.com', 'A user of PCS', 'rosmundapw');
INSERT INTO PetOwners(email) VALUES ('rosmunda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'gilbert', 'gilbert needs love!', 'gilbert is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'emma', 'emma needs love!', 'emma is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'maggie-moo', 'maggie-moo needs love!', 'maggie-moo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'beetle', 'beetle needs love!', 'beetle is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ernaline', 'ernaline@gmail.com', 'A user of PCS', 'ernalinepw');
INSERT INTO PetOwners(email) VALUES ('ernaline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'junior', 'junior needs love!', 'junior is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'oliver', 'oliver needs love!', 'oliver is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'charlie brown', 'charlie brown needs love!', 'charlie brown is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'mindy', 'mindy needs love!', 'mindy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('mayne', 'mayne@gmail.com', 'A user of PCS', 'maynepw');
INSERT INTO PetOwners(email) VALUES ('mayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'dudley', 'dudley needs love!', 'dudley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'jj', 'jj needs love!', 'jj is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('stanislaus', 'stanislaus@gmail.com', 'A user of PCS', 'stanislauspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stanislaus@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'stanislaus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'stanislaus@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stanislaus@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stanislaus@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('kipper', 'kipper@gmail.com', 'A user of PCS', 'kipperpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kipper@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kipper@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kipper@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('aland', 'aland@gmail.com', 'A user of PCS', 'alandpw');
INSERT INTO PetOwners(email) VALUES ('aland@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'kona', 'kona needs love!', 'kona is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aland@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'aland@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aland@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('zach', 'zach@gmail.com', 'A user of PCS', 'zachpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zach@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'zach@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'zach@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'zach@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zach@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zach@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('carlynne', 'carlynne@gmail.com', 'A user of PCS', 'carlynnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carlynne@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'carlynne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'carlynne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carlynne@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('sharona', 'sharona@gmail.com', 'A user of PCS', 'sharonapw');
INSERT INTO PetOwners(email) VALUES ('sharona@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'patsy', 'patsy needs love!', 'patsy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'fluffy', 'fluffy needs love!', 'fluffy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('karrie', 'karrie@gmail.com', 'A user of PCS', 'karriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'karrie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'karrie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'karrie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('damara', 'damara@gmail.com', 'A user of PCS', 'damarapw');
INSERT INTO PetOwners(email) VALUES ('damara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('damara@gmail.com', 'rosa', 'rosa needs love!', 'rosa is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('damara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'damara@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('damara@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('damara@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('sullivan', 'sullivan@gmail.com', 'A user of PCS', 'sullivanpw');
INSERT INTO PetOwners(email) VALUES ('sullivan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sullivan@gmail.com', 'benji', 'benji needs love!', 'benji is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sullivan@gmail.com', 'bizzy', 'bizzy needs love!', 'bizzy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sullivan@gmail.com', 'bailey', 'bailey needs love!', 'bailey is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ed', 'ed@gmail.com', 'A user of PCS', 'edpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ed@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ed@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ed@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ed@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ed@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ed@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ed@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jorie', 'jorie@gmail.com', 'A user of PCS', 'joriepw');
INSERT INTO PetOwners(email) VALUES ('jorie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'flower', 'flower needs love!', 'flower is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'flakey', 'flakey needs love!', 'flakey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'skip', 'skip needs love!', 'skip is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jorie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'jorie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'jorie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'jorie@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorie@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('friedrick', 'friedrick@gmail.com', 'A user of PCS', 'friedrickpw');
INSERT INTO PetOwners(email) VALUES ('friedrick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('friedrick@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('friedrick@gmail.com', 'babykins', 'babykins needs love!', 'babykins is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('friedrick@gmail.com', 'pooh-bear', 'pooh-bear needs love!', 'pooh-bear is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('friedrick@gmail.com', 'parker', 'parker needs love!', 'parker is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('friedrick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'friedrick@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'friedrick@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'friedrick@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('beck', 'beck@gmail.com', 'A user of PCS', 'beckpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beck@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'beck@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (279, 'beck@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'beck@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'beck@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beck@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beck@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('marketa', 'marketa@gmail.com', 'A user of PCS', 'marketapw');
INSERT INTO PetOwners(email) VALUES ('marketa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marketa@gmail.com', 'ripley', 'ripley needs love!', 'ripley is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marketa@gmail.com', 'bailey', 'bailey needs love!', 'bailey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marketa@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marketa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'marketa@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('bobby', 'bobby@gmail.com', 'A user of PCS', 'bobbypw');
INSERT INTO PetOwners(email) VALUES ('bobby@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bobby@gmail.com', 'logan', 'logan needs love!', 'logan is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('guendolen', 'guendolen@gmail.com', 'A user of PCS', 'guendolenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('guendolen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'guendolen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'guendolen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'guendolen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'guendolen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'guendolen@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('guendolen@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('guendolen@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('paolo', 'paolo@gmail.com', 'A user of PCS', 'paolopw');
INSERT INTO PetOwners(email) VALUES ('paolo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paolo@gmail.com', 'meadow', 'meadow needs love!', 'meadow is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('hansiain', 'hansiain@gmail.com', 'A user of PCS', 'hansiainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hansiain@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'hansiain@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'hansiain@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hansiain@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hansiain@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('ola', 'ola@gmail.com', 'A user of PCS', 'olapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ola@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'ola@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'ola@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ola@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ola@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('camella', 'camella@gmail.com', 'A user of PCS', 'camellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'camella@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'camella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'camella@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'camella@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'camella@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camella@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('gerri', 'gerri@gmail.com', 'A user of PCS', 'gerripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gerri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'gerri@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'gerri@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'gerri@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'gerri@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'gerri@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gerri@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gerri@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('germayne', 'germayne@gmail.com', 'A user of PCS', 'germaynepw');
INSERT INTO PetOwners(email) VALUES ('germayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germayne@gmail.com', 'oreo', 'oreo needs love!', 'oreo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germayne@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('averil', 'averil@gmail.com', 'A user of PCS', 'averilpw');
INSERT INTO PetOwners(email) VALUES ('averil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'macy', 'macy needs love!', 'macy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'sheba', 'sheba needs love!', 'sheba is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'frisky', 'frisky needs love!', 'frisky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('erin', 'erin@gmail.com', 'A user of PCS', 'erinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'erin@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erin@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lindie', 'lindie@gmail.com', 'A user of PCS', 'lindiepw');
INSERT INTO PetOwners(email) VALUES ('lindie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lindie@gmail.com', 'pebbles', 'pebbles needs love!', 'pebbles is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('letizia', 'letizia@gmail.com', 'A user of PCS', 'letiziapw');
INSERT INTO PetOwners(email) VALUES ('letizia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letizia@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letizia@gmail.com', 'cody', 'cody needs love!', 'cody is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letizia@gmail.com', 'hope', 'hope needs love!', 'hope is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('letizia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'letizia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'letizia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'letizia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'letizia@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letizia@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('pail', 'pail@gmail.com', 'A user of PCS', 'pailpw');
INSERT INTO PetOwners(email) VALUES ('pail@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'mimi', 'mimi needs love!', 'mimi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('carmina', 'carmina@gmail.com', 'A user of PCS', 'carminapw');
INSERT INTO PetOwners(email) VALUES ('carmina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'flakey', 'flakey needs love!', 'flakey is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carmina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'carmina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carmina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'carmina@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmina@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tally', 'tally@gmail.com', 'A user of PCS', 'tallypw');
INSERT INTO PetOwners(email) VALUES ('tally@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tally@gmail.com', 'rowdy', 'rowdy needs love!', 'rowdy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tally@gmail.com', 'chessie', 'chessie needs love!', 'chessie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('gunilla', 'gunilla@gmail.com', 'A user of PCS', 'gunillapw');
INSERT INTO PetOwners(email) VALUES ('gunilla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gunilla@gmail.com', 'rags', 'rags needs love!', 'rags is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ab', 'ab@gmail.com', 'A user of PCS', 'abpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ab@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'ab@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'ab@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ab@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ab@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('garik', 'garik@gmail.com', 'A user of PCS', 'garikpw');
INSERT INTO PetOwners(email) VALUES ('garik@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'flash', 'flash needs love!', 'flash is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('cecil', 'cecil@gmail.com', 'A user of PCS', 'cecilpw');
INSERT INTO PetOwners(email) VALUES ('cecil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'kurly', 'kurly needs love!', 'kurly is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'pixie', 'pixie needs love!', 'pixie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'rosa', 'rosa needs love!', 'rosa is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'aj', 'aj needs love!', 'aj is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'king', 'king needs love!', 'king is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cecil@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cecil@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('maureen', 'maureen@gmail.com', 'A user of PCS', 'maureenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maureen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'maureen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'maureen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'maureen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'maureen@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'maureen@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maureen@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maureen@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('lucho', 'lucho@gmail.com', 'A user of PCS', 'luchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lucho@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'lucho@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('lazar', 'lazar@gmail.com', 'A user of PCS', 'lazarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lazar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'lazar@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lazar@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lazar@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('dinny', 'dinny@gmail.com', 'A user of PCS', 'dinnypw');
INSERT INTO PetOwners(email) VALUES ('dinny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dinny@gmail.com', 'charmer', 'charmer needs love!', 'charmer is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dinny@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dinny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dinny@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dinny@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dinny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dinny@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('winnah', 'winnah@gmail.com', 'A user of PCS', 'winnahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('winnah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'winnah@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'winnah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'winnah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'winnah@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('winnah@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ferdy', 'ferdy@gmail.com', 'A user of PCS', 'ferdypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferdy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ferdy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ferdy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ferdy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ferdy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ferdy@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('deena', 'deena@gmail.com', 'A user of PCS', 'deenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'deena@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deena@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deena@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('bart', 'bart@gmail.com', 'A user of PCS', 'bartpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bart@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'bart@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'bart@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bart@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bart@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('jaime', 'jaime@gmail.com', 'A user of PCS', 'jaimepw');
INSERT INTO PetOwners(email) VALUES ('jaime@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'dutches', 'dutches needs love!', 'dutches is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'mary', 'mary needs love!', 'mary is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'koko', 'koko needs love!', 'koko is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'nala', 'nala needs love!', 'nala is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('quent', 'quent@gmail.com', 'A user of PCS', 'quentpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('quent@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'quent@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'quent@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('quent@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('glennie', 'glennie@gmail.com', 'A user of PCS', 'glenniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glennie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'glennie@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glennie@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glennie@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('dosi', 'dosi@gmail.com', 'A user of PCS', 'dosipw');
INSERT INTO PetOwners(email) VALUES ('dosi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dosi@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('kalindi', 'kalindi@gmail.com', 'A user of PCS', 'kalindipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalindi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'kalindi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'kalindi@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalindi@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalindi@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('willette', 'willette@gmail.com', 'A user of PCS', 'willettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'willette@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'willette@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'willette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'willette@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willette@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willette@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('albertine', 'albertine@gmail.com', 'A user of PCS', 'albertinepw');
INSERT INTO PetOwners(email) VALUES ('albertine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'kid', 'kid needs love!', 'kid is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'grady', 'grady needs love!', 'grady is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'dottie', 'dottie needs love!', 'dottie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('albertine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'albertine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'albertine@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'albertine@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albertine@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('willyt', 'willyt@gmail.com', 'A user of PCS', 'willytpw');
INSERT INTO PetOwners(email) VALUES ('willyt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('isaiah', 'isaiah@gmail.com', 'A user of PCS', 'isaiahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isaiah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'isaiah@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isaiah@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isaiah@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('sigrid', 'sigrid@gmail.com', 'A user of PCS', 'sigridpw');
INSERT INTO PetOwners(email) VALUES ('sigrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'curly', 'curly needs love!', 'curly is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'julius', 'julius needs love!', 'julius is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'gretel', 'gretel needs love!', 'gretel is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'sarah', 'sarah needs love!', 'sarah is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('kendell', 'kendell@gmail.com', 'A user of PCS', 'kendellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kendell@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (186, 'kendell@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'kendell@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'kendell@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kendell@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kendell@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('cosette', 'cosette@gmail.com', 'A user of PCS', 'cosettepw');
INSERT INTO PetOwners(email) VALUES ('cosette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cosette@gmail.com', 'lili', 'lili needs love!', 'lili is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cosette@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cosette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cosette@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cosette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cosette@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cosette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cosette@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('barde', 'barde@gmail.com', 'A user of PCS', 'bardepw');
INSERT INTO PetOwners(email) VALUES ('barde@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'daphne', 'daphne needs love!', 'daphne is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'goose', 'goose needs love!', 'goose is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'ruffer', 'ruffer needs love!', 'ruffer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('krystle', 'krystle@gmail.com', 'A user of PCS', 'krystlepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krystle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'krystle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'krystle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'krystle@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jana', 'jana@gmail.com', 'A user of PCS', 'janapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'jana@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jana@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jana@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('gussy', 'gussy@gmail.com', 'A user of PCS', 'gussypw');
INSERT INTO PetOwners(email) VALUES ('gussy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'booster', 'booster needs love!', 'booster is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'axel', 'axel needs love!', 'axel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'claire', 'claire needs love!', 'claire is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'jojo', 'jojo needs love!', 'jojo is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gussy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gussy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gussy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gussy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gussy@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gussy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kienan', 'kienan@gmail.com', 'A user of PCS', 'kienanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kienan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (204, 'kienan@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'kienan@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'kienan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'kienan@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kienan@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kienan@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('justino', 'justino@gmail.com', 'A user of PCS', 'justinopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('justino@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'justino@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (243, 'justino@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'justino@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('justino@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('justino@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('teresa', 'teresa@gmail.com', 'A user of PCS', 'teresapw');
INSERT INTO PetOwners(email) VALUES ('teresa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teresa@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('teresa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'teresa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'teresa@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'teresa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'teresa@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('wake', 'wake@gmail.com', 'A user of PCS', 'wakepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wake@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'wake@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'wake@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wake@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wake@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('shelly', 'shelly@gmail.com', 'A user of PCS', 'shellypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelly@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (161, 'shelly@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'shelly@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelly@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelly@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('zedekiah', 'zedekiah@gmail.com', 'A user of PCS', 'zedekiahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zedekiah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'zedekiah@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'zedekiah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'zedekiah@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'zedekiah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'zedekiah@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zedekiah@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zedekiah@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('nonah', 'nonah@gmail.com', 'A user of PCS', 'nonahpw');
INSERT INTO PetOwners(email) VALUES ('nonah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonah@gmail.com', 'alexus', 'alexus needs love!', 'alexus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonah@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonah@gmail.com', 'prince', 'prince needs love!', 'prince is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonah@gmail.com', 'ranger', 'ranger needs love!', 'ranger is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('carley', 'carley@gmail.com', 'A user of PCS', 'carleypw');
INSERT INTO PetOwners(email) VALUES ('carley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'gretel', 'gretel needs love!', 'gretel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'checkers', 'checkers needs love!', 'checkers is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'champ', 'champ needs love!', 'champ is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carley@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carley@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'carley@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'carley@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'carley@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carley@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('bud', 'bud@gmail.com', 'A user of PCS', 'budpw');
INSERT INTO PetOwners(email) VALUES ('bud@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bud@gmail.com', 'mason', 'mason needs love!', 'mason is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bud@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bud@gmail.com', 'jesse james', 'jesse james needs love!', 'jesse james is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bud@gmail.com', 'rico', 'rico needs love!', 'rico is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('pincus', 'pincus@gmail.com', 'A user of PCS', 'pincuspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pincus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'pincus@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'pincus@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pincus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'pincus@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('garold', 'garold@gmail.com', 'A user of PCS', 'garoldpw');
INSERT INTO PetOwners(email) VALUES ('garold@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garold@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garold@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'garold@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'garold@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('analise', 'analise@gmail.com', 'A user of PCS', 'analisepw');
INSERT INTO PetOwners(email) VALUES ('analise@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'daphne', 'daphne needs love!', 'daphne is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'bj', 'bj needs love!', 'bj is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('coleman', 'coleman@gmail.com', 'A user of PCS', 'colemanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('coleman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'coleman@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'coleman@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'coleman@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'coleman@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'coleman@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coleman@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coleman@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('sauncho', 'sauncho@gmail.com', 'A user of PCS', 'saunchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sauncho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sauncho@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sauncho@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sauncho@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sauncho@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sauncho@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('wynn', 'wynn@gmail.com', 'A user of PCS', 'wynnpw');
INSERT INTO PetOwners(email) VALUES ('wynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynn@gmail.com', 'barker', 'barker needs love!', 'barker is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynn@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wynn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wynn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'wynn@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hatty', 'hatty@gmail.com', 'A user of PCS', 'hattypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hatty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'hatty@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hatty@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'hatty@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hatty@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hatty@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('kalila', 'kalila@gmail.com', 'A user of PCS', 'kalilapw');
INSERT INTO PetOwners(email) VALUES ('kalila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'ajax', 'ajax needs love!', 'ajax is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'jack', 'jack needs love!', 'jack is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'dragster', 'dragster needs love!', 'dragster is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('demetra', 'demetra@gmail.com', 'A user of PCS', 'demetrapw');
INSERT INTO PetOwners(email) VALUES ('demetra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'niki', 'niki needs love!', 'niki is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'armanti', 'armanti needs love!', 'armanti is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('del', 'del@gmail.com', 'A user of PCS', 'delpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('del@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'del@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'del@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('blisse', 'blisse@gmail.com', 'A user of PCS', 'blissepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('blisse@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'blisse@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('blisse@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('blisse@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('fayre', 'fayre@gmail.com', 'A user of PCS', 'fayrepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fayre@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'fayre@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'fayre@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'fayre@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'fayre@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fayre@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fayre@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('iggie', 'iggie@gmail.com', 'A user of PCS', 'iggiepw');
INSERT INTO PetOwners(email) VALUES ('iggie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('iggie@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iggie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'iggie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('lee', 'lee@gmail.com', 'A user of PCS', 'leepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'lee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'lee@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lee@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lee@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('bil', 'bil@gmail.com', 'A user of PCS', 'bilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (181, 'bil@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'bil@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bil@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bil@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('eugenio', 'eugenio@gmail.com', 'A user of PCS', 'eugeniopw');
INSERT INTO PetOwners(email) VALUES ('eugenio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'rock', 'rock needs love!', 'rock is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'ally', 'ally needs love!', 'ally is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'booster', 'booster needs love!', 'booster is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('gustaf', 'gustaf@gmail.com', 'A user of PCS', 'gustafpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gustaf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gustaf@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('dalila', 'dalila@gmail.com', 'A user of PCS', 'dalilapw');
INSERT INTO PetOwners(email) VALUES ('dalila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'curry', 'curry needs love!', 'curry is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'luke', 'luke needs love!', 'luke is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'jett', 'jett needs love!', 'jett is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dalila@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dalila@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dalila@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dalila@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalila@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('fanni', 'fanni@gmail.com', 'A user of PCS', 'fannipw');
INSERT INTO PetOwners(email) VALUES ('fanni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fanni@gmail.com', 'iris', 'iris needs love!', 'iris is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fanni@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'fanni@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'fanni@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'fanni@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'fanni@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (161, 'fanni@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fanni@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fanni@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('everett', 'everett@gmail.com', 'A user of PCS', 'everettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('everett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'everett@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('everett@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('everett@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('maryanna', 'maryanna@gmail.com', 'A user of PCS', 'maryannapw');
INSERT INTO PetOwners(email) VALUES ('maryanna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryanna@gmail.com', 'dickens', 'dickens needs love!', 'dickens is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryanna@gmail.com', 'flopsy', 'flopsy needs love!', 'flopsy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryanna@gmail.com', 'ricky', 'ricky needs love!', 'ricky is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maryanna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'maryanna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'maryanna@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryanna@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryanna@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('celesta', 'celesta@gmail.com', 'A user of PCS', 'celestapw');
INSERT INTO PetOwners(email) VALUES ('celesta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'bonnie', 'bonnie needs love!', 'bonnie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'linus', 'linus needs love!', 'linus is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'ralphie', 'ralphie needs love!', 'ralphie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('katharyn', 'katharyn@gmail.com', 'A user of PCS', 'katharynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katharyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'katharyn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'katharyn@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katharyn@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katharyn@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('rubin', 'rubin@gmail.com', 'A user of PCS', 'rubinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rubin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rubin@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rubin@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gawen', 'gawen@gmail.com', 'A user of PCS', 'gawenpw');
INSERT INTO PetOwners(email) VALUES ('gawen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gawen@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gawen@gmail.com', 'rover', 'rover needs love!', 'rover is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gawen@gmail.com', 'india', 'india needs love!', 'india is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ranee', 'ranee@gmail.com', 'A user of PCS', 'raneepw');
INSERT INTO PetOwners(email) VALUES ('ranee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ranee@gmail.com', 'crackers', 'crackers needs love!', 'crackers is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('ranna', 'ranna@gmail.com', 'A user of PCS', 'rannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ranna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ranna@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'ranna@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ranna@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ranna@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('bertha', 'bertha@gmail.com', 'A user of PCS', 'berthapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bertha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bertha@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bertha@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bertha@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'bertha@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertha@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('kathie', 'kathie@gmail.com', 'A user of PCS', 'kathiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kathie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kathie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kathie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kathie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kathie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kathie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('anetta', 'anetta@gmail.com', 'A user of PCS', 'anettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'anetta@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anetta@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anetta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('darci', 'darci@gmail.com', 'A user of PCS', 'darcipw');
INSERT INTO PetOwners(email) VALUES ('darci@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darci@gmail.com', 'noel', 'noel needs love!', 'noel is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darci@gmail.com', 'kane', 'kane needs love!', 'kane is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darci@gmail.com', 'little bit', 'little bit needs love!', 'little bit is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('mart', 'mart@gmail.com', 'A user of PCS', 'martpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mart@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mart@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'mart@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'mart@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'mart@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mart@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mart@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('claudina', 'claudina@gmail.com', 'A user of PCS', 'claudinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'claudina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'claudina@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudina@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudina@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('mariska', 'mariska@gmail.com', 'A user of PCS', 'mariskapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariska@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mariska@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mariska@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('deborah', 'deborah@gmail.com', 'A user of PCS', 'deborahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deborah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'deborah@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'deborah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'deborah@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deborah@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deborah@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('tova', 'tova@gmail.com', 'A user of PCS', 'tovapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tova@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tova@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('cheston', 'cheston@gmail.com', 'A user of PCS', 'chestonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cheston@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cheston@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cheston@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cheston@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cheston@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('nick', 'nick@gmail.com', 'A user of PCS', 'nickpw');
INSERT INTO PetOwners(email) VALUES ('nick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nick@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nick@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('yolane', 'yolane@gmail.com', 'A user of PCS', 'yolanepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yolane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'yolane@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yolane@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yolane@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('germana', 'germana@gmail.com', 'A user of PCS', 'germanapw');
INSERT INTO PetOwners(email) VALUES ('germana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germana@gmail.com', 'lincoln', 'lincoln needs love!', 'lincoln is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germana@gmail.com', 'deacon', 'deacon needs love!', 'deacon is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germana@gmail.com', 'mattie', 'mattie needs love!', 'mattie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('germana@gmail.com', 'ashley', 'ashley needs love!', 'ashley is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('germana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'germana@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'germana@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'germana@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'germana@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'germana@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('germana@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('germana@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('mariann', 'mariann@gmail.com', 'A user of PCS', 'mariannpw');
INSERT INTO PetOwners(email) VALUES ('mariann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariann@gmail.com', 'cobweb', 'cobweb needs love!', 'cobweb is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariann@gmail.com', 'erin', 'erin needs love!', 'erin is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('pollyanna', 'pollyanna@gmail.com', 'A user of PCS', 'pollyannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pollyanna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'pollyanna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'pollyanna@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pollyanna@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pollyanna@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('tallia', 'tallia@gmail.com', 'A user of PCS', 'talliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'tallia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tallia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallia@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('clarey', 'clarey@gmail.com', 'A user of PCS', 'clareypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clarey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'clarey@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'clarey@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clarey@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clarey@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('sammy', 'sammy@gmail.com', 'A user of PCS', 'sammypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sammy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'sammy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sammy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'sammy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'sammy@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sammy@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sammy@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('uriel', 'uriel@gmail.com', 'A user of PCS', 'urielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('uriel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'uriel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'uriel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (178, 'uriel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'uriel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'uriel@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('uriel@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('uriel@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('odelinda', 'odelinda@gmail.com', 'A user of PCS', 'odelindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odelinda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'odelinda@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (216, 'odelinda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'odelinda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'odelinda@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('robenia', 'robenia@gmail.com', 'A user of PCS', 'robeniapw');
INSERT INTO PetOwners(email) VALUES ('robenia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'scout', 'scout needs love!', 'scout is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('robenia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'robenia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'robenia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'robenia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robenia@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robenia@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('giuditta', 'giuditta@gmail.com', 'A user of PCS', 'giudittapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giuditta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'giuditta@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giuditta@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giuditta@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('millard', 'millard@gmail.com', 'A user of PCS', 'millardpw');
INSERT INTO PetOwners(email) VALUES ('millard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'rin tin tin', 'rin tin tin needs love!', 'rin tin tin is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'rocco', 'rocco needs love!', 'rocco is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('otho', 'otho@gmail.com', 'A user of PCS', 'othopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('otho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'otho@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'otho@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'otho@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'otho@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gav', 'gav@gmail.com', 'A user of PCS', 'gavpw');
INSERT INTO PetOwners(email) VALUES ('gav@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gav@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('elsi', 'elsi@gmail.com', 'A user of PCS', 'elsipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'elsi@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'elsi@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'elsi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'elsi@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tamqrah', 'tamqrah@gmail.com', 'A user of PCS', 'tamqrahpw');
INSERT INTO PetOwners(email) VALUES ('tamqrah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tamqrah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'tamqrah@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tamqrah@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tamqrah@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ramon', 'ramon@gmail.com', 'A user of PCS', 'ramonpw');
INSERT INTO PetOwners(email) VALUES ('ramon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'powder', 'powder needs love!', 'powder is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'gypsy', 'gypsy needs love!', 'gypsy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'mitch', 'mitch needs love!', 'mitch is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'pepe', 'pepe needs love!', 'pepe is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ramon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'ramon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'ramon@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ramon@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ramon@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('emily', 'emily@gmail.com', 'A user of PCS', 'emilypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emily@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'emily@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'emily@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'emily@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('salomone', 'salomone@gmail.com', 'A user of PCS', 'salomonepw');
INSERT INTO PetOwners(email) VALUES ('salomone@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('salomone@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('waverly', 'waverly@gmail.com', 'A user of PCS', 'waverlypw');
INSERT INTO PetOwners(email) VALUES ('waverly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'faith', 'faith needs love!', 'faith is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'hunter', 'hunter needs love!', 'hunter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('philly', 'philly@gmail.com', 'A user of PCS', 'phillypw');
INSERT INTO PetOwners(email) VALUES ('philly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philly@gmail.com', 'petie', 'petie needs love!', 'petie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philly@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philly@gmail.com', 'aussie', 'aussie needs love!', 'aussie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('philly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'philly@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'philly@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'philly@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philly@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('zilvia', 'zilvia@gmail.com', 'A user of PCS', 'zilviapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zilvia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'zilvia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'zilvia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'zilvia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zilvia@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zilvia@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('ronald', 'ronald@gmail.com', 'A user of PCS', 'ronaldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronald@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'ronald@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ronald@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronald@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronald@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('brana', 'brana@gmail.com', 'A user of PCS', 'branapw');
INSERT INTO PetOwners(email) VALUES ('brana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'mona', 'mona needs love!', 'mona is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'edgar', 'edgar needs love!', 'edgar is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'jake', 'jake needs love!', 'jake is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'patches', 'patches needs love!', 'patches is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'kona', 'kona needs love!', 'kona is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ketti', 'ketti@gmail.com', 'A user of PCS', 'kettipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ketti@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'ketti@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'ketti@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'ketti@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'ketti@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'ketti@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ketti@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ketti@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('demott', 'demott@gmail.com', 'A user of PCS', 'demottpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('demott@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'demott@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('demott@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('demott@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('daisi', 'daisi@gmail.com', 'A user of PCS', 'daisipw');
INSERT INTO PetOwners(email) VALUES ('daisi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daisi@gmail.com', 'jimmuy', 'jimmuy needs love!', 'jimmuy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daisi@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('rik', 'rik@gmail.com', 'A user of PCS', 'rikpw');
INSERT INTO PetOwners(email) VALUES ('rik@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rik@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rik@gmail.com', 'persy', 'persy needs love!', 'persy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rik@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rik@gmail.com', 'daisey-mae', 'daisey-mae needs love!', 'daisey-mae is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rik@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rik@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rik@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rik@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rik@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rik@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('theodoric', 'theodoric@gmail.com', 'A user of PCS', 'theodoricpw');
INSERT INTO PetOwners(email) VALUES ('theodoric@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theodoric@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theodoric@gmail.com', 'millie', 'millie needs love!', 'millie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theodoric@gmail.com', 'nick', 'nick needs love!', 'nick is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('murry', 'murry@gmail.com', 'A user of PCS', 'murrypw');
INSERT INTO PetOwners(email) VALUES ('murry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('murry@gmail.com', 'madison', 'madison needs love!', 'madison is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('murry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'murry@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murry@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murry@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('tallulah', 'tallulah@gmail.com', 'A user of PCS', 'tallulahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallulah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tallulah@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tallulah@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('idette', 'idette@gmail.com', 'A user of PCS', 'idettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'idette@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'idette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'idette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'idette@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idette@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idette@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ozzy', 'ozzy@gmail.com', 'A user of PCS', 'ozzypw');
INSERT INTO PetOwners(email) VALUES ('ozzy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ozzy@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ozzy@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ozzy@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ozzy@gmail.com', 'dutchess', 'dutchess needs love!', 'dutchess is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ilka', 'ilka@gmail.com', 'A user of PCS', 'ilkapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ilka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'ilka@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'ilka@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'ilka@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ilka@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ilka@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('phebe', 'phebe@gmail.com', 'A user of PCS', 'phebepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('phebe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'phebe@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('phebe@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('phebe@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('loralee', 'loralee@gmail.com', 'A user of PCS', 'loraleepw');
INSERT INTO PetOwners(email) VALUES ('loralee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('loralee@gmail.com', 'precious', 'precious needs love!', 'precious is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('loralee@gmail.com', 'barclay', 'barclay needs love!', 'barclay is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('haywood', 'haywood@gmail.com', 'A user of PCS', 'haywoodpw');
INSERT INTO PetOwners(email) VALUES ('haywood@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'prince', 'prince needs love!', 'prince is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'newt', 'newt needs love!', 'newt is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('haywood@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'haywood@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'haywood@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haywood@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haywood@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('reggi', 'reggi@gmail.com', 'A user of PCS', 'reggipw');
INSERT INTO PetOwners(email) VALUES ('reggi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reggi@gmail.com', 'hershey', 'hershey needs love!', 'hershey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reggi@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reggi@gmail.com', 'booker', 'booker needs love!', 'booker is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reggi@gmail.com', 'pluto', 'pluto needs love!', 'pluto is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('shandra', 'shandra@gmail.com', 'A user of PCS', 'shandrapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandra@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'shandra@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shandra@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandra@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jane', 'jane@gmail.com', 'A user of PCS', 'janepw');
INSERT INTO PetOwners(email) VALUES ('jane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'jazz', 'jazz needs love!', 'jazz is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'skip', 'skip needs love!', 'skip is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('mandy', 'mandy@gmail.com', 'A user of PCS', 'mandypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mandy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'mandy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'mandy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'mandy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'mandy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'mandy@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandy@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('gideon', 'gideon@gmail.com', 'A user of PCS', 'gideonpw');
INSERT INTO PetOwners(email) VALUES ('gideon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gideon@gmail.com', 'beans', 'beans needs love!', 'beans is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gideon@gmail.com', 'aries', 'aries needs love!', 'aries is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gideon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'gideon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gideon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'gideon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'gideon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'gideon@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gideon@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gideon@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('ava', 'ava@gmail.com', 'A user of PCS', 'avapw');
INSERT INTO PetOwners(email) VALUES ('ava@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'mona', 'mona needs love!', 'mona is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'panda', 'panda needs love!', 'panda is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ava@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ava@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ava@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ava@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ava@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ava@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('eugene', 'eugene@gmail.com', 'A user of PCS', 'eugenepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eugene@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'eugene@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('samaria', 'samaria@gmail.com', 'A user of PCS', 'samariapw');
INSERT INTO PetOwners(email) VALUES ('samaria@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('samaria@gmail.com', 'bonnie', 'bonnie needs love!', 'bonnie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('boonie', 'boonie@gmail.com', 'A user of PCS', 'booniepw');
INSERT INTO PetOwners(email) VALUES ('boonie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boonie@gmail.com', 'mitch', 'mitch needs love!', 'mitch is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boonie@gmail.com', 'chic', 'chic needs love!', 'chic is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boonie@gmail.com', 'bacchus', 'bacchus needs love!', 'bacchus is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('breanne', 'breanne@gmail.com', 'A user of PCS', 'breannepw');
INSERT INTO PetOwners(email) VALUES ('breanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'ashes', 'ashes needs love!', 'ashes is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'chyna', 'chyna needs love!', 'chyna is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('shelden', 'shelden@gmail.com', 'A user of PCS', 'sheldenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelden@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'shelden@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'shelden@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('britte', 'britte@gmail.com', 'A user of PCS', 'brittepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('britte@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'britte@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'britte@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'britte@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('britte@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('carrissa', 'carrissa@gmail.com', 'A user of PCS', 'carrissapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrissa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carrissa@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'carrissa@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'carrissa@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrissa@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jenni', 'jenni@gmail.com', 'A user of PCS', 'jennipw');
INSERT INTO PetOwners(email) VALUES ('jenni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenni@gmail.com', 'camille', 'camille needs love!', 'camille is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenni@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenni@gmail.com', 'bradley', 'bradley needs love!', 'bradley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenni@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenni@gmail.com', 'opie', 'opie needs love!', 'opie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenni@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'jenni@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'jenni@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'jenni@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenni@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenni@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('darcey', 'darcey@gmail.com', 'A user of PCS', 'darceypw');
INSERT INTO PetOwners(email) VALUES ('darcey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'luci', 'luci needs love!', 'luci is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'pooh-bear', 'pooh-bear needs love!', 'pooh-bear is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'comet', 'comet needs love!', 'comet is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('farlie', 'farlie@gmail.com', 'A user of PCS', 'farliepw');
INSERT INTO PetOwners(email) VALUES ('farlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'alex', 'alex needs love!', 'alex is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'checkers', 'checkers needs love!', 'checkers is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'caesar', 'caesar needs love!', 'caesar is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('rafi', 'rafi@gmail.com', 'A user of PCS', 'rafipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rafi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rafi@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('odey', 'odey@gmail.com', 'A user of PCS', 'odeypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'odey@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odey@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odey@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('juliane', 'juliane@gmail.com', 'A user of PCS', 'julianepw');
INSERT INTO PetOwners(email) VALUES ('juliane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'digger', 'digger needs love!', 'digger is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'latte', 'latte needs love!', 'latte is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'duke', 'duke needs love!', 'duke is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('angel', 'angel@gmail.com', 'A user of PCS', 'angelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('angel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'angel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'angel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('angel@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('angel@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('kris', 'kris@gmail.com', 'A user of PCS', 'krispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kris@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'kris@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kris@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'kris@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'kris@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'kris@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kris@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kris@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('gabby', 'gabby@gmail.com', 'A user of PCS', 'gabbypw');
INSERT INTO PetOwners(email) VALUES ('gabby@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabby@gmail.com', 'cha cha', 'cha cha needs love!', 'cha cha is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabby@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabby@gmail.com', 'nico', 'nico needs love!', 'nico is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabby@gmail.com', 'brie', 'brie needs love!', 'brie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabby@gmail.com', 'mack', 'mack needs love!', 'mack is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('idalia', 'idalia@gmail.com', 'A user of PCS', 'idaliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idalia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'idalia@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('carr', 'carr@gmail.com', 'A user of PCS', 'carrpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carr@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'carr@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'carr@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'carr@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (185, 'carr@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carr@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carr@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('nari', 'nari@gmail.com', 'A user of PCS', 'naripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nari@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'nari@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'nari@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'nari@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nari@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nari@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nari@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('leesa', 'leesa@gmail.com', 'A user of PCS', 'leesapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leesa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'leesa@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('zonda', 'zonda@gmail.com', 'A user of PCS', 'zondapw');
INSERT INTO PetOwners(email) VALUES ('zonda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'augie', 'augie needs love!', 'augie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'francais', 'francais needs love!', 'francais is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zonda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'zonda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'zonda@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'zonda@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zonda@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zonda@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dwight', 'dwight@gmail.com', 'A user of PCS', 'dwightpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dwight@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dwight@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dwight@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dwight@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dwight@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jyoti', 'jyoti@gmail.com', 'A user of PCS', 'jyotipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jyoti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jyoti@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jyoti@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('brina', 'brina@gmail.com', 'A user of PCS', 'brinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'brina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'brina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (209, 'brina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'brina@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brina@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brina@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('emanuele', 'emanuele@gmail.com', 'A user of PCS', 'emanuelepw');
INSERT INTO PetOwners(email) VALUES ('emanuele@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'princess', 'princess needs love!', 'princess is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'roland', 'roland needs love!', 'roland is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'lightning', 'lightning needs love!', 'lightning is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'rover', 'rover needs love!', 'rover is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jandy', 'jandy@gmail.com', 'A user of PCS', 'jandypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jandy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jandy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jandy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jandy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jandy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jandy@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('xenia', 'xenia@gmail.com', 'A user of PCS', 'xeniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xenia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'xenia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'xenia@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('laina', 'laina@gmail.com', 'A user of PCS', 'lainapw');
INSERT INTO PetOwners(email) VALUES ('laina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'libby', 'libby needs love!', 'libby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'patches', 'patches needs love!', 'patches is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('candy', 'candy@gmail.com', 'A user of PCS', 'candypw');
INSERT INTO PetOwners(email) VALUES ('candy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('candy@gmail.com', 'june', 'june needs love!', 'june is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('candy@gmail.com', 'laney', 'laney needs love!', 'laney is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('candy@gmail.com', 'moochie', 'moochie needs love!', 'moochie is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('dianemarie', 'dianemarie@gmail.com', 'A user of PCS', 'dianemariepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dianemarie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'dianemarie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dianemarie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'dianemarie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dianemarie@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dianemarie@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('gilly', 'gilly@gmail.com', 'A user of PCS', 'gillypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gilly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gilly@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gilly@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gilly@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('wylma', 'wylma@gmail.com', 'A user of PCS', 'wylmapw');
INSERT INTO PetOwners(email) VALUES ('wylma@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wylma@gmail.com', 'booker', 'booker needs love!', 'booker is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wylma@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('estella', 'estella@gmail.com', 'A user of PCS', 'estellapw');
INSERT INTO PetOwners(email) VALUES ('estella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estella@gmail.com', 'barker', 'barker needs love!', 'barker is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'estella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'estella@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'estella@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'estella@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('giacobo', 'giacobo@gmail.com', 'A user of PCS', 'giacobopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giacobo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'giacobo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'giacobo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'giacobo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'giacobo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'giacobo@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('zebulen', 'zebulen@gmail.com', 'A user of PCS', 'zebulenpw');
INSERT INTO PetOwners(email) VALUES ('zebulen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zebulen@gmail.com', 'beamer', 'beamer needs love!', 'beamer is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zebulen@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zebulen@gmail.com', 'amos', 'amos needs love!', 'amos is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zebulen@gmail.com', 'ryder', 'ryder needs love!', 'ryder is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zebulen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'zebulen@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('henrietta', 'henrietta@gmail.com', 'A user of PCS', 'henriettapw');
INSERT INTO PetOwners(email) VALUES ('henrietta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'noel', 'noel needs love!', 'noel is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'arrow', 'arrow needs love!', 'arrow is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('henrietta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'henrietta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'henrietta@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'henrietta@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('rona', 'rona@gmail.com', 'A user of PCS', 'ronapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rona@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (270, 'rona@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'rona@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rona@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rona@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('reynolds', 'reynolds@gmail.com', 'A user of PCS', 'reynoldspw');
INSERT INTO PetOwners(email) VALUES ('reynolds@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'cheyenne', 'cheyenne needs love!', 'cheyenne is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('denny', 'denny@gmail.com', 'A user of PCS', 'dennypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'denny@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'denny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'denny@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'denny@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('roanne', 'roanne@gmail.com', 'A user of PCS', 'roannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roanne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'roanne@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roanne@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('thorn', 'thorn@gmail.com', 'A user of PCS', 'thornpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('thorn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'thorn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'thorn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'thorn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'thorn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'thorn@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thorn@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thorn@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('cletus', 'cletus@gmail.com', 'A user of PCS', 'cletuspw');
INSERT INTO PetOwners(email) VALUES ('cletus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cletus@gmail.com', 'belle', 'belle needs love!', 'belle is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cletus@gmail.com', 'sky', 'sky needs love!', 'sky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cletus@gmail.com', 'genie', 'genie needs love!', 'genie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cletus@gmail.com', 'hamlet', 'hamlet needs love!', 'hamlet is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cletus@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'cletus@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cletus@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'cletus@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cletus@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cletus@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('fairfax', 'fairfax@gmail.com', 'A user of PCS', 'fairfaxpw');
INSERT INTO PetOwners(email) VALUES ('fairfax@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'louie', 'louie needs love!', 'louie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'hope', 'hope needs love!', 'hope is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'brie', 'brie needs love!', 'brie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'gypsy', 'gypsy needs love!', 'gypsy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'dinky', 'dinky needs love!', 'dinky is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('gayler', 'gayler@gmail.com', 'A user of PCS', 'gaylerpw');
INSERT INTO PetOwners(email) VALUES ('gayler@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gayler@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'gayler@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'gayler@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gayler@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gayler@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('filmer', 'filmer@gmail.com', 'A user of PCS', 'filmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filmer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'filmer@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (230, 'filmer@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'filmer@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (234, 'filmer@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('coraline', 'coraline@gmail.com', 'A user of PCS', 'coralinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('coraline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'coraline@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'coraline@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coraline@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coraline@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('oralle', 'oralle@gmail.com', 'A user of PCS', 'orallepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('oralle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (236, 'oralle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'oralle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'oralle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oralle@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oralle@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('shannah', 'shannah@gmail.com', 'A user of PCS', 'shannahpw');
INSERT INTO PetOwners(email) VALUES ('shannah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shannah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shannah@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shannah@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shannah@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('dylan', 'dylan@gmail.com', 'A user of PCS', 'dylanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dylan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'dylan@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dylan@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dylan@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('shamus', 'shamus@gmail.com', 'A user of PCS', 'shamuspw');
INSERT INTO PetOwners(email) VALUES ('shamus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'kramer', 'kramer needs love!', 'kramer is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'ozzie', 'ozzie needs love!', 'ozzie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'reilly', 'reilly needs love!', 'reilly is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('papageno', 'papageno@gmail.com', 'A user of PCS', 'papagenopw');
INSERT INTO PetOwners(email) VALUES ('papageno@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('papageno@gmail.com', 'ace', 'ace needs love!', 'ace is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('papageno@gmail.com', 'slick', 'slick needs love!', 'slick is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('papageno@gmail.com', 'scottie', 'scottie needs love!', 'scottie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('papageno@gmail.com', 'chic', 'chic needs love!', 'chic is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('papageno@gmail.com', 'bootie', 'bootie needs love!', 'bootie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('sunny', 'sunny@gmail.com', 'A user of PCS', 'sunnypw');
INSERT INTO PetOwners(email) VALUES ('sunny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sunny@gmail.com', 'nona', 'nona needs love!', 'nona is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sunny@gmail.com', 'dino', 'dino needs love!', 'dino is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sunny@gmail.com', 'max', 'max needs love!', 'max is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sunny@gmail.com', 'genie', 'genie needs love!', 'genie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('anderson', 'anderson@gmail.com', 'A user of PCS', 'andersonpw');
INSERT INTO PetOwners(email) VALUES ('anderson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anderson@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'anderson@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'anderson@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'anderson@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'anderson@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anderson@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anderson@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('tarrah', 'tarrah@gmail.com', 'A user of PCS', 'tarrahpw');
INSERT INTO PetOwners(email) VALUES ('tarrah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'boy', 'boy needs love!', 'boy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'oz', 'oz needs love!', 'oz is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'sable', 'sable needs love!', 'sable is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'hanna', 'hanna needs love!', 'hanna is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('francis', 'francis@gmail.com', 'A user of PCS', 'francispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'francis@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francis@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francis@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('wilie', 'wilie@gmail.com', 'A user of PCS', 'wiliepw');
INSERT INTO PetOwners(email) VALUES ('wilie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('wain', 'wain@gmail.com', 'A user of PCS', 'wainpw');
INSERT INTO PetOwners(email) VALUES ('wain@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wain@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'wain@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wain@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wain@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('adriena', 'adriena@gmail.com', 'A user of PCS', 'adrienapw');
INSERT INTO PetOwners(email) VALUES ('adriena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'nickers', 'nickers needs love!', 'nickers is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'bailey', 'bailey needs love!', 'bailey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'oakley', 'oakley needs love!', 'oakley is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'silver', 'silver needs love!', 'silver is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adriena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'adriena@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'adriena@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriena@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriena@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('francyne', 'francyne@gmail.com', 'A user of PCS', 'francynepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francyne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'francyne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'francyne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'francyne@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'francyne@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'francyne@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francyne@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tyson', 'tyson@gmail.com', 'A user of PCS', 'tysonpw');
INSERT INTO PetOwners(email) VALUES ('tyson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'smarty', 'smarty needs love!', 'smarty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'brook', 'brook needs love!', 'brook is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'cyrus', 'cyrus needs love!', 'cyrus is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tyson@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'tyson@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'tyson@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (253, 'tyson@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'tyson@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyson@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyson@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('leda', 'leda@gmail.com', 'A user of PCS', 'ledapw');
INSERT INTO PetOwners(email) VALUES ('leda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'abel', 'abel needs love!', 'abel is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'leda@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leda@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leda@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('jo', 'jo@gmail.com', 'A user of PCS', 'jopw');
INSERT INTO PetOwners(email) VALUES ('jo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'blossom', 'blossom needs love!', 'blossom is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'nona', 'nona needs love!', 'nona is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'ruthie', 'ruthie needs love!', 'ruthie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'cassis', 'cassis needs love!', 'cassis is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'murphy', 'murphy needs love!', 'murphy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('milicent', 'milicent@gmail.com', 'A user of PCS', 'milicentpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milicent@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'milicent@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'milicent@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milicent@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milicent@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('donielle', 'donielle@gmail.com', 'A user of PCS', 'doniellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donielle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'donielle@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'donielle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'donielle@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donielle@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('sancho', 'sancho@gmail.com', 'A user of PCS', 'sanchopw');
INSERT INTO PetOwners(email) VALUES ('sancho@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sancho@gmail.com', 'kissy', 'kissy needs love!', 'kissy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sancho@gmail.com', 'captain', 'captain needs love!', 'captain is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('arley', 'arley@gmail.com', 'A user of PCS', 'arleypw');
INSERT INTO PetOwners(email) VALUES ('arley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'goose', 'goose needs love!', 'goose is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('thea', 'thea@gmail.com', 'A user of PCS', 'theapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('thea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'thea@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'thea@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'thea@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thea@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('syman', 'syman@gmail.com', 'A user of PCS', 'symanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('syman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'syman@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('kennett', 'kennett@gmail.com', 'A user of PCS', 'kennettpw');
INSERT INTO PetOwners(email) VALUES ('kennett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennett@gmail.com', 'butch', 'butch needs love!', 'butch is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennett@gmail.com', 'big boy', 'big boy needs love!', 'big boy is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennett@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kennett@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('brianne', 'brianne@gmail.com', 'A user of PCS', 'briannepw');
INSERT INTO PetOwners(email) VALUES ('brianne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianne@gmail.com', 'georgie', 'georgie needs love!', 'georgie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianne@gmail.com', 'genie', 'genie needs love!', 'genie is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brianne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'brianne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'brianne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'brianne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'brianne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'brianne@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('sutton', 'sutton@gmail.com', 'A user of PCS', 'suttonpw');
INSERT INTO PetOwners(email) VALUES ('sutton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'paddy', 'paddy needs love!', 'paddy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'oakley', 'oakley needs love!', 'oakley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'blossom', 'blossom needs love!', 'blossom is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'ozzy', 'ozzy needs love!', 'ozzy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('hyacinth', 'hyacinth@gmail.com', 'A user of PCS', 'hyacinthpw');
INSERT INTO PetOwners(email) VALUES ('hyacinth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hyacinth@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hyacinth@gmail.com', 'paco', 'paco needs love!', 'paco is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hyacinth@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'hyacinth@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'hyacinth@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'hyacinth@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'hyacinth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hyacinth@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hyacinth@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hyacinth@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('chanda', 'chanda@gmail.com', 'A user of PCS', 'chandapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chanda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'chanda@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chanda@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chanda@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('dasie', 'dasie@gmail.com', 'A user of PCS', 'dasiepw');
INSERT INTO PetOwners(email) VALUES ('dasie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dasie@gmail.com', 'ruger', 'ruger needs love!', 'ruger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dasie@gmail.com', 'lincoln', 'lincoln needs love!', 'lincoln is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dasie@gmail.com', 'julius', 'julius needs love!', 'julius is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dasie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'dasie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'dasie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'dasie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'dasie@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dasie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dasie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('jocko', 'jocko@gmail.com', 'A user of PCS', 'jockopw');
INSERT INTO PetOwners(email) VALUES ('jocko@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'doogie', 'doogie needs love!', 'doogie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'jingles', 'jingles needs love!', 'jingles is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jocko@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jocko@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('randa', 'randa@gmail.com', 'A user of PCS', 'randapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('randa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'randa@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'randa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'randa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'randa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'randa@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gertrude', 'gertrude@gmail.com', 'A user of PCS', 'gertrudepw');
INSERT INTO PetOwners(email) VALUES ('gertrude@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'rosy', 'rosy needs love!', 'rosy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'itsy', 'itsy needs love!', 'itsy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('tanhya', 'tanhya@gmail.com', 'A user of PCS', 'tanhyapw');
INSERT INTO PetOwners(email) VALUES ('tanhya@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'china', 'china needs love!', 'china is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'pip-squeek', 'pip-squeek needs love!', 'pip-squeek is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('laverne', 'laverne@gmail.com', 'A user of PCS', 'lavernepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laverne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'laverne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (241, 'laverne@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laverne@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laverne@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('jessica', 'jessica@gmail.com', 'A user of PCS', 'jessicapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessica@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'jessica@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'jessica@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'jessica@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessica@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessica@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('yoshiko', 'yoshiko@gmail.com', 'A user of PCS', 'yoshikopw');
INSERT INTO PetOwners(email) VALUES ('yoshiko@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yoshiko@gmail.com', 'faith', 'faith needs love!', 'faith is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yoshiko@gmail.com', 'pete', 'pete needs love!', 'pete is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yoshiko@gmail.com', 'aries', 'aries needs love!', 'aries is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yoshiko@gmail.com', 'baby', 'baby needs love!', 'baby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yoshiko@gmail.com', 'chaos', 'chaos needs love!', 'chaos is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yoshiko@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'yoshiko@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'yoshiko@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('doralynne', 'doralynne@gmail.com', 'A user of PCS', 'doralynnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('doralynne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'doralynne@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('doralynne@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('doralynne@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('yankee', 'yankee@gmail.com', 'A user of PCS', 'yankeepw');
INSERT INTO PetOwners(email) VALUES ('yankee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yankee@gmail.com', 'montgomery', 'montgomery needs love!', 'montgomery is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yankee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'yankee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'yankee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (209, 'yankee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'yankee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (185, 'yankee@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yankee@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yankee@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('otto', 'otto@gmail.com', 'A user of PCS', 'ottopw');
INSERT INTO PetOwners(email) VALUES ('otto@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'gavin', 'gavin needs love!', 'gavin is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'amber', 'amber needs love!', 'amber is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'casper', 'casper needs love!', 'casper is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('otto@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'otto@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('goran', 'goran@gmail.com', 'A user of PCS', 'goranpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('goran@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'goran@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'goran@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'goran@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'goran@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goran@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('donnamarie', 'donnamarie@gmail.com', 'A user of PCS', 'donnamariepw');
INSERT INTO PetOwners(email) VALUES ('donnamarie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnamarie@gmail.com', 'aries', 'aries needs love!', 'aries is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnamarie@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnamarie@gmail.com', 'koba', 'koba needs love!', 'koba is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donnamarie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'donnamarie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'donnamarie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnamarie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnamarie@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('kinna', 'kinna@gmail.com', 'A user of PCS', 'kinnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kinna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kinna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kinna@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kinna@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kinna@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('byrom', 'byrom@gmail.com', 'A user of PCS', 'byrompw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrom@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'byrom@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'byrom@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'byrom@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'byrom@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrom@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrom@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('lois', 'lois@gmail.com', 'A user of PCS', 'loispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lois@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lois@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gui', 'gui@gmail.com', 'A user of PCS', 'guipw');
INSERT INTO PetOwners(email) VALUES ('gui@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'boss', 'boss needs love!', 'boss is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'sam', 'sam needs love!', 'sam is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('kerri', 'kerri@gmail.com', 'A user of PCS', 'kerripw');
INSERT INTO PetOwners(email) VALUES ('kerri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerri@gmail.com', 'chewy', 'chewy needs love!', 'chewy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerri@gmail.com', 'jaxson', 'jaxson needs love!', 'jaxson is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerri@gmail.com', 'kane', 'kane needs love!', 'kane is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerri@gmail.com', 'jags', 'jags needs love!', 'jags is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kerri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'kerri@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'kerri@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'kerri@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'kerri@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('gilli', 'gilli@gmail.com', 'A user of PCS', 'gillipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gilli@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gilli@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gilli@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gilli@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gilli@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilli@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('montague', 'montague@gmail.com', 'A user of PCS', 'montaguepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('montague@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'montague@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('montague@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cary', 'cary@gmail.com', 'A user of PCS', 'carypw');
INSERT INTO PetOwners(email) VALUES ('cary@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'henry', 'henry needs love!', 'henry is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'mackenzie', 'mackenzie needs love!', 'mackenzie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cary@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'cary@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'cary@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cary@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cary@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('nichole', 'nichole@gmail.com', 'A user of PCS', 'nicholepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nichole@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'nichole@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nichole@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nichole@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ogden', 'ogden@gmail.com', 'A user of PCS', 'ogdenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ogden@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'ogden@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ogden@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ogden@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('cherri', 'cherri@gmail.com', 'A user of PCS', 'cherripw');
INSERT INTO PetOwners(email) VALUES ('cherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'babbles', 'babbles needs love!', 'babbles is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('brennen', 'brennen@gmail.com', 'A user of PCS', 'brennenpw');
INSERT INTO PetOwners(email) VALUES ('brennen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'june', 'june needs love!', 'june is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'nibby-nose', 'nibby-nose needs love!', 'nibby-nose is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brennen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'brennen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'brennen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'brennen@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brennen@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brennen@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('egor', 'egor@gmail.com', 'A user of PCS', 'egorpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('egor@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'egor@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'egor@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egor@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egor@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shellysheldon', 'shellysheldon@gmail.com', 'A user of PCS', 'shellysheldonpw');
INSERT INTO PetOwners(email) VALUES ('shellysheldon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'aldo', 'aldo needs love!', 'aldo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'prince', 'prince needs love!', 'prince is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shellysheldon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shellysheldon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'shellysheldon@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shellysheldon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'shellysheldon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shellysheldon@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ulises', 'ulises@gmail.com', 'A user of PCS', 'ulisespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulises@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ulises@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ulises@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ulises@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ulises@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('thomasina', 'thomasina@gmail.com', 'A user of PCS', 'thomasinapw');
INSERT INTO PetOwners(email) VALUES ('thomasina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'figaro', 'figaro needs love!', 'figaro is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'boo', 'boo needs love!', 'boo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'bozley', 'bozley needs love!', 'bozley is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'laney', 'laney needs love!', 'laney is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('modesty', 'modesty@gmail.com', 'A user of PCS', 'modestypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('modesty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'modesty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (272, 'modesty@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('modesty@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('modesty@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('maurizia', 'maurizia@gmail.com', 'A user of PCS', 'mauriziapw');
INSERT INTO PetOwners(email) VALUES ('maurizia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('erich', 'erich@gmail.com', 'A user of PCS', 'erichpw');
INSERT INTO PetOwners(email) VALUES ('erich@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erich@gmail.com', 'ranger', 'ranger needs love!', 'ranger is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('robinia', 'robinia@gmail.com', 'A user of PCS', 'robiniapw');
INSERT INTO PetOwners(email) VALUES ('robinia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'howie', 'howie needs love!', 'howie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'casper', 'casper needs love!', 'casper is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'domino', 'domino needs love!', 'domino is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'cubs', 'cubs needs love!', 'cubs is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('ulrike', 'ulrike@gmail.com', 'A user of PCS', 'ulrikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulrike@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ulrike@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrike@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('giana', 'giana@gmail.com', 'A user of PCS', 'gianapw');
INSERT INTO PetOwners(email) VALUES ('giana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giana@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giana@gmail.com', 'jelly', 'jelly needs love!', 'jelly is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giana@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'giana@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giana@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giana@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('xenos', 'xenos@gmail.com', 'A user of PCS', 'xenospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xenos@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'xenos@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'xenos@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'xenos@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'xenos@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenos@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ferdie', 'ferdie@gmail.com', 'A user of PCS', 'ferdiepw');
INSERT INTO PetOwners(email) VALUES ('ferdie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'doc', 'doc needs love!', 'doc is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'amos', 'amos needs love!', 'amos is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('starlin', 'starlin@gmail.com', 'A user of PCS', 'starlinpw');
INSERT INTO PetOwners(email) VALUES ('starlin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'furball', 'furball needs love!', 'furball is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'barney', 'barney needs love!', 'barney is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'boss', 'boss needs love!', 'boss is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('starlin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (245, 'starlin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'starlin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (183, 'starlin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'starlin@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('starlin@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('starlin@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('gabriellia', 'gabriellia@gmail.com', 'A user of PCS', 'gabrielliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gabriellia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'gabriellia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gabriellia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gabriellia@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('randie', 'randie@gmail.com', 'A user of PCS', 'randiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('randie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'randie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'randie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'randie@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jewel', 'jewel@gmail.com', 'A user of PCS', 'jewelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jewel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'jewel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'jewel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jewel@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jewel@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('xylia', 'xylia@gmail.com', 'A user of PCS', 'xyliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xylia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'xylia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'xylia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'xylia@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xylia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xylia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('tresa', 'tresa@gmail.com', 'A user of PCS', 'tresapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tresa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'tresa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'tresa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'tresa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'tresa@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tresa@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tresa@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('inness', 'inness@gmail.com', 'A user of PCS', 'innesspw');
INSERT INTO PetOwners(email) VALUES ('inness@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'cinder', 'cinder needs love!', 'cinder is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'henry', 'henry needs love!', 'henry is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'flopsy', 'flopsy needs love!', 'flopsy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('inness@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'inness@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'inness@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'inness@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('inness@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('inness@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('michele', 'michele@gmail.com', 'A user of PCS', 'michelepw');
INSERT INTO PetOwners(email) VALUES ('michele@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'reggie', 'reggie needs love!', 'reggie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'clicker', 'clicker needs love!', 'clicker is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'friday', 'friday needs love!', 'friday is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michele@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'michele@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'michele@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'michele@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michele@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mirabel', 'mirabel@gmail.com', 'A user of PCS', 'mirabelpw');
INSERT INTO PetOwners(email) VALUES ('mirabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mirabel@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mirabel@gmail.com', 'maxwell', 'maxwell needs love!', 'maxwell is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('patton', 'patton@gmail.com', 'A user of PCS', 'pattonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'patton@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'patton@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patton@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patton@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('trudi', 'trudi@gmail.com', 'A user of PCS', 'trudipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trudi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'trudi@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'trudi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'trudi@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tiffanie', 'tiffanie@gmail.com', 'A user of PCS', 'tiffaniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiffanie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'tiffanie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'tiffanie@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tiffanie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tiffanie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('minor', 'minor@gmail.com', 'A user of PCS', 'minorpw');
INSERT INTO PetOwners(email) VALUES ('minor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'sky', 'sky needs love!', 'sky is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'louis', 'louis needs love!', 'louis is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('sorcha', 'sorcha@gmail.com', 'A user of PCS', 'sorchapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sorcha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'sorcha@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'sorcha@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'sorcha@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'sorcha@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'sorcha@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sorcha@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sorcha@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('alma', 'alma@gmail.com', 'A user of PCS', 'almapw');
INSERT INTO PetOwners(email) VALUES ('alma@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alma@gmail.com', 'freddy', 'freddy needs love!', 'freddy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alma@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alma@gmail.com', 'ruffles', 'ruffles needs love!', 'ruffles is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alma@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alma@gmail.com', 'furball', 'furball needs love!', 'furball is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'alma@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('alexandros', 'alexandros@gmail.com', 'A user of PCS', 'alexandrospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alexandros@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alexandros@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alexandros@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('kalvin', 'kalvin@gmail.com', 'A user of PCS', 'kalvinpw');
INSERT INTO PetOwners(email) VALUES ('kalvin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalvin@gmail.com', 'bully', 'bully needs love!', 'bully is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('cinnamon', 'cinnamon@gmail.com', 'A user of PCS', 'cinnamonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cinnamon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'cinnamon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'cinnamon@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cinnamon@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cinnamon@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('daron', 'daron@gmail.com', 'A user of PCS', 'daronpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('daron@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'daron@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'daron@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('daron@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('daron@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcia', 'marcia@gmail.com', 'A user of PCS', 'marciapw');
INSERT INTO PetOwners(email) VALUES ('marcia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcia@gmail.com', 'june', 'june needs love!', 'june is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'marcia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marcia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marcia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marcia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marcia@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcia@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('cora', 'cora@gmail.com', 'A user of PCS', 'corapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cora@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cora@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ryun', 'ryun@gmail.com', 'A user of PCS', 'ryunpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ryun@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ryun@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ryun@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ryun@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('maximo', 'maximo@gmail.com', 'A user of PCS', 'maximopw');
INSERT INTO PetOwners(email) VALUES ('maximo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maximo@gmail.com', 'mitzy', 'mitzy needs love!', 'mitzy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maximo@gmail.com', 'prince', 'prince needs love!', 'prince is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maximo@gmail.com', 'blossom', 'blossom needs love!', 'blossom is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('wittie', 'wittie@gmail.com', 'A user of PCS', 'wittiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wittie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'wittie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'wittie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'wittie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'wittie@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wittie@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wittie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('dona', 'dona@gmail.com', 'A user of PCS', 'donapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dona@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dona@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dona@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dona@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('giordano', 'giordano@gmail.com', 'A user of PCS', 'giordanopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giordano@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'giordano@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'giordano@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giordano@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giordano@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('elwin', 'elwin@gmail.com', 'A user of PCS', 'elwinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elwin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'elwin@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'elwin@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'elwin@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'elwin@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwin@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('nadine', 'nadine@gmail.com', 'A user of PCS', 'nadinepw');
INSERT INTO PetOwners(email) VALUES ('nadine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'chocolate', 'chocolate needs love!', 'chocolate is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('beauregard', 'beauregard@gmail.com', 'A user of PCS', 'beauregardpw');
INSERT INTO PetOwners(email) VALUES ('beauregard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beauregard@gmail.com', 'nina', 'nina needs love!', 'nina is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beauregard@gmail.com', 'ralphie', 'ralphie needs love!', 'ralphie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beauregard@gmail.com', 'puffy', 'puffy needs love!', 'puffy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beauregard@gmail.com', 'ladybug', 'ladybug needs love!', 'ladybug is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('jeni', 'jeni@gmail.com', 'A user of PCS', 'jenipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jeni@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jeni@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jeni@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jeni@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jeni@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeni@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('hewett', 'hewett@gmail.com', 'A user of PCS', 'hewettpw');
INSERT INTO PetOwners(email) VALUES ('hewett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'dash', 'dash needs love!', 'dash is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'jesse', 'jesse needs love!', 'jesse is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hewett@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hewett@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hewett@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hewett@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('denis', 'denis@gmail.com', 'A user of PCS', 'denispw');
INSERT INTO PetOwners(email) VALUES ('denis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denis@gmail.com', 'skinny', 'skinny needs love!', 'skinny is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denis@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denis@gmail.com', 'dante', 'dante needs love!', 'dante is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denis@gmail.com', 'nikki', 'nikki needs love!', 'nikki is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denis@gmail.com', 'harry', 'harry needs love!', 'harry is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('jaine', 'jaine@gmail.com', 'A user of PCS', 'jainepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jaine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jaine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jaine@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jaine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jaine@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('franzen', 'franzen@gmail.com', 'A user of PCS', 'franzenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('franzen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'franzen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'franzen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'franzen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'franzen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'franzen@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('franzen@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('franzen@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('birgit', 'birgit@gmail.com', 'A user of PCS', 'birgitpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('birgit@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'birgit@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('birgit@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('birgit@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('darrelle', 'darrelle@gmail.com', 'A user of PCS', 'darrellepw');
INSERT INTO PetOwners(email) VALUES ('darrelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'amos', 'amos needs love!', 'amos is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'peppy', 'peppy needs love!', 'peppy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'ruthie', 'ruthie needs love!', 'ruthie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'austin', 'austin needs love!', 'austin is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darrelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'darrelle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darrelle@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darrelle@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('aleksandr', 'aleksandr@gmail.com', 'A user of PCS', 'aleksandrpw');
INSERT INTO PetOwners(email) VALUES ('aleksandr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'angel', 'angel needs love!', 'angel is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'patsy', 'patsy needs love!', 'patsy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('kara', 'kara@gmail.com', 'A user of PCS', 'karapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'kara@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'kara@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'kara@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kara@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kara@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('andromache', 'andromache@gmail.com', 'A user of PCS', 'andromachepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andromache@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'andromache@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'andromache@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andromache@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('hashim', 'hashim@gmail.com', 'A user of PCS', 'hashimpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hashim@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hashim@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'hashim@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hashim@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'hashim@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hashim@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hashim@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('marilyn', 'marilyn@gmail.com', 'A user of PCS', 'marilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marilyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marilyn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marilyn@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('claudette', 'claudette@gmail.com', 'A user of PCS', 'claudettepw');
INSERT INTO PetOwners(email) VALUES ('claudette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudette@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudette@gmail.com', 'michael', 'michael needs love!', 'michael is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudette@gmail.com', 'little-rascal', 'little-rascal needs love!', 'little-rascal is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudette@gmail.com', 'lightning', 'lightning needs love!', 'lightning is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudette@gmail.com', 'sawyer', 'sawyer needs love!', 'sawyer is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'claudette@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'claudette@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'claudette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'claudette@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudette@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudette@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('olag', 'olag@gmail.com', 'A user of PCS', 'olagpw');
INSERT INTO PetOwners(email) VALUES ('olag@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('olag@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('olag@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('olag@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('olag@gmail.com', 'buddie', 'buddie needs love!', 'buddie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('olag@gmail.com', 'doc', 'doc needs love!', 'doc is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('madonna', 'madonna@gmail.com', 'A user of PCS', 'madonnapw');
INSERT INTO PetOwners(email) VALUES ('madonna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'dante', 'dante needs love!', 'dante is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madonna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'madonna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'madonna@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madonna@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madonna@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('olivero', 'olivero@gmail.com', 'A user of PCS', 'oliveropw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('olivero@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'olivero@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'olivero@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'olivero@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('karia', 'karia@gmail.com', 'A user of PCS', 'kariapw');
INSERT INTO PetOwners(email) VALUES ('karia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karia@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karia@gmail.com', 'sabine', 'sabine needs love!', 'sabine is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ellis', 'ellis@gmail.com', 'A user of PCS', 'ellispw');
INSERT INTO PetOwners(email) VALUES ('ellis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'patch', 'patch needs love!', 'patch is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'amos', 'amos needs love!', 'amos is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'pete', 'pete needs love!', 'pete is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'kid', 'kid needs love!', 'kid is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'lazarus', 'lazarus needs love!', 'lazarus is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ellis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'ellis@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'ellis@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'ellis@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellis@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellis@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('boony', 'boony@gmail.com', 'A user of PCS', 'boonypw');
INSERT INTO PetOwners(email) VALUES ('boony@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'dude', 'dude needs love!', 'dude is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'paco', 'paco needs love!', 'paco is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boony@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'boony@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'boony@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'boony@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'boony@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'boony@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boony@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boony@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('saree', 'saree@gmail.com', 'A user of PCS', 'sareepw');
INSERT INTO PetOwners(email) VALUES ('saree@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'ace', 'ace needs love!', 'ace is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('saree@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'saree@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('ingaberg', 'ingaberg@gmail.com', 'A user of PCS', 'ingabergpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ingaberg@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (214, 'ingaberg@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ingaberg@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'ingaberg@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'ingaberg@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingaberg@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingaberg@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('rolph', 'rolph@gmail.com', 'A user of PCS', 'rolphpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rolph@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'rolph@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (214, 'rolph@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'rolph@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'rolph@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rolph@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rolph@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('linzy', 'linzy@gmail.com', 'A user of PCS', 'linzypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('linzy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'linzy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'linzy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'linzy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'linzy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'linzy@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('mallorie', 'mallorie@gmail.com', 'A user of PCS', 'malloriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mallorie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'mallorie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'mallorie@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mallorie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mallorie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('becky', 'becky@gmail.com', 'A user of PCS', 'beckypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('becky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'becky@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'becky@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (201, 'becky@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'becky@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'becky@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('paula', 'paula@gmail.com', 'A user of PCS', 'paulapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paula@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'paula@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'paula@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'paula@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'paula@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('malorie', 'malorie@gmail.com', 'A user of PCS', 'maloriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('malorie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'malorie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'malorie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('shannan', 'shannan@gmail.com', 'A user of PCS', 'shannanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shannan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shannan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shannan@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shannan@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'shannan@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('murdock', 'murdock@gmail.com', 'A user of PCS', 'murdockpw');
INSERT INTO PetOwners(email) VALUES ('murdock@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('murdock@gmail.com', 'kato', 'kato needs love!', 'kato is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('murdock@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'murdock@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'murdock@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'murdock@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'murdock@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'murdock@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murdock@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murdock@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('maddy', 'maddy@gmail.com', 'A user of PCS', 'maddypw');
INSERT INTO PetOwners(email) VALUES ('maddy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maddy@gmail.com', 'libby', 'libby needs love!', 'libby is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maddy@gmail.com', 'bobby', 'bobby needs love!', 'bobby is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maddy@gmail.com', 'hope', 'hope needs love!', 'hope is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maddy@gmail.com', 'silky', 'silky needs love!', 'silky is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maddy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'maddy@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('christabel', 'christabel@gmail.com', 'A user of PCS', 'christabelpw');
INSERT INTO PetOwners(email) VALUES ('christabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'angus', 'angus needs love!', 'angus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'shaggy', 'shaggy needs love!', 'shaggy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'patches', 'patches needs love!', 'patches is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christabel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'christabel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'christabel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christabel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christabel@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('brigid', 'brigid@gmail.com', 'A user of PCS', 'brigidpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brigid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'brigid@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'brigid@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brigid@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brigid@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('camilla', 'camilla@gmail.com', 'A user of PCS', 'camillapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camilla@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'camilla@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'camilla@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('marguerite', 'marguerite@gmail.com', 'A user of PCS', 'margueritepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marguerite@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marguerite@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marguerite@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marguerite@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marguerite@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('melva', 'melva@gmail.com', 'A user of PCS', 'melvapw');
INSERT INTO PetOwners(email) VALUES ('melva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melva@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melva@gmail.com', 'sadie', 'sadie needs love!', 'sadie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('shayla', 'shayla@gmail.com', 'A user of PCS', 'shaylapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shayla@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shayla@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shayla@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shayla@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jazmin', 'jazmin@gmail.com', 'A user of PCS', 'jazminpw');
INSERT INTO PetOwners(email) VALUES ('jazmin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'chloe', 'chloe needs love!', 'chloe is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'autumn', 'autumn needs love!', 'autumn is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jazmin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jazmin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jazmin@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jazmin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jazmin@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jazmin@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('boyd', 'boyd@gmail.com', 'A user of PCS', 'boydpw');
INSERT INTO PetOwners(email) VALUES ('boyd@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boyd@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boyd@gmail.com', 'scrappy', 'scrappy needs love!', 'scrappy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('steve', 'steve@gmail.com', 'A user of PCS', 'stevepw');
INSERT INTO PetOwners(email) VALUES ('steve@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steve@gmail.com', 'cupcake', 'cupcake needs love!', 'cupcake is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steve@gmail.com', 'mattie', 'mattie needs love!', 'mattie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steve@gmail.com', 'charles', 'charles needs love!', 'charles is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'steve@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'steve@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'steve@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('liva', 'liva@gmail.com', 'A user of PCS', 'livapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('liva@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'liva@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'liva@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'liva@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'liva@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('stoddard', 'stoddard@gmail.com', 'A user of PCS', 'stoddardpw');
INSERT INTO PetOwners(email) VALUES ('stoddard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'koko', 'koko needs love!', 'koko is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('izak', 'izak@gmail.com', 'A user of PCS', 'izakpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('izak@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'izak@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'izak@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'izak@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'izak@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'izak@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('lib', 'lib@gmail.com', 'A user of PCS', 'libpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lib@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lib@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'lib@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lib@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('merl', 'merl@gmail.com', 'A user of PCS', 'merlpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merl@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'merl@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'merl@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'merl@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gloriane', 'gloriane@gmail.com', 'A user of PCS', 'glorianepw');
INSERT INTO PetOwners(email) VALUES ('gloriane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gloriane@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gloriane@gmail.com', 'maggie-moo', 'maggie-moo needs love!', 'maggie-moo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gloriane@gmail.com', 'jess', 'jess needs love!', 'jess is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gloriane@gmail.com', 'alf', 'alf needs love!', 'alf is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gloriane@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gloriane@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gloriane@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('vassily', 'vassily@gmail.com', 'A user of PCS', 'vassilypw');
INSERT INTO PetOwners(email) VALUES ('vassily@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'cricket', 'cricket needs love!', 'cricket is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'dee dee', 'dee dee needs love!', 'dee dee is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('timmie', 'timmie@gmail.com', 'A user of PCS', 'timmiepw');
INSERT INTO PetOwners(email) VALUES ('timmie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('timmie@gmail.com', 'curly', 'curly needs love!', 'curly is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('timmie@gmail.com', 'april', 'april needs love!', 'april is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('timmie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'timmie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('timmie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('timmie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('monro', 'monro@gmail.com', 'A user of PCS', 'monropw');
INSERT INTO PetOwners(email) VALUES ('monro@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'cinder', 'cinder needs love!', 'cinder is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'dee dee', 'dee dee needs love!', 'dee dee is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'guido', 'guido needs love!', 'guido is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'barney', 'barney needs love!', 'barney is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'lou', 'lou needs love!', 'lou is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('gretta', 'gretta@gmail.com', 'A user of PCS', 'grettapw');
INSERT INTO PetOwners(email) VALUES ('gretta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'sage', 'sage needs love!', 'sage is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'jojo', 'jojo needs love!', 'jojo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'ruthie', 'ruthie needs love!', 'ruthie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('derrick', 'derrick@gmail.com', 'A user of PCS', 'derrickpw');
INSERT INTO PetOwners(email) VALUES ('derrick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'ruger', 'ruger needs love!', 'ruger is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'king', 'king needs love!', 'king is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('geri', 'geri@gmail.com', 'A user of PCS', 'geripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'geri@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'geri@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'geri@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'geri@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'geri@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('lefty', 'lefty@gmail.com', 'A user of PCS', 'leftypw');
INSERT INTO PetOwners(email) VALUES ('lefty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'ace', 'ace needs love!', 'ace is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'harley', 'harley needs love!', 'harley is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'alf', 'alf needs love!', 'alf is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'clifford', 'clifford needs love!', 'clifford is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('arturo', 'arturo@gmail.com', 'A user of PCS', 'arturopw');
INSERT INTO PetOwners(email) VALUES ('arturo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'jetta', 'jetta needs love!', 'jetta is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arturo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'arturo@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'arturo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'arturo@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'arturo@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arturo@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mitchael', 'mitchael@gmail.com', 'A user of PCS', 'mitchaelpw');
INSERT INTO PetOwners(email) VALUES ('mitchael@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mitchael@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitchael@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'mitchael@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'mitchael@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'mitchael@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'mitchael@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (243, 'mitchael@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitchael@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitchael@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('niki', 'niki@gmail.com', 'A user of PCS', 'nikipw');
INSERT INTO PetOwners(email) VALUES ('niki@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'chubbs', 'chubbs needs love!', 'chubbs is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'bonnie', 'bonnie needs love!', 'bonnie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('niki@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'niki@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'niki@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'niki@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'niki@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'niki@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('annadiana', 'annadiana@gmail.com', 'A user of PCS', 'annadianapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annadiana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'annadiana@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'annadiana@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('christye', 'christye@gmail.com', 'A user of PCS', 'christyepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christye@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'christye@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'christye@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('florina', 'florina@gmail.com', 'A user of PCS', 'florinapw');
INSERT INTO PetOwners(email) VALUES ('florina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florina@gmail.com', 'babe', 'babe needs love!', 'babe is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('florina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'florina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'florina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'florina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'florina@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('florina@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('florina@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('felizio', 'felizio@gmail.com', 'A user of PCS', 'feliziopw');
INSERT INTO PetOwners(email) VALUES ('felizio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'skipper', 'skipper needs love!', 'skipper is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'ricky', 'ricky needs love!', 'ricky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'katz', 'katz needs love!', 'katz is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('byrle', 'byrle@gmail.com', 'A user of PCS', 'byrlepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'byrle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'byrle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'byrle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrle@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ryley', 'ryley@gmail.com', 'A user of PCS', 'ryleypw');
INSERT INTO PetOwners(email) VALUES ('ryley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'bogey', 'bogey needs love!', 'bogey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'augie', 'augie needs love!', 'augie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('deeyn', 'deeyn@gmail.com', 'A user of PCS', 'deeynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deeyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'deeyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'deeyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (275, 'deeyn@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('steffi', 'steffi@gmail.com', 'A user of PCS', 'steffipw');
INSERT INTO PetOwners(email) VALUES ('steffi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steffi@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steffi@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steffi@gmail.com', 'piper', 'piper needs love!', 'piper is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steffi@gmail.com', 'dinky', 'dinky needs love!', 'dinky is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steffi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'steffi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'steffi@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('davon', 'davon@gmail.com', 'A user of PCS', 'davonpw');
INSERT INTO PetOwners(email) VALUES ('davon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('davon@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('davon@gmail.com', 'flint', 'flint needs love!', 'flint is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('davon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'davon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'davon@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('bendicty', 'bendicty@gmail.com', 'A user of PCS', 'bendictypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bendicty@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bendicty@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bendicty@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bendicty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bendicty@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('leicester', 'leicester@gmail.com', 'A user of PCS', 'leicesterpw');
INSERT INTO PetOwners(email) VALUES ('leicester@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'deacon', 'deacon needs love!', 'deacon is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'dots', 'dots needs love!', 'dots is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'conan', 'conan needs love!', 'conan is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'parker', 'parker needs love!', 'parker is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'lili', 'lili needs love!', 'lili is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('alano', 'alano@gmail.com', 'A user of PCS', 'alanopw');
INSERT INTO PetOwners(email) VALUES ('alano@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'moose', 'moose needs love!', 'moose is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'dharma', 'dharma needs love!', 'dharma is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('clare', 'clare@gmail.com', 'A user of PCS', 'clarepw');
INSERT INTO PetOwners(email) VALUES ('clare@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clare@gmail.com', 'bucky', 'bucky needs love!', 'bucky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clare@gmail.com', 'macho', 'macho needs love!', 'macho is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clare@gmail.com', 'banjo', 'banjo needs love!', 'banjo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clare@gmail.com', 'kissy', 'kissy needs love!', 'kissy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clare@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'clare@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'clare@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clare@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('sibilla', 'sibilla@gmail.com', 'A user of PCS', 'sibillapw');
INSERT INTO PetOwners(email) VALUES ('sibilla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibilla@gmail.com', 'guinness', 'guinness needs love!', 'guinness is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibilla@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sibilla@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sibilla@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sibilla@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sibilla@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibilla@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('virgina', 'virgina@gmail.com', 'A user of PCS', 'virginapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('virgina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'virgina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'virgina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'virgina@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('enrichetta', 'enrichetta@gmail.com', 'A user of PCS', 'enrichettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrichetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'enrichetta@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrichetta@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrichetta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('der', 'der@gmail.com', 'A user of PCS', 'derpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('der@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'der@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'der@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'der@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'der@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('der@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('der@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('deeann', 'deeann@gmail.com', 'A user of PCS', 'deeannpw');
INSERT INTO PetOwners(email) VALUES ('deeann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'freddy', 'freddy needs love!', 'freddy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('marina', 'marina@gmail.com', 'A user of PCS', 'marinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'marina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'marina@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marina@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marina@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('lonnie', 'lonnie@gmail.com', 'A user of PCS', 'lonniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lonnie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'lonnie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lonnie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'lonnie@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lonnie@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lonnie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorice', 'dorice@gmail.com', 'A user of PCS', 'doricepw');
INSERT INTO PetOwners(email) VALUES ('dorice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorice@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorice@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'dorice@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'dorice@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'dorice@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'dorice@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorice@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorice@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('alverta', 'alverta@gmail.com', 'A user of PCS', 'alvertapw');
INSERT INTO PetOwners(email) VALUES ('alverta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'chauncey', 'chauncey needs love!', 'chauncey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'peanut', 'peanut needs love!', 'peanut is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'nikki', 'nikki needs love!', 'nikki is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('caldwell', 'caldwell@gmail.com', 'A user of PCS', 'caldwellpw');
INSERT INTO PetOwners(email) VALUES ('caldwell@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caldwell@gmail.com', 'klaus', 'klaus needs love!', 'klaus is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caldwell@gmail.com', 'sara', 'sara needs love!', 'sara is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caldwell@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('paco', 'paco@gmail.com', 'A user of PCS', 'pacopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paco@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'paco@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paco@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lani', 'lani@gmail.com', 'A user of PCS', 'lanipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lani@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'lani@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'lani@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'lani@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lani@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lani@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('juliette', 'juliette@gmail.com', 'A user of PCS', 'juliettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juliette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (249, 'juliette@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'juliette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'juliette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'juliette@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'juliette@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliette@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliette@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('maybelle', 'maybelle@gmail.com', 'A user of PCS', 'maybellepw');
INSERT INTO PetOwners(email) VALUES ('maybelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'earl', 'earl needs love!', 'earl is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'girl', 'girl needs love!', 'girl is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'chocolate', 'chocolate needs love!', 'chocolate is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('lynea', 'lynea@gmail.com', 'A user of PCS', 'lyneapw');
INSERT INTO PetOwners(email) VALUES ('lynea@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lynea@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lynea@gmail.com', 'noel', 'noel needs love!', 'noel is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lynea@gmail.com', 'harpo', 'harpo needs love!', 'harpo is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ginni', 'ginni@gmail.com', 'A user of PCS', 'ginnipw');
INSERT INTO PetOwners(email) VALUES ('ginni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginni@gmail.com', 'dino', 'dino needs love!', 'dino is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginni@gmail.com', 'budda', 'budda needs love!', 'budda is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginni@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('albina', 'albina@gmail.com', 'A user of PCS', 'albinapw');
INSERT INTO PetOwners(email) VALUES ('albina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'daisey-mae', 'daisey-mae needs love!', 'daisey-mae is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'hanna', 'hanna needs love!', 'hanna is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'nala', 'nala needs love!', 'nala is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('desirae', 'desirae@gmail.com', 'A user of PCS', 'desiraepw');
INSERT INTO PetOwners(email) VALUES ('desirae@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desirae@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('jamie', 'jamie@gmail.com', 'A user of PCS', 'jamiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jamie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jamie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jamie@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('margarete', 'margarete@gmail.com', 'A user of PCS', 'margaretepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margarete@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'margarete@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'margarete@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('neville', 'neville@gmail.com', 'A user of PCS', 'nevillepw');
INSERT INTO PetOwners(email) VALUES ('neville@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('neville@gmail.com', 'luke', 'luke needs love!', 'luke is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('neville@gmail.com', 'francais', 'francais needs love!', 'francais is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('neville@gmail.com', 'commando', 'commando needs love!', 'commando is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('neville@gmail.com', 'prancer', 'prancer needs love!', 'prancer is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('neville@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'neville@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'neville@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('neville@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('neville@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('nonnah', 'nonnah@gmail.com', 'A user of PCS', 'nonnahpw');
INSERT INTO PetOwners(email) VALUES ('nonnah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'hunter', 'hunter needs love!', 'hunter is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'libby', 'libby needs love!', 'libby is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('alyosha', 'alyosha@gmail.com', 'A user of PCS', 'alyoshapw');
INSERT INTO PetOwners(email) VALUES ('alyosha@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alyosha@gmail.com', 'cole', 'cole needs love!', 'cole is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alyosha@gmail.com', 'porkchop', 'porkchop needs love!', 'porkchop is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alyosha@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alyosha@gmail.com', 'bo', 'bo needs love!', 'bo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alyosha@gmail.com', 'boots', 'boots needs love!', 'boots is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alyosha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'alyosha@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alyosha@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alyosha@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alyosha@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('morgen', 'morgen@gmail.com', 'A user of PCS', 'morgenpw');
INSERT INTO PetOwners(email) VALUES ('morgen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'koda', 'koda needs love!', 'koda is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'abbie', 'abbie needs love!', 'abbie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'jester', 'jester needs love!', 'jester is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('lennard', 'lennard@gmail.com', 'A user of PCS', 'lennardpw');
INSERT INTO PetOwners(email) VALUES ('lennard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('gwennie', 'gwennie@gmail.com', 'A user of PCS', 'gwenniepw');
INSERT INTO PetOwners(email) VALUES ('gwennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'oakley', 'oakley needs love!', 'oakley is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'sarah', 'sarah needs love!', 'sarah is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'nike', 'nike needs love!', 'nike is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwennie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'gwennie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'gwennie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'gwennie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'gwennie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'gwennie@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwennie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwennie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('miltie', 'miltie@gmail.com', 'A user of PCS', 'miltiepw');
INSERT INTO PetOwners(email) VALUES ('miltie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('miltie@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('miltie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'miltie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'miltie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'miltie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('page', 'page@gmail.com', 'A user of PCS', 'pagepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('page@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'page@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'page@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'page@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('sheila-kathryn', 'sheila-kathryn@gmail.com', 'A user of PCS', 'sheila-kathrynpw');
INSERT INTO PetOwners(email) VALUES ('sheila-kathryn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sheila-kathryn@gmail.com', 'rosy', 'rosy needs love!', 'rosy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sheila-kathryn@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('omar', 'omar@gmail.com', 'A user of PCS', 'omarpw');
INSERT INTO PetOwners(email) VALUES ('omar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('omar@gmail.com', 'checkers', 'checkers needs love!', 'checkers is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('omar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'omar@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'omar@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'omar@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('omar@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('omar@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('zandra', 'zandra@gmail.com', 'A user of PCS', 'zandrapw');
INSERT INTO PetOwners(email) VALUES ('zandra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'champ', 'champ needs love!', 'champ is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'mary', 'mary needs love!', 'mary is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('levey', 'levey@gmail.com', 'A user of PCS', 'leveypw');
INSERT INTO PetOwners(email) VALUES ('levey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('levey@gmail.com', 'bugsy', 'bugsy needs love!', 'bugsy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('dill', 'dill@gmail.com', 'A user of PCS', 'dillpw');
INSERT INTO PetOwners(email) VALUES ('dill@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'sarge', 'sarge needs love!', 'sarge is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'houdini', 'houdini needs love!', 'houdini is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'ralphie', 'ralphie needs love!', 'ralphie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dill@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dill@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dill@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dill@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('peggy', 'peggy@gmail.com', 'A user of PCS', 'peggypw');
INSERT INTO PetOwners(email) VALUES ('peggy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'nala', 'nala needs love!', 'nala is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'old glory', 'old glory needs love!', 'old glory is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('lannie', 'lannie@gmail.com', 'A user of PCS', 'lanniepw');
INSERT INTO PetOwners(email) VALUES ('lannie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'nibby-nose', 'nibby-nose needs love!', 'nibby-nose is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'grover', 'grover needs love!', 'grover is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'axle', 'axle needs love!', 'axle is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'logan', 'logan needs love!', 'logan is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'ralph', 'ralph needs love!', 'ralph is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('elnar', 'elnar@gmail.com', 'A user of PCS', 'elnarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elnar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (230, 'elnar@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'elnar@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('myrvyn', 'myrvyn@gmail.com', 'A user of PCS', 'myrvynpw');
INSERT INTO PetOwners(email) VALUES ('myrvyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'logan', 'logan needs love!', 'logan is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'slick', 'slick needs love!', 'slick is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'noodles', 'noodles needs love!', 'noodles is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('cello', 'cello@gmail.com', 'A user of PCS', 'cellopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cello@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'cello@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('kennan', 'kennan@gmail.com', 'A user of PCS', 'kennanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kennan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kennan@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennan@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jemimah', 'jemimah@gmail.com', 'A user of PCS', 'jemimahpw');
INSERT INTO PetOwners(email) VALUES ('jemimah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jemimah@gmail.com', 'cotton', 'cotton needs love!', 'cotton is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jemimah@gmail.com', 'chessie', 'chessie needs love!', 'chessie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jemimah@gmail.com', 'leo', 'leo needs love!', 'leo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jemimah@gmail.com', 'kira', 'kira needs love!', 'kira is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('ajay', 'ajay@gmail.com', 'A user of PCS', 'ajaypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ajay@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ajay@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ajay@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('idaline', 'idaline@gmail.com', 'A user of PCS', 'idalinepw');
INSERT INTO PetOwners(email) VALUES ('idaline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'moses', 'moses needs love!', 'moses is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'eva', 'eva needs love!', 'eva is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'puppy', 'puppy needs love!', 'puppy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'kato', 'kato needs love!', 'kato is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idaline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'idaline@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'idaline@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'idaline@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'idaline@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idaline@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idaline@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('illa', 'illa@gmail.com', 'A user of PCS', 'illapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('illa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'illa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'illa@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('illa@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('illa@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('hendrik', 'hendrik@gmail.com', 'A user of PCS', 'hendrikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hendrik@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hendrik@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hendrik@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hendrik@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('sophia', 'sophia@gmail.com', 'A user of PCS', 'sophiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sophia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'sophia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'sophia@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sophia@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sophia@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('johnath', 'johnath@gmail.com', 'A user of PCS', 'johnathpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('johnath@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'johnath@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'johnath@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'johnath@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (278, 'johnath@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'johnath@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('johnath@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('johnath@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('latrena', 'latrena@gmail.com', 'A user of PCS', 'latrenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latrena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'latrena@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'latrena@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('latrena@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jermaine', 'jermaine@gmail.com', 'A user of PCS', 'jermainepw');
INSERT INTO PetOwners(email) VALUES ('jermaine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'boo', 'boo needs love!', 'boo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'mary jane', 'mary jane needs love!', 'mary jane is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('mollee', 'mollee@gmail.com', 'A user of PCS', 'molleepw');
INSERT INTO PetOwners(email) VALUES ('mollee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollee@gmail.com', 'clifford', 'clifford needs love!', 'clifford is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollee@gmail.com', 'jackie', 'jackie needs love!', 'jackie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('alie', 'alie@gmail.com', 'A user of PCS', 'aliepw');
INSERT INTO PetOwners(email) VALUES ('alie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'bart', 'bart needs love!', 'bart is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'jess', 'jess needs love!', 'jess is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'alie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'alie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kara-lynn', 'kara-lynn@gmail.com', 'A user of PCS', 'kara-lynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kara-lynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kara-lynn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kara-lynn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kara-lynn@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara-lynn@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('danna', 'danna@gmail.com', 'A user of PCS', 'dannapw');
INSERT INTO PetOwners(email) VALUES ('danna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danna@gmail.com', 'skye', 'skye needs love!', 'skye is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('james', 'james@gmail.com', 'A user of PCS', 'jamespw');
INSERT INTO PetOwners(email) VALUES ('james@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('james@gmail.com', 'puck', 'puck needs love!', 'puck is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('james@gmail.com', 'lili', 'lili needs love!', 'lili is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('james@gmail.com', 'flint', 'flint needs love!', 'flint is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('james@gmail.com', 'ruthie', 'ruthie needs love!', 'ruthie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('james@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('james@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'james@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('nicolai', 'nicolai@gmail.com', 'A user of PCS', 'nicolaipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nicolai@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nicolai@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('dre', 'dre@gmail.com', 'A user of PCS', 'drepw');
INSERT INTO PetOwners(email) VALUES ('dre@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dre@gmail.com', 'hank', 'hank needs love!', 'hank is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dre@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('cristian', 'cristian@gmail.com', 'A user of PCS', 'cristianpw');
INSERT INTO PetOwners(email) VALUES ('cristian@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'dewey', 'dewey needs love!', 'dewey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'puck', 'puck needs love!', 'puck is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'schotzie', 'schotzie needs love!', 'schotzie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'brandy', 'brandy needs love!', 'brandy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('frederick', 'frederick@gmail.com', 'A user of PCS', 'frederickpw');
INSERT INTO PetOwners(email) VALUES ('frederick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frederick@gmail.com', 'pierre', 'pierre needs love!', 'pierre is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frederick@gmail.com', 'huey', 'huey needs love!', 'huey is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('rudie', 'rudie@gmail.com', 'A user of PCS', 'rudiepw');
INSERT INTO PetOwners(email) VALUES ('rudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'pretty-girl', 'pretty-girl needs love!', 'pretty-girl is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'skye', 'skye needs love!', 'skye is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rudie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'rudie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rudie@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rudie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('mahmud', 'mahmud@gmail.com', 'A user of PCS', 'mahmudpw');
INSERT INTO PetOwners(email) VALUES ('mahmud@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'archie', 'archie needs love!', 'archie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'gabby', 'gabby needs love!', 'gabby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'bambi', 'bambi needs love!', 'bambi is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'faith', 'faith needs love!', 'faith is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('aldridge', 'aldridge@gmail.com', 'A user of PCS', 'aldridgepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aldridge@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'aldridge@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'aldridge@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'aldridge@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'aldridge@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'aldridge@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aldridge@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorrie', 'dorrie@gmail.com', 'A user of PCS', 'dorriepw');
INSERT INTO PetOwners(email) VALUES ('dorrie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorrie@gmail.com', 'jazz', 'jazz needs love!', 'jazz is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorrie@gmail.com', 'paco', 'paco needs love!', 'paco is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorrie@gmail.com', 'latte', 'latte needs love!', 'latte is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorrie@gmail.com', 'mason', 'mason needs love!', 'mason is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('hedwiga', 'hedwiga@gmail.com', 'A user of PCS', 'hedwigapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hedwiga@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hedwiga@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hedwiga@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hedwiga@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hedwiga@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hedwiga@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hedwiga@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('web', 'web@gmail.com', 'A user of PCS', 'webpw');
INSERT INTO PetOwners(email) VALUES ('web@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'girl', 'girl needs love!', 'girl is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'bogey', 'bogey needs love!', 'bogey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'ruchus', 'ruchus needs love!', 'ruchus is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('robinet', 'robinet@gmail.com', 'A user of PCS', 'robinetpw');
INSERT INTO PetOwners(email) VALUES ('robinet@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinet@gmail.com', 'little-one', 'little-one needs love!', 'little-one is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinet@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('wainwright', 'wainwright@gmail.com', 'A user of PCS', 'wainwrightpw');
INSERT INTO PetOwners(email) VALUES ('wainwright@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'aj', 'aj needs love!', 'aj is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'charles', 'charles needs love!', 'charles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'chewy', 'chewy needs love!', 'chewy is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wainwright@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wainwright@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'wainwright@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'wainwright@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'wainwright@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'wainwright@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('brunhilda', 'brunhilda@gmail.com', 'A user of PCS', 'brunhildapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brunhilda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'brunhilda@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'brunhilda@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'brunhilda@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'brunhilda@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'brunhilda@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('red', 'red@gmail.com', 'A user of PCS', 'redpw');
INSERT INTO PetOwners(email) VALUES ('red@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('red@gmail.com', 'grady', 'grady needs love!', 'grady is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('red@gmail.com', 'magic', 'magic needs love!', 'magic is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('red@gmail.com', 'nosey', 'nosey needs love!', 'nosey is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('red@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'red@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'red@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'red@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('addi', 'addi@gmail.com', 'A user of PCS', 'addipw');
INSERT INTO PetOwners(email) VALUES ('addi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'brando', 'brando needs love!', 'brando is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'porter', 'porter needs love!', 'porter is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'cookie', 'cookie needs love!', 'cookie is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('kennie', 'kennie@gmail.com', 'A user of PCS', 'kenniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kennie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kennie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kennie@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('urbain', 'urbain@gmail.com', 'A user of PCS', 'urbainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('urbain@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'urbain@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'urbain@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'urbain@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'urbain@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('chrystel', 'chrystel@gmail.com', 'A user of PCS', 'chrystelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chrystel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'chrystel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'chrystel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'chrystel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'chrystel@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrystel@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('adolf', 'adolf@gmail.com', 'A user of PCS', 'adolfpw');
INSERT INTO PetOwners(email) VALUES ('adolf@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adolf@gmail.com', 'candy', 'candy needs love!', 'candy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'adolf@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'adolf@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'adolf@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('eleanora', 'eleanora@gmail.com', 'A user of PCS', 'eleanorapw');
INSERT INTO PetOwners(email) VALUES ('eleanora@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eleanora@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eleanora@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'eleanora@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'eleanora@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'eleanora@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'eleanora@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'eleanora@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('fredia', 'fredia@gmail.com', 'A user of PCS', 'frediapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fredia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'fredia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'fredia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'fredia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'fredia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'fredia@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fredia@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fredia@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('esmaria', 'esmaria@gmail.com', 'A user of PCS', 'esmariapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esmaria@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'esmaria@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'esmaria@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'esmaria@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'esmaria@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'esmaria@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esmaria@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('krysta', 'krysta@gmail.com', 'A user of PCS', 'krystapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krysta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'krysta@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('faythe', 'faythe@gmail.com', 'A user of PCS', 'faythepw');
INSERT INTO PetOwners(email) VALUES ('faythe@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('faythe@gmail.com', 'basil', 'basil needs love!', 'basil is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('faythe@gmail.com', 'lady', 'lady needs love!', 'lady is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('faythe@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'faythe@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('faythe@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('esma', 'esma@gmail.com', 'A user of PCS', 'esmapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'esma@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'esma@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'esma@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcelline', 'marcelline@gmail.com', 'A user of PCS', 'marcellinepw');
INSERT INTO PetOwners(email) VALUES ('marcelline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelline@gmail.com', 'olivia', 'olivia needs love!', 'olivia is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelline@gmail.com', 'maxwell', 'maxwell needs love!', 'maxwell is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('tine', 'tine@gmail.com', 'A user of PCS', 'tinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'tine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (161, 'tine@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tine@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'tine@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tine@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tine@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('jasen', 'jasen@gmail.com', 'A user of PCS', 'jasenpw');
INSERT INTO PetOwners(email) VALUES ('jasen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jasen@gmail.com', 'mandi', 'mandi needs love!', 'mandi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jasen@gmail.com', 'humphrey', 'humphrey needs love!', 'humphrey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jasen@gmail.com', 'mouse', 'mouse needs love!', 'mouse is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jasen@gmail.com', 'dino', 'dino needs love!', 'dino is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jasen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'jasen@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('claribel', 'claribel@gmail.com', 'A user of PCS', 'claribelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claribel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'claribel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'claribel@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claribel@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('lock', 'lock@gmail.com', 'A user of PCS', 'lockpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lock@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'lock@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (227, 'lock@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'lock@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'lock@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lock@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lock@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('dale', 'dale@gmail.com', 'A user of PCS', 'dalepw');
INSERT INTO PetOwners(email) VALUES ('dale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'patricky', 'patricky needs love!', 'patricky is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'louie', 'louie needs love!', 'louie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'baron', 'baron needs love!', 'baron is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dale@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dale@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dale@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dale@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dale@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dale@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dale@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('osborne', 'osborne@gmail.com', 'A user of PCS', 'osbornepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('osborne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'osborne@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'osborne@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('osborne@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('osborne@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('wiatt', 'wiatt@gmail.com', 'A user of PCS', 'wiattpw');
INSERT INTO PetOwners(email) VALUES ('wiatt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'bugsy', 'bugsy needs love!', 'bugsy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'monster', 'monster needs love!', 'monster is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'clover', 'clover needs love!', 'clover is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('felipa', 'felipa@gmail.com', 'A user of PCS', 'felipapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felipa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'felipa@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'felipa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'felipa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'felipa@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'felipa@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('wynne', 'wynne@gmail.com', 'A user of PCS', 'wynnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wynne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'wynne@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'wynne@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynne@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('cornelia', 'cornelia@gmail.com', 'A user of PCS', 'corneliapw');
INSERT INTO PetOwners(email) VALUES ('cornelia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'kibbles', 'kibbles needs love!', 'kibbles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'bo', 'bo needs love!', 'bo is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('tiphany', 'tiphany@gmail.com', 'A user of PCS', 'tiphanypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiphany@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tiphany@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tiphany@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tiphany@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gunner', 'gunner@gmail.com', 'A user of PCS', 'gunnerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gunner@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gunner@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gunner@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('darnall', 'darnall@gmail.com', 'A user of PCS', 'darnallpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darnall@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'darnall@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'darnall@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'darnall@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'darnall@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darnall@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darnall@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('margery', 'margery@gmail.com', 'A user of PCS', 'margerypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margery@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'margery@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'margery@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'margery@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'margery@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'margery@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('margery@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('margery@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('aylmer', 'aylmer@gmail.com', 'A user of PCS', 'aylmerpw');
INSERT INTO PetOwners(email) VALUES ('aylmer@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aylmer@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('muriel', 'muriel@gmail.com', 'A user of PCS', 'murielpw');
INSERT INTO PetOwners(email) VALUES ('muriel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('muriel@gmail.com', 'poppy', 'poppy needs love!', 'poppy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('muriel@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('muriel@gmail.com', 'salem', 'salem needs love!', 'salem is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('muriel@gmail.com', 'kallie', 'kallie needs love!', 'kallie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('muriel@gmail.com', 'petie', 'petie needs love!', 'petie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('lane', 'lane@gmail.com', 'A user of PCS', 'lanepw');
INSERT INTO PetOwners(email) VALUES ('lane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'hershey', 'hershey needs love!', 'hershey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'mister', 'mister needs love!', 'mister is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'reggie', 'reggie needs love!', 'reggie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'nosey', 'nosey needs love!', 'nosey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'buster-brown', 'buster-brown needs love!', 'buster-brown is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('kania', 'kania@gmail.com', 'A user of PCS', 'kaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kania@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kania@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kania@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kania@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mylo', 'mylo@gmail.com', 'A user of PCS', 'mylopw');
INSERT INTO PetOwners(email) VALUES ('mylo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mylo@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mylo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'mylo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'mylo@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mylo@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mylo@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('fidole', 'fidole@gmail.com', 'A user of PCS', 'fidolepw');
INSERT INTO PetOwners(email) VALUES ('fidole@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'big foot', 'big foot needs love!', 'big foot is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'jelly-bean', 'jelly-bean needs love!', 'jelly-bean is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'kitty', 'kitty needs love!', 'kitty is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'roman', 'roman needs love!', 'roman is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fidole@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'fidole@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fidole@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fidole@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fidole@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fidole@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kippy', 'kippy@gmail.com', 'A user of PCS', 'kippypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kippy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'kippy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'kippy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kippy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'kippy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'kippy@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kippy@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kippy@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('bettye', 'bettye@gmail.com', 'A user of PCS', 'bettyepw');
INSERT INTO PetOwners(email) VALUES ('bettye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bettye@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bettye@gmail.com', 'carley', 'carley needs love!', 'carley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bettye@gmail.com', 'dave', 'dave needs love!', 'dave is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bettye@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bettye@gmail.com', 'justice', 'justice needs love!', 'justice is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('aggie', 'aggie@gmail.com', 'A user of PCS', 'aggiepw');
INSERT INTO PetOwners(email) VALUES ('aggie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aggie@gmail.com', 'digger', 'digger needs love!', 'digger is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('claudetta', 'claudetta@gmail.com', 'A user of PCS', 'claudettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'claudetta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'claudetta@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudetta@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudetta@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('linet', 'linet@gmail.com', 'A user of PCS', 'linetpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('linet@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'linet@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'linet@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'linet@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linet@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linet@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('dougy', 'dougy@gmail.com', 'A user of PCS', 'dougypw');
INSERT INTO PetOwners(email) VALUES ('dougy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dougy@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dougy@gmail.com', 'obie', 'obie needs love!', 'obie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dougy@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dougy@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('alister', 'alister@gmail.com', 'A user of PCS', 'alisterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alister@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'alister@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'alister@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'alister@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'alister@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'alister@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('joyan', 'joyan@gmail.com', 'A user of PCS', 'joyanpw');
INSERT INTO PetOwners(email) VALUES ('joyan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'ming', 'ming needs love!', 'ming is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joyan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'joyan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'joyan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'joyan@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('geneva', 'geneva@gmail.com', 'A user of PCS', 'genevapw');
INSERT INTO PetOwners(email) VALUES ('geneva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'blast', 'blast needs love!', 'blast is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'fonzie', 'fonzie needs love!', 'fonzie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'mia', 'mia needs love!', 'mia is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geneva@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'geneva@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('geneva@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('geneva@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('devin', 'devin@gmail.com', 'A user of PCS', 'devinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('devin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'devin@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'devin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'devin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'devin@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('juieta', 'juieta@gmail.com', 'A user of PCS', 'juietapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juieta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'juieta@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'juieta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'juieta@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('rosamund', 'rosamund@gmail.com', 'A user of PCS', 'rosamundpw');
INSERT INTO PetOwners(email) VALUES ('rosamund@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('merrielle', 'merrielle@gmail.com', 'A user of PCS', 'merriellepw');
INSERT INTO PetOwners(email) VALUES ('merrielle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'penny', 'penny needs love!', 'penny is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merrielle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'merrielle@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'merrielle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'merrielle@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merrielle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merrielle@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('roseline', 'roseline@gmail.com', 'A user of PCS', 'roselinepw');
INSERT INTO PetOwners(email) VALUES ('roseline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'booster', 'booster needs love!', 'booster is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'kibbles', 'kibbles needs love!', 'kibbles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'ruffe', 'ruffe needs love!', 'ruffe is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('sibby', 'sibby@gmail.com', 'A user of PCS', 'sibbypw');
INSERT INTO PetOwners(email) VALUES ('sibby@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'popcorn', 'popcorn needs love!', 'popcorn is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'polly', 'polly needs love!', 'polly is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'jojo', 'jojo needs love!', 'jojo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibby@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sibby@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('madelina', 'madelina@gmail.com', 'A user of PCS', 'madelinapw');
INSERT INTO PetOwners(email) VALUES ('madelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'barney', 'barney needs love!', 'barney is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('juditha', 'juditha@gmail.com', 'A user of PCS', 'judithapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juditha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'juditha@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (231, 'juditha@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juditha@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juditha@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('selestina', 'selestina@gmail.com', 'A user of PCS', 'selestinapw');
INSERT INTO PetOwners(email) VALUES ('selestina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'howie', 'howie needs love!', 'howie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'queen', 'queen needs love!', 'queen is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'mitch', 'mitch needs love!', 'mitch is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('imelda', 'imelda@gmail.com', 'A user of PCS', 'imeldapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('imelda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'imelda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'imelda@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'imelda@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('imelda@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('imelda@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('jefferson', 'jefferson@gmail.com', 'A user of PCS', 'jeffersonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jefferson@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'jefferson@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jefferson@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'jefferson@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jefferson@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jefferson@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('tammara', 'tammara@gmail.com', 'A user of PCS', 'tammarapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tammara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tammara@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tammara@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tammara@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tammara@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tobye', 'tobye@gmail.com', 'A user of PCS', 'tobyepw');
INSERT INTO PetOwners(email) VALUES ('tobye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'jolly', 'jolly needs love!', 'jolly is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'buttercup', 'buttercup needs love!', 'buttercup is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tobye@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'tobye@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'tobye@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tobye@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tobye@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('beau', 'beau@gmail.com', 'A user of PCS', 'beaupw');
INSERT INTO PetOwners(email) VALUES ('beau@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'ripley', 'ripley needs love!', 'ripley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'koba', 'koba needs love!', 'koba is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'rowdy', 'rowdy needs love!', 'rowdy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'harry', 'harry needs love!', 'harry is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beau@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'beau@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'beau@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'beau@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'beau@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'beau@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beau@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('lezlie', 'lezlie@gmail.com', 'A user of PCS', 'lezliepw');
INSERT INTO PetOwners(email) VALUES ('lezlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'quinn', 'quinn needs love!', 'quinn is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'madison', 'madison needs love!', 'madison is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lezlie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lezlie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lezlie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lezlie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lezlie@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('madalena', 'madalena@gmail.com', 'A user of PCS', 'madalenapw');
INSERT INTO PetOwners(email) VALUES ('madalena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madalena@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madalena@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('milzie', 'milzie@gmail.com', 'A user of PCS', 'milziepw');
INSERT INTO PetOwners(email) VALUES ('milzie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milzie@gmail.com', 'jolly', 'jolly needs love!', 'jolly is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milzie@gmail.com', 'scoobie', 'scoobie needs love!', 'scoobie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milzie@gmail.com', 'josie', 'josie needs love!', 'josie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('jessi', 'jessi@gmail.com', 'A user of PCS', 'jessipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'jessi@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'jessi@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'jessi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'jessi@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessi@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessi@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('marie-ann', 'marie-ann@gmail.com', 'A user of PCS', 'marie-annpw');
INSERT INTO PetOwners(email) VALUES ('marie-ann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'silky', 'silky needs love!', 'silky is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'piglet', 'piglet needs love!', 'piglet is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'nutmeg', 'nutmeg needs love!', 'nutmeg is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'india', 'india needs love!', 'india is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('kizzee', 'kizzee@gmail.com', 'A user of PCS', 'kizzeepw');
INSERT INTO PetOwners(email) VALUES ('kizzee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kizzee@gmail.com', 'chad', 'chad needs love!', 'chad is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kizzee@gmail.com', 'eva', 'eva needs love!', 'eva is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('innis', 'innis@gmail.com', 'A user of PCS', 'innispw');
INSERT INTO PetOwners(email) VALUES ('innis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'austin', 'austin needs love!', 'austin is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('borg', 'borg@gmail.com', 'A user of PCS', 'borgpw');
INSERT INTO PetOwners(email) VALUES ('borg@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'guy', 'guy needs love!', 'guy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'old glory', 'old glory needs love!', 'old glory is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('paulina', 'paulina@gmail.com', 'A user of PCS', 'paulinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paulina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'paulina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'paulina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'paulina@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('emmy', 'emmy@gmail.com', 'A user of PCS', 'emmypw');
INSERT INTO PetOwners(email) VALUES ('emmy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'freedom', 'freedom needs love!', 'freedom is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'guido', 'guido needs love!', 'guido is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emmy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'emmy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'emmy@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emmy@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emmy@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('tawnya', 'tawnya@gmail.com', 'A user of PCS', 'tawnyapw');
INSERT INTO PetOwners(email) VALUES ('tawnya@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'smokey', 'smokey needs love!', 'smokey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'abbie', 'abbie needs love!', 'abbie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tawnya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tawnya@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tawnya@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tawnya@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tawnya@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('mollie', 'mollie@gmail.com', 'A user of PCS', 'molliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mollie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mollie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mollie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mollie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mollie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('bone', 'bone@gmail.com', 'A user of PCS', 'bonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bone@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'bone@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'bone@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'bone@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'bone@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('dacy', 'dacy@gmail.com', 'A user of PCS', 'dacypw');
INSERT INTO PetOwners(email) VALUES ('dacy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'mindy', 'mindy needs love!', 'mindy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'baby-doll', 'baby-doll needs love!', 'baby-doll is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'paris', 'paris needs love!', 'paris is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('milton', 'milton@gmail.com', 'A user of PCS', 'miltonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'milton@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'milton@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milton@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milton@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('raddie', 'raddie@gmail.com', 'A user of PCS', 'raddiepw');
INSERT INTO PetOwners(email) VALUES ('raddie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'chief', 'chief needs love!', 'chief is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'patch', 'patch needs love!', 'patch is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'scottie', 'scottie needs love!', 'scottie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'elliot', 'elliot needs love!', 'elliot is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('raddie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'raddie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'raddie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'raddie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'raddie@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('raddie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('raddie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dalston', 'dalston@gmail.com', 'A user of PCS', 'dalstonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dalston@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'dalston@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'dalston@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'dalston@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'dalston@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'dalston@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dalston@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dalston@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('selig', 'selig@gmail.com', 'A user of PCS', 'seligpw');
INSERT INTO PetOwners(email) VALUES ('selig@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'onie', 'onie needs love!', 'onie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('selig@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'selig@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'selig@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'selig@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'selig@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'selig@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('selig@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('selig@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('susi', 'susi@gmail.com', 'A user of PCS', 'susipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('susi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'susi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'susi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'susi@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'susi@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('norine', 'norine@gmail.com', 'A user of PCS', 'norinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('norine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'norine@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'norine@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('norine@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('merv', 'merv@gmail.com', 'A user of PCS', 'mervpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merv@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'merv@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merv@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merv@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('rodney', 'rodney@gmail.com', 'A user of PCS', 'rodneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rodney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rodney@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gonzales', 'gonzales@gmail.com', 'A user of PCS', 'gonzalespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gonzales@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gonzales@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gonzales@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gonzales@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('riobard', 'riobard@gmail.com', 'A user of PCS', 'riobardpw');
INSERT INTO PetOwners(email) VALUES ('riobard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'dylan', 'dylan needs love!', 'dylan is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'amber', 'amber needs love!', 'amber is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'armanti', 'armanti needs love!', 'armanti is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'luna', 'luna needs love!', 'luna is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('kahlil', 'kahlil@gmail.com', 'A user of PCS', 'kahlilpw');
INSERT INTO PetOwners(email) VALUES ('kahlil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kahlil@gmail.com', 'comet', 'comet needs love!', 'comet is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kahlil@gmail.com', 'major', 'major needs love!', 'major is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kahlil@gmail.com', 'powder', 'powder needs love!', 'powder is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kahlil@gmail.com', 'jasmine', 'jasmine needs love!', 'jasmine is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kahlil@gmail.com', 'lexus', 'lexus needs love!', 'lexus is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kahlil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'kahlil@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'kahlil@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'kahlil@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'kahlil@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('shirl', 'shirl@gmail.com', 'A user of PCS', 'shirlpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shirl@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'shirl@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shirl@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kalli', 'kalli@gmail.com', 'A user of PCS', 'kallipw');
INSERT INTO PetOwners(email) VALUES ('kalli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'midnight', 'midnight needs love!', 'midnight is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'porche', 'porche needs love!', 'porche is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalli@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'kalli@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'kalli@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'kalli@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalli@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalli@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('janina', 'janina@gmail.com', 'A user of PCS', 'janinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'janina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'janina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'janina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'janina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'janina@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janina@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janina@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('colene', 'colene@gmail.com', 'A user of PCS', 'colenepw');
INSERT INTO PetOwners(email) VALUES ('colene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'felix', 'felix needs love!', 'felix is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'diesel', 'diesel needs love!', 'diesel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'sammy', 'sammy needs love!', 'sammy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('colene@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'colene@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('colene@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('chaim', 'chaim@gmail.com', 'A user of PCS', 'chaimpw');
INSERT INTO PetOwners(email) VALUES ('chaim@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'rusty', 'rusty needs love!', 'rusty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'einstein', 'einstein needs love!', 'einstein is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'cookie', 'cookie needs love!', 'cookie is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chaim@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'chaim@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'chaim@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'chaim@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'chaim@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'chaim@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chaim@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chaim@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('bond', 'bond@gmail.com', 'A user of PCS', 'bondpw');
INSERT INTO PetOwners(email) VALUES ('bond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bond@gmail.com', 'lizzy', 'lizzy needs love!', 'lizzy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bond@gmail.com', 'maximus', 'maximus needs love!', 'maximus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bond@gmail.com', 'brownie', 'brownie needs love!', 'brownie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bond@gmail.com', 'flash', 'flash needs love!', 'flash is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('yule', 'yule@gmail.com', 'A user of PCS', 'yulepw');
INSERT INTO PetOwners(email) VALUES ('yule@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yule@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yule@gmail.com', 'brie', 'brie needs love!', 'brie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yule@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'yule@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'yule@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'yule@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'yule@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'yule@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('filbert', 'filbert@gmail.com', 'A user of PCS', 'filbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filbert@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'filbert@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'filbert@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filbert@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('welch', 'welch@gmail.com', 'A user of PCS', 'welchpw');
INSERT INTO PetOwners(email) VALUES ('welch@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('welch@gmail.com', 'phantom', 'phantom needs love!', 'phantom is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('welch@gmail.com', 'louie', 'louie needs love!', 'louie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('mella', 'mella@gmail.com', 'A user of PCS', 'mellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'mella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mella@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mella@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mella@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('hernando', 'hernando@gmail.com', 'A user of PCS', 'hernandopw');
INSERT INTO PetOwners(email) VALUES ('hernando@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hernando@gmail.com', 'nick', 'nick needs love!', 'nick is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hernando@gmail.com', 'chico', 'chico needs love!', 'chico is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hernando@gmail.com', 'monster', 'monster needs love!', 'monster is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hernando@gmail.com', 'fiona', 'fiona needs love!', 'fiona is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('carleton', 'carleton@gmail.com', 'A user of PCS', 'carletonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carleton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'carleton@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carleton@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carleton@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('allsun', 'allsun@gmail.com', 'A user of PCS', 'allsunpw');
INSERT INTO PetOwners(email) VALUES ('allsun@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'chewy', 'chewy needs love!', 'chewy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'boone', 'boone needs love!', 'boone is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'chucky', 'chucky needs love!', 'chucky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'cyrus', 'cyrus needs love!', 'cyrus is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('malissia', 'malissia@gmail.com', 'A user of PCS', 'malissiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('malissia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'malissia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'malissia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'malissia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'malissia@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('malissia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('malissia@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('celinka', 'celinka@gmail.com', 'A user of PCS', 'celinkapw');
INSERT INTO PetOwners(email) VALUES ('celinka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celinka@gmail.com', 'oakley', 'oakley needs love!', 'oakley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celinka@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celinka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'celinka@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'celinka@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'celinka@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'celinka@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'celinka@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorthea', 'dorthea@gmail.com', 'A user of PCS', 'dortheapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorthea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dorthea@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dorthea@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dorthea@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dorthea@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dorthea@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('letti', 'letti@gmail.com', 'A user of PCS', 'lettipw');
INSERT INTO PetOwners(email) VALUES ('letti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'gilbert', 'gilbert needs love!', 'gilbert is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'scarlett', 'scarlett needs love!', 'scarlett is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'meggie', 'meggie needs love!', 'meggie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'emma', 'emma needs love!', 'emma is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'missie', 'missie needs love!', 'missie is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('letti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'letti@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'letti@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'letti@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'letti@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('vania', 'vania@gmail.com', 'A user of PCS', 'vaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vania@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'vania@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'vania@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'vania@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'vania@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('rory', 'rory@gmail.com', 'A user of PCS', 'rorypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rory@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rory@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rory@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rory@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rory@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rory@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jany', 'jany@gmail.com', 'A user of PCS', 'janypw');
INSERT INTO PetOwners(email) VALUES ('jany@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'gibson', 'gibson needs love!', 'gibson is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'poochie', 'poochie needs love!', 'poochie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('karlis', 'karlis@gmail.com', 'A user of PCS', 'karlispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'karlis@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'karlis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'karlis@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ronny', 'ronny@gmail.com', 'A user of PCS', 'ronnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'ronny@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'ronny@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronny@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronny@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('wilton', 'wilton@gmail.com', 'A user of PCS', 'wiltonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'wilton@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilton@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('hasheem', 'hasheem@gmail.com', 'A user of PCS', 'hasheempw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hasheem@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hasheem@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hasheem@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('adriane', 'adriane@gmail.com', 'A user of PCS', 'adrianepw');
INSERT INTO PetOwners(email) VALUES ('adriane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'iris', 'iris needs love!', 'iris is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('cortney', 'cortney@gmail.com', 'A user of PCS', 'cortneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cortney@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'cortney@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'cortney@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'cortney@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'cortney@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'cortney@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cortney@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cortney@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('emilie', 'emilie@gmail.com', 'A user of PCS', 'emiliepw');
INSERT INTO PetOwners(email) VALUES ('emilie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emilie@gmail.com', 'cindy', 'cindy needs love!', 'cindy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('merry', 'merry@gmail.com', 'A user of PCS', 'merrypw');
INSERT INTO PetOwners(email) VALUES ('merry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'mango', 'mango needs love!', 'mango is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'ming', 'ming needs love!', 'ming is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'scout', 'scout needs love!', 'scout is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'roxanne', 'roxanne needs love!', 'roxanne is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('andee', 'andee@gmail.com', 'A user of PCS', 'andeepw');
INSERT INTO PetOwners(email) VALUES ('andee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'gypsy', 'gypsy needs love!', 'gypsy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'jimmuy', 'jimmuy needs love!', 'jimmuy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'sierra', 'sierra needs love!', 'sierra is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'rico', 'rico needs love!', 'rico is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('annabal', 'annabal@gmail.com', 'A user of PCS', 'annabalpw');
INSERT INTO PetOwners(email) VALUES ('annabal@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('annabal@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annabal@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'annabal@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('desmond', 'desmond@gmail.com', 'A user of PCS', 'desmondpw');
INSERT INTO PetOwners(email) VALUES ('desmond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desmond@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desmond@gmail.com', 'coal', 'coal needs love!', 'coal is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desmond@gmail.com', 'domino', 'domino needs love!', 'domino is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desmond@gmail.com', 'laddie', 'laddie needs love!', 'laddie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('gaylord', 'gaylord@gmail.com', 'A user of PCS', 'gaylordpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gaylord@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gaylord@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gaylord@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gaylord@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gaylord@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gaylord@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gaylord@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('isiahi', 'isiahi@gmail.com', 'A user of PCS', 'isiahipw');
INSERT INTO PetOwners(email) VALUES ('isiahi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isiahi@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isiahi@gmail.com', 'rudy', 'rudy needs love!', 'rudy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isiahi@gmail.com', 'riley', 'riley needs love!', 'riley is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('charyl', 'charyl@gmail.com', 'A user of PCS', 'charylpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charyl@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'charyl@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'charyl@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'charyl@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charyl@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gallagher', 'gallagher@gmail.com', 'A user of PCS', 'gallagherpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gallagher@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'gallagher@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'gallagher@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'gallagher@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'gallagher@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gallagher@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gallagher@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('syd', 'syd@gmail.com', 'A user of PCS', 'sydpw');
INSERT INTO PetOwners(email) VALUES ('syd@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'logan', 'logan needs love!', 'logan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'kasey', 'kasey needs love!', 'kasey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('trevor', 'trevor@gmail.com', 'A user of PCS', 'trevorpw');
INSERT INTO PetOwners(email) VALUES ('trevor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'layla', 'layla needs love!', 'layla is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('estrella', 'estrella@gmail.com', 'A user of PCS', 'estrellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estrella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'estrella@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'estrella@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'estrella@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estrella@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estrella@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ailey', 'ailey@gmail.com', 'A user of PCS', 'aileypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ailey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'ailey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'ailey@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'ailey@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'ailey@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ailey@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ailey@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('abram', 'abram@gmail.com', 'A user of PCS', 'abrampw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abram@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'abram@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'abram@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (197, 'abram@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'abram@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abram@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abram@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('basilio', 'basilio@gmail.com', 'A user of PCS', 'basiliopw');
INSERT INTO PetOwners(email) VALUES ('basilio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('basilio@gmail.com', 'aldo', 'aldo needs love!', 'aldo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('basilio@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('basilio@gmail.com', 'isabella', 'isabella needs love!', 'isabella is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('basilio@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'basilio@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'basilio@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'basilio@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('basilio@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('basilio@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('starla', 'starla@gmail.com', 'A user of PCS', 'starlapw');
INSERT INTO PetOwners(email) VALUES ('starla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'silky', 'silky needs love!', 'silky is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'onie', 'onie needs love!', 'onie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('mariejeanne', 'mariejeanne@gmail.com', 'A user of PCS', 'mariejeannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariejeanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mariejeanne@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'mariejeanne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'mariejeanne@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mariejeanne@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mariejeanne@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('wallis', 'wallis@gmail.com', 'A user of PCS', 'wallispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wallis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'wallis@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallis@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallis@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('michal', 'michal@gmail.com', 'A user of PCS', 'michalpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michal@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'michal@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'michal@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michal@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('shurlock', 'shurlock@gmail.com', 'A user of PCS', 'shurlockpw');
INSERT INTO PetOwners(email) VALUES ('shurlock@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'latte', 'latte needs love!', 'latte is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'parker', 'parker needs love!', 'parker is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('cissiee', 'cissiee@gmail.com', 'A user of PCS', 'cissieepw');
INSERT INTO PetOwners(email) VALUES ('cissiee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'nicky', 'nicky needs love!', 'nicky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'sarge', 'sarge needs love!', 'sarge is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('brianna', 'brianna@gmail.com', 'A user of PCS', 'briannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brianna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'brianna@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'brianna@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'brianna@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'brianna@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianna@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianna@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('esther', 'esther@gmail.com', 'A user of PCS', 'estherpw');
INSERT INTO PetOwners(email) VALUES ('esther@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'bully', 'bully needs love!', 'bully is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esther@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'esther@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('esther@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('esther@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('anthiathia', 'anthiathia@gmail.com', 'A user of PCS', 'anthiathiapw');
INSERT INTO PetOwners(email) VALUES ('anthiathia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anthiathia@gmail.com', 'beau', 'beau needs love!', 'beau is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anthiathia@gmail.com', 'kid', 'kid needs love!', 'kid is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('margarette', 'margarette@gmail.com', 'A user of PCS', 'margarettepw');
INSERT INTO PetOwners(email) VALUES ('margarette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'jess', 'jess needs love!', 'jess is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'genie', 'genie needs love!', 'genie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'dash', 'dash needs love!', 'dash is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('ollie', 'ollie@gmail.com', 'A user of PCS', 'olliepw');
INSERT INTO PetOwners(email) VALUES ('ollie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ollie@gmail.com', 'bones', 'bones needs love!', 'bones is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ollie@gmail.com', 'booker', 'booker needs love!', 'booker is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ollie@gmail.com', 'simone', 'simone needs love!', 'simone is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ollie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ollie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ollie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ollie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ollie@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('filia', 'filia@gmail.com', 'A user of PCS', 'filiapw');
INSERT INTO PetOwners(email) VALUES ('filia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'hobbes', 'hobbes needs love!', 'hobbes is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'ebony', 'ebony needs love!', 'ebony is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (262, 'filia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'filia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'filia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'filia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'filia@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filia@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filia@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('garek', 'garek@gmail.com', 'A user of PCS', 'garekpw');
INSERT INTO PetOwners(email) VALUES ('garek@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garek@gmail.com', 'skipper', 'skipper needs love!', 'skipper is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garek@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'garek@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (230, 'garek@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'garek@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'garek@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garek@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garek@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('adena', 'adena@gmail.com', 'A user of PCS', 'adenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'adena@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'adena@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('eddi', 'eddi@gmail.com', 'A user of PCS', 'eddipw');
INSERT INTO PetOwners(email) VALUES ('eddi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddi@gmail.com', 'laddie', 'laddie needs love!', 'laddie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddi@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddi@gmail.com', 'macy', 'macy needs love!', 'macy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddi@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('chrissy', 'chrissy@gmail.com', 'A user of PCS', 'chrissypw');
INSERT INTO PetOwners(email) VALUES ('chrissy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrissy@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrissy@gmail.com', 'bruno', 'bruno needs love!', 'bruno is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrissy@gmail.com', 'pete', 'pete needs love!', 'pete is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrissy@gmail.com', 'moses', 'moses needs love!', 'moses is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('johann', 'johann@gmail.com', 'A user of PCS', 'johannpw');
INSERT INTO PetOwners(email) VALUES ('johann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'chivas', 'chivas needs love!', 'chivas is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'india', 'india needs love!', 'india is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('alfonse', 'alfonse@gmail.com', 'A user of PCS', 'alfonsepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alfonse@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alfonse@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'alfonse@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'alfonse@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfonse@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('mordecai', 'mordecai@gmail.com', 'A user of PCS', 'mordecaipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mordecai@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'mordecai@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'mordecai@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'mordecai@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'mordecai@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'mordecai@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mordecai@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mordecai@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('ira', 'ira@gmail.com', 'A user of PCS', 'irapw');
INSERT INTO PetOwners(email) VALUES ('ira@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ira@gmail.com', 'ally', 'ally needs love!', 'ally is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('mattias', 'mattias@gmail.com', 'A user of PCS', 'mattiaspw');
INSERT INTO PetOwners(email) VALUES ('mattias@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'axle', 'axle needs love!', 'axle is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mattias@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'mattias@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'mattias@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'mattias@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mattias@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mattias@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('carrol', 'carrol@gmail.com', 'A user of PCS', 'carrolpw');
INSERT INTO PetOwners(email) VALUES ('carrol@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carrol@gmail.com', 'aj', 'aj needs love!', 'aj is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carrol@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('tanner', 'tanner@gmail.com', 'A user of PCS', 'tannerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tanner@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tanner@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('florida', 'florida@gmail.com', 'A user of PCS', 'floridapw');
INSERT INTO PetOwners(email) VALUES ('florida@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florida@gmail.com', 'brook', 'brook needs love!', 'brook is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florida@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('elie', 'elie@gmail.com', 'A user of PCS', 'eliepw');
INSERT INTO PetOwners(email) VALUES ('elie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'schultz', 'schultz needs love!', 'schultz is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'pandora', 'pandora needs love!', 'pandora is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'elie@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('natividad', 'natividad@gmail.com', 'A user of PCS', 'natividadpw');
INSERT INTO PetOwners(email) VALUES ('natividad@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'paddy', 'paddy needs love!', 'paddy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'slick', 'slick needs love!', 'slick is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'kali', 'kali needs love!', 'kali is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'bishop', 'bishop needs love!', 'bishop is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'benji', 'benji needs love!', 'benji is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('natividad@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'natividad@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natividad@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natividad@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('karolina', 'karolina@gmail.com', 'A user of PCS', 'karolinapw');
INSERT INTO PetOwners(email) VALUES ('karolina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karolina@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karolina@gmail.com', 'kujo', 'kujo needs love!', 'kujo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karolina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'karolina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'karolina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'karolina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'karolina@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karolina@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karolina@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('graig', 'graig@gmail.com', 'A user of PCS', 'graigpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('graig@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'graig@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'graig@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('graig@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('graig@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('gretal', 'gretal@gmail.com', 'A user of PCS', 'gretalpw');
INSERT INTO PetOwners(email) VALUES ('gretal@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'gator', 'gator needs love!', 'gator is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'dante', 'dante needs love!', 'dante is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ringo', 'ringo@gmail.com', 'A user of PCS', 'ringopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ringo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'ringo@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'ringo@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ringo@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ringo@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('rick', 'rick@gmail.com', 'A user of PCS', 'rickpw');
INSERT INTO PetOwners(email) VALUES ('rick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'heather', 'heather needs love!', 'heather is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('dominga', 'dominga@gmail.com', 'A user of PCS', 'domingapw');
INSERT INTO PetOwners(email) VALUES ('dominga@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'ralph', 'ralph needs love!', 'ralph is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'gromit', 'gromit needs love!', 'gromit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('shellie', 'shellie@gmail.com', 'A user of PCS', 'shelliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shellie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shellie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shellie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shellie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shellie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('joshua', 'joshua@gmail.com', 'A user of PCS', 'joshuapw');
INSERT INTO PetOwners(email) VALUES ('joshua@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'riggs', 'riggs needs love!', 'riggs is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joshua@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'joshua@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'joshua@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'joshua@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (259, 'joshua@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joshua@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joshua@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('kimbell', 'kimbell@gmail.com', 'A user of PCS', 'kimbellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kimbell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kimbell@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lauree', 'lauree@gmail.com', 'A user of PCS', 'laureepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lauree@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lauree@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'lauree@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lauree@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lauree@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'lauree@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lauree@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('susanne', 'susanne@gmail.com', 'A user of PCS', 'susannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('susanne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'susanne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'susanne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'susanne@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susanne@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fara', 'fara@gmail.com', 'A user of PCS', 'farapw');
INSERT INTO PetOwners(email) VALUES ('fara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fara@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'fara@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fara@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fara@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fara@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fara@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gwendolin', 'gwendolin@gmail.com', 'A user of PCS', 'gwendolinpw');
INSERT INTO PetOwners(email) VALUES ('gwendolin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'lexi', 'lexi needs love!', 'lexi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'chiquita', 'chiquita needs love!', 'chiquita is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('rodina', 'rodina@gmail.com', 'A user of PCS', 'rodinapw');
INSERT INTO PetOwners(email) VALUES ('rodina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'dragster', 'dragster needs love!', 'dragster is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rodina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rodina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rodina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rodina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rodina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rodina@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('hazlett', 'hazlett@gmail.com', 'A user of PCS', 'hazlettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hazlett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'hazlett@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hazlett@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hazlett@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('sherilyn', 'sherilyn@gmail.com', 'A user of PCS', 'sherilynpw');
INSERT INTO PetOwners(email) VALUES ('sherilyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherilyn@gmail.com', 'india', 'india needs love!', 'india is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherilyn@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherilyn@gmail.com', 'monster', 'monster needs love!', 'monster is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sherilyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'sherilyn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sherilyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (272, 'sherilyn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'sherilyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'sherilyn@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherilyn@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherilyn@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('lucille', 'lucille@gmail.com', 'A user of PCS', 'lucillepw');
INSERT INTO PetOwners(email) VALUES ('lucille@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lucille@gmail.com', 'abel', 'abel needs love!', 'abel is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucille@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lucille@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lucille@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lucille@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tonnie', 'tonnie@gmail.com', 'A user of PCS', 'tonniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tonnie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tonnie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tonnie@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonnie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcello', 'marcello@gmail.com', 'A user of PCS', 'marcellopw');
INSERT INTO PetOwners(email) VALUES ('marcello@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcello@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('tuck', 'tuck@gmail.com', 'A user of PCS', 'tuckpw');
INSERT INTO PetOwners(email) VALUES ('tuck@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'presley', 'presley needs love!', 'presley is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'mona', 'mona needs love!', 'mona is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'jersey', 'jersey needs love!', 'jersey is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tuck@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'tuck@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'tuck@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (272, 'tuck@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'tuck@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'tuck@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tuck@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tuck@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('benita', 'benita@gmail.com', 'A user of PCS', 'benitapw');
INSERT INTO PetOwners(email) VALUES ('benita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benita@gmail.com', 'indy', 'indy needs love!', 'indy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benita@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('carolan', 'carolan@gmail.com', 'A user of PCS', 'carolanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carolan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'carolan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carolan@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carolan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carolan@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'carolan@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carolan@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('katti', 'katti@gmail.com', 'A user of PCS', 'kattipw');
INSERT INTO PetOwners(email) VALUES ('katti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'ladybug', 'ladybug needs love!', 'ladybug is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'monster', 'monster needs love!', 'monster is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'faith', 'faith needs love!', 'faith is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('sandro', 'sandro@gmail.com', 'A user of PCS', 'sandropw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sandro@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'sandro@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'sandro@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sandro@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sandro@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('nels', 'nels@gmail.com', 'A user of PCS', 'nelspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nels@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'nels@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'nels@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'nels@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (240, 'nels@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'nels@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nels@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nels@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('brena', 'brena@gmail.com', 'A user of PCS', 'brenapw');
INSERT INTO PetOwners(email) VALUES ('brena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'cocoa', 'cocoa needs love!', 'cocoa is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'bubbles', 'bubbles needs love!', 'bubbles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'rin tin tin', 'rin tin tin needs love!', 'rin tin tin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('tedman', 'tedman@gmail.com', 'A user of PCS', 'tedmanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tedman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'tedman@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'tedman@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'tedman@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'tedman@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tedman@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tedman@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('delphinia', 'delphinia@gmail.com', 'A user of PCS', 'delphiniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('delphinia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'delphinia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'delphinia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'delphinia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'delphinia@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('delphinia@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('delphinia@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('ladonna', 'ladonna@gmail.com', 'A user of PCS', 'ladonnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ladonna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'ladonna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (241, 'ladonna@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (255, 'ladonna@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ladonna@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ladonna@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('eddy', 'eddy@gmail.com', 'A user of PCS', 'eddypw');
INSERT INTO PetOwners(email) VALUES ('eddy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'persy', 'persy needs love!', 'persy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'brando', 'brando needs love!', 'brando is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'bozley', 'bozley needs love!', 'bozley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'kipper', 'kipper needs love!', 'kipper is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eddy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'eddy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'eddy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'eddy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'eddy@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eddy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('reine', 'reine@gmail.com', 'A user of PCS', 'reinepw');
INSERT INTO PetOwners(email) VALUES ('reine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reine@gmail.com', 'gibson', 'gibson needs love!', 'gibson is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reine@gmail.com', 'claire', 'claire needs love!', 'claire is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reine@gmail.com', 'ruchus', 'ruchus needs love!', 'ruchus is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('rosalinda', 'rosalinda@gmail.com', 'A user of PCS', 'rosalindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosalinda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'rosalinda@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosalinda@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosalinda@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('clareta', 'clareta@gmail.com', 'A user of PCS', 'claretapw');
INSERT INTO PetOwners(email) VALUES ('clareta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clareta@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clareta@gmail.com', 'shelby', 'shelby needs love!', 'shelby is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clareta@gmail.com', 'levi', 'levi needs love!', 'levi is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clareta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'clareta@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'clareta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (264, 'clareta@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'clareta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'clareta@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('lianne', 'lianne@gmail.com', 'A user of PCS', 'liannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lianne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lianne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lianne@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'lianne@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('harbert', 'harbert@gmail.com', 'A user of PCS', 'harbertpw');
INSERT INTO PetOwners(email) VALUES ('harbert@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harbert@gmail.com', 'ginny', 'ginny needs love!', 'ginny is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harbert@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harbert@gmail.com', 'smokey', 'smokey needs love!', 'smokey is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harbert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'harbert@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'harbert@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'harbert@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'harbert@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('irwinn', 'irwinn@gmail.com', 'A user of PCS', 'irwinnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('irwinn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'irwinn@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'irwinn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'irwinn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'irwinn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'irwinn@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('zea', 'zea@gmail.com', 'A user of PCS', 'zeapw');
INSERT INTO PetOwners(email) VALUES ('zea@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zea@gmail.com', 'skinny', 'skinny needs love!', 'skinny is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zea@gmail.com', 'rocket', 'rocket needs love!', 'rocket is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zea@gmail.com', 'nana', 'nana needs love!', 'nana is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zea@gmail.com', 'may', 'may needs love!', 'may is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'zea@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'zea@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'zea@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zea@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zea@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('glen', 'glen@gmail.com', 'A user of PCS', 'glenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'glen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'glen@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glen@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glen@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('ingeborg', 'ingeborg@gmail.com', 'A user of PCS', 'ingeborgpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ingeborg@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'ingeborg@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingeborg@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingeborg@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('toiboid', 'toiboid@gmail.com', 'A user of PCS', 'toiboidpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('toiboid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'toiboid@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'toiboid@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'toiboid@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('toiboid@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('toiboid@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('burtie', 'burtie@gmail.com', 'A user of PCS', 'burtiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burtie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'burtie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'burtie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'burtie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'burtie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burtie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('carmelina', 'carmelina@gmail.com', 'A user of PCS', 'carmelinapw');
INSERT INTO PetOwners(email) VALUES ('carmelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'hobbes', 'hobbes needs love!', 'hobbes is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'mister', 'mister needs love!', 'mister is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'bits', 'bits needs love!', 'bits is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'panda', 'panda needs love!', 'panda is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('rhianon', 'rhianon@gmail.com', 'A user of PCS', 'rhianonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rhianon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rhianon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rhianon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rhianon@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rhianon@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rhianon@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('bentlee', 'bentlee@gmail.com', 'A user of PCS', 'bentleepw');
INSERT INTO PetOwners(email) VALUES ('bentlee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bentlee@gmail.com', 'nickers', 'nickers needs love!', 'nickers is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bentlee@gmail.com', 'bradley', 'bradley needs love!', 'bradley is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bentlee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'bentlee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'bentlee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'bentlee@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bentlee@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bentlee@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('harv', 'harv@gmail.com', 'A user of PCS', 'harvpw');
INSERT INTO PetOwners(email) VALUES ('harv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harv@gmail.com', 'miasy', 'miasy needs love!', 'miasy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harv@gmail.com', 'grady', 'grady needs love!', 'grady is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harv@gmail.com', 'rhett', 'rhett needs love!', 'rhett is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harv@gmail.com', 'benson', 'benson needs love!', 'benson is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harv@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harv@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'harv@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'harv@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ezechiel', 'ezechiel@gmail.com', 'A user of PCS', 'ezechielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ezechiel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ezechiel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ezechiel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ezechiel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ezechiel@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('cathi', 'cathi@gmail.com', 'A user of PCS', 'cathipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cathi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cathi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cathi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cathi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cathi@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cathi@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('francesca', 'francesca@gmail.com', 'A user of PCS', 'francescapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francesca@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'francesca@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'francesca@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francesca@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francesca@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('laraine', 'laraine@gmail.com', 'A user of PCS', 'larainepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laraine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'laraine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'laraine@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laraine@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laraine@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('shay', 'shay@gmail.com', 'A user of PCS', 'shaypw');
INSERT INTO PetOwners(email) VALUES ('shay@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shay@gmail.com', 'mango', 'mango needs love!', 'mango is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('veda', 'veda@gmail.com', 'A user of PCS', 'vedapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('veda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'veda@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('veda@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('veda@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('mellie', 'mellie@gmail.com', 'A user of PCS', 'melliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mellie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'mellie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'mellie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'mellie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mellie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mellie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('melosa', 'melosa@gmail.com', 'A user of PCS', 'melosapw');
INSERT INTO PetOwners(email) VALUES ('melosa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melosa@gmail.com', 'basil', 'basil needs love!', 'basil is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melosa@gmail.com', 'bruiser', 'bruiser needs love!', 'bruiser is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melosa@gmail.com', 'picasso', 'picasso needs love!', 'picasso is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('meridel', 'meridel@gmail.com', 'A user of PCS', 'meridelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('meridel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'meridel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'meridel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'meridel@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'meridel@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('marylinda', 'marylinda@gmail.com', 'A user of PCS', 'marylindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marylinda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marylinda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marylinda@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('abrahan', 'abrahan@gmail.com', 'A user of PCS', 'abrahanpw');
INSERT INTO PetOwners(email) VALUES ('abrahan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('abrahan@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abrahan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'abrahan@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abrahan@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abrahan@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('hollie', 'hollie@gmail.com', 'A user of PCS', 'holliepw');
INSERT INTO PetOwners(email) VALUES ('hollie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hollie@gmail.com', 'dinky', 'dinky needs love!', 'dinky is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('sigismund', 'sigismund@gmail.com', 'A user of PCS', 'sigismundpw');
INSERT INTO PetOwners(email) VALUES ('sigismund@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigismund@gmail.com', 'basil', 'basil needs love!', 'basil is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigismund@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigismund@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sigismund@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sigismund@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sigismund@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sigismund@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sigismund@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigismund@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('reilly', 'reilly@gmail.com', 'A user of PCS', 'reillypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reilly@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'reilly@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'reilly@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reilly@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reilly@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ragnar', 'ragnar@gmail.com', 'A user of PCS', 'ragnarpw');
INSERT INTO PetOwners(email) VALUES ('ragnar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ragnar@gmail.com', 'mojo', 'mojo needs love!', 'mojo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ragnar@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ragnar@gmail.com', 'allie', 'allie needs love!', 'allie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ragnar@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ragnar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ragnar@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ragnar@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ragnar@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mitch', 'mitch@gmail.com', 'A user of PCS', 'mitchpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitch@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'mitch@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitch@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitch@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('drew', 'drew@gmail.com', 'A user of PCS', 'drewpw');
INSERT INTO PetOwners(email) VALUES ('drew@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'flint', 'flint needs love!', 'flint is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'montgomery', 'montgomery needs love!', 'montgomery is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'logan', 'logan needs love!', 'logan is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('hortense', 'hortense@gmail.com', 'A user of PCS', 'hortensepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hortense@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'hortense@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (231, 'hortense@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'hortense@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hortense@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hortense@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('lurette', 'lurette@gmail.com', 'A user of PCS', 'lurettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lurette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lurette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lurette@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lurette@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('farand', 'farand@gmail.com', 'A user of PCS', 'farandpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farand@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'farand@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'farand@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'farand@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'farand@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (274, 'farand@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('calv', 'calv@gmail.com', 'A user of PCS', 'calvpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('calv@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'calv@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('calv@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('calv@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('dolores', 'dolores@gmail.com', 'A user of PCS', 'dolorespw');
INSERT INTO PetOwners(email) VALUES ('dolores@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'josie', 'josie needs love!', 'josie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'abbey', 'abbey needs love!', 'abbey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'nala', 'nala needs love!', 'nala is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('barney', 'barney@gmail.com', 'A user of PCS', 'barneypw');
INSERT INTO PetOwners(email) VALUES ('barney@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'coco', 'coco needs love!', 'coco is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'austin', 'austin needs love!', 'austin is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('hoyt', 'hoyt@gmail.com', 'A user of PCS', 'hoytpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hoyt@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hoyt@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hoyt@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hoyt@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hoyt@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hoyt@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('willy', 'willy@gmail.com', 'A user of PCS', 'willypw');
INSERT INTO PetOwners(email) VALUES ('willy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'joker', 'joker needs love!', 'joker is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'holly', 'holly needs love!', 'holly is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'chivas', 'chivas needs love!', 'chivas is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'willy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'willy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'willy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'willy@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gavin', 'gavin@gmail.com', 'A user of PCS', 'gavinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gavin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'gavin@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gavin@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'gavin@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gavin@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gavin@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('katherina', 'katherina@gmail.com', 'A user of PCS', 'katherinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katherina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'katherina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'katherina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'katherina@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katherina@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katherina@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('pepi', 'pepi@gmail.com', 'A user of PCS', 'pepipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pepi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pepi@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jeromy', 'jeromy@gmail.com', 'A user of PCS', 'jeromypw');
INSERT INTO PetOwners(email) VALUES ('jeromy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeromy@gmail.com', 'miss kitty', 'miss kitty needs love!', 'miss kitty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeromy@gmail.com', 'ellie', 'ellie needs love!', 'ellie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeromy@gmail.com', 'holly', 'holly needs love!', 'holly is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeromy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jeromy@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('palmer', 'palmer@gmail.com', 'A user of PCS', 'palmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('palmer@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'palmer@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('palmer@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('isa', 'isa@gmail.com', 'A user of PCS', 'isapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'isa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'isa@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isa@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isa@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('gwyn', 'gwyn@gmail.com', 'A user of PCS', 'gwynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'gwyn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'gwyn@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwyn@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwyn@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('cathlene', 'cathlene@gmail.com', 'A user of PCS', 'cathlenepw');
INSERT INTO PetOwners(email) VALUES ('cathlene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'casper', 'casper needs love!', 'casper is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'dandy', 'dandy needs love!', 'dandy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cathlene@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cathlene@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathlene@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathlene@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('sigfrid', 'sigfrid@gmail.com', 'A user of PCS', 'sigfridpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigfrid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sigfrid@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sigfrid@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sigfrid@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sigfrid@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sigfrid@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigfrid@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('roxie', 'roxie@gmail.com', 'A user of PCS', 'roxiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roxie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'roxie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'roxie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('latisha', 'latisha@gmail.com', 'A user of PCS', 'latishapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latisha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'latisha@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (201, 'latisha@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'latisha@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('humfrid', 'humfrid@gmail.com', 'A user of PCS', 'humfridpw');
INSERT INTO PetOwners(email) VALUES ('humfrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'may', 'may needs love!', 'may is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'kenya', 'kenya needs love!', 'kenya is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'guy', 'guy needs love!', 'guy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humfrid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'humfrid@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'humfrid@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'humfrid@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('kylila', 'kylila@gmail.com', 'A user of PCS', 'kylilapw');
INSERT INTO PetOwners(email) VALUES ('kylila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kylila@gmail.com', 'binky', 'binky needs love!', 'binky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kylila@gmail.com', 'nikki', 'nikki needs love!', 'nikki is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kylila@gmail.com', 'sassy', 'sassy needs love!', 'sassy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kylila@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('harrison', 'harrison@gmail.com', 'A user of PCS', 'harrisonpw');
INSERT INTO PetOwners(email) VALUES ('harrison@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harrison@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harrison@gmail.com', 'montgomery', 'montgomery needs love!', 'montgomery is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('federico', 'federico@gmail.com', 'A user of PCS', 'federicopw');
INSERT INTO PetOwners(email) VALUES ('federico@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'harry', 'harry needs love!', 'harry is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('gennifer', 'gennifer@gmail.com', 'A user of PCS', 'genniferpw');
INSERT INTO PetOwners(email) VALUES ('gennifer@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'humphrey', 'humphrey needs love!', 'humphrey is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'cubs', 'cubs needs love!', 'cubs is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gennifer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'gennifer@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gennifer@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gennifer@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('gradeigh', 'gradeigh@gmail.com', 'A user of PCS', 'gradeighpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gradeigh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gradeigh@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('glad', 'glad@gmail.com', 'A user of PCS', 'gladpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glad@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'glad@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'glad@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'glad@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'glad@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'glad@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('haleigh', 'haleigh@gmail.com', 'A user of PCS', 'haleighpw');
INSERT INTO PetOwners(email) VALUES ('haleigh@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haleigh@gmail.com', 'mitzi', 'mitzi needs love!', 'mitzi is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('haleigh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'haleigh@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'haleigh@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'haleigh@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('audry', 'audry@gmail.com', 'A user of PCS', 'audrypw');
INSERT INTO PetOwners(email) VALUES ('audry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('audry@gmail.com', 'max', 'max needs love!', 'max is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('audry@gmail.com', 'oscar', 'oscar needs love!', 'oscar is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('audry@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'audry@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'audry@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('audry@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('allyce', 'allyce@gmail.com', 'A user of PCS', 'allycepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('allyce@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'allyce@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'allyce@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'allyce@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('shara', 'shara@gmail.com', 'A user of PCS', 'sharapw');
INSERT INTO PetOwners(email) VALUES ('shara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'dutches', 'dutches needs love!', 'dutches is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'pippy', 'pippy needs love!', 'pippy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'garfield', 'garfield needs love!', 'garfield is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('binny', 'binny@gmail.com', 'A user of PCS', 'binnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('binny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'binny@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'binny@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'binny@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'binny@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('binny@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('binny@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('babbette', 'babbette@gmail.com', 'A user of PCS', 'babbettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('babbette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'babbette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'babbette@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('genevieve', 'genevieve@gmail.com', 'A user of PCS', 'genevievepw');
INSERT INTO PetOwners(email) VALUES ('genevieve@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('genevieve@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('genevieve@gmail.com', 'furball', 'furball needs love!', 'furball is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('genevieve@gmail.com', 'oreo', 'oreo needs love!', 'oreo is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('genevieve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'genevieve@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'genevieve@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'genevieve@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('hersh', 'hersh@gmail.com', 'A user of PCS', 'hershpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hersh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hersh@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hersh@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hersh@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('yul', 'yul@gmail.com', 'A user of PCS', 'yulpw');
INSERT INTO PetOwners(email) VALUES ('yul@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yul@gmail.com', 'dutchess', 'dutchess needs love!', 'dutchess is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yul@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yul@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'yul@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('maxy', 'maxy@gmail.com', 'A user of PCS', 'maxypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maxy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'maxy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'maxy@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maxy@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maxy@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('cordell', 'cordell@gmail.com', 'A user of PCS', 'cordellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cordell@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'cordell@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cordell@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cordell@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('frayda', 'frayda@gmail.com', 'A user of PCS', 'fraydapw');
INSERT INTO PetOwners(email) VALUES ('frayda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frayda@gmail.com', 'king', 'king needs love!', 'king is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frayda@gmail.com', 'gabby', 'gabby needs love!', 'gabby is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('frayda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'frayda@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'frayda@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorry', 'dorry@gmail.com', 'A user of PCS', 'dorrypw');
INSERT INTO PetOwners(email) VALUES ('dorry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'corky', 'corky needs love!', 'corky is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'dorry@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorry@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorry@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ellyn', 'ellyn@gmail.com', 'A user of PCS', 'ellynpw');
INSERT INTO PetOwners(email) VALUES ('ellyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'lady', 'lady needs love!', 'lady is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'porky', 'porky needs love!', 'porky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'persy', 'persy needs love!', 'persy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ellyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ellyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ellyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ellyn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ellyn@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellyn@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('sidonia', 'sidonia@gmail.com', 'A user of PCS', 'sidoniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sidonia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'sidonia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'sidonia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'sidonia@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sidonia@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sidonia@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('jacky', 'jacky@gmail.com', 'A user of PCS', 'jackypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jacky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'jacky@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'jacky@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'jacky@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (178, 'jacky@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('burnard', 'burnard@gmail.com', 'A user of PCS', 'burnardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burnard@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'burnard@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burnard@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burnard@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('andrew', 'andrew@gmail.com', 'A user of PCS', 'andrewpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrew@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'andrew@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'andrew@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'andrew@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'andrew@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'andrew@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrew@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('rafaellle', 'rafaellle@gmail.com', 'A user of PCS', 'rafaelllepw');
INSERT INTO PetOwners(email) VALUES ('rafaellle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'boo', 'boo needs love!', 'boo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'louis', 'louis needs love!', 'louis is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'archie', 'archie needs love!', 'archie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'beans', 'beans needs love!', 'beans is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rafaellle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rafaellle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rafaellle@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rafaellle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rafaellle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rafaellle@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gretel', 'gretel@gmail.com', 'A user of PCS', 'gretelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gretel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gretel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gretel@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('neely', 'neely@gmail.com', 'A user of PCS', 'neelypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('neely@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'neely@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'neely@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'neely@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'neely@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'neely@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('shurlocke', 'shurlocke@gmail.com', 'A user of PCS', 'shurlockepw');
INSERT INTO PetOwners(email) VALUES ('shurlocke@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlocke@gmail.com', 'schultz', 'schultz needs love!', 'schultz is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlocke@gmail.com', 'crystal', 'crystal needs love!', 'crystal is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shurlocke@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'shurlocke@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('andrus', 'andrus@gmail.com', 'A user of PCS', 'andruspw');
INSERT INTO PetOwners(email) VALUES ('andrus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'bobby', 'bobby needs love!', 'bobby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'india', 'india needs love!', 'india is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'andrus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'andrus@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'andrus@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'andrus@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrus@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('nerta', 'nerta@gmail.com', 'A user of PCS', 'nertapw');
INSERT INTO PetOwners(email) VALUES ('nerta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'gasby', 'gasby needs love!', 'gasby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nerta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'nerta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nerta@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nerta@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('philippe', 'philippe@gmail.com', 'A user of PCS', 'philippepw');
INSERT INTO PetOwners(email) VALUES ('philippe@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philippe@gmail.com', 'hanna', 'hanna needs love!', 'hanna is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('philippe@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'philippe@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'philippe@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'philippe@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'philippe@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('philippe@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('alfreda', 'alfreda@gmail.com', 'A user of PCS', 'alfredapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alfreda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'alfreda@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alfreda@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('halie', 'halie@gmail.com', 'A user of PCS', 'haliepw');
INSERT INTO PetOwners(email) VALUES ('halie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'raison', 'raison needs love!', 'raison is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('halie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'halie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'halie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('halie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('taddeo', 'taddeo@gmail.com', 'A user of PCS', 'taddeopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('taddeo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'taddeo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'taddeo@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'taddeo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'taddeo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'taddeo@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('curcio', 'curcio@gmail.com', 'A user of PCS', 'curciopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('curcio@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'curcio@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'curcio@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'curcio@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'curcio@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('curcio@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('curcio@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('inglis', 'inglis@gmail.com', 'A user of PCS', 'inglispw');
INSERT INTO PetOwners(email) VALUES ('inglis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'nina', 'nina needs love!', 'nina is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'marley', 'marley needs love!', 'marley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'bullet', 'bullet needs love!', 'bullet is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'sadie', 'sadie needs love!', 'sadie is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('inglis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'inglis@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jessey', 'jessey@gmail.com', 'A user of PCS', 'jesseypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'jessey@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jessey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'jessey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'jessey@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessey@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessey@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('clemente', 'clemente@gmail.com', 'A user of PCS', 'clementepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clemente@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'clemente@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'clemente@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'clemente@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'clemente@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clemente@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clemente@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('trstram', 'trstram@gmail.com', 'A user of PCS', 'trstrampw');
INSERT INTO PetOwners(email) VALUES ('trstram@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trstram@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trstram@gmail.com', 'sara', 'sara needs love!', 'sara is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trstram@gmail.com', 'bosco', 'bosco needs love!', 'bosco is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('nita', 'nita@gmail.com', 'A user of PCS', 'nitapw');
INSERT INTO PetOwners(email) VALUES ('nita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nita@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nita@gmail.com', 'panda', 'panda needs love!', 'panda is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nita@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nita@gmail.com', 'mimi', 'mimi needs love!', 'mimi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nita@gmail.com', 'bella', 'bella needs love!', 'bella is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'nita@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'nita@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'nita@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nita@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nita@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('jerrine', 'jerrine@gmail.com', 'A user of PCS', 'jerrinepw');
INSERT INTO PetOwners(email) VALUES ('jerrine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jerrine@gmail.com', 'chucky', 'chucky needs love!', 'chucky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jerrine@gmail.com', 'connor', 'connor needs love!', 'connor is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jerrine@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jerrine@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jerrine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jerrine@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jerrine@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('herc', 'herc@gmail.com', 'A user of PCS', 'hercpw');
INSERT INTO PetOwners(email) VALUES ('herc@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'porkchop', 'porkchop needs love!', 'porkchop is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('ermin', 'ermin@gmail.com', 'A user of PCS', 'erminpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ermin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ermin@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jorey', 'jorey@gmail.com', 'A user of PCS', 'joreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jorey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jorey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jorey@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jorey@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jorey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jorey@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jorey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('somerset', 'somerset@gmail.com', 'A user of PCS', 'somersetpw');
INSERT INTO PetOwners(email) VALUES ('somerset@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'otto', 'otto needs love!', 'otto is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'pooh-bear', 'pooh-bear needs love!', 'pooh-bear is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('somerset@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'somerset@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'somerset@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'somerset@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'somerset@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('somerset@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('somerset@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('hervey', 'hervey@gmail.com', 'A user of PCS', 'herveypw');
INSERT INTO PetOwners(email) VALUES ('hervey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hervey@gmail.com', 'rocket', 'rocket needs love!', 'rocket is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hervey@gmail.com', 'jolly', 'jolly needs love!', 'jolly is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hervey@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hervey@gmail.com', 'marley', 'marley needs love!', 'marley is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hervey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'hervey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'hervey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'hervey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'hervey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'hervey@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hervey@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hervey@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('elsinore', 'elsinore@gmail.com', 'A user of PCS', 'elsinorepw');
INSERT INTO PetOwners(email) VALUES ('elsinore@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'eva', 'eva needs love!', 'eva is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'destini', 'destini needs love!', 'destini is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'clicker', 'clicker needs love!', 'clicker is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'piggy', 'piggy needs love!', 'piggy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'nugget', 'nugget needs love!', 'nugget is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('mandi', 'mandi@gmail.com', 'A user of PCS', 'mandipw');
INSERT INTO PetOwners(email) VALUES ('mandi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'miles', 'miles needs love!', 'miles is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'bebe', 'bebe needs love!', 'bebe is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'piggy', 'piggy needs love!', 'piggy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mandi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'mandi@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandi@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandi@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('sonny', 'sonny@gmail.com', 'A user of PCS', 'sonnypw');
INSERT INTO PetOwners(email) VALUES ('sonny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sonny@gmail.com', 'cheyenne', 'cheyenne needs love!', 'cheyenne is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sonny@gmail.com', 'dudley', 'dudley needs love!', 'dudley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sonny@gmail.com', 'maximus', 'maximus needs love!', 'maximus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sonny@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sonny@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('patti', 'patti@gmail.com', 'A user of PCS', 'pattipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patti@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'patti@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patti@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patti@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('forster', 'forster@gmail.com', 'A user of PCS', 'forsterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('forster@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'forster@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'forster@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (278, 'forster@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'forster@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'forster@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('forster@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('forster@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('dixie', 'dixie@gmail.com', 'A user of PCS', 'dixiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dixie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'dixie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'dixie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'dixie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'dixie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'dixie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dixie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dixie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('hale', 'hale@gmail.com', 'A user of PCS', 'halepw');
INSERT INTO PetOwners(email) VALUES ('hale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'buffy', 'buffy needs love!', 'buffy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('dorey', 'dorey@gmail.com', 'A user of PCS', 'doreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dorey@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('madel', 'madel@gmail.com', 'A user of PCS', 'madelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'madel@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madel@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madel@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('renee', 'renee@gmail.com', 'A user of PCS', 'reneepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('renee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'renee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'renee@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'renee@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('renee@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('janos', 'janos@gmail.com', 'A user of PCS', 'janospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janos@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'janos@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'janos@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'janos@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janos@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janos@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('willetta', 'willetta@gmail.com', 'A user of PCS', 'willettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'willetta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'willetta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'willetta@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'willetta@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willetta@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('arlena', 'arlena@gmail.com', 'A user of PCS', 'arlenapw');
INSERT INTO PetOwners(email) VALUES ('arlena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'riggs', 'riggs needs love!', 'riggs is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'porky', 'porky needs love!', 'porky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('aubine', 'aubine@gmail.com', 'A user of PCS', 'aubinepw');
INSERT INTO PetOwners(email) VALUES ('aubine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aubine@gmail.com', 'jesse james', 'jesse james needs love!', 'jesse james is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('fenelia', 'fenelia@gmail.com', 'A user of PCS', 'feneliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fenelia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'fenelia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'fenelia@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fenelia@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fenelia@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('bail', 'bail@gmail.com', 'A user of PCS', 'bailpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bail@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bail@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('trudey', 'trudey@gmail.com', 'A user of PCS', 'trudeypw');
INSERT INTO PetOwners(email) VALUES ('trudey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'cole', 'cole needs love!', 'cole is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trudey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'trudey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'trudey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'trudey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (242, 'trudey@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'trudey@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trudey@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trudey@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('theobald', 'theobald@gmail.com', 'A user of PCS', 'theobaldpw');
INSERT INTO PetOwners(email) VALUES ('theobald@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'iris', 'iris needs love!', 'iris is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'ally', 'ally needs love!', 'ally is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('goldi', 'goldi@gmail.com', 'A user of PCS', 'goldipw');
INSERT INTO PetOwners(email) VALUES ('goldi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'jenny', 'jenny needs love!', 'jenny is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('helen-elizabeth', 'helen-elizabeth@gmail.com', 'A user of PCS', 'helen-elizabethpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('helen-elizabeth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'helen-elizabeth@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ric', 'ric@gmail.com', 'A user of PCS', 'ricpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ric@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ric@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ric@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ric@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ric@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ric@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ric@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('minne', 'minne@gmail.com', 'A user of PCS', 'minnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('minne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'minne@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('minne@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('minne@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('alex', 'alex@gmail.com', 'A user of PCS', 'alexpw');
INSERT INTO PetOwners(email) VALUES ('alex@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'king', 'king needs love!', 'king is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'beauty', 'beauty needs love!', 'beauty is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alex@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'alex@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('beckie', 'beckie@gmail.com', 'A user of PCS', 'beckiepw');
INSERT INTO PetOwners(email) VALUES ('beckie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'pooh', 'pooh needs love!', 'pooh is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'dash', 'dash needs love!', 'dash is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'magic', 'magic needs love!', 'magic is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'chic', 'chic needs love!', 'chic is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'phoebe', 'phoebe needs love!', 'phoebe is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('berton', 'berton@gmail.com', 'A user of PCS', 'bertonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('berton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'berton@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'berton@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('natalina', 'natalina@gmail.com', 'A user of PCS', 'natalinapw');
INSERT INTO PetOwners(email) VALUES ('natalina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'mariah', 'mariah needs love!', 'mariah is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('lamar', 'lamar@gmail.com', 'A user of PCS', 'lamarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lamar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lamar@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lamar@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('maurene', 'maurene@gmail.com', 'A user of PCS', 'maurenepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maurene@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'maurene@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurene@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('sara-ann', 'sara-ann@gmail.com', 'A user of PCS', 'sara-annpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sara-ann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sara-ann@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sara-ann@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorthy', 'dorthy@gmail.com', 'A user of PCS', 'dorthypw');
INSERT INTO PetOwners(email) VALUES ('dorthy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('leonardo', 'leonardo@gmail.com', 'A user of PCS', 'leonardopw');
INSERT INTO PetOwners(email) VALUES ('leonardo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leonardo@gmail.com', 'buddie', 'buddie needs love!', 'buddie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leonardo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'leonardo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'leonardo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'leonardo@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leonardo@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mike', 'mike@gmail.com', 'A user of PCS', 'mikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mike@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'mike@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mike@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('leo', 'leo@gmail.com', 'A user of PCS', 'leopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'leo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'leo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'leo@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('shem', 'shem@gmail.com', 'A user of PCS', 'shempw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shem@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shem@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shem@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shem@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shem@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shem@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('marni', 'marni@gmail.com', 'A user of PCS', 'marnipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marni@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marni@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marni@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'marni@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'marni@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('craig', 'craig@gmail.com', 'A user of PCS', 'craigpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('craig@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'craig@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'craig@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('craig@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('sibel', 'sibel@gmail.com', 'A user of PCS', 'sibelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'sibel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'sibel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'sibel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'sibel@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('parry', 'parry@gmail.com', 'A user of PCS', 'parrypw');
INSERT INTO PetOwners(email) VALUES ('parry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('parry@gmail.com', 'piper', 'piper needs love!', 'piper is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('parry@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'parry@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('parry@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tallie', 'tallie@gmail.com', 'A user of PCS', 'talliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'tallie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'tallie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'tallie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tallie@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallie@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferdinande', 'ferdinande@gmail.com', 'A user of PCS', 'ferdinandepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferdinande@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'ferdinande@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferdinande@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferdinande@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('iago', 'iago@gmail.com', 'A user of PCS', 'iagopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iago@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'iago@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iago@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('marie-jeanne', 'marie-jeanne@gmail.com', 'A user of PCS', 'marie-jeannepw');
INSERT INTO PetOwners(email) VALUES ('marie-jeanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-jeanne@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marie-jeanne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marie-jeanne@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-jeanne@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mavis', 'mavis@gmail.com', 'A user of PCS', 'mavispw');
INSERT INTO PetOwners(email) VALUES ('mavis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'midnight', 'midnight needs love!', 'midnight is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'cody', 'cody needs love!', 'cody is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mavis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'mavis@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mavis@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'mavis@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'mavis@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'mavis@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mavis@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mavis@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('cassius', 'cassius@gmail.com', 'A user of PCS', 'cassiuspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassius@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'cassius@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'cassius@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cassius@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cassius@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('andrej', 'andrej@gmail.com', 'A user of PCS', 'andrejpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrej@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'andrej@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'andrej@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorris', 'dorris@gmail.com', 'A user of PCS', 'dorrispw');
INSERT INTO PetOwners(email) VALUES ('dorris@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorris@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('elsworth', 'elsworth@gmail.com', 'A user of PCS', 'elsworthpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsworth@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'elsworth@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsworth@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsworth@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('jodee', 'jodee@gmail.com', 'A user of PCS', 'jodeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jodee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'jodee@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'jodee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'jodee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'jodee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'jodee@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jodee@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jodee@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('darbee', 'darbee@gmail.com', 'A user of PCS', 'darbeepw');
INSERT INTO PetOwners(email) VALUES ('darbee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'kayla', 'kayla needs love!', 'kayla is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'madison', 'madison needs love!', 'madison is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('viva', 'viva@gmail.com', 'A user of PCS', 'vivapw');
INSERT INTO PetOwners(email) VALUES ('viva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('viva@gmail.com', 'cocoa', 'cocoa needs love!', 'cocoa is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('viva@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('viva@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('viva@gmail.com', 'rocky', 'rocky needs love!', 'rocky is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('viva@gmail.com', 'nakita', 'nakita needs love!', 'nakita is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('cash', 'cash@gmail.com', 'A user of PCS', 'cashpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cash@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cash@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'cash@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'cash@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'cash@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'cash@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('harper', 'harper@gmail.com', 'A user of PCS', 'harperpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harper@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'harper@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'harper@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'harper@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'harper@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harper@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harper@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('donnajean', 'donnajean@gmail.com', 'A user of PCS', 'donnajeanpw');
INSERT INTO PetOwners(email) VALUES ('donnajean@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'sandy', 'sandy needs love!', 'sandy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'meadow', 'meadow needs love!', 'meadow is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'boo', 'boo needs love!', 'boo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('tomasine', 'tomasine@gmail.com', 'A user of PCS', 'tomasinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tomasine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tomasine@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tomasine@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kiersten', 'kiersten@gmail.com', 'A user of PCS', 'kierstenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kiersten@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (253, 'kiersten@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'kiersten@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'kiersten@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'kiersten@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'kiersten@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kiersten@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kiersten@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('katrinka', 'katrinka@gmail.com', 'A user of PCS', 'katrinkapw');
INSERT INTO PetOwners(email) VALUES ('katrinka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katrinka@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katrinka@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katrinka@gmail.com', 'queen', 'queen needs love!', 'queen is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katrinka@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'katrinka@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'katrinka@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katrinka@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('misty', 'misty@gmail.com', 'A user of PCS', 'mistypw');
INSERT INTO PetOwners(email) VALUES ('misty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('misty@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('misty@gmail.com', 'bacchus', 'bacchus needs love!', 'bacchus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('misty@gmail.com', 'lucky', 'lucky needs love!', 'lucky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('misty@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('misty@gmail.com', 'chubbs', 'chubbs needs love!', 'chubbs is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('egan', 'egan@gmail.com', 'A user of PCS', 'eganpw');
INSERT INTO PetOwners(email) VALUES ('egan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'porter', 'porter needs love!', 'porter is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'madison', 'madison needs love!', 'madison is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('egan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'egan@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'egan@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'egan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'egan@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'egan@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egan@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egan@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('garvy', 'garvy@gmail.com', 'A user of PCS', 'garvypw');
INSERT INTO PetOwners(email) VALUES ('garvy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garvy@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garvy@gmail.com', 'charlie brown', 'charlie brown needs love!', 'charlie brown is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garvy@gmail.com', 'jamie', 'jamie needs love!', 'jamie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garvy@gmail.com', 'puffy', 'puffy needs love!', 'puffy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garvy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'garvy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'garvy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'garvy@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('erv', 'erv@gmail.com', 'A user of PCS', 'ervpw');
INSERT INTO PetOwners(email) VALUES ('erv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'onyx', 'onyx needs love!', 'onyx is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'connor', 'connor needs love!', 'connor is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'baron', 'baron needs love!', 'baron is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erv@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'erv@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erv@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gerard', 'gerard@gmail.com', 'A user of PCS', 'gerardpw');
INSERT INTO PetOwners(email) VALUES ('gerard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'luke', 'luke needs love!', 'luke is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gerard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gerard@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gerard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gerard@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gerard@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('fernando', 'fernando@gmail.com', 'A user of PCS', 'fernandopw');
INSERT INTO PetOwners(email) VALUES ('fernando@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fernando@gmail.com', 'bernie', 'bernie needs love!', 'bernie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('lev', 'lev@gmail.com', 'A user of PCS', 'levpw');
INSERT INTO PetOwners(email) VALUES ('lev@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'mister', 'mister needs love!', 'mister is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'dusty', 'dusty needs love!', 'dusty is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('marcie', 'marcie@gmail.com', 'A user of PCS', 'marciepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'marcie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcie@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('abagael', 'abagael@gmail.com', 'A user of PCS', 'abagaelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abagael@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'abagael@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'abagael@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'abagael@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abagael@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abagael@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('verla', 'verla@gmail.com', 'A user of PCS', 'verlapw');
INSERT INTO PetOwners(email) VALUES ('verla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'earl', 'earl needs love!', 'earl is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'mimi', 'mimi needs love!', 'mimi is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('verla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'verla@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('verla@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('verla@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('rowe', 'rowe@gmail.com', 'A user of PCS', 'rowepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rowe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'rowe@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rowe@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'rowe@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'rowe@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'rowe@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rowe@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rowe@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('kayley', 'kayley@gmail.com', 'A user of PCS', 'kayleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kayley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'kayley@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'kayley@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'kayley@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'kayley@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'kayley@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('dwayne', 'dwayne@gmail.com', 'A user of PCS', 'dwaynepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dwayne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dwayne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dwayne@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dwayne@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwayne@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('stephi', 'stephi@gmail.com', 'A user of PCS', 'stephipw');
INSERT INTO PetOwners(email) VALUES ('stephi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'armanti', 'armanti needs love!', 'armanti is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'marble', 'marble needs love!', 'marble is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'autumn', 'autumn needs love!', 'autumn is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('godfrey', 'godfrey@gmail.com', 'A user of PCS', 'godfreypw');
INSERT INTO PetOwners(email) VALUES ('godfrey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('godfrey@gmail.com', 'nicky', 'nicky needs love!', 'nicky is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('zenia', 'zenia@gmail.com', 'A user of PCS', 'zeniapw');
INSERT INTO PetOwners(email) VALUES ('zenia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zenia@gmail.com', 'missie', 'missie needs love!', 'missie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zenia@gmail.com', 'gator', 'gator needs love!', 'gator is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zenia@gmail.com', 'bobbie', 'bobbie needs love!', 'bobbie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zenia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'zenia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'zenia@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('janella', 'janella@gmail.com', 'A user of PCS', 'janellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (225, 'janella@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janella@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janella@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('ravi', 'ravi@gmail.com', 'A user of PCS', 'ravipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ravi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ravi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ravi@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ravi@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ravi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ravi@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ansell', 'ansell@gmail.com', 'A user of PCS', 'ansellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ansell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ansell@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ansell@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('atalanta', 'atalanta@gmail.com', 'A user of PCS', 'atalantapw');
INSERT INTO PetOwners(email) VALUES ('atalanta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('atalanta@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('atalanta@gmail.com', 'nero', 'nero needs love!', 'nero is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('atalanta@gmail.com', 'little-one', 'little-one needs love!', 'little-one is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('atalanta@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('atalanta@gmail.com', 'minnie', 'minnie needs love!', 'minnie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('atalanta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'atalanta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'atalanta@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('atalanta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('enrika', 'enrika@gmail.com', 'A user of PCS', 'enrikapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrika@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'enrika@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'enrika@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'enrika@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrika@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrika@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('christina', 'christina@gmail.com', 'A user of PCS', 'christinapw');
INSERT INTO PetOwners(email) VALUES ('christina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christina@gmail.com', 'mittens', 'mittens needs love!', 'mittens is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('eunice', 'eunice@gmail.com', 'A user of PCS', 'eunicepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eunice@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'eunice@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'eunice@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'eunice@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('wallie', 'wallie@gmail.com', 'A user of PCS', 'walliepw');
INSERT INTO PetOwners(email) VALUES ('wallie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallie@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wallie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'wallie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'wallie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'wallie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallie@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ofilia', 'ofilia@gmail.com', 'A user of PCS', 'ofiliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ofilia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'ofilia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'ofilia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'ofilia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'ofilia@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ofilia@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ofilia@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('fletch', 'fletch@gmail.com', 'A user of PCS', 'fletchpw');
INSERT INTO PetOwners(email) VALUES ('fletch@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fletch@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('calley', 'calley@gmail.com', 'A user of PCS', 'calleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('calley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'calley@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'calley@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'calley@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'calley@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('calley@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('chuck', 'chuck@gmail.com', 'A user of PCS', 'chuckpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chuck@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'chuck@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'chuck@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'chuck@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'chuck@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'chuck@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chuck@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('vivien', 'vivien@gmail.com', 'A user of PCS', 'vivienpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vivien@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'vivien@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'vivien@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'vivien@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'vivien@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'vivien@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vivien@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vivien@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('angelita', 'angelita@gmail.com', 'A user of PCS', 'angelitapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('angelita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'angelita@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'angelita@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'angelita@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('angelita@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('angelita@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('denise', 'denise@gmail.com', 'A user of PCS', 'denisepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denise@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'denise@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'denise@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'denise@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'denise@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'denise@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denise@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('remy', 'remy@gmail.com', 'A user of PCS', 'remypw');
INSERT INTO PetOwners(email) VALUES ('remy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('remy@gmail.com', 'angus', 'angus needs love!', 'angus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('remy@gmail.com', 'hammer', 'hammer needs love!', 'hammer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('remy@gmail.com', 'salem', 'salem needs love!', 'salem is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('remy@gmail.com', 'newton', 'newton needs love!', 'newton is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('remy@gmail.com', 'indy', 'indy needs love!', 'indy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('remy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'remy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'remy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('remy@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('remy@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('teri', 'teri@gmail.com', 'A user of PCS', 'teripw');
INSERT INTO PetOwners(email) VALUES ('teri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teri@gmail.com', 'bailey', 'bailey needs love!', 'bailey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teri@gmail.com', 'roxanne', 'roxanne needs love!', 'roxanne is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('adolpho', 'adolpho@gmail.com', 'A user of PCS', 'adolphopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolpho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'adolpho@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'adolpho@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'adolpho@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cassi', 'cassi@gmail.com', 'A user of PCS', 'cassipw');
INSERT INTO PetOwners(email) VALUES ('cassi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'aires', 'aires needs love!', 'aires is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'mandi', 'mandi needs love!', 'mandi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'rhett', 'rhett needs love!', 'rhett is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cassi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cassi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cassi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cassi@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('bertina', 'bertina@gmail.com', 'A user of PCS', 'bertinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bertina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'bertina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bertina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bertina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'bertina@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('patten', 'patten@gmail.com', 'A user of PCS', 'pattenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patten@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'patten@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'patten@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patten@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patten@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('cesya', 'cesya@gmail.com', 'A user of PCS', 'cesyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cesya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cesya@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cesya@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cesya@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('antin', 'antin@gmail.com', 'A user of PCS', 'antinpw');
INSERT INTO PetOwners(email) VALUES ('antin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antin@gmail.com', 'apollo', 'apollo needs love!', 'apollo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antin@gmail.com', 'echo', 'echo needs love!', 'echo is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'antin@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antin@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dannie', 'dannie@gmail.com', 'A user of PCS', 'danniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dannie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'dannie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dannie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'dannie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'dannie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dannie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dannie@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('biron', 'biron@gmail.com', 'A user of PCS', 'bironpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('biron@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'biron@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('biron@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('biron@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('darwin', 'darwin@gmail.com', 'A user of PCS', 'darwinpw');
INSERT INTO PetOwners(email) VALUES ('darwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'dickens', 'dickens needs love!', 'dickens is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'mindy', 'mindy needs love!', 'mindy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'fred', 'fred needs love!', 'fred is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'bozley', 'bozley needs love!', 'bozley is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darwin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'darwin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'darwin@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darwin@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('pip', 'pip@gmail.com', 'A user of PCS', 'pippw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pip@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'pip@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pip@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'pip@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'pip@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'pip@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('christiane', 'christiane@gmail.com', 'A user of PCS', 'christianepw');
INSERT INTO PetOwners(email) VALUES ('christiane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'shelby', 'shelby needs love!', 'shelby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'old glory', 'old glory needs love!', 'old glory is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'lizzy', 'lizzy needs love!', 'lizzy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'mo', 'mo needs love!', 'mo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christiane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'christiane@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christiane@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christiane@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('fabiano', 'fabiano@gmail.com', 'A user of PCS', 'fabianopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fabiano@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'fabiano@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'fabiano@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fabiano@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fabiano@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fabiano@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('rockie', 'rockie@gmail.com', 'A user of PCS', 'rockiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rockie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rockie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rockie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rockie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rockie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('aundrea', 'aundrea@gmail.com', 'A user of PCS', 'aundreapw');
INSERT INTO PetOwners(email) VALUES ('aundrea@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aundrea@gmail.com', 'dharma', 'dharma needs love!', 'dharma is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aundrea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'aundrea@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'aundrea@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'aundrea@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'aundrea@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'aundrea@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aundrea@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aundrea@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('charlotte', 'charlotte@gmail.com', 'A user of PCS', 'charlottepw');
INSERT INTO PetOwners(email) VALUES ('charlotte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'joy', 'joy needs love!', 'joy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'levi', 'levi needs love!', 'levi is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'billie', 'billie needs love!', 'billie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'boss', 'boss needs love!', 'boss is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'ebony', 'ebony needs love!', 'ebony is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('hillary', 'hillary@gmail.com', 'A user of PCS', 'hillarypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hillary@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hillary@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hillary@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hillary@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hillary@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hurley', 'hurley@gmail.com', 'A user of PCS', 'hurleypw');
INSERT INTO PetOwners(email) VALUES ('hurley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'sam', 'sam needs love!', 'sam is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('ulrich', 'ulrich@gmail.com', 'A user of PCS', 'ulrichpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulrich@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'ulrich@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'ulrich@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (256, 'ulrich@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ulrich@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'ulrich@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulrich@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulrich@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('gwenette', 'gwenette@gmail.com', 'A user of PCS', 'gwenettepw');
INSERT INTO PetOwners(email) VALUES ('gwenette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwenette@gmail.com', 'koty', 'koty needs love!', 'koty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwenette@gmail.com', 'amber', 'amber needs love!', 'amber is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwenette@gmail.com', 'guy', 'guy needs love!', 'guy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwenette@gmail.com', 'old glory', 'old glory needs love!', 'old glory is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('gordon', 'gordon@gmail.com', 'A user of PCS', 'gordonpw');
INSERT INTO PetOwners(email) VALUES ('gordon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'niko', 'niko needs love!', 'niko is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gordon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gordon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gordon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gordon@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ede', 'ede@gmail.com', 'A user of PCS', 'edepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ede@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ede@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ede@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('burgess', 'burgess@gmail.com', 'A user of PCS', 'burgesspw');
INSERT INTO PetOwners(email) VALUES ('burgess@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burgess@gmail.com', 'blue', 'blue needs love!', 'blue is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('sybila', 'sybila@gmail.com', 'A user of PCS', 'sybilapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sybila@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sybila@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sybila@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sybila@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sybila@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sybila@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('antonella', 'antonella@gmail.com', 'A user of PCS', 'antonellapw');
INSERT INTO PetOwners(email) VALUES ('antonella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'gigi', 'gigi needs love!', 'gigi is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'brando', 'brando needs love!', 'brando is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'domino', 'domino needs love!', 'domino is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antonella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'antonella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'antonella@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'antonella@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('antonella@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('antonella@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('porty', 'porty@gmail.com', 'A user of PCS', 'portypw');
INSERT INTO PetOwners(email) VALUES ('porty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'miles', 'miles needs love!', 'miles is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'onie', 'onie needs love!', 'onie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'harry', 'harry needs love!', 'harry is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('roosevelt', 'roosevelt@gmail.com', 'A user of PCS', 'rooseveltpw');
INSERT INTO PetOwners(email) VALUES ('roosevelt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'mac', 'mac needs love!', 'mac is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'cocoa', 'cocoa needs love!', 'cocoa is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'kurly', 'kurly needs love!', 'kurly is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'andy', 'andy needs love!', 'andy is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roosevelt@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'roosevelt@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roosevelt@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roosevelt@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('krishnah', 'krishnah@gmail.com', 'A user of PCS', 'krishnahpw');
INSERT INTO PetOwners(email) VALUES ('krishnah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'mia', 'mia needs love!', 'mia is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('carlee', 'carlee@gmail.com', 'A user of PCS', 'carleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'carlee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'carlee@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (260, 'carlee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'carlee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'carlee@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlee@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlee@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('barrett', 'barrett@gmail.com', 'A user of PCS', 'barrettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('barrett@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'barrett@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'barrett@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'barrett@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barrett@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('laurice', 'laurice@gmail.com', 'A user of PCS', 'lauricepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laurice@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (232, 'laurice@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'laurice@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laurice@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laurice@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('marian', 'marian@gmail.com', 'A user of PCS', 'marianpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marian@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marian@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'marian@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'marian@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marian@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('clair', 'clair@gmail.com', 'A user of PCS', 'clairpw');
INSERT INTO PetOwners(email) VALUES ('clair@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'silver', 'silver needs love!', 'silver is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'klaus', 'klaus needs love!', 'klaus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'pockets', 'pockets needs love!', 'pockets is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'nike', 'nike needs love!', 'nike is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('augustina', 'augustina@gmail.com', 'A user of PCS', 'augustinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('augustina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'augustina@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('charleen', 'charleen@gmail.com', 'A user of PCS', 'charleenpw');
INSERT INTO PetOwners(email) VALUES ('charleen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'kobe', 'kobe needs love!', 'kobe is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charleen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'charleen@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charleen@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charleen@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('maryl', 'maryl@gmail.com', 'A user of PCS', 'marylpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maryl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'maryl@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'maryl@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'maryl@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'maryl@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('delaney', 'delaney@gmail.com', 'A user of PCS', 'delaneypw');
INSERT INTO PetOwners(email) VALUES ('delaney@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('delaney@gmail.com', 'biggie', 'biggie needs love!', 'biggie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('delaney@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('delaney@gmail.com', 'bully', 'bully needs love!', 'bully is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('vyky', 'vyky@gmail.com', 'A user of PCS', 'vykypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vyky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'vyky@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'vyky@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'vyky@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'vyky@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'vyky@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vyky@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vyky@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosana', 'rosana@gmail.com', 'A user of PCS', 'rosanapw');
INSERT INTO PetOwners(email) VALUES ('rosana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosana@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosana@gmail.com', 'olive', 'olive needs love!', 'olive is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosana@gmail.com', 'dee', 'dee needs love!', 'dee is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'rosana@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosana@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosana@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('julietta', 'julietta@gmail.com', 'A user of PCS', 'juliettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('julietta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'julietta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'julietta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'julietta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'julietta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'julietta@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('julietta@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('julietta@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('jenelle', 'jenelle@gmail.com', 'A user of PCS', 'jenellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'jenelle@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'jenelle@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('geordie', 'geordie@gmail.com', 'A user of PCS', 'geordiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geordie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'geordie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geordie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('reid', 'reid@gmail.com', 'A user of PCS', 'reidpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'reid@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jaquenetta', 'jaquenetta@gmail.com', 'A user of PCS', 'jaquenettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaquenetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'jaquenetta@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jaquenetta@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jaquenetta@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('janean', 'janean@gmail.com', 'A user of PCS', 'janeanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janean@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'janean@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'janean@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'janean@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'janean@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'janean@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janean@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janean@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosamond', 'rosamond@gmail.com', 'A user of PCS', 'rosamondpw');
INSERT INTO PetOwners(email) VALUES ('rosamond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'paris', 'paris needs love!', 'paris is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'coal', 'coal needs love!', 'coal is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'cujo', 'cujo needs love!', 'cujo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'chi chi', 'chi chi needs love!', 'chi chi is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('catarina', 'catarina@gmail.com', 'A user of PCS', 'catarinapw');
INSERT INTO PetOwners(email) VALUES ('catarina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('constantia', 'constantia@gmail.com', 'A user of PCS', 'constantiapw');
INSERT INTO PetOwners(email) VALUES ('constantia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'erin', 'erin needs love!', 'erin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'maggie', 'maggie needs love!', 'maggie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('loy', 'loy@gmail.com', 'A user of PCS', 'loypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('loy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'loy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'loy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'loy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'loy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('fallon', 'fallon@gmail.com', 'A user of PCS', 'fallonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fallon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fallon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fallon@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ferrel', 'ferrel@gmail.com', 'A user of PCS', 'ferrelpw');
INSERT INTO PetOwners(email) VALUES ('ferrel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'boone', 'boone needs love!', 'boone is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'athena', 'athena needs love!', 'athena is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'fiona', 'fiona needs love!', 'fiona is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferrel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ferrel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ferrel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ferrel@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('berte', 'berte@gmail.com', 'A user of PCS', 'bertepw');
INSERT INTO PetOwners(email) VALUES ('berte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'harpo', 'harpo needs love!', 'harpo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'bodie', 'bodie needs love!', 'bodie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('berte@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'berte@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'berte@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'berte@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'berte@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berte@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('megen', 'megen@gmail.com', 'A user of PCS', 'megenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('megen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'megen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'megen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'megen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'megen@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('danella', 'danella@gmail.com', 'A user of PCS', 'danellapw');
INSERT INTO PetOwners(email) VALUES ('danella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'brady', 'brady needs love!', 'brady is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'midnight', 'midnight needs love!', 'midnight is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'hobbes', 'hobbes needs love!', 'hobbes is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('danella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'danella@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'danella@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'danella@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'danella@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ellary', 'ellary@gmail.com', 'A user of PCS', 'ellarypw');
INSERT INTO PetOwners(email) VALUES ('ellary@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellary@gmail.com', 'porter', 'porter needs love!', 'porter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellary@gmail.com', 'latte', 'latte needs love!', 'latte is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('ciel', 'ciel@gmail.com', 'A user of PCS', 'cielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ciel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'ciel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'ciel@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'ciel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ciel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'ciel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ciel@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ciel@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('benedicto', 'benedicto@gmail.com', 'A user of PCS', 'benedictopw');
INSERT INTO PetOwners(email) VALUES ('benedicto@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'coco', 'coco needs love!', 'coco is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'kato', 'kato needs love!', 'kato is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'indy', 'indy needs love!', 'indy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'doc', 'doc needs love!', 'doc is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('ginevra', 'ginevra@gmail.com', 'A user of PCS', 'ginevrapw');
INSERT INTO PetOwners(email) VALUES ('ginevra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('erwin', 'erwin@gmail.com', 'A user of PCS', 'erwinpw');
INSERT INTO PetOwners(email) VALUES ('erwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'admiral', 'admiral needs love!', 'admiral is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'misty', 'misty needs love!', 'misty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'little-one', 'little-one needs love!', 'little-one is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('roseanna', 'roseanna@gmail.com', 'A user of PCS', 'roseannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roseanna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'roseanna@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (142, 'roseanna@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'roseanna@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roseanna@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roseanna@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('sherri', 'sherri@gmail.com', 'A user of PCS', 'sherripw');
INSERT INTO PetOwners(email) VALUES ('sherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'checkers', 'checkers needs love!', 'checkers is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'jenny', 'jenny needs love!', 'jenny is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'pierre', 'pierre needs love!', 'pierre is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'mitch', 'mitch needs love!', 'mitch is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sherri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (214, 'sherri@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (211, 'sherri@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'sherri@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherri@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherri@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('bride', 'bride@gmail.com', 'A user of PCS', 'bridepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bride@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bride@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bride@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bride@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bride@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('felike', 'felike@gmail.com', 'A user of PCS', 'felikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felike@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'felike@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'felike@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'felike@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'felike@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felike@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('carlynn', 'carlynn@gmail.com', 'A user of PCS', 'carlynnpw');
INSERT INTO PetOwners(email) VALUES ('carlynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carlynn@gmail.com', 'emily', 'emily needs love!', 'emily is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carlynn@gmail.com', 'jersey', 'jersey needs love!', 'jersey is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'carlynn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'carlynn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'carlynn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carlynn@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('feodora', 'feodora@gmail.com', 'A user of PCS', 'feodorapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('feodora@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'feodora@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'feodora@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'feodora@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'feodora@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'feodora@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('feodora@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('feodora@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('orazio', 'orazio@gmail.com', 'A user of PCS', 'oraziopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('orazio@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'orazio@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'orazio@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'orazio@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'orazio@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'orazio@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('orazio@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('orazio@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('sharai', 'sharai@gmail.com', 'A user of PCS', 'sharaipw');
INSERT INTO PetOwners(email) VALUES ('sharai@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharai@gmail.com', 'boris', 'boris needs love!', 'boris is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharai@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('sabrina', 'sabrina@gmail.com', 'A user of PCS', 'sabrinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sabrina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'sabrina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'sabrina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'sabrina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'sabrina@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sabrina@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sabrina@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('adel', 'adel@gmail.com', 'A user of PCS', 'adelpw');
INSERT INTO PetOwners(email) VALUES ('adel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'mason', 'mason needs love!', 'mason is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('nicoline', 'nicoline@gmail.com', 'A user of PCS', 'nicolinepw');
INSERT INTO PetOwners(email) VALUES ('nicoline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicoline@gmail.com', 'newton', 'newton needs love!', 'newton is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('chance', 'chance@gmail.com', 'A user of PCS', 'chancepw');
INSERT INTO PetOwners(email) VALUES ('chance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'noel', 'noel needs love!', 'noel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('jeremy', 'jeremy@gmail.com', 'A user of PCS', 'jeremypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeremy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jeremy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jeremy@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeremy@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcellus', 'marcellus@gmail.com', 'A user of PCS', 'marcelluspw');
INSERT INTO PetOwners(email) VALUES ('marcellus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'nobel', 'nobel needs love!', 'nobel is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'pockets', 'pockets needs love!', 'pockets is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'patch', 'patch needs love!', 'patch is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcellus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marcellus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marcellus@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marcellus@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcellus@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('hesther', 'hesther@gmail.com', 'A user of PCS', 'hestherpw');
INSERT INTO PetOwners(email) VALUES ('hesther@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hesther@gmail.com', 'beamer', 'beamer needs love!', 'beamer is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hesther@gmail.com', 'ferris', 'ferris needs love!', 'ferris is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hesther@gmail.com', 'duffy', 'duffy needs love!', 'duffy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('helli', 'helli@gmail.com', 'A user of PCS', 'hellipw');
INSERT INTO PetOwners(email) VALUES ('helli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'chance', 'chance needs love!', 'chance is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('dukey', 'dukey@gmail.com', 'A user of PCS', 'dukeypw');
INSERT INTO PetOwners(email) VALUES ('dukey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'hank', 'hank needs love!', 'hank is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'bucko', 'bucko needs love!', 'bucko is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('odelle', 'odelle@gmail.com', 'A user of PCS', 'odellepw');
INSERT INTO PetOwners(email) VALUES ('odelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelle@gmail.com', 'dinky', 'dinky needs love!', 'dinky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelle@gmail.com', 'panda', 'panda needs love!', 'panda is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelle@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelle@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('pepito', 'pepito@gmail.com', 'A user of PCS', 'pepitopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pepito@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'pepito@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'pepito@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'pepito@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'pepito@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'pepito@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepito@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kanya', 'kanya@gmail.com', 'A user of PCS', 'kanyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kanya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kanya@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('marwin', 'marwin@gmail.com', 'A user of PCS', 'marwinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marwin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marwin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marwin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'marwin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marwin@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kerrie', 'kerrie@gmail.com', 'A user of PCS', 'kerriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kerrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kerrie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kerrie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kerrie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kerrie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kerrie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kerrie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('xerxes', 'xerxes@gmail.com', 'A user of PCS', 'xerxespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xerxes@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'xerxes@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'xerxes@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xerxes@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xerxes@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('elspeth', 'elspeth@gmail.com', 'A user of PCS', 'elspethpw');
INSERT INTO PetOwners(email) VALUES ('elspeth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elspeth@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('nickey', 'nickey@gmail.com', 'A user of PCS', 'nickeypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nickey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nickey@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('elwira', 'elwira@gmail.com', 'A user of PCS', 'elwirapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elwira@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'elwira@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'elwira@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'elwira@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'elwira@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwira@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwira@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('hannah', 'hannah@gmail.com', 'A user of PCS', 'hannahpw');
INSERT INTO PetOwners(email) VALUES ('hannah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hannah@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('gillan', 'gillan@gmail.com', 'A user of PCS', 'gillanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gillan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gillan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gillan@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gillan@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('dominique', 'dominique@gmail.com', 'A user of PCS', 'dominiquepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dominique@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'dominique@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'dominique@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'dominique@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dominique@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dominique@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('alexander', 'alexander@gmail.com', 'A user of PCS', 'alexanderpw');
INSERT INTO PetOwners(email) VALUES ('alexander@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alexander@gmail.com', 'flake', 'flake needs love!', 'flake is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('cristen', 'cristen@gmail.com', 'A user of PCS', 'cristenpw');
INSERT INTO PetOwners(email) VALUES ('cristen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristen@gmail.com', 'paddington', 'paddington needs love!', 'paddington is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristen@gmail.com', 'crystal', 'crystal needs love!', 'crystal is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristen@gmail.com', 'leo', 'leo needs love!', 'leo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristen@gmail.com', 'iris', 'iris needs love!', 'iris is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('alaster', 'alaster@gmail.com', 'A user of PCS', 'alasterpw');
INSERT INTO PetOwners(email) VALUES ('alaster@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'bb', 'bb needs love!', 'bb is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'pokey', 'pokey needs love!', 'pokey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alaster@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'alaster@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alaster@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('maynord', 'maynord@gmail.com', 'A user of PCS', 'maynordpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maynord@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'maynord@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'maynord@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (185, 'maynord@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'maynord@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'maynord@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maynord@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maynord@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('caty', 'caty@gmail.com', 'A user of PCS', 'catypw');
INSERT INTO PetOwners(email) VALUES ('caty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'mona', 'mona needs love!', 'mona is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'onie', 'onie needs love!', 'onie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'logan', 'logan needs love!', 'logan is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'pepe', 'pepe needs love!', 'pepe is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'caty@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caty@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caty@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('valentine', 'valentine@gmail.com', 'A user of PCS', 'valentinepw');
INSERT INTO PetOwners(email) VALUES ('valentine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'rebel', 'rebel needs love!', 'rebel is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'dee', 'dee needs love!', 'dee is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('valentine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'valentine@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'valentine@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('orsola', 'orsola@gmail.com', 'A user of PCS', 'orsolapw');
INSERT INTO PetOwners(email) VALUES ('orsola@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'diva', 'diva needs love!', 'diva is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'bosco', 'bosco needs love!', 'bosco is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'abbey', 'abbey needs love!', 'abbey is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('marcelo', 'marcelo@gmail.com', 'A user of PCS', 'marcelopw');
INSERT INTO PetOwners(email) VALUES ('marcelo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelo@gmail.com', 'commando', 'commando needs love!', 'commando is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelo@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelo@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcelo@gmail.com', 'panther', 'panther needs love!', 'panther is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('oberon', 'oberon@gmail.com', 'A user of PCS', 'oberonpw');
INSERT INTO PetOwners(email) VALUES ('oberon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'frisco', 'frisco needs love!', 'frisco is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'benji', 'benji needs love!', 'benji is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('catrina', 'catrina@gmail.com', 'A user of PCS', 'catrinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('catrina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'catrina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'catrina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'catrina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'catrina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'catrina@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('catrina@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('catrina@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('therine', 'therine@gmail.com', 'A user of PCS', 'therinepw');
INSERT INTO PetOwners(email) VALUES ('therine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('therine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'therine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'therine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'therine@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('therine@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('therine@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('kameko', 'kameko@gmail.com', 'A user of PCS', 'kamekopw');
INSERT INTO PetOwners(email) VALUES ('kameko@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kameko@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kameko@gmail.com', 'cutie', 'cutie needs love!', 'cutie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kameko@gmail.com', 'ozzie', 'ozzie needs love!', 'ozzie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kameko@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kameko@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kameko@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kameko@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('antone', 'antone@gmail.com', 'A user of PCS', 'antonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antone@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'antone@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'antone@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'antone@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'antone@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('arabelle', 'arabelle@gmail.com', 'A user of PCS', 'arabellepw');
INSERT INTO PetOwners(email) VALUES ('arabelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'abbie', 'abbie needs love!', 'abbie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arabelle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'arabelle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'arabelle@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'arabelle@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arabelle@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('eydie', 'eydie@gmail.com', 'A user of PCS', 'eydiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eydie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (232, 'eydie@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eydie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eydie@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorie', 'dorie@gmail.com', 'A user of PCS', 'doriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dorie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'dorie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (222, 'dorie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'dorie@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('estel', 'estel@gmail.com', 'A user of PCS', 'estelpw');
INSERT INTO PetOwners(email) VALUES ('estel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'dolly', 'dolly needs love!', 'dolly is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'estel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'estel@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estel@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estel@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('hobie', 'hobie@gmail.com', 'A user of PCS', 'hobiepw');
INSERT INTO PetOwners(email) VALUES ('hobie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'bug', 'bug needs love!', 'bug is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'rowdy', 'rowdy needs love!', 'rowdy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'coco', 'coco needs love!', 'coco is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('rriocard', 'rriocard@gmail.com', 'A user of PCS', 'rriocardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rriocard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rriocard@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rriocard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rriocard@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rriocard@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rriocard@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('elliot', 'elliot@gmail.com', 'A user of PCS', 'elliotpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elliot@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'elliot@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'elliot@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'elliot@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elliot@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elliot@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('shandie', 'shandie@gmail.com', 'A user of PCS', 'shandiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shandie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shandie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('vernen', 'vernen@gmail.com', 'A user of PCS', 'vernenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vernen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'vernen@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'vernen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'vernen@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('burr', 'burr@gmail.com', 'A user of PCS', 'burrpw');
INSERT INTO PetOwners(email) VALUES ('burr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'boss', 'boss needs love!', 'boss is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'chiquita', 'chiquita needs love!', 'chiquita is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'niki', 'niki needs love!', 'niki is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burr@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'burr@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'burr@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burr@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('bealle', 'bealle@gmail.com', 'A user of PCS', 'beallepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bealle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bealle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bealle@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bealle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bealle@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('devlen', 'devlen@gmail.com', 'A user of PCS', 'devlenpw');
INSERT INTO PetOwners(email) VALUES ('devlen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'puck', 'puck needs love!', 'puck is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'murphy', 'murphy needs love!', 'murphy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'jester', 'jester needs love!', 'jester is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('devlen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'devlen@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('devlen@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('tibold', 'tibold@gmail.com', 'A user of PCS', 'tiboldpw');
INSERT INTO PetOwners(email) VALUES ('tibold@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'apollo', 'apollo needs love!', 'apollo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'jessie', 'jessie needs love!', 'jessie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('leland', 'leland@gmail.com', 'A user of PCS', 'lelandpw');
INSERT INTO PetOwners(email) VALUES ('leland@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leland@gmail.com', 'sky', 'sky needs love!', 'sky is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('hilario', 'hilario@gmail.com', 'A user of PCS', 'hilariopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hilario@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hilario@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hilario@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hilario@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hilario@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('nerita', 'nerita@gmail.com', 'A user of PCS', 'neritapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nerita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'nerita@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'nerita@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'nerita@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'nerita@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerita@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerita@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('jefferey', 'jefferey@gmail.com', 'A user of PCS', 'jeffereypw');
INSERT INTO PetOwners(email) VALUES ('jefferey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'duncan', 'duncan needs love!', 'duncan is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'kayla', 'kayla needs love!', 'kayla is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'codi', 'codi needs love!', 'codi is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('ruthann', 'ruthann@gmail.com', 'A user of PCS', 'ruthannpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ruthann@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'ruthann@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'ruthann@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'ruthann@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (234, 'ruthann@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ruthann@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ruthann@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('tonye', 'tonye@gmail.com', 'A user of PCS', 'tonyepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tonye@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'tonye@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'tonye@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (181, 'tonye@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'tonye@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'tonye@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tonye@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tonye@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('cristabel', 'cristabel@gmail.com', 'A user of PCS', 'cristabelpw');
INSERT INTO PetOwners(email) VALUES ('cristabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristabel@gmail.com', 'hamlet', 'hamlet needs love!', 'hamlet is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristabel@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristabel@gmail.com', 'flint', 'flint needs love!', 'flint is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristabel@gmail.com', 'schotzie', 'schotzie needs love!', 'schotzie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristabel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'cristabel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'cristabel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'cristabel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'cristabel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'cristabel@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristabel@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristabel@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('corrina', 'corrina@gmail.com', 'A user of PCS', 'corrinapw');
INSERT INTO PetOwners(email) VALUES ('corrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'eddie', 'eddie needs love!', 'eddie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'abby', 'abby needs love!', 'abby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'flower', 'flower needs love!', 'flower is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('corrina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'corrina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'corrina@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('corrina@gmail.com', '2022-07-03');

INSERT INTO BidsFor VALUES ('millard@gmail.com', 'beau@gmail.com', 'mocha', '2020-01-01 00:00:00', '2022-07-13', '2022-07-15', 50, 65, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('aundrea@gmail.com', 'lonnie@gmail.com', 'dharma', '2020-01-01 00:00:01', '2022-06-26', '2022-06-28', 38, 47, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('clareta@gmail.com', 'clemente@gmail.com', 'levi', '2020-01-01 00:00:02', '2022-06-22', '2022-06-23', 71, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('garek@gmail.com', 'ragnar@gmail.com', 'skipper', '2020-01-01 00:00:03', '2022-10-21', '2022-10-27', 90, 90, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ramon@gmail.com', 'marcia@gmail.com', 'gypsy', '2020-01-01 00:00:04', '2021-07-08', '2021-07-13', 100, 117, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marcia@gmail.com', 'phebe@gmail.com', 'june', '2020-01-01 00:00:05', '2022-01-26', '2022-01-28', 42, 42, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('minor@gmail.com', 'janean@gmail.com', 'louis', '2020-01-01 00:00:06', '2022-02-16', '2022-02-20', 53, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('demetra@gmail.com', 'marwin@gmail.com', 'niki', '2020-01-01 00:00:07', '2021-06-07', '2021-06-09', 130, 139, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('miof mela@gmail.com', 'kayley@gmail.com', 'jethro', '2020-01-01 00:00:08', '2022-08-12', '2022-08-18', 145, 161, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('claudette@gmail.com', 'joshua@gmail.com', 'bobo', '2020-01-01 00:00:09', '2021-09-23', '2021-09-28', 69, 96, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('farlie@gmail.com', 'margery@gmail.com', 'caesar', '2020-01-01 00:00:10', '2022-02-28', '2022-03-01', 131, 144, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('madelina@gmail.com', 'red@gmail.com', 'heidi', '2020-01-01 00:00:11', '2022-08-07', '2022-08-12', 100, 105, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sharona@gmail.com', 'fanni@gmail.com', 'fluffy', '2020-01-01 00:00:12', '2022-08-25', '2022-08-30', 65, 87, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('trudie@gmail.com', 'augustina@gmail.com', 'holly', '2020-01-01 00:00:13', '2022-06-05', '2022-06-08', 80, 81, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('garik@gmail.com', 'brunhilda@gmail.com', 'flash', '2020-01-01 00:00:14', '2022-01-14', '2022-01-15', 50, 52, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('bettye@gmail.com', 'remy@gmail.com', 'maddie', '2020-01-01 00:00:15', '2021-05-11', '2021-05-15', 82, 104, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenilee@gmail.com', 'trudey@gmail.com', 'annie', '2020-01-01 00:00:16', '2022-06-08', '2022-06-13', 51, 61, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ange@gmail.com', 'reilly@gmail.com', 'mojo', '2020-01-01 00:00:17', '2021-05-11', '2021-05-14', 113, 127, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('zenia@gmail.com', 'jaine@gmail.com', 'bobbie', '2020-01-01 00:00:18', '2021-11-20', '2021-11-22', 80, 95, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ava@gmail.com', 'blisse@gmail.com', 'frosty', '2020-01-01 00:00:19', '2022-11-03', '2022-11-05', 98, 100, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mirabel@gmail.com', 'constance@gmail.com', 'fifi', '2020-01-01 00:00:20', '2021-09-21', '2021-09-21', 140, 160, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('humfrid@gmail.com', 'lezlie@gmail.com', 'kenya', '2020-01-01 00:00:21', '2021-10-31', '2021-11-02', 120, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('donnamarie@gmail.com', 'jeni@gmail.com', 'aries', '2020-01-01 00:00:22', '2022-12-18', '2022-12-20', 70, 86, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ava@gmail.com', 'hewett@gmail.com', 'boomer', '2020-01-01 00:00:23', '2022-06-20', '2022-06-24', 80, 110, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alyosha@gmail.com', 'basilio@gmail.com', 'cole', '2020-01-01 00:00:24', '2022-05-28', '2022-06-02', 45, 63, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('michele@gmail.com', 'corrina@gmail.com', 'friday', '2020-01-01 00:00:25', '2022-10-03', '2022-10-09', 130, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('clare@gmail.com', 'wainwright@gmail.com', 'banjo', '2020-01-01 00:00:26', '2021-08-29', '2021-08-29', 110, 122, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alaster@gmail.com', 'gussy@gmail.com', 'gabriella', '2020-01-01 00:00:27', '2022-02-02', '2022-02-04', 80, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('godfrey@gmail.com', 'tiphany@gmail.com', 'nicky', '2020-01-01 00:00:28', '2021-11-21', '2021-11-23', 80, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('peggy@gmail.com', 'jeni@gmail.com', 'old glory', '2020-01-01 00:00:29', '2021-06-05', '2021-06-05', 50, 78, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('benedicto@gmail.com', 'lauree@gmail.com', 'coco', '2020-01-01 00:00:30', '2021-08-24', '2021-08-28', 90, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('darrelle@gmail.com', 'sibilla@gmail.com', 'ruthie', '2020-01-01 00:00:31', '2021-03-14', '2021-03-14', 50, 61, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('kylila@gmail.com', 'dannie@gmail.com', 'sassy', '2020-01-01 00:00:32', '2021-10-04', '2021-10-06', 71, 92, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('constantia@gmail.com', 'dinny@gmail.com', 'erin', '2020-01-01 00:00:33', '2022-07-06', '2022-07-10', 90, 102, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mitchael@gmail.com', 'pip@gmail.com', 'daffy', '2020-01-01 00:00:34', '2022-07-16', '2022-07-18', 60, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wilhelmine@gmail.com', 'gallagher@gmail.com', 'roxy', '2020-01-01 00:00:35', '2021-08-25', '2021-08-31', 87, 117, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('web@gmail.com', 'marcellus@gmail.com', 'girl', '2020-01-01 00:00:36', '2022-12-20', '2022-12-25', 100, 119, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('carlynn@gmail.com', 'reilly@gmail.com', 'jersey', '2020-01-01 00:00:37', '2022-05-03', '2022-05-08', 59, 66, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('christiane@gmail.com', 'krysta@gmail.com', 'shelby', '2020-01-01 00:00:38', '2022-02-12', '2022-02-16', 120, 134, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('roosevelt@gmail.com', 'sibilla@gmail.com', 'kosmo', '2020-01-01 00:00:39', '2022-05-25', '2022-05-25', 140, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('olag@gmail.com', 'camilla@gmail.com', 'blondie', '2020-01-01 00:00:40', '2021-10-23', '2021-10-28', 120, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('joshua@gmail.com', 'milton@gmail.com', 'riggs', '2020-01-01 00:00:41', '2022-11-04', '2022-11-10', 64, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('abrahan@gmail.com', 'cosette@gmail.com', 'chippy', '2020-01-01 00:00:42', '2021-11-25', '2021-11-28', 130, 134, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('raddie@gmail.com', 'irwinn@gmail.com', 'cassie', '2020-01-01 00:00:43', '2021-10-30', '2021-11-02', 120, 140, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mariann@gmail.com', 'lock@gmail.com', 'cobweb', '2020-01-01 00:00:44', '2022-02-13', '2022-02-19', 38, 43, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cosette@gmail.com', 'carmina@gmail.com', 'bridgett', '2020-01-01 00:00:45', '2022-05-31', '2022-06-05', 110, 116, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('kalila@gmail.com', 'modesty@gmail.com', 'jack', '2020-01-01 00:00:46', '2022-01-19', '2022-01-21', 272, 301, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('herc@gmail.com', 'wittie@gmail.com', 'porkchop', '2020-01-01 00:00:47', '2022-12-01', '2022-12-03', 61, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marcelo@gmail.com', 'inglis@gmail.com', 'panther', '2020-01-01 00:00:48', '2022-04-29', '2022-04-30', 130, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('trstram@gmail.com', 'steve@gmail.com', 'sara', '2020-01-01 00:00:49', '2021-11-08', '2021-11-13', 60, 75, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mahmud@gmail.com', 'francklyn@gmail.com', 'archie', '2020-01-01 00:00:50', '2022-06-24', '2022-06-24', 43, 53, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('claudette@gmail.com', 'shem@gmail.com', 'little-rascal', '2020-01-01 00:00:51', '2022-04-05', '2022-04-07', 70, 90, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charleen@gmail.com', 'brianna@gmail.com', 'kobe', '2020-01-01 00:00:52', '2022-12-01', '2022-12-02', 116, 120, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lezlie@gmail.com', 'megen@gmail.com', 'madison', '2020-01-01 00:00:53', '2022-09-04', '2022-09-05', 140, 145, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dinny@gmail.com', 'frayda@gmail.com', 'charmer', '2020-01-01 00:00:54', '2021-05-17', '2021-05-18', 110, 136, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brana@gmail.com', 'demott@gmail.com', 'jake', '2020-01-01 00:00:55', '2022-04-26', '2022-04-27', 189, 206, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sibby@gmail.com', 'curcio@gmail.com', 'foxy', '2020-01-01 00:00:56', '2021-09-15', '2021-09-19', 108, 122, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charleen@gmail.com', 'ronny@gmail.com', 'kobe', '2020-01-01 00:00:57', '2022-06-22', '2022-06-24', 44, 62, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jermaine@gmail.com', 'miltie@gmail.com', 'mary jane', '2020-01-01 00:00:58', '2021-10-13', '2021-10-13', 70, 99, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('helli@gmail.com', 'laverne@gmail.com', 'chance', '2020-01-01 00:00:59', '2022-11-25', '2022-11-29', 241, 248, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ozzy@gmail.com', 'jazmin@gmail.com', 'pink panther', '2020-01-01 00:01:00', '2022-05-10', '2022-05-10', 70, 88, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('miltie@gmail.com', 'fanni@gmail.com', 'dunn', '2020-01-01 00:01:01', '2021-11-08', '2021-11-10', 65, 86, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('garold@gmail.com', 'claribel@gmail.com', 'barnaby', '2020-01-01 00:01:02', '2021-06-21', '2021-06-23', 110, 118, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('margarette@gmail.com', 'paulina@gmail.com', 'jess', '2020-01-01 00:01:03', '2022-02-19', '2022-02-21', 100, 104, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jeromy@gmail.com', 'modesty@gmail.com', 'ellie', '2020-01-01 00:01:04', '2021-07-31', '2021-08-04', 272, 285, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('bud@gmail.com', 'donnamarie@gmail.com', 'cooper', '2020-01-01 00:01:05', '2021-06-16', '2021-06-17', 247, 274, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('devlen@gmail.com', 'carleton@gmail.com', 'murphy', '2020-01-01 00:01:06', '2022-03-30', '2022-03-30', 80, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('neville@gmail.com', 'urbain@gmail.com', 'francais', '2020-01-01 00:01:07', '2022-08-16', '2022-08-22', 130, 137, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ellis@gmail.com', 'tresa@gmail.com', 'kid', '2020-01-01 00:01:08', '2021-06-18', '2021-06-24', 156, 162, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mattias@gmail.com', 'jaine@gmail.com', 'axle', '2020-01-01 00:01:09', '2022-02-08', '2022-02-09', 120, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('harv@gmail.com', 'wilton@gmail.com', 'miasy', '2020-01-01 00:01:10', '2022-05-17', '2022-05-19', 70, 94, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sherilyn@gmail.com', 'nari@gmail.com', 'monster', '2020-01-01 00:01:11', '2022-09-23', '2022-09-23', 60, 87, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cecil@gmail.com', 'cristabel@gmail.com', 'aj', '2020-01-01 00:01:12', '2021-10-22', '2021-10-23', 35, 36, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('waverly@gmail.com', 'cristabel@gmail.com', 'hunter', '2020-01-01 00:01:13', '2022-09-01', '2022-09-07', 35, 40, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('derrick@gmail.com', 'marwin@gmail.com', 'ruger', '2020-01-01 00:01:14', '2022-06-06', '2022-06-06', 90, 93, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sharona@gmail.com', 'dannie@gmail.com', 'patsy', '2020-01-01 00:01:15', '2022-12-12', '2022-12-18', 69, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lefty@gmail.com', 'fredia@gmail.com', 'clifford', '2020-01-01 00:01:16', '2022-02-13', '2022-02-17', 132, 136, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('federico@gmail.com', 'sigismund@gmail.com', 'harry', '2020-01-01 00:01:17', '2022-10-24', '2022-10-28', 80, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('anderson@gmail.com', 'sybila@gmail.com', 'romeo', '2020-01-01 00:01:18', '2022-09-21', '2022-09-26', 60, 65, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rik@gmail.com', 'binny@gmail.com', 'persy', '2020-01-01 00:01:19', '2022-02-02', '2022-02-03', 44, 61, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('erv@gmail.com', 'ulises@gmail.com', 'jaguar', '2020-01-01 00:01:20', '2021-01-15', '2021-01-21', 130, 130, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gideon@gmail.com', 'taddeo@gmail.com', 'aries', '2020-01-01 00:01:21', '2022-06-23', '2022-06-24', 50, 71, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ranee@gmail.com', 'alister@gmail.com', 'crackers', '2020-01-01 00:01:22', '2022-11-06', '2022-11-07', 52, 55, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('fidole@gmail.com', 'syman@gmail.com', 'roman', '2020-01-01 00:01:23', '2021-04-04', '2021-04-05', 117, 133, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('andee@gmail.com', 'rockie@gmail.com', 'jimmuy', '2020-01-01 00:01:24', '2021-10-20', '2021-10-20', 50, 50, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lucille@gmail.com', 'niki@gmail.com', 'abel', '2020-01-01 00:01:25', '2022-01-02', '2022-01-04', 120, 130, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marcelo@gmail.com', 'kalindi@gmail.com', 'elvis', '2020-01-01 00:01:26', '2021-06-20', '2021-06-25', 49, 55, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('yoshiko@gmail.com', 'cinnamon@gmail.com', 'aries', '2020-01-01 00:01:27', '2022-08-23', '2022-08-27', 74, 75, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('christiane@gmail.com', 'alyosha@gmail.com', 'mandy', '2020-01-01 00:01:28', '2022-02-16', '2022-02-19', 110, 138, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sheila-kathryn@gmail.com', 'laraine@gmail.com', 'brodie', '2020-01-01 00:01:29', '2022-03-18', '2022-03-19', 62, 63, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('philly@gmail.com', 'elwira@gmail.com', 'aussie', '2020-01-01 00:01:30', '2021-09-24', '2021-09-30', 86, 113, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('eugenio@gmail.com', 'fanni@gmail.com', 'ally', '2020-01-01 00:01:31', '2021-06-05', '2021-06-06', 161, 188, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lev@gmail.com', 'veda@gmail.com', 'biablo', '2020-01-01 00:01:32', '2022-02-24', '2022-02-24', 38, 56, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('filia@gmail.com', 'dannie@gmail.com', 'hobbes', '2020-01-01 00:01:33', '2021-04-02', '2021-04-04', 69, 73, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('web@gmail.com', 'dalila@gmail.com', 'girl', '2020-01-01 00:01:34', '2022-09-21', '2022-09-21', 100, 110, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('drew@gmail.com', 'clareta@gmail.com', 'montgomery', '2020-01-01 00:01:35', '2022-12-04', '2022-12-07', 264, 283, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sancho@gmail.com', 'karolina@gmail.com', 'captain', '2020-01-01 00:01:36', '2021-02-07', '2021-02-07', 159, 181, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('nick@gmail.com', 'hedwiga@gmail.com', 'poncho', '2020-01-01 00:01:37', '2022-10-28', '2022-11-02', 120, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('genevieve@gmail.com', 'franzen@gmail.com', 'furball', '2020-01-01 00:01:38', '2022-05-10', '2022-05-13', 217, 238, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('adolf@gmail.com', 'janina@gmail.com', 'candy', '2020-01-01 00:01:39', '2021-03-16', '2021-03-22', 48, 52, NULL, False, '1', '1', NULL, NULL);
