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
    PRIMARY KEY (caretaker_email, owner_email, pet_name, submission_time),
    CONSTRAINT bidsfor_dates_check CHECK (submission_time < start_date AND start_date <= end_date),
    CONSTRAINT bidsfor_price_le_bid_amount CHECK (price <= amount_bidded),
    CONSTRAINT bidsfor_confirm_before_paid CHECK (NOT is_paid OR is_confirmed) -- check that is_paid implies confirmed
);

CREATE TABLE TakecarePrice (
    daily_price DECIMAL(10,2),
    email varchar(30) REFERENCES Caretakers(email) ON DELETE cascade, -- references the caretaker
    species varchar(30) REFERENCES PetTypes(species) ON DELETE cascade,
    PRIMARY KEY (email, species)  --- daily price > base price
);

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



--==================================================== first half of trigger ====================================================

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
		RAISE 'Invalid leave pattern for % on %', NEW.email, NEW.leave_date;
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


--==================================================== first half of trigger ====================================================





















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

INSERT INTO Users(name, email, description, password) VALUES ('rosalinda', 'rosalinda@gmail.com', 'A user of PCS', 'rosalindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosalinda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rosalinda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rosalinda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rosalinda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rosalinda@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('aundrea', 'aundrea@gmail.com', 'A user of PCS', 'aundreapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aundrea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'aundrea@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'aundrea@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aundrea@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('corrina', 'corrina@gmail.com', 'A user of PCS', 'corrinapw');
INSERT INTO PetOwners(email) VALUES ('corrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'freckles', 'freckles needs love!', 'freckles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'blaze', 'blaze needs love!', 'blaze is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'samson', 'samson needs love!', 'samson is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('sidonia', 'sidonia@gmail.com', 'A user of PCS', 'sidoniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sidonia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sidonia@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sidonia@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ansell', 'ansell@gmail.com', 'A user of PCS', 'ansellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ansell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ansell@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ansell@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ansell@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('federico', 'federico@gmail.com', 'A user of PCS', 'federicopw');
INSERT INTO PetOwners(email) VALUES ('federico@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'hannah', 'hannah needs love!', 'hannah is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'monty', 'monty needs love!', 'monty is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'little-one', 'little-one needs love!', 'little-one is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('federico@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'federico@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'federico@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'federico@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'federico@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'federico@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('federico@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kienan', 'kienan@gmail.com', 'A user of PCS', 'kienanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kienan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'kienan@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kienan@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kienan@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('rubin', 'rubin@gmail.com', 'A user of PCS', 'rubinpw');
INSERT INTO PetOwners(email) VALUES ('rubin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rubin@gmail.com', 'kato', 'kato needs love!', 'kato is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('andrej', 'andrej@gmail.com', 'A user of PCS', 'andrejpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrej@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'andrej@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'andrej@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'andrej@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('andrej@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('idette', 'idette@gmail.com', 'A user of PCS', 'idettepw');
INSERT INTO PetOwners(email) VALUES ('idette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idette@gmail.com', 'koty', 'koty needs love!', 'koty is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idette@gmail.com', 'monkey', 'monkey needs love!', 'monkey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('latrena', 'latrena@gmail.com', 'A user of PCS', 'latrenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latrena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'latrena@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'latrena@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'latrena@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'latrena@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latrena@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latrena@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('helli', 'helli@gmail.com', 'A user of PCS', 'hellipw');
INSERT INTO PetOwners(email) VALUES ('helli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'katz', 'katz needs love!', 'katz is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'samantha', 'samantha needs love!', 'samantha is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'jewels', 'jewels needs love!', 'jewels is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('helli@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'helli@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'helli@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'helli@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helli@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ezechiel', 'ezechiel@gmail.com', 'A user of PCS', 'ezechielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ezechiel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ezechiel@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('alexander', 'alexander@gmail.com', 'A user of PCS', 'alexanderpw');
INSERT INTO PetOwners(email) VALUES ('alexander@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alexander@gmail.com', 'michael', 'michael needs love!', 'michael is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alexander@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alexander@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'alexander@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexander@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('natalina', 'natalina@gmail.com', 'A user of PCS', 'natalinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('natalina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'natalina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'natalina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'natalina@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natalina@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natalina@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('bond', 'bond@gmail.com', 'A user of PCS', 'bondpw');
INSERT INTO PetOwners(email) VALUES ('bond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bond@gmail.com', 'mitzy', 'mitzy needs love!', 'mitzy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('margarette', 'margarette@gmail.com', 'A user of PCS', 'margarettepw');
INSERT INTO PetOwners(email) VALUES ('margarette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'shorty', 'shorty needs love!', 'shorty is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'binky', 'binky needs love!', 'binky is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margarette@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margarette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'margarette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'margarette@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'margarette@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'margarette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'margarette@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarette@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('estella', 'estella@gmail.com', 'A user of PCS', 'estellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'estella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (234, 'estella@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'estella@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'estella@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estella@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estella@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcello', 'marcello@gmail.com', 'A user of PCS', 'marcellopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcello@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'marcello@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'marcello@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'marcello@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcello@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcello@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('aleksandr', 'aleksandr@gmail.com', 'A user of PCS', 'aleksandrpw');
INSERT INTO PetOwners(email) VALUES ('aleksandr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'coal', 'coal needs love!', 'coal is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'papa', 'papa needs love!', 'papa is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'diesel', 'diesel needs love!', 'diesel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aleksandr@gmail.com', 'otis', 'otis needs love!', 'otis is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aleksandr@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'aleksandr@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'aleksandr@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'aleksandr@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aleksandr@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aleksandr@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ange', 'ange@gmail.com', 'A user of PCS', 'angepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ange@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ange@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ange@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ange@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ange@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fara', 'fara@gmail.com', 'A user of PCS', 'farapw');
INSERT INTO PetOwners(email) VALUES ('fara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fara@gmail.com', 'bodie', 'bodie needs love!', 'bodie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'fara@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'fara@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'fara@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'fara@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fara@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fara@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('laina', 'laina@gmail.com', 'A user of PCS', 'lainapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'laina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'laina@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laina@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laina@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('mandi', 'mandi@gmail.com', 'A user of PCS', 'mandipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mandi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mandi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mandi@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('francis', 'francis@gmail.com', 'A user of PCS', 'francispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'francis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'francis@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'francis@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'francis@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francis@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francis@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('ernaline', 'ernaline@gmail.com', 'A user of PCS', 'ernalinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ernaline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'ernaline@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ernaline@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ernaline@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('gonzales', 'gonzales@gmail.com', 'A user of PCS', 'gonzalespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gonzales@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gonzales@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gonzales@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lennard', 'lennard@gmail.com', 'A user of PCS', 'lennardpw');
INSERT INTO PetOwners(email) VALUES ('lennard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'booker', 'booker needs love!', 'booker is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'rosa', 'rosa needs love!', 'rosa is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('tanner', 'tanner@gmail.com', 'A user of PCS', 'tannerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tanner@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tanner@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tanner@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tanner@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tanner@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tanner@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tanner@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorry', 'dorry@gmail.com', 'A user of PCS', 'dorrypw');
INSERT INTO PetOwners(email) VALUES ('dorry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'schotzie', 'schotzie needs love!', 'schotzie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'jags', 'jags needs love!', 'jags is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'muffin', 'muffin needs love!', 'muffin is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorry@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dorry@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorry@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('hilario', 'hilario@gmail.com', 'A user of PCS', 'hilariopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hilario@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'hilario@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'hilario@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hilario@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'hilario@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hilario@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hilario@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('kennan', 'kennan@gmail.com', 'A user of PCS', 'kennanpw');
INSERT INTO PetOwners(email) VALUES ('kennan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'brindle', 'brindle needs love!', 'brindle is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'sebastian', 'sebastian needs love!', 'sebastian is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'lincoln', 'lincoln needs love!', 'lincoln is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'jelly-bean', 'jelly-bean needs love!', 'jelly-bean is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'kennan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kennan@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'kennan@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'kennan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'kennan@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kennan@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kennan@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('maryanna', 'maryanna@gmail.com', 'A user of PCS', 'maryannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maryanna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'maryanna@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'maryanna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'maryanna@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'maryanna@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'maryanna@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryanna@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryanna@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('karia', 'karia@gmail.com', 'A user of PCS', 'kariapw');
INSERT INTO PetOwners(email) VALUES ('karia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karia@gmail.com', 'claire', 'claire needs love!', 'claire is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'karia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'karia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'karia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'karia@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karia@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('lauree', 'lauree@gmail.com', 'A user of PCS', 'laureepw');
INSERT INTO PetOwners(email) VALUES ('lauree@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lauree@gmail.com', 'jet', 'jet needs love!', 'jet is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lauree@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lauree@gmail.com', 'norton', 'norton needs love!', 'norton is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('peggy', 'peggy@gmail.com', 'A user of PCS', 'peggypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('peggy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'peggy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'peggy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'peggy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'peggy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'peggy@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('peggy@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('peggy@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('clareta', 'clareta@gmail.com', 'A user of PCS', 'claretapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clareta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'clareta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'clareta@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('clair', 'clair@gmail.com', 'A user of PCS', 'clairpw');
INSERT INTO PetOwners(email) VALUES ('clair@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'gator', 'gator needs love!', 'gator is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clair@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'clair@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'clair@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'clair@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'clair@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'clair@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clair@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clair@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('cosette', 'cosette@gmail.com', 'A user of PCS', 'cosettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cosette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cosette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cosette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'cosette@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('jenelle', 'jenelle@gmail.com', 'A user of PCS', 'jenellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'jenelle@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('joshua', 'joshua@gmail.com', 'A user of PCS', 'joshuapw');
INSERT INTO PetOwners(email) VALUES ('joshua@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'gilbert', 'gilbert needs love!', 'gilbert is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'comet', 'comet needs love!', 'comet is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('dougy', 'dougy@gmail.com', 'A user of PCS', 'dougypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dougy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'dougy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'dougy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'dougy@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dougy@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dougy@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('carr', 'carr@gmail.com', 'A user of PCS', 'carrpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carr@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'carr@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'carr@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'carr@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'carr@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carr@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carr@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('juliette', 'juliette@gmail.com', 'A user of PCS', 'juliettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juliette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'juliette@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'juliette@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'juliette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'juliette@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliette@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliette@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('stanislaus', 'stanislaus@gmail.com', 'A user of PCS', 'stanislauspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stanislaus@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'stanislaus@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'stanislaus@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stanislaus@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stanislaus@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('danna', 'danna@gmail.com', 'A user of PCS', 'dannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('danna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'danna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'danna@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'danna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'danna@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'danna@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('danna@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('danna@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('mayne', 'mayne@gmail.com', 'A user of PCS', 'maynepw');
INSERT INTO PetOwners(email) VALUES ('mayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'kasey', 'kasey needs love!', 'kasey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'ollie', 'ollie needs love!', 'ollie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'phoenix', 'phoenix needs love!', 'phoenix is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mayne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'mayne@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'mayne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'mayne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'mayne@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mayne@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mayne@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('tobye', 'tobye@gmail.com', 'A user of PCS', 'tobyepw');
INSERT INTO PetOwners(email) VALUES ('tobye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('erwin', 'erwin@gmail.com', 'A user of PCS', 'erwinpw');
INSERT INTO PetOwners(email) VALUES ('erwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'buster', 'buster needs love!', 'buster is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'pepper', 'pepper needs love!', 'pepper is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'baron', 'baron needs love!', 'baron is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('rowe', 'rowe@gmail.com', 'A user of PCS', 'rowepw');
INSERT INTO PetOwners(email) VALUES ('rowe@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rowe@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rowe@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rowe@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('claudie', 'claudie@gmail.com', 'A user of PCS', 'claudiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'claudie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'claudie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'claudie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (260, 'claudie@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudie@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('cissiee', 'cissiee@gmail.com', 'A user of PCS', 'cissieepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cissiee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cissiee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cissiee@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cissiee@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('berte', 'berte@gmail.com', 'A user of PCS', 'bertepw');
INSERT INTO PetOwners(email) VALUES ('berte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'gidget', 'gidget needs love!', 'gidget is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'lexi', 'lexi needs love!', 'lexi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'porkchop', 'porkchop needs love!', 'porkchop is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'diesel', 'diesel needs love!', 'diesel is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'dozer', 'dozer needs love!', 'dozer is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('calley', 'calley@gmail.com', 'A user of PCS', 'calleypw');
INSERT INTO PetOwners(email) VALUES ('calley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calley@gmail.com', 'norton', 'norton needs love!', 'norton is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calley@gmail.com', 'destini', 'destini needs love!', 'destini is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calley@gmail.com', 'kiwi', 'kiwi needs love!', 'kiwi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calley@gmail.com', 'oz', 'oz needs love!', 'oz is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calley@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('letti', 'letti@gmail.com', 'A user of PCS', 'lettipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('letti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'letti@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('letti@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('friedrick', 'friedrick@gmail.com', 'A user of PCS', 'friedrickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('friedrick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'friedrick@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'friedrick@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'friedrick@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'friedrick@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cecil', 'cecil@gmail.com', 'A user of PCS', 'cecilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cecil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'cecil@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cecil@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cecil@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('alma', 'alma@gmail.com', 'A user of PCS', 'almapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alma@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'alma@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alma@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alma@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('tonye', 'tonye@gmail.com', 'A user of PCS', 'tonyepw');
INSERT INTO PetOwners(email) VALUES ('tonye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'norton', 'norton needs love!', 'norton is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tonye@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tonye@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tonye@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tonye@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('gwyn', 'gwyn@gmail.com', 'A user of PCS', 'gwynpw');
INSERT INTO PetOwners(email) VALUES ('gwyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwyn@gmail.com', 'samantha', 'samantha needs love!', 'samantha is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwyn@gmail.com', 'dodger', 'dodger needs love!', 'dodger is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwyn@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwyn@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwyn@gmail.com', 'curry', 'curry needs love!', 'curry is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('justino', 'justino@gmail.com', 'A user of PCS', 'justinopw');
INSERT INTO PetOwners(email) VALUES ('justino@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('justino@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('justino@gmail.com', 'nugget', 'nugget needs love!', 'nugget is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('gradeigh', 'gradeigh@gmail.com', 'A user of PCS', 'gradeighpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gradeigh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gradeigh@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gradeigh@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gradeigh@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gradeigh@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('delphinia', 'delphinia@gmail.com', 'A user of PCS', 'delphiniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('delphinia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'delphinia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'delphinia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'delphinia@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delphinia@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('halie', 'halie@gmail.com', 'A user of PCS', 'haliepw');
INSERT INTO PetOwners(email) VALUES ('halie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'caesar', 'caesar needs love!', 'caesar is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'jewels', 'jewels needs love!', 'jewels is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'brindle', 'brindle needs love!', 'brindle is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('waverly', 'waverly@gmail.com', 'A user of PCS', 'waverlypw');
INSERT INTO PetOwners(email) VALUES ('waverly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'salty', 'salty needs love!', 'salty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'freedom', 'freedom needs love!', 'freedom is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('waverly@gmail.com', 'cole', 'cole needs love!', 'cole is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('waverly@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'waverly@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('waverly@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('waverly@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('bride', 'bride@gmail.com', 'A user of PCS', 'bridepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bride@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'bride@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'bride@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bride@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'bride@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bride@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bride@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('susi', 'susi@gmail.com', 'A user of PCS', 'susipw');
INSERT INTO PetOwners(email) VALUES ('susi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susi@gmail.com', 'ginny', 'ginny needs love!', 'ginny is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susi@gmail.com', 'diesel', 'diesel needs love!', 'diesel is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susi@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('iggie', 'iggie@gmail.com', 'A user of PCS', 'iggiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iggie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'iggie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'iggie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'iggie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'iggie@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iggie@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iggie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('zandra', 'zandra@gmail.com', 'A user of PCS', 'zandrapw');
INSERT INTO PetOwners(email) VALUES ('zandra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'diva', 'diva needs love!', 'diva is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'blast', 'blast needs love!', 'blast is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'sadie', 'sadie needs love!', 'sadie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zandra@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'zandra@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zandra@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zandra@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('randa', 'randa@gmail.com', 'A user of PCS', 'randapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('randa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'randa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'randa@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'randa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'randa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'randa@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('sherilyn', 'sherilyn@gmail.com', 'A user of PCS', 'sherilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sherilyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'sherilyn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'sherilyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'sherilyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'sherilyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'sherilyn@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherilyn@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sherilyn@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('charin', 'charin@gmail.com', 'A user of PCS', 'charinpw');
INSERT INTO PetOwners(email) VALUES ('charin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charin@gmail.com', 'chevy', 'chevy needs love!', 'chevy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charin@gmail.com', 'abbey', 'abbey needs love!', 'abbey is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('rodney', 'rodney@gmail.com', 'A user of PCS', 'rodneypw');
INSERT INTO PetOwners(email) VALUES ('rodney@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodney@gmail.com', 'persy', 'persy needs love!', 'persy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodney@gmail.com', 'bobby', 'bobby needs love!', 'bobby is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('felike', 'felike@gmail.com', 'A user of PCS', 'felikepw');
INSERT INTO PetOwners(email) VALUES ('felike@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felike@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felike@gmail.com', 'kiki', 'kiki needs love!', 'kiki is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felike@gmail.com', 'pickles', 'pickles needs love!', 'pickles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felike@gmail.com', 'ashes', 'ashes needs love!', 'ashes is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felike@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'felike@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'felike@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'felike@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felike@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felike@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('mandy', 'mandy@gmail.com', 'A user of PCS', 'mandypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mandy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mandy@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mandy@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kimbell', 'kimbell@gmail.com', 'A user of PCS', 'kimbellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kimbell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kimbell@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kimbell@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('dwight', 'dwight@gmail.com', 'A user of PCS', 'dwightpw');
INSERT INTO PetOwners(email) VALUES ('dwight@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwight@gmail.com', 'goldie', 'goldie needs love!', 'goldie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwight@gmail.com', 'mollie', 'mollie needs love!', 'mollie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwight@gmail.com', 'doc', 'doc needs love!', 'doc is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwight@gmail.com', 'sissy', 'sissy needs love!', 'sissy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('beau', 'beau@gmail.com', 'A user of PCS', 'beaupw');
INSERT INTO PetOwners(email) VALUES ('beau@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('ronald', 'ronald@gmail.com', 'A user of PCS', 'ronaldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronald@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ronald@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('shelly', 'shelly@gmail.com', 'A user of PCS', 'shellypw');
INSERT INTO PetOwners(email) VALUES ('shelly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelly@gmail.com', 'libby', 'libby needs love!', 'libby is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelly@gmail.com', 'sherman', 'sherman needs love!', 'sherman is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelly@gmail.com', 'nona', 'nona needs love!', 'nona is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelly@gmail.com', 'kc', 'kc needs love!', 'kc is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shelly@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shelly@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ingaberg', 'ingaberg@gmail.com', 'A user of PCS', 'ingabergpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ingaberg@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'ingaberg@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (213, 'ingaberg@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingaberg@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingaberg@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('curcio', 'curcio@gmail.com', 'A user of PCS', 'curciopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('curcio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'curcio@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'curcio@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'curcio@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'curcio@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('curcio@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('carlynn', 'carlynn@gmail.com', 'A user of PCS', 'carlynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'carlynn@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'carlynn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'carlynn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'carlynn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carlynn@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynn@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('adel', 'adel@gmail.com', 'A user of PCS', 'adelpw');
INSERT INTO PetOwners(email) VALUES ('adel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'kira', 'kira needs love!', 'kira is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'isabella', 'isabella needs love!', 'isabella is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'paris', 'paris needs love!', 'paris is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'daphne', 'daphne needs love!', 'daphne is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('kahlil', 'kahlil@gmail.com', 'A user of PCS', 'kahlilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kahlil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'kahlil@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('emanuele', 'emanuele@gmail.com', 'A user of PCS', 'emanuelepw');
INSERT INTO PetOwners(email) VALUES ('emanuele@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'brook', 'brook needs love!', 'brook is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'chad', 'chad needs love!', 'chad is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emanuele@gmail.com', 'bobbie', 'bobbie needs love!', 'bobbie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('geneva', 'geneva@gmail.com', 'A user of PCS', 'genevapw');
INSERT INTO PetOwners(email) VALUES ('geneva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'paris', 'paris needs love!', 'paris is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'kurly', 'kurly needs love!', 'kurly is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'allie', 'allie needs love!', 'allie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geneva@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'geneva@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'geneva@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'geneva@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geneva@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jo', 'jo@gmail.com', 'A user of PCS', 'jopw');
INSERT INTO PetOwners(email) VALUES ('jo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'katie', 'katie needs love!', 'katie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'rocket', 'rocket needs love!', 'rocket is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'dutches', 'dutches needs love!', 'dutches is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'patty', 'patty needs love!', 'patty is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('atalanta', 'atalanta@gmail.com', 'A user of PCS', 'atalantapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('atalanta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'atalanta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'atalanta@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('atalanta@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('atalanta@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('anetta', 'anetta@gmail.com', 'A user of PCS', 'anettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'anetta@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('cortney', 'cortney@gmail.com', 'A user of PCS', 'cortneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cortney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cortney@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cortney@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('mordecai', 'mordecai@gmail.com', 'A user of PCS', 'mordecaipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mordecai@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'mordecai@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'mordecai@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'mordecai@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'mordecai@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'mordecai@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mordecai@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mordecai@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('harrison', 'harrison@gmail.com', 'A user of PCS', 'harrisonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harrison@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'harrison@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (212, 'harrison@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'harrison@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harrison@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harrison@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('daron', 'daron@gmail.com', 'A user of PCS', 'daronpw');
INSERT INTO PetOwners(email) VALUES ('daron@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'hunter', 'hunter needs love!', 'hunter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('xylia', 'xylia@gmail.com', 'A user of PCS', 'xyliapw');
INSERT INTO PetOwners(email) VALUES ('xylia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xylia@gmail.com', 'magic', 'magic needs love!', 'magic is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xylia@gmail.com', 'luci', 'luci needs love!', 'luci is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xylia@gmail.com', 'queenie', 'queenie needs love!', 'queenie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('geordie', 'geordie@gmail.com', 'A user of PCS', 'geordiepw');
INSERT INTO PetOwners(email) VALUES ('geordie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geordie@gmail.com', 'rhett', 'rhett needs love!', 'rhett is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geordie@gmail.com', 'petey', 'petey needs love!', 'petey is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geordie@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geordie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'geordie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'geordie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'geordie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'geordie@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('geordie@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('geordie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('carley', 'carley@gmail.com', 'A user of PCS', 'carleypw');
INSERT INTO PetOwners(email) VALUES ('carley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'ricky', 'ricky needs love!', 'ricky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'happyt', 'happyt needs love!', 'happyt is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'griffen', 'griffen needs love!', 'griffen is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('letizia', 'letizia@gmail.com', 'A user of PCS', 'letiziapw');
INSERT INTO PetOwners(email) VALUES ('letizia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letizia@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('brena', 'brena@gmail.com', 'A user of PCS', 'brenapw');
INSERT INTO PetOwners(email) VALUES ('brena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'axle', 'axle needs love!', 'axle is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brena@gmail.com', 'basil', 'basil needs love!', 'basil is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('ulrike', 'ulrike@gmail.com', 'A user of PCS', 'ulrikepw');
INSERT INTO PetOwners(email) VALUES ('ulrike@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'chips', 'chips needs love!', 'chips is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'sally', 'sally needs love!', 'sally is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'diego', 'diego needs love!', 'diego is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('candy', 'candy@gmail.com', 'A user of PCS', 'candypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('candy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'candy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (197, 'candy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'candy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'candy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'candy@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('candy@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('candy@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('kalila', 'kalila@gmail.com', 'A user of PCS', 'kalilapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalila@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'kalila@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'kalila@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'kalila@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'kalila@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalila@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalila@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorthy', 'dorthy@gmail.com', 'A user of PCS', 'dorthypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorthy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'dorthy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dorthy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'dorthy@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorthy@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorthy@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('flynn', 'flynn@gmail.com', 'A user of PCS', 'flynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('flynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'flynn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'flynn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'flynn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'flynn@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('flynn@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('paulina', 'paulina@gmail.com', 'A user of PCS', 'paulinapw');
INSERT INTO PetOwners(email) VALUES ('paulina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paulina@gmail.com', 'mercedes', 'mercedes needs love!', 'mercedes is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paulina@gmail.com', 'red', 'red needs love!', 'red is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paulina@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paulina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'paulina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'paulina@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paulina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ric', 'ric@gmail.com', 'A user of PCS', 'ricpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ric@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'ric@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'ric@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'ric@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ric@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ric@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('rhianon', 'rhianon@gmail.com', 'A user of PCS', 'rhianonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rhianon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'rhianon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'rhianon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'rhianon@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rhianon@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rhianon@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('donnamarie', 'donnamarie@gmail.com', 'A user of PCS', 'donnamariepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donnamarie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'donnamarie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'donnamarie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnamarie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnamarie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dre', 'dre@gmail.com', 'A user of PCS', 'drepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dre@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dre@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dre@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dre@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dre@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dre@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dre@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('maynord', 'maynord@gmail.com', 'A user of PCS', 'maynordpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maynord@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'maynord@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'maynord@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'maynord@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (212, 'maynord@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'maynord@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maynord@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maynord@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('imelda', 'imelda@gmail.com', 'A user of PCS', 'imeldapw');
INSERT INTO PetOwners(email) VALUES ('imelda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'sherman', 'sherman needs love!', 'sherman is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'camille', 'camille needs love!', 'camille is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'simon', 'simon needs love!', 'simon is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('imelda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'imelda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'imelda@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'imelda@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('imelda@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('imelda@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('cash', 'cash@gmail.com', 'A user of PCS', 'cashpw');
INSERT INTO PetOwners(email) VALUES ('cash@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cash@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cash@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'cash@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'cash@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'cash@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'cash@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'cash@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('iago', 'iago@gmail.com', 'A user of PCS', 'iagopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iago@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'iago@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'iago@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (241, 'iago@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iago@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iago@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('philly', 'philly@gmail.com', 'A user of PCS', 'phillypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('philly@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'philly@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'philly@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'philly@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philly@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philly@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('dwayne', 'dwayne@gmail.com', 'A user of PCS', 'dwaynepw');
INSERT INTO PetOwners(email) VALUES ('dwayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'brook', 'brook needs love!', 'brook is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('latisha', 'latisha@gmail.com', 'A user of PCS', 'latishapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latisha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'latisha@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (236, 'latisha@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('doralynne', 'doralynne@gmail.com', 'A user of PCS', 'doralynnepw');
INSERT INTO PetOwners(email) VALUES ('doralynne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'joey', 'joey needs love!', 'joey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'buster', 'buster needs love!', 'buster is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'beauty', 'beauty needs love!', 'beauty is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'hailey', 'hailey needs love!', 'hailey is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('doralynne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'doralynne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'doralynne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'doralynne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'doralynne@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'doralynne@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('doralynne@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('doralynne@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('remy', 'remy@gmail.com', 'A user of PCS', 'remypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('remy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'remy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'remy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'remy@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ryley', 'ryley@gmail.com', 'A user of PCS', 'ryleypw');
INSERT INTO PetOwners(email) VALUES ('ryley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'alex', 'alex needs love!', 'alex is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'magic', 'magic needs love!', 'magic is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'ivory', 'ivory needs love!', 'ivory is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'kyra', 'kyra needs love!', 'kyra is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'paddy', 'paddy needs love!', 'paddy is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ryley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'ryley@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'ryley@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'ryley@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'ryley@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ryley@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ryley@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('graig', 'graig@gmail.com', 'A user of PCS', 'graigpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('graig@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'graig@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'graig@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'graig@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'graig@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'graig@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('graig@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('graig@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('irwinn', 'irwinn@gmail.com', 'A user of PCS', 'irwinnpw');
INSERT INTO PetOwners(email) VALUES ('irwinn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('irwinn@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('irwinn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'irwinn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'irwinn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'irwinn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'irwinn@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('irwinn@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('irwinn@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('felipa', 'felipa@gmail.com', 'A user of PCS', 'felipapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felipa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'felipa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (183, 'felipa@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'felipa@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'felipa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'felipa@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felipa@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felipa@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('montague', 'montague@gmail.com', 'A user of PCS', 'montaguepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('montague@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'montague@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'montague@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('montague@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('montague@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('morgen', 'morgen@gmail.com', 'A user of PCS', 'morgenpw');
INSERT INTO PetOwners(email) VALUES ('morgen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'brie', 'brie needs love!', 'brie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'lightning', 'lightning needs love!', 'lightning is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('ava', 'ava@gmail.com', 'A user of PCS', 'avapw');
INSERT INTO PetOwners(email) VALUES ('ava@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'ryder', 'ryder needs love!', 'ryder is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'flint', 'flint needs love!', 'flint is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('vyky', 'vyky@gmail.com', 'A user of PCS', 'vykypw');
INSERT INTO PetOwners(email) VALUES ('vyky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('jaime', 'jaime@gmail.com', 'A user of PCS', 'jaimepw');
INSERT INTO PetOwners(email) VALUES ('jaime@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'doodles', 'doodles needs love!', 'doodles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('bail', 'bail@gmail.com', 'A user of PCS', 'bailpw');
INSERT INTO PetOwners(email) VALUES ('bail@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bail@gmail.com', 'gretel', 'gretel needs love!', 'gretel is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bail@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bail@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bail@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'bail@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'bail@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'bail@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (243, 'bail@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bail@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bail@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('sonny', 'sonny@gmail.com', 'A user of PCS', 'sonnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sonny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'sonny@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'sonny@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'sonny@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'sonny@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sonny@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sonny@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('jenni', 'jenni@gmail.com', 'A user of PCS', 'jennipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jenni@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jenni@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jenni@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jenni@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jenni@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('dagmar', 'dagmar@gmail.com', 'A user of PCS', 'dagmarpw');
INSERT INTO PetOwners(email) VALUES ('dagmar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'silver', 'silver needs love!', 'silver is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'miles', 'miles needs love!', 'miles is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'blue', 'blue needs love!', 'blue is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dagmar@gmail.com', 'layla', 'layla needs love!', 'layla is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dagmar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'dagmar@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'dagmar@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'dagmar@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'dagmar@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dagmar@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dagmar@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('wittie', 'wittie@gmail.com', 'A user of PCS', 'wittiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wittie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'wittie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'wittie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'wittie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'wittie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'wittie@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wittie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wittie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('neville', 'neville@gmail.com', 'A user of PCS', 'nevillepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('neville@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'neville@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'neville@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'neville@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neville@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('mahmud', 'mahmud@gmail.com', 'A user of PCS', 'mahmudpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mahmud@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mahmud@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'mahmud@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mahmud@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mahmud@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('alfreda', 'alfreda@gmail.com', 'A user of PCS', 'alfredapw');
INSERT INTO PetOwners(email) VALUES ('alfreda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alfreda@gmail.com', 'duffy', 'duffy needs love!', 'duffy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alfreda@gmail.com', 'dots', 'dots needs love!', 'dots is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('andrus', 'andrus@gmail.com', 'A user of PCS', 'andruspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrus@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'andrus@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'andrus@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrus@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrus@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shirl', 'shirl@gmail.com', 'A user of PCS', 'shirlpw');
INSERT INTO PetOwners(email) VALUES ('shirl@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shirl@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shirl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'shirl@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'shirl@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'shirl@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'shirl@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'shirl@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shirl@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shirl@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('cletus', 'cletus@gmail.com', 'A user of PCS', 'cletuspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cletus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cletus@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('chuck', 'chuck@gmail.com', 'A user of PCS', 'chuckpw');
INSERT INTO PetOwners(email) VALUES ('chuck@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chuck@gmail.com', 'kibbles', 'kibbles needs love!', 'kibbles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chuck@gmail.com', 'blast', 'blast needs love!', 'blast is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chuck@gmail.com', 'jamie', 'jamie needs love!', 'jamie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chuck@gmail.com', 'skippy', 'skippy needs love!', 'skippy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('jefferson', 'jefferson@gmail.com', 'A user of PCS', 'jeffersonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jefferson@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jefferson@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'jefferson@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'jefferson@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jefferson@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jefferson@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('jorie', 'jorie@gmail.com', 'A user of PCS', 'joriepw');
INSERT INTO PetOwners(email) VALUES ('jorie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'maxine', 'maxine needs love!', 'maxine is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('murdock', 'murdock@gmail.com', 'A user of PCS', 'murdockpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('murdock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'murdock@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'murdock@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'murdock@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'murdock@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'murdock@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('andrew', 'andrew@gmail.com', 'A user of PCS', 'andrewpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrew@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (204, 'andrew@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'andrew@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'andrew@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'andrew@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrew@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrew@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('hashim', 'hashim@gmail.com', 'A user of PCS', 'hashimpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hashim@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hashim@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hashim@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hashim@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hashim@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('paula', 'paula@gmail.com', 'A user of PCS', 'paulapw');
INSERT INTO PetOwners(email) VALUES ('paula@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paula@gmail.com', 'kallie', 'kallie needs love!', 'kallie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paula@gmail.com', 'milo', 'milo needs love!', 'milo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paula@gmail.com', 'jade', 'jade needs love!', 'jade is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paula@gmail.com', 'arrow', 'arrow needs love!', 'arrow is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paula@gmail.com', 'chanel', 'chanel needs love!', 'chanel is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paula@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'paula@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('anderson', 'anderson@gmail.com', 'A user of PCS', 'andersonpw');
INSERT INTO PetOwners(email) VALUES ('anderson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'bradley', 'bradley needs love!', 'bradley is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('mirabel', 'mirabel@gmail.com', 'A user of PCS', 'mirabelpw');
INSERT INTO PetOwners(email) VALUES ('mirabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mirabel@gmail.com', 'bj', 'bj needs love!', 'bj is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('mella', 'mella@gmail.com', 'A user of PCS', 'mellapw');
INSERT INTO PetOwners(email) VALUES ('mella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'kobe', 'kobe needs love!', 'kobe is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mella@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'mella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mella@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mella@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mella@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('otho', 'otho@gmail.com', 'A user of PCS', 'othopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('otho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'otho@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'otho@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'otho@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'otho@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'otho@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otho@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('demetra', 'demetra@gmail.com', 'A user of PCS', 'demetrapw');
INSERT INTO PetOwners(email) VALUES ('demetra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'plato', 'plato needs love!', 'plato is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'chevy', 'chevy needs love!', 'chevy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'josie', 'josie needs love!', 'josie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'sarah', 'sarah needs love!', 'sarah is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('sheila-kathryn', 'sheila-kathryn@gmail.com', 'A user of PCS', 'sheila-kathrynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sheila-kathryn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (225, 'sheila-kathryn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'sheila-kathryn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sheila-kathryn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'sheila-kathryn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'sheila-kathryn@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sheila-kathryn@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sheila-kathryn@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('boony', 'boony@gmail.com', 'A user of PCS', 'boonypw');
INSERT INTO PetOwners(email) VALUES ('boony@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'scrappy', 'scrappy needs love!', 'scrappy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'koty', 'koty needs love!', 'koty is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boony@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boony@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'boony@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'boony@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'boony@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'boony@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('teresa', 'teresa@gmail.com', 'A user of PCS', 'teresapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('teresa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'teresa@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('philippe', 'philippe@gmail.com', 'A user of PCS', 'philippepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('philippe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'philippe@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'philippe@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'philippe@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philippe@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philippe@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('maximo', 'maximo@gmail.com', 'A user of PCS', 'maximopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maximo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'maximo@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maximo@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('red', 'red@gmail.com', 'A user of PCS', 'redpw');
INSERT INTO PetOwners(email) VALUES ('red@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('red@gmail.com', 'hugh', 'hugh needs love!', 'hugh is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('red@gmail.com', 'missie', 'missie needs love!', 'missie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('juliane', 'juliane@gmail.com', 'A user of PCS', 'julianepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juliane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'juliane@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'juliane@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'juliane@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'juliane@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'juliane@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliane@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('juliane@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('reggi', 'reggi@gmail.com', 'A user of PCS', 'reggipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reggi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'reggi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'reggi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'reggi@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reggi@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('fanni', 'fanni@gmail.com', 'A user of PCS', 'fannipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fanni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'fanni@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'fanni@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fanni@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fanni@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fanni@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('raddie', 'raddie@gmail.com', 'A user of PCS', 'raddiepw');
INSERT INTO PetOwners(email) VALUES ('raddie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'koda', 'koda needs love!', 'koda is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'klaus', 'klaus needs love!', 'klaus is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('raddie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'raddie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('antonella', 'antonella@gmail.com', 'A user of PCS', 'antonellapw');
INSERT INTO PetOwners(email) VALUES ('antonella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'salem', 'salem needs love!', 'salem is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'jaxson', 'jaxson needs love!', 'jaxson is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('sandro', 'sandro@gmail.com', 'A user of PCS', 'sandropw');
INSERT INTO PetOwners(email) VALUES ('sandro@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sandro@gmail.com', 'sable', 'sable needs love!', 'sable is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sandro@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sandro@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sandro@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sandro@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sandro@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sandro@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('bil', 'bil@gmail.com', 'A user of PCS', 'bilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (280, 'bil@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'bil@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bil@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bil@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('kalindi', 'kalindi@gmail.com', 'A user of PCS', 'kalindipw');
INSERT INTO PetOwners(email) VALUES ('kalindi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalindi@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalindi@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalindi@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalindi@gmail.com', 'marble', 'marble needs love!', 'marble is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('coraline', 'coraline@gmail.com', 'A user of PCS', 'coralinepw');
INSERT INTO PetOwners(email) VALUES ('coraline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coraline@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coraline@gmail.com', 'flint', 'flint needs love!', 'flint is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coraline@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coraline@gmail.com', 'giant', 'giant needs love!', 'giant is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coraline@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('sigrid', 'sigrid@gmail.com', 'A user of PCS', 'sigridpw');
INSERT INTO PetOwners(email) VALUES ('sigrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'genie', 'genie needs love!', 'genie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'india', 'india needs love!', 'india is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'jazz', 'jazz needs love!', 'jazz is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('becky', 'becky@gmail.com', 'A user of PCS', 'beckypw');
INSERT INTO PetOwners(email) VALUES ('becky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'rico', 'rico needs love!', 'rico is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'dash', 'dash needs love!', 'dash is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'jelly', 'jelly needs love!', 'jelly is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('becky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'becky@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('murry', 'murry@gmail.com', 'A user of PCS', 'murrypw');
INSERT INTO PetOwners(email) VALUES ('murry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('murry@gmail.com', 'buddie', 'buddie needs love!', 'buddie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('murry@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('karrie', 'karrie@gmail.com', 'A user of PCS', 'karriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karrie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'karrie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'karrie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'karrie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'karrie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'karrie@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karrie@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karrie@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('blisse', 'blisse@gmail.com', 'A user of PCS', 'blissepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('blisse@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'blisse@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'blisse@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'blisse@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('blisse@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('blisse@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('erv', 'erv@gmail.com', 'A user of PCS', 'ervpw');
INSERT INTO PetOwners(email) VALUES ('erv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'cyrus', 'cyrus needs love!', 'cyrus is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'simba', 'simba needs love!', 'simba is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('beauregard', 'beauregard@gmail.com', 'A user of PCS', 'beauregardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beauregard@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'beauregard@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'beauregard@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (243, 'beauregard@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'beauregard@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'beauregard@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beauregard@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beauregard@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('catrina', 'catrina@gmail.com', 'A user of PCS', 'catrinapw');
INSERT INTO PetOwners(email) VALUES ('catrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catrina@gmail.com', 'adam', 'adam needs love!', 'adam is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catrina@gmail.com', 'freedom', 'freedom needs love!', 'freedom is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catrina@gmail.com', 'cindy', 'cindy needs love!', 'cindy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catrina@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('kipper', 'kipper@gmail.com', 'A user of PCS', 'kipperpw');
INSERT INTO PetOwners(email) VALUES ('kipper@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kipper@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('kalvin', 'kalvin@gmail.com', 'A user of PCS', 'kalvinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalvin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kalvin@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kalvin@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kalvin@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalvin@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('rick', 'rick@gmail.com', 'A user of PCS', 'rickpw');
INSERT INTO PetOwners(email) VALUES ('rick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'friday', 'friday needs love!', 'friday is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'skittles', 'skittles needs love!', 'skittles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'sebastian', 'sebastian needs love!', 'sebastian is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rick@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rick@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('alyosha', 'alyosha@gmail.com', 'A user of PCS', 'alyoshapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alyosha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'alyosha@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alyosha@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'alyosha@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('lock', 'lock@gmail.com', 'A user of PCS', 'lockpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lock@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lock@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lock@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('sherri', 'sherri@gmail.com', 'A user of PCS', 'sherripw');
INSERT INTO PetOwners(email) VALUES ('sherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'justice', 'justice needs love!', 'justice is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jazmin', 'jazmin@gmail.com', 'A user of PCS', 'jazminpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jazmin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jazmin@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jazmin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jazmin@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jazmin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jazmin@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jazmin@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('marguerite', 'marguerite@gmail.com', 'A user of PCS', 'margueritepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marguerite@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'marguerite@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marguerite@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'marguerite@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marguerite@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marguerite@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marguerite@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marguerite@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('tally', 'tally@gmail.com', 'A user of PCS', 'tallypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tally@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tally@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('sunny', 'sunny@gmail.com', 'A user of PCS', 'sunnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sunny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sunny@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sunny@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sunny@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('cello', 'cello@gmail.com', 'A user of PCS', 'cellopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cello@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'cello@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'cello@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'cello@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'cello@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('shelden', 'shelden@gmail.com', 'A user of PCS', 'sheldenpw');
INSERT INTO PetOwners(email) VALUES ('shelden@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelden@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shelden@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelden@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'shelden@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'shelden@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('eddi', 'eddi@gmail.com', 'A user of PCS', 'eddipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eddi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'eddi@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'eddi@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddi@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddi@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('joyan', 'joyan@gmail.com', 'A user of PCS', 'joyanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joyan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'joyan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'joyan@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'joyan@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'joyan@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joyan@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('toiboid', 'toiboid@gmail.com', 'A user of PCS', 'toiboidpw');
INSERT INTO PetOwners(email) VALUES ('toiboid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'humphrey', 'humphrey needs love!', 'humphrey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'oscar', 'oscar needs love!', 'oscar is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'holly', 'holly needs love!', 'holly is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('toiboid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'toiboid@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'toiboid@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'toiboid@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'toiboid@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'toiboid@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('toiboid@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kiersten', 'kiersten@gmail.com', 'A user of PCS', 'kierstenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kiersten@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kiersten@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kiersten@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kiersten@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kiersten@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kiersten@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kiersten@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lee', 'lee@gmail.com', 'A user of PCS', 'leepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'lee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'lee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'lee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'lee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'lee@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lee@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lee@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('ulises', 'ulises@gmail.com', 'A user of PCS', 'ulisespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulises@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'ulises@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'ulises@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'ulises@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulises@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulises@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('nari', 'nari@gmail.com', 'A user of PCS', 'naripw');
INSERT INTO PetOwners(email) VALUES ('nari@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nari@gmail.com', 'midnight', 'midnight needs love!', 'midnight is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nari@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nari@gmail.com', 'ruthie', 'ruthie needs love!', 'ruthie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('tedman', 'tedman@gmail.com', 'A user of PCS', 'tedmanpw');
INSERT INTO PetOwners(email) VALUES ('tedman@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'ollie', 'ollie needs love!', 'ollie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'kona', 'kona needs love!', 'kona is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('zea', 'zea@gmail.com', 'A user of PCS', 'zeapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'zea@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'zea@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zea@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('claudette', 'claudette@gmail.com', 'A user of PCS', 'claudettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'claudette@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'claudette@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'claudette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'claudette@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudette@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ranee', 'ranee@gmail.com', 'A user of PCS', 'raneepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ranee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'ranee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'ranee@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ranee@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ranee@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('stoddard', 'stoddard@gmail.com', 'A user of PCS', 'stoddardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stoddard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'stoddard@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stoddard@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('katti', 'katti@gmail.com', 'A user of PCS', 'kattipw');
INSERT INTO PetOwners(email) VALUES ('katti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'newton', 'newton needs love!', 'newton is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'persy', 'persy needs love!', 'persy is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('rory', 'rory@gmail.com', 'A user of PCS', 'rorypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rory@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'rory@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rory@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rory@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('chance', 'chance@gmail.com', 'A user of PCS', 'chancepw');
INSERT INTO PetOwners(email) VALUES ('chance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'george', 'george needs love!', 'george is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'mitzi', 'mitzi needs love!', 'mitzi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'leo', 'leo needs love!', 'leo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'kato', 'kato needs love!', 'kato is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('cristian', 'cristian@gmail.com', 'A user of PCS', 'cristianpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristian@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cristian@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cristian@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cristian@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('willetta', 'willetta@gmail.com', 'A user of PCS', 'willettapw');
INSERT INTO PetOwners(email) VALUES ('willetta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'joey', 'joey needs love!', 'joey is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'mojo', 'mojo needs love!', 'mojo is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('stephi', 'stephi@gmail.com', 'A user of PCS', 'stephipw');
INSERT INTO PetOwners(email) VALUES ('stephi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'jamie', 'jamie needs love!', 'jamie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'freckles', 'freckles needs love!', 'freckles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stephi@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('ginevra', 'ginevra@gmail.com', 'A user of PCS', 'ginevrapw');
INSERT INTO PetOwners(email) VALUES ('ginevra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'argus', 'argus needs love!', 'argus is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ginevra@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'ginevra@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginevra@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginevra@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('madelina', 'madelina@gmail.com', 'A user of PCS', 'madelinapw');
INSERT INTO PetOwners(email) VALUES ('madelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'bradley', 'bradley needs love!', 'bradley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'bodie', 'bodie needs love!', 'bodie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'indy', 'indy needs love!', 'indy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'bebe', 'bebe needs love!', 'bebe is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'skippy', 'skippy needs love!', 'skippy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madelina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'madelina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'madelina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'madelina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'madelina@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madelina@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kara', 'kara@gmail.com', 'A user of PCS', 'karapw');
INSERT INTO PetOwners(email) VALUES ('kara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara@gmail.com', 'kissy', 'kissy needs love!', 'kissy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara@gmail.com', 'sherman', 'sherman needs love!', 'sherman is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('wallie', 'wallie@gmail.com', 'A user of PCS', 'walliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wallie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'wallie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'wallie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'wallie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'wallie@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallie@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wallie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('pail', 'pail@gmail.com', 'A user of PCS', 'pailpw');
INSERT INTO PetOwners(email) VALUES ('pail@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'jenny', 'jenny needs love!', 'jenny is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'boris', 'boris needs love!', 'boris is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'patches', 'patches needs love!', 'patches is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'baron', 'baron needs love!', 'baron is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pail@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'pail@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pail@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pail@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('lianne', 'lianne@gmail.com', 'A user of PCS', 'liannepw');
INSERT INTO PetOwners(email) VALUES ('lianne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'francais', 'francais needs love!', 'francais is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'simba', 'simba needs love!', 'simba is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'judy', 'judy needs love!', 'judy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'meggie', 'meggie needs love!', 'meggie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lianne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lianne@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lianne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lianne@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lianne@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('sigfrid', 'sigfrid@gmail.com', 'A user of PCS', 'sigfridpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigfrid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'sigfrid@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'sigfrid@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'sigfrid@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigfrid@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigfrid@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('zach', 'zach@gmail.com', 'A user of PCS', 'zachpw');
INSERT INTO PetOwners(email) VALUES ('zach@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'maximus', 'maximus needs love!', 'maximus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'angel', 'angel needs love!', 'angel is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zach@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'zach@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zach@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('sara-ann', 'sara-ann@gmail.com', 'A user of PCS', 'sara-annpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sara-ann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sara-ann@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sara-ann@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sara-ann@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sara-ann@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('eugenio', 'eugenio@gmail.com', 'A user of PCS', 'eugeniopw');
INSERT INTO PetOwners(email) VALUES ('eugenio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'dylan', 'dylan needs love!', 'dylan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'peter', 'peter needs love!', 'peter is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugenio@gmail.com', 'bunky', 'bunky needs love!', 'bunky is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eugenio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'eugenio@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'eugenio@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'eugenio@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'eugenio@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'eugenio@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gavin', 'gavin@gmail.com', 'A user of PCS', 'gavinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gavin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'gavin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'gavin@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'gavin@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gavin@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gavin@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('olag', 'olag@gmail.com', 'A user of PCS', 'olagpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('olag@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'olag@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'olag@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'olag@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'olag@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'olag@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('olag@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('olag@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('marni', 'marni@gmail.com', 'A user of PCS', 'marnipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marni@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'marni@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marni@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marni@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('syman', 'syman@gmail.com', 'A user of PCS', 'symanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('syman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'syman@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('eugene', 'eugene@gmail.com', 'A user of PCS', 'eugenepw');
INSERT INTO PetOwners(email) VALUES ('eugene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eugene@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eugene@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'eugene@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'eugene@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'eugene@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'eugene@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eugene@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eugene@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('kania', 'kania@gmail.com', 'A user of PCS', 'kaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kania@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kania@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kania@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kania@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kania@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kania@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('hannah', 'hannah@gmail.com', 'A user of PCS', 'hannahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hannah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hannah@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hannah@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hannah@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hannah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hannah@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hannah@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gwennie', 'gwennie@gmail.com', 'A user of PCS', 'gwenniepw');
INSERT INTO PetOwners(email) VALUES ('gwennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'baron', 'baron needs love!', 'baron is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'jewel', 'jewel needs love!', 'jewel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'purdy', 'purdy needs love!', 'purdy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('garold', 'garold@gmail.com', 'A user of PCS', 'garoldpw');
INSERT INTO PetOwners(email) VALUES ('garold@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garold@gmail.com', 'pepper', 'pepper needs love!', 'pepper is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garold@gmail.com', 'dude', 'dude needs love!', 'dude is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garold@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'garold@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'garold@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'garold@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garold@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('pepi', 'pepi@gmail.com', 'A user of PCS', 'pepipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pepi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pepi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'pepi@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pepi@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('kippy', 'kippy@gmail.com', 'A user of PCS', 'kippypw');
INSERT INTO PetOwners(email) VALUES ('kippy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kippy@gmail.com', 'pete', 'pete needs love!', 'pete is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kippy@gmail.com', 'barley', 'barley needs love!', 'barley is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kippy@gmail.com', 'guido', 'guido needs love!', 'guido is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kippy@gmail.com', 'red', 'red needs love!', 'red is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kippy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kippy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kippy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kippy@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kanya', 'kanya@gmail.com', 'A user of PCS', 'kanyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kanya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kanya@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kanya@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('glen', 'glen@gmail.com', 'A user of PCS', 'glenpw');
INSERT INTO PetOwners(email) VALUES ('glen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'carley', 'carley needs love!', 'carley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'aj', 'aj needs love!', 'aj is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'glen@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glen@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('marketa', 'marketa@gmail.com', 'A user of PCS', 'marketapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marketa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'marketa@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('odey', 'odey@gmail.com', 'A user of PCS', 'odeypw');
INSERT INTO PetOwners(email) VALUES ('odey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'gus', 'gus needs love!', 'gus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'barker', 'barker needs love!', 'barker is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'joe', 'joe needs love!', 'joe is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'odey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'odey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'odey@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('odey@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('reynolds', 'reynolds@gmail.com', 'A user of PCS', 'reynoldspw');
INSERT INTO PetOwners(email) VALUES ('reynolds@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'charisma', 'charisma needs love!', 'charisma is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('brana', 'brana@gmail.com', 'A user of PCS', 'branapw');
INSERT INTO PetOwners(email) VALUES ('brana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'hank', 'hank needs love!', 'hank is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'mary jane', 'mary jane needs love!', 'mary jane is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'harvey', 'harvey needs love!', 'harvey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'bumper', 'bumper needs love!', 'bumper is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'brana@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('andee', 'andee@gmail.com', 'A user of PCS', 'andeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'andee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'andee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'andee@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andee@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andee@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('hansiain', 'hansiain@gmail.com', 'A user of PCS', 'hansiainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hansiain@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hansiain@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hansiain@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('wainwright', 'wainwright@gmail.com', 'A user of PCS', 'wainwrightpw');
INSERT INTO PetOwners(email) VALUES ('wainwright@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'kujo', 'kujo needs love!', 'kujo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wainwright@gmail.com', 'sampson', 'sampson needs love!', 'sampson is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('bone', 'bone@gmail.com', 'A user of PCS', 'bonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bone@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'bone@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'bone@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('goran', 'goran@gmail.com', 'A user of PCS', 'goranpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('goran@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'goran@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'goran@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'goran@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'goran@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('goran@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('goran@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('lonnie', 'lonnie@gmail.com', 'A user of PCS', 'lonniepw');
INSERT INTO PetOwners(email) VALUES ('lonnie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lonnie@gmail.com', 'babe', 'babe needs love!', 'babe is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lonnie@gmail.com', 'salem', 'salem needs love!', 'salem is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lonnie@gmail.com', 'goldie', 'goldie needs love!', 'goldie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lonnie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'lonnie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lonnie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lonnie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mylo', 'mylo@gmail.com', 'A user of PCS', 'mylopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mylo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mylo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mylo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mylo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'mylo@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mylo@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mylo@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('fairfax', 'fairfax@gmail.com', 'A user of PCS', 'fairfaxpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fairfax@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'fairfax@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'fairfax@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'fairfax@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'fairfax@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'fairfax@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fairfax@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fairfax@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('aggie', 'aggie@gmail.com', 'A user of PCS', 'aggiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aggie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (213, 'aggie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'aggie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'aggie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aggie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aggie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('marylinda', 'marylinda@gmail.com', 'A user of PCS', 'marylindapw');
INSERT INTO PetOwners(email) VALUES ('marylinda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'lady', 'lady needs love!', 'lady is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('leland', 'leland@gmail.com', 'A user of PCS', 'lelandpw');
INSERT INTO PetOwners(email) VALUES ('leland@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leland@gmail.com', 'slinky', 'slinky needs love!', 'slinky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leland@gmail.com', 'parker', 'parker needs love!', 'parker is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leland@gmail.com', 'oakley', 'oakley needs love!', 'oakley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leland@gmail.com', 'queen', 'queen needs love!', 'queen is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('willy', 'willy@gmail.com', 'A user of PCS', 'willypw');
INSERT INTO PetOwners(email) VALUES ('willy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'coal', 'coal needs love!', 'coal is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'skipper', 'skipper needs love!', 'skipper is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'samson', 'samson needs love!', 'samson is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willy@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('katherina', 'katherina@gmail.com', 'A user of PCS', 'katherinapw');
INSERT INTO PetOwners(email) VALUES ('katherina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katherina@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katherina@gmail.com', 'queenie', 'queenie needs love!', 'queenie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katherina@gmail.com', 'argus', 'argus needs love!', 'argus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katherina@gmail.com', 'billy', 'billy needs love!', 'billy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katherina@gmail.com', 'bambi', 'bambi needs love!', 'bambi is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('roseline', 'roseline@gmail.com', 'A user of PCS', 'roselinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roseline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'roseline@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'roseline@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'roseline@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'roseline@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roseline@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roseline@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('starlin', 'starlin@gmail.com', 'A user of PCS', 'starlinpw');
INSERT INTO PetOwners(email) VALUES ('starlin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'ben', 'ben needs love!', 'ben is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'mariah', 'mariah needs love!', 'mariah is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'april', 'april needs love!', 'april is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'bacchus', 'bacchus needs love!', 'bacchus is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('aland', 'aland@gmail.com', 'A user of PCS', 'alandpw');
INSERT INTO PetOwners(email) VALUES ('aland@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'howie', 'howie needs love!', 'howie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'shadow', 'shadow needs love!', 'shadow is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'aussie', 'aussie needs love!', 'aussie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'kurly', 'kurly needs love!', 'kurly is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'destini', 'destini needs love!', 'destini is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('norine', 'norine@gmail.com', 'A user of PCS', 'norinepw');
INSERT INTO PetOwners(email) VALUES ('norine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('norine@gmail.com', 'morgan', 'morgan needs love!', 'morgan is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('norine@gmail.com', 'moonshine', 'moonshine needs love!', 'moonshine is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('norine@gmail.com', 'armanti', 'armanti needs love!', 'armanti is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('lamar', 'lamar@gmail.com', 'A user of PCS', 'lamarpw');
INSERT INTO PetOwners(email) VALUES ('lamar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lamar@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('ilka', 'ilka@gmail.com', 'A user of PCS', 'ilkapw');
INSERT INTO PetOwners(email) VALUES ('ilka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'gavin', 'gavin needs love!', 'gavin is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'bj', 'bj needs love!', 'bj is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('eleanora', 'eleanora@gmail.com', 'A user of PCS', 'eleanorapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eleanora@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'eleanora@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'eleanora@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eleanora@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eleanora@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('jaine', 'jaine@gmail.com', 'A user of PCS', 'jainepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jaine@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('monro', 'monro@gmail.com', 'A user of PCS', 'monropw');
INSERT INTO PetOwners(email) VALUES ('monro@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('monro@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('monro@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'monro@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('monro@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('alano', 'alano@gmail.com', 'A user of PCS', 'alanopw');
INSERT INTO PetOwners(email) VALUES ('alano@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('robinia', 'robinia@gmail.com', 'A user of PCS', 'robiniapw');
INSERT INTO PetOwners(email) VALUES ('robinia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinia@gmail.com', 'cheyenne', 'cheyenne needs love!', 'cheyenne is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('wynn', 'wynn@gmail.com', 'A user of PCS', 'wynnpw');
INSERT INTO PetOwners(email) VALUES ('wynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynn@gmail.com', 'big foot', 'big foot needs love!', 'big foot is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynn@gmail.com', 'purdy', 'purdy needs love!', 'purdy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wynn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'wynn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wynn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wynn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'wynn@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'wynn@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wynn@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('adena', 'adena@gmail.com', 'A user of PCS', 'adenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'adena@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'adena@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'adena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'adena@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adena@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('lane', 'lane@gmail.com', 'A user of PCS', 'lanepw');
INSERT INTO PetOwners(email) VALUES ('lane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'darby', 'darby needs love!', 'darby is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lane@gmail.com', 'bruiser', 'bruiser needs love!', 'bruiser is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('deena', 'deena@gmail.com', 'A user of PCS', 'deenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'deena@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'deena@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deena@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deena@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('ola', 'ola@gmail.com', 'A user of PCS', 'olapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ola@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ola@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('janos', 'janos@gmail.com', 'A user of PCS', 'janospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janos@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'janos@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'janos@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janos@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janos@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('kinna', 'kinna@gmail.com', 'A user of PCS', 'kinnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kinna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kinna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kinna@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fallon', 'fallon@gmail.com', 'A user of PCS', 'fallonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fallon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fallon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'fallon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'fallon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fallon@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fallon@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('wain', 'wain@gmail.com', 'A user of PCS', 'wainpw');
INSERT INTO PetOwners(email) VALUES ('wain@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'hammer', 'hammer needs love!', 'hammer is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'nathan', 'nathan needs love!', 'nathan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'flash', 'flash needs love!', 'flash is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'george', 'george needs love!', 'george is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('alaster', 'alaster@gmail.com', 'A user of PCS', 'alasterpw');
INSERT INTO PetOwners(email) VALUES ('alaster@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'pooh', 'pooh needs love!', 'pooh is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'amber', 'amber needs love!', 'amber is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alaster@gmail.com', 'edgar', 'edgar needs love!', 'edgar is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alaster@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'alaster@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'alaster@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'alaster@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'alaster@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alaster@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alaster@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('ravi', 'ravi@gmail.com', 'A user of PCS', 'ravipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ravi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'ravi@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'ravi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'ravi@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ravi@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ravi@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('jessi', 'jessi@gmail.com', 'A user of PCS', 'jessipw');
INSERT INTO PetOwners(email) VALUES ('jessi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'bob', 'bob needs love!', 'bob is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'cody', 'cody needs love!', 'cody is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'peter', 'peter needs love!', 'peter is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jessi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jessi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jessi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jessi@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('saree', 'saree@gmail.com', 'A user of PCS', 'sareepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('saree@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'saree@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('filia', 'filia@gmail.com', 'A user of PCS', 'filiapw');
INSERT INTO PetOwners(email) VALUES ('filia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'athena', 'athena needs love!', 'athena is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'axel', 'axel needs love!', 'axel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filia@gmail.com', 'puck', 'puck needs love!', 'puck is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'filia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'filia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'filia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'filia@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('filia@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('patten', 'patten@gmail.com', 'A user of PCS', 'pattenpw');
INSERT INTO PetOwners(email) VALUES ('patten@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patten@gmail.com', 'obie', 'obie needs love!', 'obie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patten@gmail.com', 'chase', 'chase needs love!', 'chase is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patten@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patten@gmail.com', 'ozzy', 'ozzy needs love!', 'ozzy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patten@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'patten@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tyler', 'tyler@gmail.com', 'A user of PCS', 'tylerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tyler@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'tyler@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyler@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tyler@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('wallis', 'wallis@gmail.com', 'A user of PCS', 'wallispw');
INSERT INTO PetOwners(email) VALUES ('wallis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallis@gmail.com', 'sky', 'sky needs love!', 'sky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallis@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('muriel', 'muriel@gmail.com', 'A user of PCS', 'murielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('muriel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (243, 'muriel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'muriel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'muriel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'muriel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'muriel@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('muriel@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('muriel@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('taddeo', 'taddeo@gmail.com', 'A user of PCS', 'taddeopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('taddeo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'taddeo@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'taddeo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'taddeo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'taddeo@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'taddeo@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('cathlene', 'cathlene@gmail.com', 'A user of PCS', 'cathlenepw');
INSERT INTO PetOwners(email) VALUES ('cathlene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'dewey', 'dewey needs love!', 'dewey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'lazarus', 'lazarus needs love!', 'lazarus is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'nemo', 'nemo needs love!', 'nemo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathlene@gmail.com', 'abby', 'abby needs love!', 'abby is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('palmer', 'palmer@gmail.com', 'A user of PCS', 'palmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('palmer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'palmer@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('palmer@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('palmer@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('miof mela', 'miof mela@gmail.com', 'A user of PCS', 'miof melapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('miof mela@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'miof mela@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'miof mela@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'miof mela@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miof mela@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tresa', 'tresa@gmail.com', 'A user of PCS', 'tresapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tresa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tresa@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tresa@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tresa@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('aldridge', 'aldridge@gmail.com', 'A user of PCS', 'aldridgepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aldridge@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (253, 'aldridge@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'aldridge@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'aldridge@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'aldridge@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'aldridge@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aldridge@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aldridge@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('madison', 'madison@gmail.com', 'A user of PCS', 'madisonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madison@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'madison@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'madison@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('tine', 'tine@gmail.com', 'A user of PCS', 'tinepw');
INSERT INTO PetOwners(email) VALUES ('tine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tine@gmail.com', 'dante', 'dante needs love!', 'dante is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tine@gmail.com', 'ben', 'ben needs love!', 'ben is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('fawn', 'fawn@gmail.com', 'A user of PCS', 'fawnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fawn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fawn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'fawn@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fawn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'fawn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'fawn@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fawn@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('rona', 'rona@gmail.com', 'A user of PCS', 'ronapw');
INSERT INTO PetOwners(email) VALUES ('rona@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rona@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rona@gmail.com', 'puffy', 'puffy needs love!', 'puffy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rona@gmail.com', 'maximus', 'maximus needs love!', 'maximus is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('hasheem', 'hasheem@gmail.com', 'A user of PCS', 'hasheempw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hasheem@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'hasheem@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'hasheem@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'hasheem@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hasheem@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hasheem@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('beck', 'beck@gmail.com', 'A user of PCS', 'beckpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beck@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'beck@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'beck@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'beck@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'beck@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'beck@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beck@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('cordell', 'cordell@gmail.com', 'A user of PCS', 'cordellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cordell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cordell@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cordell@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cordell@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cordell@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cordell@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cordell@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('dalston', 'dalston@gmail.com', 'A user of PCS', 'dalstonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dalston@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dalston@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dalston@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dalston@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dalston@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ginni', 'ginni@gmail.com', 'A user of PCS', 'ginnipw');
INSERT INTO PetOwners(email) VALUES ('ginni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginni@gmail.com', 'beauty', 'beauty needs love!', 'beauty is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ginni@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'ginni@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginni@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginni@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('riobard', 'riobard@gmail.com', 'A user of PCS', 'riobardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('riobard@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'riobard@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (222, 'riobard@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'riobard@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'riobard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'riobard@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('riobard@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('riobard@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('misty', 'misty@gmail.com', 'A user of PCS', 'mistypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('misty@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'misty@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('robenia', 'robenia@gmail.com', 'A user of PCS', 'robeniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('robenia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'robenia@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robenia@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robenia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('catarina', 'catarina@gmail.com', 'A user of PCS', 'catarinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('catarina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (183, 'catarina@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('catarina@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('catarina@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('rik', 'rik@gmail.com', 'A user of PCS', 'rikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rik@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rik@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'rik@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (225, 'rik@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rik@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rik@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('rafi', 'rafi@gmail.com', 'A user of PCS', 'rafipw');
INSERT INTO PetOwners(email) VALUES ('rafi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafi@gmail.com', 'nathan', 'nathan needs love!', 'nathan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafi@gmail.com', 'beans', 'beans needs love!', 'beans is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafi@gmail.com', 'moochie', 'moochie needs love!', 'moochie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('alverta', 'alverta@gmail.com', 'A user of PCS', 'alvertapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alverta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'alverta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'alverta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'alverta@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'alverta@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alverta@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alverta@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('jewel', 'jewel@gmail.com', 'A user of PCS', 'jewelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jewel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jewel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jewel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jewel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jewel@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jewel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('albina', 'albina@gmail.com', 'A user of PCS', 'albinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('albina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'albina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'albina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'albina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'albina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'albina@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('albina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('pincus', 'pincus@gmail.com', 'A user of PCS', 'pincuspw');
INSERT INTO PetOwners(email) VALUES ('pincus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pincus@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pincus@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pincus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'pincus@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pincus@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('steffi', 'steffi@gmail.com', 'A user of PCS', 'steffipw');
INSERT INTO PetOwners(email) VALUES ('steffi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('steffi@gmail.com', 'mischief', 'mischief needs love!', 'mischief is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steffi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'steffi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'steffi@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'steffi@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'steffi@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steffi@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('johann', 'johann@gmail.com', 'A user of PCS', 'johannpw');
INSERT INTO PetOwners(email) VALUES ('johann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('mariejeanne', 'mariejeanne@gmail.com', 'A user of PCS', 'mariejeannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariejeanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'mariejeanne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'mariejeanne@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mariejeanne@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mariejeanne@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('sammy', 'sammy@gmail.com', 'A user of PCS', 'sammypw');
INSERT INTO PetOwners(email) VALUES ('sammy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'megan', 'megan needs love!', 'megan is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'alf', 'alf needs love!', 'alf is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'crackers', 'crackers needs love!', 'crackers is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'simba', 'simba needs love!', 'simba is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sammy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sammy@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sammy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('trudey', 'trudey@gmail.com', 'A user of PCS', 'trudeypw');
INSERT INTO PetOwners(email) VALUES ('trudey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'raison', 'raison needs love!', 'raison is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'bullet', 'bullet needs love!', 'bullet is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('denise', 'denise@gmail.com', 'A user of PCS', 'denisepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denise@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'denise@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'denise@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'denise@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'denise@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('denise@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('denise@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('ingeborg', 'ingeborg@gmail.com', 'A user of PCS', 'ingeborgpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ingeborg@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ingeborg@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ingeborg@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dona', 'dona@gmail.com', 'A user of PCS', 'donapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dona@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dona@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dona@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dona@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dona@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('roosevelt', 'roosevelt@gmail.com', 'A user of PCS', 'rooseveltpw');
INSERT INTO PetOwners(email) VALUES ('roosevelt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'otis', 'otis needs love!', 'otis is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'hank', 'hank needs love!', 'hank is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'max', 'max needs love!', 'max is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'babbles', 'babbles needs love!', 'babbles is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('somerset', 'somerset@gmail.com', 'A user of PCS', 'somersetpw');
INSERT INTO PetOwners(email) VALUES ('somerset@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'dinky', 'dinky needs love!', 'dinky is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('trudie', 'trudie@gmail.com', 'A user of PCS', 'trudiepw');
INSERT INTO PetOwners(email) VALUES ('trudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'simone', 'simone needs love!', 'simone is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'jasmine', 'jasmine needs love!', 'jasmine is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trudie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'trudie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'trudie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'trudie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trudie@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trudie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('esma', 'esma@gmail.com', 'A user of PCS', 'esmapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'esma@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'esma@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'esma@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'esma@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'esma@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('godfrey', 'godfrey@gmail.com', 'A user of PCS', 'godfreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('godfrey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'godfrey@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('godfrey@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('godfrey@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('dinny', 'dinny@gmail.com', 'A user of PCS', 'dinnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dinny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'dinny@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'dinny@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'dinny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'dinny@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dinny@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dinny@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('mollie', 'mollie@gmail.com', 'A user of PCS', 'molliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mollie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'mollie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'mollie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mollie@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mollie@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('porty', 'porty@gmail.com', 'A user of PCS', 'portypw');
INSERT INTO PetOwners(email) VALUES ('porty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'sissy', 'sissy needs love!', 'sissy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'cricket', 'cricket needs love!', 'cricket is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'maggie', 'maggie needs love!', 'maggie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'abbey', 'abbey needs love!', 'abbey is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('porty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'porty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'porty@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'porty@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'porty@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'porty@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('porty@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('porty@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('hurley', 'hurley@gmail.com', 'A user of PCS', 'hurleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hurley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hurley@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hurley@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hurley@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('grace', 'grace@gmail.com', 'A user of PCS', 'gracepw');
INSERT INTO PetOwners(email) VALUES ('grace@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'katz', 'katz needs love!', 'katz is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('grace@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('grace@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'grace@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'grace@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'grace@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'grace@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'grace@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('grace@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('grace@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('nonah', 'nonah@gmail.com', 'A user of PCS', 'nonahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nonah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (183, 'nonah@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nonah@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nonah@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('tamqrah', 'tamqrah@gmail.com', 'A user of PCS', 'tamqrahpw');
INSERT INTO PetOwners(email) VALUES ('tamqrah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'dreamer', 'dreamer needs love!', 'dreamer is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'hugh', 'hugh needs love!', 'hugh is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tamqrah@gmail.com', 'buster', 'buster needs love!', 'buster is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('selig', 'selig@gmail.com', 'A user of PCS', 'seligpw');
INSERT INTO PetOwners(email) VALUES ('selig@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'puffy', 'puffy needs love!', 'puffy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'hobbes', 'hobbes needs love!', 'hobbes is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('selig@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'selig@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'selig@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'selig@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'selig@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'selig@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selig@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('willette', 'willette@gmail.com', 'A user of PCS', 'willettepw');
INSERT INTO PetOwners(email) VALUES ('willette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willette@gmail.com', 'itsy-bitsy', 'itsy-bitsy needs love!', 'itsy-bitsy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'willette@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willette@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willette@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('dill', 'dill@gmail.com', 'A user of PCS', 'dillpw');
INSERT INTO PetOwners(email) VALUES ('dill@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'bo', 'bo needs love!', 'bo is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dill@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'dill@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (210, 'dill@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'dill@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dill@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dill@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('antin', 'antin@gmail.com', 'A user of PCS', 'antinpw');
INSERT INTO PetOwners(email) VALUES ('antin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antin@gmail.com', 'fluffy', 'fluffy needs love!', 'fluffy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antin@gmail.com', 'louie', 'louie needs love!', 'louie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('mollee', 'mollee@gmail.com', 'A user of PCS', 'molleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mollee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'mollee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mollee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mollee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mollee@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('garvy', 'garvy@gmail.com', 'A user of PCS', 'garvypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garvy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'garvy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'garvy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'garvy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'garvy@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garvy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('darnall', 'darnall@gmail.com', 'A user of PCS', 'darnallpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darnall@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'darnall@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'darnall@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'darnall@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('foss', 'foss@gmail.com', 'A user of PCS', 'fosspw');
INSERT INTO PetOwners(email) VALUES ('foss@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('foss@gmail.com', 'cha cha', 'cha cha needs love!', 'cha cha is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('robinet', 'robinet@gmail.com', 'A user of PCS', 'robinetpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('robinet@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'robinet@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'robinet@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'robinet@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'robinet@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'robinet@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('robinet@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('marie-ann', 'marie-ann@gmail.com', 'A user of PCS', 'marie-annpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marie-ann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marie-ann@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marie-ann@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marie-ann@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('minne', 'minne@gmail.com', 'A user of PCS', 'minnepw');
INSERT INTO PetOwners(email) VALUES ('minne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minne@gmail.com', 'lucy', 'lucy needs love!', 'lucy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minne@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minne@gmail.com', 'dolly', 'dolly needs love!', 'dolly is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minne@gmail.com', 'bradley', 'bradley needs love!', 'bradley is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('claudina', 'claudina@gmail.com', 'A user of PCS', 'claudinapw');
INSERT INTO PetOwners(email) VALUES ('claudina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudina@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudina@gmail.com', 'ming', 'ming needs love!', 'ming is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('erin', 'erin@gmail.com', 'A user of PCS', 'erinpw');
INSERT INTO PetOwners(email) VALUES ('erin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erin@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('tyson', 'tyson@gmail.com', 'A user of PCS', 'tysonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tyson@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tyson@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tyson@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tyson@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tyson@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyson@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('elwin', 'elwin@gmail.com', 'A user of PCS', 'elwinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elwin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'elwin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'elwin@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'elwin@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'elwin@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwin@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwin@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('hyacinth', 'hyacinth@gmail.com', 'A user of PCS', 'hyacinthpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hyacinth@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'hyacinth@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'hyacinth@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'hyacinth@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hyacinth@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hyacinth@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('urbain', 'urbain@gmail.com', 'A user of PCS', 'urbainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('urbain@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'urbain@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'urbain@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('urbain@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('denis', 'denis@gmail.com', 'A user of PCS', 'denispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'denis@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('merv', 'merv@gmail.com', 'A user of PCS', 'mervpw');
INSERT INTO PetOwners(email) VALUES ('merv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'allie', 'allie needs love!', 'allie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'homer', 'homer needs love!', 'homer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'karma', 'karma needs love!', 'karma is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('dorie', 'dorie@gmail.com', 'A user of PCS', 'doriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dorie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dorie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dorie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dorie@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jessica', 'jessica@gmail.com', 'A user of PCS', 'jessicapw');
INSERT INTO PetOwners(email) VALUES ('jessica@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessica@gmail.com', 'schultz', 'schultz needs love!', 'schultz is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessica@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessica@gmail.com', 'sassy', 'sassy needs love!', 'sassy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('alexandros', 'alexandros@gmail.com', 'A user of PCS', 'alexandrospw');
INSERT INTO PetOwners(email) VALUES ('alexandros@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alexandros@gmail.com', 'jewels', 'jewels needs love!', 'jewels is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alexandros@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alexandros@gmail.com', 'macy', 'macy needs love!', 'macy is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('coleman', 'coleman@gmail.com', 'A user of PCS', 'colemanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('coleman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'coleman@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'coleman@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'coleman@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'coleman@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coleman@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('coleman@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('orsola', 'orsola@gmail.com', 'A user of PCS', 'orsolapw');
INSERT INTO PetOwners(email) VALUES ('orsola@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'louis', 'louis needs love!', 'louis is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'butch', 'butch needs love!', 'butch is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'rock', 'rock needs love!', 'rock is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('orsola@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'orsola@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'orsola@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'orsola@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'orsola@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orsola@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('carmelina', 'carmelina@gmail.com', 'A user of PCS', 'carmelinapw');
INSERT INTO PetOwners(email) VALUES ('carmelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'milo', 'milo needs love!', 'milo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'montgomery', 'montgomery needs love!', 'montgomery is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carmelina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'carmelina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'carmelina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'carmelina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'carmelina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'carmelina@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carmelina@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carmelina@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('demott', 'demott@gmail.com', 'A user of PCS', 'demottpw');
INSERT INTO PetOwners(email) VALUES ('demott@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'cody', 'cody needs love!', 'cody is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'butch', 'butch needs love!', 'butch is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('lannie', 'lannie@gmail.com', 'A user of PCS', 'lanniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lannie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'lannie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'lannie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lannie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lannie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('fidole', 'fidole@gmail.com', 'A user of PCS', 'fidolepw');
INSERT INTO PetOwners(email) VALUES ('fidole@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'grace', 'grace needs love!', 'grace is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'mercle', 'mercle needs love!', 'mercle is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'nestle', 'nestle needs love!', 'nestle is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'butter', 'butter needs love!', 'butter is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fidole@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fidole@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'fidole@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fidole@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('carolan', 'carolan@gmail.com', 'A user of PCS', 'carolanpw');
INSERT INTO PetOwners(email) VALUES ('carolan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'alexus', 'alexus needs love!', 'alexus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'mary jane', 'mary jane needs love!', 'mary jane is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'birdie', 'birdie needs love!', 'birdie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'jenna', 'jenna needs love!', 'jenna is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('gennifer', 'gennifer@gmail.com', 'A user of PCS', 'genniferpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gennifer@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gennifer@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gennifer@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gennifer@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gennifer@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gennifer@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gennifer@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gabby', 'gabby@gmail.com', 'A user of PCS', 'gabbypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gabby@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gabby@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gabby@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gabby@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gabby@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gabby@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('liva', 'liva@gmail.com', 'A user of PCS', 'livapw');
INSERT INTO PetOwners(email) VALUES ('liva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('liva@gmail.com', 'digger', 'digger needs love!', 'digger is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('liva@gmail.com', 'porkchop', 'porkchop needs love!', 'porkchop is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('liva@gmail.com', 'freckles', 'freckles needs love!', 'freckles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('liva@gmail.com', 'bud', 'bud needs love!', 'bud is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('liva@gmail.com', 'polly', 'polly needs love!', 'polly is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('liva@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'liva@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'liva@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'liva@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'liva@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'liva@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('liva@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('liva@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('pia', 'pia@gmail.com', 'A user of PCS', 'piapw');
INSERT INTO PetOwners(email) VALUES ('pia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pia@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pia@gmail.com', 'kissy', 'kissy needs love!', 'kissy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pia@gmail.com', 'sarge', 'sarge needs love!', 'sarge is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('ramon', 'ramon@gmail.com', 'A user of PCS', 'ramonpw');
INSERT INTO PetOwners(email) VALUES ('ramon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'patty', 'patty needs love!', 'patty is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ramon@gmail.com', 'joker', 'joker needs love!', 'joker is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('marcelo', 'marcelo@gmail.com', 'A user of PCS', 'marcelopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcelo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'marcelo@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'marcelo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'marcelo@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marcelo@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcelo@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcelo@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('florina', 'florina@gmail.com', 'A user of PCS', 'florinapw');
INSERT INTO PetOwners(email) VALUES ('florina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florina@gmail.com', 'dickens', 'dickens needs love!', 'dickens is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florina@gmail.com', 'joy', 'joy needs love!', 'joy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florina@gmail.com', 'chips', 'chips needs love!', 'chips is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('florina@gmail.com', 'lili', 'lili needs love!', 'lili is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('dacy', 'dacy@gmail.com', 'A user of PCS', 'dacypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dacy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dacy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dacy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dacy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dacy@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dacy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kameko', 'kameko@gmail.com', 'A user of PCS', 'kamekopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kameko@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kameko@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kameko@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kameko@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kameko@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kameko@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kameko@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('laurice', 'laurice@gmail.com', 'A user of PCS', 'lauricepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laurice@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'laurice@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laurice@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laurice@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('dannie', 'dannie@gmail.com', 'A user of PCS', 'danniepw');
INSERT INTO PetOwners(email) VALUES ('dannie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dannie@gmail.com', 'sailor', 'sailor needs love!', 'sailor is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dannie@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('claudetta', 'claudetta@gmail.com', 'A user of PCS', 'claudettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'claudetta@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudetta@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudetta@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('marina', 'marina@gmail.com', 'A user of PCS', 'marinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marina@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('loy', 'loy@gmail.com', 'A user of PCS', 'loypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('loy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'loy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'loy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'loy@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('francesca', 'francesca@gmail.com', 'A user of PCS', 'francescapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francesca@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'francesca@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'francesca@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'francesca@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'francesca@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'francesca@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ellary', 'ellary@gmail.com', 'A user of PCS', 'ellarypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ellary@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ellary@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ellary@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ellary@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ellary@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('megen', 'megen@gmail.com', 'A user of PCS', 'megenpw');
INSERT INTO PetOwners(email) VALUES ('megen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('megen@gmail.com', 'paco', 'paco needs love!', 'paco is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('megen@gmail.com', 'humphrey', 'humphrey needs love!', 'humphrey is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('megen@gmail.com', 'nemo', 'nemo needs love!', 'nemo is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('megen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'megen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'megen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'megen@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'megen@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('elie', 'elie@gmail.com', 'A user of PCS', 'eliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'elie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'elie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('web', 'web@gmail.com', 'A user of PCS', 'webpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('web@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'web@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'web@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'web@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'web@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'web@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('web@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('nita', 'nita@gmail.com', 'A user of PCS', 'nitapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'nita@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'nita@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'nita@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'nita@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'nita@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nita@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nita@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('sybila', 'sybila@gmail.com', 'A user of PCS', 'sybilapw');
INSERT INTO PetOwners(email) VALUES ('sybila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sybila@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sybila@gmail.com', 'shady', 'shady needs love!', 'shady is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sybila@gmail.com', 'piggy', 'piggy needs love!', 'piggy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sybila@gmail.com', 'guinness', 'guinness needs love!', 'guinness is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('mitch', 'mitch@gmail.com', 'A user of PCS', 'mitchpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitch@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mitch@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('ed', 'ed@gmail.com', 'A user of PCS', 'edpw');
INSERT INTO PetOwners(email) VALUES ('ed@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ed@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('carleton', 'carleton@gmail.com', 'A user of PCS', 'carletonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carleton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (275, 'carleton@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'carleton@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'carleton@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'carleton@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'carleton@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carleton@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carleton@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shay', 'shay@gmail.com', 'A user of PCS', 'shaypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shay@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (229, 'shay@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shay@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shay@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('camella', 'camella@gmail.com', 'A user of PCS', 'camellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'camella@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'camella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'camella@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'camella@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camella@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camella@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('pepito', 'pepito@gmail.com', 'A user of PCS', 'pepitopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pepito@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'pepito@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'pepito@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'pepito@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'pepito@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'pepito@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pepito@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pepito@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('constance', 'constance@gmail.com', 'A user of PCS', 'constancepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('constance@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'constance@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'constance@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'constance@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'constance@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constance@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jandy', 'jandy@gmail.com', 'A user of PCS', 'jandypw');
INSERT INTO PetOwners(email) VALUES ('jandy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jandy@gmail.com', 'chevy', 'chevy needs love!', 'chevy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jandy@gmail.com', 'scooter', 'scooter needs love!', 'scooter is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jandy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'jandy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'jandy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'jandy@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jandy@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jandy@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('charlotte', 'charlotte@gmail.com', 'A user of PCS', 'charlottepw');
INSERT INTO PetOwners(email) VALUES ('charlotte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'luna', 'luna needs love!', 'luna is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('hobie', 'hobie@gmail.com', 'A user of PCS', 'hobiepw');
INSERT INTO PetOwners(email) VALUES ('hobie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'nosey', 'nosey needs love!', 'nosey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'goldie', 'goldie needs love!', 'goldie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'johnny', 'johnny needs love!', 'johnny is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('lucho', 'lucho@gmail.com', 'A user of PCS', 'luchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lucho@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lucho@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucho@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('emmy', 'emmy@gmail.com', 'A user of PCS', 'emmypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emmy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'emmy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'emmy@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emmy@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('malissia', 'malissia@gmail.com', 'A user of PCS', 'malissiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('malissia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'malissia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'malissia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'malissia@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('malissia@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('malissia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('milicent', 'milicent@gmail.com', 'A user of PCS', 'milicentpw');
INSERT INTO PetOwners(email) VALUES ('milicent@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milicent@gmail.com', 'henry', 'henry needs love!', 'henry is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milicent@gmail.com', 'sasha', 'sasha needs love!', 'sasha is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milicent@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'milicent@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'milicent@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milicent@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('milicent@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosamund', 'rosamund@gmail.com', 'A user of PCS', 'rosamundpw');
INSERT INTO PetOwners(email) VALUES ('rosamund@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'misty', 'misty needs love!', 'misty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'rags', 'rags needs love!', 'rags is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'miller', 'miller needs love!', 'miller is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamund@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('nerita', 'nerita@gmail.com', 'A user of PCS', 'neritapw');
INSERT INTO PetOwners(email) VALUES ('nerita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerita@gmail.com', 'chyna', 'chyna needs love!', 'chyna is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nerita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'nerita@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerita@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerita@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('ringo', 'ringo@gmail.com', 'A user of PCS', 'ringopw');
INSERT INTO PetOwners(email) VALUES ('ringo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'benji', 'benji needs love!', 'benji is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'hunter', 'hunter needs love!', 'hunter is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'bozley', 'bozley needs love!', 'bozley is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'beetle', 'beetle needs love!', 'beetle is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ringo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ringo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'ringo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (262, 'ringo@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'ringo@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'ringo@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ringo@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ringo@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('tonnie', 'tonnie@gmail.com', 'A user of PCS', 'tonniepw');
INSERT INTO PetOwners(email) VALUES ('tonnie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'macintosh', 'macintosh needs love!', 'macintosh is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'freddy', 'freddy needs love!', 'freddy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tonnie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'tonnie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tonnie@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tonnie@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('isiahi', 'isiahi@gmail.com', 'A user of PCS', 'isiahipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isiahi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'isiahi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'isiahi@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isiahi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hazlett', 'hazlett@gmail.com', 'A user of PCS', 'hazlettpw');
INSERT INTO PetOwners(email) VALUES ('hazlett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'newton', 'newton needs love!', 'newton is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'pokey', 'pokey needs love!', 'pokey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hazlett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'hazlett@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'hazlett@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'hazlett@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'hazlett@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'hazlett@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hazlett@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hazlett@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('leesa', 'leesa@gmail.com', 'A user of PCS', 'leesapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leesa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'leesa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (186, 'leesa@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leesa@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leesa@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('roseanna', 'roseanna@gmail.com', 'A user of PCS', 'roseannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roseanna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'roseanna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'roseanna@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jermaine', 'jermaine@gmail.com', 'A user of PCS', 'jermainepw');
INSERT INTO PetOwners(email) VALUES ('jermaine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('james', 'james@gmail.com', 'A user of PCS', 'jamespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('james@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'james@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('james@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('arlena', 'arlena@gmail.com', 'A user of PCS', 'arlenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arlena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'arlena@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'arlena@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arlena@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('nichole', 'nichole@gmail.com', 'A user of PCS', 'nicholepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nichole@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nichole@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'nichole@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'nichole@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('charyl', 'charyl@gmail.com', 'A user of PCS', 'charylpw');
INSERT INTO PetOwners(email) VALUES ('charyl@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charyl@gmail.com', 'luna', 'luna needs love!', 'luna is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charyl@gmail.com', 'diva', 'diva needs love!', 'diva is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charyl@gmail.com', 'brutus', 'brutus needs love!', 'brutus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charyl@gmail.com', 'honey', 'honey needs love!', 'honey is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charyl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'charyl@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charyl@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charyl@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('nick', 'nick@gmail.com', 'A user of PCS', 'nickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'nick@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nick@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nick@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('garik', 'garik@gmail.com', 'A user of PCS', 'garikpw');
INSERT INTO PetOwners(email) VALUES ('garik@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'petey', 'petey needs love!', 'petey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'figaro', 'figaro needs love!', 'figaro is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'aires', 'aires needs love!', 'aires is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garik@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'garik@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'garik@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garik@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garik@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('hatty', 'hatty@gmail.com', 'A user of PCS', 'hattypw');
INSERT INTO PetOwners(email) VALUES ('hatty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hatty@gmail.com', 'gibson', 'gibson needs love!', 'gibson is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hatty@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hatty@gmail.com', 'flakey', 'flakey needs love!', 'flakey is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('kennett', 'kennett@gmail.com', 'A user of PCS', 'kennettpw');
INSERT INTO PetOwners(email) VALUES ('kennett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennett@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennett@gmail.com', 'boy', 'boy needs love!', 'boy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennett@gmail.com', 'hardy', 'hardy needs love!', 'hardy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('starla', 'starla@gmail.com', 'A user of PCS', 'starlapw');
INSERT INTO PetOwners(email) VALUES ('starla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'simba', 'simba needs love!', 'simba is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'macy', 'macy needs love!', 'macy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'rosie', 'rosie needs love!', 'rosie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'grace', 'grace needs love!', 'grace is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('karlik', 'karlik@gmail.com', 'A user of PCS', 'karlikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlik@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'karlik@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'karlik@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'karlik@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'karlik@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'karlik@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karlik@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karlik@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('binny', 'binny@gmail.com', 'A user of PCS', 'binnypw');
INSERT INTO PetOwners(email) VALUES ('binny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'queen', 'queen needs love!', 'queen is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'francais', 'francais needs love!', 'francais is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'giant', 'giant needs love!', 'giant is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('binny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'binny@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'binny@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'binny@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('binny@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('binny@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('humbert', 'humbert@gmail.com', 'A user of PCS', 'humbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humbert@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'humbert@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'humbert@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'humbert@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('salomone', 'salomone@gmail.com', 'A user of PCS', 'salomonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('salomone@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'salomone@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'salomone@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('salomone@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcia', 'marcia@gmail.com', 'A user of PCS', 'marciapw');
INSERT INTO PetOwners(email) VALUES ('marcia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcia@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'marcia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'marcia@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcia@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('gav', 'gav@gmail.com', 'A user of PCS', 'gavpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gav@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'gav@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gav@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gav@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('annabal', 'annabal@gmail.com', 'A user of PCS', 'annabalpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annabal@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'annabal@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annabal@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('elnar', 'elnar@gmail.com', 'A user of PCS', 'elnarpw');
INSERT INTO PetOwners(email) VALUES ('elnar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elnar@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elnar@gmail.com', 'sandy', 'sandy needs love!', 'sandy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elnar@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elnar@gmail.com', 'koty', 'koty needs love!', 'koty is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elnar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'elnar@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'elnar@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('lynea', 'lynea@gmail.com', 'A user of PCS', 'lyneapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lynea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'lynea@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lynea@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lynea@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('estrella', 'estrella@gmail.com', 'A user of PCS', 'estrellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estrella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'estrella@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estrella@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gui', 'gui@gmail.com', 'A user of PCS', 'guipw');
INSERT INTO PetOwners(email) VALUES ('gui@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'rocky', 'rocky needs love!', 'rocky is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'diva', 'diva needs love!', 'diva is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'gretel', 'gretel needs love!', 'gretel is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gui@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'gui@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gui@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gui@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gui@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('merry', 'merry@gmail.com', 'A user of PCS', 'merrypw');
INSERT INTO PetOwners(email) VALUES ('merry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'boo', 'boo needs love!', 'boo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merry@gmail.com', 'andy', 'andy needs love!', 'andy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('dasie', 'dasie@gmail.com', 'A user of PCS', 'dasiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dasie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dasie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dasie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dasie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dasie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dasie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('cherri', 'cherri@gmail.com', 'A user of PCS', 'cherripw');
INSERT INTO PetOwners(email) VALUES ('cherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'nina', 'nina needs love!', 'nina is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'sassy', 'sassy needs love!', 'sassy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'casper', 'casper needs love!', 'casper is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('gilli', 'gilli@gmail.com', 'A user of PCS', 'gillipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gilli@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'gilli@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'gilli@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gilli@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gilli@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('dominga', 'dominga@gmail.com', 'A user of PCS', 'domingapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dominga@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dominga@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominga@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('bertha', 'bertha@gmail.com', 'A user of PCS', 'berthapw');
INSERT INTO PetOwners(email) VALUES ('bertha@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertha@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertha@gmail.com', 'einstein', 'einstein needs love!', 'einstein is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertha@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('sauncho', 'sauncho@gmail.com', 'A user of PCS', 'saunchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sauncho@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'sauncho@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'sauncho@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sauncho@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'sauncho@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sauncho@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sauncho@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('marian', 'marian@gmail.com', 'A user of PCS', 'marianpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marian@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'marian@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marian@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marian@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('aylmer', 'aylmer@gmail.com', 'A user of PCS', 'aylmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aylmer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'aylmer@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aylmer@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aylmer@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('annadiana', 'annadiana@gmail.com', 'A user of PCS', 'annadianapw');
INSERT INTO PetOwners(email) VALUES ('annadiana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('annadiana@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('annadiana@gmail.com', 'panda', 'panda needs love!', 'panda is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('annadiana@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annadiana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'annadiana@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('annadiana@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('christye', 'christye@gmail.com', 'A user of PCS', 'christyepw');
INSERT INTO PetOwners(email) VALUES ('christye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christye@gmail.com', 'andy', 'andy needs love!', 'andy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('devin', 'devin@gmail.com', 'A user of PCS', 'devinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('devin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'devin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'devin@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('renee', 'renee@gmail.com', 'A user of PCS', 'reneepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('renee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'renee@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('renee@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('renee@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('frayda', 'frayda@gmail.com', 'A user of PCS', 'fraydapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('frayda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'frayda@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frayda@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('berton', 'berton@gmail.com', 'A user of PCS', 'bertonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('berton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'berton@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('germana', 'germana@gmail.com', 'A user of PCS', 'germanapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('germana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'germana@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'germana@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'germana@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'germana@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('lezlie', 'lezlie@gmail.com', 'A user of PCS', 'lezliepw');
INSERT INTO PetOwners(email) VALUES ('lezlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'crystal', 'crystal needs love!', 'crystal is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'mary', 'mary needs love!', 'mary is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lezlie@gmail.com', 'pickles', 'pickles needs love!', 'pickles is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('shellie', 'shellie@gmail.com', 'A user of PCS', 'shelliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shellie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'shellie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shellie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shellie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shellie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('enrichetta', 'enrichetta@gmail.com', 'A user of PCS', 'enrichettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrichetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'enrichetta@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'enrichetta@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'enrichetta@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('roanne', 'roanne@gmail.com', 'A user of PCS', 'roannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'roanne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'roanne@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'roanne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'roanne@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roanne@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roanne@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('milton', 'milton@gmail.com', 'A user of PCS', 'miltonpw');
INSERT INTO PetOwners(email) VALUES ('milton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'magic', 'magic needs love!', 'magic is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'eva', 'eva needs love!', 'eva is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'milton@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'milton@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'milton@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milton@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gustaf', 'gustaf@gmail.com', 'A user of PCS', 'gustafpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gustaf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gustaf@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gustaf@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gustaf@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gustaf@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gustaf@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('otto', 'otto@gmail.com', 'A user of PCS', 'ottopw');
INSERT INTO PetOwners(email) VALUES ('otto@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otto@gmail.com', 'chad', 'chad needs love!', 'chad is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('otto@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'otto@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'otto@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('wylma', 'wylma@gmail.com', 'A user of PCS', 'wylmapw');
INSERT INTO PetOwners(email) VALUES ('wylma@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wylma@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wylma@gmail.com', 'joker', 'joker needs love!', 'joker is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('marie-jeanne', 'marie-jeanne@gmail.com', 'A user of PCS', 'marie-jeannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marie-jeanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'marie-jeanne@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marie-jeanne@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marie-jeanne@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('elsi', 'elsi@gmail.com', 'A user of PCS', 'elsipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'elsi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'elsi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'elsi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'elsi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'elsi@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsi@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsi@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('sullivan', 'sullivan@gmail.com', 'A user of PCS', 'sullivanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sullivan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'sullivan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'sullivan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'sullivan@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sullivan@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sullivan@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('laraine', 'laraine@gmail.com', 'A user of PCS', 'larainepw');
INSERT INTO PetOwners(email) VALUES ('laraine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laraine@gmail.com', 'moose', 'moose needs love!', 'moose is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('tammara', 'tammara@gmail.com', 'A user of PCS', 'tammarapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tammara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tammara@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tammara@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tammara@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tammara@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tammara@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ferdinande', 'ferdinande@gmail.com', 'A user of PCS', 'ferdinandepw');
INSERT INTO PetOwners(email) VALUES ('ferdinande@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdinande@gmail.com', 'benson', 'benson needs love!', 'benson is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('lib', 'lib@gmail.com', 'A user of PCS', 'libpw');
INSERT INTO PetOwners(email) VALUES ('lib@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lib@gmail.com', 'pretty-girl', 'pretty-girl needs love!', 'pretty-girl is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lib@gmail.com', 'camille', 'camille needs love!', 'camille is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lib@gmail.com', 'moochie', 'moochie needs love!', 'moochie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lib@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lib@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('sophia', 'sophia@gmail.com', 'A user of PCS', 'sophiapw');
INSERT INTO PetOwners(email) VALUES ('sophia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sophia@gmail.com', 'cupcake', 'cupcake needs love!', 'cupcake is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sophia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sophia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sophia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sophia@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('orazio', 'orazio@gmail.com', 'A user of PCS', 'oraziopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('orazio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'orazio@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'orazio@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'orazio@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('orazio@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('burtie', 'burtie@gmail.com', 'A user of PCS', 'burtiepw');
INSERT INTO PetOwners(email) VALUES ('burtie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burtie@gmail.com', 'kiwi', 'kiwi needs love!', 'kiwi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burtie@gmail.com', 'miles', 'miles needs love!', 'miles is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burtie@gmail.com', 'ivory', 'ivory needs love!', 'ivory is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burtie@gmail.com', 'cricket', 'cricket needs love!', 'cricket is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burtie@gmail.com', 'greta', 'greta needs love!', 'greta is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('estel', 'estel@gmail.com', 'A user of PCS', 'estelpw');
INSERT INTO PetOwners(email) VALUES ('estel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'duchess', 'duchess needs love!', 'duchess is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'georgia', 'georgia needs love!', 'georgia is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estel@gmail.com', 'cole', 'cole needs love!', 'cole is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('britte', 'britte@gmail.com', 'A user of PCS', 'brittepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('britte@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'britte@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'britte@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'britte@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('britte@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('britte@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('carlynne', 'carlynne@gmail.com', 'A user of PCS', 'carlynnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'carlynne@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carlynne@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlynne@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('patton', 'patton@gmail.com', 'A user of PCS', 'pattonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'patton@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'patton@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'patton@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'patton@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patton@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kerrie', 'kerrie@gmail.com', 'A user of PCS', 'kerriepw');
INSERT INTO PetOwners(email) VALUES ('kerrie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerrie@gmail.com', 'jaxson', 'jaxson needs love!', 'jaxson is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerrie@gmail.com', 'mr kitty', 'mr kitty needs love!', 'mr kitty is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kerrie@gmail.com', 'girl', 'girl needs love!', 'girl is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('katharyn', 'katharyn@gmail.com', 'A user of PCS', 'katharynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katharyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'katharyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'katharyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'katharyn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'katharyn@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katharyn@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('kris', 'kris@gmail.com', 'A user of PCS', 'krispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kris@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kris@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kris@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kris@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kris@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kris@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jorey', 'jorey@gmail.com', 'A user of PCS', 'joreypw');
INSERT INTO PetOwners(email) VALUES ('jorey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorey@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorey@gmail.com', 'katz', 'katz needs love!', 'katz is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorey@gmail.com', 'duncan', 'duncan needs love!', 'duncan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorey@gmail.com', 'scout', 'scout needs love!', 'scout is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorey@gmail.com', 'molly', 'molly needs love!', 'molly is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('kathie', 'kathie@gmail.com', 'A user of PCS', 'kathiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kathie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kathie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kathie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kathie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'kathie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kathie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kathie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('chanda', 'chanda@gmail.com', 'A user of PCS', 'chandapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chanda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'chanda@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'chanda@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'chanda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'chanda@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'chanda@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chanda@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('calv', 'calv@gmail.com', 'A user of PCS', 'calvpw');
INSERT INTO PetOwners(email) VALUES ('calv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'rollie', 'rollie needs love!', 'rollie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('wilton', 'wilton@gmail.com', 'A user of PCS', 'wiltonpw');
INSERT INTO PetOwners(email) VALUES ('wilton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'king', 'king needs love!', 'king is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'ginger', 'ginger needs love!', 'ginger is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'bubbles', 'bubbles needs love!', 'bubbles is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (248, 'wilton@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'wilton@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilton@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilton@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('odelle', 'odelle@gmail.com', 'A user of PCS', 'odellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'odelle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelle@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ajay', 'ajay@gmail.com', 'A user of PCS', 'ajaypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ajay@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'ajay@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'ajay@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ajay@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ajay@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('hesther', 'hesther@gmail.com', 'A user of PCS', 'hestherpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hesther@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'hesther@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'hesther@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'hesther@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'hesther@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'hesther@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hesther@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hesther@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('cary', 'cary@gmail.com', 'A user of PCS', 'carypw');
INSERT INTO PetOwners(email) VALUES ('cary@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'miles', 'miles needs love!', 'miles is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cary@gmail.com', 'sage', 'sage needs love!', 'sage is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cary@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'cary@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'cary@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cary@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cary@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferdy', 'ferdy@gmail.com', 'A user of PCS', 'ferdypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferdy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'ferdy@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferdy@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferdy@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('byrle', 'byrle@gmail.com', 'A user of PCS', 'byrlepw');
INSERT INTO PetOwners(email) VALUES ('byrle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrle@gmail.com', 'salty', 'salty needs love!', 'salty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrle@gmail.com', 'ladybug', 'ladybug needs love!', 'ladybug is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrle@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'byrle@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrle@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('trevor', 'trevor@gmail.com', 'A user of PCS', 'trevorpw');
INSERT INTO PetOwners(email) VALUES ('trevor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'phantom', 'phantom needs love!', 'phantom is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'gucci', 'gucci needs love!', 'gucci is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'kyra', 'kyra needs love!', 'kyra is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trevor@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (260, 'trevor@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trevor@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trevor@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('nels', 'nels@gmail.com', 'A user of PCS', 'nelspw');
INSERT INTO PetOwners(email) VALUES ('nels@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nels@gmail.com', 'bunky', 'bunky needs love!', 'bunky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nels@gmail.com', 'andy', 'andy needs love!', 'andy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nels@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'nels@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'nels@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'nels@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'nels@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'nels@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nels@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nels@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('krishnah', 'krishnah@gmail.com', 'A user of PCS', 'krishnahpw');
INSERT INTO PetOwners(email) VALUES ('krishnah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'camille', 'camille needs love!', 'camille is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'dutchess', 'dutchess needs love!', 'dutchess is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'nicky', 'nicky needs love!', 'nicky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('krishnah@gmail.com', 'lili', 'lili needs love!', 'lili is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krishnah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (270, 'krishnah@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krishnah@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krishnah@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('jefferey', 'jefferey@gmail.com', 'A user of PCS', 'jeffereypw');
INSERT INTO PetOwners(email) VALUES ('jefferey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'kc', 'kc needs love!', 'kc is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jefferey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jefferey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jefferey@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jefferey@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jefferey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('antone', 'antone@gmail.com', 'A user of PCS', 'antonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antone@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (222, 'antone@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'antone@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'antone@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'antone@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('antone@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('antone@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('hervey', 'hervey@gmail.com', 'A user of PCS', 'herveypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hervey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hervey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hervey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hervey@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hervey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('inness', 'inness@gmail.com', 'A user of PCS', 'innesspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('inness@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'inness@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'inness@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'inness@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'inness@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'inness@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inness@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('faythe', 'faythe@gmail.com', 'A user of PCS', 'faythepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('faythe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'faythe@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('faythe@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('faythe@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('neely', 'neely@gmail.com', 'A user of PCS', 'neelypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('neely@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'neely@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'neely@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'neely@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'neely@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('neely@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('neely@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('kylila', 'kylila@gmail.com', 'A user of PCS', 'kylilapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kylila@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kylila@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kylila@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('miltie', 'miltie@gmail.com', 'A user of PCS', 'miltiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('miltie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'miltie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'miltie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'miltie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'miltie@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('miltie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('miltie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('gretal', 'gretal@gmail.com', 'A user of PCS', 'gretalpw');
INSERT INTO PetOwners(email) VALUES ('gretal@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'george', 'george needs love!', 'george is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'digger', 'digger needs love!', 'digger is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('burr', 'burr@gmail.com', 'A user of PCS', 'burrpw');
INSERT INTO PetOwners(email) VALUES ('burr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'alf', 'alf needs love!', 'alf is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'parker', 'parker needs love!', 'parker is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'rocko', 'rocko needs love!', 'rocko is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burr@gmail.com', 'belle', 'belle needs love!', 'belle is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('giordano', 'giordano@gmail.com', 'A user of PCS', 'giordanopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giordano@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'giordano@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('giordano@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('isaiah', 'isaiah@gmail.com', 'A user of PCS', 'isaiahpw');
INSERT INTO PetOwners(email) VALUES ('isaiah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isaiah@gmail.com', 'simon', 'simon needs love!', 'simon is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isaiah@gmail.com', 'jester', 'jester needs love!', 'jester is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('isaiah@gmail.com', 'lizzy', 'lizzy needs love!', 'lizzy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('shannah', 'shannah@gmail.com', 'A user of PCS', 'shannahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shannah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'shannah@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shannah@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shannah@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('gerard', 'gerard@gmail.com', 'A user of PCS', 'gerardpw');
INSERT INTO PetOwners(email) VALUES ('gerard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gerard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gerard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gerard@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gerard@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gerard@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gerard@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerard@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('isa', 'isa@gmail.com', 'A user of PCS', 'isapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'isa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'isa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'isa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'isa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'isa@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isa@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isa@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('ragnar', 'ragnar@gmail.com', 'A user of PCS', 'ragnarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ragnar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ragnar@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ragnar@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ragnar@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('biron', 'biron@gmail.com', 'A user of PCS', 'bironpw');
INSERT INTO PetOwners(email) VALUES ('biron@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('biron@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('biron@gmail.com', 'lightning', 'lightning needs love!', 'lightning is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('biron@gmail.com', 'jade', 'jade needs love!', 'jade is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('lev', 'lev@gmail.com', 'A user of PCS', 'levpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lev@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'lev@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lev@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lev@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('daisi', 'daisi@gmail.com', 'A user of PCS', 'daisipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('daisi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'daisi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'daisi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'daisi@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('daisi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('dianemarie', 'dianemarie@gmail.com', 'A user of PCS', 'dianemariepw');
INSERT INTO PetOwners(email) VALUES ('dianemarie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dianemarie@gmail.com', 'jolly', 'jolly needs love!', 'jolly is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dianemarie@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dianemarie@gmail.com', 'laney', 'laney needs love!', 'laney is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dianemarie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'dianemarie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'dianemarie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'dianemarie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'dianemarie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'dianemarie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dianemarie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dianemarie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ira', 'ira@gmail.com', 'A user of PCS', 'irapw');
INSERT INTO PetOwners(email) VALUES ('ira@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ira@gmail.com', 'jessie', 'jessie needs love!', 'jessie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ira@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ira@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ira@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ira@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ira@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ira@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('yule', 'yule@gmail.com', 'A user of PCS', 'yulepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yule@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'yule@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'yule@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yule@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('linzy', 'linzy@gmail.com', 'A user of PCS', 'linzypw');
INSERT INTO PetOwners(email) VALUES ('linzy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linzy@gmail.com', 'ripley', 'ripley needs love!', 'ripley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linzy@gmail.com', 'pedro', 'pedro needs love!', 'pedro is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linzy@gmail.com', 'lady', 'lady needs love!', 'lady is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('linzy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'linzy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'linzy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'linzy@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('maureen', 'maureen@gmail.com', 'A user of PCS', 'maureenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maureen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'maureen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'maureen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'maureen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'maureen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'maureen@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maureen@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maureen@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('syd', 'syd@gmail.com', 'A user of PCS', 'sydpw');
INSERT INTO PetOwners(email) VALUES ('syd@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'boo-boo', 'boo-boo needs love!', 'boo-boo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'alexus', 'alexus needs love!', 'alexus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syd@gmail.com', 'ruchus', 'ruchus needs love!', 'ruchus is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('syd@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'syd@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'syd@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'syd@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'syd@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'syd@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syd@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syd@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('papageno', 'papageno@gmail.com', 'A user of PCS', 'papagenopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('papageno@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'papageno@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'papageno@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'papageno@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'papageno@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'papageno@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('papageno@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('papageno@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('malorie', 'malorie@gmail.com', 'A user of PCS', 'maloriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('malorie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'malorie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'malorie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jenilee', 'jenilee@gmail.com', 'A user of PCS', 'jenileepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenilee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'jenilee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'jenilee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'jenilee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'jenilee@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'jenilee@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenilee@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenilee@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('gillan', 'gillan@gmail.com', 'A user of PCS', 'gillanpw');
INSERT INTO PetOwners(email) VALUES ('gillan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gillan@gmail.com', 'simon', 'simon needs love!', 'simon is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gillan@gmail.com', 'ozzie', 'ozzie needs love!', 'ozzie is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('gwenette', 'gwenette@gmail.com', 'A user of PCS', 'gwenettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwenette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'gwenette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'gwenette@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwenette@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwenette@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('davon', 'davon@gmail.com', 'A user of PCS', 'davonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('davon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'davon@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('davon@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('filmer', 'filmer@gmail.com', 'A user of PCS', 'filmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filmer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'filmer@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'filmer@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'filmer@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('valentine', 'valentine@gmail.com', 'A user of PCS', 'valentinepw');
INSERT INTO PetOwners(email) VALUES ('valentine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'bebe', 'bebe needs love!', 'bebe is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'gasby', 'gasby needs love!', 'gasby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'hans', 'hans needs love!', 'hans is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('valentine@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('jamie', 'jamie@gmail.com', 'A user of PCS', 'jamiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jamie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'jamie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'jamie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jamie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jamie@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('vania', 'vania@gmail.com', 'A user of PCS', 'vaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vania@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'vania@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vania@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vania@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('birgit', 'birgit@gmail.com', 'A user of PCS', 'birgitpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('birgit@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'birgit@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'birgit@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'birgit@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'birgit@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'birgit@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('birgit@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('alie', 'alie@gmail.com', 'A user of PCS', 'aliepw');
INSERT INTO PetOwners(email) VALUES ('alie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'freckles', 'freckles needs love!', 'freckles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'simone', 'simone needs love!', 'simone is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alie@gmail.com', 'camille', 'camille needs love!', 'camille is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'alie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('maxy', 'maxy@gmail.com', 'A user of PCS', 'maxypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maxy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'maxy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'maxy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'maxy@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maxy@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maxy@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('lurette', 'lurette@gmail.com', 'A user of PCS', 'lurettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lurette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'lurette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'lurette@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lurette@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lurette@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('ozzy', 'ozzy@gmail.com', 'A user of PCS', 'ozzypw');
INSERT INTO PetOwners(email) VALUES ('ozzy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ozzy@gmail.com', 'munchkin', 'munchkin needs love!', 'munchkin is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('harbert', 'harbert@gmail.com', 'A user of PCS', 'harbertpw');
INSERT INTO PetOwners(email) VALUES ('harbert@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harbert@gmail.com', 'sampson', 'sampson needs love!', 'sampson is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harbert@gmail.com', 'fresier', 'fresier needs love!', 'fresier is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harbert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'harbert@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'harbert@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'harbert@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('burnard', 'burnard@gmail.com', 'A user of PCS', 'burnardpw');
INSERT INTO PetOwners(email) VALUES ('burnard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burnard@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burnard@gmail.com', 'reilly', 'reilly needs love!', 'reilly is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('willyt', 'willyt@gmail.com', 'A user of PCS', 'willytpw');
INSERT INTO PetOwners(email) VALUES ('willyt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'benny', 'benny needs love!', 'benny is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'hoover', 'hoover needs love!', 'hoover is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'may', 'may needs love!', 'may is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'noel', 'noel needs love!', 'noel is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ruthann', 'ruthann@gmail.com', 'A user of PCS', 'ruthannpw');
INSERT INTO PetOwners(email) VALUES ('ruthann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ruthann@gmail.com', 'gigi', 'gigi needs love!', 'gigi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ruthann@gmail.com', 'sampson', 'sampson needs love!', 'sampson is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ruthann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ruthann@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ruthann@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ruthann@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('zilvia', 'zilvia@gmail.com', 'A user of PCS', 'zilviapw');
INSERT INTO PetOwners(email) VALUES ('zilvia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'nemo', 'nemo needs love!', 'nemo is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('fletch', 'fletch@gmail.com', 'A user of PCS', 'fletchpw');
INSERT INTO PetOwners(email) VALUES ('fletch@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fletch@gmail.com', 'may', 'may needs love!', 'may is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fletch@gmail.com', 'gilda', 'gilda needs love!', 'gilda is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('tomasine', 'tomasine@gmail.com', 'A user of PCS', 'tomasinepw');
INSERT INTO PetOwners(email) VALUES ('tomasine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'sabine', 'sabine needs love!', 'sabine is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'chloe', 'chloe needs love!', 'chloe is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tomasine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tomasine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'tomasine@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'tomasine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'tomasine@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tomasine@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tomasine@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcelline', 'marcelline@gmail.com', 'A user of PCS', 'marcellinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcelline@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'marcelline@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('nadine', 'nadine@gmail.com', 'A user of PCS', 'nadinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nadine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'nadine@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'nadine@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nadine@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nadine@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('lindie', 'lindie@gmail.com', 'A user of PCS', 'lindiepw');
INSERT INTO PetOwners(email) VALUES ('lindie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lindie@gmail.com', 'curry', 'curry needs love!', 'curry is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lindie@gmail.com', 'miko', 'miko needs love!', 'miko is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('leonardo', 'leonardo@gmail.com', 'A user of PCS', 'leonardopw');
INSERT INTO PetOwners(email) VALUES ('leonardo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leonardo@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leonardo@gmail.com', 'indy', 'indy needs love!', 'indy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leonardo@gmail.com', 'niko', 'niko needs love!', 'niko is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leonardo@gmail.com', 'rollie', 'rollie needs love!', 'rollie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('pollyanna', 'pollyanna@gmail.com', 'A user of PCS', 'pollyannapw');
INSERT INTO PetOwners(email) VALUES ('pollyanna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pollyanna@gmail.com', 'ember', 'ember needs love!', 'ember is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('bealle', 'bealle@gmail.com', 'A user of PCS', 'beallepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bealle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'bealle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'bealle@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bealle@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bealle@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('finn', 'finn@gmail.com', 'A user of PCS', 'finnpw');
INSERT INTO PetOwners(email) VALUES ('finn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('finn@gmail.com', 'shorty', 'shorty needs love!', 'shorty is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('finn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'finn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'finn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'finn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'finn@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('finn@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('finn@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('hedwiga', 'hedwiga@gmail.com', 'A user of PCS', 'hedwigapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hedwiga@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'hedwiga@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hedwiga@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hedwiga@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('tarrah', 'tarrah@gmail.com', 'A user of PCS', 'tarrahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tarrah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tarrah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tarrah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tarrah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tarrah@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tarrah@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tallulah', 'tallulah@gmail.com', 'A user of PCS', 'tallulahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallulah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tallulah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tallulah@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tallulah@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tallulah@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallulah@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('elspeth', 'elspeth@gmail.com', 'A user of PCS', 'elspethpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elspeth@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'elspeth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'elspeth@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (273, 'elspeth@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elspeth@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elspeth@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('jessey', 'jessey@gmail.com', 'A user of PCS', 'jesseypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jessey@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jessey@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jessey@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('janean', 'janean@gmail.com', 'A user of PCS', 'janeanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janean@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'janean@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janean@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('arabelle', 'arabelle@gmail.com', 'A user of PCS', 'arabellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arabelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'arabelle@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'arabelle@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'arabelle@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'arabelle@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arabelle@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arabelle@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('madel', 'madel@gmail.com', 'A user of PCS', 'madelpw');
INSERT INTO PetOwners(email) VALUES ('madel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'gabby', 'gabby needs love!', 'gabby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'rocky', 'rocky needs love!', 'rocky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'madel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'madel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'madel@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madel@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('xerxes', 'xerxes@gmail.com', 'A user of PCS', 'xerxespw');
INSERT INTO PetOwners(email) VALUES ('xerxes@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'capone', 'capone needs love!', 'capone is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'bella', 'bella needs love!', 'bella is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'dudley', 'dudley needs love!', 'dudley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'arrow', 'arrow needs love!', 'arrow is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('idalia', 'idalia@gmail.com', 'A user of PCS', 'idaliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idalia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'idalia@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idalia@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('buddy', 'buddy@gmail.com', 'A user of PCS', 'buddypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('buddy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'buddy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'buddy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'buddy@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('buddy@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('geri', 'geri@gmail.com', 'A user of PCS', 'geripw');
INSERT INTO PetOwners(email) VALUES ('geri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geri@gmail.com', 'powder', 'powder needs love!', 'powder is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('quent', 'quent@gmail.com', 'A user of PCS', 'quentpw');
INSERT INTO PetOwners(email) VALUES ('quent@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('quent@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('quent@gmail.com', 'chipper', 'chipper needs love!', 'chipper is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('quent@gmail.com', 'cobweb', 'cobweb needs love!', 'cobweb is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('quent@gmail.com', 'pepper', 'pepper needs love!', 'pepper is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('quent@gmail.com', 'oliver', 'oliver needs love!', 'oliver is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('donnajean', 'donnajean@gmail.com', 'A user of PCS', 'donnajeanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donnajean@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'donnajean@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'donnajean@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'donnajean@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'donnajean@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'donnajean@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnajean@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnajean@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('carrol', 'carrol@gmail.com', 'A user of PCS', 'carrolpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrol@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'carrol@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carrol@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'carrol@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'carrol@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carrol@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('drew', 'drew@gmail.com', 'A user of PCS', 'drewpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('drew@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'drew@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'drew@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'drew@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('drew@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('drew@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('felizio', 'felizio@gmail.com', 'A user of PCS', 'feliziopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felizio@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'felizio@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felizio@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felizio@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ofilia', 'ofilia@gmail.com', 'A user of PCS', 'ofiliapw');
INSERT INTO PetOwners(email) VALUES ('ofilia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ofilia@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ofilia@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('thorn', 'thorn@gmail.com', 'A user of PCS', 'thornpw');
INSERT INTO PetOwners(email) VALUES ('thorn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thorn@gmail.com', 'fonzie', 'fonzie needs love!', 'fonzie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thorn@gmail.com', 'bosley', 'bosley needs love!', 'bosley is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('devlen', 'devlen@gmail.com', 'A user of PCS', 'devlenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('devlen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'devlen@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devlen@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devlen@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('desirae', 'desirae@gmail.com', 'A user of PCS', 'desiraepw');
INSERT INTO PetOwners(email) VALUES ('desirae@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desirae@gmail.com', 'pepper', 'pepper needs love!', 'pepper is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desirae@gmail.com', 'duncan', 'duncan needs love!', 'duncan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desirae@gmail.com', 'howie', 'howie needs love!', 'howie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desirae@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('desirae@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'desirae@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'desirae@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'desirae@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desirae@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desirae@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('emilie', 'emilie@gmail.com', 'A user of PCS', 'emiliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emilie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'emilie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'emilie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'emilie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emilie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('oralle', 'oralle@gmail.com', 'A user of PCS', 'orallepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('oralle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (162, 'oralle@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'oralle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'oralle@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'oralle@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oralle@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oralle@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('deborah', 'deborah@gmail.com', 'A user of PCS', 'deborahpw');
INSERT INTO PetOwners(email) VALUES ('deborah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'miasy', 'miasy needs love!', 'miasy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'nakita', 'nakita needs love!', 'nakita is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'ebony', 'ebony needs love!', 'ebony is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'jackie', 'jackie needs love!', 'jackie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deborah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'deborah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'deborah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'deborah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'deborah@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'deborah@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deborah@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deborah@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('damara', 'damara@gmail.com', 'A user of PCS', 'damarapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('damara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'damara@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'damara@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'damara@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'damara@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'damara@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('damara@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('damara@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('linet', 'linet@gmail.com', 'A user of PCS', 'linetpw');
INSERT INTO PetOwners(email) VALUES ('linet@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'sabine', 'sabine needs love!', 'sabine is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'ace', 'ace needs love!', 'ace is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'purdy', 'purdy needs love!', 'purdy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'megan', 'megan needs love!', 'megan is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'rico', 'rico needs love!', 'rico is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('desmond', 'desmond@gmail.com', 'A user of PCS', 'desmondpw');
INSERT INTO PetOwners(email) VALUES ('desmond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('desmond@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('gaylord', 'gaylord@gmail.com', 'A user of PCS', 'gaylordpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gaylord@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'gaylord@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'gaylord@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'gaylord@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gaylord@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gaylord@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('averil', 'averil@gmail.com', 'A user of PCS', 'averilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('averil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'averil@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('averil@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('averil@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('hale', 'hale@gmail.com', 'A user of PCS', 'halepw');
INSERT INTO PetOwners(email) VALUES ('hale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'ashley', 'ashley needs love!', 'ashley is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'ruffer', 'ruffer needs love!', 'ruffer is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'misha', 'misha needs love!', 'misha is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hale@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hale@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hale@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hale@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hale@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hale@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('brunhilda', 'brunhilda@gmail.com', 'A user of PCS', 'brunhildapw');
INSERT INTO PetOwners(email) VALUES ('brunhilda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brunhilda@gmail.com', 'scoobie', 'scoobie needs love!', 'scoobie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('christabel', 'christabel@gmail.com', 'A user of PCS', 'christabelpw');
INSERT INTO PetOwners(email) VALUES ('christabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'boy', 'boy needs love!', 'boy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'franky', 'franky needs love!', 'franky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'big boy', 'big boy needs love!', 'big boy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'booker', 'booker needs love!', 'booker is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('therine', 'therine@gmail.com', 'A user of PCS', 'therinepw');
INSERT INTO PetOwners(email) VALUES ('therine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'itsy-bitsy', 'itsy-bitsy needs love!', 'itsy-bitsy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('sorcha', 'sorcha@gmail.com', 'A user of PCS', 'sorchapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sorcha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sorcha@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sorcha@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sorcha@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('zebulen', 'zebulen@gmail.com', 'A user of PCS', 'zebulenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zebulen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'zebulen@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('mellie', 'mellie@gmail.com', 'A user of PCS', 'melliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mellie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mellie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mellie@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mellie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kendell', 'kendell@gmail.com', 'A user of PCS', 'kendellpw');
INSERT INTO PetOwners(email) VALUES ('kendell@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kendell@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kendell@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kendell@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kendell@gmail.com', 'rover', 'rover needs love!', 'rover is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kendell@gmail.com', 'cole', 'cole needs love!', 'cole is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kendell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kendell@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('sharona', 'sharona@gmail.com', 'A user of PCS', 'sharonapw');
INSERT INTO PetOwners(email) VALUES ('sharona@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'goober', 'goober needs love!', 'goober is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'koda', 'koda needs love!', 'koda is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'lefty', 'lefty needs love!', 'lefty is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('sigismund', 'sigismund@gmail.com', 'A user of PCS', 'sigismundpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigismund@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (162, 'sigismund@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigismund@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigismund@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('benita', 'benita@gmail.com', 'A user of PCS', 'benitapw');
INSERT INTO PetOwners(email) VALUES ('benita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benita@gmail.com', 'sherman', 'sherman needs love!', 'sherman is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('gabriellia', 'gabriellia@gmail.com', 'A user of PCS', 'gabrielliapw');
INSERT INTO PetOwners(email) VALUES ('gabriellia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'babbles', 'babbles needs love!', 'babbles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'gus', 'gus needs love!', 'gus is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('borg', 'borg@gmail.com', 'A user of PCS', 'borgpw');
INSERT INTO PetOwners(email) VALUES ('borg@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'chaos', 'chaos needs love!', 'chaos is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'blast', 'blast needs love!', 'blast is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'lassie', 'lassie needs love!', 'lassie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('borg@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'borg@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'borg@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'borg@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('borg@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('borg@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('christina', 'christina@gmail.com', 'A user of PCS', 'christinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'christina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'christina@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tova', 'tova@gmail.com', 'A user of PCS', 'tovapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tova@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tova@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('adolpho', 'adolpho@gmail.com', 'A user of PCS', 'adolphopw');
INSERT INTO PetOwners(email) VALUES ('adolpho@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adolpho@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolpho@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'adolpho@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (204, 'adolpho@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'adolpho@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adolpho@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adolpho@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('carlee', 'carlee@gmail.com', 'A user of PCS', 'carleepw');
INSERT INTO PetOwners(email) VALUES ('carlee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carlee@gmail.com', 'pepe', 'pepe needs love!', 'pepe is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carlee@gmail.com', 'rex', 'rex needs love!', 'rex is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'carlee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'carlee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carlee@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('emily', 'emily@gmail.com', 'A user of PCS', 'emilypw');
INSERT INTO PetOwners(email) VALUES ('emily@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emily@gmail.com', 'lynx', 'lynx needs love!', 'lynx is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emily@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'emily@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'emily@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emily@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emily@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('tuck', 'tuck@gmail.com', 'A user of PCS', 'tuckpw');
INSERT INTO PetOwners(email) VALUES ('tuck@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'bullet', 'bullet needs love!', 'bullet is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tuck@gmail.com', 'cookie', 'cookie needs love!', 'cookie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tuck@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tuck@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tuck@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tuck@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tuck@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('modesty', 'modesty@gmail.com', 'A user of PCS', 'modestypw');
INSERT INTO PetOwners(email) VALUES ('modesty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('modesty@gmail.com', 'rudy', 'rudy needs love!', 'rudy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('modesty@gmail.com', 'mouse', 'mouse needs love!', 'mouse is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('modesty@gmail.com', 'paddington', 'paddington needs love!', 'paddington is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('modesty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'modesty@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'modesty@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'modesty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'modesty@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('modesty@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('modesty@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('fabiano', 'fabiano@gmail.com', 'A user of PCS', 'fabianopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fabiano@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fabiano@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'fabiano@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'fabiano@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'fabiano@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fabiano@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fabiano@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('kerri', 'kerri@gmail.com', 'A user of PCS', 'kerripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kerri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'kerri@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'kerri@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'kerri@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'kerri@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('adriena', 'adriena@gmail.com', 'A user of PCS', 'adrienapw');
INSERT INTO PetOwners(email) VALUES ('adriena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'goober', 'goober needs love!', 'goober is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriena@gmail.com', 'mouse', 'mouse needs love!', 'mouse is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('henrietta', 'henrietta@gmail.com', 'A user of PCS', 'henriettapw');
INSERT INTO PetOwners(email) VALUES ('henrietta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'chyna', 'chyna needs love!', 'chyna is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('henrietta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'henrietta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'henrietta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'henrietta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'henrietta@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('barde', 'barde@gmail.com', 'A user of PCS', 'bardepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('barde@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'barde@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'barde@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'barde@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'barde@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barde@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('nicoline', 'nicoline@gmail.com', 'A user of PCS', 'nicolinepw');
INSERT INTO PetOwners(email) VALUES ('nicoline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicoline@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('bud', 'bud@gmail.com', 'A user of PCS', 'budpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bud@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'bud@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'bud@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bud@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('andromache', 'andromache@gmail.com', 'A user of PCS', 'andromachepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andromache@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'andromache@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (250, 'andromache@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'andromache@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'andromache@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'andromache@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andromache@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andromache@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('breanne', 'breanne@gmail.com', 'A user of PCS', 'breannepw');
INSERT INTO PetOwners(email) VALUES ('breanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'chubbs', 'chubbs needs love!', 'chubbs is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('elsinore', 'elsinore@gmail.com', 'A user of PCS', 'elsinorepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsinore@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'elsinore@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'elsinore@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (278, 'elsinore@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'elsinore@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsinore@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsinore@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('ollie', 'ollie@gmail.com', 'A user of PCS', 'olliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ollie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'ollie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (222, 'ollie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'ollie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ollie@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ollie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('michele', 'michele@gmail.com', 'A user of PCS', 'michelepw');
INSERT INTO PetOwners(email) VALUES ('michele@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'charlie brown', 'charlie brown needs love!', 'charlie brown is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'chance', 'chance needs love!', 'chance is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('trstram', 'trstram@gmail.com', 'A user of PCS', 'trstrampw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trstram@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'trstram@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'trstram@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trstram@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('fredia', 'fredia@gmail.com', 'A user of PCS', 'frediapw');
INSERT INTO PetOwners(email) VALUES ('fredia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'edsel', 'edsel needs love!', 'edsel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'gator', 'gator needs love!', 'gator is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'hershey', 'hershey needs love!', 'hershey is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fredia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fredia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'fredia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'fredia@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fredia@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hewett', 'hewett@gmail.com', 'A user of PCS', 'hewettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hewett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'hewett@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hewett@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hewett@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('verla', 'verla@gmail.com', 'A user of PCS', 'verlapw');
INSERT INTO PetOwners(email) VALUES ('verla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'roland', 'roland needs love!', 'roland is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'koko', 'koko needs love!', 'koko is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'max', 'max needs love!', 'max is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('sharai', 'sharai@gmail.com', 'A user of PCS', 'sharaipw');
INSERT INTO PetOwners(email) VALUES ('sharai@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharai@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('barney', 'barney@gmail.com', 'A user of PCS', 'barneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('barney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'barney@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'barney@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'barney@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('uriel', 'uriel@gmail.com', 'A user of PCS', 'urielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('uriel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'uriel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'uriel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'uriel@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('uriel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('glad', 'glad@gmail.com', 'A user of PCS', 'gladpw');
INSERT INTO PetOwners(email) VALUES ('glad@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'booker', 'booker needs love!', 'booker is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'daphne', 'daphne needs love!', 'daphne is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'cole', 'cole needs love!', 'cole is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glad@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'glad@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('shara', 'shara@gmail.com', 'A user of PCS', 'sharapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shara@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shara@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shara@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shara@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'shara@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('glennie', 'glennie@gmail.com', 'A user of PCS', 'glenniepw');
INSERT INTO PetOwners(email) VALUES ('glennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'prancer', 'prancer needs love!', 'prancer is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'hank', 'hank needs love!', 'hank is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'riggs', 'riggs needs love!', 'riggs is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glennie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'glennie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'glennie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'glennie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'glennie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'glennie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tibold', 'tibold@gmail.com', 'A user of PCS', 'tiboldpw');
INSERT INTO PetOwners(email) VALUES ('tibold@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'olivia', 'olivia needs love!', 'olivia is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tibold@gmail.com', 'corky', 'corky needs love!', 'corky is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('everett', 'everett@gmail.com', 'A user of PCS', 'everettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('everett@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'everett@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'everett@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'everett@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'everett@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('everett@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('giana', 'giana@gmail.com', 'A user of PCS', 'gianapw');
INSERT INTO PetOwners(email) VALUES ('giana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giana@gmail.com', 'eva', 'eva needs love!', 'eva is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('kissee', 'kissee@gmail.com', 'A user of PCS', 'kisseepw');
INSERT INTO PetOwners(email) VALUES ('kissee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'shelby', 'shelby needs love!', 'shelby is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('fayre', 'fayre@gmail.com', 'A user of PCS', 'fayrepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fayre@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fayre@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fayre@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fayre@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'fayre@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('darcey', 'darcey@gmail.com', 'A user of PCS', 'darceypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darcey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'darcey@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('yolane', 'yolane@gmail.com', 'A user of PCS', 'yolanepw');
INSERT INTO PetOwners(email) VALUES ('yolane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'nicky', 'nicky needs love!', 'nicky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'chubbs', 'chubbs needs love!', 'chubbs is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'blast', 'blast needs love!', 'blast is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yolane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'yolane@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'yolane@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (214, 'yolane@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'yolane@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yolane@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yolane@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('hollie', 'hollie@gmail.com', 'A user of PCS', 'holliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hollie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hollie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hollie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hollie@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('mitchael', 'mitchael@gmail.com', 'A user of PCS', 'mitchaelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitchael@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mitchael@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'mitchael@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mitchael@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'mitchael@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mitchael@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitchael@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('harv', 'harv@gmail.com', 'A user of PCS', 'harvpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harv@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'harv@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'harv@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harv@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('rockie', 'rockie@gmail.com', 'A user of PCS', 'rockiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rockie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (248, 'rockie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'rockie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'rockie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rockie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rockie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('thea', 'thea@gmail.com', 'A user of PCS', 'theapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('thea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'thea@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'thea@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'thea@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thea@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thea@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('odelinda', 'odelinda@gmail.com', 'A user of PCS', 'odelindapw');
INSERT INTO PetOwners(email) VALUES ('odelinda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelinda@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odelinda@gmail.com', 'miko', 'miko needs love!', 'miko is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odelinda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'odelinda@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('tawnya', 'tawnya@gmail.com', 'A user of PCS', 'tawnyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tawnya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tawnya@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tawnya@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ellis', 'ellis@gmail.com', 'A user of PCS', 'ellispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ellis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'ellis@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'ellis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'ellis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'ellis@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellis@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellis@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('arley', 'arley@gmail.com', 'A user of PCS', 'arleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'arley@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arley@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arley@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('abagael', 'abagael@gmail.com', 'A user of PCS', 'abagaelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abagael@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (211, 'abagael@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'abagael@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'abagael@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'abagael@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'abagael@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abagael@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abagael@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shurlock', 'shurlock@gmail.com', 'A user of PCS', 'shurlockpw');
INSERT INTO PetOwners(email) VALUES ('shurlock@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'prancer', 'prancer needs love!', 'prancer is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'charisma', 'charisma needs love!', 'charisma is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shurlock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shurlock@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dylan', 'dylan@gmail.com', 'A user of PCS', 'dylanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dylan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dylan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dylan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dylan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dylan@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dylan@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('guendolen', 'guendolen@gmail.com', 'A user of PCS', 'guendolenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('guendolen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'guendolen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'guendolen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'guendolen@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('guendolen@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('angel', 'angel@gmail.com', 'A user of PCS', 'angelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('angel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'angel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'angel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'angel@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('garek', 'garek@gmail.com', 'A user of PCS', 'garekpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garek@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'garek@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'garek@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'garek@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'garek@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'garek@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gussy', 'gussy@gmail.com', 'A user of PCS', 'gussypw');
INSERT INTO PetOwners(email) VALUES ('gussy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'edgar', 'edgar needs love!', 'edgar is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'sage', 'sage needs love!', 'sage is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'koty', 'koty needs love!', 'koty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gussy@gmail.com', 'maya', 'maya needs love!', 'maya is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('karlis', 'karlis@gmail.com', 'A user of PCS', 'karlispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'karlis@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'karlis@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'karlis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'karlis@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'karlis@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ketti', 'ketti@gmail.com', 'A user of PCS', 'kettipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ketti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ketti@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ketti@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ketti@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ketti@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('myrvyn', 'myrvyn@gmail.com', 'A user of PCS', 'myrvynpw');
INSERT INTO PetOwners(email) VALUES ('myrvyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'panther', 'panther needs love!', 'panther is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'shiloh', 'shiloh needs love!', 'shiloh is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('farah', 'farah@gmail.com', 'A user of PCS', 'farahpw');
INSERT INTO PetOwners(email) VALUES ('farah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'houdini', 'houdini needs love!', 'houdini is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'doodles', 'doodles needs love!', 'doodles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'fresier', 'fresier needs love!', 'fresier is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'bosley', 'bosley needs love!', 'bosley is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'bridgette', 'bridgette needs love!', 'bridgette is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (150, 'farah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'farah@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farah@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farah@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('analise', 'analise@gmail.com', 'A user of PCS', 'analisepw');
INSERT INTO PetOwners(email) VALUES ('analise@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'mercle', 'mercle needs love!', 'mercle is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'mitzy', 'mitzy needs love!', 'mitzy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'basil', 'basil needs love!', 'basil is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('analise@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'analise@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'analise@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('analise@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('analise@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('parry', 'parry@gmail.com', 'A user of PCS', 'parrypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('parry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'parry@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'parry@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'parry@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'parry@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (226, 'parry@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('parry@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('parry@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('merilyn', 'merilyn@gmail.com', 'A user of PCS', 'merilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merilyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'merilyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'merilyn@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'merilyn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'merilyn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'merilyn@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merilyn@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merilyn@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ladonna', 'ladonna@gmail.com', 'A user of PCS', 'ladonnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ladonna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'ladonna@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (250, 'ladonna@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'ladonna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'ladonna@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ladonna@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ladonna@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('hernando', 'hernando@gmail.com', 'A user of PCS', 'hernandopw');
INSERT INTO PetOwners(email) VALUES ('hernando@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hernando@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('bettye', 'bettye@gmail.com', 'A user of PCS', 'bettyepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bettye@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'bettye@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('vivien', 'vivien@gmail.com', 'A user of PCS', 'vivienpw');
INSERT INTO PetOwners(email) VALUES ('vivien@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vivien@gmail.com', 'misty', 'misty needs love!', 'misty is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('reilly', 'reilly@gmail.com', 'A user of PCS', 'reillypw');
INSERT INTO PetOwners(email) VALUES ('reilly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reilly@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reilly@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reilly@gmail.com', 'misty', 'misty needs love!', 'misty is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reilly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'reilly@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'reilly@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'reilly@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reilly@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('farand', 'farand@gmail.com', 'A user of PCS', 'farandpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farand@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'farand@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'farand@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'farand@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'farand@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'farand@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('gallagher', 'gallagher@gmail.com', 'A user of PCS', 'gallagherpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gallagher@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'gallagher@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gallagher@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gallagher@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('maybelle', 'maybelle@gmail.com', 'A user of PCS', 'maybellepw');
INSERT INTO PetOwners(email) VALUES ('maybelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'boss', 'boss needs love!', 'boss is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'buttercup', 'buttercup needs love!', 'buttercup is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maybelle@gmail.com', 'scarlett', 'scarlett needs love!', 'scarlett is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maybelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'maybelle@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maybelle@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maybelle@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('reid', 'reid@gmail.com', 'A user of PCS', 'reidpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'reid@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'reid@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reid@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reid@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('shem', 'shem@gmail.com', 'A user of PCS', 'shempw');
INSERT INTO PetOwners(email) VALUES ('shem@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shem@gmail.com', 'peppy', 'peppy needs love!', 'peppy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('madalena', 'madalena@gmail.com', 'A user of PCS', 'madalenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madalena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'madalena@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'madalena@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'madalena@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'madalena@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madalena@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('tallie', 'tallie@gmail.com', 'A user of PCS', 'talliepw');
INSERT INTO PetOwners(email) VALUES ('tallie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallie@gmail.com', 'misty', 'misty needs love!', 'misty is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallie@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallie@gmail.com', 'bumper', 'bumper needs love!', 'bumper is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallie@gmail.com', 'chloe', 'chloe needs love!', 'chloe is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallie@gmail.com', 'peter', 'peter needs love!', 'peter is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('margery', 'margery@gmail.com', 'A user of PCS', 'margerypw');
INSERT INTO PetOwners(email) VALUES ('margery@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margery@gmail.com', 'frosty', 'frosty needs love!', 'frosty is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('carrissa', 'carrissa@gmail.com', 'A user of PCS', 'carrissapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrissa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'carrissa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'carrissa@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrissa@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrissa@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('virgina', 'virgina@gmail.com', 'A user of PCS', 'virginapw');
INSERT INTO PetOwners(email) VALUES ('virgina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('virgina@gmail.com', 'chipper', 'chipper needs love!', 'chipper is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('virgina@gmail.com', 'greenie', 'greenie needs love!', 'greenie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('virgina@gmail.com', 'sarge', 'sarge needs love!', 'sarge is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('virgina@gmail.com', 'argus', 'argus needs love!', 'argus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('virgina@gmail.com', 'buck', 'buck needs love!', 'buck is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('virgina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'virgina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'virgina@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jocko', 'jocko@gmail.com', 'A user of PCS', 'jockopw');
INSERT INTO PetOwners(email) VALUES ('jocko@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'lovey', 'lovey needs love!', 'lovey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'dottie', 'dottie needs love!', 'dottie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jocko@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jocko@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jocko@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('inglis', 'inglis@gmail.com', 'A user of PCS', 'inglispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('inglis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'inglis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'inglis@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('inglis@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cornelia', 'cornelia@gmail.com', 'A user of PCS', 'corneliapw');
INSERT INTO PetOwners(email) VALUES ('cornelia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cornelia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cornelia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cornelia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cornelia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cornelia@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('kizzee', 'kizzee@gmail.com', 'A user of PCS', 'kizzeepw');
INSERT INTO PetOwners(email) VALUES ('kizzee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kizzee@gmail.com', 'destini', 'destini needs love!', 'destini is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kizzee@gmail.com', 'olive', 'olive needs love!', 'olive is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('jasen', 'jasen@gmail.com', 'A user of PCS', 'jasenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jasen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'jasen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (271, 'jasen@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('burgess', 'burgess@gmail.com', 'A user of PCS', 'burgesspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burgess@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (233, 'burgess@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'burgess@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'burgess@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'burgess@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burgess@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burgess@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('randie', 'randie@gmail.com', 'A user of PCS', 'randiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('randie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'randie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (212, 'randie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('randie@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('randie@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosmunda', 'rosmunda@gmail.com', 'A user of PCS', 'rosmundapw');
INSERT INTO PetOwners(email) VALUES ('rosmunda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'paris', 'paris needs love!', 'paris is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosmunda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'rosmunda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'rosmunda@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'rosmunda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'rosmunda@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosmunda@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosmunda@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('jeni', 'jeni@gmail.com', 'A user of PCS', 'jenipw');
INSERT INTO PetOwners(email) VALUES ('jeni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeni@gmail.com', 'buck', 'buck needs love!', 'buck is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('vassily', 'vassily@gmail.com', 'A user of PCS', 'vassilypw');
INSERT INTO PetOwners(email) VALUES ('vassily@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'bubbles', 'bubbles needs love!', 'bubbles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'lefty', 'lefty needs love!', 'lefty is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'quinn', 'quinn needs love!', 'quinn is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vassily@gmail.com', 'scooter', 'scooter needs love!', 'scooter is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vassily@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'vassily@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'vassily@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'vassily@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'vassily@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'vassily@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('darrelle', 'darrelle@gmail.com', 'A user of PCS', 'darrellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darrelle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'darrelle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'darrelle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'darrelle@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darrelle@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('millard', 'millard@gmail.com', 'A user of PCS', 'millardpw');
INSERT INTO PetOwners(email) VALUES ('millard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'athena', 'athena needs love!', 'athena is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'sarge', 'sarge needs love!', 'sarge is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('millard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'millard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'millard@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'millard@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('shannan', 'shannan@gmail.com', 'A user of PCS', 'shannanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shannan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shannan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shannan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'shannan@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shannan@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shannan@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('lazar', 'lazar@gmail.com', 'A user of PCS', 'lazarpw');
INSERT INTO PetOwners(email) VALUES ('lazar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lazar@gmail.com', 'kelly', 'kelly needs love!', 'kelly is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lazar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'lazar@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'lazar@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'lazar@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lazar@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lazar@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('farlie', 'farlie@gmail.com', 'A user of PCS', 'farliepw');
INSERT INTO PetOwners(email) VALUES ('farlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'oliver', 'oliver needs love!', 'oliver is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'salty', 'salty needs love!', 'salty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farlie@gmail.com', 'kenya', 'kenya needs love!', 'kenya is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farlie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'farlie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'farlie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'farlie@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farlie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farlie@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('claribel', 'claribel@gmail.com', 'A user of PCS', 'claribelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claribel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'claribel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'claribel@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'claribel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'claribel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'claribel@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claribel@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claribel@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('sibilla', 'sibilla@gmail.com', 'A user of PCS', 'sibillapw');
INSERT INTO PetOwners(email) VALUES ('sibilla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibilla@gmail.com', 'bart', 'bart needs love!', 'bart is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('clemente', 'clemente@gmail.com', 'A user of PCS', 'clementepw');
INSERT INTO PetOwners(email) VALUES ('clemente@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clemente@gmail.com', 'rock', 'rock needs love!', 'rock is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clemente@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'clemente@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('trudi', 'trudi@gmail.com', 'A user of PCS', 'trudipw');
INSERT INTO PetOwners(email) VALUES ('trudi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudi@gmail.com', 'cyrus', 'cyrus needs love!', 'cyrus is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('yoshiko', 'yoshiko@gmail.com', 'A user of PCS', 'yoshikopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yoshiko@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'yoshiko@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'yoshiko@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'yoshiko@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'yoshiko@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'yoshiko@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('petr', 'petr@gmail.com', 'A user of PCS', 'petrpw');
INSERT INTO PetOwners(email) VALUES ('petr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'butch', 'butch needs love!', 'butch is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'kiwi', 'kiwi needs love!', 'kiwi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'girl', 'girl needs love!', 'girl is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'coconut', 'coconut needs love!', 'coconut is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('filbert', 'filbert@gmail.com', 'A user of PCS', 'filbertpw');
INSERT INTO PetOwners(email) VALUES ('filbert@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('filbert@gmail.com', 'athena', 'athena needs love!', 'athena is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('ogden', 'ogden@gmail.com', 'A user of PCS', 'ogdenpw');
INSERT INTO PetOwners(email) VALUES ('ogden@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ogden@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ogden@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ogden@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ogden@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ogden@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ogden@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ogden@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('theobald', 'theobald@gmail.com', 'A user of PCS', 'theobaldpw');
INSERT INTO PetOwners(email) VALUES ('theobald@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'miasy', 'miasy needs love!', 'miasy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('theobald@gmail.com', 'katie', 'katie needs love!', 'katie is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('cinnamon', 'cinnamon@gmail.com', 'A user of PCS', 'cinnamonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cinnamon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cinnamon@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cinnamon@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cinnamon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cinnamon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cinnamon@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('mariann', 'mariann@gmail.com', 'A user of PCS', 'mariannpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mariann@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mariann@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('danella', 'danella@gmail.com', 'A user of PCS', 'danellapw');
INSERT INTO PetOwners(email) VALUES ('danella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'houdini', 'houdini needs love!', 'houdini is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('danella@gmail.com', 'silky', 'silky needs love!', 'silky is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('danella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (221, 'danella@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('danella@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('danella@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('steve', 'steve@gmail.com', 'A user of PCS', 'stevepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'steve@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('shellysheldon', 'shellysheldon@gmail.com', 'A user of PCS', 'shellysheldonpw');
INSERT INTO PetOwners(email) VALUES ('shellysheldon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'gasby', 'gasby needs love!', 'gasby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'cindy', 'cindy needs love!', 'cindy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('collen', 'collen@gmail.com', 'A user of PCS', 'collenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('collen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'collen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'collen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'collen@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('collen@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('bart', 'bart@gmail.com', 'A user of PCS', 'bartpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bart@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bart@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bart@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bart@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bart@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bart@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('gloriane', 'gloriane@gmail.com', 'A user of PCS', 'glorianepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gloriane@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gloriane@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gloriane@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gloriane@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gloriane@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gloriane@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gerri', 'gerri@gmail.com', 'A user of PCS', 'gerripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gerri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gerri@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gerri@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gerri@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gerri@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gerri@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('tiffanie', 'tiffanie@gmail.com', 'A user of PCS', 'tiffaniepw');
INSERT INTO PetOwners(email) VALUES ('tiffanie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tiffanie@gmail.com', 'jags', 'jags needs love!', 'jags is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tiffanie@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tiffanie@gmail.com', 'brit', 'brit needs love!', 'brit is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiffanie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tiffanie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tiffanie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tiffanie@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('albertine', 'albertine@gmail.com', 'A user of PCS', 'albertinepw');
INSERT INTO PetOwners(email) VALUES ('albertine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'jelly', 'jelly needs love!', 'jelly is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'miko', 'miko needs love!', 'miko is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'jet', 'jet needs love!', 'jet is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albertine@gmail.com', 'jade', 'jade needs love!', 'jade is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jemimah', 'jemimah@gmail.com', 'A user of PCS', 'jemimahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jemimah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jemimah@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jemimah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jemimah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jemimah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jemimah@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jemimah@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ermin', 'ermin@gmail.com', 'A user of PCS', 'erminpw');
INSERT INTO PetOwners(email) VALUES ('ermin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ermin@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ermin@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ermin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ermin@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ermin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ermin@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ermin@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('alfonse', 'alfonse@gmail.com', 'A user of PCS', 'alfonsepw');
INSERT INTO PetOwners(email) VALUES ('alfonse@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alfonse@gmail.com', 'gypsy', 'gypsy needs love!', 'gypsy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('osborne', 'osborne@gmail.com', 'A user of PCS', 'osbornepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('osborne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'osborne@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('osborne@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('osborne@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('leo', 'leo@gmail.com', 'A user of PCS', 'leopw');
INSERT INTO PetOwners(email) VALUES ('leo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leo@gmail.com', 'rolex', 'rolex needs love!', 'rolex is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leo@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leo@gmail.com', 'happyt', 'happyt needs love!', 'happyt is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leo@gmail.com', 'dharma', 'dharma needs love!', 'dharma is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leo@gmail.com', 'mulligan', 'mulligan needs love!', 'mulligan is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'leo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'leo@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leo@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('ryun', 'ryun@gmail.com', 'A user of PCS', 'ryunpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ryun@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ryun@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ryun@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ryun@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryun@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('yul', 'yul@gmail.com', 'A user of PCS', 'yulpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yul@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'yul@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yul@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yul@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('manda', 'manda@gmail.com', 'A user of PCS', 'mandapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('manda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'manda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'manda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'manda@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('wake', 'wake@gmail.com', 'A user of PCS', 'wakepw');
INSERT INTO PetOwners(email) VALUES ('wake@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wake@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wake@gmail.com', 'missie', 'missie needs love!', 'missie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('clarey', 'clarey@gmail.com', 'A user of PCS', 'clareypw');
INSERT INTO PetOwners(email) VALUES ('clarey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clarey@gmail.com', 'mittens', 'mittens needs love!', 'mittens is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clarey@gmail.com', 'mischief', 'mischief needs love!', 'mischief is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clarey@gmail.com', 'freddy', 'freddy needs love!', 'freddy is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('dolores', 'dolores@gmail.com', 'A user of PCS', 'dolorespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dolores@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dolores@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dolores@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('sibby', 'sibby@gmail.com', 'A user of PCS', 'sibbypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibby@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sibby@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sibby@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sibby@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sibby@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorey', 'dorey@gmail.com', 'A user of PCS', 'doreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'dorey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'dorey@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'dorey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'dorey@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorey@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorey@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorice', 'dorice@gmail.com', 'A user of PCS', 'doricepw');
INSERT INTO PetOwners(email) VALUES ('dorice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorice@gmail.com', 'macho', 'macho needs love!', 'macho is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('darci', 'darci@gmail.com', 'A user of PCS', 'darcipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darci@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'darci@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'darci@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'darci@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'darci@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'darci@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darci@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darci@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('illa', 'illa@gmail.com', 'A user of PCS', 'illapw');
INSERT INTO PetOwners(email) VALUES ('illa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('illa@gmail.com', 'dewey', 'dewey needs love!', 'dewey is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('illa@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('kara-lynn', 'kara-lynn@gmail.com', 'A user of PCS', 'kara-lynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kara-lynn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'kara-lynn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kara-lynn@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kara-lynn@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kara-lynn@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('deeann', 'deeann@gmail.com', 'A user of PCS', 'deeannpw');
INSERT INTO PetOwners(email) VALUES ('deeann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'koda', 'koda needs love!', 'koda is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'baron', 'baron needs love!', 'baron is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'benji', 'benji needs love!', 'benji is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeann@gmail.com', 'hanna', 'hanna needs love!', 'hanna is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('charleen', 'charleen@gmail.com', 'A user of PCS', 'charleenpw');
INSERT INTO PetOwners(email) VALUES ('charleen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'minnie', 'minnie needs love!', 'minnie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'ferris', 'ferris needs love!', 'ferris is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'pedro', 'pedro needs love!', 'pedro is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charleen@gmail.com', 'blaze', 'blaze needs love!', 'blaze is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charleen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'charleen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'charleen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'charleen@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'charleen@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'charleen@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('charleen@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('cesya', 'cesya@gmail.com', 'A user of PCS', 'cesyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cesya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cesya@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cesya@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cesya@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cesya@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('chrissy', 'chrissy@gmail.com', 'A user of PCS', 'chrissypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chrissy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'chrissy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'chrissy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'chrissy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'chrissy@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('sabrina', 'sabrina@gmail.com', 'A user of PCS', 'sabrinapw');
INSERT INTO PetOwners(email) VALUES ('sabrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sabrina@gmail.com', 'raison', 'raison needs love!', 'raison is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sabrina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sabrina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sabrina@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('janina', 'janina@gmail.com', 'A user of PCS', 'janinapw');
INSERT INTO PetOwners(email) VALUES ('janina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('janina@gmail.com', 'salem', 'salem needs love!', 'salem is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('janina@gmail.com', 'joe', 'joe needs love!', 'joe is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('haywood', 'haywood@gmail.com', 'A user of PCS', 'haywoodpw');
INSERT INTO PetOwners(email) VALUES ('haywood@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'franky', 'franky needs love!', 'franky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'penny', 'penny needs love!', 'penny is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'bear', 'bear needs love!', 'bear is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'mac', 'mac needs love!', 'mac is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('haywood@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'haywood@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'haywood@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'haywood@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haywood@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haywood@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('page', 'page@gmail.com', 'A user of PCS', 'pagepw');
INSERT INTO PetOwners(email) VALUES ('page@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('page@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('page@gmail.com', 'hoover', 'hoover needs love!', 'hoover is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('page@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('page@gmail.com', 'poochie', 'poochie needs love!', 'poochie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('page@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('boyd', 'boyd@gmail.com', 'A user of PCS', 'boydpw');
INSERT INTO PetOwners(email) VALUES ('boyd@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boyd@gmail.com', 'daphne', 'daphne needs love!', 'daphne is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boyd@gmail.com', 'kira', 'kira needs love!', 'kira is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boyd@gmail.com', 'cheyenne', 'cheyenne needs love!', 'cheyenne is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('brina', 'brina@gmail.com', 'A user of PCS', 'brinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'brina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'brina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'brina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'brina@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('melva', 'melva@gmail.com', 'A user of PCS', 'melvapw');
INSERT INTO PetOwners(email) VALUES ('melva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melva@gmail.com', 'gretchen', 'gretchen needs love!', 'gretchen is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melva@gmail.com', 'poppy', 'poppy needs love!', 'poppy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('melva@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'melva@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'melva@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melva@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('bendicty', 'bendicty@gmail.com', 'A user of PCS', 'bendictypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bendicty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'bendicty@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (251, 'bendicty@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'bendicty@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'bendicty@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'bendicty@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bendicty@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bendicty@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('wilhelmine', 'wilhelmine@gmail.com', 'A user of PCS', 'wilhelminepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilhelmine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'wilhelmine@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'wilhelmine@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilhelmine@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilhelmine@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('ulrich', 'ulrich@gmail.com', 'A user of PCS', 'ulrichpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulrich@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ulrich@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ulrich@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ulrich@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jane', 'jane@gmail.com', 'A user of PCS', 'janepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'jane@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jane@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jane@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('roxie', 'roxie@gmail.com', 'A user of PCS', 'roxiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roxie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'roxie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'roxie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'roxie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roxie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('bobby', 'bobby@gmail.com', 'A user of PCS', 'bobbypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bobby@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bobby@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'bobby@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bobby@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bobby@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bobby@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('melosa', 'melosa@gmail.com', 'A user of PCS', 'melosapw');
INSERT INTO PetOwners(email) VALUES ('melosa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melosa@gmail.com', 'rocky', 'rocky needs love!', 'rocky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('melosa@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('melosa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'melosa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'melosa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'melosa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'melosa@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('melosa@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('melosa@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('alex', 'alex@gmail.com', 'A user of PCS', 'alexpw');
INSERT INTO PetOwners(email) VALUES ('alex@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'pippy', 'pippy needs love!', 'pippy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('xenia', 'xenia@gmail.com', 'A user of PCS', 'xeniapw');
INSERT INTO PetOwners(email) VALUES ('xenia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenia@gmail.com', 'kasey', 'kasey needs love!', 'kasey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenia@gmail.com', 'nero', 'nero needs love!', 'nero is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('marilyn', 'marilyn@gmail.com', 'A user of PCS', 'marilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marilyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marilyn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marilyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marilyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marilyn@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jany', 'jany@gmail.com', 'A user of PCS', 'janypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jany@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'jany@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'jany@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'jany@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jany@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jany@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jany@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('anthiathia', 'anthiathia@gmail.com', 'A user of PCS', 'anthiathiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anthiathia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'anthiathia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'anthiathia@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anthiathia@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anthiathia@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('hortense', 'hortense@gmail.com', 'A user of PCS', 'hortensepw');
INSERT INTO PetOwners(email) VALUES ('hortense@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'prancer', 'prancer needs love!', 'prancer is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('allyce', 'allyce@gmail.com', 'A user of PCS', 'allycepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('allyce@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'allyce@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allyce@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ranna', 'ranna@gmail.com', 'A user of PCS', 'rannapw');
INSERT INTO PetOwners(email) VALUES ('ranna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ranna@gmail.com', 'rocky', 'rocky needs love!', 'rocky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ranna@gmail.com', 'nitro', 'nitro needs love!', 'nitro is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('enrika', 'enrika@gmail.com', 'A user of PCS', 'enrikapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrika@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'enrika@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'enrika@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrika@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('enrika@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferdie', 'ferdie@gmail.com', 'A user of PCS', 'ferdiepw');
INSERT INTO PetOwners(email) VALUES ('ferdie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'samantha', 'samantha needs love!', 'samantha is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'banjo', 'banjo needs love!', 'banjo is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('shandra', 'shandra@gmail.com', 'A user of PCS', 'shandrapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandra@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'shandra@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandra@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandra@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('craig', 'craig@gmail.com', 'A user of PCS', 'craigpw');
INSERT INTO PetOwners(email) VALUES ('craig@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('craig@gmail.com', 'luna', 'luna needs love!', 'luna is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('craig@gmail.com', 'puddles', 'puddles needs love!', 'puddles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('craig@gmail.com', 'maggie-moo', 'maggie-moo needs love!', 'maggie-moo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('craig@gmail.com', 'friday', 'friday needs love!', 'friday is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('milzie', 'milzie@gmail.com', 'A user of PCS', 'milziepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milzie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'milzie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'milzie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('maurene', 'maurene@gmail.com', 'A user of PCS', 'maurenepw');
INSERT INTO PetOwners(email) VALUES ('maurene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'brady', 'brady needs love!', 'brady is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'annie', 'annie needs love!', 'annie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'grace', 'grace needs love!', 'grace is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'rosa', 'rosa needs love!', 'rosa is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maurene@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'maurene@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maurene@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maurene@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('hoyt', 'hoyt@gmail.com', 'A user of PCS', 'hoytpw');
INSERT INTO PetOwners(email) VALUES ('hoyt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hoyt@gmail.com', 'genie', 'genie needs love!', 'genie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hoyt@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hoyt@gmail.com', 'jasper', 'jasper needs love!', 'jasper is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('gayler', 'gayler@gmail.com', 'A user of PCS', 'gaylerpw');
INSERT INTO PetOwners(email) VALUES ('gayler@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'abbie', 'abbie needs love!', 'abbie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('deeyn', 'deeyn@gmail.com', 'A user of PCS', 'deeynpw');
INSERT INTO PetOwners(email) VALUES ('deeyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'flash', 'flash needs love!', 'flash is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deeyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'deeyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'deeyn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'deeyn@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('lucille', 'lucille@gmail.com', 'A user of PCS', 'lucillepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucille@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'lucille@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lucille@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lucille@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosamond', 'rosamond@gmail.com', 'A user of PCS', 'rosamondpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosamond@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rosamond@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosamond@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('brigid', 'brigid@gmail.com', 'A user of PCS', 'brigidpw');
INSERT INTO PetOwners(email) VALUES ('brigid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'miles', 'miles needs love!', 'miles is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'bo', 'bo needs love!', 'bo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'greta', 'greta needs love!', 'greta is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'lexi', 'lexi needs love!', 'lexi is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'prince', 'prince needs love!', 'prince is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('wilie', 'wilie@gmail.com', 'A user of PCS', 'wiliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'wilie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'wilie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'wilie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'wilie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'wilie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilie@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilie@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('xenos', 'xenos@gmail.com', 'A user of PCS', 'xenospw');
INSERT INTO PetOwners(email) VALUES ('xenos@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'joker', 'joker needs love!', 'joker is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'jingles', 'jingles needs love!', 'jingles is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('selestina', 'selestina@gmail.com', 'A user of PCS', 'selestinapw');
INSERT INTO PetOwners(email) VALUES ('selestina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'jet', 'jet needs love!', 'jet is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'chipper', 'chipper needs love!', 'chipper is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'jade', 'jade needs love!', 'jade is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selestina@gmail.com', 'cotton', 'cotton needs love!', 'cotton is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('marcie', 'marcie@gmail.com', 'A user of PCS', 'marciepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marcie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('susanne', 'susanne@gmail.com', 'A user of PCS', 'susannepw');
INSERT INTO PetOwners(email) VALUES ('susanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susanne@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susanne@gmail.com', 'kc', 'kc needs love!', 'kc is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susanne@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('susanne@gmail.com', 'sissy', 'sissy needs love!', 'sissy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('susanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'susanne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'susanne@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'susanne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'susanne@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('susanne@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('susanne@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('humfrid', 'humfrid@gmail.com', 'A user of PCS', 'humfridpw');
INSERT INTO PetOwners(email) VALUES ('humfrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'jethro', 'jethro needs love!', 'jethro is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('humfrid@gmail.com', 'poppy', 'poppy needs love!', 'poppy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humfrid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'humfrid@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'humfrid@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'humfrid@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'humfrid@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humfrid@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jeffry', 'jeffry@gmail.com', 'A user of PCS', 'jeffrypw');
INSERT INTO PetOwners(email) VALUES ('jeffry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'georgie', 'georgie needs love!', 'georgie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'olive', 'olive needs love!', 'olive is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'beauty', 'beauty needs love!', 'beauty is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'jj', 'jj needs love!', 'jj is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeffry@gmail.com', 'lucy', 'lucy needs love!', 'lucy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('rriocard', 'rriocard@gmail.com', 'A user of PCS', 'rriocardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rriocard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rriocard@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dale', 'dale@gmail.com', 'A user of PCS', 'dalepw');
INSERT INTO PetOwners(email) VALUES ('dale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'emily', 'emily needs love!', 'emily is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('dorthea', 'dorthea@gmail.com', 'A user of PCS', 'dortheapw');
INSERT INTO PetOwners(email) VALUES ('dorthea@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthea@gmail.com', 'mary jane', 'mary jane needs love!', 'mary jane is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthea@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthea@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthea@gmail.com', 'cubs', 'cubs needs love!', 'cubs is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('addy', 'addy@gmail.com', 'A user of PCS', 'addypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('addy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'addy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'addy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'addy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'addy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'addy@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('addy@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fenelia', 'fenelia@gmail.com', 'A user of PCS', 'feneliapw');
INSERT INTO PetOwners(email) VALUES ('fenelia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fenelia@gmail.com', 'brook', 'brook needs love!', 'brook is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fenelia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'fenelia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fenelia@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('cathi', 'cathi@gmail.com', 'A user of PCS', 'cathipw');
INSERT INTO PetOwners(email) VALUES ('cathi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathi@gmail.com', 'jesse', 'jesse needs love!', 'jesse is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cathi@gmail.com', 'angus', 'angus needs love!', 'angus is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('bertina', 'bertina@gmail.com', 'A user of PCS', 'bertinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bertina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bertina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bertina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'bertina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'bertina@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bertina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('levey', 'levey@gmail.com', 'A user of PCS', 'leveypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('levey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'levey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'levey@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'levey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'levey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'levey@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('levey@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('alister', 'alister@gmail.com', 'A user of PCS', 'alisterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alister@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'alister@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'alister@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('constantia', 'constantia@gmail.com', 'A user of PCS', 'constantiapw');
INSERT INTO PetOwners(email) VALUES ('constantia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'reggie', 'reggie needs love!', 'reggie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'alex', 'alex needs love!', 'alex is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'mister', 'mister needs love!', 'mister is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constantia@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('angelita', 'angelita@gmail.com', 'A user of PCS', 'angelitapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('angelita@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'angelita@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'angelita@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'angelita@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'angelita@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'angelita@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angelita@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fernando', 'fernando@gmail.com', 'A user of PCS', 'fernandopw');
INSERT INTO PetOwners(email) VALUES ('fernando@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fernando@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fernando@gmail.com', 'hammer', 'hammer needs love!', 'hammer is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fernando@gmail.com', 'sky', 'sky needs love!', 'sky is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('mariska', 'mariska@gmail.com', 'A user of PCS', 'mariskapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariska@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mariska@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mariska@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mariska@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariska@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dominique', 'dominique@gmail.com', 'A user of PCS', 'dominiquepw');
INSERT INTO PetOwners(email) VALUES ('dominique@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominique@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominique@gmail.com', 'capone', 'capone needs love!', 'capone is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominique@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominique@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dominique@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dominique@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dominique@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('leda', 'leda@gmail.com', 'A user of PCS', 'ledapw');
INSERT INTO PetOwners(email) VALUES ('leda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'jesse', 'jesse needs love!', 'jesse is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'slinky', 'slinky needs love!', 'slinky is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('giuditta', 'giuditta@gmail.com', 'A user of PCS', 'giudittapw');
INSERT INTO PetOwners(email) VALUES ('giuditta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giuditta@gmail.com', 'ivy', 'ivy needs love!', 'ivy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giuditta@gmail.com', 'scoobie', 'scoobie needs love!', 'scoobie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('darwin', 'darwin@gmail.com', 'A user of PCS', 'darwinpw');
INSERT INTO PetOwners(email) VALUES ('darwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'alexus', 'alexus needs love!', 'alexus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('dorris', 'dorris@gmail.com', 'A user of PCS', 'dorrispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorris@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dorris@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dorris@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dorris@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dorris@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'dorris@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorris@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('francyne', 'francyne@gmail.com', 'A user of PCS', 'francynepw');
INSERT INTO PetOwners(email) VALUES ('francyne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'nala', 'nala needs love!', 'nala is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'skinny', 'skinny needs love!', 'skinny is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'barbie', 'barbie needs love!', 'barbie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francyne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'francyne@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francyne@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francyne@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('eddy', 'eddy@gmail.com', 'A user of PCS', 'eddypw');
INSERT INTO PetOwners(email) VALUES ('eddy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'gretel', 'gretel needs love!', 'gretel is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'curry', 'curry needs love!', 'curry is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('gideon', 'gideon@gmail.com', 'A user of PCS', 'gideonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gideon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gideon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gideon@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gideon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gideon@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gideon@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('ailey', 'ailey@gmail.com', 'A user of PCS', 'aileypw');
INSERT INTO PetOwners(email) VALUES ('ailey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ailey@gmail.com', 'sawyer', 'sawyer needs love!', 'sawyer is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jacky', 'jacky@gmail.com', 'A user of PCS', 'jackypw');
INSERT INTO PetOwners(email) VALUES ('jacky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jacky@gmail.com', 'abel', 'abel needs love!', 'abel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jacky@gmail.com', 'judy', 'judy needs love!', 'judy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jacky@gmail.com', 'franky', 'franky needs love!', 'franky is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jacky@gmail.com', 'nina', 'nina needs love!', 'nina is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jacky@gmail.com', 'flake', 'flake needs love!', 'flake is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jacky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'jacky@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jacky@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'jacky@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'jacky@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('ellyn', 'ellyn@gmail.com', 'A user of PCS', 'ellynpw');
INSERT INTO PetOwners(email) VALUES ('ellyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'boo', 'boo needs love!', 'boo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'barley', 'barley needs love!', 'barley is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('siusan', 'siusan@gmail.com', 'A user of PCS', 'siusanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('siusan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'siusan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'siusan@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'siusan@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('thomasina', 'thomasina@gmail.com', 'A user of PCS', 'thomasinapw');
INSERT INTO PetOwners(email) VALUES ('thomasina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'rocko', 'rocko needs love!', 'rocko is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'domino', 'domino needs love!', 'domino is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'harley', 'harley needs love!', 'harley is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('basilio', 'basilio@gmail.com', 'A user of PCS', 'basiliopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('basilio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'basilio@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'basilio@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('mavis', 'mavis@gmail.com', 'A user of PCS', 'mavispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mavis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mavis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mavis@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mavis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mavis@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gretel', 'gretel@gmail.com', 'A user of PCS', 'gretelpw');
INSERT INTO PetOwners(email) VALUES ('gretel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretel@gmail.com', 'kellie', 'kellie needs love!', 'kellie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretel@gmail.com', 'jr', 'jr needs love!', 'jr is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretel@gmail.com', 'ricky', 'ricky needs love!', 'ricky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretel@gmail.com', 'chipper', 'chipper needs love!', 'chipper is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretel@gmail.com', 'justice', 'justice needs love!', 'justice is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gretel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gretel@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretel@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('gunilla', 'gunilla@gmail.com', 'A user of PCS', 'gunillapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gunilla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'gunilla@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'gunilla@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'gunilla@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunilla@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunilla@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('feodora', 'feodora@gmail.com', 'A user of PCS', 'feodorapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('feodora@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'feodora@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'feodora@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'feodora@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('feodora@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('phebe', 'phebe@gmail.com', 'A user of PCS', 'phebepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('phebe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'phebe@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'phebe@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'phebe@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('phebe@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('phebe@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('shurlocke', 'shurlocke@gmail.com', 'A user of PCS', 'shurlockepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shurlocke@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shurlocke@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('teri', 'teri@gmail.com', 'A user of PCS', 'teripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('teri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'teri@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teri@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('mike', 'mike@gmail.com', 'A user of PCS', 'mikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mike@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mike@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mike@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mike@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('cora', 'cora@gmail.com', 'A user of PCS', 'corapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cora@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cora@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cora@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cora@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cora@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cora@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cora@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('lois', 'lois@gmail.com', 'A user of PCS', 'loispw');
INSERT INTO PetOwners(email) VALUES ('lois@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lois@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lois@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lois@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lois@gmail.com', 'onie', 'onie needs love!', 'onie is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lois@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lois@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lois@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lois@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lois@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lois@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('rafaellle', 'rafaellle@gmail.com', 'A user of PCS', 'rafaelllepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rafaellle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rafaellle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rafaellle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'rafaellle@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rafaellle@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('krystle', 'krystle@gmail.com', 'A user of PCS', 'krystlepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krystle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'krystle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'krystle@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krystle@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gilly', 'gilly@gmail.com', 'A user of PCS', 'gillypw');
INSERT INTO PetOwners(email) VALUES ('gilly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'nike', 'nike needs love!', 'nike is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'digger', 'digger needs love!', 'digger is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'henry', 'henry needs love!', 'henry is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('chrystel', 'chrystel@gmail.com', 'A user of PCS', 'chrystelpw');
INSERT INTO PetOwners(email) VALUES ('chrystel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrystel@gmail.com', 'quinn', 'quinn needs love!', 'quinn is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrystel@gmail.com', 'barney', 'barney needs love!', 'barney is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrystel@gmail.com', 'petie', 'petie needs love!', 'petie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrystel@gmail.com', 'ashes', 'ashes needs love!', 'ashes is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrystel@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('patti', 'patti@gmail.com', 'A user of PCS', 'pattipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'patti@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patti@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mart', 'mart@gmail.com', 'A user of PCS', 'martpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mart@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mart@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'mart@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mart@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mart@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('egor', 'egor@gmail.com', 'A user of PCS', 'egorpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('egor@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'egor@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'egor@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'egor@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('egor@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('joline', 'joline@gmail.com', 'A user of PCS', 'jolinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joline@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'joline@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joline@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('shamus', 'shamus@gmail.com', 'A user of PCS', 'shamuspw');
INSERT INTO PetOwners(email) VALUES ('shamus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shamus@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('eunice', 'eunice@gmail.com', 'A user of PCS', 'eunicepw');
INSERT INTO PetOwners(email) VALUES ('eunice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eunice@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eunice@gmail.com', 'missie', 'missie needs love!', 'missie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eunice@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'eunice@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'eunice@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'eunice@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'eunice@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'eunice@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eunice@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('boonie', 'boonie@gmail.com', 'A user of PCS', 'booniepw');
INSERT INTO PetOwners(email) VALUES ('boonie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('boonie@gmail.com', 'chili', 'chili needs love!', 'chili is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boonie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (268, 'boonie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'boonie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'boonie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'boonie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'boonie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boonie@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boonie@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('darbee', 'darbee@gmail.com', 'A user of PCS', 'darbeepw');
INSERT INTO PetOwners(email) VALUES ('darbee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'doc', 'doc needs love!', 'doc is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darbee@gmail.com', 'pooh', 'pooh needs love!', 'pooh is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darbee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'darbee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'darbee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'darbee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'darbee@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('shayla', 'shayla@gmail.com', 'A user of PCS', 'shaylapw');
INSERT INTO PetOwners(email) VALUES ('shayla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shayla@gmail.com', 'nutmeg', 'nutmeg needs love!', 'nutmeg is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shayla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'shayla@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'shayla@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shayla@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shayla@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('clare', 'clare@gmail.com', 'A user of PCS', 'clarepw');
INSERT INTO PetOwners(email) VALUES ('clare@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clare@gmail.com', 'bruno', 'bruno needs love!', 'bruno is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clare@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'clare@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'clare@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'clare@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'clare@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'clare@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clare@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clare@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('caty', 'caty@gmail.com', 'A user of PCS', 'catypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'caty@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'caty@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'caty@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'caty@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'caty@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caty@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caty@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('shandie', 'shandie@gmail.com', 'A user of PCS', 'shandiepw');
INSERT INTO PetOwners(email) VALUES ('shandie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shandie@gmail.com', 'barker', 'barker needs love!', 'barker is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shandie@gmail.com', 'oreo', 'oreo needs love!', 'oreo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'shandie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'shandie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shandie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shandie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shandie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('sibel', 'sibel@gmail.com', 'A user of PCS', 'sibelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'sibel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (238, 'sibel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'sibel@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('pip', 'pip@gmail.com', 'A user of PCS', 'pippw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pip@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pip@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'pip@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'pip@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('helen-elizabeth', 'helen-elizabeth@gmail.com', 'A user of PCS', 'helen-elizabethpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('helen-elizabeth@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'helen-elizabeth@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'helen-elizabeth@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'helen-elizabeth@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'helen-elizabeth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'helen-elizabeth@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('helen-elizabeth@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('helen-elizabeth@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('audry', 'audry@gmail.com', 'A user of PCS', 'audrypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('audry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'audry@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'audry@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'audry@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('audry@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('audry@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('jaquenetta', 'jaquenetta@gmail.com', 'A user of PCS', 'jaquenettapw');
INSERT INTO PetOwners(email) VALUES ('jaquenetta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaquenetta@gmail.com', 'chewy', 'chewy needs love!', 'chewy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaquenetta@gmail.com', 'riggs', 'riggs needs love!', 'riggs is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaquenetta@gmail.com', 'charisma', 'charisma needs love!', 'charisma is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaquenetta@gmail.com', 'lincoln', 'lincoln needs love!', 'lincoln is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaquenetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'jaquenetta@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jaquenetta@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jaquenetta@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('veda', 'veda@gmail.com', 'A user of PCS', 'vedapw');
INSERT INTO PetOwners(email) VALUES ('veda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'cassie', 'cassie needs love!', 'cassie is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('innis', 'innis@gmail.com', 'A user of PCS', 'innispw');
INSERT INTO PetOwners(email) VALUES ('innis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'chauncey', 'chauncey needs love!', 'chauncey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('innis@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'innis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'innis@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('innis@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('innis@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('maurizia', 'maurizia@gmail.com', 'A user of PCS', 'mauriziapw');
INSERT INTO PetOwners(email) VALUES ('maurizia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'cupcake', 'cupcake needs love!', 'cupcake is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'rosie', 'rosie needs love!', 'rosie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'picasso', 'picasso needs love!', 'picasso is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'gringo', 'gringo needs love!', 'gringo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurizia@gmail.com', 'clyde', 'clyde needs love!', 'clyde is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maurizia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'maurizia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'maurizia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'maurizia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'maurizia@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('tanhya', 'tanhya@gmail.com', 'A user of PCS', 'tanhyapw');
INSERT INTO PetOwners(email) VALUES ('tanhya@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'linus', 'linus needs love!', 'linus is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'apollo', 'apollo needs love!', 'apollo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'nike', 'nike needs love!', 'nike is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tanhya@gmail.com', 'huey', 'huey needs love!', 'huey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('dalila', 'dalila@gmail.com', 'A user of PCS', 'dalilapw');
INSERT INTO PetOwners(email) VALUES ('dalila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'joy', 'joy needs love!', 'joy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('tallia', 'tallia@gmail.com', 'A user of PCS', 'talliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tallia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tallia@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tallia@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('allsun', 'allsun@gmail.com', 'A user of PCS', 'allsunpw');
INSERT INTO PetOwners(email) VALUES ('allsun@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'gretchen', 'gretchen needs love!', 'gretchen is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('allsun@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'allsun@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'allsun@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'allsun@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'allsun@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'allsun@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('allsun@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('barrett', 'barrett@gmail.com', 'A user of PCS', 'barrettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('barrett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'barrett@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (216, 'barrett@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'barrett@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('barrett@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('barrett@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('sutton', 'sutton@gmail.com', 'A user of PCS', 'suttonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sutton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (161, 'sutton@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'sutton@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'sutton@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'sutton@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'sutton@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sutton@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sutton@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('minor', 'minor@gmail.com', 'A user of PCS', 'minorpw');
INSERT INTO PetOwners(email) VALUES ('minor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'lady', 'lady needs love!', 'lady is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jodee', 'jodee@gmail.com', 'A user of PCS', 'jodeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jodee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'jodee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jodee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'jodee@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jodee@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jodee@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('winnah', 'winnah@gmail.com', 'A user of PCS', 'winnahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('winnah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'winnah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'winnah@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (215, 'winnah@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'winnah@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('winnah@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('winnah@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('abrahan', 'abrahan@gmail.com', 'A user of PCS', 'abrahanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abrahan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'abrahan@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'abrahan@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abrahan@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('abrahan@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('arturo', 'arturo@gmail.com', 'A user of PCS', 'arturopw');
INSERT INTO PetOwners(email) VALUES ('arturo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'echo', 'echo needs love!', 'echo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('michal', 'michal@gmail.com', 'A user of PCS', 'michalpw');
INSERT INTO PetOwners(email) VALUES ('michal@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michal@gmail.com', 'louis', 'louis needs love!', 'louis is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michal@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michal@gmail.com', 'flakey', 'flakey needs love!', 'flakey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michal@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michal@gmail.com', 'nico', 'nico needs love!', 'nico is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michal@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (226, 'michal@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (216, 'michal@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michal@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michal@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('jyoti', 'jyoti@gmail.com', 'A user of PCS', 'jyotipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jyoti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jyoti@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jyoti@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('brennen', 'brennen@gmail.com', 'A user of PCS', 'brennenpw');
INSERT INTO PetOwners(email) VALUES ('brennen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'codi', 'codi needs love!', 'codi is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'jewel', 'jewel needs love!', 'jewel is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'baby-doll', 'baby-doll needs love!', 'baby-doll is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'jackie', 'jackie needs love!', 'jackie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('zenia', 'zenia@gmail.com', 'A user of PCS', 'zeniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zenia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'zenia@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zenia@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('juieta', 'juieta@gmail.com', 'A user of PCS', 'juietapw');
INSERT INTO PetOwners(email) VALUES ('juieta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juieta@gmail.com', 'remy', 'remy needs love!', 'remy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juieta@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juieta@gmail.com', 'moses', 'moses needs love!', 'moses is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('samaria', 'samaria@gmail.com', 'A user of PCS', 'samariapw');
INSERT INTO PetOwners(email) VALUES ('samaria@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('samaria@gmail.com', 'buster-brown', 'buster-brown needs love!', 'buster-brown is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('samaria@gmail.com', 'boo-boo', 'boo-boo needs love!', 'boo-boo is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('samaria@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'samaria@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (232, 'samaria@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('samaria@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('samaria@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('del', 'del@gmail.com', 'A user of PCS', 'delpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('del@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'del@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'del@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'del@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ede', 'ede@gmail.com', 'A user of PCS', 'edepw');
INSERT INTO PetOwners(email) VALUES ('ede@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ede@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ede@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ede@gmail.com', 'greta', 'greta needs love!', 'greta is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ede@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ede@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ede@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ede@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('genevieve', 'genevieve@gmail.com', 'A user of PCS', 'genevievepw');
INSERT INTO PetOwners(email) VALUES ('genevieve@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('genevieve@gmail.com', 'deacon', 'deacon needs love!', 'deacon is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('genevieve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'genevieve@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'genevieve@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'genevieve@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'genevieve@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'genevieve@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jana', 'jana@gmail.com', 'A user of PCS', 'janapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jana@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jana@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('wiatt', 'wiatt@gmail.com', 'A user of PCS', 'wiattpw');
INSERT INTO PetOwners(email) VALUES ('wiatt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'emily', 'emily needs love!', 'emily is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wiatt@gmail.com', 'bits', 'bits needs love!', 'bits is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('paco', 'paco@gmail.com', 'A user of PCS', 'pacopw');
INSERT INTO PetOwners(email) VALUES ('paco@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paco@gmail.com', 'megan', 'megan needs love!', 'megan is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paco@gmail.com', 'jordan', 'jordan needs love!', 'jordan is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('cristabel', 'cristabel@gmail.com', 'A user of PCS', 'cristabelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristabel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cristabel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cristabel@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristabel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('juditha', 'juditha@gmail.com', 'A user of PCS', 'judithapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juditha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'juditha@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'juditha@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'juditha@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'juditha@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'juditha@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juditha@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gretta', 'gretta@gmail.com', 'A user of PCS', 'grettapw');
INSERT INTO PetOwners(email) VALUES ('gretta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'dragster', 'dragster needs love!', 'dragster is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'andy', 'andy needs love!', 'andy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'houdini', 'houdini needs love!', 'houdini is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretta@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('addi', 'addi@gmail.com', 'A user of PCS', 'addipw');
INSERT INTO PetOwners(email) VALUES ('addi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'cameo', 'cameo needs love!', 'cameo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'patches', 'patches needs love!', 'patches is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'goldie', 'goldie needs love!', 'goldie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('addi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'addi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'addi@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('addi@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('addi@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('maddy', 'maddy@gmail.com', 'A user of PCS', 'maddypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maddy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'maddy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'maddy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'maddy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'maddy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maddy@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maddy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('carmina', 'carmina@gmail.com', 'A user of PCS', 'carminapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carmina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'carmina@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carmina@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carmina@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('esther', 'esther@gmail.com', 'A user of PCS', 'estherpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esther@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'esther@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'esther@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'esther@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esther@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gwendolin', 'gwendolin@gmail.com', 'A user of PCS', 'gwendolinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwendolin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gwendolin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gwendolin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gwendolin@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gwendolin@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gwendolin@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwendolin@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('paolo', 'paolo@gmail.com', 'A user of PCS', 'paolopw');
INSERT INTO PetOwners(email) VALUES ('paolo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paolo@gmail.com', 'rocket', 'rocket needs love!', 'rocket is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paolo@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paolo@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paolo@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paolo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'paolo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'paolo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'paolo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'paolo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'paolo@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('izak', 'izak@gmail.com', 'A user of PCS', 'izakpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('izak@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'izak@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'izak@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'izak@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'izak@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'izak@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('izak@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('izak@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('forster', 'forster@gmail.com', 'A user of PCS', 'forsterpw');
INSERT INTO PetOwners(email) VALUES ('forster@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('forster@gmail.com', 'isabella', 'isabella needs love!', 'isabella is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('forster@gmail.com', 'piggy', 'piggy needs love!', 'piggy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('brianne', 'brianne@gmail.com', 'A user of PCS', 'briannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brianne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'brianne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (211, 'brianne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'brianne@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianne@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianne@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('nickey', 'nickey@gmail.com', 'A user of PCS', 'nickeypw');
INSERT INTO PetOwners(email) VALUES ('nickey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'panther', 'panther needs love!', 'panther is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'shorty', 'shorty needs love!', 'shorty is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'shadow', 'shadow needs love!', 'shadow is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nickey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'nickey@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'nickey@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nickey@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nickey@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('hendrik', 'hendrik@gmail.com', 'A user of PCS', 'hendrikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hendrik@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'hendrik@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'hendrik@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hendrik@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hendrik@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('natividad', 'natividad@gmail.com', 'A user of PCS', 'natividadpw');
INSERT INTO PetOwners(email) VALUES ('natividad@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'gizmo', 'gizmo needs love!', 'gizmo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'ellie', 'ellie needs love!', 'ellie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('natividad@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'natividad@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'natividad@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'natividad@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'natividad@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natividad@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('natividad@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('katrinka', 'katrinka@gmail.com', 'A user of PCS', 'katrinkapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katrinka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'katrinka@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'katrinka@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'katrinka@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katrinka@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katrinka@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('karolina', 'karolina@gmail.com', 'A user of PCS', 'karolinapw');
INSERT INTO PetOwners(email) VALUES ('karolina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karolina@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karolina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'karolina@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karolina@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karolina@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('cassius', 'cassius@gmail.com', 'A user of PCS', 'cassiuspw');
INSERT INTO PetOwners(email) VALUES ('cassius@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassius@gmail.com', 'prince', 'prince needs love!', 'prince is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('franzen', 'franzen@gmail.com', 'A user of PCS', 'franzenpw');
INSERT INTO PetOwners(email) VALUES ('franzen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'meadow', 'meadow needs love!', 'meadow is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('derrick', 'derrick@gmail.com', 'A user of PCS', 'derrickpw');
INSERT INTO PetOwners(email) VALUES ('derrick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'lilly', 'lilly needs love!', 'lilly is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('derrick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'derrick@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcellus', 'marcellus@gmail.com', 'A user of PCS', 'marcelluspw');
INSERT INTO PetOwners(email) VALUES ('marcellus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'cricket', 'cricket needs love!', 'cricket is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'maggie', 'maggie needs love!', 'maggie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'koba', 'koba needs love!', 'koba is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcellus@gmail.com', 'rocco', 'rocco needs love!', 'rocco is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('brianna', 'brianna@gmail.com', 'A user of PCS', 'briannapw');
INSERT INTO PetOwners(email) VALUES ('brianna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'pickles', 'pickles needs love!', 'pickles is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'queenie', 'queenie needs love!', 'queenie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'scruffy', 'scruffy needs love!', 'scruffy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'jimmuy', 'jimmuy needs love!', 'jimmuy is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brianna@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'brianna@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'brianna@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'brianna@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'brianna@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianna@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brianna@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('viva', 'viva@gmail.com', 'A user of PCS', 'vivapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('viva@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'viva@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('viva@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('erich', 'erich@gmail.com', 'A user of PCS', 'erichpw');
INSERT INTO PetOwners(email) VALUES ('erich@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erich@gmail.com', 'allie', 'allie needs love!', 'allie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erich@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'erich@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'erich@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'erich@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'erich@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'erich@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gordon', 'gordon@gmail.com', 'A user of PCS', 'gordonpw');
INSERT INTO PetOwners(email) VALUES ('gordon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'rosy', 'rosy needs love!', 'rosy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gordon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gordon@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gordon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gordon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gordon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gordon@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('maryl', 'maryl@gmail.com', 'A user of PCS', 'marylpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maryl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'maryl@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('zedekiah', 'zedekiah@gmail.com', 'A user of PCS', 'zedekiahpw');
INSERT INTO PetOwners(email) VALUES ('zedekiah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zedekiah@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zedekiah@gmail.com', 'chief', 'chief needs love!', 'chief is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zedekiah@gmail.com', 'happyt', 'happyt needs love!', 'happyt is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zedekiah@gmail.com', 'abigail', 'abigail needs love!', 'abigail is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zedekiah@gmail.com', 'scooter', 'scooter needs love!', 'scooter is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('elwira', 'elwira@gmail.com', 'A user of PCS', 'elwirapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elwira@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'elwira@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwira@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elwira@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('marwin', 'marwin@gmail.com', 'A user of PCS', 'marwinpw');
INSERT INTO PetOwners(email) VALUES ('marwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'itsy-bitsy', 'itsy-bitsy needs love!', 'itsy-bitsy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'augie', 'augie needs love!', 'augie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'miller', 'miller needs love!', 'miller is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marwin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marwin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marwin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marwin@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marwin@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('caldwell', 'caldwell@gmail.com', 'A user of PCS', 'caldwellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caldwell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'caldwell@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'caldwell@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'caldwell@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'caldwell@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'caldwell@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('caldwell@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('elsworth', 'elsworth@gmail.com', 'A user of PCS', 'elsworthpw');
INSERT INTO PetOwners(email) VALUES ('elsworth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsworth@gmail.com', 'grace', 'grace needs love!', 'grace is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsworth@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsworth@gmail.com', 'henry', 'henry needs love!', 'henry is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsworth@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsworth@gmail.com', 'buffie', 'buffie needs love!', 'buffie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsworth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'elsworth@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'elsworth@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mallorie', 'mallorie@gmail.com', 'A user of PCS', 'malloriepw');
INSERT INTO PetOwners(email) VALUES ('mallorie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'fluffy', 'fluffy needs love!', 'fluffy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'lulu', 'lulu needs love!', 'lulu is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'sam', 'sam needs love!', 'sam is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('rudie', 'rudie@gmail.com', 'A user of PCS', 'rudiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rudie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rudie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rudie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'rudie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rudie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rudie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('giacobo', 'giacobo@gmail.com', 'A user of PCS', 'giacobopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giacobo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'giacobo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'giacobo@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'giacobo@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'giacobo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'giacobo@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('celesta', 'celesta@gmail.com', 'A user of PCS', 'celestapw');
INSERT INTO PetOwners(email) VALUES ('celesta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'iris', 'iris needs love!', 'iris is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'benny', 'benny needs love!', 'benny is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'benson', 'benson needs love!', 'benson is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celesta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'celesta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'celesta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'celesta@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celesta@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celesta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('janella', 'janella@gmail.com', 'A user of PCS', 'janellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'janella@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'janella@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'janella@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'janella@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janella@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('adriane', 'adriane@gmail.com', 'A user of PCS', 'adrianepw');
INSERT INTO PetOwners(email) VALUES ('adriane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'furball', 'furball needs love!', 'furball is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'athena', 'athena needs love!', 'athena is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('herc', 'herc@gmail.com', 'A user of PCS', 'hercpw');
INSERT INTO PetOwners(email) VALUES ('herc@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'sassie', 'sassie needs love!', 'sassie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'cinder', 'cinder needs love!', 'cinder is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'noel', 'noel needs love!', 'noel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'mack', 'mack needs love!', 'mack is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('julietta', 'julietta@gmail.com', 'A user of PCS', 'juliettapw');
INSERT INTO PetOwners(email) VALUES ('julietta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('julietta@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('julietta@gmail.com', 'jade', 'jade needs love!', 'jade is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('julietta@gmail.com', 'frisky', 'frisky needs love!', 'frisky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('julietta@gmail.com', 'kira', 'kira needs love!', 'kira is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('olivero', 'olivero@gmail.com', 'A user of PCS', 'oliveropw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('olivero@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'olivero@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'olivero@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'olivero@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('welch', 'welch@gmail.com', 'A user of PCS', 'welchpw');
INSERT INTO PetOwners(email) VALUES ('welch@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('welch@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('welch@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'welch@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('welch@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorrie', 'dorrie@gmail.com', 'A user of PCS', 'dorriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dorrie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dorrie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('augustina', 'augustina@gmail.com', 'A user of PCS', 'augustinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('augustina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'augustina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'augustina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'augustina@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('idaline', 'idaline@gmail.com', 'A user of PCS', 'idalinepw');
INSERT INTO PetOwners(email) VALUES ('idaline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'noodles', 'noodles needs love!', 'noodles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'sadie', 'sadie needs love!', 'sadie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'comet', 'comet needs love!', 'comet is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('merl', 'merl@gmail.com', 'A user of PCS', 'merlpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merl@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'merl@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hillary', 'hillary@gmail.com', 'A user of PCS', 'hillarypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hillary@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'hillary@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'hillary@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'hillary@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'hillary@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hillary@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hillary@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('vernen', 'vernen@gmail.com', 'A user of PCS', 'vernenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vernen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'vernen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'vernen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'vernen@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('benedicto', 'benedicto@gmail.com', 'A user of PCS', 'benedictopw');
INSERT INTO PetOwners(email) VALUES ('benedicto@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'atlas', 'atlas needs love!', 'atlas is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'phantom', 'phantom needs love!', 'phantom is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'felix', 'felix needs love!', 'felix is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'dolly', 'dolly needs love!', 'dolly is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('niki', 'niki@gmail.com', 'A user of PCS', 'nikipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('niki@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'niki@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'niki@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'niki@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'niki@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('niki@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('kalli', 'kalli@gmail.com', 'A user of PCS', 'kallipw');
INSERT INTO PetOwners(email) VALUES ('kalli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'booker', 'booker needs love!', 'booker is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'maddy', 'maddy needs love!', 'maddy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('abram', 'abram@gmail.com', 'A user of PCS', 'abrampw');
INSERT INTO PetOwners(email) VALUES ('abram@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('abram@gmail.com', 'pepsi', 'pepsi needs love!', 'pepsi is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('laverne', 'laverne@gmail.com', 'A user of PCS', 'lavernepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laverne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'laverne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'laverne@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laverne@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('aubine', 'aubine@gmail.com', 'A user of PCS', 'aubinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aubine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'aubine@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dixie', 'dixie@gmail.com', 'A user of PCS', 'dixiepw');
INSERT INTO PetOwners(email) VALUES ('dixie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dixie@gmail.com', 'billy', 'billy needs love!', 'billy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dixie@gmail.com', 'papa', 'papa needs love!', 'papa is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dixie@gmail.com', 'sierra', 'sierra needs love!', 'sierra is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dixie@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('elliot', 'elliot@gmail.com', 'A user of PCS', 'elliotpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elliot@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'elliot@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'elliot@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'elliot@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'elliot@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'elliot@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elliot@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elliot@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('zonda', 'zonda@gmail.com', 'A user of PCS', 'zondapw');
INSERT INTO PetOwners(email) VALUES ('zonda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'eddie', 'eddie needs love!', 'eddie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'puppy', 'puppy needs love!', 'puppy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zonda@gmail.com', 'cyrus', 'cyrus needs love!', 'cyrus is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zonda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'zonda@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'zonda@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zonda@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('leicester', 'leicester@gmail.com', 'A user of PCS', 'leicesterpw');
INSERT INTO PetOwners(email) VALUES ('leicester@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'gus', 'gus needs love!', 'gus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'henry', 'henry needs love!', 'henry is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leicester@gmail.com', 'biggie', 'biggie needs love!', 'biggie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leicester@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'leicester@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'leicester@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'leicester@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leicester@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('omar', 'omar@gmail.com', 'A user of PCS', 'omarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('omar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'omar@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'omar@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('omar@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('loralee', 'loralee@gmail.com', 'A user of PCS', 'loraleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('loralee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'loralee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'loralee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'loralee@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loralee@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loralee@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('lani', 'lani@gmail.com', 'A user of PCS', 'lanipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lani@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'lani@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'lani@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lani@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lani@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('cheston', 'cheston@gmail.com', 'A user of PCS', 'chestonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cheston@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cheston@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cheston@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cheston@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cheston@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cheston@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('esmaria', 'esmaria@gmail.com', 'A user of PCS', 'esmariapw');
INSERT INTO PetOwners(email) VALUES ('esmaria@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esmaria@gmail.com', 'booster', 'booster needs love!', 'booster is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esmaria@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esmaria@gmail.com', 'koty', 'koty needs love!', 'koty is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ab', 'ab@gmail.com', 'A user of PCS', 'abpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ab@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ab@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ab@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ab@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kayley', 'kayley@gmail.com', 'A user of PCS', 'kayleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kayley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'kayley@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'kayley@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'kayley@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'kayley@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('merrielle', 'merrielle@gmail.com', 'A user of PCS', 'merriellepw');
INSERT INTO PetOwners(email) VALUES ('merrielle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'bernie', 'bernie needs love!', 'bernie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'chi chi', 'chi chi needs love!', 'chi chi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'jesse', 'jesse needs love!', 'jesse is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'bruiser', 'bruiser needs love!', 'bruiser is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('theodoric', 'theodoric@gmail.com', 'A user of PCS', 'theodoricpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('theodoric@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'theodoric@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'theodoric@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'theodoric@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'theodoric@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'theodoric@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('celinka', 'celinka@gmail.com', 'A user of PCS', 'celinkapw');
INSERT INTO PetOwners(email) VALUES ('celinka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celinka@gmail.com', 'baron', 'baron needs love!', 'baron is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celinka@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celinka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'celinka@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'celinka@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferrel', 'ferrel@gmail.com', 'A user of PCS', 'ferrelpw');
INSERT INTO PetOwners(email) VALUES ('ferrel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'skipper', 'skipper needs love!', 'skipper is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferrel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ferrel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ferrel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ferrel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ferrel@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferrel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('byrom', 'byrom@gmail.com', 'A user of PCS', 'byrompw');
INSERT INTO PetOwners(email) VALUES ('byrom@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrom@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrom@gmail.com', 'amber', 'amber needs love!', 'amber is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrom@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrom@gmail.com', 'edgar', 'edgar needs love!', 'edgar is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrom@gmail.com', 'raison', 'raison needs love!', 'raison is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrom@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'byrom@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'byrom@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrom@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('byrom@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ciel', 'ciel@gmail.com', 'A user of PCS', 'cielpw');
INSERT INTO PetOwners(email) VALUES ('ciel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ciel@gmail.com', 'rambo', 'rambo needs love!', 'rambo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ciel@gmail.com', 'grace', 'grace needs love!', 'grace is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ciel@gmail.com', 'puffy', 'puffy needs love!', 'puffy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ciel@gmail.com', 'brandy', 'brandy needs love!', 'brandy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ciel@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('meridel', 'meridel@gmail.com', 'A user of PCS', 'meridelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('meridel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'meridel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'meridel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'meridel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'meridel@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('meridel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('meridel@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('babbette', 'babbette@gmail.com', 'A user of PCS', 'babbettepw');
INSERT INTO PetOwners(email) VALUES ('babbette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('babbette@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('babbette@gmail.com', 'chaos', 'chaos needs love!', 'chaos is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('babbette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'babbette@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'babbette@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('babbette@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('babbette@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dukey', 'dukey@gmail.com', 'A user of PCS', 'dukeypw');
INSERT INTO PetOwners(email) VALUES ('dukey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'brady', 'brady needs love!', 'brady is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'bosley', 'bosley needs love!', 'bosley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'conan', 'conan needs love!', 'conan is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('bentlee', 'bentlee@gmail.com', 'A user of PCS', 'bentleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bentlee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bentlee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bentlee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'bentlee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bentlee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bentlee@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('eydie', 'eydie@gmail.com', 'A user of PCS', 'eydiepw');
INSERT INTO PetOwners(email) VALUES ('eydie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eydie@gmail.com', 'mimi', 'mimi needs love!', 'mimi is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('mattias', 'mattias@gmail.com', 'A user of PCS', 'mattiaspw');
INSERT INTO PetOwners(email) VALUES ('mattias@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'ally', 'ally needs love!', 'ally is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'gilda', 'gilda needs love!', 'gilda is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'dodger', 'dodger needs love!', 'dodger is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'papa', 'papa needs love!', 'papa is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('rosana', 'rosana@gmail.com', 'A user of PCS', 'rosanapw');
INSERT INTO PetOwners(email) VALUES ('rosana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosana@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('adolf', 'adolf@gmail.com', 'A user of PCS', 'adolfpw');
INSERT INTO PetOwners(email) VALUES ('adolf@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adolf@gmail.com', 'shelly', 'shelly needs love!', 'shelly is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'adolf@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'adolf@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'adolf@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'adolf@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('donielle', 'donielle@gmail.com', 'A user of PCS', 'doniellepw');
INSERT INTO PetOwners(email) VALUES ('donielle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donielle@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donielle@gmail.com', 'picasso', 'picasso needs love!', 'picasso is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donielle@gmail.com', 'friday', 'friday needs love!', 'friday is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donielle@gmail.com', 'sailor', 'sailor needs love!', 'sailor is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('germayne', 'germayne@gmail.com', 'A user of PCS', 'germaynepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('germayne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'germayne@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('nerta', 'nerta@gmail.com', 'A user of PCS', 'nertapw');
INSERT INTO PetOwners(email) VALUES ('nerta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'mona', 'mona needs love!', 'mona is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'odie', 'odie needs love!', 'odie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerta@gmail.com', 'friday', 'friday needs love!', 'friday is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('krysta', 'krysta@gmail.com', 'A user of PCS', 'krystapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krysta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'krysta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'krysta@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('rodina', 'rodina@gmail.com', 'A user of PCS', 'rodinapw');
INSERT INTO PetOwners(email) VALUES ('rodina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rodina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rodina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rodina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rodina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rodina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rodina@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodina@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('reine', 'reine@gmail.com', 'A user of PCS', 'reinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'reine@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'reine@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reine@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('michaela', 'michaela@gmail.com', 'A user of PCS', 'michaelapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michaela@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'michaela@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'michaela@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'michaela@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'michaela@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'michaela@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('wynne', 'wynne@gmail.com', 'A user of PCS', 'wynnepw');
INSERT INTO PetOwners(email) VALUES ('wynne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'cha cha', 'cha cha needs love!', 'cha cha is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'joker', 'joker needs love!', 'joker is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'aldo', 'aldo needs love!', 'aldo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'chase', 'chase needs love!', 'chase is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wynne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'wynne@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wynne@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wynne@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('egan', 'egan@gmail.com', 'A user of PCS', 'eganpw');
INSERT INTO PetOwners(email) VALUES ('egan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'sassy', 'sassy needs love!', 'sassy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'big boy', 'big boy needs love!', 'big boy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('egan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'egan@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'egan@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'egan@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'egan@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egan@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('egan@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('dosi', 'dosi@gmail.com', 'A user of PCS', 'dosipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dosi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'dosi@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dosi@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dosi@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('yankee', 'yankee@gmail.com', 'A user of PCS', 'yankeepw');
INSERT INTO PetOwners(email) VALUES ('yankee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yankee@gmail.com', 'hope', 'hope needs love!', 'hope is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yankee@gmail.com', 'bessie', 'bessie needs love!', 'bessie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('frederick', 'frederick@gmail.com', 'A user of PCS', 'frederickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('frederick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'frederick@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'frederick@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'frederick@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'frederick@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'frederick@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('frederick@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jerrine', 'jerrine@gmail.com', 'A user of PCS', 'jerrinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jerrine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'jerrine@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'jerrine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'jerrine@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jerrine@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jerrine@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('madonna', 'madonna@gmail.com', 'A user of PCS', 'madonnapw');
INSERT INTO PetOwners(email) VALUES ('madonna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'brutus', 'brutus needs love!', 'brutus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'peter', 'peter needs love!', 'peter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madonna@gmail.com', 'joker', 'joker needs love!', 'joker is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madonna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'madonna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'madonna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'madonna@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'madonna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'madonna@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('francklyn', 'francklyn@gmail.com', 'A user of PCS', 'francklynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francklyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'francklyn@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'francklyn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'francklyn@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francklyn@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('francklyn@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('sancho', 'sancho@gmail.com', 'A user of PCS', 'sanchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sancho@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'sancho@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sancho@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sancho@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('nonnah', 'nonnah@gmail.com', 'A user of PCS', 'nonnahpw');
INSERT INTO PetOwners(email) VALUES ('nonnah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'pepe', 'pepe needs love!', 'pepe is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'scout', 'scout needs love!', 'scout is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'ajax', 'ajax needs love!', 'ajax is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'andy', 'andy needs love!', 'andy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('oberon', 'oberon@gmail.com', 'A user of PCS', 'oberonpw');
INSERT INTO PetOwners(email) VALUES ('oberon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'nico', 'nico needs love!', 'nico is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'chance', 'chance needs love!', 'chance is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'rocko', 'rocko needs love!', 'rocko is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('oberon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'oberon@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'oberon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'oberon@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'oberon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'oberon@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oberon@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('oberon@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('timmie', 'timmie@gmail.com', 'A user of PCS', 'timmiepw');
INSERT INTO PetOwners(email) VALUES ('timmie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('timmie@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('timmie@gmail.com', 'layla', 'layla needs love!', 'layla is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('beckie', 'beckie@gmail.com', 'A user of PCS', 'beckiepw');
INSERT INTO PetOwners(email) VALUES ('beckie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'josie', 'josie needs love!', 'josie is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beckie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'beckie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'beckie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'beckie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (234, 'beckie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beckie@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('beckie@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('rolph', 'rolph@gmail.com', 'A user of PCS', 'rolphpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rolph@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rolph@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rolph@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rolph@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rolph@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rolph@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rolph@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gertrude', 'gertrude@gmail.com', 'A user of PCS', 'gertrudepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gertrude@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'gertrude@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'gertrude@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gertrude@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (209, 'gertrude@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gertrude@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gertrude@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('der', 'der@gmail.com', 'A user of PCS', 'derpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('der@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (225, 'der@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('der@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('der@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('lefty', 'lefty@gmail.com', 'A user of PCS', 'leftypw');
INSERT INTO PetOwners(email) VALUES ('lefty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'dakota', 'dakota needs love!', 'dakota is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'chevy', 'chevy needs love!', 'chevy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'riggs', 'riggs needs love!', 'riggs is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lefty@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lefty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'lefty@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (171, 'lefty@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'lefty@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'lefty@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lefty@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lefty@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('goldi', 'goldi@gmail.com', 'A user of PCS', 'goldipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('goldi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'goldi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'goldi@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('goldi@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('denny', 'denny@gmail.com', 'A user of PCS', 'dennypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'denny@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cassi', 'cassi@gmail.com', 'A user of PCS', 'cassipw');
INSERT INTO PetOwners(email) VALUES ('cassi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'belle', 'belle needs love!', 'belle is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'gabby', 'gabby needs love!', 'gabby is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'kyra', 'kyra needs love!', 'kyra is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'sable', 'sable needs love!', 'sable is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('jeromy', 'jeromy@gmail.com', 'A user of PCS', 'jeromypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeromy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'jeromy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'jeromy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'jeromy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'jeromy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'jeromy@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeromy@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeromy@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('hersh', 'hersh@gmail.com', 'A user of PCS', 'hershpw');
INSERT INTO PetOwners(email) VALUES ('hersh@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hersh@gmail.com', 'rock', 'rock needs love!', 'rock is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('christiane', 'christiane@gmail.com', 'A user of PCS', 'christianepw');
INSERT INTO PetOwners(email) VALUES ('christiane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'benji', 'benji needs love!', 'benji is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'poppy', 'poppy needs love!', 'poppy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'princess', 'princess needs love!', 'princess is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christiane@gmail.com', 'scottie', 'scottie needs love!', 'scottie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('johnath', 'johnath@gmail.com', 'A user of PCS', 'johnathpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('johnath@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'johnath@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'johnath@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'johnath@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'johnath@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johnath@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('chaim', 'chaim@gmail.com', 'A user of PCS', 'chaimpw');
INSERT INTO PetOwners(email) VALUES ('chaim@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'charlie brown', 'charlie brown needs love!', 'charlie brown is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('florida', 'florida@gmail.com', 'A user of PCS', 'floridapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('florida@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'florida@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'florida@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('margarete', 'margarete@gmail.com', 'A user of PCS', 'margaretepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margarete@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'margarete@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'margarete@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('ronny', 'ronny@gmail.com', 'A user of PCS', 'ronnypw');
INSERT INTO PetOwners(email) VALUES ('ronny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronny@gmail.com', 'lizzy', 'lizzy needs love!', 'lizzy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ronny@gmail.com', 'layla', 'layla needs love!', 'layla is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ronny@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ronny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ronny@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ronny@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ronny@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronny@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('harper', 'harper@gmail.com', 'A user of PCS', 'harperpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harper@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'harper@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'harper@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'harper@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'harper@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harper@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('delaney', 'delaney@gmail.com', 'A user of PCS', 'delaneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('delaney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'delaney@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('delaney@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tiphany', 'tiphany@gmail.com', 'A user of PCS', 'tiphanypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiphany@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tiphany@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tiphany@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tiphany@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tiphany@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tiphany@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('colene', 'colene@gmail.com', 'A user of PCS', 'colenepw');
INSERT INTO PetOwners(email) VALUES ('colene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'mango', 'mango needs love!', 'mango is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('camilla', 'camilla@gmail.com', 'A user of PCS', 'camillapw');
INSERT INTO PetOwners(email) VALUES ('camilla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('camilla@gmail.com', 'hamlet', 'hamlet needs love!', 'hamlet is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('camilla@gmail.com', 'otto', 'otto needs love!', 'otto is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camilla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'camilla@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'camilla@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'camilla@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camilla@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camilla@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('kennie', 'kennie@gmail.com', 'A user of PCS', 'kenniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kennie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kennie@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gunner', 'gunner@gmail.com', 'A user of PCS', 'gunnerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gunner@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'gunner@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'gunner@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunner@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunner@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('nicolai', 'nicolai@gmail.com', 'A user of PCS', 'nicolaipw');
INSERT INTO PetOwners(email) VALUES ('nicolai@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicolai@gmail.com', 'mandi', 'mandi needs love!', 'mandi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicolai@gmail.com', 'aj', 'aj needs love!', 'aj is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicolai@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicolai@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nicolai@gmail.com', 'babe', 'babe needs love!', 'babe is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('haleigh', 'haleigh@gmail.com', 'A user of PCS', 'haleighpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('haleigh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'haleigh@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('haleigh@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jeremy', 'jeremy@gmail.com', 'A user of PCS', 'jeremypw');
INSERT INTO PetOwners(email) VALUES ('jeremy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeremy@gmail.com', 'dante', 'dante needs love!', 'dante is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('gawen', 'gawen@gmail.com', 'A user of PCS', 'gawenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gawen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'gawen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (220, 'gawen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'gawen@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'gawen@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gawen@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gawen@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('cristen', 'cristen@gmail.com', 'A user of PCS', 'cristenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cristen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cristen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cristen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cristen@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristen@gmail.com', '2022-07-03');

INSERT INTO BidsFor VALUES ('maurizia@gmail.com', 'steffi@gmail.com', 'rosie', '2020-01-01 00:00:00', '2022-08-26', '2022-08-29', 80, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('arturo@gmail.com', 'sauncho@gmail.com', 'buddy', '2020-01-01 00:00:01', '2022-06-26', '2022-06-28', 70, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('quent@gmail.com', 'carlynne@gmail.com', 'chipper', '2020-01-01 00:00:02', '2021-01-21', '2021-01-22', 100, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('valentine@gmail.com', 'darci@gmail.com', 'rexy', '2020-01-01 00:00:03', '2021-02-25', '2021-02-28', 32, 37, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('fredia@gmail.com', 'babbette@gmail.com', 'buckeye', '2020-01-01 00:00:04', '2022-08-28', '2022-08-30', 165, 184, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ermin@gmail.com', 'roanne@gmail.com', 'pookie', '2020-01-01 00:00:05', '2022-01-04', '2022-01-08', 98, 128, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('tibold@gmail.com', 'claudie@gmail.com', 'olivia', '2020-01-01 00:00:06', '2022-06-20', '2022-06-25', 157, 173, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('erin@gmail.com', 'gabby@gmail.com', 'jagger', '2020-01-01 00:00:07', '2021-03-12', '2021-03-18', 130, 134, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('trudie@gmail.com', 'jyoti@gmail.com', 'simone', '2020-01-01 00:00:08', '2022-06-03', '2022-06-08', 90, 102, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('kippy@gmail.com', 'aldridge@gmail.com', 'red', '2020-01-01 00:00:09', '2021-06-12', '2021-06-18', 36, 61, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('glennie@gmail.com', 'aldridge@gmail.com', 'keesha', '2020-01-01 00:00:10', '2021-05-01', '2021-05-04', 36, 45, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('julietta@gmail.com', 'doralynne@gmail.com', 'kira', '2020-01-01 00:00:11', '2021-04-02', '2021-04-05', 151, 161, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('kennett@gmail.com', 'elsinore@gmail.com', 'boy', '2020-01-01 00:00:12', '2021-05-08', '2021-05-11', 164, 188, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mayne@gmail.com', 'maddy@gmail.com', 'phoenix', '2020-01-01 00:00:13', '2021-08-26', '2021-09-01', 109, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felike@gmail.com', 'abagael@gmail.com', 'pookie', '2020-01-01 00:00:14', '2022-09-14', '2022-09-16', 147, 170, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alfreda@gmail.com', 'dre@gmail.com', 'dots', '2020-01-01 00:00:15', '2021-03-05', '2021-03-09', 50, 77, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jeremy@gmail.com', 'dasie@gmail.com', 'dante', '2020-01-01 00:00:16', '2021-11-08', '2021-11-09', 140, 152, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lamar@gmail.com', 'isa@gmail.com', 'butterscotch', '2020-01-01 00:00:17', '2022-10-29', '2022-11-04', 111, 133, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felike@gmail.com', 'aldridge@gmail.com', 'pickles', '2020-01-01 00:00:18', '2022-10-12', '2022-10-12', 253, 278, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('halie@gmail.com', 'isa@gmail.com', 'magnolia', '2020-01-01 00:00:19', '2022-01-31', '2022-02-03', 205, 230, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('zonda@gmail.com', 'bertina@gmail.com', 'eddie', '2020-01-01 00:00:20', '2022-03-21', '2022-03-24', 110, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('chaim@gmail.com', 'ketti@gmail.com', 'charlie brown', '2020-01-01 00:00:21', '2021-05-18', '2021-05-21', 120, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jaime@gmail.com', 'sonny@gmail.com', 'doodles', '2020-01-01 00:00:22', '2021-02-11', '2021-02-13', 93, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('nickey@gmail.com', 'reine@gmail.com', 'panther', '2020-01-01 00:00:23', '2022-02-28', '2022-03-04', 90, 109, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jaquenetta@gmail.com', 'otho@gmail.com', 'chewy', '2020-01-01 00:00:24', '2022-10-12', '2022-10-12', 130, 130, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('shellysheldon@gmail.com', 'hilario@gmail.com', 'rascal', '2020-01-01 00:00:25', '2021-12-27', '2021-12-27', 130, 147, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ed@gmail.com', 'elnar@gmail.com', 'skeeter', '2020-01-01 00:00:26', '2022-03-06', '2022-03-07', 90, 97, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('leland@gmail.com', 'lurette@gmail.com', 'oakley', '2020-01-01 00:00:27', '2022-06-16', '2022-06-21', 94, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('erich@gmail.com', 'henrietta@gmail.com', 'allie', '2020-01-01 00:00:28', '2021-12-14', '2021-12-14', 130, 144, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('borg@gmail.com', 'cristen@gmail.com', 'blast', '2020-01-01 00:00:29', '2021-09-18', '2021-09-24', 130, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beau@gmail.com', 'modesty@gmail.com', 'savannah', '2020-01-01 00:00:30', '2022-05-15', '2022-05-18', 56, 73, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('carley@gmail.com', 'samaria@gmail.com', 'cinnamon', '2020-01-01 00:00:31', '2022-10-04', '2022-10-09', 232, 233, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('leland@gmail.com', 'sigfrid@gmail.com', 'slinky', '2020-01-01 00:00:32', '2021-05-30', '2021-06-01', 135, 161, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('merrielle@gmail.com', 'ruthann@gmail.com', 'chi chi', '2020-01-01 00:00:33', '2022-07-25', '2022-07-31', 120, 131, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('eddy@gmail.com', 'maureen@gmail.com', 'gretel', '2020-01-01 00:00:34', '2021-07-10', '2021-07-15', 47, 76, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('darwin@gmail.com', 'genevieve@gmail.com', 'cleo', '2020-01-01 00:00:35', '2022-09-05', '2022-09-06', 60, 69, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dominique@gmail.com', 'madalena@gmail.com', 'capone', '2020-01-01 00:00:36', '2021-07-17', '2021-07-22', 120, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('herc@gmail.com', 'bride@gmail.com', 'muffy', '2020-01-01 00:00:37', '2021-08-11', '2021-08-14', 150, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('vivien@gmail.com', 'angel@gmail.com', 'misty', '2020-01-01 00:00:38', '2021-08-06', '2021-08-08', 80, 95, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rafi@gmail.com', 'ernaline@gmail.com', 'beans', '2020-01-01 00:00:39', '2022-01-15', '2022-01-16', 114, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alfreda@gmail.com', 'shirl@gmail.com', 'dots', '2020-01-01 00:00:40', '2021-01-10', '2021-01-16', 59, 83, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wake@gmail.com', 'sophia@gmail.com', 'missie', '2020-01-01 00:00:41', '2021-11-22', '2021-11-22', 60, 73, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marcia@gmail.com', 'miltie@gmail.com', 'barkley', '2020-01-01 00:00:42', '2022-11-13', '2022-11-17', 97, 120, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jessi@gmail.com', 'patti@gmail.com', 'bob', '2020-01-01 00:00:43', '2022-10-08', '2022-10-08', 50, 78, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ogden@gmail.com', 'levey@gmail.com', 'chamberlain', '2020-01-01 00:00:44', '2022-12-09', '2022-12-09', 80, 101, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('melosa@gmail.com', 'abrahan@gmail.com', 'nickie', '2020-01-01 00:00:45', '2021-11-30', '2021-12-01', 133, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lefty@gmail.com', 'kalvin@gmail.com', 'riggs', '2020-01-01 00:00:46', '2021-07-06', '2021-07-07', 110, 135, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('shelden@gmail.com', 'borg@gmail.com', 'bingo', '2020-01-01 00:00:47', '2021-04-29', '2021-05-04', 190, 219, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('linzy@gmail.com', 'camilla@gmail.com', 'ripley', '2020-01-01 00:00:48', '2021-09-25', '2021-09-30', 224, 241, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sabrina@gmail.com', 'kerri@gmail.com', 'raison', '2020-01-01 00:00:49', '2021-07-28', '2021-08-03', 158, 185, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wynn@gmail.com', 'albina@gmail.com', 'big foot', '2020-01-01 00:00:50', '2021-03-29', '2021-04-02', 50, 56, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lib@gmail.com', 'frederick@gmail.com', 'pretty-girl', '2020-01-01 00:00:51', '2021-10-10', '2021-10-14', 70, 71, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gayler@gmail.com', 'jocko@gmail.com', 'dakota', '2020-01-01 00:00:52', '2022-11-25', '2022-11-28', 90, 105, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('leo@gmail.com', 'carleton@gmail.com', 'mulligan', '2020-01-01 00:00:53', '2021-12-19', '2021-12-19', 155, 177, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('chaim@gmail.com', 'nels@gmail.com', 'charlie brown', '2020-01-01 00:00:54', '2021-02-02', '2021-02-02', 158, 186, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cathi@gmail.com', 'carleton@gmail.com', 'angus', '2020-01-01 00:00:55', '2022-01-23', '2022-01-24', 174, 203, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('letizia@gmail.com', 'jemimah@gmail.com', 'silvester', '2020-01-01 00:00:56', '2021-02-15', '2021-02-21', 100, 108, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('foss@gmail.com', 'dominique@gmail.com', 'cha cha', '2020-01-01 00:00:57', '2021-07-27', '2021-08-02', 140, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felike@gmail.com', 'kylila@gmail.com', 'pookie', '2020-01-01 00:00:58', '2022-09-30', '2022-10-02', 110, 127, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('justino@gmail.com', 'del@gmail.com', 'nugget', '2020-01-01 00:00:59', '2022-01-30', '2022-01-31', 133, 136, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('theobald@gmail.com', 'kennie@gmail.com', 'katie', '2020-01-01 00:01:00', '2021-03-12', '2021-03-17', 70, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('imelda@gmail.com', 'roxie@gmail.com', 'sherman', '2020-01-01 00:01:01', '2022-12-01', '2022-12-04', 100, 101, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charin@gmail.com', 'brina@gmail.com', 'chevy', '2020-01-01 00:01:02', '2021-02-09', '2021-02-12', 80, 101, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wilton@gmail.com', 'carlynn@gmail.com', 'ginger', '2020-01-01 00:01:03', '2021-04-14', '2021-04-17', 80, 93, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lindie@gmail.com', 'kathie@gmail.com', 'miko', '2020-01-01 00:01:04', '2021-10-06', '2021-10-11', 100, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('linzy@gmail.com', 'marilyn@gmail.com', 'ripley', '2020-01-01 00:01:05', '2022-08-06', '2022-08-09', 130, 146, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('addi@gmail.com', 'cello@gmail.com', 'patches', '2020-01-01 00:01:06', '2021-02-09', '2021-02-12', 168, 168, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brana@gmail.com', 'dona@gmail.com', 'bumper', '2020-01-01 00:01:07', '2022-12-15', '2022-12-17', 80, 85, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('chuck@gmail.com', 'ulises@gmail.com', 'kibbles', '2020-01-01 00:01:08', '2021-09-04', '2021-09-09', 163, 182, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('pollyanna@gmail.com', 'emmy@gmail.com', 'ember', '2020-01-01 00:01:09', '2021-08-07', '2021-08-10', 110, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('willy@gmail.com', 'friedrick@gmail.com', 'samson', '2020-01-01 00:01:10', '2021-09-12', '2021-09-14', 90, 109, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brigid@gmail.com', 'gordon@gmail.com', 'lexi', '2020-01-01 00:01:11', '2021-12-01', '2021-12-04', 140, 154, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('christabel@gmail.com', 'addi@gmail.com', 'big boy', '2020-01-01 00:01:12', '2021-01-30', '2021-01-31', 133, 152, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('tallie@gmail.com', 'kathie@gmail.com', 'bumper', '2020-01-01 00:01:13', '2021-03-04', '2021-03-07', 100, 111, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dorry@gmail.com', 'hillary@gmail.com', 'muffin', '2020-01-01 00:01:14', '2021-09-13', '2021-09-13', 51, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('toiboid@gmail.com', 'yolane@gmail.com', 'cleo', '2020-01-01 00:01:15', '2022-02-18', '2022-02-23', 53, 55, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('daron@gmail.com', 'alverta@gmail.com', 'hunter', '2020-01-01 00:01:16', '2021-04-04', '2021-04-04', 153, 168, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('shandie@gmail.com', 'hasheem@gmail.com', 'barker', '2020-01-01 00:01:17', '2021-09-05', '2021-09-05', 147, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wynn@gmail.com', 'alyosha@gmail.com', 'big foot', '2020-01-01 00:01:18', '2021-11-11', '2021-11-15', 50, 68, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('erin@gmail.com', 'uriel@gmail.com', 'jagger', '2020-01-01 00:01:19', '2021-04-27', '2021-04-30', 130, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('millard@gmail.com', 'denise@gmail.com', 'chaz', '2020-01-01 00:01:20', '2021-03-20', '2021-03-26', 148, 176, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hortense@gmail.com', 'barrett@gmail.com', 'dobie', '2020-01-01 00:01:21', '2021-02-11', '2021-02-16', 154, 168, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dalila@gmail.com', 'lefty@gmail.com', 'joy', '2020-01-01 00:01:22', '2021-09-04', '2021-09-08', 69, 99, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('waverly@gmail.com', 'devin@gmail.com', 'cole', '2020-01-01 00:01:23', '2022-05-31', '2022-06-05', 41, 48, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lazar@gmail.com', 'cora@gmail.com', 'kelly', '2020-01-01 00:01:24', '2021-05-05', '2021-05-11', 110, 127, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brennen@gmail.com', 'ab@gmail.com', 'jewel', '2020-01-01 00:01:25', '2021-04-12', '2021-04-15', 140, 164, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gwennie@gmail.com', 'ketti@gmail.com', 'chelsea', '2020-01-01 00:01:26', '2021-03-16', '2021-03-21', 120, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('shelden@gmail.com', 'olag@gmail.com', 'bingo', '2020-01-01 00:01:27', '2021-02-05', '2021-02-10', 128, 152, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('thomasina@gmail.com', 'gideon@gmail.com', 'harley', '2020-01-01 00:01:28', '2022-11-19', '2022-11-24', 70, 75, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gretel@gmail.com', 'lefty@gmail.com', 'kellie', '2020-01-01 00:01:29', '2022-03-10', '2022-03-12', 157, 164, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xylia@gmail.com', 'gwendolin@gmail.com', 'luci', '2020-01-01 00:01:30', '2021-05-16', '2021-05-21', 100, 116, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('harbert@gmail.com', 'humfrid@gmail.com', 'sampson', '2020-01-01 00:01:31', '2022-07-19', '2022-07-19', 120, 120, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('joshua@gmail.com', 'elsi@gmail.com', 'gilbert', '2020-01-01 00:01:32', '2022-08-03', '2022-08-03', 133, 143, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('modesty@gmail.com', 'cornelia@gmail.com', 'rudy', '2020-01-01 00:01:33', '2022-10-08', '2022-10-09', 140, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('christye@gmail.com', 'flynn@gmail.com', 'andy', '2020-01-01 00:01:34', '2021-08-02', '2021-08-08', 80, 105, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('idette@gmail.com', 'ajay@gmail.com', 'koty', '2020-01-01 00:01:35', '2021-12-10', '2021-12-13', 174, 197, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hatty@gmail.com', 'chanda@gmail.com', 'birdy', '2020-01-01 00:01:36', '2021-10-01', '2021-10-07', 110, 137, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alaster@gmail.com', 'marguerite@gmail.com', 'amber', '2020-01-01 00:01:37', '2022-06-11', '2022-06-16', 100, 115, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlotte@gmail.com', 'lefty@gmail.com', 'luna', '2020-01-01 00:01:38', '2021-11-12', '2021-11-16', 157, 182, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('claudina@gmail.com', 'darbee@gmail.com', 'natasha', '2020-01-01 00:01:39', '2021-07-06', '2021-07-06', 140, 149, NULL, False, '1', '1', NULL, NULL);



-- ======================================= END GENERATED DATA =======================================




--================================================ TRIGGERS ===================================================================

-- These are the triggers that I avoid because then its much harder to generate the data
-- but the generated data is still valid

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

-- =============================================== END TRIGGERS ====================================================
