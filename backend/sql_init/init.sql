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
    rating DECIMAL(10, 2),
    CHECK (0 <= rating AND rating <= 5)
);

CREATE TABLE PartTimeAvail ( -- records the part time availability
    email VARCHAR(30) REFERENCES Caretakers(email) ON DELETE CASCADE,
    work_date DATE,
    PRIMARY KEY (email, work_date)
);

CREATE TABLE FullTimeLeave ( -- records the full time availability
    email VARCHAR(30) REFERENCES Caretakers(email) ON DELETE CASCADE,
    leave_date DATE NOT NULL,
    PRIMARY KEY (email, leave_date)
);

CREATE TABLE PetOwners (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE
);

CREATE TABLE PetTypes ( -- enumerates the types of pets there are, like Dog, Cat, etc
    species VARCHAR(30) PRIMARY KEY NOT NULL,
    base_price DECIMAL(10,2) not null
);

CREATE TABLE Pets (
    email VARCHAR(30) REFERENCES PetOwners(email) ON DELETE CASCADE,
    pet_name VARCHAR(30),
    special_requirements VARCHAR(255),
    description VARCHAR(255),
    species VARCHAR(30) REFERENCES PetTypes(species) ON DELETE CASCADE,
    PRIMARY KEY (pet_name, email)
);

CREATE TABLE PcsAdmins (
    email VARCHAR(30) PRIMARY KEY REFERENCES Users(email) ON DELETE CASCADE
);

CREATE TABLE BidsFor (
    owner_email VARCHAR(30),
    caretaker_email VARCHAR(30) REFERENCES CareTakers(email) ON DELETE CASCADE,
    pet_name VARCHAR(30),
    submission_time TIMESTAMP,
    start_date DATE,
    end_date DATE,
    price DECIMAL(10,2),
    amount_bidded DECIMAL(10,2),
    is_confirmed BOOLEAN DEFAULT NULL,
    is_paid BOOLEAN DEFAULT False,
    payment_type payment_type,
    transfer_type transfer_type,
    rating DECIMAL(10, 1) DEFAULT NULL CHECK (rating ISNULL or (rating >= 0 AND rating <= 5)), 
    review VARCHAR(255) DEFAULT NULL, --can add text for the review
    PRIMARY KEY (caretaker_email, owner_email, pet_name, submission_time)
-- disable checks so easier for testing
--     CONSTRAINT bidsfor_dates_check CHECK (submission_time < start_date AND start_date <= end_date),
--     CONSTRAINT bidsfor_price_le_bid_amount CHECK (price <= amount_bidded),
--     CONSTRAINT bidsfor_confirm_before_paid CHECK (NOT is_paid OR is_confirmed) -- check that is_paid implies confirmed
);

CREATE TABLE TakecarePrice (
    daily_price DECIMAL(10,2),
    email varchar(30) REFERENCES Caretakers(email) ON DELETE cascade, -- references the caretaker
    species varchar(30) REFERENCES PetTypes(species) ON DELETE cascade,
    PRIMARY KEY (email, species)  --- daily price > base price
);
-- for ft caretaker, the daily price is calculated as base_price for that pet + 5 * caretakers rating
-- for pt caretaker, the daily price is whatever they want to set it as
-- triggers (see below) : trigger to update the daily_price when 1) base_price change 2) caretaker rating change

CREATE TABLE Posts (
	post_id SERIAL PRIMARY KEY,
    email VARCHAR(30) REFERENCES Users(email) ON DELETE SET NULL,
    title VARCHAR(255),
    cont TEXT,
    last_modified TIMESTAMP DEFAULT NOW()
);

CREATE TABLE Comments (
	post_id INTEGER REFERENCES Posts(post_id) ON DELETE CASCADE,
    email VARCHAR(30) REFERENCES Users(email) ON DELETE CASCADE,
    date_time TIMESTAMP DEFAULT NOW(),
    cont TEXT,
    PRIMARY KEY (post_id, email, date_time)
);

-- ============================================ HELPER FUNCTIONS =============================================================

-- return true if interval [s1, e1] overlaps with [s2, e2]
CREATE OR REPLACE FUNCTION clash(s1 date, e1 date, d date)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return ((s1, e1 + interval '1 day') overlaps (d, d + interval '1 day'));
END;
$$;

-- return true if interval [s1, e1] overlaps with [s2, e2]
CREATE OR REPLACE FUNCTION clash(s1 date, e1 date, s2 date, e2 date)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return ((s1, e1 + interval '1 day') overlaps (s2, e2 + interval '1 day'));
END;
$$;

-- return true if cemail is fulltimecaretaker, else false
CREATE OR REPLACE FUNCTION isFullTime(cemail varchar)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return (select is_fulltime from Caretakers CT where CT.email = cemail);
END;
$$;

-- return the max number of pets this caretaker can take care of
CREATE OR REPLACE FUNCTION getPetLimit(cemail varchar)
RETURNS int
language plpgsql
as
$$
BEGIN
	IF (NOT EXISTS (select 1 from caretakers where email = cemail)) THEN
		return 0;
	ELSIF (select is_fulltime from caretakers where email = cemail) THEN
		return 5;
	ELSIF (select rating from caretakers where email = cemail) >= 4 THEN
		return 5;
	ELSE
		return 2;
	END IF;
END;
$$;

-- return the workload of this caretaker on the interval
-- workload is a table of pairs (work_date, num_jobs)
drop function if exists getWorkload;
CREATE OR REPLACE FUNCTION getWorkload(cemail varchar, s date, e date)
RETURNS table (work_date date, num_jobs int)
language plpgsql
as
$$
BEGIN
	return query select D.work_date, (
		select COUNT(*)::int from bidsFor
		where
			caretaker_email = cemail and 
			is_confirmed = True and
			clash(start_date, end_date, D.work_date, D.work_date)
	) as num_jobs
	from (select generate_series(s, e, '1 day'::interval)::date as work_date) as D;
END;
$$;

-- return true if caretaker has capacity to take on 1 more pet on the given interval
drop function if exists hasSpareCapacity;
CREATE OR REPLACE FUNCTION hasSpareCapacity(cemail varchar, s date, e date)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return getPetLimit(cemail) > ALL (select num_jobs from getWorkload(cemail, s, e));
END;
$$;

-- return true if caretaker is available (not on leave if fulltime, and is on work if parttime) on the given interval
drop function if exists isAvail;
CREATE OR REPLACE FUNCTION isAvail(cemail varchar, s date, e date)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	IF (select is_fulltime from caretakers where email = cemail) THEN
		return not exists (
			select * from FullTimeLeave
			where
				email = cemail and
				clash(s, e, leave_date)
		);
	ELSE
		return not exists (
			SELECT generate_series(s::date, e::date, '1 day'::interval)::date as datez
			EXCEPT (select work_date as datez from parttimeavail where email = cemail)
		);
	END IF;
END;
$$;

drop function if exists canWork;
CREATE OR REPLACE FUNCTION canWork(cemail varchar, s date, e date)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return isAvail(cemail, s, e) AND hasSpareCapacity(cemail, s, e);
END;
$$;

-- returns whether oemail likes cemail
-- O likes C if O's average rating of C is >= 4
CREATE OR REPLACE FUNCTION likes(oemail varchar, cemail varchar)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return (select avg(rating) from bidsfor BF
		where
			BF.owner_email = oemail and
			BF.caretaker_email = cemail and
			rating is not null
		) >= 4;
END;
$$;

-- returns whether owners likes at least 3 caretakers in common
CREATE OR REPLACE FUNCTION isSimilar(oemail1 varchar, oemail2 varchar)
RETURNS boolean
language plpgsql
as
$$
BEGIN
	return (select COUNT(*) from 
		(
        select * from Caretakers where likes(oemail1, email)
		INTERSECT
		select * from Caretakers where likes(oemail2, email)
		) AS Common
	) >= 3;
END;
$$;

-- returns the number of blocks of length at least 150
CREATE OR REPLACE FUNCTION isLeaveValid(cemail varchar, yr int)
RETURNS boolean
language plpgsql
as
$$
DECLARE
	fd date;
	ld date;
	cemail_min date;
	cemail_max date;
	cemail_x bigint;
BEGIN
	select into fd (yr || '-01-01')::date;
	select into ld (yr || '-12-31')::date;
	
	IF (
		select COUNT(*) from fulltimeleave where
			email = cemail and
			fd <= leave_date and
			leave_date <= ld
		) <= 1 THEN
		RETURN True;
	END IF;
	
	select into cemail_min MIN(leave_date) from fulltimeleave where
		email = cemail and
		fd <= leave_date and
		leave_date <= ld;
	select into cemail_max MAX(leave_date) from fulltimeleave where
		email = cemail and
		fd <= leave_date and
		leave_date <= ld;
		
	select SUM(len / 150) into cemail_x from (
		select (lead(leave_date, 1) over (order by leave_date asc) - leave_date) as len
		from (
		SELECT 
			email, 
			leave_date
		FROM fulltimeleave where
			email = cemail and
			fd <= leave_date and
			leave_date <= ld
		ORDER BY leave_date asc
		) L1
	) L2;
		
   	cemail_x := cemail_x + (cemail_min - fd) / 150;
	cemail_x := cemail_x + (ld - cemail_max) / 150;
	
	return cemail_x >= 2;
END;
$$;


-- void function. Creates a new user and pcsadmin in a single transaction.
drop function if exists createPcsAdmin;
CREATE OR REPLACE FUNCTION createPcsAdmin(email varchar, username varchar)
RETURNS void
language plpgsql
AS
$$
BEGIN
    insert into users values (username, email, 'Your bio is blank. Tell the world about yourself!', 'password1');
    insert into pcsadmins values (email);
END;
$$;

-- void function. Creates a new user and fulltime caretaker in a single transaction.
drop function if exists createFtCaretaker;
CREATE OR REPLACE FUNCTION createFtCaretaker(email varchar, username varchar)
RETURNS void
language plpgsql
AS
$$
BEGIN
    insert into users values (username, email, 'Your bio is blank. Tell the world about yourself!', 'password1');
    insert into caretakers (email, is_fulltime) values (email, true);
END;
$$;

-- void function. Creates a new user and part time caretaker in a single transaction.
drop function if exists createPtCaretaker;
CREATE OR REPLACE FUNCTION createPtCaretaker(email varchar, username varchar, descript varchar, pass varchar)
RETURNS void
language plpgsql
AS
$$
BEGIN
    insert into users values (username, email, descript, pass);
    insert into caretakers (email, is_fulltime) values (email, false);
END;
$$;

-- void function. Creates a new user and petowner in a single transaction.
drop function if exists createPetOwner;
CREATE OR REPLACE FUNCTION createPetOwner(email varchar, username varchar, descript varchar, pass varchar)
RETURNS void
language plpgsql
AS
$$
BEGIN
    insert into users values (username, email, descript, pass);
    insert into petowners (email) values (email);
END;
$$;

-- void function. Creates a new user, petowner and part time caretaker in a single transaction.
drop function if exists createPtAndPo;
CREATE OR REPLACE FUNCTION createPtAndPo (email varchar, username varchar, descript varchar, pass varchar)
RETURNS void
language plpgsql
AS
$$
BEGIN
    insert into users values (username, email, descript, pass);
    insert into petowners (email) values (email);
    insert into caretakers (email, is_fulltime) values (email, false);
END;
$$;

-- getPetDays(email, start, end) -> int :: total pet days worked
-- returns NULL if email hasn't completed any jobs that month (have to check division by NULL)
drop function if exists getPetDays;
CREATE OR REPLACE FUNCTION getPetDays(cemail varchar, s date, e date)
RETURNS int
language plpgsql
as
$$
declare 
	daysWorked INTEGER;
BEGIN
	select sum(end_date - start_date + 1) into daysWorked
	from bidsfor
	where caretaker_email=cemail
		and (s <= end_date and end_date <= e)
		and is_paid
        and is_confirmed
	group by cemail;
	
	return daysWorked;
END;
$$;

-- getTotalRevenue(email, start, end) -> float :: total revenue
-- returns NULL if email hasn't completed any jobs that month hence earned no revenue 
-- take note of this when doing arithmetic with this result
drop function if exists getTotalRevenue;
CREATE OR REPLACE FUNCTION getTotalRevenue(cemail varchar, s date, e date)
RETURNS FLOAT
language plpgsql
as
$$
declare 
	revenue FLOAT;
BEGIN
	select sum((end_date - start_date + 1) * amount_bidded) into revenue
	from bidsfor 
	where is_paid 
        and is_confirmed
		and (s <= end_date and end_date <= e)
		and caretaker_email=cemail
	group by cemail;
	
	return revenue;
END;
$$;

-- getSalary(email, start, end) -> float
-- gets salary to be paid to a caretaker for jobs COMPLETED during 
-- [start, end] inclusive
-- e.g.: if job starts Jan 30, ends Feb 5, he will only be paid for the entire job 
-- in Feb
drop function if exists getSalary;
CREATE OR REPLACE FUNCTION getSalary(cemail varchar, s date, e date)
RETURNS float
language plpgsql
as
$$
declare
    -- these vars are null, caretaker didn't complete any jobs during period
    totalRev FLOAT := getTotalRevenue(cemail, s, e);
    daysWorked INT := getPetDays(cemail, s, e);
	avgPricePerDay FLOAT := totalRev / daysWorked;
	is_ft BOOLEAN;
BEGIN	
	select is_fulltime into is_ft
	from caretakers
	where email=cemail;
	
    if daysWorked is null then
        daysWorked := 0;
    end if;
	
    if totalRev is null then
        totalRev := 0;
    end if;

	if is_ft and daysWorked <= 60 then
        -- less than 60 pet days worked
		return 3000;
	elsif is_ft and daysWorked > 60 then
		return 3000 + ((daysWorked - 60) * avgPricePerDay);
	else -- is parttime
		return 0.75 * totalRev;
	end if;
END;
$$;

-- getWorkDays(email, start, end) -> int :: total working days worked
-- returns 0 if email hasn't completed any jobs that month
drop function if exists getWorkDays;
CREATE OR REPLACE FUNCTION getWorkDays(cemail varchar, s date, e date)
RETURNS int
language plpgsql
as
$$
declare 
	daysWorked INTEGER;
BEGIN
	select count(*) into daysWorked
	from generate_series (s::timestamp, e::timestamp, '1 day'::interval) dd 
	where exists (select 1 
                  from bidsFor B
                  where clash(B.start_date, B.end_date, date_trunc('day', dd)::date)
                    and B.is_confirmed
                    and B.is_paid
                    and B.caretaker_email=cemail);
	
	return daysWorked;
END;
$$;

-- compute the daily price for this caretaker and this pet type
-- if caretaker is full time, then returns base_price * 5 * rating (base_price depends on pet type)
-- if caretaker is part time, returns the price specified in Takecareprice if exists, else return null
CREATE OR REPLACE FUNCTION getDailyPrice(cemail varchar, spec varchar)
RETURNS DECIMAL(10, 2)
language plpgsql
as
$$
DECLARE
	r DECIMAL(10, 2);  -- rating
	bp DECIMAL(10, 2); -- base price
BEGIN
	select rating into r from Caretakers CT where CT.email = cemail;
	select base_price into bp from PetTypes PT where PT.species = spec;
	if isFullTime(cemail) then
		if r is null then
			return bp;
		else
			return bp + 5 * r;
		end if;
	else
		return (
			select daily_price from Takecareprice TCP
			where
				TCP.email = cemail and
				TCP.species = spec
			);
	end if;
END;
$$;

-- function to see which bids satisfy a set of criteria (i.e. a filter on bids)
DROP FUNCTION IF EXISTS filterBids;
CREATE OR REPLACE FUNCTION filterBids(
	p_po_name varchar, -- bids with this substr in petowner name
	p_ct_name varchar, -- bids with this substr in caretaker name
	p_is_fulltime boolean, -- bids with this type of caretaker
	p_pet_type varchar, -- bids with this pet type
	p_start_date date, -- bids with start_date after this
	p_end_date date, -- bids with end_date before this
	p_min DECIMAL(10, 2), -- bids with amount_bidded more than this
	p_max DECIMAL(10, 2), -- bids with amount_bidded less than this
	p_rating DECIMAL(10, 2), -- bids with rating more than this
	p_bid_status boolean, -- bids with this is_confirmed
	p_paid_status boolean) -- bids with this is_paid
RETURNS table (
	owner_email varchar,
	owner_name varchar,
	caretaker_email varchar,
	caretaker_name varchar,
	caretaker_rating DECIMAL(10, 2),
	is_fulltime boolean,
	species varchar,
	start_date date,
	end_date date,
	amount_bidded DECIMAL(10, 2),
	rating DECIMAL(10, 2),
	is_confirmed boolean,
	is_paid boolean
)
language plpgsql
AS
$$
BEGIN
    return query
	select
		EBF.owner_email,
		EBF.owner_name,
		EBF.caretaker_email,
		EBF.caretaker_name,
		EBF.caretaker_rating,
		EBF.is_fulltime,
		EBF.species,
		EBF.start_date,
		EBF.end_date,
		EBF.amount_bidded,
		EBF.rating,
		EBF.is_confirmed,
		EBF.is_paid
	from (
		BidsFor BF NATURAL JOIN (
			select U1.email as owner_email, U1.name as owner_name from users U1
		) UPO NATURAL JOIN (
			select U2.email as caretaker_email, U2.name as caretaker_name from users U2
		) UCT NATURAL JOIN (
			select C1.email as caretaker_email, C1.is_fulltime, C1.rating as caretaker_rating from Caretakers C1
		) CT NATURAL JOIN (
			select P1.email as owner_email, P1.pet_name, P1.species from Pets P1
		) PETS
	) as EBF
	where
		(EBF.owner_name LIKE ('%' || p_po_name || '%') or p_po_name is null) and
		(EBF.caretaker_name LIKE ('%' || p_ct_name || '%') or p_ct_name is null) and
		(EBF.is_fulltime = p_is_fulltime or p_is_fulltime is null) and
		(EBF.species = p_pet_type or p_pet_type is null) and
		(EBF.start_date >= p_start_date or p_start_date is null) and
		(EBF.end_date <= p_end_date or p_end_date is null) and
        (EBF.amount_bidded >= p_min or p_min is null) and
		(EBF.amount_bidded <= p_max or p_max is null) and
		(EBF.rating >= p_rating or p_rating is null) and
		(EBF.is_confirmed = p_bid_status or p_bid_status is null) and
		(EBF.is_paid = p_paid_status or p_paid_status is null);
END;
$$;

-- function to filter caretakers by a set of criteria
-- if a pet type is not specified, the price col will be null
-- if a pet type is specified, the price col will contain the price to take care of that pet
DROP FUNCTION IF EXISTS filterCaretakers;
CREATE OR REPLACE FUNCTION filterCaretakers(
	p_ct_name varchar, -- caretakers with this in their name
	p_rating DECIMAL(10, 2), -- caretakers with at least this rating
	p_is_fulltime boolean, -- caretaker of this type
	p_pet_type varchar, -- caretakers that can take care of this pet type, with p_min <= price <= p_max
	p_min DECIMAL(10, 2), -- note that if caretaker cannot take care of this pet type, the price does not matter
	p_max DECIMAL(10, 2),
	p_start_date date, -- caretakers that can work on this interval
	p_end_date date
) RETURNS table (
	email varchar,
	name varchar,
	rating DECIMAL(10, 2),
	is_fulltime boolean,
	daily_price DECIMAL(10, 2) -- this is null if no pet type is specified
)
language plpgsql
AS
$$
BEGIN
	if p_pet_type is null then
    	return query
		select
			ECT.email,
			ECT.name,
			ECT.rating,
			ECT.is_fulltime,
			null::numeric as daily_price
		from (
			Caretakers CT NATURAL JOIN (
				select U1.email, U1.name from users U1
			) U 
		) as ECT
		where
			(ECT.name LIKE ('%' || p_ct_name || '%') or p_ct_name is null) and
			(ECT.rating >= p_rating or p_rating is null) and
			(ECT.is_fulltime = p_is_fulltime or p_is_fulltime is null) and
			(p_start_date is null or p_end_date is null or canWork(ECT.email, p_start_date, p_end_date));
	else
    	return query
		select
			ECT.email,
			ECT.name,
			ECT.rating,
			ECT.is_fulltime,
			ECT.daily_price
		from (
			Caretakers CT NATURAL JOIN (
				select U1.email, U1.name from users U1
			) U NATURAL JOIN (
				select * from takecareprice
			) TCP
		) as ECT
		where
			(ECT.name LIKE ('%' || p_ct_name || '%') or p_ct_name is null) and
			(ECT.rating >= p_rating or p_rating is null) and
			(ECT.is_fulltime = p_is_fulltime or p_is_fulltime is null) and
			(ECT.species = p_pet_type) and
			(ECT.daily_price >= p_min or p_min is null) and
			(ECT.daily_price <= p_max or p_max is null) and
			(p_start_date is null or p_end_date is null or canWork(ECT.email, p_start_date, p_end_date));
	end if;
END;
$$;



















--=================================================== END HELPER ============================================================




























-- ======================================= GENERATED DATA =======================================
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

INSERT INTO Users(name, email, description, password) VALUES ('alice', 'alice@gmail.com', 'A user of PCS', 'alicepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alice@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'alice@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'alice@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'alice@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'alice@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-03-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-07-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-07-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-07-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alice@gmail.com', '2022-07-05');

INSERT INTO Users(name, email, description, password) VALUES ('alex', 'alex@gmail.com', 'A user of PCS', 'alexpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alex@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alex@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alex@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2021-12-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2021-12-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2021-12-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2022-12-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2022-12-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alex@gmail.com', '2022-12-11');

INSERT INTO Users(name, email, description, password) VALUES ('arnold', 'arnold@gmail.com', 'A user of PCS', 'arnoldpw');
INSERT INTO PetOwners(email) VALUES ('arnold@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arnold@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arnold@gmail.com', 'roger', 'roger needs love!', 'roger is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arnold@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arnold@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('bob', 'bob@gmail.com', 'A user of PCS', 'bobpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bob@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'bob@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bob@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'bob@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bob@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bob@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2021-02-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2021-02-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2021-03-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2022-06-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2022-06-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bob@gmail.com', '2022-06-25');

INSERT INTO Users(name, email, description, password) VALUES ('becky', 'becky@gmail.com', 'A user of PCS', 'beckypw');
INSERT INTO PetOwners(email) VALUES ('becky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('becky@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'becky@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'becky@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2022-05-22');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2022-05-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('becky@gmail.com', '2022-05-24');

INSERT INTO Users(name, email, description, password) VALUES ('beth', 'beth@gmail.com', 'A user of PCS', 'bethpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'beth@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'beth@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-07-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-07-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-07-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-22');

INSERT INTO Users(name, email, description, password) VALUES ('connor', 'connor@gmail.com', 'A user of PCS', 'connorpw');
INSERT INTO PetOwners(email) VALUES ('connor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('connor@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('connor@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'connor@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'connor@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'connor@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'connor@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'connor@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-04-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-04-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-04-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-05-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-05-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-05-27');

INSERT INTO Users(name, email, description, password) VALUES ('cassie', 'cassie@gmail.com', 'A user of PCS', 'cassiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cassie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cassie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'cassie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cassie@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-08-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-08-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-08-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-10-14');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-10-15');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-10-16');

INSERT INTO Users(name, email, description, password) VALUES ('carrie', 'carrie@gmail.com', 'A user of PCS', 'carriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'carrie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carrie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carrie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2021-11-23');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2021-11-24');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2021-11-25');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('caleb', 'caleb@gmail.com', 'A user of PCS', 'calebpw');
INSERT INTO PetOwners(email) VALUES ('caleb@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caleb@gmail.com', 'choco', 'choco needs love!', 'choco is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caleb@gmail.com', 'logan', 'logan needs love!', 'logan is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caleb@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caleb@gmail.com', 'axa', 'axa needs love!', 'axa is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caleb@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'caleb@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'caleb@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'caleb@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2021-06-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2021-06-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2021-06-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2022-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2022-06-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caleb@gmail.com', '2022-06-08');

INSERT INTO Users(name, email, description, password) VALUES ('charlie', 'charlie@gmail.com', 'A user of PCS', 'charliepw');
INSERT INTO PetOwners(email) VALUES ('charlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'roger', 'roger needs love!', 'roger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'choco', 'choco needs love!', 'choco is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charlie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'charlie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'charlie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2021-04-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2021-04-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2021-04-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2022-06-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2022-06-13');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charlie@gmail.com', '2022-06-14');

INSERT INTO Users(name, email, description, password) VALUES ('dick', 'dick@gmail.com', 'A user of PCS', 'dickpw');
INSERT INTO PetOwners(email) VALUES ('dick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dick@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dick@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dick@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dick@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'dick@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'dick@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'dick@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-07-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-07-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-07-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-07-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dick@gmail.com', '2022-02-05');

INSERT INTO Users(name, email, description, password) VALUES ('dawson', 'dawson@gmail.com', 'A user of PCS', 'dawsonpw');
INSERT INTO PetOwners(email) VALUES ('dawson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dawson@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dawson@gmail.com', 'sammy', 'sammy needs love!', 'sammy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dawson@gmail.com', 'abby', 'abby needs love!', 'abby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dawson@gmail.com', 'cloud', 'cloud needs love!', 'cloud is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('emma', 'emma@gmail.com', 'A user of PCS', 'emmapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'emma@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'emma@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'emma@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'emma@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'emma@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2021-08-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2021-08-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2021-08-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2022-09-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2022-09-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emma@gmail.com', '2022-09-28');

INSERT INTO Users(name, email, description, password) VALUES ('felix', 'felix@gmail.com', 'A user of PCS', 'felixpw');
INSERT INTO PetOwners(email) VALUES ('felix@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felix@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felix@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felix@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('gordon', 'gordon@gmail.com', 'A user of PCS', 'gordonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gordon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'gordon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (229, 'gordon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'gordon@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-01-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-01-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-01-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-01-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-10-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-10-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-10-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-10-05');

INSERT INTO Users(name, email, description, password) VALUES ('hassan', 'hassan@gmail.com', 'A user of PCS', 'hassanpw');
INSERT INTO PetOwners(email) VALUES ('hassan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hassan@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hassan@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hassan@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ian', 'ian@gmail.com', 'A user of PCS', 'ianpw');
INSERT INTO PetOwners(email) VALUES ('ian@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ian@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ian@gmail.com', 'gus', 'gus needs love!', 'gus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ian@gmail.com', 'axa', 'axa needs love!', 'axa is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ian@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('jenny', 'jenny@gmail.com', 'A user of PCS', 'jennypw');
INSERT INTO PetOwners(email) VALUES ('jenny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'ginger', 'ginger needs love!', 'ginger is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('konstance', 'konstance@gmail.com', 'A user of PCS', 'konstancepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('konstance@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'konstance@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'konstance@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2021-03-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2021-03-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2021-03-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2022-04-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2022-04-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('konstance@gmail.com', '2022-04-03');

INSERT INTO Users(name, email, description, password) VALUES ('rupert', 'rupert@gmail.com', 'A user of PCS', 'rupertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rupert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'rupert@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'rupert@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'rupert@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-01-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-01-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-01-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-01-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2021-05-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rupert@gmail.com', '2022-05-05');

INSERT INTO Users(name, email, description, password) VALUES ('ronald', 'ronald@gmail.com', 'A user of PCS', 'ronaldpw');
INSERT INTO PetOwners(email) VALUES ('ronald@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronald@gmail.com', 'jacky', 'jacky needs love!', 'jacky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronald@gmail.com', 'sammy', 'sammy needs love!', 'sammy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronald@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronald@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronald@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ronald@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ronald@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ronald@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ronald@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-03-16');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-03-17');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-03-18');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-05-09');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-05-10');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-05-11');

INSERT INTO Users(name, email, description, password) VALUES ('romeo', 'romeo@gmail.com', 'A user of PCS', 'romeopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('romeo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'romeo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'romeo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (257, 'romeo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'romeo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'romeo@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-08-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('romeo@gmail.com', '2022-06-05');

INSERT INTO Users(name, email, description, password) VALUES ('rick', 'rick@gmail.com', 'A user of PCS', 'rickpw');
INSERT INTO PetOwners(email) VALUES ('rick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'chad', 'chad needs love!', 'chad is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'choco', 'choco needs love!', 'choco is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('xiaoping', 'xiaoping@gmail.com', 'A user of PCS', 'xiaopingpw');
INSERT INTO PetOwners(email) VALUES ('xiaoping@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoping@gmail.com', 'buster', 'buster needs love!', 'buster is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoping@gmail.com', 'jacky', 'jacky needs love!', 'jacky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoping@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoping@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaoping@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'xiaoping@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'xiaoping@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'xiaoping@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2022-10-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2022-10-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoping@gmail.com', '2022-10-31');

INSERT INTO Users(name, email, description, password) VALUES ('xiaoming', 'xiaoming@gmail.com', 'A user of PCS', 'xiaomingpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaoming@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'xiaoming@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'xiaoming@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'xiaoming@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2021-08-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2021-08-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2021-08-28');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2022-12-26');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2022-12-27');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaoming@gmail.com', '2022-12-28');

INSERT INTO Users(name, email, description, password) VALUES ('xiaodong', 'xiaodong@gmail.com', 'A user of PCS', 'xiaodongpw');
INSERT INTO PetOwners(email) VALUES ('xiaodong@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaodong@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaodong@gmail.com', 'buster', 'buster needs love!', 'buster is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaodong@gmail.com', 'logan', 'logan needs love!', 'logan is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaodong@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'xiaodong@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'xiaodong@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'xiaodong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'xiaodong@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'xiaodong@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-05-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2021-03-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaodong@gmail.com', '2022-08-05');

INSERT INTO Users(name, email, description, password) VALUES ('xiaolong', 'xiaolong@gmail.com', 'A user of PCS', 'xiaolongpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaolong@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'xiaolong@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'xiaolong@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2021-06-29');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2021-06-30');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2022-05-11');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2022-05-12');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaolong@gmail.com', '2022-05-13');

INSERT INTO Users(name, email, description, password) VALUES ('xiaobao', 'xiaobao@gmail.com', 'A user of PCS', 'xiaobaopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaobao@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'xiaobao@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'xiaobao@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-04-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-04-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-04-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2021-04-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaobao@gmail.com', '2022-12-05');

INSERT INTO Users(name, email, description, password) VALUES ('xiaorong', 'xiaorong@gmail.com', 'A user of PCS', 'xiaorongpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaorong@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'xiaorong@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'xiaorong@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2021-04-19');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2021-04-20');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2021-04-21');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2022-03-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2022-03-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaorong@gmail.com', '2022-03-05');

INSERT INTO Users(name, email, description, password) VALUES ('xiaohong', 'xiaohong@gmail.com', 'A user of PCS', 'xiaohongpw');
INSERT INTO PetOwners(email) VALUES ('xiaohong@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaohong@gmail.com', 'choco', 'choco needs love!', 'choco is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('xiaozong', 'xiaozong@gmail.com', 'A user of PCS', 'xiaozongpw');
INSERT INTO PetOwners(email) VALUES ('xiaozong@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaozong@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaozong@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Dog', 'Dog');








INSERT INTO BidsFor VALUES ('felix@gmail.com', 'cassie@gmail.com', 'charlie', '2020-01-01 00:00:00', '2021-11-04', '2021-11-06', 80, 84, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'rupert@gmail.com', 'sammy', '2020-01-01 00:00:01', '2021-02-16', '2021-02-21', 87, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'alice@gmail.com', 'boomer', '2020-01-01 00:00:02', '2022-11-24', '2022-11-26', 72, 89, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaohong@gmail.com', 'carrie@gmail.com', 'choco', '2020-01-01 00:00:03', '2022-03-09', '2022-03-10', 140, 165, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'becky@gmail.com', 'buster', '2020-01-01 00:00:04', '2021-07-24', '2021-07-29', 110, 137, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaodong@gmail.com', 'chewie', '2020-01-01 00:00:05', '2021-04-16', '2021-04-19', 172, 178, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'beth@gmail.com', 'choco', '2020-01-01 00:00:06', '2021-05-19', '2021-05-19', 50, 54, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'xiaolong@gmail.com', 'maddie', '2020-01-01 00:00:07', '2022-11-06', '2022-11-12', 50, 52, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('connor@gmail.com', 'xiaobao@gmail.com', 'roscoe', '2020-01-01 00:00:08', '2021-04-30', '2021-04-30', 171, 184, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaozong@gmail.com', 'xiaodong@gmail.com', 'daisy', '2020-01-01 00:00:09', '2022-12-10', '2022-12-10', 172, 183, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'connor@gmail.com', 'logan', '2020-01-01 00:00:10', '2022-10-05', '2022-10-07', 110, 116, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'connor@gmail.com', 'ginger', '2020-01-01 00:00:11', '2022-11-15', '2022-11-16', 90, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'xiaoping@gmail.com', 'chippy', '2020-01-01 00:00:12', '2022-10-26', '2022-10-31', 70, 92, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ronald@gmail.com', 'romeo@gmail.com', 'sammy', '2020-01-01 00:00:13', '2022-10-01', '2022-10-01', 257, 260, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'alex@gmail.com', 'roscoe', '2020-01-01 00:00:14', '2022-11-27', '2022-11-27', 90, 94, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaolong@gmail.com', 'bandit', '2020-01-01 00:00:15', '2022-09-04', '2022-09-06', 100, 126, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ronald@gmail.com', 'xiaodong@gmail.com', 'jacky', '2020-01-01 00:00:16', '2021-02-01', '2021-02-07', 78, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'dick@gmail.com', 'sammy', '2020-01-01 00:00:17', '2022-11-06', '2022-11-09', 199, 208, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('connor@gmail.com', 'cassie@gmail.com', 'roscoe', '2020-01-01 00:00:18', '2022-07-28', '2022-07-31', 90, 94, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'cassie@gmail.com', 'chad', '2020-01-01 00:00:19', '2021-07-11', '2021-07-14', 100, 130, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'carrie@gmail.com', 'jacky', '2020-01-01 00:00:20', '2021-04-19', '2021-04-20', 130, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'xiaolong@gmail.com', 'logan', '2020-01-01 00:00:21', '2022-06-20', '2022-06-23', 50, 56, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'cassie@gmail.com', 'daisy', '2020-01-01 00:00:22', '2021-10-01', '2021-10-02', 90, 109, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'gordon@gmail.com', 'daisy', '2020-01-01 00:00:23', '2021-03-23', '2021-03-28', 134, 156, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'xiaoping@gmail.com', 'gizmo', '2020-01-01 00:00:24', '2022-08-18', '2022-08-20', 120, 138, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaolong@gmail.com', 'chewie', '2020-01-01 00:00:25', '2022-05-18', '2022-05-19', 100, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaolong@gmail.com', 'bandit', '2020-01-01 00:00:26', '2022-07-22', '2022-07-27', 100, 100, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'romeo@gmail.com', 'gizmo', '2020-01-01 00:00:27', '2021-10-05', '2021-10-10', 49, 63, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('connor@gmail.com', 'connor@gmail.com', 'roscoe', '2020-01-01 00:00:28', '2022-11-29', '2022-11-29', 90, 92, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaohong@gmail.com', 'bob@gmail.com', 'choco', '2020-01-01 00:00:29', '2021-08-13', '2021-08-13', 140, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'alex@gmail.com', 'roscoe', '2020-01-01 00:00:30', '2021-08-17', '2021-08-21', 90, 113, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'connor@gmail.com', 'daisy', '2020-01-01 00:00:31', '2021-08-04', '2021-08-05', 90, 112, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'xiaolong@gmail.com', 'charlie', '2020-01-01 00:00:32', '2021-01-12', '2021-01-18', 100, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'romeo@gmail.com', 'gus', '2020-01-01 00:00:33', '2021-07-11', '2021-07-16', 257, 262, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'emma@gmail.com', 'abby', '2020-01-01 00:00:34', '2021-11-19', '2021-11-23', 140, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaolong@gmail.com', 'bandit', '2020-01-01 00:00:35', '2021-02-01', '2021-02-02', 100, 127, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'xiaobao@gmail.com', 'daisy', '2020-01-01 00:00:36', '2021-02-04', '2021-02-09', 171, 176, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'becky@gmail.com', 'gizmo', '2020-01-01 00:00:37', '2021-02-13', '2021-02-15', 70, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'xiaobao@gmail.com', 'daisy', '2020-01-01 00:00:38', '2022-06-28', '2022-07-04', 171, 191, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'rupert@gmail.com', 'choco', '2020-01-01 00:00:39', '2022-12-14', '2022-12-20', 128, 141, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'emma@gmail.com', 'daisy', '2020-01-01 00:00:40', '2021-06-23', '2021-06-27', 90, 102, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'xiaolong@gmail.com', 'charlie', '2020-01-01 00:00:41', '2022-09-11', '2022-09-16', 50, 73, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ronald@gmail.com', 'carrie@gmail.com', 'sammy', '2020-01-01 00:00:42', '2022-02-12', '2022-02-15', 130, 158, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'xiaoping@gmail.com', 'gizmo', '2020-01-01 00:00:43', '2022-03-15', '2022-03-17', 70, 78, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'ronald@gmail.com', 'chad', '2020-01-01 00:00:44', '2022-05-13', '2022-05-13', 100, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('connor@gmail.com', 'xiaoming@gmail.com', 'roscoe', '2020-01-01 00:00:45', '2022-10-06', '2022-10-09', 90, 104, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'dick@gmail.com', 'hugo', '2020-01-01 00:00:46', '2022-06-17', '2022-06-20', 64, 68, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'connor@gmail.com', 'roscoe', '2020-01-01 00:00:47', '2021-04-19', '2021-04-20', 90, 102, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'charlie@gmail.com', 'boomer', '2020-01-01 00:00:48', '2022-03-29', '2022-03-29', 110, 130, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'beth@gmail.com', 'jerry', '2020-01-01 00:00:49', '2022-11-13', '2022-11-19', 100, 119, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'bob@gmail.com', 'gus', '2020-01-01 00:00:50', '2021-03-27', '2021-04-02', 130, 133, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaodong@gmail.com', 'roger', '2020-01-01 00:00:51', '2021-01-27', '2021-01-29', 217, 221, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'caleb@gmail.com', 'boomer', '2020-01-01 00:00:52', '2021-02-10', '2021-02-14', 110, 122, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ronald@gmail.com', 'bob@gmail.com', 'jacky', '2020-01-01 00:00:53', '2022-07-28', '2022-07-29', 130, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'romeo@gmail.com', 'gizmo', '2020-01-01 00:00:54', '2021-11-24', '2021-11-24', 49, 70, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'konstance@gmail.com', 'charlie', '2020-01-01 00:00:55', '2021-10-21', '2021-10-24', 50, 52, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'connor@gmail.com', 'roger', '2020-01-01 00:00:56', '2021-10-08', '2021-10-13', 50, 70, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'carrie@gmail.com', 'bandit', '2020-01-01 00:00:57', '2022-03-11', '2022-03-11', 100, 104, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'charlie@gmail.com', 'fergie', '2020-01-01 00:00:58', '2021-12-15', '2021-12-17', 130, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaohong@gmail.com', 'emma@gmail.com', 'choco', '2020-01-01 00:00:59', '2022-11-27', '2022-12-02', 140, 152, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'xiaoping@gmail.com', 'gizmo', '2020-01-01 00:01:00', '2022-08-17', '2022-08-20', 120, 140, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'emma@gmail.com', 'axa', '2020-01-01 00:01:01', '2021-02-17', '2021-02-18', 120, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'romeo@gmail.com', 'choco', '2020-01-01 00:01:02', '2022-05-29', '2022-05-29', 257, 274, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'konstance@gmail.com', 'choco', '2020-01-01 00:01:03', '2022-12-23', '2022-12-26', 130, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'konstance@gmail.com', 'roger', '2020-01-01 00:01:04', '2021-07-11', '2021-07-12', 50, 52, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'alice@gmail.com', 'buster', '2020-01-01 00:01:05', '2022-08-04', '2022-08-05', 72, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'bob@gmail.com', 'abby', '2020-01-01 00:01:06', '2021-05-26', '2021-05-26', 140, 159, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'gordon@gmail.com', 'gizmo', '2020-01-01 00:01:07', '2022-03-06', '2022-03-10', 229, 252, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'dick@gmail.com', 'chippy', '2020-01-01 00:01:08', '2022-08-11', '2022-08-12', 64, 73, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'dick@gmail.com', 'chippy', '2020-01-01 00:01:09', '2022-07-23', '2022-07-28', 64, 77, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'xiaoping@gmail.com', 'sammy', '2020-01-01 00:01:10', '2022-05-08', '2022-05-09', 120, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'carrie@gmail.com', 'jacky', '2020-01-01 00:01:11', '2021-12-01', '2021-12-02', 130, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaozong@gmail.com', 'connor@gmail.com', 'jerry', '2020-01-01 00:01:12', '2022-05-24', '2022-05-24', 50, 63, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaohong@gmail.com', 'caleb@gmail.com', 'choco', '2020-01-01 00:01:13', '2021-12-16', '2021-12-21', 140, 166, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'xiaoming@gmail.com', 'bandit', '2020-01-01 00:01:14', '2021-10-28', '2021-11-01', 60, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaodong@gmail.com', 'roger', '2020-01-01 00:01:15', '2021-01-29', '2021-01-29', 217, 247, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'bob@gmail.com', 'gizmo', '2020-01-01 00:01:16', '2021-12-14', '2021-12-20', 120, 143, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rick@gmail.com', 'alex@gmail.com', 'roscoe', '2020-01-01 00:01:17', '2022-07-17', '2022-07-17', 90, 113, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaozong@gmail.com', 'xiaolong@gmail.com', 'jerry', '2020-01-01 00:01:18', '2022-02-15', '2022-02-20', 50, 64, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'carrie@gmail.com', 'fergie', '2020-01-01 00:01:19', '2022-10-16', '2022-10-19', 130, 155, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'dick@gmail.com', 'chippy', '2020-01-01 00:01:20', '2021-04-12', '2021-04-12', 64, 81, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaohong@gmail.com', 'bob@gmail.com', 'choco', '2020-01-01 00:01:21', '2022-02-08', '2022-02-13', 140, 144, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'romeo@gmail.com', 'choco', '2020-01-01 00:01:22', '2021-12-10', '2021-12-13', 257, 281, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'alex@gmail.com', 'fergie', '2020-01-01 00:01:23', '2021-08-08', '2021-08-12', 120, 147, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'romeo@gmail.com', 'choco', '2020-01-01 00:01:24', '2022-09-10', '2022-09-12', 30, 55, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'xiaoming@gmail.com', 'daisy', '2020-01-01 00:01:25', '2022-11-20', '2022-11-20', 90, 109, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'cassie@gmail.com', 'gizmo', '2020-01-01 00:01:26', '2022-04-29', '2022-05-05', 120, 146, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'emma@gmail.com', 'fergie', '2020-01-01 00:01:27', '2022-08-19', '2022-08-19', 140, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'carrie@gmail.com', 'fergie', '2020-01-01 00:01:28', '2022-05-24', '2022-05-24', 140, 169, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'alice@gmail.com', 'boomer', '2020-01-01 00:01:29', '2021-02-13', '2021-02-14', 72, 102, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hassan@gmail.com', 'dick@gmail.com', 'gizmo', '2020-01-01 00:01:30', '2022-11-03', '2022-11-03', 64, 89, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'xiaobao@gmail.com', 'daisy', '2020-01-01 00:01:31', '2021-06-29', '2021-06-30', 171, 174, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'xiaoping@gmail.com', 'axa', '2020-01-01 00:01:32', '2022-01-14', '2022-01-17', 120, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dawson@gmail.com', 'gordon@gmail.com', 'sammy', '2020-01-01 00:01:33', '2022-02-12', '2022-02-12', 229, 257, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'connor@gmail.com', 'ginger', '2020-01-01 00:01:34', '2021-11-14', '2021-11-19', 90, 111, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('caleb@gmail.com', 'konstance@gmail.com', 'charlie', '2020-01-01 00:01:35', '2022-11-17', '2022-11-23', 50, 78, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('connor@gmail.com', 'xiaobao@gmail.com', 'roscoe', '2020-01-01 00:01:36', '2021-09-21', '2021-09-21', 171, 174, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'ronald@gmail.com', 'charlie', '2020-01-01 00:01:37', '2021-03-11', '2021-03-11', 80, 97, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arnold@gmail.com', 'xiaorong@gmail.com', 'rufus', '2020-01-01 00:01:38', '2022-09-15', '2022-09-21', 110, 128, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ronald@gmail.com', 'bob@gmail.com', 'jacky', '2020-01-01 00:01:39', '2021-11-26', '2021-11-29', 130, 132, NULL, False, '1', '1', NULL, NULL);



-- ======================================= END GENERATED DATA =======================================



































INSERT INTO BidsFor VALUES ('panter@gmail.com', 'cassie@gmail.com', 'roger',
'2020-10-25', '2020-01-01', '2020-01-01',
100, 110,
false, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'cassie@gmail.com', 'alfie',
'2020-10-25', '2020-01-01', '2020-01-05',
80, 130,
false, true, '1', '1', 5
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
'2020-01-01', '2022-01-05', '2022-01-10',
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
'2020-01-02', '2022-01-05', '2022-01-07',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'xiaoming@gmail.com', 'fido',
'2020-01-03', '2022-01-06', '2022-01-08',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('panter@gmail.com', 'xiaoming@gmail.com', 'fido',
'2020-01-04', '2022-01-07', '2022-01-09',
80, 110,
true, true, '1', '1', 5
);


-- test recommends
-- input pistachio should return celine, cejudo
-- input patty should return xiaohong
INSERT INTO BidsFor VALUES ('pistachio@gmail.com', 'xiaohong@gmail.com', 'millie',
'2022-01-01', '2022-01-02', '2022-01-05',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pistachio@gmail.com', 'carl@gmail.com', 'choco',
'2022-01-01', '2022-01-02', '2022-01-05',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pistachio@gmail.com', 'carlos@gmail.com', 'choco',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);

INSERT INTO BidsFor VALUES ('patty@gmail.com', 'carlos@gmail.com', 'jerry',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('patty@gmail.com', 'cejudo@gmail.com', 'jerry',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('patty@gmail.com', 'carl@gmail.com', 'biscuit',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pattison@gmail.com', 'carlos@gmail.com', 'tom',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('pattison@gmail.com', 'celine@gmail.com', 'tom',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('parthus@gmail.com', 'carl@gmail.com', 'roscoe',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('parthus@gmail.com', 'canneth@gmail.com', 'charlie',
'2022-01-01', '2022-01-06', '2022-01-10',
80, 110,
true, true, '1', '1', 5
);

Delete from Takecareprice where email = 'canneth@gmail.com' and species = 'Dog';
INSERT INTO Takecareprice(daily_price, email, species) VALUES (100, 'xiaohong@gmail.com', 'Turtle');

-- test bidsFor trigger
-- if the first bid is updated to is_confirmed = True, it will set is_confirmed = False for the 2nd and 3rd bids
INSERT INTO BidsFor VALUES ('pistachio@gmail.com', 'carl@gmail.com', 'millie',
'2022-01-01', '2023-01-05', '2023-01-10',
80, 110,
null, null, '1', '1', null
);
INSERT INTO BidsFor VALUES ('parthus@gmail.com', 'carl@gmail.com', 'hugo',
'2020-01-01', '2023-01-01', '2023-01-05',
80, 110,
null, null, '1', '1', null
);
INSERT INTO BidsFor VALUES ('parthus@gmail.com', 'carl@gmail.com', 'hugo',
'2020-01-02', '2023-01-10', '2023-01-15',
80, 110,
null, null, '1', '1', null
);
INSERT INTO BidsFor VALUES ('parthus@gmail.com', 'carl@gmail.com', 'hugo',
'2020-01-03', '2023-01-5', '2023-01-20',
80, 110,
null, null, '1', '1', null
);

-- test recommend 2
-- perry likes xiaohong, xiaoming, xiaobao
-- pearl likes xiaohong, xiaoming, xiaobao, xiaorong, cain, caren
-- perry owns dog, hamster, bird
-- cain cares for cat, monkey
-- caren cares for dog, cat, turtle
-- perry knows xiaorong, cain does not care for perry pets, caren care for perry pets (dog)
-- recommend caren only
delete from takecareprice where email = 'cain@gmail.com' and species = 'Dog'; -- delete dog from cain's carefor set

INSERT INTO BidsFor VALUES ('perry@gmail.com', 'carrie@gmail.com', 'axa',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 1
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'carrie@gmail.com', 'axa',
'2020-01-02', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 2
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'xiaohong@gmail.com', 'axa',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 3
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'xiaohong@gmail.com', 'axa',
'2020-01-02', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 5
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'xiaoming@gmail.com', 'axa',
'2020-01-02', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'xiaobao@gmail.com', 'axa',
'2020-01-02', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('perry@gmail.com', 'xiaorong@gmail.com', 'axa',
'2020-01-02', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);

INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'xiaohong@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'xiaoming@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'xiaobao@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'xiaorong@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'cain@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);
INSERT INTO BidsFor VALUES ('pearl@gmail.com', 'caren@gmail.com', 'abby',
'2020-01-01', '2020-01-01', '2020-01-05',
80, 110,
true, false, '1', '1', 4
);

--================================================ TRIGGERS ===================================================================
-- You might want to comment out the triggers so it is easier to put in data to test

--users covering constraint
CREATE OR REPLACE FUNCTION check_user_covering() RETURNS TRIGGER
    AS $$
DECLARE 
    uncovered_user VARCHAR(30);
BEGIN 
    SELECT email INTO uncovered_user
    FROM Users u
    WHERE NOT EXISTS (
        SELECT 1
        FROM PetOwners p
        WHERE p.email = u.email
    )
    AND
    NOT EXISTS (
        SELECT 1
        FROM CareTakers c
        WHERE c.email = u.email
    )
    AND 
    NOT EXISTS (
        SELECT 1
        FROM PcsAdmins pcs
        WHERE pcs.email = u.email
    );
    
    IF uncovered_user IS NOT NULL THEN 
        RAISE exception 'user % must belong to one user type', uncovered_user;
    END IF;
    RETURN NULL;

END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS user_cover_trigger ON Users;
CREATE CONSTRAINT TRIGGER user_cover_trigger
    AFTER INSERT ON Users
    DEFERRABLE INITIALLY DEFERRED
    FOR EACH ROW
    EXECUTE PROCEDURE check_user_covering();

-- admin + petowner overlap constraint
CREATE OR REPLACE FUNCTION check_admin_petowner_overlap() RETURNS TRIGGER
    AS $$
DECLARE 
    overlap_user VARCHAR(30);
BEGIN
    SELECT pcs.email into overlap_user
    FROM PcsAdmins pcs, PetOwners p
    WHERE pcs.email = p.email;

    IF overlap_user IS NOT NULL THEN
        RAISE exception '% should not be both PCS Admin and Pet Owner', overlap_user;
    END IF;
    RETURN NULL;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS petowner_overlap_trigger ON PetOwners;
CREATE TRIGGER petowner_overlap_trigger
    AFTER INSERT ON PetOwners
    EXECUTE PROCEDURE check_admin_petowner_overlap();

DROP TRIGGER IF EXISTS pcs_petowner_overlap_trigger ON PcsAdmins;
CREATE TRIGGER pcs_petowner_overlap_trigger
    AFTER INSERT ON PcsAdmins
    EXECUTE PROCEDURE check_admin_petowner_overlap();

-- admin + caretaker overlap constraint
CREATE OR REPLACE FUNCTION check_admin_caretaker_overlap() RETURNS TRIGGER
    AS $$
DECLARE 
    overlap_user VARCHAR(30);
BEGIN
    SELECT pcs.email into overlap_user
    FROM PcsAdmins pcs, CareTakers c
    WHERE pcs.email = c.email;

    IF overlap_user IS NOT NULL THEN
        RAISE exception '% should not be both PCS Admin and CareTaker', overlap_user;
    END IF;
    RETURN NULL;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS caretaker_overlap_trigger ON CareTakers;
CREATE TRIGGER caretaker_overlap_trigger
    AFTER INSERT ON CareTakers
    EXECUTE PROCEDURE check_admin_caretaker_overlap();

DROP TRIGGER IF EXISTS pcs_caretaker_overlap_trigger ON PcsAdmins;
CREATE TRIGGER pcs_caretaker_overlap_trigger
    AFTER INSERT ON PcsAdmins
    EXECUTE PROCEDURE check_admin_caretaker_overlap();

-- Trigger: when a bid has its is_confirmed set to True, this trigger will find all clashing bids and set is_confirmed to False
-- bid B clashes with bid A if B have same caretaker_email as A and bid B's (start_date, end_date) overlaps with that of A
CREATE OR REPLACE FUNCTION invalidate_bids()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	update bidsfor BF set
		is_confirmed = false
	where
		BF.caretaker_email = NEW.caretaker_email and
		BF.is_confirmed isnull and
		NOT canWork(NEW.caretaker_email, BF.start_date, BF.end_date);
	return new;
END;
$$;

drop trigger if exists trigger_invalidate_bids on BidsFor;
CREATE TRIGGER trigger_invalidate_bids
    AFTER UPDATE OF is_confirmed ON BidsFor
    FOR EACH ROW
    EXECUTE PROCEDURE invalidate_bids();


-- Trigger: when a bidsFor has rating updated, this function will compute the caretakers new rating and update Caretakers table
CREATE OR REPLACE FUNCTION update_rating()
RETURNS trigger
language plpgsql
as
$$
DECLARE
	r DECIMAL(10, 2);
BEGIN
	select AVG(rating) into r from bidsfor
	where
		caretaker_email = NEW.caretaker_email and
		rating is not null;
		
	update Caretakers CT set
		rating = r
	where
		CT.email = NEW.caretaker_email;
		
	return new;
END;
$$;

DROP TRIGGER IF EXISTS trigger_update_rating on BidsFor;
CREATE TRIGGER trigger_update_rating
    AFTER UPDATE OF rating ON BidsFor
    FOR EACH ROW
    EXECUTE PROCEDURE update_rating();


-- trigger: prevent adding leave when you have a confirmed bid that overlaps with the leave date (Full Time)
CREATE OR REPLACE FUNCTION block_taking_leave()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	IF EXISTS (
		select 1 from bidsFor
		where
			caretaker_email = NEW.email and
			((start_date, end_date + interval '1 day') overlaps (NEW.leave_date, NEW.leave_date + interval '1 day'))
			and is_confirmed = true
	) THEN
		RAISE EXCEPTION 'You have a job on this date';
	END IF;
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_block_taking_leave on FullTimeLeave;
CREATE TRIGGER trigger_block_taking_leave
    BEFORE INSERT ON FullTimeLeave
    FOR EACH ROW
    EXECUTE PROCEDURE block_taking_leave();

-- trigger: full time caretaker accept bid immediately if he can work
CREATE OR REPLACE FUNCTION ft_accept_bid() RETURNS TRIGGER
    AS $$
BEGIN
    UPDATE BidsFor BF
    SET is_confirmed = true
    WHERE 
        BF.caretaker_email = NEW.caretaker_email AND
        BF.owner_email = NEW.owner_email AND
        BF.pet_name = NEW.pet_name AND
        BF.submission_time = NEW.submission_time AND 
        canWork(NEW.caretaker_email, NEW.start_date, NEW.end_date) AND
        EXISTS (select 1 from Caretakers where email = New.caretaker_email and is_fulltime=true);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ft_accept_bid ON BidsFor;
CREATE TRIGGER ft_accept_bid
    AFTER INSERT ON BidsFor
	FOR EACH ROW
    EXECUTE PROCEDURE ft_accept_bid();


-- trigger to ensure the leave table is valid
-- if invalid row is entered into leave table, this trigger will delete that row
CREATE OR REPLACE FUNCTION isLeaveValidTrigger()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	IF NOT (
		(
		select sum(len / 150) from (
			select (lead(leave_date, 1) over (order by leave_date asc)) - leave_date - 1 as len
			FROM (
				select * from fulltimeleave
				where
					email = NEW.email and
					EXTRACT(YEAR FROM leave_date) = EXTRACT(YEAR FROM NEW.leave_date)::int
				UNION
				select NEW.email as email, ((EXTRACT(YEAR FROM NEW.leave_date)::int - 1) || '-12-31')::date as leave_date
				UNION
				select NEW.email as email, ((EXTRACT(YEAR FROM NEW.leave_date)::int + 1) || '-01-01')::date as leave_date
			) L1
		) L2
		) >= 2
	) THEN
		RAISE 'Invalid leave pattern';
	END IF;
	RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS is_leave_valid_trigger ON FullTimeLeave;
CREATE CONSTRAINT TRIGGER is_leave_valid_trigger
    AFTER INSERT ON FullTimeLeave
    FOR EACH ROW
    EXECUTE PROCEDURE isLeaveValidTrigger();


-- trigger: prevent deleting avail when you have a confirmed bid that overlaps with the avail date (Part Time)
CREATE OR REPLACE FUNCTION block_deleting_avail()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	IF EXISTS (
		select 1 from bidsFor
		where
			caretaker_email = OLD.email and
			((start_date, end_date + interval '1 day') overlaps (OLD.work_date, OLD.work_date + interval '1 day'))
	) THEN
		RAISE EXCEPTION 'You have a job on this date';
	END IF;
	RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trigger_block_deleting_avail on PartTimeAvail;
CREATE TRIGGER trigger_block_deleting_avail
    BEFORE DELETE ON PartTimeAvail
    FOR EACH ROW
    EXECUTE PROCEDURE block_deleting_avail();

-- trigger: prevent adding bid when you have no avail date (Part Time)
CREATE OR REPLACE FUNCTION block_inserting_bid_part_time()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	IF EXISTS (
        select 1 from CareTakers
        where 
            email = NEW.caretaker_email and is_fulltime = false
    ) 
    AND
    EXISTS (
		select generate_series(NEW.start_date, NEW.end_date, '1 day'::interval)::date as work_date
		EXCEPT
		select work_date from PartTimeAvail where email = NEW.caretaker_email
	) THEN
		RAISE EXCEPTION 'Part time worker does not have availability on this date';
	END IF;
	RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_block_inserting_bid_part_time on BidsFor;
CREATE TRIGGER trigger_block_inserting_bid_part_time
    BEFORE INSERT ON BidsFor
    FOR EACH ROW
    EXECUTE PROCEDURE block_inserting_bid_part_time();


-- trigger to ensure that only partTime Caretakers are inserted into the PartTimeAvail table
CREATE OR REPLACE FUNCTION partTimeEntryIsPartTime()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	if isFullTime(NEW.email) THEN
		RAISE EXCEPTION 'Cannot insert because % is not a part time caretaker', NEW.email;
		return null;
	end if;
	return new;
END;
$$;

DROP TRIGGER IF EXISTS trigger_check_part_time_entry on PartTimeAvail;
CREATE TRIGGER trigger_check_part_time_entry
    BEFORE INSERT ON PartTimeAvail
    FOR EACH ROW
    EXECUTE PROCEDURE partTimeEntryIsPartTime();
	
-- trigger to ensure that only fullTime Caretakers are inserted into the FullTimeLeave table
CREATE OR REPLACE FUNCTION fullTimeEntryIsFullTime()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	if not isFullTime(NEW.email) THEN
		RAISE EXCEPTION 'Cannot insert because % is not a full time caretaker', NEW.email;
		return null;
	end if;
	return new;
END;
$$;

DROP TRIGGER IF EXISTS trigger_check_full_time_entry on FullTimeLeave;
CREATE TRIGGER trigger_check_full_time_entry
    BEFORE INSERT ON FullTimeLeave
    FOR EACH ROW
    EXECUTE PROCEDURE fullTimeEntryIsFullTime();

-- trigger to update a caretakers daily price when his rating changes
CREATE OR REPLACE FUNCTION updatePriceOnRatingChange()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	-- update the daily_price of this caretaker for all the pet types
    -- but only if this caretaker is a fulltime caretaker
    IF isFullTime(NEW.email) THEN
	    UPDATE TakecarePrice TP SET
		    daily_price = getDailyPrice(NEW.email, species)
	    WHERE
		    TP.email = NEW.email;
    END IF;

	RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_update_price_on_rating_change on Caretakers;
CREATE TRIGGER trigger_update_price_on_rating_change
    AFTER UPDATE OF rating ON Caretakers
    FOR EACH ROW
    EXECUTE PROCEDURE updatePriceOnRatingChange();


-- trigger to update all full time caretakers daily price for a particular pet
-- when the base_price of that pet is changed
CREATE OR REPLACE FUNCTION updatePriceOnBasePriceChange()
RETURNS trigger
language plpgsql
as
$$
BEGIN
	-- update the daily_price of all caretaker that take care of NEW.species
	UPDATE Takecareprice TP SET
		daily_price = getDailyPrice(email, NEW.species)
	WHERE
		TP.species = NEW.species and
        isFullTime(TP.email);
		
	RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS trigger_update_price_on_base_price_change on PetTypes;
CREATE TRIGGER trigger_update_price_on_base_price_change
    AFTER UPDATE OF base_price ON PetTypes
    FOR EACH ROW
    EXECUTE PROCEDURE updatePriceOnBasePriceChange();

-- =============================================== END TRIGGERS ====================================================
