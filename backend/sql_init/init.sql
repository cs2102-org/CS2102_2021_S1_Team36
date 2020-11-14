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





















--==================================================== end first half of trigger ====================================================

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

--==================================================== GENERATED DATA HERE ====================================================

INSERT INTO Users(name, email, description, password) VALUES ('allyce', 'allyce@gmail.com', 'A user of PCS', 'allycepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('allyce@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'allyce@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('allyce@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('allyce@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('rowe', 'rowe@gmail.com', 'A user of PCS', 'rowepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rowe@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rowe@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rowe@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rowe@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rowe@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('wiatt', 'wiatt@gmail.com', 'A user of PCS', 'wiattpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wiatt@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'wiatt@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'wiatt@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'wiatt@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wiatt@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wiatt@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('syman', 'syman@gmail.com', 'A user of PCS', 'symanpw');
INSERT INTO PetOwners(email) VALUES ('syman@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('syman@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('syman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'syman@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'syman@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syman@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('gennifer', 'gennifer@gmail.com', 'A user of PCS', 'genniferpw');
INSERT INTO PetOwners(email) VALUES ('gennifer@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'muffin', 'muffin needs love!', 'muffin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'hope', 'hope needs love!', 'hope is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'sage', 'sage needs love!', 'sage is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gennifer@gmail.com', 'patch', 'patch needs love!', 'patch is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('alister', 'alister@gmail.com', 'A user of PCS', 'alisterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alister@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'alister@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alister@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'alister@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (237, 'alister@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alister@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alister@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('tanhya', 'tanhya@gmail.com', 'A user of PCS', 'tanhyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tanhya@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'tanhya@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'tanhya@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'tanhya@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tanhya@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tanhya@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('petr', 'petr@gmail.com', 'A user of PCS', 'petrpw');
INSERT INTO PetOwners(email) VALUES ('petr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'prince', 'prince needs love!', 'prince is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'curly', 'curly needs love!', 'curly is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('petr@gmail.com', 'koty', 'koty needs love!', 'koty is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('gallagher', 'gallagher@gmail.com', 'A user of PCS', 'gallagherpw');
INSERT INTO PetOwners(email) VALUES ('gallagher@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gallagher@gmail.com', 'sebastian', 'sebastian needs love!', 'sebastian is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gallagher@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gallagher@gmail.com', 'oliver', 'oliver needs love!', 'oliver is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gallagher@gmail.com', 'athena', 'athena needs love!', 'athena is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gallagher@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gallagher@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gallagher@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gallagher@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gallagher@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gallagher@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gallagher@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('devlen', 'devlen@gmail.com', 'A user of PCS', 'devlenpw');
INSERT INTO PetOwners(email) VALUES ('devlen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'cozmo', 'cozmo needs love!', 'cozmo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'dutches', 'dutches needs love!', 'dutches is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'griffen', 'griffen needs love!', 'griffen is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('devlen@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('elwin', 'elwin@gmail.com', 'A user of PCS', 'elwinpw');
INSERT INTO PetOwners(email) VALUES ('elwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elwin@gmail.com', 'mischief', 'mischief needs love!', 'mischief is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('giuditta', 'giuditta@gmail.com', 'A user of PCS', 'giudittapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giuditta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'giuditta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'giuditta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'giuditta@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giuditta@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giuditta@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('darwin', 'darwin@gmail.com', 'A user of PCS', 'darwinpw');
INSERT INTO PetOwners(email) VALUES ('darwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darwin@gmail.com', 'dodger', 'dodger needs love!', 'dodger is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darwin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'darwin@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'darwin@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'darwin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'darwin@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'darwin@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darwin@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darwin@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('kiersten', 'kiersten@gmail.com', 'A user of PCS', 'kierstenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kiersten@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'kiersten@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kiersten@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kiersten@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kiersten@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('lois', 'lois@gmail.com', 'A user of PCS', 'loispw');
INSERT INTO PetOwners(email) VALUES ('lois@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lois@gmail.com', 'koda', 'koda needs love!', 'koda is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lois@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'lois@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'lois@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lois@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lois@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lois@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lois@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('janella', 'janella@gmail.com', 'A user of PCS', 'janellapw');
INSERT INTO PetOwners(email) VALUES ('janella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('janella@gmail.com', 'lexus', 'lexus needs love!', 'lexus is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('sophia', 'sophia@gmail.com', 'A user of PCS', 'sophiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sophia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sophia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sophia@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sophia@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('izak', 'izak@gmail.com', 'A user of PCS', 'izakpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('izak@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'izak@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'izak@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('izak@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('breanne', 'breanne@gmail.com', 'A user of PCS', 'breannepw');
INSERT INTO PetOwners(email) VALUES ('breanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'audi', 'audi needs love!', 'audi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('breanne@gmail.com', 'munchkin', 'munchkin needs love!', 'munchkin is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('brianna', 'brianna@gmail.com', 'A user of PCS', 'briannapw');
INSERT INTO PetOwners(email) VALUES ('brianna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'aj', 'aj needs love!', 'aj is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'diesel', 'diesel needs love!', 'diesel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianna@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('katti', 'katti@gmail.com', 'A user of PCS', 'kattipw');
INSERT INTO PetOwners(email) VALUES ('katti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'nikki', 'nikki needs love!', 'nikki is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'ladybug', 'ladybug needs love!', 'ladybug is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'chelsea', 'chelsea needs love!', 'chelsea is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katti@gmail.com', 'bullet', 'bullet needs love!', 'bullet is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'katti@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'katti@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'katti@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'katti@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katti@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ronny', 'ronny@gmail.com', 'A user of PCS', 'ronnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'ronny@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'ronny@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronny@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ronny@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('cary', 'cary@gmail.com', 'A user of PCS', 'carypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cary@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cary@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cary@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('joshua', 'joshua@gmail.com', 'A user of PCS', 'joshuapw');
INSERT INTO PetOwners(email) VALUES ('joshua@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'buster', 'buster needs love!', 'buster is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'cherokee', 'cherokee needs love!', 'cherokee is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'adam', 'adam needs love!', 'adam is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'corky', 'corky needs love!', 'corky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joshua@gmail.com', 'puck', 'puck needs love!', 'puck is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joshua@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'joshua@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'joshua@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'joshua@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'joshua@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'joshua@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('joshua@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('cash', 'cash@gmail.com', 'A user of PCS', 'cashpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cash@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'cash@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'cash@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cash@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('mavis', 'mavis@gmail.com', 'A user of PCS', 'mavispw');
INSERT INTO PetOwners(email) VALUES ('mavis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'mercedes', 'mercedes needs love!', 'mercedes is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'maxwell', 'maxwell needs love!', 'maxwell is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'angus', 'angus needs love!', 'angus is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'hunter', 'hunter needs love!', 'hunter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mavis@gmail.com', 'nakita', 'nakita needs love!', 'nakita is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mavis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mavis@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mavis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mavis@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mavis@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mavis@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mavis@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gunilla', 'gunilla@gmail.com', 'A user of PCS', 'gunillapw');
INSERT INTO PetOwners(email) VALUES ('gunilla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gunilla@gmail.com', 'gunther', 'gunther needs love!', 'gunther is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('sibilla', 'sibilla@gmail.com', 'A user of PCS', 'sibillapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibilla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'sibilla@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'sibilla@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'sibilla@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sibilla@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibilla@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibilla@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('sancho', 'sancho@gmail.com', 'A user of PCS', 'sanchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sancho@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (181, 'sancho@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'sancho@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'sancho@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sancho@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sancho@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('mahmud', 'mahmud@gmail.com', 'A user of PCS', 'mahmudpw');
INSERT INTO PetOwners(email) VALUES ('mahmud@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'harley', 'harley needs love!', 'harley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'sebastian', 'sebastian needs love!', 'sebastian is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'klaus', 'klaus needs love!', 'klaus is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mahmud@gmail.com', 'heather', 'heather needs love!', 'heather is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('mandy', 'mandy@gmail.com', 'A user of PCS', 'mandypw');
INSERT INTO PetOwners(email) VALUES ('mandy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandy@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandy@gmail.com', 'gringo', 'gringo needs love!', 'gringo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandy@gmail.com', 'mona', 'mona needs love!', 'mona is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mandy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'mandy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'mandy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'mandy@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandy@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mandy@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('danella', 'danella@gmail.com', 'A user of PCS', 'danellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('danella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'danella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'danella@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'danella@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'danella@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danella@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('enrika', 'enrika@gmail.com', 'A user of PCS', 'enrikapw');
INSERT INTO PetOwners(email) VALUES ('enrika@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('enrika@gmail.com', 'paris', 'paris needs love!', 'paris is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('enrika@gmail.com', 'bully', 'bully needs love!', 'bully is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('enrika@gmail.com', 'shasta', 'shasta needs love!', 'shasta is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('enrika@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('enrika@gmail.com', 'jazz', 'jazz needs love!', 'jazz is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrika@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'enrika@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'enrika@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrika@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('christabel', 'christabel@gmail.com', 'A user of PCS', 'christabelpw');
INSERT INTO PetOwners(email) VALUES ('christabel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christabel@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christabel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'christabel@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christabel@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kayley', 'kayley@gmail.com', 'A user of PCS', 'kayleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kayley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (214, 'kayley@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'kayley@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kayley@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('eugene', 'eugene@gmail.com', 'A user of PCS', 'eugenepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eugene@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'eugene@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'eugene@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'eugene@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugene@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('shem', 'shem@gmail.com', 'A user of PCS', 'shempw');
INSERT INTO PetOwners(email) VALUES ('shem@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shem@gmail.com', 'mocha', 'mocha needs love!', 'mocha is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shem@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'shem@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'shem@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shem@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shem@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('chuck', 'chuck@gmail.com', 'A user of PCS', 'chuckpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chuck@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'chuck@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chuck@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chuck@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('garik', 'garik@gmail.com', 'A user of PCS', 'garikpw');
INSERT INTO PetOwners(email) VALUES ('garik@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'newt', 'newt needs love!', 'newt is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'curly', 'curly needs love!', 'curly is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'joy', 'joy needs love!', 'joy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garik@gmail.com', 'gypsy', 'gypsy needs love!', 'gypsy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('henrietta', 'henrietta@gmail.com', 'A user of PCS', 'henriettapw');
INSERT INTO PetOwners(email) VALUES ('henrietta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'nike', 'nike needs love!', 'nike is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'dots', 'dots needs love!', 'dots is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'birdie', 'birdie needs love!', 'birdie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'jimmuy', 'jimmuy needs love!', 'jimmuy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('henrietta@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('henrietta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'henrietta@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'henrietta@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'henrietta@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('henrietta@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('kylila', 'kylila@gmail.com', 'A user of PCS', 'kylilapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kylila@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kylila@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kylila@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kylila@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kylila@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ajay', 'ajay@gmail.com', 'A user of PCS', 'ajaypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ajay@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ajay@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ajay@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ajay@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ajay@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ajay@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('zilvia', 'zilvia@gmail.com', 'A user of PCS', 'zilviapw');
INSERT INTO PetOwners(email) VALUES ('zilvia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'babbles', 'babbles needs love!', 'babbles is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'bizzy', 'bizzy needs love!', 'bizzy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'crackers', 'crackers needs love!', 'crackers is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'muffin', 'muffin needs love!', 'muffin is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zilvia@gmail.com', 'montana', 'montana needs love!', 'montana is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('leesa', 'leesa@gmail.com', 'A user of PCS', 'leesapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leesa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'leesa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'leesa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'leesa@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'leesa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'leesa@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('leesa@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('lefty', 'lefty@gmail.com', 'A user of PCS', 'leftypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lefty@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'lefty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'lefty@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'lefty@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lefty@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lefty@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('milton', 'milton@gmail.com', 'A user of PCS', 'miltonpw');
INSERT INTO PetOwners(email) VALUES ('milton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'boy', 'boy needs love!', 'boy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milton@gmail.com', 'luna', 'luna needs love!', 'luna is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('biron', 'biron@gmail.com', 'A user of PCS', 'bironpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('biron@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'biron@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'biron@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'biron@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'biron@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'biron@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('biron@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gerri', 'gerri@gmail.com', 'A user of PCS', 'gerripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gerri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gerri@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gerri@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gerri@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mike', 'mike@gmail.com', 'A user of PCS', 'mikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mike@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'mike@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mike@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mike@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('peggy', 'peggy@gmail.com', 'A user of PCS', 'peggypw');
INSERT INTO PetOwners(email) VALUES ('peggy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'charles', 'charles needs love!', 'charles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'kujo', 'kujo needs love!', 'kujo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'echo', 'echo needs love!', 'echo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'binky', 'binky needs love!', 'binky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('peggy@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('peggy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'peggy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'peggy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'peggy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'peggy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'peggy@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('peggy@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('peggy@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('kania', 'kania@gmail.com', 'A user of PCS', 'kaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kania@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kania@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kania@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kania@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kania@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('cristabel', 'cristabel@gmail.com', 'A user of PCS', 'cristabelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristabel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'cristabel@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristabel@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristabel@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('borg', 'borg@gmail.com', 'A user of PCS', 'borgpw');
INSERT INTO PetOwners(email) VALUES ('borg@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'laney', 'laney needs love!', 'laney is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'skittles', 'skittles needs love!', 'skittles is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'emma', 'emma needs love!', 'emma is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('borg@gmail.com', 'bizzy', 'bizzy needs love!', 'bizzy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('borg@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'borg@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('borg@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('tyson', 'tyson@gmail.com', 'A user of PCS', 'tysonpw');
INSERT INTO PetOwners(email) VALUES ('tyson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'bella', 'bella needs love!', 'bella is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'alf', 'alf needs love!', 'alf is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tyson@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('beauregard', 'beauregard@gmail.com', 'A user of PCS', 'beauregardpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beauregard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'beauregard@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'beauregard@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'beauregard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'beauregard@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beauregard@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('mordecai', 'mordecai@gmail.com', 'A user of PCS', 'mordecaipw');
INSERT INTO PetOwners(email) VALUES ('mordecai@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mordecai@gmail.com', 'jelly-bean', 'jelly-bean needs love!', 'jelly-bean is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mordecai@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mordecai@gmail.com', 'chanel', 'chanel needs love!', 'chanel is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mordecai@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('shandra', 'shandra@gmail.com', 'A user of PCS', 'shandrapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandra@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'shandra@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'shandra@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'shandra@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'shandra@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandra@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandra@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('tonnie', 'tonnie@gmail.com', 'A user of PCS', 'tonniepw');
INSERT INTO PetOwners(email) VALUES ('tonnie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'papa', 'papa needs love!', 'papa is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'autumn', 'autumn needs love!', 'autumn is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonnie@gmail.com', 'ollie', 'ollie needs love!', 'ollie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('rosalinda', 'rosalinda@gmail.com', 'A user of PCS', 'rosalindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosalinda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rosalinda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rosalinda@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rosalinda@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rosalinda@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosalinda@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('miltie', 'miltie@gmail.com', 'A user of PCS', 'miltiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('miltie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'miltie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'miltie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'miltie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'miltie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'miltie@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('miltie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('andrew', 'andrew@gmail.com', 'A user of PCS', 'andrewpw');
INSERT INTO PetOwners(email) VALUES ('andrew@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrew@gmail.com', 'samson', 'samson needs love!', 'samson is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('modesty', 'modesty@gmail.com', 'A user of PCS', 'modestypw');
INSERT INTO PetOwners(email) VALUES ('modesty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('modesty@gmail.com', 'aj', 'aj needs love!', 'aj is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('hansiain', 'hansiain@gmail.com', 'A user of PCS', 'hansiainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hansiain@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hansiain@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hansiain@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hansiain@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('darrelle', 'darrelle@gmail.com', 'A user of PCS', 'darrellepw');
INSERT INTO PetOwners(email) VALUES ('darrelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'pippy', 'pippy needs love!', 'pippy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'callie', 'callie needs love!', 'callie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'gibson', 'gibson needs love!', 'gibson is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'aires', 'aires needs love!', 'aires is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darrelle@gmail.com', 'ruffles', 'ruffles needs love!', 'ruffles is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darrelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (217, 'darrelle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'darrelle@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'darrelle@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'darrelle@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darrelle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('darrelle@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('montague', 'montague@gmail.com', 'A user of PCS', 'montaguepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('montague@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'montague@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'montague@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (258, 'montague@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'montague@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'montague@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('montague@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('montague@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('kanya', 'kanya@gmail.com', 'A user of PCS', 'kanyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kanya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kanya@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kanya@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('zebulen', 'zebulen@gmail.com', 'A user of PCS', 'zebulenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zebulen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'zebulen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'zebulen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'zebulen@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'zebulen@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'zebulen@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zebulen@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('roosevelt', 'roosevelt@gmail.com', 'A user of PCS', 'rooseveltpw');
INSERT INTO PetOwners(email) VALUES ('roosevelt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'rover', 'rover needs love!', 'rover is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'barley', 'barley needs love!', 'barley is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roosevelt@gmail.com', 'braggs', 'braggs needs love!', 'braggs is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('jefferson', 'jefferson@gmail.com', 'A user of PCS', 'jeffersonpw');
INSERT INTO PetOwners(email) VALUES ('jefferson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferson@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferson@gmail.com', 'lady', 'lady needs love!', 'lady is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferson@gmail.com', 'fido', 'fido needs love!', 'fido is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferson@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferson@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('sibel', 'sibel@gmail.com', 'A user of PCS', 'sibelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'sibel@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'sibel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'sibel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sibel@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('der', 'der@gmail.com', 'A user of PCS', 'derpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('der@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'der@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'der@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'der@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('der@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gussy', 'gussy@gmail.com', 'A user of PCS', 'gussypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gussy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'gussy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'gussy@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gussy@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gussy@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('geordie', 'geordie@gmail.com', 'A user of PCS', 'geordiepw');
INSERT INTO PetOwners(email) VALUES ('geordie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geordie@gmail.com', 'jess', 'jess needs love!', 'jess is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('dinny', 'dinny@gmail.com', 'A user of PCS', 'dinnypw');
INSERT INTO PetOwners(email) VALUES ('dinny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dinny@gmail.com', 'pretty', 'pretty needs love!', 'pretty is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dinny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dinny@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dinny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dinny@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dinny@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dinny@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jefferey', 'jefferey@gmail.com', 'A user of PCS', 'jeffereypw');
INSERT INTO PetOwners(email) VALUES ('jefferey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'georgie', 'georgie needs love!', 'georgie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jefferey@gmail.com', 'karma', 'karma needs love!', 'karma is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('thea', 'thea@gmail.com', 'A user of PCS', 'theapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('thea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'thea@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thea@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('thea@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('foss', 'foss@gmail.com', 'A user of PCS', 'fosspw');
INSERT INTO PetOwners(email) VALUES ('foss@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('foss@gmail.com', 'dots', 'dots needs love!', 'dots is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('foss@gmail.com', 'chip', 'chip needs love!', 'chip is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('foss@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('felipa', 'felipa@gmail.com', 'A user of PCS', 'felipapw');
INSERT INTO PetOwners(email) VALUES ('felipa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felipa@gmail.com', 'crystal', 'crystal needs love!', 'crystal is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felipa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'felipa@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'felipa@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'felipa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'felipa@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('felipa@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('rodina', 'rodina@gmail.com', 'A user of PCS', 'rodinapw');
INSERT INTO PetOwners(email) VALUES ('rodina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'puppy', 'puppy needs love!', 'puppy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'slick', 'slick needs love!', 'slick is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'cali', 'cali needs love!', 'cali is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rodina@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rodina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'rodina@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rodina@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rodina@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('claudetta', 'claudetta@gmail.com', 'A user of PCS', 'claudettapw');
INSERT INTO PetOwners(email) VALUES ('claudetta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudetta@gmail.com', 'chanel', 'chanel needs love!', 'chanel is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudetta@gmail.com', 'babe', 'babe needs love!', 'babe is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'claudetta@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('claudetta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('emily', 'emily@gmail.com', 'A user of PCS', 'emilypw');
INSERT INTO PetOwners(email) VALUES ('emily@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emily@gmail.com', 'augie', 'augie needs love!', 'augie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emily@gmail.com', 'rollie', 'rollie needs love!', 'rollie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emily@gmail.com', 'angus', 'angus needs love!', 'angus is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emily@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'emily@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'emily@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'emily@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'emily@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('emily@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('claudette', 'claudette@gmail.com', 'A user of PCS', 'claudettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('claudette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'claudette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'claudette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'claudette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'claudette@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudette@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('claudette@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('kinna', 'kinna@gmail.com', 'A user of PCS', 'kinnapw');
INSERT INTO PetOwners(email) VALUES ('kinna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kinna@gmail.com', 'buck', 'buck needs love!', 'buck is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kinna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kinna@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kinna@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('idaline', 'idaline@gmail.com', 'A user of PCS', 'idalinepw');
INSERT INTO PetOwners(email) VALUES ('idaline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'nathan', 'nathan needs love!', 'nathan is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idaline@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('theodoric', 'theodoric@gmail.com', 'A user of PCS', 'theodoricpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('theodoric@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'theodoric@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'theodoric@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'theodoric@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theodoric@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('starlin', 'starlin@gmail.com', 'A user of PCS', 'starlinpw');
INSERT INTO PetOwners(email) VALUES ('starlin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'rico', 'rico needs love!', 'rico is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'kellie', 'kellie needs love!', 'kellie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starlin@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('rosamond', 'rosamond@gmail.com', 'A user of PCS', 'rosamondpw');
INSERT INTO PetOwners(email) VALUES ('rosamond@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'pluto', 'pluto needs love!', 'pluto is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosamond@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ellis', 'ellis@gmail.com', 'A user of PCS', 'ellispw');
INSERT INTO PetOwners(email) VALUES ('ellis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'grace', 'grace needs love!', 'grace is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'silky', 'silky needs love!', 'silky is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'hannah', 'hannah needs love!', 'hannah is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellis@gmail.com', 'emily', 'emily needs love!', 'emily is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('lindie', 'lindie@gmail.com', 'A user of PCS', 'lindiepw');
INSERT INTO PetOwners(email) VALUES ('lindie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lindie@gmail.com', 'kid', 'kid needs love!', 'kid is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lindie@gmail.com', 'bo', 'bo needs love!', 'bo is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('jocko', 'jocko@gmail.com', 'A user of PCS', 'jockopw');
INSERT INTO PetOwners(email) VALUES ('jocko@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'muffin', 'muffin needs love!', 'muffin is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'cricket', 'cricket needs love!', 'cricket is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jocko@gmail.com', 'benson', 'benson needs love!', 'benson is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jocko@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jocko@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jocko@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jocko@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('burtie', 'burtie@gmail.com', 'A user of PCS', 'burtiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burtie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (231, 'burtie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'burtie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'burtie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'burtie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'burtie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burtie@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burtie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('ellary', 'ellary@gmail.com', 'A user of PCS', 'ellarypw');
INSERT INTO PetOwners(email) VALUES ('ellary@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellary@gmail.com', 'powder', 'powder needs love!', 'powder is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellary@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellary@gmail.com', 'hailey', 'hailey needs love!', 'hailey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('gerard', 'gerard@gmail.com', 'A user of PCS', 'gerardpw');
INSERT INTO PetOwners(email) VALUES ('gerard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'baby-doll', 'baby-doll needs love!', 'baby-doll is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'rin tin tin', 'rin tin tin needs love!', 'rin tin tin is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gerard@gmail.com', 'monster', 'monster needs love!', 'monster is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('imelda', 'imelda@gmail.com', 'A user of PCS', 'imeldapw');
INSERT INTO PetOwners(email) VALUES ('imelda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'chucky', 'chucky needs love!', 'chucky is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'norton', 'norton needs love!', 'norton is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'bobbie', 'bobbie needs love!', 'bobbie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'salem', 'salem needs love!', 'salem is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('imelda@gmail.com', 'grizzly', 'grizzly needs love!', 'grizzly is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('mattias', 'mattias@gmail.com', 'A user of PCS', 'mattiaspw');
INSERT INTO PetOwners(email) VALUES ('mattias@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mattias@gmail.com', 'rags', 'rags needs love!', 'rags is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('justino', 'justino@gmail.com', 'A user of PCS', 'justinopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('justino@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'justino@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'justino@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'justino@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('justino@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('alfonse', 'alfonse@gmail.com', 'A user of PCS', 'alfonsepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alfonse@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'alfonse@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (194, 'alfonse@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'alfonse@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alfonse@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alfonse@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('bond', 'bond@gmail.com', 'A user of PCS', 'bondpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bond@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bond@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bond@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bond@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bond@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('delaney', 'delaney@gmail.com', 'A user of PCS', 'delaneypw');
INSERT INTO PetOwners(email) VALUES ('delaney@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('delaney@gmail.com', 'sebastian', 'sebastian needs love!', 'sebastian is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('delaney@gmail.com', 'boy', 'boy needs love!', 'boy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('lee', 'lee@gmail.com', 'A user of PCS', 'leepw');
INSERT INTO PetOwners(email) VALUES ('lee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lee@gmail.com', 'dudley', 'dudley needs love!', 'dudley is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lee@gmail.com', 'charisma', 'charisma needs love!', 'charisma is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lee@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('winnah', 'winnah@gmail.com', 'A user of PCS', 'winnahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('winnah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'winnah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'winnah@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'winnah@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'winnah@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'winnah@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('winnah@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('winnah@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('tibold', 'tibold@gmail.com', 'A user of PCS', 'tiboldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tibold@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tibold@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'tibold@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'tibold@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tibold@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tibold@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('lucho', 'lucho@gmail.com', 'A user of PCS', 'luchopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucho@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (186, 'lucho@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'lucho@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'lucho@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'lucho@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (79, 'lucho@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lucho@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lucho@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('hazlett', 'hazlett@gmail.com', 'A user of PCS', 'hazlettpw');
INSERT INTO PetOwners(email) VALUES ('hazlett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'franky', 'franky needs love!', 'franky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'ralph', 'ralph needs love!', 'ralph is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hazlett@gmail.com', 'millie', 'millie needs love!', 'millie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('audry', 'audry@gmail.com', 'A user of PCS', 'audrypw');
INSERT INTO PetOwners(email) VALUES ('audry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('audry@gmail.com', 'copper', 'copper needs love!', 'copper is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('audry@gmail.com', 'gromit', 'gromit needs love!', 'gromit is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('coleman', 'coleman@gmail.com', 'A user of PCS', 'colemanpw');
INSERT INTO PetOwners(email) VALUES ('coleman@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('coleman@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('coleman@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'coleman@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'coleman@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'coleman@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coleman@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('paco', 'paco@gmail.com', 'A user of PCS', 'pacopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paco@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'paco@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'paco@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'paco@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (227, 'paco@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'paco@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('paco@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('paco@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('otto', 'otto@gmail.com', 'A user of PCS', 'ottopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('otto@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'otto@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'otto@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'otto@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'otto@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('otto@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('donielle', 'donielle@gmail.com', 'A user of PCS', 'doniellepw');
INSERT INTO PetOwners(email) VALUES ('donielle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donielle@gmail.com', 'mikey', 'mikey needs love!', 'mikey is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donielle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'donielle@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'donielle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'donielle@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donielle@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donielle@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('mayne', 'mayne@gmail.com', 'A user of PCS', 'maynepw');
INSERT INTO PetOwners(email) VALUES ('mayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mayne@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('christye', 'christye@gmail.com', 'A user of PCS', 'christyepw');
INSERT INTO PetOwners(email) VALUES ('christye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christye@gmail.com', 'bibbles', 'bibbles needs love!', 'bibbles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christye@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christye@gmail.com', 'bj', 'bj needs love!', 'bj is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christye@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'christye@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'christye@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'christye@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'christye@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('christye@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('dominga', 'dominga@gmail.com', 'A user of PCS', 'domingapw');
INSERT INTO PetOwners(email) VALUES ('dominga@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'megan', 'megan needs love!', 'megan is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dominga@gmail.com', 'mikey', 'mikey needs love!', 'mikey is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('carlee', 'carlee@gmail.com', 'A user of PCS', 'carleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carlee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'carlee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'carlee@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carlee@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('aundrea', 'aundrea@gmail.com', 'A user of PCS', 'aundreapw');
INSERT INTO PetOwners(email) VALUES ('aundrea@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aundrea@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aundrea@gmail.com', 'barney', 'barney needs love!', 'barney is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aundrea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'aundrea@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'aundrea@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'aundrea@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aundrea@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('aundrea@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('loy', 'loy@gmail.com', 'A user of PCS', 'loypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('loy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'loy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'loy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'loy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (244, 'loy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'loy@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('loy@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('nicoline', 'nicoline@gmail.com', 'A user of PCS', 'nicolinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nicoline@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'nicoline@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nicoline@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'nicoline@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicoline@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('therine', 'therine@gmail.com', 'A user of PCS', 'therinepw');
INSERT INTO PetOwners(email) VALUES ('therine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'noel', 'noel needs love!', 'noel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('therine@gmail.com', 'aj', 'aj needs love!', 'aj is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('shellie', 'shellie@gmail.com', 'A user of PCS', 'shelliepw');
INSERT INTO PetOwners(email) VALUES ('shellie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellie@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shellie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shellie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shellie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shellie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shellie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellie@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('trevor', 'trevor@gmail.com', 'A user of PCS', 'trevorpw');
INSERT INTO PetOwners(email) VALUES ('trevor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'nobel', 'nobel needs love!', 'nobel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'homer', 'homer needs love!', 'homer is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'macy', 'macy needs love!', 'macy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trevor@gmail.com', 'goober', 'goober needs love!', 'goober is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trevor@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'trevor@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'trevor@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'trevor@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trevor@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('eydie', 'eydie@gmail.com', 'A user of PCS', 'eydiepw');
INSERT INTO PetOwners(email) VALUES ('eydie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eydie@gmail.com', 'joy', 'joy needs love!', 'joy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eydie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'eydie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'eydie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'eydie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'eydie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eydie@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eydie@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('cassius', 'cassius@gmail.com', 'A user of PCS', 'cassiuspw');
INSERT INTO PetOwners(email) VALUES ('cassius@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassius@gmail.com', 'elliot', 'elliot needs love!', 'elliot is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassius@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (236, 'cassius@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'cassius@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cassius@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cassius@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cassius@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('rick', 'rick@gmail.com', 'A user of PCS', 'rickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rick@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'rick@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rick@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rick@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rick@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cesya', 'cesya@gmail.com', 'A user of PCS', 'cesyapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cesya@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cesya@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cesya@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cesya@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cesya@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cesya@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ryun', 'ryun@gmail.com', 'A user of PCS', 'ryunpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ryun@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'ryun@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'ryun@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'ryun@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'ryun@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ryun@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ryun@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('cora', 'cora@gmail.com', 'A user of PCS', 'corapw');
INSERT INTO PetOwners(email) VALUES ('cora@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cora@gmail.com', 'lucy', 'lucy needs love!', 'lucy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cora@gmail.com', 'belle', 'belle needs love!', 'belle is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cora@gmail.com', 'koda', 'koda needs love!', 'koda is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cora@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'cora@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cora@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cora@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('virgina', 'virgina@gmail.com', 'A user of PCS', 'virginapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('virgina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'virgina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'virgina@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('virgina@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('cathi', 'cathi@gmail.com', 'A user of PCS', 'cathipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cathi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'cathi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'cathi@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathi@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathi@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('trudi', 'trudi@gmail.com', 'A user of PCS', 'trudipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trudi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'trudi@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'trudi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'trudi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'trudi@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('trudi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('francklyn', 'francklyn@gmail.com', 'A user of PCS', 'francklynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francklyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'francklyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'francklyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'francklyn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'francklyn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'francklyn@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francklyn@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('valentine', 'valentine@gmail.com', 'A user of PCS', 'valentinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('valentine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'valentine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'valentine@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'valentine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'valentine@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('valentine@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('barde', 'barde@gmail.com', 'A user of PCS', 'bardepw');
INSERT INTO PetOwners(email) VALUES ('barde@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'macho', 'macho needs love!', 'macho is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'scout', 'scout needs love!', 'scout is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'pogo', 'pogo needs love!', 'pogo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barde@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('veda', 'veda@gmail.com', 'A user of PCS', 'vedapw');
INSERT INTO PetOwners(email) VALUES ('veda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'julius', 'julius needs love!', 'julius is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'kelsey', 'kelsey needs love!', 'kelsey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'augie', 'augie needs love!', 'augie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('veda@gmail.com', 'skippy', 'skippy needs love!', 'skippy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('ogden', 'ogden@gmail.com', 'A user of PCS', 'ogdenpw');
INSERT INTO PetOwners(email) VALUES ('ogden@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ogden@gmail.com', 'jackson', 'jackson needs love!', 'jackson is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ogden@gmail.com', 'kallie', 'kallie needs love!', 'kallie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ogden@gmail.com', 'jimmuy', 'jimmuy needs love!', 'jimmuy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('jermaine', 'jermaine@gmail.com', 'A user of PCS', 'jermainepw');
INSERT INTO PetOwners(email) VALUES ('jermaine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'ripley', 'ripley needs love!', 'ripley is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jermaine@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('marylinda', 'marylinda@gmail.com', 'A user of PCS', 'marylindapw');
INSERT INTO PetOwners(email) VALUES ('marylinda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'chic', 'chic needs love!', 'chic is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'brook', 'brook needs love!', 'brook is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'charles', 'charles needs love!', 'charles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marylinda@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marylinda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marylinda@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'marylinda@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marylinda@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'marylinda@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marylinda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('reilly', 'reilly@gmail.com', 'A user of PCS', 'reillypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reilly@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'reilly@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reilly@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reilly@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('meridel', 'meridel@gmail.com', 'A user of PCS', 'meridelpw');
INSERT INTO PetOwners(email) VALUES ('meridel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('meridel@gmail.com', 'patty', 'patty needs love!', 'patty is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('meridel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'meridel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'meridel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'meridel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'meridel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'meridel@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('meridel@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('krishnah', 'krishnah@gmail.com', 'A user of PCS', 'krishnahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krishnah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'krishnah@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krishnah@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krishnah@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ragnar', 'ragnar@gmail.com', 'A user of PCS', 'ragnarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ragnar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'ragnar@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ragnar@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ragnar@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('helli', 'helli@gmail.com', 'A user of PCS', 'hellipw');
INSERT INTO PetOwners(email) VALUES ('helli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('helli@gmail.com', 'mandi', 'mandi needs love!', 'mandi is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('dukey', 'dukey@gmail.com', 'A user of PCS', 'dukeypw');
INSERT INTO PetOwners(email) VALUES ('dukey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'bongo', 'bongo needs love!', 'bongo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dukey@gmail.com', 'skeeter', 'skeeter needs love!', 'skeeter is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dukey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dukey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dukey@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dukey@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('roseline', 'roseline@gmail.com', 'A user of PCS', 'roselinepw');
INSERT INTO PetOwners(email) VALUES ('roseline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'panda', 'panda needs love!', 'panda is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'mo', 'mo needs love!', 'mo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roseline@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('erin', 'erin@gmail.com', 'A user of PCS', 'erinpw');
INSERT INTO PetOwners(email) VALUES ('erin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erin@gmail.com', 'lynx', 'lynx needs love!', 'lynx is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'erin@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('erin@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('erin@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('sandro', 'sandro@gmail.com', 'A user of PCS', 'sandropw');
INSERT INTO PetOwners(email) VALUES ('sandro@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sandro@gmail.com', 'paco', 'paco needs love!', 'paco is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sandro@gmail.com', 'precious', 'precious needs love!', 'precious is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sandro@gmail.com', 'kirby', 'kirby needs love!', 'kirby is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sandro@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sandro@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sandro@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sandro@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('halie', 'halie@gmail.com', 'A user of PCS', 'haliepw');
INSERT INTO PetOwners(email) VALUES ('halie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'michael', 'michael needs love!', 'michael is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('halie@gmail.com', 'shady', 'shady needs love!', 'shady is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ollie', 'ollie@gmail.com', 'A user of PCS', 'olliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ollie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ollie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ollie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ollie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ollie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ollie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('nick', 'nick@gmail.com', 'A user of PCS', 'nickpw');
INSERT INTO PetOwners(email) VALUES ('nick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nick@gmail.com', 'red', 'red needs love!', 'red is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nick@gmail.com', 'patty', 'patty needs love!', 'patty is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nick@gmail.com', 'greta', 'greta needs love!', 'greta is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('taddeo', 'taddeo@gmail.com', 'A user of PCS', 'taddeopw');
INSERT INTO PetOwners(email) VALUES ('taddeo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('taddeo@gmail.com', 'duke', 'duke needs love!', 'duke is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('taddeo@gmail.com', 'barley', 'barley needs love!', 'barley is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('taddeo@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('taddeo@gmail.com', 'rolex', 'rolex needs love!', 'rolex is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('taddeo@gmail.com', 'ollie', 'ollie needs love!', 'ollie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('taddeo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'taddeo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'taddeo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'taddeo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'taddeo@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('taddeo@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('hewett', 'hewett@gmail.com', 'A user of PCS', 'hewettpw');
INSERT INTO PetOwners(email) VALUES ('hewett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'dutchess', 'dutchess needs love!', 'dutchess is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'freeway', 'freeway needs love!', 'freeway is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'hobbes', 'hobbes needs love!', 'hobbes is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hewett@gmail.com', 'peaches', 'peaches needs love!', 'peaches is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('xylia', 'xylia@gmail.com', 'A user of PCS', 'xyliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xylia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'xylia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'xylia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'xylia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (189, 'xylia@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xylia@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xylia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('patton', 'patton@gmail.com', 'A user of PCS', 'pattonpw');
INSERT INTO PetOwners(email) VALUES ('patton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patton@gmail.com', 'mariah', 'mariah needs love!', 'mariah is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patton@gmail.com', 'scooby-doo', 'scooby-doo needs love!', 'scooby-doo is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'patton@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'patton@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'patton@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'patton@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patton@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('patton@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('carlynn', 'carlynn@gmail.com', 'A user of PCS', 'carlynnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'carlynn@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlynn@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlynn@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('bealle', 'bealle@gmail.com', 'A user of PCS', 'beallepw');
INSERT INTO PetOwners(email) VALUES ('bealle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bealle@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bealle@gmail.com', 'boots', 'boots needs love!', 'boots is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bealle@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bealle@gmail.com', 'mason', 'mason needs love!', 'mason is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bealle@gmail.com', 'barnaby', 'barnaby needs love!', 'barnaby is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bealle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bealle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bealle@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bealle@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('christina', 'christina@gmail.com', 'A user of PCS', 'christinapw');
INSERT INTO PetOwners(email) VALUES ('christina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('christina@gmail.com', 'maximus', 'maximus needs love!', 'maximus is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('cello', 'cello@gmail.com', 'A user of PCS', 'cellopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cello@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'cello@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'cello@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'cello@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'cello@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cello@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('xenos', 'xenos@gmail.com', 'A user of PCS', 'xenospw');
INSERT INTO PetOwners(email) VALUES ('xenos@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'eddie', 'eddie needs love!', 'eddie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'magic', 'magic needs love!', 'magic is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'scoobie', 'scoobie needs love!', 'scoobie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xenos@gmail.com', 'rosa', 'rosa needs love!', 'rosa is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('merrielle', 'merrielle@gmail.com', 'A user of PCS', 'merriellepw');
INSERT INTO PetOwners(email) VALUES ('merrielle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'riley', 'riley needs love!', 'riley is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'gromit', 'gromit needs love!', 'gromit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merrielle@gmail.com', 'fresier', 'fresier needs love!', 'fresier is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('jandy', 'jandy@gmail.com', 'A user of PCS', 'jandypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jandy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jandy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jandy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jandy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jandy@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jandy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jo', 'jo@gmail.com', 'A user of PCS', 'jopw');
INSERT INTO PetOwners(email) VALUES ('jo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'itsy', 'itsy needs love!', 'itsy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jo@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'jo@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jo@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jo@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('wainwright', 'wainwright@gmail.com', 'A user of PCS', 'wainwrightpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wainwright@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wainwright@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wainwright@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'wainwright@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wainwright@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('pollyanna', 'pollyanna@gmail.com', 'A user of PCS', 'pollyannapw');
INSERT INTO PetOwners(email) VALUES ('pollyanna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pollyanna@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('marni', 'marni@gmail.com', 'A user of PCS', 'marnipw');
INSERT INTO PetOwners(email) VALUES ('marni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marni@gmail.com', 'phantom', 'phantom needs love!', 'phantom is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marni@gmail.com', 'silver', 'silver needs love!', 'silver is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marni@gmail.com', 'gigi', 'gigi needs love!', 'gigi is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marni@gmail.com', 'flint', 'flint needs love!', 'flint is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marni@gmail.com', 'porky', 'porky needs love!', 'porky is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'marni@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marni@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('manda', 'manda@gmail.com', 'A user of PCS', 'mandapw');
INSERT INTO PetOwners(email) VALUES ('manda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('manda@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('manda@gmail.com', 'bonnie', 'bonnie needs love!', 'bonnie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('manda@gmail.com', 'brit', 'brit needs love!', 'brit is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('manda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'manda@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'manda@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'manda@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'manda@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'manda@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('manda@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('rosana', 'rosana@gmail.com', 'A user of PCS', 'rosanapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rosana@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rosana@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('kathie', 'kathie@gmail.com', 'A user of PCS', 'kathiepw');
INSERT INTO PetOwners(email) VALUES ('kathie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kathie@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kathie@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kathie@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('lurette', 'lurette@gmail.com', 'A user of PCS', 'lurettepw');
INSERT INTO PetOwners(email) VALUES ('lurette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lurette@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lurette@gmail.com', 'missy', 'missy needs love!', 'missy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lurette@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('jessica', 'jessica@gmail.com', 'A user of PCS', 'jessicapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessica@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'jessica@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'jessica@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'jessica@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'jessica@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessica@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessica@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('lane', 'lane@gmail.com', 'A user of PCS', 'lanepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'lane@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lane@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lane@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('cortney', 'cortney@gmail.com', 'A user of PCS', 'cortneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cortney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cortney@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cortney@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cortney@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('willette', 'willette@gmail.com', 'A user of PCS', 'willettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'willette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'willette@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'willette@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'willette@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willette@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('murry', 'murry@gmail.com', 'A user of PCS', 'murrypw');
INSERT INTO PetOwners(email) VALUES ('murry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('murry@gmail.com', 'koda', 'koda needs love!', 'koda is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('murry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'murry@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'murry@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'murry@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'murry@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murry@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('murry@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ava', 'ava@gmail.com', 'A user of PCS', 'avapw');
INSERT INTO PetOwners(email) VALUES ('ava@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ava@gmail.com', 'sara', 'sara needs love!', 'sara is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('lauree', 'lauree@gmail.com', 'A user of PCS', 'laureepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lauree@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'lauree@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lauree@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lauree@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('alexander', 'alexander@gmail.com', 'A user of PCS', 'alexanderpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alexander@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'alexander@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (197, 'alexander@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alexander@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alexander@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alexander@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('kameko', 'kameko@gmail.com', 'A user of PCS', 'kamekopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kameko@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (233, 'kameko@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kameko@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kameko@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcellus', 'marcellus@gmail.com', 'A user of PCS', 'marcelluspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcellus@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'marcellus@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'marcellus@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (260, 'marcellus@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'marcellus@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcellus@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcellus@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('lamar', 'lamar@gmail.com', 'A user of PCS', 'lamarpw');
INSERT INTO PetOwners(email) VALUES ('lamar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lamar@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lamar@gmail.com', 'levi', 'levi needs love!', 'levi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lamar@gmail.com', 'judy', 'judy needs love!', 'judy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lamar@gmail.com', 'mikey', 'mikey needs love!', 'mikey is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('hatty', 'hatty@gmail.com', 'A user of PCS', 'hattypw');
INSERT INTO PetOwners(email) VALUES ('hatty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hatty@gmail.com', 'butterball', 'butterball needs love!', 'butterball is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hatty@gmail.com', 'adam', 'adam needs love!', 'adam is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('vivien', 'vivien@gmail.com', 'A user of PCS', 'vivienpw');
INSERT INTO PetOwners(email) VALUES ('vivien@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vivien@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vivien@gmail.com', 'gigi', 'gigi needs love!', 'gigi is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('graig', 'graig@gmail.com', 'A user of PCS', 'graigpw');
INSERT INTO PetOwners(email) VALUES ('graig@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('graig@gmail.com', 'curly', 'curly needs love!', 'curly is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('graig@gmail.com', 'newton', 'newton needs love!', 'newton is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('graig@gmail.com', 'nico', 'nico needs love!', 'nico is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('graig@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'graig@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'graig@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('graig@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('yoshiko', 'yoshiko@gmail.com', 'A user of PCS', 'yoshikopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yoshiko@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'yoshiko@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'yoshiko@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'yoshiko@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'yoshiko@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'yoshiko@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('yoshiko@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('latrena', 'latrena@gmail.com', 'A user of PCS', 'latrenapw');
INSERT INTO PetOwners(email) VALUES ('latrena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('latrena@gmail.com', 'gator', 'gator needs love!', 'gator is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('latrena@gmail.com', 'fido', 'fido needs love!', 'fido is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latrena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'latrena@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'latrena@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'latrena@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latrena@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latrena@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('osborne', 'osborne@gmail.com', 'A user of PCS', 'osbornepw');
INSERT INTO PetOwners(email) VALUES ('osborne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('osborne@gmail.com', 'crackers', 'crackers needs love!', 'crackers is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('osborne@gmail.com', 'nona', 'nona needs love!', 'nona is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('osborne@gmail.com', 'jesse', 'jesse needs love!', 'jesse is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('osborne@gmail.com', 'penny', 'penny needs love!', 'penny is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('osborne@gmail.com', 'lili', 'lili needs love!', 'lili is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('osborne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'osborne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'osborne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'osborne@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('osborne@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('minor', 'minor@gmail.com', 'A user of PCS', 'minorpw');
INSERT INTO PetOwners(email) VALUES ('minor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'mindy', 'mindy needs love!', 'mindy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'abbey', 'abbey needs love!', 'abbey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('minor@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('tallulah', 'tallulah@gmail.com', 'A user of PCS', 'tallulahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallulah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tallulah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'tallulah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (178, 'tallulah@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'tallulah@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'tallulah@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallulah@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallulah@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('kizzee', 'kizzee@gmail.com', 'A user of PCS', 'kizzeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kizzee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'kizzee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'kizzee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'kizzee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (234, 'kizzee@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kizzee@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kizzee@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('francyne', 'francyne@gmail.com', 'A user of PCS', 'francynepw');
INSERT INTO PetOwners(email) VALUES ('francyne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'moochie', 'moochie needs love!', 'moochie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'jackpot', 'jackpot needs love!', 'jackpot is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'puck', 'puck needs love!', 'puck is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francyne@gmail.com', 'ming', 'ming needs love!', 'ming is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('muriel', 'muriel@gmail.com', 'A user of PCS', 'murielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('muriel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (265, 'muriel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (244, 'muriel@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('muriel@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('muriel@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('babbette', 'babbette@gmail.com', 'A user of PCS', 'babbettepw');
INSERT INTO PetOwners(email) VALUES ('babbette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('babbette@gmail.com', 'grover', 'grover needs love!', 'grover is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('babbette@gmail.com', 'jasmine', 'jasmine needs love!', 'jasmine is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('babbette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'babbette@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'babbette@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'babbette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'babbette@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'babbette@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('babbette@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('bart', 'bart@gmail.com', 'A user of PCS', 'bartpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bart@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bart@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'bart@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bart@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('web', 'web@gmail.com', 'A user of PCS', 'webpw');
INSERT INTO PetOwners(email) VALUES ('web@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'leo', 'leo needs love!', 'leo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('web@gmail.com', 'jester', 'jester needs love!', 'jester is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('camilla', 'camilla@gmail.com', 'A user of PCS', 'camillapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camilla@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'camilla@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'camilla@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'camilla@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('camilla@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tomasine', 'tomasine@gmail.com', 'A user of PCS', 'tomasinepw');
INSERT INTO PetOwners(email) VALUES ('tomasine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'buck', 'buck needs love!', 'buck is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tomasine@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('wittie', 'wittie@gmail.com', 'A user of PCS', 'wittiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wittie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wittie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'wittie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wittie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wittie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('neville', 'neville@gmail.com', 'A user of PCS', 'nevillepw');
INSERT INTO PetOwners(email) VALUES ('neville@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('neville@gmail.com', 'bonnie', 'bonnie needs love!', 'bonnie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('abrahan', 'abrahan@gmail.com', 'A user of PCS', 'abrahanpw');
INSERT INTO PetOwners(email) VALUES ('abrahan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('abrahan@gmail.com', 'chester', 'chester needs love!', 'chester is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('kienan', 'kienan@gmail.com', 'A user of PCS', 'kienanpw');
INSERT INTO PetOwners(email) VALUES ('kienan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kienan@gmail.com', 'cody', 'cody needs love!', 'cody is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kienan@gmail.com', 'ollie', 'ollie needs love!', 'ollie is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kienan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kienan@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kienan@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kienan@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('yankee', 'yankee@gmail.com', 'A user of PCS', 'yankeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yankee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'yankee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'yankee@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'yankee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'yankee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'yankee@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yankee@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cinnamon', 'cinnamon@gmail.com', 'A user of PCS', 'cinnamonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cinnamon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'cinnamon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'cinnamon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cinnamon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cinnamon@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cinnamon@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('pail', 'pail@gmail.com', 'A user of PCS', 'pailpw');
INSERT INTO PetOwners(email) VALUES ('pail@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'audi', 'audi needs love!', 'audi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'emmy', 'emmy needs love!', 'emmy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pail@gmail.com', 'haley', 'haley needs love!', 'haley is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pail@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'pail@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'pail@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pail@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('clare', 'clare@gmail.com', 'A user of PCS', 'clarepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clare@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'clare@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clare@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clare@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('ira', 'ira@gmail.com', 'A user of PCS', 'irapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ira@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'ira@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'ira@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ira@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ira@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('red', 'red@gmail.com', 'A user of PCS', 'redpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('red@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'red@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('red@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('margery', 'margery@gmail.com', 'A user of PCS', 'margerypw');
INSERT INTO PetOwners(email) VALUES ('margery@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margery@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margery@gmail.com', 'clifford', 'clifford needs love!', 'clifford is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('margery@gmail.com', 'buffy', 'buffy needs love!', 'buffy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('timmie', 'timmie@gmail.com', 'A user of PCS', 'timmiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('timmie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'timmie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'timmie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'timmie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'timmie@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('timmie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('timmie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('urbain', 'urbain@gmail.com', 'A user of PCS', 'urbainpw');
INSERT INTO PetOwners(email) VALUES ('urbain@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('urbain@gmail.com', 'kibbles', 'kibbles needs love!', 'kibbles is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('urbain@gmail.com', 'nickers', 'nickers needs love!', 'nickers is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('urbain@gmail.com', 'angus', 'angus needs love!', 'angus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('urbain@gmail.com', 'clyde', 'clyde needs love!', 'clyde is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('urbain@gmail.com', 'fluffy', 'fluffy needs love!', 'fluffy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('sigfrid', 'sigfrid@gmail.com', 'A user of PCS', 'sigfridpw');
INSERT INTO PetOwners(email) VALUES ('sigfrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigfrid@gmail.com', 'harry', 'harry needs love!', 'harry is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigfrid@gmail.com', 'michael', 'michael needs love!', 'michael is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigfrid@gmail.com', 'peanut', 'peanut needs love!', 'peanut is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigfrid@gmail.com', 'macintosh', 'macintosh needs love!', 'macintosh is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('kimbell', 'kimbell@gmail.com', 'A user of PCS', 'kimbellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kimbell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kimbell@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kimbell@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kerri', 'kerri@gmail.com', 'A user of PCS', 'kerripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kerri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (211, 'kerri@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'kerri@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'kerri@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerri@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('ginevra', 'ginevra@gmail.com', 'A user of PCS', 'ginevrapw');
INSERT INTO PetOwners(email) VALUES ('ginevra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'piglet', 'piglet needs love!', 'piglet is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ginevra@gmail.com', 'niki', 'niki needs love!', 'niki is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ginevra@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'ginevra@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ginevra@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ginevra@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'ginevra@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'ginevra@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginevra@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ginevra@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('garvy', 'garvy@gmail.com', 'A user of PCS', 'garvypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garvy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'garvy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'garvy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'garvy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'garvy@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garvy@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garvy@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('jazmin', 'jazmin@gmail.com', 'A user of PCS', 'jazminpw');
INSERT INTO PetOwners(email) VALUES ('jazmin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'braggs', 'braggs needs love!', 'braggs is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'aries', 'aries needs love!', 'aries is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jazmin@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jazmin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'jazmin@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'jazmin@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jazmin@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jazmin@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('tanner', 'tanner@gmail.com', 'A user of PCS', 'tannerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tanner@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'tanner@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'tanner@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'tanner@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'tanner@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tanner@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tanner@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('mirabel', 'mirabel@gmail.com', 'A user of PCS', 'mirabelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mirabel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'mirabel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'mirabel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'mirabel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (232, 'mirabel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'mirabel@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mirabel@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mirabel@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('arley', 'arley@gmail.com', 'A user of PCS', 'arleypw');
INSERT INTO PetOwners(email) VALUES ('arley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arley@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'arley@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('arley@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('goran', 'goran@gmail.com', 'A user of PCS', 'goranpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('goran@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'goran@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('goran@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('goran@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ramon', 'ramon@gmail.com', 'A user of PCS', 'ramonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ramon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ramon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ramon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ramon@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ramon@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ruthann', 'ruthann@gmail.com', 'A user of PCS', 'ruthannpw');
INSERT INTO PetOwners(email) VALUES ('ruthann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ruthann@gmail.com', 'georgia', 'georgia needs love!', 'georgia is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ruthann@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ruthann@gmail.com', 'cha cha', 'cha cha needs love!', 'cha cha is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ruthann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ruthann@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ruthann@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ruthann@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ruthann@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ruthann@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('donnajean', 'donnajean@gmail.com', 'A user of PCS', 'donnajeanpw');
INSERT INTO PetOwners(email) VALUES ('donnajean@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'layla', 'layla needs love!', 'layla is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('donnajean@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donnajean@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'donnajean@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'donnajean@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnajean@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('donnajean@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('rudie', 'rudie@gmail.com', 'A user of PCS', 'rudiepw');
INSERT INTO PetOwners(email) VALUES ('rudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rudie@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('marwin', 'marwin@gmail.com', 'A user of PCS', 'marwinpw');
INSERT INTO PetOwners(email) VALUES ('marwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'isabella', 'isabella needs love!', 'isabella is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'darby', 'darby needs love!', 'darby is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'isabelle', 'isabelle needs love!', 'isabelle is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'mookie', 'mookie needs love!', 'mookie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marwin@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marwin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'marwin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marwin@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'marwin@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'marwin@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marwin@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('helen-elizabeth', 'helen-elizabeth@gmail.com', 'A user of PCS', 'helen-elizabethpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('helen-elizabeth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'helen-elizabeth@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'helen-elizabeth@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'helen-elizabeth@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'helen-elizabeth@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'helen-elizabeth@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('helen-elizabeth@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('sabrina', 'sabrina@gmail.com', 'A user of PCS', 'sabrinapw');
INSERT INTO PetOwners(email) VALUES ('sabrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sabrina@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sabrina@gmail.com', 'bits', 'bits needs love!', 'bits is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sabrina@gmail.com', 'mary', 'mary needs love!', 'mary is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sabrina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'sabrina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sabrina@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sabrina@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sabrina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tallie', 'tallie@gmail.com', 'A user of PCS', 'talliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tallie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'tallie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'tallie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'tallie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'tallie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'tallie@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallie@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tallie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('sybila', 'sybila@gmail.com', 'A user of PCS', 'sybilapw');
INSERT INTO PetOwners(email) VALUES ('sybila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sybila@gmail.com', 'chloe', 'chloe needs love!', 'chloe is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sybila@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sybila@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sybila@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sybila@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('brunhilda', 'brunhilda@gmail.com', 'A user of PCS', 'brunhildapw');
INSERT INTO PetOwners(email) VALUES ('brunhilda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brunhilda@gmail.com', 'chucky', 'chucky needs love!', 'chucky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brunhilda@gmail.com', 'bootie', 'bootie needs love!', 'bootie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brunhilda@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brunhilda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'brunhilda@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brunhilda@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('celinka', 'celinka@gmail.com', 'A user of PCS', 'celinkapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celinka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (279, 'celinka@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'celinka@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celinka@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('sutton', 'sutton@gmail.com', 'A user of PCS', 'suttonpw');
INSERT INTO PetOwners(email) VALUES ('sutton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'porter', 'porter needs love!', 'porter is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sutton@gmail.com', 'missy', 'missy needs love!', 'missy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('bendicty', 'bendicty@gmail.com', 'A user of PCS', 'bendictypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bendicty@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bendicty@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bendicty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'bendicty@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bendicty@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('kalila', 'kalila@gmail.com', 'A user of PCS', 'kalilapw');
INSERT INTO PetOwners(email) VALUES ('kalila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'megan', 'megan needs love!', 'megan is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'ryder', 'ryder needs love!', 'ryder is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'murphy', 'murphy needs love!', 'murphy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalila@gmail.com', 'moose', 'moose needs love!', 'moose is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('finn', 'finn@gmail.com', 'A user of PCS', 'finnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('finn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'finn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'finn@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('finn@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('finn@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('esther', 'esther@gmail.com', 'A user of PCS', 'estherpw');
INSERT INTO PetOwners(email) VALUES ('esther@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'chanel', 'chanel needs love!', 'chanel is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'holly', 'holly needs love!', 'holly is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'mariah', 'mariah needs love!', 'mariah is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('esther@gmail.com', 'brittany', 'brittany needs love!', 'brittany is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('charin', 'charin@gmail.com', 'A user of PCS', 'charinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'charin@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charin@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charin@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('gustaf', 'gustaf@gmail.com', 'A user of PCS', 'gustafpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gustaf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gustaf@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gustaf@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gustaf@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gustaf@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('julietta', 'julietta@gmail.com', 'A user of PCS', 'juliettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('julietta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'julietta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'julietta@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('julietta@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('julietta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('shamus', 'shamus@gmail.com', 'A user of PCS', 'shamuspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shamus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shamus@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'shamus@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'shamus@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shamus@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shamus@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('bride', 'bride@gmail.com', 'A user of PCS', 'bridepw');
INSERT INTO PetOwners(email) VALUES ('bride@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bride@gmail.com', 'banjo', 'banjo needs love!', 'banjo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bride@gmail.com', 'poochie', 'poochie needs love!', 'poochie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bride@gmail.com', 'max', 'max needs love!', 'max is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bride@gmail.com', 'cobweb', 'cobweb needs love!', 'cobweb is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('hollie', 'hollie@gmail.com', 'A user of PCS', 'holliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hollie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hollie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hollie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('cathlene', 'cathlene@gmail.com', 'A user of PCS', 'cathlenepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cathlene@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (208, 'cathlene@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (170, 'cathlene@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'cathlene@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'cathlene@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathlene@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cathlene@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('odelinda', 'odelinda@gmail.com', 'A user of PCS', 'odelindapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odelinda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'odelinda@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'odelinda@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'odelinda@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'odelinda@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'odelinda@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelinda@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('carlynne', 'carlynne@gmail.com', 'A user of PCS', 'carlynnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carlynne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carlynne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'carlynne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'carlynne@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'carlynne@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlynne@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carlynne@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('ciel', 'ciel@gmail.com', 'A user of PCS', 'cielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ciel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'ciel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'ciel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'ciel@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ciel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ciel@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('aylmer', 'aylmer@gmail.com', 'A user of PCS', 'aylmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aylmer@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'aylmer@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aylmer@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('constance', 'constance@gmail.com', 'A user of PCS', 'constancepw');
INSERT INTO PetOwners(email) VALUES ('constance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('constance@gmail.com', 'milo', 'milo needs love!', 'milo is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('constance@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'constance@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'constance@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'constance@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'constance@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('constance@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('constance@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferdie', 'ferdie@gmail.com', 'A user of PCS', 'ferdiepw');
INSERT INTO PetOwners(email) VALUES ('ferdie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdie@gmail.com', 'homer', 'homer needs love!', 'homer is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferdie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ferdie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('marina', 'marina@gmail.com', 'A user of PCS', 'marinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'marina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'marina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'marina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'marina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'marina@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marina@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marina@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('merilyn', 'merilyn@gmail.com', 'A user of PCS', 'merilynpw');
INSERT INTO PetOwners(email) VALUES ('merilyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merilyn@gmail.com', 'kayla', 'kayla needs love!', 'kayla is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merilyn@gmail.com', 'bugsy', 'bugsy needs love!', 'bugsy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merilyn@gmail.com', 'amos', 'amos needs love!', 'amos is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merilyn@gmail.com', 'ruffe', 'ruffe needs love!', 'ruffe is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merilyn@gmail.com', 'pepper', 'pepper needs love!', 'pepper is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('shelly', 'shelly@gmail.com', 'A user of PCS', 'shellypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shelly@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shelly@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shelly@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'shelly@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shelly@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shelly@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('siusan', 'siusan@gmail.com', 'A user of PCS', 'siusanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('siusan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'siusan@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('siusan@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('enrichetta', 'enrichetta@gmail.com', 'A user of PCS', 'enrichettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('enrichetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'enrichetta@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'enrichetta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'enrichetta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'enrichetta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'enrichetta@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('enrichetta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('estrella', 'estrella@gmail.com', 'A user of PCS', 'estrellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estrella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'estrella@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'estrella@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'estrella@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (216, 'estrella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'estrella@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estrella@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('estrella@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('rory', 'rory@gmail.com', 'A user of PCS', 'rorypw');
INSERT INTO PetOwners(email) VALUES ('rory@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rory@gmail.com', 'patches', 'patches needs love!', 'patches is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rory@gmail.com', 'amigo', 'amigo needs love!', 'amigo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rory@gmail.com', 'paddington', 'paddington needs love!', 'paddington is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rory@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('susi', 'susi@gmail.com', 'A user of PCS', 'susipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('susi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'susi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'susi@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('susi@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('neely', 'neely@gmail.com', 'A user of PCS', 'neelypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('neely@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'neely@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'neely@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'neely@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('neely@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('jorie', 'jorie@gmail.com', 'A user of PCS', 'joriepw');
INSERT INTO PetOwners(email) VALUES ('jorie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jorie@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jorie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'jorie@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorie@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorie@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('rubin', 'rubin@gmail.com', 'A user of PCS', 'rubinpw');
INSERT INTO PetOwners(email) VALUES ('rubin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rubin@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rubin@gmail.com', 'louis', 'louis needs love!', 'louis is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rubin@gmail.com', 'nico', 'nico needs love!', 'nico is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rubin@gmail.com', 'cha cha', 'cha cha needs love!', 'cha cha is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('ermin', 'ermin@gmail.com', 'A user of PCS', 'erminpw');
INSERT INTO PetOwners(email) VALUES ('ermin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ermin@gmail.com', 'bogey', 'bogey needs love!', 'bogey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ermin@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ermin@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ermin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ermin@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ermin@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ermin@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('carr', 'carr@gmail.com', 'A user of PCS', 'carrpw');
INSERT INTO PetOwners(email) VALUES ('carr@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carr@gmail.com', 'bella', 'bella needs love!', 'bella is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('tally', 'tally@gmail.com', 'A user of PCS', 'tallypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tally@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'tally@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tally@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tally@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jodee', 'jodee@gmail.com', 'A user of PCS', 'jodeepw');
INSERT INTO PetOwners(email) VALUES ('jodee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jodee@gmail.com', 'otto', 'otto needs love!', 'otto is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jodee@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('welch', 'welch@gmail.com', 'A user of PCS', 'welchpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('welch@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'welch@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'welch@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('welch@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('welch@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('janean', 'janean@gmail.com', 'A user of PCS', 'janeanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janean@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'janean@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'janean@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janean@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('janean@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('murdock', 'murdock@gmail.com', 'A user of PCS', 'murdockpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('murdock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'murdock@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'murdock@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'murdock@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'murdock@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'murdock@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('murdock@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('malorie', 'malorie@gmail.com', 'A user of PCS', 'maloriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('malorie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'malorie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'malorie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'malorie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('malorie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('sara-ann', 'sara-ann@gmail.com', 'A user of PCS', 'sara-annpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sara-ann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'sara-ann@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sara-ann@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sara-ann@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mariska', 'mariska@gmail.com', 'A user of PCS', 'mariskapw');
INSERT INTO PetOwners(email) VALUES ('mariska@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariska@gmail.com', 'dusty', 'dusty needs love!', 'dusty is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariska@gmail.com', 'frisky', 'frisky needs love!', 'frisky is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariska@gmail.com', 'clicker', 'clicker needs love!', 'clicker is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariska@gmail.com', 'georgie', 'georgie needs love!', 'georgie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariska@gmail.com', 'charmer', 'charmer needs love!', 'charmer is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('burgess', 'burgess@gmail.com', 'A user of PCS', 'burgesspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burgess@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'burgess@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'burgess@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'burgess@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'burgess@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'burgess@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('burgess@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('annadiana', 'annadiana@gmail.com', 'A user of PCS', 'annadianapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annadiana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'annadiana@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'annadiana@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'annadiana@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('annadiana@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('annadiana@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('robinia', 'robinia@gmail.com', 'A user of PCS', 'robiniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('robinia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'robinia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'robinia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'robinia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'robinia@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robinia@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('robinia@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('angelita', 'angelita@gmail.com', 'A user of PCS', 'angelitapw');
INSERT INTO PetOwners(email) VALUES ('angelita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('angelita@gmail.com', 'ruffer', 'ruffer needs love!', 'ruffer is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('angelita@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('olag', 'olag@gmail.com', 'A user of PCS', 'olagpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('olag@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'olag@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'olag@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'olag@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olag@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('nichole', 'nichole@gmail.com', 'A user of PCS', 'nicholepw');
INSERT INTO PetOwners(email) VALUES ('nichole@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nichole@gmail.com', 'parker', 'parker needs love!', 'parker is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nichole@gmail.com', 'nick', 'nick needs love!', 'nick is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nichole@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nichole@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nichole@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nichole@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'nichole@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nichole@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('bone', 'bone@gmail.com', 'A user of PCS', 'bonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bone@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bone@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'bone@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'bone@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bone@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('remy', 'remy@gmail.com', 'A user of PCS', 'remypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('remy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'remy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'remy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'remy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'remy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'remy@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('remy@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('gretel', 'gretel@gmail.com', 'A user of PCS', 'gretelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gretel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'gretel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (235, 'gretel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'gretel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'gretel@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gretel@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gretel@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('jaquenetta', 'jaquenetta@gmail.com', 'A user of PCS', 'jaquenettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaquenetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'jaquenetta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jaquenetta@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaquenetta@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('hillary', 'hillary@gmail.com', 'A user of PCS', 'hillarypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hillary@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hillary@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'hillary@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hillary@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hillary@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hillary@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hillary@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('wilton', 'wilton@gmail.com', 'A user of PCS', 'wiltonpw');
INSERT INTO PetOwners(email) VALUES ('wilton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'beetle', 'beetle needs love!', 'beetle is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'claire', 'claire needs love!', 'claire is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'peaches', 'peaches needs love!', 'peaches is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilton@gmail.com', 'boots', 'boots needs love!', 'boots is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'wilton@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'wilton@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'wilton@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'wilton@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'wilton@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilton@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wilton@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('philippe', 'philippe@gmail.com', 'A user of PCS', 'philippepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('philippe@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'philippe@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philippe@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('philippe@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('salomone', 'salomone@gmail.com', 'A user of PCS', 'salomonepw');
INSERT INTO PetOwners(email) VALUES ('salomone@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('salomone@gmail.com', 'cutie-pie', 'cutie-pie needs love!', 'cutie-pie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('salomone@gmail.com', 'heather', 'heather needs love!', 'heather is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('salomone@gmail.com', 'ming', 'ming needs love!', 'ming is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('salomone@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('kendell', 'kendell@gmail.com', 'A user of PCS', 'kendellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kendell@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kendell@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kendell@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kendell@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'kendell@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kendell@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kendell@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('chanda', 'chanda@gmail.com', 'A user of PCS', 'chandapw');
INSERT INTO PetOwners(email) VALUES ('chanda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chanda@gmail.com', 'curry', 'curry needs love!', 'curry is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('mallorie', 'mallorie@gmail.com', 'A user of PCS', 'malloriepw');
INSERT INTO PetOwners(email) VALUES ('mallorie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'jamie', 'jamie needs love!', 'jamie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'kismet', 'kismet needs love!', 'kismet is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'pedro', 'pedro needs love!', 'pedro is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mallorie@gmail.com', 'bosco', 'bosco needs love!', 'bosco is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mallorie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'mallorie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mallorie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'mallorie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mallorie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mallorie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('juditha', 'juditha@gmail.com', 'A user of PCS', 'judithapw');
INSERT INTO PetOwners(email) VALUES ('juditha@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juditha@gmail.com', 'hamlet', 'hamlet needs love!', 'hamlet is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juditha@gmail.com', 'maxwell', 'maxwell needs love!', 'maxwell is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juditha@gmail.com', 'silver', 'silver needs love!', 'silver is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juditha@gmail.com', 'brie', 'brie needs love!', 'brie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juditha@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('kris', 'kris@gmail.com', 'A user of PCS', 'krispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kris@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kris@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kris@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kris@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('candy', 'candy@gmail.com', 'A user of PCS', 'candypw');
INSERT INTO PetOwners(email) VALUES ('candy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('candy@gmail.com', 'papa', 'papa needs love!', 'papa is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('candy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'candy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'candy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'candy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'candy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'candy@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('candy@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('candy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('tyler', 'tyler@gmail.com', 'A user of PCS', 'tylerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tyler@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tyler@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tyler@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'tyler@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tyler@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tyler@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('wain', 'wain@gmail.com', 'A user of PCS', 'wainpw');
INSERT INTO PetOwners(email) VALUES ('wain@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'koty', 'koty needs love!', 'koty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'mia', 'mia needs love!', 'mia is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'ben', 'ben needs love!', 'ben is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wain@gmail.com', 'lili', 'lili needs love!', 'lili is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('sauncho', 'sauncho@gmail.com', 'A user of PCS', 'saunchopw');
INSERT INTO PetOwners(email) VALUES ('sauncho@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sauncho@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sauncho@gmail.com', 'dusty', 'dusty needs love!', 'dusty is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sauncho@gmail.com', 'chiquita', 'chiquita needs love!', 'chiquita is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sauncho@gmail.com', 'kallie', 'kallie needs love!', 'kallie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sauncho@gmail.com', 'mitzi', 'mitzi needs love!', 'mitzi is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('jeffry', 'jeffry@gmail.com', 'A user of PCS', 'jeffrypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeffry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'jeffry@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'jeffry@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'jeffry@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'jeffry@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeffry@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeffry@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('marian', 'marian@gmail.com', 'A user of PCS', 'marianpw');
INSERT INTO PetOwners(email) VALUES ('marian@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marian@gmail.com', 'roxie', 'roxie needs love!', 'roxie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marian@gmail.com', 'dodger', 'dodger needs love!', 'dodger is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marian@gmail.com', 'ruffe', 'ruffe needs love!', 'ruffe is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marian@gmail.com', 'shasta', 'shasta needs love!', 'shasta is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marian@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'marian@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'marian@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'marian@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marian@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marian@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('inglis', 'inglis@gmail.com', 'A user of PCS', 'inglispw');
INSERT INTO PetOwners(email) VALUES ('inglis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'doc', 'doc needs love!', 'doc is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inglis@gmail.com', 'aries', 'aries needs love!', 'aries is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('mitchael', 'mitchael@gmail.com', 'A user of PCS', 'mitchaelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitchael@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'mitchael@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'mitchael@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'mitchael@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'mitchael@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitchael@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mitchael@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('jacky', 'jacky@gmail.com', 'A user of PCS', 'jackypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jacky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'jacky@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'jacky@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'jacky@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'jacky@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jacky@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('erich', 'erich@gmail.com', 'A user of PCS', 'erichpw');
INSERT INTO PetOwners(email) VALUES ('erich@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erich@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erich@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'erich@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'erich@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'erich@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('erich@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('derrick', 'derrick@gmail.com', 'A user of PCS', 'derrickpw');
INSERT INTO PetOwners(email) VALUES ('derrick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'oreo', 'oreo needs love!', 'oreo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'barley', 'barley needs love!', 'barley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'cujo', 'cujo needs love!', 'cujo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('derrick@gmail.com', 'noel', 'noel needs love!', 'noel is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('derrick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'derrick@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'derrick@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('derrick@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('morgen', 'morgen@gmail.com', 'A user of PCS', 'morgenpw');
INSERT INTO PetOwners(email) VALUES ('morgen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'nina', 'nina needs love!', 'nina is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'guinness', 'guinness needs love!', 'guinness is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('morgen@gmail.com', 'edgar', 'edgar needs love!', 'edgar is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('morgen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'morgen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (204, 'morgen@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'morgen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'morgen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'morgen@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('morgen@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('morgen@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('federico', 'federico@gmail.com', 'A user of PCS', 'federicopw');
INSERT INTO PetOwners(email) VALUES ('federico@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'milo', 'milo needs love!', 'milo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'jewel', 'jewel needs love!', 'jewel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('federico@gmail.com', 'reilly', 'reilly needs love!', 'reilly is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('nickey', 'nickey@gmail.com', 'A user of PCS', 'nickeypw');
INSERT INTO PetOwners(email) VALUES ('nickey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'kipper', 'kipper needs love!', 'kipper is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'hardy', 'hardy needs love!', 'hardy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nickey@gmail.com', 'curry', 'curry needs love!', 'curry is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('margarete', 'margarete@gmail.com', 'A user of PCS', 'margaretepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margarete@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'margarete@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'margarete@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'margarete@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'margarete@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'margarete@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('margarete@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('tuck', 'tuck@gmail.com', 'A user of PCS', 'tuckpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tuck@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tuck@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tuck@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tuck@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tuck@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('phebe', 'phebe@gmail.com', 'A user of PCS', 'phebepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('phebe@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'phebe@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'phebe@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'phebe@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'phebe@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('phebe@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gayler', 'gayler@gmail.com', 'A user of PCS', 'gaylerpw');
INSERT INTO PetOwners(email) VALUES ('gayler@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'booker', 'booker needs love!', 'booker is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'digger', 'digger needs love!', 'digger is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'chaos', 'chaos needs love!', 'chaos is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gayler@gmail.com', 'daisey-mae', 'daisey-mae needs love!', 'daisey-mae is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gayler@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gayler@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gayler@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hyacinth', 'hyacinth@gmail.com', 'A user of PCS', 'hyacinthpw');
INSERT INTO PetOwners(email) VALUES ('hyacinth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hyacinth@gmail.com', 'silvester', 'silvester needs love!', 'silvester is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hyacinth@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('craig', 'craig@gmail.com', 'A user of PCS', 'craigpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('craig@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'craig@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (244, 'craig@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'craig@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'craig@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'craig@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('craig@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('craig@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('merv', 'merv@gmail.com', 'A user of PCS', 'mervpw');
INSERT INTO PetOwners(email) VALUES ('merv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'cassis', 'cassis needs love!', 'cassis is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'josie', 'josie needs love!', 'josie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('merv@gmail.com', 'presley', 'presley needs love!', 'presley is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('gwendolin', 'gwendolin@gmail.com', 'A user of PCS', 'gwendolinpw');
INSERT INTO PetOwners(email) VALUES ('gwendolin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'logan', 'logan needs love!', 'logan is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwendolin@gmail.com', 'nick', 'nick needs love!', 'nick is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwendolin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'gwendolin@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'gwendolin@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwendolin@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwendolin@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('doralynne', 'doralynne@gmail.com', 'A user of PCS', 'doralynnepw');
INSERT INTO PetOwners(email) VALUES ('doralynne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'heather', 'heather needs love!', 'heather is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'ruffe', 'ruffe needs love!', 'ruffe is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('doralynne@gmail.com', 'roland', 'roland needs love!', 'roland is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('doralynne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'doralynne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'doralynne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'doralynne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'doralynne@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('doralynne@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('clarey', 'clarey@gmail.com', 'A user of PCS', 'clareypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clarey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'clarey@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'clarey@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clarey@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jane', 'jane@gmail.com', 'A user of PCS', 'janepw');
INSERT INTO PetOwners(email) VALUES ('jane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'scoobie', 'scoobie needs love!', 'scoobie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'harpo', 'harpo needs love!', 'harpo is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'fiona', 'fiona needs love!', 'fiona is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'barker', 'barker needs love!', 'barker is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jane@gmail.com', 'hudson', 'hudson needs love!', 'hudson is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('steffi', 'steffi@gmail.com', 'A user of PCS', 'steffipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steffi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'steffi@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('steffi@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('steffi@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('darbee', 'darbee@gmail.com', 'A user of PCS', 'darbeepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darbee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'darbee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'darbee@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darbee@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('alyosha', 'alyosha@gmail.com', 'A user of PCS', 'alyoshapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alyosha@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'alyosha@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'alyosha@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alyosha@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('cordell', 'cordell@gmail.com', 'A user of PCS', 'cordellpw');
INSERT INTO PetOwners(email) VALUES ('cordell@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cordell@gmail.com', 'remy', 'remy needs love!', 'remy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cordell@gmail.com', 'kibbles', 'kibbles needs love!', 'kibbles is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cordell@gmail.com', 'charlie brown', 'charlie brown needs love!', 'charlie brown is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('dwayne', 'dwayne@gmail.com', 'A user of PCS', 'dwaynepw');
INSERT INTO PetOwners(email) VALUES ('dwayne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'oscar', 'oscar needs love!', 'oscar is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'benji', 'benji needs love!', 'benji is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dwayne@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('florida', 'florida@gmail.com', 'A user of PCS', 'floridapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('florida@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'florida@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'florida@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'florida@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'florida@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florida@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tine', 'tine@gmail.com', 'A user of PCS', 'tinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tine@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tine@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tine@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('emilie', 'emilie@gmail.com', 'A user of PCS', 'emiliepw');
INSERT INTO PetOwners(email) VALUES ('emilie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emilie@gmail.com', 'clancy', 'clancy needs love!', 'clancy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emilie@gmail.com', 'kato', 'kato needs love!', 'kato is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emilie@gmail.com', 'mouse', 'mouse needs love!', 'mouse is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('gaylord', 'gaylord@gmail.com', 'A user of PCS', 'gaylordpw');
INSERT INTO PetOwners(email) VALUES ('gaylord@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gaylord@gmail.com', 'black-jack', 'black-jack needs love!', 'black-jack is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gaylord@gmail.com', 'kosmo', 'kosmo needs love!', 'kosmo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gaylord@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gaylord@gmail.com', 'nibbles', 'nibbles needs love!', 'nibbles is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('gwennie', 'gwennie@gmail.com', 'A user of PCS', 'gwenniepw');
INSERT INTO PetOwners(email) VALUES ('gwennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'jesse james', 'jesse james needs love!', 'jesse james is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'destini', 'destini needs love!', 'destini is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gwennie@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwennie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (258, 'gwennie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'gwennie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gwennie@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwennie@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gwennie@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('maurizia', 'maurizia@gmail.com', 'A user of PCS', 'mauriziapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maurizia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'maurizia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'maurizia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'maurizia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'maurizia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'maurizia@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maurizia@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('kara', 'kara@gmail.com', 'A user of PCS', 'karapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'kara@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kara@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kara@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('waverly', 'waverly@gmail.com', 'A user of PCS', 'waverlypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('waverly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'waverly@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('waverly@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('gordon', 'gordon@gmail.com', 'A user of PCS', 'gordonpw');
INSERT INTO PetOwners(email) VALUES ('gordon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'midnight', 'midnight needs love!', 'midnight is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gordon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gordon@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gordon@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gordon@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gordon@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('niki', 'niki@gmail.com', 'A user of PCS', 'nikipw');
INSERT INTO PetOwners(email) VALUES ('niki@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'montgomery', 'montgomery needs love!', 'montgomery is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'ruffer', 'ruffer needs love!', 'ruffer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('niki@gmail.com', 'klaus', 'klaus needs love!', 'klaus is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('ketti', 'ketti@gmail.com', 'A user of PCS', 'kettipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ketti@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'ketti@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ketti@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ketti@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('janina', 'janina@gmail.com', 'A user of PCS', 'janinapw');
INSERT INTO PetOwners(email) VALUES ('janina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('janina@gmail.com', 'dragster', 'dragster needs love!', 'dragster is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('addy', 'addy@gmail.com', 'A user of PCS', 'addypw');
INSERT INTO PetOwners(email) VALUES ('addy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addy@gmail.com', 'nala', 'nala needs love!', 'nala is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addy@gmail.com', 'bosley', 'bosley needs love!', 'bosley is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addy@gmail.com', 'nina', 'nina needs love!', 'nina is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addy@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addy@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('addy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'addy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'addy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'addy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'addy@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('addy@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('addy@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('denise', 'denise@gmail.com', 'A user of PCS', 'denisepw');
INSERT INTO PetOwners(email) VALUES ('denise@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denise@gmail.com', 'simba', 'simba needs love!', 'simba is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denise@gmail.com', 'roxy', 'roxy needs love!', 'roxy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('denise@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ange', 'ange@gmail.com', 'A user of PCS', 'angepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ange@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ange@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ange@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ange@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ange@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ange@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('devin', 'devin@gmail.com', 'A user of PCS', 'devinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('devin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (216, 'devin@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('devin@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('rosamund', 'rosamund@gmail.com', 'A user of PCS', 'rosamundpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosamund@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'rosamund@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rosamund@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'rosamund@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'rosamund@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosamund@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosamund@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('nonah', 'nonah@gmail.com', 'A user of PCS', 'nonahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nonah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'nonah@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nonah@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('shannah', 'shannah@gmail.com', 'A user of PCS', 'shannahpw');
INSERT INTO PetOwners(email) VALUES ('shannah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'mckenzie', 'mckenzie needs love!', 'mckenzie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannah@gmail.com', 'otto', 'otto needs love!', 'otto is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('mariann', 'mariann@gmail.com', 'A user of PCS', 'mariannpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mariann@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mariann@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mariann@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariann@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('theobald', 'theobald@gmail.com', 'A user of PCS', 'theobaldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('theobald@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'theobald@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'theobald@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'theobald@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'theobald@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'theobald@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('theobald@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('nels', 'nels@gmail.com', 'A user of PCS', 'nelspw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nels@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nels@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'nels@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'nels@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'nels@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nels@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('hannah', 'hannah@gmail.com', 'A user of PCS', 'hannahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hannah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'hannah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'hannah@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'hannah@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hannah@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hannah@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('ginni', 'ginni@gmail.com', 'A user of PCS', 'ginnipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ginni@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ginni@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ginni@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ginni@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ginni@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ginni@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ginni@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dasie', 'dasie@gmail.com', 'A user of PCS', 'dasiepw');
INSERT INTO PetOwners(email) VALUES ('dasie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dasie@gmail.com', 'coal', 'coal needs love!', 'coal is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('alaster', 'alaster@gmail.com', 'A user of PCS', 'alasterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alaster@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alaster@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'alaster@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'alaster@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'alaster@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alaster@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('juliette', 'juliette@gmail.com', 'A user of PCS', 'juliettepw');
INSERT INTO PetOwners(email) VALUES ('juliette@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliette@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliette@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliette@gmail.com', 'amy', 'amy needs love!', 'amy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('michal', 'michal@gmail.com', 'A user of PCS', 'michalpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michal@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'michal@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'michal@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'michal@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michal@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('michal@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('burr', 'burr@gmail.com', 'A user of PCS', 'burrpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burr@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'burr@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burr@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burr@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('olivero', 'olivero@gmail.com', 'A user of PCS', 'oliveropw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('olivero@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'olivero@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'olivero@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'olivero@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'olivero@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'olivero@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('olivero@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('page', 'page@gmail.com', 'A user of PCS', 'pagepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('page@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'page@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'page@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'page@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('page@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('thorn', 'thorn@gmail.com', 'A user of PCS', 'thornpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('thorn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'thorn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'thorn@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('thorn@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('rik', 'rik@gmail.com', 'A user of PCS', 'rikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rik@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rik@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rik@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rik@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rik@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('nerita', 'nerita@gmail.com', 'A user of PCS', 'neritapw');
INSERT INTO PetOwners(email) VALUES ('nerita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerita@gmail.com', 'harley', 'harley needs love!', 'harley is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nerita@gmail.com', 'nickie', 'nickie needs love!', 'nickie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('aldridge', 'aldridge@gmail.com', 'A user of PCS', 'aldridgepw');
INSERT INTO PetOwners(email) VALUES ('aldridge@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aldridge@gmail.com', 'miles', 'miles needs love!', 'miles is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aldridge@gmail.com', 'nico', 'nico needs love!', 'nico is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aldridge@gmail.com', 'dharma', 'dharma needs love!', 'dharma is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ilka', 'ilka@gmail.com', 'A user of PCS', 'ilkapw');
INSERT INTO PetOwners(email) VALUES ('ilka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'harpo', 'harpo needs love!', 'harpo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'chyna', 'chyna needs love!', 'chyna is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ilka@gmail.com', 'pockets', 'pockets needs love!', 'pockets is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ilka@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'ilka@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'ilka@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'ilka@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'ilka@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ilka@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ilka@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('inness', 'inness@gmail.com', 'A user of PCS', 'innesspw');
INSERT INTO PetOwners(email) VALUES ('inness@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'nickers', 'nickers needs love!', 'nickers is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'daisey-mae', 'daisey-mae needs love!', 'daisey-mae is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'flake', 'flake needs love!', 'flake is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'petie', 'petie needs love!', 'petie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('inness@gmail.com', 'noodles', 'noodles needs love!', 'noodles is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('inness@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'inness@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'inness@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('inness@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('inness@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('reine', 'reine@gmail.com', 'A user of PCS', 'reinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'reine@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'reine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'reine@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'reine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'reine@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reine@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reine@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('guendolen', 'guendolen@gmail.com', 'A user of PCS', 'guendolenpw');
INSERT INTO PetOwners(email) VALUES ('guendolen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('guendolen@gmail.com', 'birdie', 'birdie needs love!', 'birdie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('guendolen@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('guendolen@gmail.com', 'dante', 'dante needs love!', 'dante is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('guendolen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'guendolen@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('guendolen@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('guendolen@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('deena', 'deena@gmail.com', 'A user of PCS', 'deenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'deena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'deena@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'deena@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deena@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('nicolai', 'nicolai@gmail.com', 'A user of PCS', 'nicolaipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nicolai@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nicolai@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'nicolai@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'nicolai@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'nicolai@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nicolai@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('maximo', 'maximo@gmail.com', 'A user of PCS', 'maximopw');
INSERT INTO PetOwners(email) VALUES ('maximo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maximo@gmail.com', 'brit', 'brit needs love!', 'brit is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maximo@gmail.com', 'augie', 'augie needs love!', 'augie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('melosa', 'melosa@gmail.com', 'A user of PCS', 'melosapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('melosa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'melosa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'melosa@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'melosa@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'melosa@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('melosa@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('melva', 'melva@gmail.com', 'A user of PCS', 'melvapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('melva@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'melva@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('melva@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('melva@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('carleton', 'carleton@gmail.com', 'A user of PCS', 'carletonpw');
INSERT INTO PetOwners(email) VALUES ('carleton@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carleton@gmail.com', 'ellie', 'ellie needs love!', 'ellie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carleton@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carleton@gmail.com', 'honey-bear', 'honey-bear needs love!', 'honey-bear is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carleton@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carleton@gmail.com', 'pooh-bear', 'pooh-bear needs love!', 'pooh-bear is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carleton@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'carleton@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'carleton@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'carleton@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'carleton@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carleton@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carleton@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('johnath', 'johnath@gmail.com', 'A user of PCS', 'johnathpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('johnath@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'johnath@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (181, 'johnath@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'johnath@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'johnath@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'johnath@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('johnath@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('johnath@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('zonda', 'zonda@gmail.com', 'A user of PCS', 'zondapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zonda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (275, 'zonda@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'zonda@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'zonda@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'zonda@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zonda@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zonda@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('lonnie', 'lonnie@gmail.com', 'A user of PCS', 'lonniepw');
INSERT INTO PetOwners(email) VALUES ('lonnie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lonnie@gmail.com', 'leo', 'leo needs love!', 'leo is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lonnie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lonnie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lonnie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'lonnie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lonnie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lonnie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lonnie@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('selig', 'selig@gmail.com', 'A user of PCS', 'seligpw');
INSERT INTO PetOwners(email) VALUES ('selig@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('selig@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('adel', 'adel@gmail.com', 'A user of PCS', 'adelpw');
INSERT INTO PetOwners(email) VALUES ('adel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adel@gmail.com', 'gringo', 'gringo needs love!', 'gringo is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'adel@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'adel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'adel@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adel@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('willy', 'willy@gmail.com', 'A user of PCS', 'willypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'willy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'willy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'willy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'willy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'willy@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willy@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('antone', 'antone@gmail.com', 'A user of PCS', 'antonepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antone@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'antone@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'antone@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'antone@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'antone@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'antone@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antone@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('lazar', 'lazar@gmail.com', 'A user of PCS', 'lazarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lazar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'lazar@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lazar@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('flynn', 'flynn@gmail.com', 'A user of PCS', 'flynnpw');
INSERT INTO PetOwners(email) VALUES ('flynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('flynn@gmail.com', 'isabelle', 'isabelle needs love!', 'isabelle is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('flynn@gmail.com', 'cocoa', 'cocoa needs love!', 'cocoa is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('flynn@gmail.com', 'fido', 'fido needs love!', 'fido is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('flynn@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('flynn@gmail.com', 'cozmo', 'cozmo needs love!', 'cozmo is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('jewel', 'jewel@gmail.com', 'A user of PCS', 'jewelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jewel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (225, 'jewel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'jewel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'jewel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'jewel@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jewel@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jewel@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('ingaberg', 'ingaberg@gmail.com', 'A user of PCS', 'ingabergpw');
INSERT INTO PetOwners(email) VALUES ('ingaberg@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ingaberg@gmail.com', 'goober', 'goober needs love!', 'goober is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('marcia', 'marcia@gmail.com', 'A user of PCS', 'marciapw');
INSERT INTO PetOwners(email) VALUES ('marcia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcia@gmail.com', 'belle', 'belle needs love!', 'belle is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcia@gmail.com', 'gavin', 'gavin needs love!', 'gavin is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcia@gmail.com', 'skippy', 'skippy needs love!', 'skippy is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('renee', 'renee@gmail.com', 'A user of PCS', 'reneepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('renee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'renee@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('renee@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('renee@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('bertina', 'bertina@gmail.com', 'A user of PCS', 'bertinapw');
INSERT INTO PetOwners(email) VALUES ('bertina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertina@gmail.com', 'friday', 'friday needs love!', 'friday is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertina@gmail.com', 'barney', 'barney needs love!', 'barney is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertina@gmail.com', 'mulligan', 'mulligan needs love!', 'mulligan is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertina@gmail.com', 'jesse james', 'jesse james needs love!', 'jesse james is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bertina@gmail.com', 'scottie', 'scottie needs love!', 'scottie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bertina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'bertina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (161, 'bertina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'bertina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'bertina@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'bertina@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bertina@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bertina@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shara', 'shara@gmail.com', 'A user of PCS', 'sharapw');
INSERT INTO PetOwners(email) VALUES ('shara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'emily', 'emily needs love!', 'emily is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'obie', 'obie needs love!', 'obie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shara@gmail.com', 'mulligan', 'mulligan needs love!', 'mulligan is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shara@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shara@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shara@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('shayla', 'shayla@gmail.com', 'A user of PCS', 'shaylapw');
INSERT INTO PetOwners(email) VALUES ('shayla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shayla@gmail.com', 'hailey', 'hailey needs love!', 'hailey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shayla@gmail.com', 'fritz', 'fritz needs love!', 'fritz is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shayla@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shayla@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shayla@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'shayla@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shayla@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('charlotte', 'charlotte@gmail.com', 'A user of PCS', 'charlottepw');
INSERT INTO PetOwners(email) VALUES ('charlotte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'ozzie', 'ozzie needs love!', 'ozzie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'cotton', 'cotton needs love!', 'cotton is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'beetle', 'beetle needs love!', 'beetle is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlotte@gmail.com', 'jordan', 'jordan needs love!', 'jordan is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charlotte@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (184, 'charlotte@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'charlotte@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (228, 'charlotte@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (255, 'charlotte@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'charlotte@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charlotte@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charlotte@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('maryl', 'maryl@gmail.com', 'A user of PCS', 'marylpw');
INSERT INTO PetOwners(email) VALUES ('maryl@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryl@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maryl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'maryl@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'maryl@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maryl@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('ferrel', 'ferrel@gmail.com', 'A user of PCS', 'ferrelpw');
INSERT INTO PetOwners(email) VALUES ('ferrel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'coal', 'coal needs love!', 'coal is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferrel@gmail.com', 'pebbles', 'pebbles needs love!', 'pebbles is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferrel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'ferrel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (163, 'ferrel@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferrel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ferrel@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('nadine', 'nadine@gmail.com', 'A user of PCS', 'nadinepw');
INSERT INTO PetOwners(email) VALUES ('nadine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'bodie', 'bodie needs love!', 'bodie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'reilly', 'reilly needs love!', 'reilly is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'olivia', 'olivia needs love!', 'olivia is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nadine@gmail.com', 'axle', 'axle needs love!', 'axle is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('alex', 'alex@gmail.com', 'A user of PCS', 'alexpw');
INSERT INTO PetOwners(email) VALUES ('alex@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'newton', 'newton needs love!', 'newton is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'cinnamon', 'cinnamon needs love!', 'cinnamon is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'nathan', 'nathan needs love!', 'nathan is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'pablo', 'pablo needs love!', 'pablo is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alex@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'alex@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'alex@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'alex@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'alex@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'alex@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('giordano', 'giordano@gmail.com', 'A user of PCS', 'giordanopw');
INSERT INTO PetOwners(email) VALUES ('giordano@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giordano@gmail.com', 'reggie', 'reggie needs love!', 'reggie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giordano@gmail.com', 'boss', 'boss needs love!', 'boss is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giordano@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('jaime', 'jaime@gmail.com', 'A user of PCS', 'jaimepw');
INSERT INTO PetOwners(email) VALUES ('jaime@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'cheyenne', 'cheyenne needs love!', 'cheyenne is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'shelly', 'shelly needs love!', 'shelly is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'norton', 'norton needs love!', 'norton is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaime@gmail.com', 'kasey', 'kasey needs love!', 'kasey is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaime@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jaime@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jaime@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaime@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('carrol', 'carrol@gmail.com', 'A user of PCS', 'carrolpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrol@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carrol@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'carrol@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'carrol@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'carrol@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carrol@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('sunny', 'sunny@gmail.com', 'A user of PCS', 'sunnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sunny@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'sunny@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'sunny@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sunny@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sunny@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('liva', 'liva@gmail.com', 'A user of PCS', 'livapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('liva@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'liva@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('liva@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('bail', 'bail@gmail.com', 'A user of PCS', 'bailpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bail@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'bail@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bail@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bail@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('shurlock', 'shurlock@gmail.com', 'A user of PCS', 'shurlockpw');
INSERT INTO PetOwners(email) VALUES ('shurlock@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'simone', 'simone needs love!', 'simone is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'charmer', 'charmer needs love!', 'charmer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shurlock@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shurlock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'shurlock@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'shurlock@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shurlock@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlock@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('yule', 'yule@gmail.com', 'A user of PCS', 'yulepw');
INSERT INTO PetOwners(email) VALUES ('yule@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yule@gmail.com', 'chase', 'chase needs love!', 'chase is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('allsun', 'allsun@gmail.com', 'A user of PCS', 'allsunpw');
INSERT INTO PetOwners(email) VALUES ('allsun@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'gromit', 'gromit needs love!', 'gromit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('allsun@gmail.com', 'curly', 'curly needs love!', 'curly is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('allsun@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'allsun@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('allsun@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('allsun@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('kennett', 'kennett@gmail.com', 'A user of PCS', 'kennettpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennett@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kennett@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kennett@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kennett@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kennett@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kennett@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('birgit', 'birgit@gmail.com', 'A user of PCS', 'birgitpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('birgit@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'birgit@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'birgit@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'birgit@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'birgit@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'birgit@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('birgit@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('birgit@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('giana', 'giana@gmail.com', 'A user of PCS', 'gianapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giana@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'giana@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giana@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giana@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('zach', 'zach@gmail.com', 'A user of PCS', 'zachpw');
INSERT INTO PetOwners(email) VALUES ('zach@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'salty', 'salty needs love!', 'salty is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'bella', 'bella needs love!', 'bella is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'pierre', 'pierre needs love!', 'pierre is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zach@gmail.com', 'laney', 'laney needs love!', 'laney is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('blisse', 'blisse@gmail.com', 'A user of PCS', 'blissepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('blisse@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'blisse@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'blisse@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'blisse@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('blisse@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('farlie', 'farlie@gmail.com', 'A user of PCS', 'farliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farlie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'farlie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farlie@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farlie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('brennen', 'brennen@gmail.com', 'A user of PCS', 'brennenpw');
INSERT INTO PetOwners(email) VALUES ('brennen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brennen@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brennen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'brennen@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brennen@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brennen@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('mitch', 'mitch@gmail.com', 'A user of PCS', 'mitchpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mitch@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'mitch@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mitch@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'mitch@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mitch@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('geri', 'geri@gmail.com', 'A user of PCS', 'geripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('geri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'geri@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'geri@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'geri@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'geri@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'geri@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('geri@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('marcelo', 'marcelo@gmail.com', 'A user of PCS', 'marcelopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcelo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'marcelo@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'marcelo@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (230, 'marcelo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'marcelo@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'marcelo@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcelo@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marcelo@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('maryanna', 'maryanna@gmail.com', 'A user of PCS', 'maryannapw');
INSERT INTO PetOwners(email) VALUES ('maryanna@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryanna@gmail.com', 'beamer', 'beamer needs love!', 'beamer is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maryanna@gmail.com', 'astro', 'astro needs love!', 'astro is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('boonie', 'boonie@gmail.com', 'A user of PCS', 'booniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boonie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'boonie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'boonie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'boonie@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boonie@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('boonie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dosi', 'dosi@gmail.com', 'A user of PCS', 'dosipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dosi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dosi@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dosi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('maxy', 'maxy@gmail.com', 'A user of PCS', 'maxypw');
INSERT INTO PetOwners(email) VALUES ('maxy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maxy@gmail.com', 'louis', 'louis needs love!', 'louis is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maxy@gmail.com', 'adam', 'adam needs love!', 'adam is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maxy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'maxy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'maxy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'maxy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'maxy@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maxy@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('tedman', 'tedman@gmail.com', 'A user of PCS', 'tedmanpw');
INSERT INTO PetOwners(email) VALUES ('tedman@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'bits', 'bits needs love!', 'bits is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'cherokee', 'cherokee needs love!', 'cherokee is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tedman@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tedman@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (204, 'tedman@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'tedman@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'tedman@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'tedman@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'tedman@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tedman@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tedman@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('gilly', 'gilly@gmail.com', 'A user of PCS', 'gillypw');
INSERT INTO PetOwners(email) VALUES ('gilly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'ivy', 'ivy needs love!', 'ivy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'mason', 'mason needs love!', 'mason is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilly@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gilly@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gilly@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gilly@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gilly@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('trstram', 'trstram@gmail.com', 'A user of PCS', 'trstrampw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('trstram@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'trstram@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'trstram@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'trstram@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'trstram@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trstram@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('trstram@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('sigismund', 'sigismund@gmail.com', 'A user of PCS', 'sigismundpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigismund@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'sigismund@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sigismund@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'sigismund@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'sigismund@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'sigismund@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigismund@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sigismund@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('cherri', 'cherri@gmail.com', 'A user of PCS', 'cherripw');
INSERT INTO PetOwners(email) VALUES ('cherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'lili', 'lili needs love!', 'lili is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'domino', 'domino needs love!', 'domino is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'buckeye', 'buckeye needs love!', 'buckeye is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cherri@gmail.com', 'comet', 'comet needs love!', 'comet is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('lannie', 'lannie@gmail.com', 'A user of PCS', 'lanniepw');
INSERT INTO PetOwners(email) VALUES ('lannie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'budda', 'budda needs love!', 'budda is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'amos', 'amos needs love!', 'amos is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'cleopatra', 'cleopatra needs love!', 'cleopatra is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lannie@gmail.com', 'rico', 'rico needs love!', 'rico is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('rodney', 'rodney@gmail.com', 'A user of PCS', 'rodneypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rodney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'rodney@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rodney@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rodney@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rodney@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ferdy', 'ferdy@gmail.com', 'A user of PCS', 'ferdypw');
INSERT INTO PetOwners(email) VALUES ('ferdy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdy@gmail.com', 'scout', 'scout needs love!', 'scout is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdy@gmail.com', 'deacon', 'deacon needs love!', 'deacon is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ferdy@gmail.com', 'jingles', 'jingles needs love!', 'jingles is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('abram', 'abram@gmail.com', 'A user of PCS', 'abrampw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abram@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'abram@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'abram@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'abram@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'abram@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'abram@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abram@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('hasheem', 'hasheem@gmail.com', 'A user of PCS', 'hasheempw');
INSERT INTO PetOwners(email) VALUES ('hasheem@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hasheem@gmail.com', 'jester', 'jester needs love!', 'jester is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hasheem@gmail.com', 'bart', 'bart needs love!', 'bart is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hasheem@gmail.com', 'fresier', 'fresier needs love!', 'fresier is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('hortense', 'hortense@gmail.com', 'A user of PCS', 'hortensepw');
INSERT INTO PetOwners(email) VALUES ('hortense@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'rhett', 'rhett needs love!', 'rhett is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'pockets', 'pockets needs love!', 'pockets is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'big foot', 'big foot needs love!', 'big foot is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hortense@gmail.com', 'jester', 'jester needs love!', 'jester is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hortense@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hortense@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hortense@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hortense@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hortense@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('bil', 'bil@gmail.com', 'A user of PCS', 'bilpw');
INSERT INTO PetOwners(email) VALUES ('bil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bil@gmail.com', 'brady', 'brady needs love!', 'brady is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bil@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bil@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('germana', 'germana@gmail.com', 'A user of PCS', 'germanapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('germana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'germana@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'germana@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'germana@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germana@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('rosmunda', 'rosmunda@gmail.com', 'A user of PCS', 'rosmundapw');
INSERT INTO PetOwners(email) VALUES ('rosmunda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'bogey', 'bogey needs love!', 'bogey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'booker', 'booker needs love!', 'booker is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rosmunda@gmail.com', 'petie', 'petie needs love!', 'petie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rosmunda@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'rosmunda@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosmunda@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rosmunda@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('myrvyn', 'myrvyn@gmail.com', 'A user of PCS', 'myrvynpw');
INSERT INTO PetOwners(email) VALUES ('myrvyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'moonshine', 'moonshine needs love!', 'moonshine is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'karma', 'karma needs love!', 'karma is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('myrvyn@gmail.com', 'braggs', 'braggs needs love!', 'braggs is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('wallis', 'wallis@gmail.com', 'A user of PCS', 'wallispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wallis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wallis@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'wallis@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wallis@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('elnar', 'elnar@gmail.com', 'A user of PCS', 'elnarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elnar@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'elnar@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'elnar@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elnar@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('jessey', 'jessey@gmail.com', 'A user of PCS', 'jesseypw');
INSERT INTO PetOwners(email) VALUES ('jessey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessey@gmail.com', 'merlin', 'merlin needs love!', 'merlin is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessey@gmail.com', 'pokey', 'pokey needs love!', 'pokey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessey@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessey@gmail.com', 'gabriella', 'gabriella needs love!', 'gabriella is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jessey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'jessey@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessey@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jessey@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('dannie', 'dannie@gmail.com', 'A user of PCS', 'danniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dannie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'dannie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'dannie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'dannie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dannie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dannie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('reid', 'reid@gmail.com', 'A user of PCS', 'reidpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'reid@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'reid@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'reid@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'reid@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('reid@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('robinet', 'robinet@gmail.com', 'A user of PCS', 'robinetpw');
INSERT INTO PetOwners(email) VALUES ('robinet@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinet@gmail.com', 'rock', 'rock needs love!', 'rock is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robinet@gmail.com', 'itsy-bitsy', 'itsy-bitsy needs love!', 'itsy-bitsy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('haywood', 'haywood@gmail.com', 'A user of PCS', 'haywoodpw');
INSERT INTO PetOwners(email) VALUES ('haywood@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'blue', 'blue needs love!', 'blue is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'lily', 'lily needs love!', 'lily is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'allie', 'allie needs love!', 'allie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haywood@gmail.com', 'smarty', 'smarty needs love!', 'smarty is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('oralle', 'oralle@gmail.com', 'A user of PCS', 'orallepw');
INSERT INTO PetOwners(email) VALUES ('oralle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oralle@gmail.com', 'sly', 'sly needs love!', 'sly is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oralle@gmail.com', 'pooky', 'pooky needs love!', 'pooky is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('irwinn', 'irwinn@gmail.com', 'A user of PCS', 'irwinnpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('irwinn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'irwinn@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'irwinn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'irwinn@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('irwinn@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('eddy', 'eddy@gmail.com', 'A user of PCS', 'eddypw');
INSERT INTO PetOwners(email) VALUES ('eddy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'slinky', 'slinky needs love!', 'slinky is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'jasmine', 'jasmine needs love!', 'jasmine is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eddy@gmail.com', 'angus', 'angus needs love!', 'angus is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eddy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (246, 'eddy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'eddy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (182, 'eddy@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddy@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddy@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('adolpho', 'adolpho@gmail.com', 'A user of PCS', 'adolphopw');
INSERT INTO PetOwners(email) VALUES ('adolpho@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adolpho@gmail.com', 'godiva', 'godiva needs love!', 'godiva is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolpho@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'adolpho@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'adolpho@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'adolpho@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolpho@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('selestina', 'selestina@gmail.com', 'A user of PCS', 'selestinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('selestina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'selestina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'selestina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'selestina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'selestina@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('selestina@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('quent', 'quent@gmail.com', 'A user of PCS', 'quentpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('quent@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'quent@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'quent@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('quent@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('quent@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorrie', 'dorrie@gmail.com', 'A user of PCS', 'dorriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dorrie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorrie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('gretta', 'gretta@gmail.com', 'A user of PCS', 'grettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gretta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gretta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gretta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gretta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gretta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gretta@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretta@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('wake', 'wake@gmail.com', 'A user of PCS', 'wakepw');
INSERT INTO PetOwners(email) VALUES ('wake@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wake@gmail.com', 'dandy', 'dandy needs love!', 'dandy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('katrinka', 'katrinka@gmail.com', 'A user of PCS', 'katrinkapw');
INSERT INTO PetOwners(email) VALUES ('katrinka@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katrinka@gmail.com', 'pedro', 'pedro needs love!', 'pedro is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('katrinka@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('andrus', 'andrus@gmail.com', 'A user of PCS', 'andruspw');
INSERT INTO PetOwners(email) VALUES ('andrus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'bj', 'bj needs love!', 'bj is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'paris', 'paris needs love!', 'paris is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'pookie', 'pookie needs love!', 'pookie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrus@gmail.com', 'dragster', 'dragster needs love!', 'dragster is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('karia', 'karia@gmail.com', 'A user of PCS', 'kariapw');
INSERT INTO PetOwners(email) VALUES ('karia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karia@gmail.com', 'mackenzie', 'mackenzie needs love!', 'mackenzie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karia@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('jamie', 'jamie@gmail.com', 'A user of PCS', 'jamiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jamie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jamie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jamie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jamie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jamie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jamie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jamie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('donnamarie', 'donnamarie@gmail.com', 'A user of PCS', 'donnamariepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('donnamarie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'donnamarie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'donnamarie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'donnamarie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'donnamarie@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('donnamarie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('dale', 'dale@gmail.com', 'A user of PCS', 'dalepw');
INSERT INTO PetOwners(email) VALUES ('dale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'baron', 'baron needs love!', 'baron is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'freedom', 'freedom needs love!', 'freedom is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'grady', 'grady needs love!', 'grady is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'hugh', 'hugh needs love!', 'hugh is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dale@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dale@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'dale@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dale@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dale@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('papageno', 'papageno@gmail.com', 'A user of PCS', 'papagenopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('papageno@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'papageno@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'papageno@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'papageno@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('papageno@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('papageno@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('kara-lynn', 'kara-lynn@gmail.com', 'A user of PCS', 'kara-lynnpw');
INSERT INTO PetOwners(email) VALUES ('kara-lynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara-lynn@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara-lynn@gmail.com', 'honey', 'honey needs love!', 'honey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara-lynn@gmail.com', 'freckles', 'freckles needs love!', 'freckles is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara-lynn@gmail.com', 'purdy', 'purdy needs love!', 'purdy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kara-lynn@gmail.com', 'skip', 'skip needs love!', 'skip is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('leland', 'leland@gmail.com', 'A user of PCS', 'lelandpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leland@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'leland@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'leland@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leland@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leland@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('mellie', 'mellie@gmail.com', 'A user of PCS', 'melliepw');
INSERT INTO PetOwners(email) VALUES ('mellie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mellie@gmail.com', 'nike', 'nike needs love!', 'nike is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mellie@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mellie@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('latisha', 'latisha@gmail.com', 'A user of PCS', 'latishapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('latisha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'latisha@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'latisha@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'latisha@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('latisha@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('brena', 'brena@gmail.com', 'A user of PCS', 'brenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brena@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'brena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'brena@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brena@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('hale', 'hale@gmail.com', 'A user of PCS', 'halepw');
INSERT INTO PetOwners(email) VALUES ('hale@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'koba', 'koba needs love!', 'koba is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hale@gmail.com', 'bam-bam', 'bam-bam needs love!', 'bam-bam is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hale@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hale@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hale@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hale@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hale@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'hale@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hale@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('collen', 'collen@gmail.com', 'A user of PCS', 'collenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('collen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'collen@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('collen@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('collen@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('farand', 'farand@gmail.com', 'A user of PCS', 'farandpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farand@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'farand@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'farand@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'farand@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'farand@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'farand@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('farand@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('lynea', 'lynea@gmail.com', 'A user of PCS', 'lyneapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lynea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'lynea@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'lynea@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lynea@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lynea@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ladonna', 'ladonna@gmail.com', 'A user of PCS', 'ladonnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ladonna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ladonna@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ladonna@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ladonna@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ladonna@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('darci', 'darci@gmail.com', 'A user of PCS', 'darcipw');
INSERT INTO PetOwners(email) VALUES ('darci@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darci@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('fallon', 'fallon@gmail.com', 'A user of PCS', 'fallonpw');
INSERT INTO PetOwners(email) VALUES ('fallon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fallon@gmail.com', 'harvey', 'harvey needs love!', 'harvey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fallon@gmail.com', 'linus', 'linus needs love!', 'linus is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fallon@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fallon@gmail.com', 'rocko', 'rocko needs love!', 'rocko is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('ernaline', 'ernaline@gmail.com', 'A user of PCS', 'ernalinepw');
INSERT INTO PetOwners(email) VALUES ('ernaline@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'abigail', 'abigail needs love!', 'abigail is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ernaline@gmail.com', 'sly', 'sly needs love!', 'sly is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('laurice', 'laurice@gmail.com', 'A user of PCS', 'lauricepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laurice@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'laurice@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('laurice@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('rhianon', 'rhianon@gmail.com', 'A user of PCS', 'rhianonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rhianon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'rhianon@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'rhianon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'rhianon@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rhianon@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rhianon@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('benita', 'benita@gmail.com', 'A user of PCS', 'benitapw');
INSERT INTO PetOwners(email) VALUES ('benita@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benita@gmail.com', 'roman', 'roman needs love!', 'roman is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benita@gmail.com', 'boone', 'boone needs love!', 'boone is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('benita@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'benita@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'benita@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('benita@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('benita@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('byrom', 'byrom@gmail.com', 'A user of PCS', 'byrompw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrom@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'byrom@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrom@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('demetra', 'demetra@gmail.com', 'A user of PCS', 'demetrapw');
INSERT INTO PetOwners(email) VALUES ('demetra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demetra@gmail.com', 'astro', 'astro needs love!', 'astro is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ferdinande', 'ferdinande@gmail.com', 'A user of PCS', 'ferdinandepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ferdinande@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ferdinande@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ferdinande@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ferdinande@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ferdinande@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ferdinande@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('anetta', 'anetta@gmail.com', 'A user of PCS', 'anettapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anetta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'anetta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'anetta@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'anetta@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anetta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jaine', 'jaine@gmail.com', 'A user of PCS', 'jainepw');
INSERT INTO PetOwners(email) VALUES ('jaine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaine@gmail.com', 'bits', 'bits needs love!', 'bits is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaine@gmail.com', 'levi', 'levi needs love!', 'levi is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaine@gmail.com', 'chester', 'chester needs love!', 'chester is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaine@gmail.com', 'hannah', 'hannah needs love!', 'hannah is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jaine@gmail.com', 'riley', 'riley needs love!', 'riley is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jaine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'jaine@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jaine@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jaine@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('cissiee', 'cissiee@gmail.com', 'A user of PCS', 'cissieepw');
INSERT INTO PetOwners(email) VALUES ('cissiee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'monster', 'monster needs love!', 'monster is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'bogey', 'bogey needs love!', 'bogey is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'june', 'june needs love!', 'june is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'carley', 'carley needs love!', 'carley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cissiee@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cissiee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'cissiee@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'cissiee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (213, 'cissiee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'cissiee@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'cissiee@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cissiee@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cissiee@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('glen', 'glen@gmail.com', 'A user of PCS', 'glenpw');
INSERT INTO PetOwners(email) VALUES ('glen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'abel', 'abel needs love!', 'abel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glen@gmail.com', 'opie', 'opie needs love!', 'opie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'glen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'glen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'glen@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glen@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glen@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('idalia', 'idalia@gmail.com', 'A user of PCS', 'idaliapw');
INSERT INTO PetOwners(email) VALUES ('idalia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idalia@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('idalia@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idalia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'idalia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'idalia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'idalia@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idalia@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('idalia@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('hilario', 'hilario@gmail.com', 'A user of PCS', 'hilariopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hilario@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hilario@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hilario@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'hilario@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hilario@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hilario@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('cristian', 'cristian@gmail.com', 'A user of PCS', 'cristianpw');
INSERT INTO PetOwners(email) VALUES ('cristian@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'dixie', 'dixie needs love!', 'dixie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'puppy', 'puppy needs love!', 'puppy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'coal', 'coal needs love!', 'coal is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cristian@gmail.com', 'belle', 'belle needs love!', 'belle is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristian@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cristian@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cristian@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('jenilee', 'jenilee@gmail.com', 'A user of PCS', 'jenileepw');
INSERT INTO PetOwners(email) VALUES ('jenilee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenilee@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenilee@gmail.com', 'fergie', 'fergie needs love!', 'fergie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenilee@gmail.com', 'harpo', 'harpo needs love!', 'harpo is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('genevieve', 'genevieve@gmail.com', 'A user of PCS', 'genevievepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('genevieve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'genevieve@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'genevieve@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'genevieve@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'genevieve@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('genevieve@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('dixie', 'dixie@gmail.com', 'A user of PCS', 'dixiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dixie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dixie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dixie@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dixie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('paulina', 'paulina@gmail.com', 'A user of PCS', 'paulinapw');
INSERT INTO PetOwners(email) VALUES ('paulina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('paulina@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('antin', 'antin@gmail.com', 'A user of PCS', 'antinpw');
INSERT INTO PetOwners(email) VALUES ('antin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antin@gmail.com', 'hercules', 'hercules needs love!', 'hercules is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('adriena', 'adriena@gmail.com', 'A user of PCS', 'adrienapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adriena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'adriena@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'adriena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'adriena@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'adriena@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'adriena@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriena@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriena@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('pepito', 'pepito@gmail.com', 'A user of PCS', 'pepitopw');
INSERT INTO PetOwners(email) VALUES ('pepito@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pepito@gmail.com', 'oreo', 'oreo needs love!', 'oreo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pepito@gmail.com', 'onyx', 'onyx needs love!', 'onyx is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('ansell', 'ansell@gmail.com', 'A user of PCS', 'ansellpw');
INSERT INTO PetOwners(email) VALUES ('ansell@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ansell@gmail.com', 'lazarus', 'lazarus needs love!', 'lazarus is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ansell@gmail.com', 'precious', 'precious needs love!', 'precious is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ansell@gmail.com', 'jack', 'jack needs love!', 'jack is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('sherri', 'sherri@gmail.com', 'A user of PCS', 'sherripw');
INSERT INTO PetOwners(email) VALUES ('sherri@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'luke', 'luke needs love!', 'luke is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'bingo', 'bingo needs love!', 'bingo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sherri@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sherri@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sherri@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sherri@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sherri@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sherri@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sherri@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherri@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('elspeth', 'elspeth@gmail.com', 'A user of PCS', 'elspethpw');
INSERT INTO PetOwners(email) VALUES ('elspeth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elspeth@gmail.com', 'punkin', 'punkin needs love!', 'punkin is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elspeth@gmail.com', 'abigail', 'abigail needs love!', 'abigail is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elspeth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'elspeth@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elspeth@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('alma', 'alma@gmail.com', 'A user of PCS', 'almapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alma@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alma@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alma@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('lennard', 'lennard@gmail.com', 'A user of PCS', 'lennardpw');
INSERT INTO PetOwners(email) VALUES ('lennard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'dee', 'dee needs love!', 'dee is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'prissy', 'prissy needs love!', 'prissy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'dave', 'dave needs love!', 'dave is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'beanie', 'beanie needs love!', 'beanie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lennard@gmail.com', 'alfie', 'alfie needs love!', 'alfie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('frayda', 'frayda@gmail.com', 'A user of PCS', 'fraydapw');
INSERT INTO PetOwners(email) VALUES ('frayda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frayda@gmail.com', 'samantha', 'samantha needs love!', 'samantha is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('frayda@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('madel', 'madel@gmail.com', 'A user of PCS', 'madelpw');
INSERT INTO PetOwners(email) VALUES ('madel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'piggy', 'piggy needs love!', 'piggy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'adam', 'adam needs love!', 'adam is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madel@gmail.com', 'moose', 'moose needs love!', 'moose is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'madel@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madel@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('randie', 'randie@gmail.com', 'A user of PCS', 'randiepw');
INSERT INTO PetOwners(email) VALUES ('randie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('randie@gmail.com', 'doggon�', 'doggon� needs love!', 'doggon� is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('randie@gmail.com', 'pebbles', 'pebbles needs love!', 'pebbles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('randie@gmail.com', 'libby', 'libby needs love!', 'libby is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('syd', 'syd@gmail.com', 'A user of PCS', 'sydpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('syd@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'syd@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (127, 'syd@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (241, 'syd@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syd@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('syd@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('arturo', 'arturo@gmail.com', 'A user of PCS', 'arturopw');
INSERT INTO PetOwners(email) VALUES ('arturo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arturo@gmail.com', 'latte', 'latte needs love!', 'latte is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('pincus', 'pincus@gmail.com', 'A user of PCS', 'pincuspw');
INSERT INTO PetOwners(email) VALUES ('pincus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pincus@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pincus@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('madonna', 'madonna@gmail.com', 'A user of PCS', 'madonnapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madonna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'madonna@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madonna@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('hurley', 'hurley@gmail.com', 'A user of PCS', 'hurleypw');
INSERT INTO PetOwners(email) VALUES ('hurley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'mack', 'mack needs love!', 'mack is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'puck', 'puck needs love!', 'puck is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'boo-boo', 'boo-boo needs love!', 'boo-boo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'bizzy', 'bizzy needs love!', 'bizzy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hurley@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hurley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hurley@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hurley@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('burnard', 'burnard@gmail.com', 'A user of PCS', 'burnardpw');
INSERT INTO PetOwners(email) VALUES ('burnard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('burnard@gmail.com', 'peter', 'peter needs love!', 'peter is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('burnard@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'burnard@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'burnard@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'burnard@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burnard@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('burnard@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('cornelia', 'cornelia@gmail.com', 'A user of PCS', 'corneliapw');
INSERT INTO PetOwners(email) VALUES ('cornelia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'sienna', 'sienna needs love!', 'sienna is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cornelia@gmail.com', 'butter', 'butter needs love!', 'butter is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cornelia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cornelia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cornelia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cornelia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cornelia@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cornelia@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('franzen', 'franzen@gmail.com', 'A user of PCS', 'franzenpw');
INSERT INTO PetOwners(email) VALUES ('franzen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'beans', 'beans needs love!', 'beans is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'nike', 'nike needs love!', 'nike is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'chester', 'chester needs love!', 'chester is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'lexie', 'lexie needs love!', 'lexie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('franzen@gmail.com', 'pete', 'pete needs love!', 'pete is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('marguerite', 'marguerite@gmail.com', 'A user of PCS', 'margueritepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marguerite@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'marguerite@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marguerite@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marguerite@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('leda', 'leda@gmail.com', 'A user of PCS', 'ledapw');
INSERT INTO PetOwners(email) VALUES ('leda@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'lilly', 'lilly needs love!', 'lilly is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'benji', 'benji needs love!', 'benji is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'beauty', 'beauty needs love!', 'beauty is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('leda@gmail.com', 'rico', 'rico needs love!', 'rico is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('hoyt', 'hoyt@gmail.com', 'A user of PCS', 'hoytpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hoyt@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'hoyt@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'hoyt@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (62, 'hoyt@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hoyt@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hoyt@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('stoddard', 'stoddard@gmail.com', 'A user of PCS', 'stoddardpw');
INSERT INTO PetOwners(email) VALUES ('stoddard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'duchess', 'duchess needs love!', 'duchess is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'biablo', 'biablo needs love!', 'biablo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'chip', 'chip needs love!', 'chip is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stoddard@gmail.com', 'mariah', 'mariah needs love!', 'mariah is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stoddard@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'stoddard@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'stoddard@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'stoddard@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stoddard@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('stoddard@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('harrison', 'harrison@gmail.com', 'A user of PCS', 'harrisonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harrison@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'harrison@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('harrison@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('loralee', 'loralee@gmail.com', 'A user of PCS', 'loraleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('loralee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'loralee@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'loralee@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'loralee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'loralee@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('loralee@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gwyn', 'gwyn@gmail.com', 'A user of PCS', 'gwynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'gwyn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gwyn@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwyn@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('maddy', 'maddy@gmail.com', 'A user of PCS', 'maddypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maddy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'maddy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'maddy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'maddy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'maddy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'maddy@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maddy@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('cosette', 'cosette@gmail.com', 'A user of PCS', 'cosettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cosette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cosette@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cosette@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cosette@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cosette@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ranee', 'ranee@gmail.com', 'A user of PCS', 'raneepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ranee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ranee@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ranee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ranee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ranee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ranee@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranee@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('aleksandr', 'aleksandr@gmail.com', 'A user of PCS', 'aleksandrpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aleksandr@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'aleksandr@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'aleksandr@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aleksandr@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dolores', 'dolores@gmail.com', 'A user of PCS', 'dolorespw');
INSERT INTO PetOwners(email) VALUES ('dolores@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'porter', 'porter needs love!', 'porter is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'patch', 'patch needs love!', 'patch is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'bruiser', 'bruiser needs love!', 'bruiser is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dolores@gmail.com', 'eva', 'eva needs love!', 'eva is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dolores@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'dolores@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'dolores@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dolores@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dolores@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('jeromy', 'jeromy@gmail.com', 'A user of PCS', 'jeromypw');
INSERT INTO PetOwners(email) VALUES ('jeromy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeromy@gmail.com', 'brie', 'brie needs love!', 'brie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeromy@gmail.com', 'dozer', 'dozer needs love!', 'dozer is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeromy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'jeromy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'jeromy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'jeromy@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jeromy@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jeromy@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('desirae', 'desirae@gmail.com', 'A user of PCS', 'desiraepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('desirae@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'desirae@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'desirae@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'desirae@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'desirae@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desirae@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desirae@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('beckie', 'beckie@gmail.com', 'A user of PCS', 'beckiepw');
INSERT INTO PetOwners(email) VALUES ('beckie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'shaggy', 'shaggy needs love!', 'shaggy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'jess', 'jess needs love!', 'jess is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'gavin', 'gavin needs love!', 'gavin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beckie@gmail.com', 'justice', 'justice needs love!', 'justice is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('davon', 'davon@gmail.com', 'A user of PCS', 'davonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('davon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'davon@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'davon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'davon@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'davon@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'davon@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('davon@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('davon@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('mart', 'mart@gmail.com', 'A user of PCS', 'martpw');
INSERT INTO PetOwners(email) VALUES ('mart@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mart@gmail.com', 'jolie', 'jolie needs love!', 'jolie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mart@gmail.com', 'moochie', 'moochie needs love!', 'moochie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mart@gmail.com', 'michael', 'michael needs love!', 'michael is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mart@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'mart@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mart@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('mylo', 'mylo@gmail.com', 'A user of PCS', 'mylopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mylo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'mylo@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'mylo@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'mylo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'mylo@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mylo@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('mylo@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('fabiano', 'fabiano@gmail.com', 'A user of PCS', 'fabianopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fabiano@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'fabiano@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'fabiano@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'fabiano@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fabiano@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fabiano@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('delphinia', 'delphinia@gmail.com', 'A user of PCS', 'delphiniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('delphinia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'delphinia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'delphinia@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'delphinia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('delphinia@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('delphinia@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('lezlie', 'lezlie@gmail.com', 'A user of PCS', 'lezliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lezlie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'lezlie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lezlie@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lezlie@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('addi', 'addi@gmail.com', 'A user of PCS', 'addipw');
INSERT INTO PetOwners(email) VALUES ('addi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'chase', 'chase needs love!', 'chase is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'phoenix', 'phoenix needs love!', 'phoenix is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('addi@gmail.com', 'major', 'major needs love!', 'major is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('starla', 'starla@gmail.com', 'A user of PCS', 'starlapw');
INSERT INTO PetOwners(email) VALUES ('starla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'barclay', 'barclay needs love!', 'barclay is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'kellie', 'kellie needs love!', 'kellie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('starla@gmail.com', 'buddie', 'buddie needs love!', 'buddie is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('dorris', 'dorris@gmail.com', 'A user of PCS', 'dorrispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorris@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'dorris@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'dorris@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'dorris@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'dorris@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'dorris@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorris@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorris@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('gloriane', 'gloriane@gmail.com', 'A user of PCS', 'glorianepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gloriane@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'gloriane@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'gloriane@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gloriane@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gloriane@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'gloriane@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gloriane@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('egor', 'egor@gmail.com', 'A user of PCS', 'egorpw');
INSERT INTO PetOwners(email) VALUES ('egor@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egor@gmail.com', 'skye', 'skye needs love!', 'skye is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egor@gmail.com', 'clyde', 'clyde needs love!', 'clyde is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('kalindi', 'kalindi@gmail.com', 'A user of PCS', 'kalindipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalindi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kalindi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'kalindi@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'kalindi@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kalindi@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kalindi@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kalindi@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('bobby', 'bobby@gmail.com', 'A user of PCS', 'bobbypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bobby@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'bobby@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (159, 'bobby@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'bobby@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'bobby@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'bobby@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bobby@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bobby@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('ofilia', 'ofilia@gmail.com', 'A user of PCS', 'ofiliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ofilia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'ofilia@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'ofilia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'ofilia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'ofilia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (245, 'ofilia@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ofilia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ofilia@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('lev', 'lev@gmail.com', 'A user of PCS', 'levpw');
INSERT INTO PetOwners(email) VALUES ('lev@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'howie', 'howie needs love!', 'howie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'quinn', 'quinn needs love!', 'quinn is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'gidget', 'gidget needs love!', 'gidget is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lev@gmail.com', 'nina', 'nina needs love!', 'nina is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lev@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'lev@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lev@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('merl', 'merl@gmail.com', 'A user of PCS', 'merlpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merl@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'merl@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'merl@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('merl@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('palmer', 'palmer@gmail.com', 'A user of PCS', 'palmerpw');
INSERT INTO PetOwners(email) VALUES ('palmer@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('palmer@gmail.com', 'butchy', 'butchy needs love!', 'butchy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('palmer@gmail.com', 'bullet', 'bullet needs love!', 'bullet is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('palmer@gmail.com', 'penny', 'penny needs love!', 'penny is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('palmer@gmail.com', 'captain', 'captain needs love!', 'captain is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('palmer@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('cassi', 'cassi@gmail.com', 'A user of PCS', 'cassipw');
INSERT INTO PetOwners(email) VALUES ('cassi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'axle', 'axle needs love!', 'axle is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cassi@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('krystle', 'krystle@gmail.com', 'A user of PCS', 'krystlepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krystle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'krystle@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'krystle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'krystle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'krystle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krystle@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('krystle@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('desmond', 'desmond@gmail.com', 'A user of PCS', 'desmondpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('desmond@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'desmond@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'desmond@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'desmond@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desmond@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('desmond@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('alverta', 'alverta@gmail.com', 'A user of PCS', 'alvertapw');
INSERT INTO PetOwners(email) VALUES ('alverta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'ivy', 'ivy needs love!', 'ivy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'justice', 'justice needs love!', 'justice is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alverta@gmail.com', 'norton', 'norton needs love!', 'norton is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('britte', 'britte@gmail.com', 'A user of PCS', 'brittepw');
INSERT INTO PetOwners(email) VALUES ('britte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('britte@gmail.com', 'linus', 'linus needs love!', 'linus is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('britte@gmail.com', 'sheba', 'sheba needs love!', 'sheba is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('britte@gmail.com', 'miko', 'miko needs love!', 'miko is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('britte@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'britte@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'britte@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'britte@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'britte@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('britte@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('britte@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('adolf', 'adolf@gmail.com', 'A user of PCS', 'adolfpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adolf@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'adolf@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'adolf@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('adolf@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('damara', 'damara@gmail.com', 'A user of PCS', 'damarapw');
INSERT INTO PetOwners(email) VALUES ('damara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('damara@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('damara@gmail.com', 'keesha', 'keesha needs love!', 'keesha is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('damara@gmail.com', 'smokey', 'smokey needs love!', 'smokey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('damara@gmail.com', 'patricky', 'patricky needs love!', 'patricky is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('letizia', 'letizia@gmail.com', 'A user of PCS', 'letiziapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('letizia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'letizia@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'letizia@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'letizia@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (238, 'letizia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (141, 'letizia@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('letizia@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('letizia@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('binny', 'binny@gmail.com', 'A user of PCS', 'binnypw');
INSERT INTO PetOwners(email) VALUES ('binny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'mollie', 'mollie needs love!', 'mollie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'porche', 'porche needs love!', 'porche is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('binny@gmail.com', 'paco', 'paco needs love!', 'paco is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('binny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'binny@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'binny@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'binny@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('binny@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('nita', 'nita@gmail.com', 'A user of PCS', 'nitapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nita@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'nita@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'nita@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'nita@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'nita@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('nita@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorry', 'dorry@gmail.com', 'A user of PCS', 'dorrypw');
INSERT INTO PetOwners(email) VALUES ('dorry@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorry@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('wylma', 'wylma@gmail.com', 'A user of PCS', 'wylmapw');
INSERT INTO PetOwners(email) VALUES ('wylma@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wylma@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('adena', 'adena@gmail.com', 'A user of PCS', 'adenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'adena@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'adena@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adena@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adena@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('elie', 'elie@gmail.com', 'A user of PCS', 'eliepw');
INSERT INTO PetOwners(email) VALUES ('elie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'cisco', 'cisco needs love!', 'cisco is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elie@gmail.com', 'georgie', 'georgie needs love!', 'georgie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('harv', 'harv@gmail.com', 'A user of PCS', 'harvpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harv@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'harv@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'harv@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (59, 'harv@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'harv@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'harv@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harv@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harv@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('drew', 'drew@gmail.com', 'A user of PCS', 'drewpw');
INSERT INTO PetOwners(email) VALUES ('drew@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'lexus', 'lexus needs love!', 'lexus is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'shelly', 'shelly needs love!', 'shelly is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('drew@gmail.com', 'chaos', 'chaos needs love!', 'chaos is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('drew@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'drew@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('drew@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('drew@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('malissia', 'malissia@gmail.com', 'A user of PCS', 'malissiapw');
INSERT INTO PetOwners(email) VALUES ('malissia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('malissia@gmail.com', 'magnolia', 'magnolia needs love!', 'magnolia is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('malissia@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('malissia@gmail.com', 'gidget', 'gidget needs love!', 'gidget is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('malissia@gmail.com', 'butch', 'butch needs love!', 'butch is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('malissia@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('elliot', 'elliot@gmail.com', 'A user of PCS', 'elliotpw');
INSERT INTO PetOwners(email) VALUES ('elliot@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elliot@gmail.com', 'miasy', 'miasy needs love!', 'miasy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elliot@gmail.com', 'rudy', 'rudy needs love!', 'rudy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elliot@gmail.com', 'mcduff', 'mcduff needs love!', 'mcduff is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elliot@gmail.com', 'howie', 'howie needs love!', 'howie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elliot@gmail.com', 'levi', 'levi needs love!', 'levi is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('riobard', 'riobard@gmail.com', 'A user of PCS', 'riobardpw');
INSERT INTO PetOwners(email) VALUES ('riobard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('riobard@gmail.com', 'jenny', 'jenny needs love!', 'jenny is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('kennie', 'kennie@gmail.com', 'A user of PCS', 'kenniepw');
INSERT INTO PetOwners(email) VALUES ('kennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennie@gmail.com', 'bobo', 'bobo needs love!', 'bobo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennie@gmail.com', 'kona', 'kona needs love!', 'kona is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennie@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennie@gmail.com', 'buffy', 'buffy needs love!', 'buffy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennie@gmail.com', 'powder', 'powder needs love!', 'powder is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('fredia', 'fredia@gmail.com', 'A user of PCS', 'frediapw');
INSERT INTO PetOwners(email) VALUES ('fredia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'grace', 'grace needs love!', 'grace is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'chamberlain', 'chamberlain needs love!', 'chamberlain is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fredia@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fredia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'fredia@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'fredia@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (119, 'fredia@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fredia@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fredia@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('harper', 'harper@gmail.com', 'A user of PCS', 'harperpw');
INSERT INTO PetOwners(email) VALUES ('harper@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harper@gmail.com', 'black-jack', 'black-jack needs love!', 'black-jack is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harper@gmail.com', 'jr', 'jr needs love!', 'jr is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harper@gmail.com', 'mason', 'mason needs love!', 'mason is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harper@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('harper@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('boony', 'boony@gmail.com', 'A user of PCS', 'boonypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boony@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'boony@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'boony@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boony@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hendrik', 'hendrik@gmail.com', 'A user of PCS', 'hendrikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hendrik@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'hendrik@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'hendrik@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hendrik@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('juieta', 'juieta@gmail.com', 'A user of PCS', 'juietapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('juieta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'juieta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'juieta@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'juieta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'juieta@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('juieta@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('ola', 'ola@gmail.com', 'A user of PCS', 'olapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ola@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ola@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ola@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('beau', 'beau@gmail.com', 'A user of PCS', 'beaupw');
INSERT INTO PetOwners(email) VALUES ('beau@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'billie', 'billie needs love!', 'billie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'sampson', 'sampson needs love!', 'sampson is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beau@gmail.com', 'kissy', 'kissy needs love!', 'kissy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ab', 'ab@gmail.com', 'A user of PCS', 'abpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ab@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ab@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ab@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ab@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ab@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ab@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ab@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('gav', 'gav@gmail.com', 'A user of PCS', 'gavpw');
INSERT INTO PetOwners(email) VALUES ('gav@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gav@gmail.com', 'amy', 'amy needs love!', 'amy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gav@gmail.com', 'jewels', 'jewels needs love!', 'jewels is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gav@gmail.com', 'lola', 'lola needs love!', 'lola is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('garold', 'garold@gmail.com', 'A user of PCS', 'garoldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garold@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'garold@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'garold@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'garold@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garold@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('garold@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('sigrid', 'sigrid@gmail.com', 'A user of PCS', 'sigridpw');
INSERT INTO PetOwners(email) VALUES ('sigrid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sigrid@gmail.com', 'bodie', 'bodie needs love!', 'bodie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sigrid@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sigrid@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sigrid@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sigrid@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('tonye', 'tonye@gmail.com', 'A user of PCS', 'tonyepw');
INSERT INTO PetOwners(email) VALUES ('tonye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'aires', 'aires needs love!', 'aires is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'lola', 'lola needs love!', 'lola is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tonye@gmail.com', 'katz', 'katz needs love!', 'katz is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('dorthy', 'dorthy@gmail.com', 'A user of PCS', 'dorthypw');
INSERT INTO PetOwners(email) VALUES ('dorthy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'ferris', 'ferris needs love!', 'ferris is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'clicker', 'clicker needs love!', 'clicker is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorthy@gmail.com', 'beaux', 'beaux needs love!', 'beaux is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorthy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'dorthy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'dorthy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'dorthy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'dorthy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'dorthy@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorthy@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorthy@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('aubine', 'aubine@gmail.com', 'A user of PCS', 'aubinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('aubine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'aubine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'aubine@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'aubine@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('aubine@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('daron', 'daron@gmail.com', 'A user of PCS', 'daronpw');
INSERT INTO PetOwners(email) VALUES ('daron@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'harrison', 'harrison needs love!', 'harrison is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'aussie', 'aussie needs love!', 'aussie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'iris', 'iris needs love!', 'iris is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'abbie', 'abbie needs love!', 'abbie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('daron@gmail.com', 'monty', 'monty needs love!', 'monty is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('hashim', 'hashim@gmail.com', 'A user of PCS', 'hashimpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hashim@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hashim@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'hashim@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hashim@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hashim@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('humfrid', 'humfrid@gmail.com', 'A user of PCS', 'humfridpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humfrid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'humfrid@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'humfrid@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('humfrid@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('humfrid@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('claribel', 'claribel@gmail.com', 'A user of PCS', 'claribelpw');
INSERT INTO PetOwners(email) VALUES ('claribel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claribel@gmail.com', 'mollie', 'mollie needs love!', 'mollie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claribel@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claribel@gmail.com', 'dandy', 'dandy needs love!', 'dandy is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('lani', 'lani@gmail.com', 'A user of PCS', 'lanipw');
INSERT INTO PetOwners(email) VALUES ('lani@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lani@gmail.com', 'roland', 'roland needs love!', 'roland is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lani@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('hobie', 'hobie@gmail.com', 'A user of PCS', 'hobiepw');
INSERT INTO PetOwners(email) VALUES ('hobie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'rhett', 'rhett needs love!', 'rhett is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'rex', 'rex needs love!', 'rex is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'presley', 'presley needs love!', 'presley is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'magic', 'magic needs love!', 'magic is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hobie@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hobie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'hobie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (201, 'hobie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'hobie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'hobie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hobie@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hobie@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('teri', 'teri@gmail.com', 'A user of PCS', 'teripw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('teri@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (118, 'teri@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (276, 'teri@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'teri@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'teri@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('teri@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('teri@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('karlik', 'karlik@gmail.com', 'A user of PCS', 'karlikpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlik@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'karlik@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karlik@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('karlik@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('rafaellle', 'rafaellle@gmail.com', 'A user of PCS', 'rafaelllepw');
INSERT INTO PetOwners(email) VALUES ('rafaellle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafaellle@gmail.com', 'queen', 'queen needs love!', 'queen is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rafaellle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'rafaellle@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rafaellle@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rafaellle@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('dougy', 'dougy@gmail.com', 'A user of PCS', 'dougypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dougy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'dougy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'dougy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'dougy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'dougy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'dougy@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dougy@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dougy@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('brigid', 'brigid@gmail.com', 'A user of PCS', 'brigidpw');
INSERT INTO PetOwners(email) VALUES ('brigid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'powder', 'powder needs love!', 'powder is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'francais', 'francais needs love!', 'francais is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'skippy', 'skippy needs love!', 'skippy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'may', 'may needs love!', 'may is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brigid@gmail.com', 'cassis', 'cassis needs love!', 'cassis is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brigid@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'brigid@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'brigid@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'brigid@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'brigid@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brigid@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brigid@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('chaim', 'chaim@gmail.com', 'A user of PCS', 'chaimpw');
INSERT INTO PetOwners(email) VALUES ('chaim@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chaim@gmail.com', 'scooter', 'scooter needs love!', 'scooter is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('dre', 'dre@gmail.com', 'A user of PCS', 'drepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dre@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'dre@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'dre@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'dre@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'dre@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'dre@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dre@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dre@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('michele', 'michele@gmail.com', 'A user of PCS', 'michelepw');
INSERT INTO PetOwners(email) VALUES ('michele@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'bernie', 'bernie needs love!', 'bernie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'nicky', 'nicky needs love!', 'nicky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'mitzy', 'mitzy needs love!', 'mitzy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('michele@gmail.com', 'bubba', 'bubba needs love!', 'bubba is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('shellysheldon', 'shellysheldon@gmail.com', 'A user of PCS', 'shellysheldonpw');
INSERT INTO PetOwners(email) VALUES ('shellysheldon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'paddy', 'paddy needs love!', 'paddy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'birdie', 'birdie needs love!', 'birdie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'roman', 'roman needs love!', 'roman is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shellysheldon@gmail.com', 'lynx', 'lynx needs love!', 'lynx is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shellysheldon@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'shellysheldon@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'shellysheldon@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'shellysheldon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'shellysheldon@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shellysheldon@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('sammy', 'sammy@gmail.com', 'A user of PCS', 'sammypw');
INSERT INTO PetOwners(email) VALUES ('sammy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'april', 'april needs love!', 'april is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sammy@gmail.com', 'bernie', 'bernie needs love!', 'bernie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sammy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'sammy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'sammy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'sammy@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sammy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sammy@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sammy@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorice', 'dorice@gmail.com', 'A user of PCS', 'doricepw');
INSERT INTO PetOwners(email) VALUES ('dorice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorice@gmail.com', 'layla', 'layla needs love!', 'layla is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dorice@gmail.com', 'pooh', 'pooh needs love!', 'pooh is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('cheston', 'cheston@gmail.com', 'A user of PCS', 'chestonpw');
INSERT INTO PetOwners(email) VALUES ('cheston@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cheston@gmail.com', 'mickey', 'mickey needs love!', 'mickey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cheston@gmail.com', 'lexus', 'lexus needs love!', 'lexus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cheston@gmail.com', 'sabrina', 'sabrina needs love!', 'sabrina is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cheston@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'cheston@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'cheston@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cheston@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cheston@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cheston@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('patti', 'patti@gmail.com', 'A user of PCS', 'pattipw');
INSERT INTO PetOwners(email) VALUES ('patti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('patti@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('linet', 'linet@gmail.com', 'A user of PCS', 'linetpw');
INSERT INTO PetOwners(email) VALUES ('linet@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'nakita', 'nakita needs love!', 'nakita is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('linet@gmail.com', 'diamond', 'diamond needs love!', 'diamond is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('linet@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'linet@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'linet@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'linet@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'linet@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'linet@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linet@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linet@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('roanne', 'roanne@gmail.com', 'A user of PCS', 'roannepw');
INSERT INTO PetOwners(email) VALUES ('roanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roanne@gmail.com', 'georgia', 'georgia needs love!', 'georgia is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roanne@gmail.com', 'minnie', 'minnie needs love!', 'minnie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roanne@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('roanne@gmail.com', 'purdy', 'purdy needs love!', 'purdy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('katherina', 'katherina@gmail.com', 'A user of PCS', 'katherinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katherina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'katherina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'katherina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'katherina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'katherina@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('katherina@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('filia', 'filia@gmail.com', 'A user of PCS', 'filiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'filia@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'filia@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filia@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filia@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('sibby', 'sibby@gmail.com', 'A user of PCS', 'sibbypw');
INSERT INTO PetOwners(email) VALUES ('sibby@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'silver', 'silver needs love!', 'silver is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'chance', 'chance needs love!', 'chance is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'big boy', 'big boy needs love!', 'big boy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'sadie', 'sadie needs love!', 'sadie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sibby@gmail.com', 'kyra', 'kyra needs love!', 'kyra is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sibby@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sibby@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sibby@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('alfreda', 'alfreda@gmail.com', 'A user of PCS', 'alfredapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alfreda@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alfreda@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'alfreda@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alfreda@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gavin', 'gavin@gmail.com', 'A user of PCS', 'gavinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gavin@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'gavin@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gavin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'gavin@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gavin@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'gavin@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gavin@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('atalanta', 'atalanta@gmail.com', 'A user of PCS', 'atalantapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('atalanta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'atalanta@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('atalanta@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('atalanta@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('fawn', 'fawn@gmail.com', 'A user of PCS', 'fawnpw');
INSERT INTO PetOwners(email) VALUES ('fawn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fawn@gmail.com', 'ringo', 'ringo needs love!', 'ringo is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('dalston', 'dalston@gmail.com', 'A user of PCS', 'dalstonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dalston@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'dalston@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'dalston@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dalston@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dalston@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('gideon', 'gideon@gmail.com', 'A user of PCS', 'gideonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gideon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'gideon@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'gideon@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gideon@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gideon@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('kerrie', 'kerrie@gmail.com', 'A user of PCS', 'kerriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kerrie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'kerrie@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerrie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kerrie@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('carmelina', 'carmelina@gmail.com', 'A user of PCS', 'carmelinapw');
INSERT INTO PetOwners(email) VALUES ('carmelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmelina@gmail.com', 'nikita', 'nikita needs love!', 'nikita is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carmelina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'carmelina@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('carmelina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('berton', 'berton@gmail.com', 'A user of PCS', 'bertonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('berton@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'berton@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'berton@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'berton@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'berton@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'berton@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('berton@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('tova', 'tova@gmail.com', 'A user of PCS', 'tovapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tova@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tova@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tova@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tova@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('demott', 'demott@gmail.com', 'A user of PCS', 'demottpw');
INSERT INTO PetOwners(email) VALUES ('demott@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'emma', 'emma needs love!', 'emma is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'budda', 'budda needs love!', 'budda is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'ozzy', 'ozzy needs love!', 'ozzy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('demott@gmail.com', 'bug', 'bug needs love!', 'bug is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('demott@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'demott@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (244, 'demott@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (36, 'demott@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'demott@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('demott@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('demott@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorie', 'dorie@gmail.com', 'A user of PCS', 'doriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (167, 'dorie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'dorie@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dorie@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('glad', 'glad@gmail.com', 'A user of PCS', 'gladpw');
INSERT INTO PetOwners(email) VALUES ('glad@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'parker', 'parker needs love!', 'parker is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'dylan', 'dylan needs love!', 'dylan is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glad@gmail.com', 'lexus', 'lexus needs love!', 'lexus is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glad@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (255, 'glad@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('glad@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('caldwell', 'caldwell@gmail.com', 'A user of PCS', 'caldwellpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caldwell@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'caldwell@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'caldwell@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'caldwell@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'caldwell@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'caldwell@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caldwell@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caldwell@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('fidole', 'fidole@gmail.com', 'A user of PCS', 'fidolepw');
INSERT INTO PetOwners(email) VALUES ('fidole@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'kitty', 'kitty needs love!', 'kitty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'luna', 'luna needs love!', 'luna is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'barney', 'barney needs love!', 'barney is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fidole@gmail.com', 'sly', 'sly needs love!', 'sly is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('karlis', 'karlis@gmail.com', 'A user of PCS', 'karlispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karlis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'karlis@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'karlis@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karlis@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jenni', 'jenni@gmail.com', 'A user of PCS', 'jennipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenni@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'jenni@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'jenni@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'jenni@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenni@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenni@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('andee', 'andee@gmail.com', 'A user of PCS', 'andeepw');
INSERT INTO PetOwners(email) VALUES ('andee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'miss priss', 'miss priss needs love!', 'miss priss is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'bud', 'bud needs love!', 'bud is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andee@gmail.com', 'dodger', 'dodger needs love!', 'dodger is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andee@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'andee@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (177, 'andee@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'andee@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andee@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andee@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('mariejeanne', 'mariejeanne@gmail.com', 'A user of PCS', 'mariejeannepw');
INSERT INTO PetOwners(email) VALUES ('mariejeanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mariejeanne@gmail.com', 'dewey', 'dewey needs love!', 'dewey is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mariejeanne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'mariejeanne@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'mariejeanne@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mariejeanne@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'mariejeanne@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'mariejeanne@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mariejeanne@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('glennie', 'glennie@gmail.com', 'A user of PCS', 'glenniepw');
INSERT INTO PetOwners(email) VALUES ('glennie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'luna', 'luna needs love!', 'luna is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'butch', 'butch needs love!', 'butch is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'rover', 'rover needs love!', 'rover is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('glennie@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('glennie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'glennie@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('glennie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('robenia', 'robenia@gmail.com', 'A user of PCS', 'robeniapw');
INSERT INTO PetOwners(email) VALUES ('robenia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'bizzy', 'bizzy needs love!', 'bizzy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'peanut', 'peanut needs love!', 'peanut is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'major', 'major needs love!', 'major is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'chip', 'chip needs love!', 'chip is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('robenia@gmail.com', 'bo', 'bo needs love!', 'bo is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('orsola', 'orsola@gmail.com', 'A user of PCS', 'orsolapw');
INSERT INTO PetOwners(email) VALUES ('orsola@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'mary', 'mary needs love!', 'mary is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orsola@gmail.com', 'rover', 'rover needs love!', 'rover is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('vania', 'vania@gmail.com', 'A user of PCS', 'vaniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vania@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'vania@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'vania@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'vania@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'vania@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'vania@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vania@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('sidonia', 'sidonia@gmail.com', 'A user of PCS', 'sidoniapw');
INSERT INTO PetOwners(email) VALUES ('sidonia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sidonia@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sidonia@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sidonia@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sidonia@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sidonia@gmail.com', 'baby', 'baby needs love!', 'baby is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sidonia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'sidonia@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sidonia@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sidonia@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcello', 'marcello@gmail.com', 'A user of PCS', 'marcellopw');
INSERT INTO PetOwners(email) VALUES ('marcello@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcello@gmail.com', 'skye', 'skye needs love!', 'skye is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('krysta', 'krysta@gmail.com', 'A user of PCS', 'krystapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('krysta@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'krysta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'krysta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'krysta@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('krysta@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('wilhelmine', 'wilhelmine@gmail.com', 'A user of PCS', 'wilhelminepw');
INSERT INTO PetOwners(email) VALUES ('wilhelmine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'giant', 'giant needs love!', 'giant is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'clicker', 'clicker needs love!', 'clicker is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'mo', 'mo needs love!', 'mo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilhelmine@gmail.com', 'frisco', 'frisco needs love!', 'frisco is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wilhelmine@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'wilhelmine@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'wilhelmine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'wilhelmine@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'wilhelmine@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'wilhelmine@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('wilhelmine@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('jyoti', 'jyoti@gmail.com', 'A user of PCS', 'jyotipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jyoti@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'jyoti@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jyoti@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'jyoti@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'jyoti@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'jyoti@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('jyoti@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('fairfax', 'fairfax@gmail.com', 'A user of PCS', 'fairfaxpw');
INSERT INTO PetOwners(email) VALUES ('fairfax@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'magic', 'magic needs love!', 'magic is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'jessie', 'jessie needs love!', 'jessie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'mittens', 'mittens needs love!', 'mittens is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'raison', 'raison needs love!', 'raison is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fairfax@gmail.com', 'lola', 'lola needs love!', 'lola is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fairfax@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (128, 'fairfax@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'fairfax@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'fairfax@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fairfax@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fairfax@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('cecil', 'cecil@gmail.com', 'A user of PCS', 'cecilpw');
INSERT INTO PetOwners(email) VALUES ('cecil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cecil@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cecil@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cecil@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cecil@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('laina', 'laina@gmail.com', 'A user of PCS', 'lainapw');
INSERT INTO PetOwners(email) VALUES ('laina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'guy', 'guy needs love!', 'guy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'chevy', 'chevy needs love!', 'chevy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'dottie', 'dottie needs love!', 'dottie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laina@gmail.com', 'dudley', 'dudley needs love!', 'dudley is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('christiane', 'christiane@gmail.com', 'A user of PCS', 'christianepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('christiane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'christiane@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (215, 'christiane@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'christiane@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christiane@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('christiane@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('isiahi', 'isiahi@gmail.com', 'A user of PCS', 'isiahipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isiahi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'isiahi@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isiahi@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('isiahi@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('hervey', 'hervey@gmail.com', 'A user of PCS', 'herveypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hervey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'hervey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'hervey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'hervey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'hervey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'hervey@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hervey@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hervey@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('minne', 'minne@gmail.com', 'A user of PCS', 'minnepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('minne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'minne@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'minne@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'minne@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('minne@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('minne@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('toiboid', 'toiboid@gmail.com', 'A user of PCS', 'toiboidpw');
INSERT INTO PetOwners(email) VALUES ('toiboid@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'adam', 'adam needs love!', 'adam is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'niki', 'niki needs love!', 'niki is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('toiboid@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('sullivan', 'sullivan@gmail.com', 'A user of PCS', 'sullivanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sullivan@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'sullivan@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'sullivan@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'sullivan@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sullivan@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sullivan@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('tiphany', 'tiphany@gmail.com', 'A user of PCS', 'tiphanypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiphany@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tiphany@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'tiphany@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tiphany@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'tiphany@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'tiphany@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiphany@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('teresa', 'teresa@gmail.com', 'A user of PCS', 'teresapw');
INSERT INTO PetOwners(email) VALUES ('teresa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teresa@gmail.com', 'casey', 'casey needs love!', 'casey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teresa@gmail.com', 'porter', 'porter needs love!', 'porter is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('teresa@gmail.com', 'scooby', 'scooby needs love!', 'scooby is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('teresa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'teresa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'teresa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'teresa@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('teresa@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('margarette', 'margarette@gmail.com', 'A user of PCS', 'margarettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('margarette@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'margarette@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'margarette@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (55, 'margarette@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('margarette@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('margarette@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('marie-ann', 'marie-ann@gmail.com', 'A user of PCS', 'marie-annpw');
INSERT INTO PetOwners(email) VALUES ('marie-ann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-ann@gmail.com', 'sasha', 'sasha needs love!', 'sasha is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('gabby', 'gabby@gmail.com', 'A user of PCS', 'gabbypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gabby@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (240, 'gabby@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'gabby@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gabby@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gabby@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('maureen', 'maureen@gmail.com', 'A user of PCS', 'maureenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maureen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'maureen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'maureen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'maureen@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'maureen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'maureen@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maureen@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('fanni', 'fanni@gmail.com', 'A user of PCS', 'fannipw');
INSERT INTO PetOwners(email) VALUES ('fanni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fanni@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fanni@gmail.com', 'crackers', 'crackers needs love!', 'crackers is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fanni@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fanni@gmail.com', 'bob', 'bob needs love!', 'bob is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('maybelle', 'maybelle@gmail.com', 'A user of PCS', 'maybellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maybelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'maybelle@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (222, 'maybelle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'maybelle@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'maybelle@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maybelle@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('maybelle@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('tobye', 'tobye@gmail.com', 'A user of PCS', 'tobyepw');
INSERT INTO PetOwners(email) VALUES ('tobye@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'piglet', 'piglet needs love!', 'piglet is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'cooper', 'cooper needs love!', 'cooper is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'mackenzie', 'mackenzie needs love!', 'mackenzie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tobye@gmail.com', 'pongo', 'pongo needs love!', 'pongo is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('ulrich', 'ulrich@gmail.com', 'A user of PCS', 'ulrichpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulrich@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ulrich@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulrich@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('erwin', 'erwin@gmail.com', 'A user of PCS', 'erwinpw');
INSERT INTO PetOwners(email) VALUES ('erwin@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erwin@gmail.com', 'jet', 'jet needs love!', 'jet is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('erwin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'erwin@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (99, 'erwin@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'erwin@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('erwin@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('erwin@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('tawnya', 'tawnya@gmail.com', 'A user of PCS', 'tawnyapw');
INSERT INTO PetOwners(email) VALUES ('tawnya@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'josie', 'josie needs love!', 'josie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'bunky', 'bunky needs love!', 'bunky is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'moonshine', 'moonshine needs love!', 'moonshine is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tawnya@gmail.com', 'china', 'china needs love!', 'china is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('filmer', 'filmer@gmail.com', 'A user of PCS', 'filmerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filmer@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'filmer@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (201, 'filmer@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filmer@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('marilyn', 'marilyn@gmail.com', 'A user of PCS', 'marilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marilyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'marilyn@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marilyn@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('grace', 'grace@gmail.com', 'A user of PCS', 'gracepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('grace@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'grace@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'grace@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('grace@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('grace@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('daisi', 'daisi@gmail.com', 'A user of PCS', 'daisipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('daisi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (37, 'daisi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'daisi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'daisi@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('daisi@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('daisi@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('tammara', 'tammara@gmail.com', 'A user of PCS', 'tammarapw');
INSERT INTO PetOwners(email) VALUES ('tammara@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tammara@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tammara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'tammara@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'tammara@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'tammara@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'tammara@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tammara@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tammara@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('carolan', 'carolan@gmail.com', 'A user of PCS', 'carolanpw');
INSERT INTO PetOwners(email) VALUES ('carolan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carolan@gmail.com', 'fancy', 'fancy needs love!', 'fancy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('shandie', 'shandie@gmail.com', 'A user of PCS', 'shandiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shandie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'shandie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shandie@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('deborah', 'deborah@gmail.com', 'A user of PCS', 'deborahpw');
INSERT INTO PetOwners(email) VALUES ('deborah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deborah@gmail.com', 'kali', 'kali needs love!', 'kali is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deborah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'deborah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'deborah@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deborah@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('humbert', 'humbert@gmail.com', 'A user of PCS', 'humbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('humbert@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'humbert@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'humbert@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('humbert@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('stanislaus', 'stanislaus@gmail.com', 'A user of PCS', 'stanislauspw');
INSERT INTO PetOwners(email) VALUES ('stanislaus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stanislaus@gmail.com', 'dave', 'dave needs love!', 'dave is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stanislaus@gmail.com', 'may', 'may needs love!', 'may is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stanislaus@gmail.com', 'macintosh', 'macintosh needs love!', 'macintosh is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stanislaus@gmail.com', 'chewy', 'chewy needs love!', 'chewy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('stanislaus@gmail.com', 'bj', 'bj needs love!', 'bj is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stanislaus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'stanislaus@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'stanislaus@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'stanislaus@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'stanislaus@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stanislaus@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('mella', 'mella@gmail.com', 'A user of PCS', 'mellapw');
INSERT INTO PetOwners(email) VALUES ('mella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'ginny', 'ginny needs love!', 'ginny is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'koty', 'koty needs love!', 'koty is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'arnie', 'arnie needs love!', 'arnie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mella@gmail.com', 'brit', 'brit needs love!', 'brit is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('camella', 'camella@gmail.com', 'A user of PCS', 'camellapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('camella@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'camella@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (78, 'camella@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (82, 'camella@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camella@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('camella@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('thomasina', 'thomasina@gmail.com', 'A user of PCS', 'thomasinapw');
INSERT INTO PetOwners(email) VALUES ('thomasina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'sheena', 'sheena needs love!', 'sheena is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'linus', 'linus needs love!', 'linus is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'daffy', 'daffy needs love!', 'daffy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'moose', 'moose needs love!', 'moose is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('thomasina@gmail.com', 'calvin', 'calvin needs love!', 'calvin is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('calley', 'calley@gmail.com', 'A user of PCS', 'calleypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('calley@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (227, 'calley@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'calley@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (64, 'calley@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'calley@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('calley@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('calley@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('jenelle', 'jenelle@gmail.com', 'A user of PCS', 'jenellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jenelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'jenelle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'jenelle@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'jenelle@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (168, 'jenelle@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jenelle@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('trudie', 'trudie@gmail.com', 'A user of PCS', 'trudiepw');
INSERT INTO PetOwners(email) VALUES ('trudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'pooch', 'pooch needs love!', 'pooch is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'kenya', 'kenya needs love!', 'kenya is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'savannah', 'savannah needs love!', 'savannah is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'schultz', 'schultz needs love!', 'schultz is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudie@gmail.com', 'miles', 'miles needs love!', 'miles is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('alexandros', 'alexandros@gmail.com', 'A user of PCS', 'alexandrospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alexandros@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'alexandros@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'alexandros@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'alexandros@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alexandros@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alexandros@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('esmaria', 'esmaria@gmail.com', 'A user of PCS', 'esmariapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esmaria@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'esmaria@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'esmaria@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'esmaria@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('esmaria@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('esmaria@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('erv', 'erv@gmail.com', 'A user of PCS', 'ervpw');
INSERT INTO PetOwners(email) VALUES ('erv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'sable', 'sable needs love!', 'sable is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'brooke', 'brooke needs love!', 'brooke is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'plato', 'plato needs love!', 'plato is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'rascal', 'rascal needs love!', 'rascal is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('erv@gmail.com', 'chad', 'chad needs love!', 'chad is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('shay', 'shay@gmail.com', 'A user of PCS', 'shaypw');
INSERT INTO PetOwners(email) VALUES ('shay@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shay@gmail.com', 'missie', 'missie needs love!', 'missie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shay@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shay@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (199, 'shay@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'shay@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'shay@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'shay@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shay@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shay@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('feodora', 'feodora@gmail.com', 'A user of PCS', 'feodorapw');
INSERT INTO PetOwners(email) VALUES ('feodora@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('feodora@gmail.com', 'petie', 'petie needs love!', 'petie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('feodora@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('feodora@gmail.com', 'joe', 'joe needs love!', 'joe is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('feodora@gmail.com', 'skittles', 'skittles needs love!', 'skittles is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('raddie', 'raddie@gmail.com', 'A user of PCS', 'raddiepw');
INSERT INTO PetOwners(email) VALUES ('raddie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'cosmo', 'cosmo needs love!', 'cosmo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'lucky', 'lucky needs love!', 'lucky is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'blackie', 'blackie needs love!', 'blackie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('raddie@gmail.com', 'skip', 'skip needs love!', 'skip is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('raddie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'raddie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('raddie@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('ric', 'ric@gmail.com', 'A user of PCS', 'ricpw');
INSERT INTO PetOwners(email) VALUES ('ric@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ric@gmail.com', 'chance', 'chance needs love!', 'chance is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ric@gmail.com', 'dillon', 'dillon needs love!', 'dillon is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ric@gmail.com', 'silver', 'silver needs love!', 'silver is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ric@gmail.com', 'romeo', 'romeo needs love!', 'romeo is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('carley', 'carley@gmail.com', 'A user of PCS', 'carleypw');
INSERT INTO PetOwners(email) VALUES ('carley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carley@gmail.com', 'roxie', 'roxie needs love!', 'roxie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('jana', 'jana@gmail.com', 'A user of PCS', 'janapw');
INSERT INTO PetOwners(email) VALUES ('jana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jana@gmail.com', 'girl', 'girl needs love!', 'girl is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jana@gmail.com', 'houdini', 'houdini needs love!', 'houdini is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jana@gmail.com', 'aussie', 'aussie needs love!', 'aussie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jana@gmail.com', 'brutus', 'brutus needs love!', 'brutus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jana@gmail.com', 'bullwinkle', 'bullwinkle needs love!', 'bullwinkle is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('monro', 'monro@gmail.com', 'A user of PCS', 'monropw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('monro@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'monro@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'monro@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('monro@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('monro@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('claudie', 'claudie@gmail.com', 'A user of PCS', 'claudiepw');
INSERT INTO PetOwners(email) VALUES ('claudie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudie@gmail.com', 'armanti', 'armanti needs love!', 'armanti is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudie@gmail.com', 'monkey', 'monkey needs love!', 'monkey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudie@gmail.com', 'pumpkin', 'pumpkin needs love!', 'pumpkin is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudie@gmail.com', 'kelsey', 'kelsey needs love!', 'kelsey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudie@gmail.com', 'andy', 'andy needs love!', 'andy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('aland', 'aland@gmail.com', 'A user of PCS', 'alandpw');
INSERT INTO PetOwners(email) VALUES ('aland@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'dickens', 'dickens needs love!', 'dickens is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aland@gmail.com', 'oliver', 'oliver needs love!', 'oliver is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('wallie', 'wallie@gmail.com', 'A user of PCS', 'walliepw');
INSERT INTO PetOwners(email) VALUES ('wallie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallie@gmail.com', 'kiwi', 'kiwi needs love!', 'kiwi is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallie@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallie@gmail.com', 'otto', 'otto needs love!', 'otto is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wallie@gmail.com', 'sandy', 'sandy needs love!', 'sandy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('sheila-kathryn', 'sheila-kathryn@gmail.com', 'A user of PCS', 'sheila-kathrynpw');
INSERT INTO PetOwners(email) VALUES ('sheila-kathryn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sheila-kathryn@gmail.com', 'kirby', 'kirby needs love!', 'kirby is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sheila-kathryn@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sheila-kathryn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'sheila-kathryn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'sheila-kathryn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'sheila-kathryn@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sheila-kathryn@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sheila-kathryn@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('rockie', 'rockie@gmail.com', 'A user of PCS', 'rockiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rockie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'rockie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'rockie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'rockie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'rockie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'rockie@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rockie@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rockie@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('kippy', 'kippy@gmail.com', 'A user of PCS', 'kippypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kippy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'kippy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'kippy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kippy@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kippy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ozzy', 'ozzy@gmail.com', 'A user of PCS', 'ozzypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ozzy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'ozzy@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (31, 'ozzy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'ozzy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'ozzy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ozzy@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ozzy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('lock', 'lock@gmail.com', 'A user of PCS', 'lockpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lock@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lock@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lock@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'lock@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lock@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('albina', 'albina@gmail.com', 'A user of PCS', 'albinapw');
INSERT INTO PetOwners(email) VALUES ('albina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'murphy', 'murphy needs love!', 'murphy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'honey', 'honey needs love!', 'honey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'gator', 'gator needs love!', 'gator is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('albina@gmail.com', 'natasha', 'natasha needs love!', 'natasha is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('karrie', 'karrie@gmail.com', 'A user of PCS', 'karriepw');
INSERT INTO PetOwners(email) VALUES ('karrie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karrie@gmail.com', 'moonshine', 'moonshine needs love!', 'moonshine is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karrie@gmail.com', 'angus', 'angus needs love!', 'angus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('karrie@gmail.com', 'chance', 'chance needs love!', 'chance is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karrie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'karrie@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'karrie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karrie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('laverne', 'laverne@gmail.com', 'A user of PCS', 'lavernepw');
INSERT INTO PetOwners(email) VALUES ('laverne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laverne@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('laverne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'laverne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'laverne@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'laverne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'laverne@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laverne@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('laverne@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('deeann', 'deeann@gmail.com', 'A user of PCS', 'deeannpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deeann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'deeann@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'deeann@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'deeann@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'deeann@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'deeann@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('deeann@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('paolo', 'paolo@gmail.com', 'A user of PCS', 'paolopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paolo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'paolo@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'paolo@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paolo@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('karolina', 'karolina@gmail.com', 'A user of PCS', 'karolinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('karolina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'karolina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'karolina@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('karolina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('garek', 'garek@gmail.com', 'A user of PCS', 'garekpw');
INSERT INTO PetOwners(email) VALUES ('garek@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('garek@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('garek@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'garek@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'garek@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('garek@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('vyky', 'vyky@gmail.com', 'A user of PCS', 'vykypw');
INSERT INTO PetOwners(email) VALUES ('vyky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'mimi', 'mimi needs love!', 'mimi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'aldo', 'aldo needs love!', 'aldo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'sly', 'sly needs love!', 'sly is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('vyky@gmail.com', 'ivory', 'ivory needs love!', 'ivory is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vyky@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'vyky@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'vyky@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'vyky@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'vyky@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vyky@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('trudey', 'trudey@gmail.com', 'A user of PCS', 'trudeypw');
INSERT INTO PetOwners(email) VALUES ('trudey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'popcorn', 'popcorn needs love!', 'popcorn is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'elwood', 'elwood needs love!', 'elwood is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'beaux', 'beaux needs love!', 'beaux is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('trudey@gmail.com', 'kipper', 'kipper needs love!', 'kipper is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('chrystel', 'chrystel@gmail.com', 'A user of PCS', 'chrystelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chrystel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (186, 'chrystel@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'chrystel@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chrystel@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chrystel@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ellyn', 'ellyn@gmail.com', 'A user of PCS', 'ellynpw');
INSERT INTO PetOwners(email) VALUES ('ellyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'alexus', 'alexus needs love!', 'alexus is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'rebel', 'rebel needs love!', 'rebel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ellyn@gmail.com', 'frodo', 'frodo needs love!', 'frodo is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ellyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'ellyn@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'ellyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (34, 'ellyn@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (197, 'ellyn@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellyn@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ellyn@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('shirl', 'shirl@gmail.com', 'A user of PCS', 'shirlpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shirl@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (56, 'shirl@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shirl@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shirl@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('dill', 'dill@gmail.com', 'A user of PCS', 'dillpw');
INSERT INTO PetOwners(email) VALUES ('dill@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'mandi', 'mandi needs love!', 'mandi is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'grover', 'grover needs love!', 'grover is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dill@gmail.com', 'mister', 'mister needs love!', 'mister is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dill@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'dill@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (211, 'dill@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'dill@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'dill@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'dill@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dill@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dill@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('miof mela', 'miof mela@gmail.com', 'A user of PCS', 'miof melapw');
INSERT INTO PetOwners(email) VALUES ('miof mela@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('miof mela@gmail.com', 'lovey', 'lovey needs love!', 'lovey is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('miof mela@gmail.com', 'brady', 'brady needs love!', 'brady is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('ulises', 'ulises@gmail.com', 'A user of PCS', 'ulisespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulises@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ulises@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ulises@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ulises@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ulises@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('celesta', 'celesta@gmail.com', 'A user of PCS', 'celestapw');
INSERT INTO PetOwners(email) VALUES ('celesta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('celesta@gmail.com', 'abigail', 'abigail needs love!', 'abigail is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('celesta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (210, 'celesta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'celesta@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'celesta@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celesta@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('celesta@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('charyl', 'charyl@gmail.com', 'A user of PCS', 'charylpw');
INSERT INTO PetOwners(email) VALUES ('charyl@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charyl@gmail.com', 'buttons', 'buttons needs love!', 'buttons is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('randa', 'randa@gmail.com', 'A user of PCS', 'randapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('randa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'randa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'randa@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'randa@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('randa@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('jemimah', 'jemimah@gmail.com', 'A user of PCS', 'jemimahpw');
INSERT INTO PetOwners(email) VALUES ('jemimah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jemimah@gmail.com', 'mo', 'mo needs love!', 'mo is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('pia', 'pia@gmail.com', 'A user of PCS', 'piapw');
INSERT INTO PetOwners(email) VALUES ('pia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pia@gmail.com', 'budda', 'budda needs love!', 'budda is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('pia@gmail.com', 'obie', 'obie needs love!', 'obie is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('clareta', 'clareta@gmail.com', 'A user of PCS', 'claretapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clareta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'clareta@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'clareta@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('clareta@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('samaria', 'samaria@gmail.com', 'A user of PCS', 'samariapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('samaria@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'samaria@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'samaria@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'samaria@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'samaria@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'samaria@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('samaria@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('parry', 'parry@gmail.com', 'A user of PCS', 'parrypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('parry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (54, 'parry@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'parry@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'parry@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'parry@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('parry@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('parry@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('florina', 'florina@gmail.com', 'A user of PCS', 'florinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('florina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'florina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'florina@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'florina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'florina@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('florina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('dacy', 'dacy@gmail.com', 'A user of PCS', 'dacypw');
INSERT INTO PetOwners(email) VALUES ('dacy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'baby-doll', 'baby-doll needs love!', 'baby-doll is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'brindle', 'brindle needs love!', 'brindle is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'jet', 'jet needs love!', 'jet is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'gigi', 'gigi needs love!', 'gigi is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dacy@gmail.com', 'dude', 'dude needs love!', 'dude is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('kennan', 'kennan@gmail.com', 'A user of PCS', 'kennanpw');
INSERT INTO PetOwners(email) VALUES ('kennan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kennan@gmail.com', 'diego', 'diego needs love!', 'diego is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kennan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'kennan@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kennan@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kennan@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('deeyn', 'deeyn@gmail.com', 'A user of PCS', 'deeynpw');
INSERT INTO PetOwners(email) VALUES ('deeyn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'kid', 'kid needs love!', 'kid is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'gavin', 'gavin needs love!', 'gavin is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'mouse', 'mouse needs love!', 'mouse is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('deeyn@gmail.com', 'connor', 'connor needs love!', 'connor is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('deeyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (203, 'deeyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'deeyn@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'deeyn@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('deeyn@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('barney', 'barney@gmail.com', 'A user of PCS', 'barneypw');
INSERT INTO PetOwners(email) VALUES ('barney@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'shelly', 'shelly needs love!', 'shelly is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'mugsy', 'mugsy needs love!', 'mugsy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'morgan', 'morgan needs love!', 'morgan is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barney@gmail.com', 'cherokee', 'cherokee needs love!', 'cherokee is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('barney@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'barney@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'barney@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('barney@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('reggi', 'reggi@gmail.com', 'A user of PCS', 'reggipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('reggi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'reggi@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reggi@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('reggi@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('jany', 'jany@gmail.com', 'A user of PCS', 'janypw');
INSERT INTO PetOwners(email) VALUES ('jany@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'bishop', 'bishop needs love!', 'bishop is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'muffy', 'muffy needs love!', 'muffy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'braggs', 'braggs needs love!', 'braggs is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'silky', 'silky needs love!', 'silky is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jany@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('innis', 'innis@gmail.com', 'A user of PCS', 'innispw');
INSERT INTO PetOwners(email) VALUES ('innis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('innis@gmail.com', 'dexter', 'dexter needs love!', 'dexter is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('eunice', 'eunice@gmail.com', 'A user of PCS', 'eunicepw');
INSERT INTO PetOwners(email) VALUES ('eunice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eunice@gmail.com', 'joe', 'joe needs love!', 'joe is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eunice@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'eunice@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eunice@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eunice@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('shannan', 'shannan@gmail.com', 'A user of PCS', 'shannanpw');
INSERT INTO PetOwners(email) VALUES ('shannan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannan@gmail.com', 'jagger', 'jagger needs love!', 'jagger is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannan@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannan@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('shannan@gmail.com', 'nico', 'nico needs love!', 'nico is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('isaiah', 'isaiah@gmail.com', 'A user of PCS', 'isaiahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isaiah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'isaiah@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'isaiah@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'isaiah@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isaiah@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hesther', 'hesther@gmail.com', 'A user of PCS', 'hestherpw');
INSERT INTO PetOwners(email) VALUES ('hesther@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hesther@gmail.com', 'jaguar', 'jaguar needs love!', 'jaguar is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hesther@gmail.com', 'queen', 'queen needs love!', 'queen is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hesther@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'hesther@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hesther@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('albertine', 'albertine@gmail.com', 'A user of PCS', 'albertinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('albertine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'albertine@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'albertine@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('albertine@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('albertine@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('jorey', 'jorey@gmail.com', 'A user of PCS', 'joreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jorey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (175, 'jorey@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (92, 'jorey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'jorey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'jorey@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'jorey@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorey@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jorey@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('lib', 'lib@gmail.com', 'A user of PCS', 'libpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lib@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'lib@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lib@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('lib@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('levey', 'levey@gmail.com', 'A user of PCS', 'leveypw');
INSERT INTO PetOwners(email) VALUES ('levey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('levey@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('levey@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'levey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (247, 'levey@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'levey@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'levey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (156, 'levey@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('levey@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('levey@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('jeremy', 'jeremy@gmail.com', 'A user of PCS', 'jeremypw');
INSERT INTO PetOwners(email) VALUES ('jeremy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeremy@gmail.com', 'ryder', 'ryder needs love!', 'ryder is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeremy@gmail.com', 'phoenix', 'phoenix needs love!', 'phoenix is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeremy@gmail.com', 'kellie', 'kellie needs love!', 'kellie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeremy@gmail.com', 'dozer', 'dozer needs love!', 'dozer is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jeremy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'jeremy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'jeremy@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'jeremy@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeremy@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jeremy@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('chrissy', 'chrissy@gmail.com', 'A user of PCS', 'chrissypw');
INSERT INTO PetOwners(email) VALUES ('chrissy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chrissy@gmail.com', 'autumn', 'autumn needs love!', 'autumn is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chrissy@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'chrissy@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'chrissy@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'chrissy@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('chrissy@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dianemarie', 'dianemarie@gmail.com', 'A user of PCS', 'dianemariepw');
INSERT INTO PetOwners(email) VALUES ('dianemarie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dianemarie@gmail.com', 'benny', 'benny needs love!', 'benny is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('andromache', 'andromache@gmail.com', 'A user of PCS', 'andromachepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andromache@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'andromache@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andromache@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andromache@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('emmy', 'emmy@gmail.com', 'A user of PCS', 'emmypw');
INSERT INTO PetOwners(email) VALUES ('emmy@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'gunner', 'gunner needs love!', 'gunner is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'billie', 'billie needs love!', 'billie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'cosmo', 'cosmo needs love!', 'cosmo is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emmy@gmail.com', 'grover', 'grover needs love!', 'grover is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emmy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'emmy@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'emmy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (122, 'emmy@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emmy@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emmy@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('tallia', 'tallia@gmail.com', 'A user of PCS', 'talliapw');
INSERT INTO PetOwners(email) VALUES ('tallia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallia@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallia@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallia@gmail.com', 'mona', 'mona needs love!', 'mona is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallia@gmail.com', 'pinto', 'pinto needs love!', 'pinto is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tallia@gmail.com', 'conan', 'conan needs love!', 'conan is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('hedwiga', 'hedwiga@gmail.com', 'A user of PCS', 'hedwigapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hedwiga@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (97, 'hedwiga@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'hedwiga@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'hedwiga@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (185, 'hedwiga@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hedwiga@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hedwiga@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('nerta', 'nerta@gmail.com', 'A user of PCS', 'nertapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nerta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (104, 'nerta@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'nerta@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'nerta@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerta@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nerta@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('mollie', 'mollie@gmail.com', 'A user of PCS', 'molliepw');
INSERT INTO PetOwners(email) VALUES ('mollie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollie@gmail.com', 'bucky', 'bucky needs love!', 'bucky is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollie@gmail.com', 'gasby', 'gasby needs love!', 'gasby is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollie@gmail.com', 'rambo', 'rambo needs love!', 'rambo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mollie@gmail.com', 'barkley', 'barkley needs love!', 'barkley is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mollie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'mollie@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'mollie@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('cristen', 'cristen@gmail.com', 'A user of PCS', 'cristenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cristen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'cristen@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'cristen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'cristen@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'cristen@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristen@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cristen@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('kipper', 'kipper@gmail.com', 'A user of PCS', 'kipperpw');
INSERT INTO PetOwners(email) VALUES ('kipper@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kipper@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kipper@gmail.com', 'noel', 'noel needs love!', 'noel is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kipper@gmail.com', 'polly', 'polly needs love!', 'polly is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kipper@gmail.com', 'comet', 'comet needs love!', 'comet is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('fernando', 'fernando@gmail.com', 'A user of PCS', 'fernandopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fernando@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'fernando@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fernando@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fernando@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dorey', 'dorey@gmail.com', 'A user of PCS', 'doreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dorey@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dorey@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorey@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('emanuele', 'emanuele@gmail.com', 'A user of PCS', 'emanuelepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emanuele@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'emanuele@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emanuele@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emanuele@gmail.com', '2022-08-01');

INSERT INTO Users(name, email, description, password) VALUES ('alie', 'alie@gmail.com', 'A user of PCS', 'aliepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'alie@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'alie@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'alie@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'alie@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('alie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('anderson', 'anderson@gmail.com', 'A user of PCS', 'andersonpw');
INSERT INTO PetOwners(email) VALUES ('anderson@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'bob', 'bob needs love!', 'bob is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'finnegan', 'finnegan needs love!', 'finnegan is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('anderson@gmail.com', 'pippin', 'pippin needs love!', 'pippin is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anderson@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'anderson@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'anderson@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'anderson@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('anderson@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('fletch', 'fletch@gmail.com', 'A user of PCS', 'fletchpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fletch@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'fletch@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (196, 'fletch@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'fletch@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fletch@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fletch@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('jeni', 'jeni@gmail.com', 'A user of PCS', 'jenipw');
INSERT INTO PetOwners(email) VALUES ('jeni@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeni@gmail.com', 'kyra', 'kyra needs love!', 'kyra is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeni@gmail.com', 'misha', 'misha needs love!', 'misha is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeni@gmail.com', 'lili', 'lili needs love!', 'lili is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jeni@gmail.com', 'lexi', 'lexi needs love!', 'lexi is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('millard', 'millard@gmail.com', 'A user of PCS', 'millardpw');
INSERT INTO PetOwners(email) VALUES ('millard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('millard@gmail.com', 'ginger', 'ginger needs love!', 'ginger is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('millard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'millard@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'millard@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('millard@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('johann', 'johann@gmail.com', 'A user of PCS', 'johannpw');
INSERT INTO PetOwners(email) VALUES ('johann@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'barley', 'barley needs love!', 'barley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'nick', 'nick needs love!', 'nick is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'ruger', 'ruger needs love!', 'ruger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('johann@gmail.com', 'luna', 'luna needs love!', 'luna is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('johann@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'johann@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'johann@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('johann@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('shelden', 'shelden@gmail.com', 'A user of PCS', 'sheldenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shelden@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'shelden@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (61, 'shelden@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'shelden@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (125, 'shelden@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (169, 'shelden@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('shelden@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('calv', 'calv@gmail.com', 'A user of PCS', 'calvpw');
INSERT INTO PetOwners(email) VALUES ('calv@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'cleo', 'cleo needs love!', 'cleo is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'monty', 'monty needs love!', 'monty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'champ', 'champ needs love!', 'champ is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'dunn', 'dunn needs love!', 'dunn is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('calv@gmail.com', 'lucas', 'lucas needs love!', 'lucas is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('chance', 'chance@gmail.com', 'A user of PCS', 'chancepw');
INSERT INTO PetOwners(email) VALUES ('chance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('chance@gmail.com', 'skyler', 'skyler needs love!', 'skyler is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('chance@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'chance@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'chance@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (190, 'chance@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'chance@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chance@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('chance@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('iggie', 'iggie@gmail.com', 'A user of PCS', 'iggiepw');
INSERT INTO PetOwners(email) VALUES ('iggie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('iggie@gmail.com', 'killian', 'killian needs love!', 'killian is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('iggie@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('iggie@gmail.com', 'domino', 'domino needs love!', 'domino is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('iggie@gmail.com', 'ivy', 'ivy needs love!', 'ivy is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iggie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'iggie@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('iggie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('roxie', 'roxie@gmail.com', 'A user of PCS', 'roxiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roxie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'roxie@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roxie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('roxie@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('augustina', 'augustina@gmail.com', 'A user of PCS', 'augustinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('augustina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'augustina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'augustina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'augustina@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'augustina@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('augustina@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('frederick', 'frederick@gmail.com', 'A user of PCS', 'frederickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('frederick@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (65, 'frederick@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'frederick@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('frederick@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('frederick@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('fara', 'fara@gmail.com', 'A user of PCS', 'farapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fara@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'fara@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fara@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('fara@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('paula', 'paula@gmail.com', 'A user of PCS', 'paulapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('paula@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'paula@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'paula@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'paula@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'paula@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('paula@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('vernen', 'vernen@gmail.com', 'A user of PCS', 'vernenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vernen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'vernen@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('vernen@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('eugenio', 'eugenio@gmail.com', 'A user of PCS', 'eugeniopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eugenio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'eugenio@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'eugenio@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'eugenio@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eugenio@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('tamqrah', 'tamqrah@gmail.com', 'A user of PCS', 'tamqrahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tamqrah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (181, 'tamqrah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (206, 'tamqrah@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tamqrah@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('tamqrah@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('xenia', 'xenia@gmail.com', 'A user of PCS', 'xeniapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xenia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'xenia@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xenia@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gawen', 'gawen@gmail.com', 'A user of PCS', 'gawenpw');
INSERT INTO PetOwners(email) VALUES ('gawen@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gawen@gmail.com', 'jett', 'jett needs love!', 'jett is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gawen@gmail.com', 'amber', 'amber needs love!', 'amber is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gawen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gawen@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gawen@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('elsi', 'elsi@gmail.com', 'A user of PCS', 'elsipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'elsi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'elsi@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (134, 'elsi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (124, 'elsi@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsi@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('elsi@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('elwira', 'elwira@gmail.com', 'A user of PCS', 'elwirapw');
INSERT INTO PetOwners(email) VALUES ('elwira@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elwira@gmail.com', 'nero', 'nero needs love!', 'nero is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elwira@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'elwira@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'elwira@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'elwira@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'elwira@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elwira@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('beck', 'beck@gmail.com', 'A user of PCS', 'beckpw');
INSERT INTO PetOwners(email) VALUES ('beck@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beck@gmail.com', 'koko', 'koko needs love!', 'koko is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('otho', 'otho@gmail.com', 'A user of PCS', 'othopw');
INSERT INTO PetOwners(email) VALUES ('otho@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otho@gmail.com', 'doodles', 'doodles needs love!', 'doodles is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otho@gmail.com', 'poochie', 'poochie needs love!', 'poochie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otho@gmail.com', 'bruno', 'bruno needs love!', 'bruno is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otho@gmail.com', 'cubby', 'cubby needs love!', 'cubby is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('otho@gmail.com', 'buzzy', 'buzzy needs love!', 'buzzy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('byrle', 'byrle@gmail.com', 'A user of PCS', 'byrlepw');
INSERT INTO PetOwners(email) VALUES ('byrle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrle@gmail.com', 'baron', 'baron needs love!', 'baron is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('byrle@gmail.com', 'kiki', 'kiki needs love!', 'kiki is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('byrle@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'byrle@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('byrle@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('rriocard', 'rriocard@gmail.com', 'A user of PCS', 'rriocardpw');
INSERT INTO PetOwners(email) VALUES ('rriocard@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rriocard@gmail.com', 'smarty', 'smarty needs love!', 'smarty is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rriocard@gmail.com', 'jester', 'jester needs love!', 'jester is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rriocard@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rriocard@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'rriocard@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rriocard@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'rriocard@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'rriocard@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rriocard@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('arabelle', 'arabelle@gmail.com', 'A user of PCS', 'arabellepw');
INSERT INTO PetOwners(email) VALUES ('arabelle@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'chanel', 'chanel needs love!', 'chanel is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'ruffles', 'ruffles needs love!', 'ruffles is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'bella', 'bella needs love!', 'bella is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arabelle@gmail.com', 'lassie', 'lassie needs love!', 'lassie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('wynne', 'wynne@gmail.com', 'A user of PCS', 'wynnepw');
INSERT INTO PetOwners(email) VALUES ('wynne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'sable', 'sable needs love!', 'sable is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'dempsey', 'dempsey needs love!', 'dempsey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'kelly', 'kelly needs love!', 'kelly is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynne@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('harbert', 'harbert@gmail.com', 'A user of PCS', 'harbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('harbert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'harbert@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (77, 'harbert@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'harbert@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (155, 'harbert@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'harbert@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('harbert@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('ravi', 'ravi@gmail.com', 'A user of PCS', 'ravipw');
INSERT INTO PetOwners(email) VALUES ('ravi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ravi@gmail.com', 'elvis', 'elvis needs love!', 'elvis is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ravi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ravi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ravi@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ravi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ravi@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ravi@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('clair', 'clair@gmail.com', 'A user of PCS', 'clairpw');
INSERT INTO PetOwners(email) VALUES ('clair@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('clair@gmail.com', 'mona', 'mona needs love!', 'mona is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clair@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'clair@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'clair@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'clair@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clair@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('dwight', 'dwight@gmail.com', 'A user of PCS', 'dwightpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dwight@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dwight@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'dwight@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'dwight@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dwight@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('denis', 'denis@gmail.com', 'A user of PCS', 'denispw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denis@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'denis@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denis@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('saree', 'saree@gmail.com', 'A user of PCS', 'sareepw');
INSERT INTO PetOwners(email) VALUES ('saree@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'josie', 'josie needs love!', 'josie is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'piper', 'piper needs love!', 'piper is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'bridgett', 'bridgett needs love!', 'bridgett is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('saree@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('saree@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'saree@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'saree@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'saree@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('saree@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('haleigh', 'haleigh@gmail.com', 'A user of PCS', 'haleighpw');
INSERT INTO PetOwners(email) VALUES ('haleigh@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haleigh@gmail.com', 'shady', 'shady needs love!', 'shady is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haleigh@gmail.com', 'india', 'india needs love!', 'india is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haleigh@gmail.com', 'salem', 'salem needs love!', 'salem is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('haleigh@gmail.com', 'alf', 'alf needs love!', 'alf is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('haleigh@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'haleigh@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haleigh@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('haleigh@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('caty', 'caty@gmail.com', 'A user of PCS', 'catypw');
INSERT INTO PetOwners(email) VALUES ('caty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'bobbie', 'bobbie needs love!', 'bobbie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'lucifer', 'lucifer needs love!', 'lucifer is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'brandi', 'brandi needs love!', 'brandi is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'hardy', 'hardy needs love!', 'hardy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('caty@gmail.com', 'brando', 'brando needs love!', 'brando is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('somerset', 'somerset@gmail.com', 'A user of PCS', 'somersetpw');
INSERT INTO PetOwners(email) VALUES ('somerset@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('somerset@gmail.com', 'pudge', 'pudge needs love!', 'pudge is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('somerset@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'somerset@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('somerset@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('somerset@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('natalina', 'natalina@gmail.com', 'A user of PCS', 'natalinapw');
INSERT INTO PetOwners(email) VALUES ('natalina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'mercedes', 'mercedes needs love!', 'mercedes is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'kona', 'kona needs love!', 'kona is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'silver', 'silver needs love!', 'silver is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'buck', 'buck needs love!', 'buck is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natalina@gmail.com', 'buster', 'buster needs love!', 'buster is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('natalina@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'natalina@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'natalina@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natalina@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ranna', 'ranna@gmail.com', 'A user of PCS', 'rannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ranna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ranna@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ranna@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ranna@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ranna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ranna@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ranna@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('james', 'james@gmail.com', 'A user of PCS', 'jamespw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('james@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'james@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'james@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('james@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('james@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('fayre', 'fayre@gmail.com', 'A user of PCS', 'fayrepw');
INSERT INTO PetOwners(email) VALUES ('fayre@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fayre@gmail.com', 'nellie', 'nellie needs love!', 'nellie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('fayre@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fayre@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fayre@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'fayre@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'fayre@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'fayre@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fayre@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fayre@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('shurlocke', 'shurlocke@gmail.com', 'A user of PCS', 'shurlockepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('shurlocke@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'shurlocke@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('shurlocke@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('gradeigh', 'gradeigh@gmail.com', 'A user of PCS', 'gradeighpw');
INSERT INTO PetOwners(email) VALUES ('gradeigh@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gradeigh@gmail.com', 'bunky', 'bunky needs love!', 'bunky is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gradeigh@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'gradeigh@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'gradeigh@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'gradeigh@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'gradeigh@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gradeigh@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gradeigh@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('ezechiel', 'ezechiel@gmail.com', 'A user of PCS', 'ezechielpw');
INSERT INTO PetOwners(email) VALUES ('ezechiel@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ezechiel@gmail.com', 'fuzzy', 'fuzzy needs love!', 'fuzzy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ezechiel@gmail.com', 'poncho', 'poncho needs love!', 'poncho is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ezechiel@gmail.com', 'isabella', 'isabella needs love!', 'isabella is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ezechiel@gmail.com', 'boy', 'boy needs love!', 'boy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ezechiel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ezechiel@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ezechiel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ezechiel@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ezechiel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ezechiel@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ezechiel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('elsworth', 'elsworth@gmail.com', 'A user of PCS', 'elsworthpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsworth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'elsworth@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsworth@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('reynolds', 'reynolds@gmail.com', 'A user of PCS', 'reynoldspw');
INSERT INTO PetOwners(email) VALUES ('reynolds@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'rusty', 'rusty needs love!', 'rusty is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'bob', 'bob needs love!', 'bob is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'alf', 'alf needs love!', 'alf is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'smarty', 'smarty needs love!', 'smarty is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('reynolds@gmail.com', 'felix', 'felix needs love!', 'felix is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('gui', 'gui@gmail.com', 'A user of PCS', 'guipw');
INSERT INTO PetOwners(email) VALUES ('gui@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'panther', 'panther needs love!', 'panther is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'persy', 'persy needs love!', 'persy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gui@gmail.com', 'jackie', 'jackie needs love!', 'jackie is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('oberon', 'oberon@gmail.com', 'A user of PCS', 'oberonpw');
INSERT INTO PetOwners(email) VALUES ('oberon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'cosmo', 'cosmo needs love!', 'cosmo is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'morgan', 'morgan needs love!', 'morgan is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'popcorn', 'popcorn needs love!', 'popcorn is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('oberon@gmail.com', 'billy', 'billy needs love!', 'billy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('francis', 'francis@gmail.com', 'A user of PCS', 'francispw');
INSERT INTO PetOwners(email) VALUES ('francis@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francis@gmail.com', 'oscar', 'oscar needs love!', 'oscar is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francis@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francis@gmail.com', 'checkers', 'checkers needs love!', 'checkers is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francis@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francis@gmail.com', 'shiner', 'shiner needs love!', 'shiner is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('gunner', 'gunner@gmail.com', 'A user of PCS', 'gunnerpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gunner@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (212, 'gunner@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunner@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gunner@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('abagael', 'abagael@gmail.com', 'A user of PCS', 'abagaelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('abagael@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'abagael@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('abagael@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('estella', 'estella@gmail.com', 'A user of PCS', 'estellapw');
INSERT INTO PetOwners(email) VALUES ('estella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estella@gmail.com', 'peter', 'peter needs love!', 'peter is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estella@gmail.com', 'butter', 'butter needs love!', 'butter is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('estella@gmail.com', 'panther', 'panther needs love!', 'panther is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'estella@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'estella@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'estella@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estella@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('xerxes', 'xerxes@gmail.com', 'A user of PCS', 'xerxespw');
INSERT INTO PetOwners(email) VALUES ('xerxes@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'phoenix', 'phoenix needs love!', 'phoenix is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'belle', 'belle needs love!', 'belle is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'ajax', 'ajax needs love!', 'ajax is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xerxes@gmail.com', 'ashes', 'ashes needs love!', 'ashes is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xerxes@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'xerxes@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xerxes@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xerxes@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('marie-jeanne', 'marie-jeanne@gmail.com', 'A user of PCS', 'marie-jeannepw');
INSERT INTO PetOwners(email) VALUES ('marie-jeanne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-jeanne@gmail.com', 'axel', 'axel needs love!', 'axel is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-jeanne@gmail.com', 'emily', 'emily needs love!', 'emily is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-jeanne@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marie-jeanne@gmail.com', 'scruffy', 'scruffy needs love!', 'scruffy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marie-jeanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (81, 'marie-jeanne@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marie-jeanne@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marie-jeanne@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('averil', 'averil@gmail.com', 'A user of PCS', 'averilpw');
INSERT INTO PetOwners(email) VALUES ('averil@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'noel', 'noel needs love!', 'noel is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'curly', 'curly needs love!', 'curly is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('averil@gmail.com', 'rosy', 'rosy needs love!', 'rosy is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('lucille', 'lucille@gmail.com', 'A user of PCS', 'lucillepw');
INSERT INTO PetOwners(email) VALUES ('lucille@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lucille@gmail.com', 'bebe', 'bebe needs love!', 'bebe is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lucille@gmail.com', 'maggy', 'maggy needs love!', 'maggy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lucille@gmail.com', 'gracie', 'gracie needs love!', 'gracie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lucille@gmail.com', 'blanche', 'blanche needs love!', 'blanche is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('lucille@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'lucille@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'lucille@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'lucille@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('lucille@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('mollee', 'mollee@gmail.com', 'A user of PCS', 'molleepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('mollee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'mollee@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('mollee@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('gabriellia', 'gabriellia@gmail.com', 'A user of PCS', 'gabrielliapw');
INSERT INTO PetOwners(email) VALUES ('gabriellia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'nosey', 'nosey needs love!', 'nosey is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'chaz', 'chaz needs love!', 'chaz is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'beamer', 'beamer needs love!', 'beamer is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'moonshine', 'moonshine needs love!', 'moonshine is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gabriellia@gmail.com', 'niko', 'niko needs love!', 'niko is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('everett', 'everett@gmail.com', 'A user of PCS', 'everettpw');
INSERT INTO PetOwners(email) VALUES ('everett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('everett@gmail.com', 'chad', 'chad needs love!', 'chad is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('everett@gmail.com', 'boss', 'boss needs love!', 'boss is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('everett@gmail.com', 'holly', 'holly needs love!', 'holly is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('everett@gmail.com', 'peanuts', 'peanuts needs love!', 'peanuts is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('everett@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'everett@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (239, 'everett@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'everett@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (151, 'everett@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('everett@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('everett@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('kissee', 'kissee@gmail.com', 'A user of PCS', 'kisseepw');
INSERT INTO PetOwners(email) VALUES ('kissee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'rin tin tin', 'rin tin tin needs love!', 'rin tin tin is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'shaggy', 'shaggy needs love!', 'shaggy is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kissee@gmail.com', 'paddy', 'paddy needs love!', 'paddy is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kissee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'kissee@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'kissee@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'kissee@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('kissee@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('cletus', 'cletus@gmail.com', 'A user of PCS', 'cletuspw');
INSERT INTO PetOwners(email) VALUES ('cletus@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('cletus@gmail.com', 'binky', 'binky needs love!', 'binky is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cletus@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'cletus@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cletus@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cletus@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'cletus@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cletus@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('yolane', 'yolane@gmail.com', 'A user of PCS', 'yolanepw');
INSERT INTO PetOwners(email) VALUES ('yolane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('yolane@gmail.com', 'brodie', 'brodie needs love!', 'brodie is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yolane@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'yolane@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'yolane@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'yolane@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yolane@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('francesca', 'francesca@gmail.com', 'A user of PCS', 'francescapw');
INSERT INTO PetOwners(email) VALUES ('francesca@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francesca@gmail.com', 'pedro', 'pedro needs love!', 'pedro is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francesca@gmail.com', 'kirby', 'kirby needs love!', 'kirby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francesca@gmail.com', 'gordon', 'gordon needs love!', 'gordon is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('francesca@gmail.com', 'little-guy', 'little-guy needs love!', 'little-guy is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('francesca@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'francesca@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('francesca@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('farah', 'farah@gmail.com', 'A user of PCS', 'farahpw');
INSERT INTO PetOwners(email) VALUES ('farah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('farah@gmail.com', 'destini', 'destini needs love!', 'destini is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('farah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'farah@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'farah@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('farah@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('susanne', 'susanne@gmail.com', 'A user of PCS', 'susannepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('susanne@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (158, 'susanne@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'susanne@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (172, 'susanne@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('susanne@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('susanne@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('joyan', 'joyan@gmail.com', 'A user of PCS', 'joyanpw');
INSERT INTO PetOwners(email) VALUES ('joyan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'dante', 'dante needs love!', 'dante is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'buffie', 'buffie needs love!', 'buffie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('joyan@gmail.com', 'mandy', 'mandy needs love!', 'mandy is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('illa', 'illa@gmail.com', 'A user of PCS', 'illapw');
INSERT INTO PetOwners(email) VALUES ('illa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('illa@gmail.com', 'lassie', 'lassie needs love!', 'lassie is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('egan', 'egan@gmail.com', 'A user of PCS', 'eganpw');
INSERT INTO PetOwners(email) VALUES ('egan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'chrissy', 'chrissy needs love!', 'chrissy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'dharma', 'dharma needs love!', 'dharma is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('egan@gmail.com', 'gasby', 'gasby needs love!', 'gasby is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('corrina', 'corrina@gmail.com', 'A user of PCS', 'corrinapw');
INSERT INTO PetOwners(email) VALUES ('corrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'duncan', 'duncan needs love!', 'duncan is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'buster-brown', 'buster-brown needs love!', 'buster-brown is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('corrina@gmail.com', 'fiona', 'fiona needs love!', 'fiona is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('corrina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'corrina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'corrina@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (160, 'corrina@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'corrina@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'corrina@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('corrina@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('corrina@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('idette', 'idette@gmail.com', 'A user of PCS', 'idettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('idette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'idette@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'idette@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'idette@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('idette@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('megen', 'megen@gmail.com', 'A user of PCS', 'megenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('megen@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'megen@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('megen@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('germayne', 'germayne@gmail.com', 'A user of PCS', 'germaynepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('germayne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'germayne@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'germayne@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'germayne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'germayne@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('germayne@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('jessi', 'jessi@gmail.com', 'A user of PCS', 'jessipw');
INSERT INTO PetOwners(email) VALUES ('jessi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'freedom', 'freedom needs love!', 'freedom is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'rags', 'rags needs love!', 'rags is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jessi@gmail.com', 'brady', 'brady needs love!', 'brady is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('tiffanie', 'tiffanie@gmail.com', 'A user of PCS', 'tiffaniepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tiffanie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'tiffanie@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tiffanie@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('rolph', 'rolph@gmail.com', 'A user of PCS', 'rolphpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rolph@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'rolph@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'rolph@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (146, 'rolph@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rolph@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rolph@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('omar', 'omar@gmail.com', 'A user of PCS', 'omarpw');
INSERT INTO PetOwners(email) VALUES ('omar@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('omar@gmail.com', 'audi', 'audi needs love!', 'audi is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('carmina', 'carmina@gmail.com', 'A user of PCS', 'carminapw');
INSERT INTO PetOwners(email) VALUES ('carmina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'hanna', 'hanna needs love!', 'hanna is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'eddy', 'eddy needs love!', 'eddy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'smarty', 'smarty needs love!', 'smarty is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'madison', 'madison needs love!', 'madison is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('carmina@gmail.com', 'bb', 'bb needs love!', 'bb is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('jasen', 'jasen@gmail.com', 'A user of PCS', 'jasenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jasen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'jasen@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'jasen@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (111, 'jasen@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (138, 'jasen@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jasen@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('madalena', 'madalena@gmail.com', 'A user of PCS', 'madalenapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madalena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'madalena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'madalena@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (152, 'madalena@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madalena@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madalena@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('tarrah', 'tarrah@gmail.com', 'A user of PCS', 'tarrahpw');
INSERT INTO PetOwners(email) VALUES ('tarrah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'chivas', 'chivas needs love!', 'chivas is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'aldo', 'aldo needs love!', 'aldo is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tarrah@gmail.com', 'hans', 'hans needs love!', 'hans is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('danna', 'danna@gmail.com', 'A user of PCS', 'dannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('danna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'danna@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'danna@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('danna@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('orazio', 'orazio@gmail.com', 'A user of PCS', 'oraziopw');
INSERT INTO PetOwners(email) VALUES ('orazio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orazio@gmail.com', 'parker', 'parker needs love!', 'parker is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orazio@gmail.com', 'dozer', 'dozer needs love!', 'dozer is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orazio@gmail.com', 'brownie', 'brownie needs love!', 'brownie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orazio@gmail.com', 'gromit', 'gromit needs love!', 'gromit is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('orazio@gmail.com', 'mulligan', 'mulligan needs love!', 'mulligan is a Mouse', 'Mouse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('orazio@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'orazio@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'orazio@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'orazio@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (96, 'orazio@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('orazio@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('orazio@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('bertha', 'bertha@gmail.com', 'A user of PCS', 'berthapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bertha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'bertha@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'bertha@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bertha@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bertha@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('merry', 'merry@gmail.com', 'A user of PCS', 'merrypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('merry@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'merry@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'merry@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (51, 'merry@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merry@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('merry@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('linzy', 'linzy@gmail.com', 'A user of PCS', 'linzypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('linzy@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'linzy@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (108, 'linzy@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'linzy@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (202, 'linzy@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('linzy@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('sorcha', 'sorcha@gmail.com', 'A user of PCS', 'sorchapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sorcha@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'sorcha@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'sorcha@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'sorcha@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (193, 'sorcha@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sorcha@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('sorcha@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('milzie', 'milzie@gmail.com', 'A user of PCS', 'milziepw');
INSERT INTO PetOwners(email) VALUES ('milzie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milzie@gmail.com', 'holly', 'holly needs love!', 'holly is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milzie@gmail.com', 'flower', 'flower needs love!', 'flower is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('milzie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'milzie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'milzie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'milzie@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'milzie@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('milzie@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('ryley', 'ryley@gmail.com', 'A user of PCS', 'ryleypw');
INSERT INTO PetOwners(email) VALUES ('ryley@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'flint', 'flint needs love!', 'flint is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'slick', 'slick needs love!', 'slick is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'otis', 'otis needs love!', 'otis is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ryley@gmail.com', 'pearl', 'pearl needs love!', 'pearl is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ryley@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ryley@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ryley@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ryley@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('rafi', 'rafi@gmail.com', 'A user of PCS', 'rafipw');
INSERT INTO PetOwners(email) VALUES ('rafi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafi@gmail.com', 'max', 'max needs love!', 'max is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rafi@gmail.com', 'ricky', 'ricky needs love!', 'ricky is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('analise', 'analise@gmail.com', 'A user of PCS', 'analisepw');
INSERT INTO PetOwners(email) VALUES ('analise@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'april', 'april needs love!', 'april is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('analise@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('analise@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'analise@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('analise@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('constantia', 'constantia@gmail.com', 'A user of PCS', 'constantiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('constantia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'constantia@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'constantia@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('constantia@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('forster', 'forster@gmail.com', 'A user of PCS', 'forsterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('forster@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (142, 'forster@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'forster@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'forster@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('forster@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('forster@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcelline', 'marcelline@gmail.com', 'A user of PCS', 'marcellinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marcelline@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'marcelline@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'marcelline@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'marcelline@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('marcelline@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('gillan', 'gillan@gmail.com', 'A user of PCS', 'gillanpw');
INSERT INTO PetOwners(email) VALUES ('gillan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gillan@gmail.com', 'blackie', 'blackie needs love!', 'blackie is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('natividad', 'natividad@gmail.com', 'A user of PCS', 'natividadpw');
INSERT INTO PetOwners(email) VALUES ('natividad@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'rocket', 'rocket needs love!', 'rocket is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('natividad@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('natividad@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'natividad@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'natividad@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'natividad@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('natividad@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('verla', 'verla@gmail.com', 'A user of PCS', 'verlapw');
INSERT INTO PetOwners(email) VALUES ('verla@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'shaggy', 'shaggy needs love!', 'shaggy is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('verla@gmail.com', 'buster', 'buster needs love!', 'buster is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('verla@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'verla@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'verla@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('verla@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('verla@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('catrina', 'catrina@gmail.com', 'A user of PCS', 'catrinapw');
INSERT INTO PetOwners(email) VALUES ('catrina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catrina@gmail.com', 'flash', 'flash needs love!', 'flash is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('milicent', 'milicent@gmail.com', 'A user of PCS', 'milicentpw');
INSERT INTO PetOwners(email) VALUES ('milicent@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('milicent@gmail.com', 'baxter', 'baxter needs love!', 'baxter is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('antonella', 'antonella@gmail.com', 'A user of PCS', 'antonellapw');
INSERT INTO PetOwners(email) VALUES ('antonella@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('antonella@gmail.com', 'boy', 'boy needs love!', 'boy is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('antonella@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'antonella@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'antonella@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'antonella@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'antonella@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('antonella@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('darnall', 'darnall@gmail.com', 'A user of PCS', 'darnallpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darnall@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'darnall@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'darnall@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'darnall@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darnall@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('denny', 'denny@gmail.com', 'A user of PCS', 'dennypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('denny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'denny@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'denny@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'denny@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('denny@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('boyd', 'boyd@gmail.com', 'A user of PCS', 'boydpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('boyd@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'boyd@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'boyd@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'boyd@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'boyd@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'boyd@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('boyd@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('roseanna', 'roseanna@gmail.com', 'A user of PCS', 'roseannapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('roseanna@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'roseanna@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('roseanna@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('vassily', 'vassily@gmail.com', 'A user of PCS', 'vassilypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('vassily@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'vassily@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'vassily@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'vassily@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('vassily@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('ulrike', 'ulrike@gmail.com', 'A user of PCS', 'ulrikepw');
INSERT INTO PetOwners(email) VALUES ('ulrike@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'autumn', 'autumn needs love!', 'autumn is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'newton', 'newton needs love!', 'newton is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ulrike@gmail.com', 'echo', 'echo needs love!', 'echo is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ulrike@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'ulrike@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'ulrike@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (109, 'ulrike@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'ulrike@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'ulrike@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulrike@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ulrike@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('coraline', 'coraline@gmail.com', 'A user of PCS', 'coralinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('coraline@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'coraline@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'coraline@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'coraline@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'coraline@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'coraline@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('coraline@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('gilli', 'gilli@gmail.com', 'A user of PCS', 'gillipw');
INSERT INTO PetOwners(email) VALUES ('gilli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gilli@gmail.com', 'patty', 'patty needs love!', 'patty is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('laraine', 'laraine@gmail.com', 'A user of PCS', 'larainepw');
INSERT INTO PetOwners(email) VALUES ('laraine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laraine@gmail.com', 'cosmo', 'cosmo needs love!', 'cosmo is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laraine@gmail.com', 'mikey', 'mikey needs love!', 'mikey is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laraine@gmail.com', 'luna', 'luna needs love!', 'luna is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('laraine@gmail.com', 'guido', 'guido needs love!', 'guido is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('barrett', 'barrett@gmail.com', 'A user of PCS', 'barrettpw');
INSERT INTO PetOwners(email) VALUES ('barrett@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barrett@gmail.com', 'bugsey', 'bugsey needs love!', 'bugsey is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barrett@gmail.com', 'picasso', 'picasso needs love!', 'picasso is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barrett@gmail.com', 'hardy', 'hardy needs love!', 'hardy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barrett@gmail.com', 'reilly', 'reilly needs love!', 'reilly is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('barrett@gmail.com', 'ally', 'ally needs love!', 'ally is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('katharyn', 'katharyn@gmail.com', 'A user of PCS', 'katharynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('katharyn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'katharyn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (207, 'katharyn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (179, 'katharyn@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'katharyn@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katharyn@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('katharyn@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('sonny', 'sonny@gmail.com', 'A user of PCS', 'sonnypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sonny@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sonny@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sonny@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'sonny@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sonny@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('maynord', 'maynord@gmail.com', 'A user of PCS', 'maynordpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('maynord@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'maynord@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'maynord@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('maynord@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('juliane', 'juliane@gmail.com', 'A user of PCS', 'julianepw');
INSERT INTO PetOwners(email) VALUES ('juliane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'honey', 'honey needs love!', 'honey is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('juliane@gmail.com', 'nona', 'nona needs love!', 'nona is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('felizio', 'felizio@gmail.com', 'A user of PCS', 'feliziopw');
INSERT INTO PetOwners(email) VALUES ('felizio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'abigail', 'abigail needs love!', 'abigail is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felizio@gmail.com', 'red', 'red needs love!', 'red is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('nonnah', 'nonnah@gmail.com', 'A user of PCS', 'nonnahpw');
INSERT INTO PetOwners(email) VALUES ('nonnah@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'sheba', 'sheba needs love!', 'sheba is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'noodles', 'noodles needs love!', 'noodles is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'mojo', 'mojo needs love!', 'mojo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nonnah@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('nonnah@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (183, 'nonnah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (75, 'nonnah@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (136, 'nonnah@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (74, 'nonnah@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nonnah@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('nonnah@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('dalila', 'dalila@gmail.com', 'A user of PCS', 'dalilapw');
INSERT INTO PetOwners(email) VALUES ('dalila@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'lassie', 'lassie needs love!', 'lassie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'chrissy', 'chrissy needs love!', 'chrissy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'nemo', 'nemo needs love!', 'nemo is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dalila@gmail.com', 'maggie-mae', 'maggie-mae needs love!', 'maggie-mae is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('stephi', 'stephi@gmail.com', 'A user of PCS', 'stephipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('stephi@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'stephi@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('stephi@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('willetta', 'willetta@gmail.com', 'A user of PCS', 'willettapw');
INSERT INTO PetOwners(email) VALUES ('willetta@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'hope', 'hope needs love!', 'hope is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willetta@gmail.com', 'pink panther', 'pink panther needs love!', 'pink panther is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willetta@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (44, 'willetta@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (191, 'willetta@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willetta@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('willetta@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('benedicto', 'benedicto@gmail.com', 'A user of PCS', 'benedictopw');
INSERT INTO PetOwners(email) VALUES ('benedicto@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'aires', 'aires needs love!', 'aires is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('benedicto@gmail.com', 'fido', 'fido needs love!', 'fido is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('michaela', 'michaela@gmail.com', 'A user of PCS', 'michaelapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('michaela@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'michaela@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'michaela@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'michaela@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('michaela@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('mandi', 'mandi@gmail.com', 'A user of PCS', 'mandipw');
INSERT INTO PetOwners(email) VALUES ('mandi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'buddie', 'buddie needs love!', 'buddie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'bentley', 'bentley needs love!', 'bentley is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'jaxson', 'jaxson needs love!', 'jaxson is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('mandi@gmail.com', 'gucci', 'gucci needs love!', 'gucci is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('filbert', 'filbert@gmail.com', 'A user of PCS', 'filbertpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('filbert@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'filbert@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'filbert@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'filbert@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'filbert@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filbert@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('filbert@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('elsinore', 'elsinore@gmail.com', 'A user of PCS', 'elsinorepw');
INSERT INTO PetOwners(email) VALUES ('elsinore@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('elsinore@gmail.com', 'pickles', 'pickles needs love!', 'pickles is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('elsinore@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'elsinore@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('elsinore@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('maurene', 'maurene@gmail.com', 'A user of PCS', 'maurenepw');
INSERT INTO PetOwners(email) VALUES ('maurene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'lacey', 'lacey needs love!', 'lacey is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'prancer', 'prancer needs love!', 'prancer is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'mulligan', 'mulligan needs love!', 'mulligan is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('maurene@gmail.com', 'ginny', 'ginny needs love!', 'ginny is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('zandra', 'zandra@gmail.com', 'A user of PCS', 'zandrapw');
INSERT INTO PetOwners(email) VALUES ('zandra@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'kramer', 'kramer needs love!', 'kramer is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zandra@gmail.com', 'maggie-moo', 'maggie-moo needs love!', 'maggie-moo is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('estel', 'estel@gmail.com', 'A user of PCS', 'estelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('estel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'estel@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'estel@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'estel@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'estel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'estel@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('estel@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('marketa', 'marketa@gmail.com', 'A user of PCS', 'marketapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('marketa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (106, 'marketa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (69, 'marketa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'marketa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'marketa@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('marketa@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('friedrick', 'friedrick@gmail.com', 'A user of PCS', 'friedrickpw');
INSERT INTO PetOwners(email) VALUES ('friedrick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('friedrick@gmail.com', 'genie', 'genie needs love!', 'genie is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('friedrick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'friedrick@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'friedrick@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('friedrick@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('alano', 'alano@gmail.com', 'A user of PCS', 'alanopw');
INSERT INTO PetOwners(email) VALUES ('alano@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'clifford', 'clifford needs love!', 'clifford is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'smokey', 'smokey needs love!', 'smokey is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'porky', 'porky needs love!', 'porky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'napoleon', 'napoleon needs love!', 'napoleon is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alano@gmail.com', 'reggie', 'reggie needs love!', 'reggie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ailey', 'ailey@gmail.com', 'A user of PCS', 'aileypw');
INSERT INTO PetOwners(email) VALUES ('ailey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ailey@gmail.com', 'roland', 'roland needs love!', 'roland is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ailey@gmail.com', 'scottie', 'scottie needs love!', 'scottie is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ailey@gmail.com', 'domino', 'domino needs love!', 'domino is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ailey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'ailey@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ailey@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ailey@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ailey@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ailey@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('eddi', 'eddi@gmail.com', 'A user of PCS', 'eddipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eddi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'eddi@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (166, 'eddi@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'eddi@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (221, 'eddi@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddi@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('eddi@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('dorthea', 'dorthea@gmail.com', 'A user of PCS', 'dortheapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dorthea@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dorthea@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dorthea@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'dorthea@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'dorthea@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dorthea@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('hersh', 'hersh@gmail.com', 'A user of PCS', 'hershpw');
INSERT INTO PetOwners(email) VALUES ('hersh@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hersh@gmail.com', 'ruffles', 'ruffles needs love!', 'ruffles is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hersh@gmail.com', 'ruger', 'ruger needs love!', 'ruger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('hersh@gmail.com', 'pirate', 'pirate needs love!', 'pirate is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hersh@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'hersh@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'hersh@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'hersh@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('hersh@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('bud', 'bud@gmail.com', 'A user of PCS', 'budpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bud@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bud@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'bud@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bud@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('patten', 'patten@gmail.com', 'A user of PCS', 'pattenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('patten@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'patten@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('patten@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('jerrine', 'jerrine@gmail.com', 'A user of PCS', 'jerrinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('jerrine@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (84, 'jerrine@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (231, 'jerrine@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jerrine@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('jerrine@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('goldi', 'goldi@gmail.com', 'A user of PCS', 'goldipw');
INSERT INTO PetOwners(email) VALUES ('goldi@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'chauncey', 'chauncey needs love!', 'chauncey is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('goldi@gmail.com', 'hank', 'hank needs love!', 'hank is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('yul', 'yul@gmail.com', 'A user of PCS', 'yulpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('yul@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'yul@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'yul@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'yul@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'yul@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('yul@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('norine', 'norine@gmail.com', 'A user of PCS', 'norinepw');
INSERT INTO PetOwners(email) VALUES ('norine@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('norine@gmail.com', 'fred', 'fred needs love!', 'fred is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('norine@gmail.com', 'kc', 'kc needs love!', 'kc is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('letti', 'letti@gmail.com', 'A user of PCS', 'lettipw');
INSERT INTO PetOwners(email) VALUES ('letti@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'duncan', 'duncan needs love!', 'duncan is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'macintosh', 'macintosh needs love!', 'macintosh is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'little bit', 'little bit needs love!', 'little bit is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('letti@gmail.com', 'magic', 'magic needs love!', 'magic is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('letti@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (101, 'letti@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('letti@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('letti@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('viva', 'viva@gmail.com', 'A user of PCS', 'vivapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('viva@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'viva@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (67, 'viva@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (154, 'viva@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'viva@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('viva@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('viva@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('angel', 'angel@gmail.com', 'A user of PCS', 'angelpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('angel@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'angel@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'angel@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'angel@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('angel@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('darcey', 'darcey@gmail.com', 'A user of PCS', 'darceypw');
INSERT INTO PetOwners(email) VALUES ('darcey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'jackie', 'jackie needs love!', 'jackie is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'butterscotch', 'butterscotch needs love!', 'butterscotch is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'rexy', 'rexy needs love!', 'rexy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'dolly', 'dolly needs love!', 'dolly is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('darcey@gmail.com', 'nugget', 'nugget needs love!', 'nugget is a Bird', 'Bird');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('darcey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'darcey@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('darcey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('basilio', 'basilio@gmail.com', 'A user of PCS', 'basiliopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('basilio@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'basilio@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'basilio@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('basilio@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ronald', 'ronald@gmail.com', 'A user of PCS', 'ronaldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronald@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'ronald@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'ronald@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'ronald@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'ronald@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('iago', 'iago@gmail.com', 'A user of PCS', 'iagopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('iago@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (115, 'iago@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'iago@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (89, 'iago@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'iago@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iago@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('iago@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('pepi', 'pepi@gmail.com', 'A user of PCS', 'pepipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pepi@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'pepi@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'pepi@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'pepi@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (129, 'pepi@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pepi@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('pepi@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('dagmar', 'dagmar@gmail.com', 'A user of PCS', 'dagmarpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dagmar@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dagmar@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'dagmar@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'dagmar@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dagmar@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'dagmar@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dagmar@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('dylan', 'dylan@gmail.com', 'A user of PCS', 'dylanpw');
INSERT INTO PetOwners(email) VALUES ('dylan@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dylan@gmail.com', 'callie', 'callie needs love!', 'callie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dylan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'dylan@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (132, 'dylan@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (121, 'dylan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'dylan@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dylan@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dylan@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('fenelia', 'fenelia@gmail.com', 'A user of PCS', 'feneliapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('fenelia@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'fenelia@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'fenelia@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('fenelia@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('geneva', 'geneva@gmail.com', 'A user of PCS', 'genevapw');
INSERT INTO PetOwners(email) VALUES ('geneva@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'noel', 'noel needs love!', 'noel is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('geneva@gmail.com', 'remy', 'remy needs love!', 'remy is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('ed', 'ed@gmail.com', 'A user of PCS', 'edpw');
INSERT INTO PetOwners(email) VALUES ('ed@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ed@gmail.com', 'braggs', 'braggs needs love!', 'braggs is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ed@gmail.com', 'dots', 'dots needs love!', 'dots is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ed@gmail.com', 'dallas', 'dallas needs love!', 'dallas is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('charleen', 'charleen@gmail.com', 'A user of PCS', 'charleenpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('charleen@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (47, 'charleen@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charleen@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('charleen@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('rona', 'rona@gmail.com', 'A user of PCS', 'ronapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rona@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (73, 'rona@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (95, 'rona@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'rona@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rona@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('rona@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('brina', 'brina@gmail.com', 'A user of PCS', 'brinapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (241, 'brina@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brina@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('brina@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('sharai', 'sharai@gmail.com', 'A user of PCS', 'sharaipw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sharai@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'sharai@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sharai@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'sharai@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'sharai@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sharai@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('zedekiah', 'zedekiah@gmail.com', 'A user of PCS', 'zedekiahpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zedekiah@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'zedekiah@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'zedekiah@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'zedekiah@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('zedekiah@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('adriane', 'adriane@gmail.com', 'A user of PCS', 'adrianepw');
INSERT INTO PetOwners(email) VALUES ('adriane@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'hooch', 'hooch needs love!', 'hooch is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'rex', 'rex needs love!', 'rex is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'coal', 'coal needs love!', 'coal is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('adriane@gmail.com', 'babbles', 'babbles needs love!', 'babbles is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('adriane@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (139, 'adriane@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'adriane@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'adriane@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'adriane@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (39, 'adriane@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriane@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('adriane@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('hernando', 'hernando@gmail.com', 'A user of PCS', 'hernandopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hernando@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (231, 'hernando@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (251, 'hernando@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'hernando@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hernando@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hernando@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('kalvin', 'kalvin@gmail.com', 'A user of PCS', 'kalvinpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kalvin@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (102, 'kalvin@gmail.com', 'Cat');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalvin@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kalvin@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('isa', 'isa@gmail.com', 'A user of PCS', 'isapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('isa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'isa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'isa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'isa@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'isa@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'isa@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('isa@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('wynn', 'wynn@gmail.com', 'A user of PCS', 'wynnpw');
INSERT INTO PetOwners(email) VALUES ('wynn@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wynn@gmail.com', 'hardy', 'hardy needs love!', 'hardy is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('wynn@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (192, 'wynn@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (86, 'wynn@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'wynn@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'wynn@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wynn@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('wynn@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('gwenette', 'gwenette@gmail.com', 'A user of PCS', 'gwenettepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gwenette@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'gwenette@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gwenette@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('sharona', 'sharona@gmail.com', 'A user of PCS', 'sharonapw');
INSERT INTO PetOwners(email) VALUES ('sharona@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('sharona@gmail.com', 'beaux', 'beaux needs love!', 'beaux is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('joline', 'joline@gmail.com', 'A user of PCS', 'jolinepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('joline@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (219, 'joline@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (87, 'joline@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (112, 'joline@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joline@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('joline@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('arlena', 'arlena@gmail.com', 'A user of PCS', 'arlenapw');
INSERT INTO PetOwners(email) VALUES ('arlena@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'kenya', 'kenya needs love!', 'kenya is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'black-jack', 'black-jack needs love!', 'black-jack is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'charisma', 'charisma needs love!', 'charisma is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'shasta', 'shasta needs love!', 'shasta is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('arlena@gmail.com', 'quincy', 'quincy needs love!', 'quincy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arlena@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'arlena@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (137, 'arlena@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'arlena@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (41, 'arlena@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arlena@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arlena@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('madelina', 'madelina@gmail.com', 'A user of PCS', 'madelinapw');
INSERT INTO PetOwners(email) VALUES ('madelina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('madelina@gmail.com', 'emma', 'emma needs love!', 'emma is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madelina@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'madelina@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'madelina@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (200, 'madelina@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madelina@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('madelina@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('giacobo', 'giacobo@gmail.com', 'A user of PCS', 'giacobopw');
INSERT INTO PetOwners(email) VALUES ('giacobo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('giacobo@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('giacobo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (162, 'giacobo@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('giacobo@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('philly', 'philly@gmail.com', 'A user of PCS', 'phillypw');
INSERT INTO PetOwners(email) VALUES ('philly@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philly@gmail.com', 'dobie', 'dobie needs love!', 'dobie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('philly@gmail.com', 'flint', 'flint needs love!', 'flint is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('curcio', 'curcio@gmail.com', 'A user of PCS', 'curciopw');
INSERT INTO PetOwners(email) VALUES ('curcio@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('curcio@gmail.com', 'patches', 'patches needs love!', 'patches is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('curcio@gmail.com', 'duchess', 'duchess needs love!', 'duchess is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('curcio@gmail.com', 'mango', 'mango needs love!', 'mango is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('carrissa', 'carrissa@gmail.com', 'A user of PCS', 'carrissapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrissa@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (215, 'carrissa@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (30, 'carrissa@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'carrissa@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (116, 'carrissa@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrissa@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrissa@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('clemente', 'clemente@gmail.com', 'A user of PCS', 'clementepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('clemente@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'clemente@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'clemente@gmail.com', 'Lion');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('clemente@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('faythe', 'faythe@gmail.com', 'A user of PCS', 'faythepw');
INSERT INTO PetOwners(email) VALUES ('faythe@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('faythe@gmail.com', 'casey', 'casey needs love!', 'casey is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('faythe@gmail.com', 'cujo', 'cujo needs love!', 'cujo is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('faythe@gmail.com', 'ruby', 'ruby needs love!', 'ruby is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('ingeborg', 'ingeborg@gmail.com', 'A user of PCS', 'ingeborgpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ingeborg@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (72, 'ingeborg@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingeborg@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ingeborg@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('wilie', 'wilie@gmail.com', 'A user of PCS', 'wiliepw');
INSERT INTO PetOwners(email) VALUES ('wilie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'picasso', 'picasso needs love!', 'picasso is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'quinn', 'quinn needs love!', 'quinn is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'kane', 'kane needs love!', 'kane is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'chrissy', 'chrissy needs love!', 'chrissy is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('wilie@gmail.com', 'billie', 'billie needs love!', 'billie is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('nari', 'nari@gmail.com', 'A user of PCS', 'naripw');
INSERT INTO PetOwners(email) VALUES ('nari@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('nari@gmail.com', 'elmo', 'elmo needs love!', 'elmo is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('leo', 'leo@gmail.com', 'A user of PCS', 'leopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'leo@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (117, 'leo@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leo@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leo@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('gretal', 'gretal@gmail.com', 'A user of PCS', 'gretalpw');
INSERT INTO PetOwners(email) VALUES ('gretal@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'barney', 'barney needs love!', 'barney is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gretal@gmail.com', 'jett', 'jett needs love!', 'jett is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gretal@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'gretal@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'gretal@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('gretal@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('dona', 'dona@gmail.com', 'A user of PCS', 'donapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dona@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (53, 'dona@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (176, 'dona@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dona@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dona@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('colene', 'colene@gmail.com', 'A user of PCS', 'colenepw');
INSERT INTO PetOwners(email) VALUES ('colene@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'higgins', 'higgins needs love!', 'higgins is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'bobby', 'bobby needs love!', 'bobby is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('colene@gmail.com', 'lovey', 'lovey needs love!', 'lovey is a Monkey', 'Monkey');

INSERT INTO Users(name, email, description, password) VALUES ('felike', 'felike@gmail.com', 'A user of PCS', 'felikepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felike@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (88, 'felike@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (195, 'felike@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'felike@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (57, 'felike@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felike@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felike@gmail.com', '2022-01-01');

INSERT INTO Users(name, email, description, password) VALUES ('godfrey', 'godfrey@gmail.com', 'A user of PCS', 'godfreypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('godfrey@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'godfrey@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'godfrey@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('godfrey@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('andrej', 'andrej@gmail.com', 'A user of PCS', 'andrejpw');
INSERT INTO PetOwners(email) VALUES ('andrej@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrej@gmail.com', 'jerry', 'jerry needs love!', 'jerry is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrej@gmail.com', 'kallie', 'kallie needs love!', 'kallie is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrej@gmail.com', 'eva', 'eva needs love!', 'eva is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('andrej@gmail.com', 'piper', 'piper needs love!', 'piper is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('andrej@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (107, 'andrej@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrej@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('andrej@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('zea', 'zea@gmail.com', 'A user of PCS', 'zeapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('zea@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'zea@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'zea@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zea@gmail.com', '2021-07-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('zea@gmail.com', '2022-12-01');

INSERT INTO Users(name, email, description, password) VALUES ('tresa', 'tresa@gmail.com', 'A user of PCS', 'tresapw');
INSERT INTO PetOwners(email) VALUES ('tresa@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tresa@gmail.com', 'porter', 'porter needs love!', 'porter is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('tresa@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('tresa@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'tresa@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'tresa@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'tresa@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'tresa@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('tresa@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('odey', 'odey@gmail.com', 'A user of PCS', 'odeypw');
INSERT INTO PetOwners(email) VALUES ('odey@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'izzy', 'izzy needs love!', 'izzy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('odey@gmail.com', 'frisky', 'frisky needs love!', 'frisky is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('herc', 'herc@gmail.com', 'A user of PCS', 'hercpw');
INSERT INTO PetOwners(email) VALUES ('herc@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'eifel', 'eifel needs love!', 'eifel is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'buddy boy', 'buddy boy needs love!', 'buddy boy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'newt', 'newt needs love!', 'newt is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('herc@gmail.com', 'killian', 'killian needs love!', 'killian is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('gertrude', 'gertrude@gmail.com', 'A user of PCS', 'gertrudepw');
INSERT INTO PetOwners(email) VALUES ('gertrude@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'sammy', 'sammy needs love!', 'sammy is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'floyd', 'floyd needs love!', 'floyd is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'connor', 'connor needs love!', 'connor is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gertrude@gmail.com', 'phoebe', 'phoebe needs love!', 'phoebe is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('sherilyn', 'sherilyn@gmail.com', 'A user of PCS', 'sherilynpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('sherilyn@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'sherilyn@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('sherilyn@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('aggie', 'aggie@gmail.com', 'A user of PCS', 'aggiepw');
INSERT INTO PetOwners(email) VALUES ('aggie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('aggie@gmail.com', 'maverick', 'maverick needs love!', 'maverick is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('becky', 'becky@gmail.com', 'A user of PCS', 'beckypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('becky@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (245, 'becky@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'becky@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (205, 'becky@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('becky@gmail.com', '2022-04-01');

INSERT INTO Users(name, email, description, password) VALUES ('claudina', 'claudina@gmail.com', 'A user of PCS', 'claudinapw');
INSERT INTO PetOwners(email) VALUES ('claudina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudina@gmail.com', 'candy', 'candy needs love!', 'candy is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('claudina@gmail.com', 'ernie', 'ernie needs love!', 'ernie is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('uriel', 'uriel@gmail.com', 'A user of PCS', 'urielpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('uriel@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'uriel@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (63, 'uriel@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('uriel@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('uriel@gmail.com', '2022-10-01');

INSERT INTO Users(name, email, description, password) VALUES ('zenia', 'zenia@gmail.com', 'A user of PCS', 'zeniapw');
INSERT INTO PetOwners(email) VALUES ('zenia@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('zenia@gmail.com', 'ally', 'ally needs love!', 'ally is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('pip', 'pip@gmail.com', 'A user of PCS', 'pippw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('pip@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'pip@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'pip@gmail.com', 'Dog');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('pip@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('bentlee', 'bentlee@gmail.com', 'A user of PCS', 'bentleepw');
INSERT INTO PetOwners(email) VALUES ('bentlee@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bentlee@gmail.com', 'black-jack', 'black-jack needs love!', 'black-jack is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('bentlee@gmail.com', 'harvey', 'harvey needs love!', 'harvey is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bentlee@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bentlee@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'bentlee@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'bentlee@gmail.com', 'Snake');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bentlee@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('eleanora', 'eleanora@gmail.com', 'A user of PCS', 'eleanorapw');
INSERT INTO PetOwners(email) VALUES ('eleanora@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eleanora@gmail.com', 'fifi', 'fifi needs love!', 'fifi is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eleanora@gmail.com', 'queen', 'queen needs love!', 'queen is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eleanora@gmail.com', 'joker', 'joker needs love!', 'joker is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('eleanora@gmail.com', 'smoke', 'smoke needs love!', 'smoke is a Hamster', 'Hamster');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('eleanora@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'eleanora@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'eleanora@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('eleanora@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('brianne', 'brianne@gmail.com', 'A user of PCS', 'briannepw');
INSERT INTO PetOwners(email) VALUES ('brianne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianne@gmail.com', 'miko', 'miko needs love!', 'miko is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianne@gmail.com', 'olivia', 'olivia needs love!', 'olivia is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brianne@gmail.com', 'blondie', 'blondie needs love!', 'blondie is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brianne@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'brianne@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'brianne@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'brianne@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brianne@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('leicester', 'leicester@gmail.com', 'A user of PCS', 'leicesterpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leicester@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (113, 'leicester@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (149, 'leicester@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leicester@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leicester@gmail.com', '2022-05-01');

INSERT INTO Users(name, email, description, password) VALUES ('bettye', 'bettye@gmail.com', 'A user of PCS', 'bettyepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bettye@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'bettye@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'bettye@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('bettye@gmail.com', '2022-11-03');

INSERT INTO Users(name, email, description, password) VALUES ('odelle', 'odelle@gmail.com', 'A user of PCS', 'odellepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('odelle@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (42, 'odelle@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (145, 'odelle@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelle@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('odelle@gmail.com', '2022-09-01');

INSERT INTO Users(name, email, description, password) VALUES ('del', 'del@gmail.com', 'A user of PCS', 'delpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('del@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (114, 'del@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (58, 'del@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('del@gmail.com', '2022-03-01');

INSERT INTO Users(name, email, description, password) VALUES ('berte', 'berte@gmail.com', 'A user of PCS', 'bertepw');
INSERT INTO PetOwners(email) VALUES ('berte@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('berte@gmail.com', 'loki', 'loki needs love!', 'loki is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('lianne', 'lianne@gmail.com', 'A user of PCS', 'liannepw');
INSERT INTO PetOwners(email) VALUES ('lianne@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'darcy', 'darcy needs love!', 'darcy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'erin', 'erin needs love!', 'erin is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'rocco', 'rocco needs love!', 'rocco is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('lianne@gmail.com', 'foxy', 'foxy needs love!', 'foxy is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('steve', 'steve@gmail.com', 'A user of PCS', 'stevepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('steve@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'steve@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'steve@gmail.com', 'Horse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('steve@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('janos', 'janos@gmail.com', 'A user of PCS', 'janospw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('janos@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'janos@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'janos@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'janos@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'janos@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('janos@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ede', 'ede@gmail.com', 'A user of PCS', 'edepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ede@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'ede@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ede@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'ede@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ede@gmail.com', '2022-01-03');

INSERT INTO Users(name, email, description, password) VALUES ('ringo', 'ringo@gmail.com', 'A user of PCS', 'ringopw');
INSERT INTO PetOwners(email) VALUES ('ringo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'blossom', 'blossom needs love!', 'blossom is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'shasta', 'shasta needs love!', 'shasta is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'ruffles', 'ruffles needs love!', 'ruffles is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'otto', 'otto needs love!', 'otto is a Monkey', 'Monkey');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ringo@gmail.com', 'carley', 'carley needs love!', 'carley is a Cat', 'Cat');

INSERT INTO Users(name, email, description, password) VALUES ('porty', 'porty@gmail.com', 'A user of PCS', 'portypw');
INSERT INTO PetOwners(email) VALUES ('porty@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('porty@gmail.com', 'shaggy', 'shaggy needs love!', 'shaggy is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('porty@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'porty@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('porty@gmail.com', '2022-06-03');

INSERT INTO Users(name, email, description, password) VALUES ('catarina', 'catarina@gmail.com', 'A user of PCS', 'catarinapw');
INSERT INTO PetOwners(email) VALUES ('catarina@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'pasha', 'pasha needs love!', 'pasha is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'benson', 'benson needs love!', 'benson is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'bitsy', 'bitsy needs love!', 'bitsy is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('catarina@gmail.com', 'boozer', 'boozer needs love!', 'boozer is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('anthiathia', 'anthiathia@gmail.com', 'A user of PCS', 'anthiathiapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('anthiathia@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'anthiathia@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anthiathia@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('anthiathia@gmail.com', '2022-07-01');

INSERT INTO Users(name, email, description, password) VALUES ('misty', 'misty@gmail.com', 'A user of PCS', 'mistypw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('misty@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'misty@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'misty@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'misty@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (50, 'misty@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'misty@gmail.com', 'Turtle');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('misty@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kalli', 'kalli@gmail.com', 'A user of PCS', 'kallipw');
INSERT INTO PetOwners(email) VALUES ('kalli@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'buddy', 'buddy needs love!', 'buddy is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'frankie', 'frankie needs love!', 'frankie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'pugsley', 'pugsley needs love!', 'pugsley is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'camille', 'camille needs love!', 'camille is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('kalli@gmail.com', 'astro', 'astro needs love!', 'astro is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('brana', 'brana@gmail.com', 'A user of PCS', 'branapw');
INSERT INTO PetOwners(email) VALUES ('brana@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'birdy', 'birdy needs love!', 'birdy is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('brana@gmail.com', 'hallie', 'hallie needs love!', 'hallie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('brana@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'brana@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('brana@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('kahlil', 'kahlil@gmail.com', 'A user of PCS', 'kahlilpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('kahlil@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (94, 'kahlil@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (83, 'kahlil@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('kahlil@gmail.com', '2022-06-01');

INSERT INTO Users(name, email, description, password) VALUES ('marcie', 'marcie@gmail.com', 'A user of PCS', 'marciepw');
INSERT INTO PetOwners(email) VALUES ('marcie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcie@gmail.com', 'precious', 'precious needs love!', 'precious is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcie@gmail.com', 'skip', 'skip needs love!', 'skip is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcie@gmail.com', 'heidi', 'heidi needs love!', 'heidi is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('marcie@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('esma', 'esma@gmail.com', 'A user of PCS', 'esmapw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('esma@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'esma@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'esma@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'esma@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'esma@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'esma@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('esma@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('dominique', 'dominique@gmail.com', 'A user of PCS', 'dominiquepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dominique@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'dominique@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'dominique@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('dominique@gmail.com', '2022-07-03');

INSERT INTO Users(name, email, description, password) VALUES ('willyt', 'willyt@gmail.com', 'A user of PCS', 'willytpw');
INSERT INTO PetOwners(email) VALUES ('willyt@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'odie', 'odie needs love!', 'odie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('willyt@gmail.com', 'hope', 'hope needs love!', 'hope is a Horse', 'Horse');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('willyt@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'willyt@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'willyt@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'willyt@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2022-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2022-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('willyt@gmail.com', '2022-12-03');

INSERT INTO Users(name, email, description, password) VALUES ('leonardo', 'leonardo@gmail.com', 'A user of PCS', 'leonardopw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('leonardo@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (144, 'leonardo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (131, 'leonardo@gmail.com', 'Mouse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leonardo@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('leonardo@gmail.com', '2022-02-01');

INSERT INTO Users(name, email, description, password) VALUES ('madison', 'madison@gmail.com', 'A user of PCS', 'madisonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('madison@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'madison@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2021-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('madison@gmail.com', '2022-02-03');

INSERT INTO Users(name, email, description, password) VALUES ('annabal', 'annabal@gmail.com', 'A user of PCS', 'annabalpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('annabal@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (49, 'annabal@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('annabal@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('annabal@gmail.com', '2022-11-01');

INSERT INTO Users(name, email, description, password) VALUES ('gonzales', 'gonzales@gmail.com', 'A user of PCS', 'gonzalespw');
INSERT INTO PetOwners(email) VALUES ('gonzales@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gonzales@gmail.com', 'gretta', 'gretta needs love!', 'gretta is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gonzales@gmail.com', 'barbie', 'barbie needs love!', 'barbie is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gonzales@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'gonzales@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (38, 'gonzales@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'gonzales@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'gonzales@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gonzales@gmail.com', '2021-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gonzales@gmail.com', '2022-06-01');

INSERT INTO BidsFor VALUES ('palmer@gmail.com', 'theodoric@gmail.com', 'bullet', '2020-01-01 00:00:00', '2021-02-06', '2021-02-11', 130, 142, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('devlen@gmail.com', 'mariejeanne@gmail.com', 'dutches', '2020-01-01 00:00:01', '2021-07-05', '2021-07-10', 70, 91, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('kathie@gmail.com', 'desirae@gmail.com', 'dillon', '2020-01-01 00:00:02', '2022-04-11', '2022-04-11', 133, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('oberon@gmail.com', 'filia@gmail.com', 'morgan', '2020-01-01 00:00:03', '2021-02-12', '2021-02-17', 165, 177, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('philly@gmail.com', 'blisse@gmail.com', 'dobie', '2020-01-01 00:00:04', '2022-08-15', '2022-08-19', 90, 95, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('catrina@gmail.com', 'candy@gmail.com', 'flash', '2020-01-01 00:00:05', '2021-08-03', '2021-08-04', 114, 138, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jemimah@gmail.com', 'gavin@gmail.com', 'mo', '2020-01-01 00:00:06', '2021-04-29', '2021-05-03', 60, 64, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('pincus@gmail.com', 'abram@gmail.com', 'fuzzy', '2020-01-01 00:00:07', '2022-10-07', '2022-10-12', 50, 60, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brennen@gmail.com', 'humfrid@gmail.com', 'hercules', '2020-01-01 00:00:08', '2022-03-08', '2022-03-14', 87, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('helli@gmail.com', 'kara@gmail.com', 'mandi', '2020-01-01 00:00:09', '2021-10-05', '2021-10-11', 80, 110, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ilka@gmail.com', 'kahlil@gmail.com', 'chyna', '2020-01-01 00:00:10', '2022-06-14', '2022-06-19', 94, 122, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('pincus@gmail.com', 'paco@gmail.com', 'brodie', '2020-01-01 00:00:11', '2022-11-02', '2022-11-04', 170, 186, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('carleton@gmail.com', 'linet@gmail.com', 'honey-bear', '2020-01-01 00:00:12', '2021-02-06', '2021-02-11', 99, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('egor@gmail.com', 'karrie@gmail.com', 'skye', '2020-01-01 00:00:13', '2021-06-17', '2021-06-17', 120, 150, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('petr@gmail.com', 'francklyn@gmail.com', 'koty', '2020-01-01 00:00:14', '2022-01-19', '2022-01-19', 100, 114, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gui@gmail.com', 'benita@gmail.com', 'jackie', '2020-01-01 00:00:15', '2022-01-01', '2022-01-01', 49, 68, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brianna@gmail.com', 'everett@gmail.com', 'daisy', '2020-01-01 00:00:16', '2021-05-10', '2021-05-15', 117, 144, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marie-ann@gmail.com', 'anetta@gmail.com', 'sasha', '2020-01-01 00:00:17', '2022-12-21', '2022-12-25', 70, 75, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('nonnah@gmail.com', 'jessica@gmail.com', 'charlie', '2020-01-01 00:00:18', '2022-09-15', '2022-09-16', 111, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sigfrid@gmail.com', 'charlotte@gmail.com', 'michael', '2020-01-01 00:00:19', '2022-04-23', '2022-04-24', 184, 210, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('norine@gmail.com', 'estella@gmail.com', 'fred', '2020-01-01 00:00:20', '2022-10-23', '2022-10-24', 120, 136, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('denise@gmail.com', 'sunny@gmail.com', 'diamond', '2020-01-01 00:00:21', '2022-05-02', '2022-05-08', 91, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('glad@gmail.com', 'marcellus@gmail.com', 'lexus', '2020-01-01 00:00:22', '2022-06-21', '2022-06-26', 106, 126, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('garik@gmail.com', 'basilio@gmail.com', 'curly', '2020-01-01 00:00:23', '2021-10-21', '2021-10-25', 140, 147, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jodee@gmail.com', 'grace@gmail.com', 'pooky', '2020-01-01 00:00:24', '2021-08-19', '2021-08-20', 160, 190, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('pincus@gmail.com', 'otto@gmail.com', 'brodie', '2020-01-01 00:00:25', '2021-10-28', '2021-11-01', 140, 145, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rory@gmail.com', 'gonzales@gmail.com', 'izzy', '2020-01-01 00:00:26', '2021-07-12', '2021-07-16', 32, 57, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dacy@gmail.com', 'ronny@gmail.com', 'brindle', '2020-01-01 00:00:27', '2021-03-10', '2021-03-11', 79, 100, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dorice@gmail.com', 'yankee@gmail.com', 'layla', '2020-01-01 00:00:28', '2021-02-09', '2021-02-09', 80, 104, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('omar@gmail.com', 'margarete@gmail.com', 'audi', '2020-01-01 00:00:29', '2021-01-30', '2021-01-31', 50, 62, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('oberon@gmail.com', 'manda@gmail.com', 'billy', '2020-01-01 00:00:30', '2021-06-26', '2021-06-28', 130, 144, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dianemarie@gmail.com', 'adriane@gmail.com', 'benny', '2020-01-01 00:00:31', '2021-09-30', '2021-10-04', 200, 203, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('graig@gmail.com', 'cosette@gmail.com', 'curly', '2020-01-01 00:00:32', '2021-10-07', '2021-10-12', 110, 111, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('francis@gmail.com', 'stanislaus@gmail.com', 'shiner', '2020-01-01 00:00:33', '2021-01-18', '2021-01-19', 50, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('donnajean@gmail.com', 'yul@gmail.com', 'hercules', '2020-01-01 00:00:34', '2022-01-12', '2022-01-12', 80, 88, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('adel@gmail.com', 'hoyt@gmail.com', 'gringo', '2020-01-01 00:00:35', '2022-06-11', '2022-06-14', 66, 88, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('lindie@gmail.com', 'babbette@gmail.com', 'bo', '2020-01-01 00:00:36', '2021-07-29', '2021-07-29', 60, 64, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('selig@gmail.com', 'thorn@gmail.com', 'elwood', '2020-01-01 00:00:37', '2022-02-16', '2022-02-18', 100, 100, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('merrielle@gmail.com', 'aubine@gmail.com', 'mookie', '2020-01-01 00:00:38', '2021-01-15', '2021-01-20', 100, 128, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('millard@gmail.com', 'farah@gmail.com', 'ginger', '2020-01-01 00:00:39', '2022-09-28', '2022-10-02', 50, 77, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cherri@gmail.com', 'mirabel@gmail.com', 'comet', '2020-01-01 00:00:40', '2022-09-15', '2022-09-15', 93, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('andrej@gmail.com', 'yolane@gmail.com', 'kallie', '2020-01-01 00:00:41', '2021-12-23', '2021-12-28', 110, 111, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('pail@gmail.com', 'maurizia@gmail.com', 'audi', '2020-01-01 00:00:42', '2022-01-03', '2022-01-07', 120, 137, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dorthy@gmail.com', 'berton@gmail.com', 'buddy', '2020-01-01 00:00:43', '2021-08-20', '2021-08-26', 130, 135, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('emmy@gmail.com', 'fairfax@gmail.com', 'grover', '2020-01-01 00:00:44', '2021-12-08', '2021-12-11', 128, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('brianne@gmail.com', 'hobie@gmail.com', 'blondie', '2020-01-01 00:00:45', '2022-02-24', '2022-03-01', 143, 154, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marcello@gmail.com', 'willy@gmail.com', 'skye', '2020-01-01 00:00:46', '2021-05-23', '2021-05-27', 70, 97, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hasheem@gmail.com', 'johnath@gmail.com', 'fresier', '2020-01-01 00:00:47', '2021-11-20', '2021-11-25', 48, 67, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dukey@gmail.com', 'burnard@gmail.com', 'fritz', '2020-01-01 00:00:48', '2022-04-01', '2022-04-02', 126, 126, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rory@gmail.com', 'nels@gmail.com', 'patches', '2020-01-01 00:00:49', '2021-04-28', '2021-04-30', 130, 135, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('drew@gmail.com', 'ketti@gmail.com', 'pudge', '2020-01-01 00:00:50', '2022-12-20', '2022-12-26', 32, 42, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('enrika@gmail.com', 'alexandros@gmail.com', 'paris', '2020-01-01 00:00:51', '2022-04-22', '2022-04-24', 100, 116, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('adolpho@gmail.com', 'carrissa@gmail.com', 'godiva', '2020-01-01 00:00:52', '2021-09-23', '2021-09-29', 100, 112, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('fallon@gmail.com', 'guendolen@gmail.com', 'ruby', '2020-01-01 00:00:53', '2022-06-27', '2022-06-30', 47, 67, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dale@gmail.com', 'zebulen@gmail.com', 'grady', '2020-01-01 00:00:54', '2021-10-19', '2021-10-21', 137, 161, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('nonnah@gmail.com', 'analise@gmail.com', 'noodles', '2020-01-01 00:00:55', '2022-05-21', '2022-05-22', 60, 85, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('babbette@gmail.com', 'carlynne@gmail.com', 'grover', '2020-01-01 00:00:56', '2021-11-01', '2021-11-02', 100, 123, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('wylma@gmail.com', 'alie@gmail.com', 'brooke', '2020-01-01 00:00:57', '2021-02-21', '2021-02-24', 70, 95, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('mahmud@gmail.com', 'eddi@gmail.com', 'heather', '2020-01-01 00:00:58', '2021-02-11', '2021-02-17', 83, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('geordie@gmail.com', 'jandy@gmail.com', 'jess', '2020-01-01 00:00:59', '2021-12-22', '2021-12-28', 80, 85, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('patton@gmail.com', 'julietta@gmail.com', 'scooby-doo', '2020-01-01 00:01:00', '2021-02-13', '2021-02-18', 94, 106, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('roseline@gmail.com', 'delphinia@gmail.com', 'mo', '2020-01-01 00:01:01', '2021-12-25', '2021-12-30', 173, 189, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('curcio@gmail.com', 'burnard@gmail.com', 'mango', '2020-01-01 00:01:02', '2021-06-29', '2021-06-30', 126, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('tomasine@gmail.com', 'ronald@gmail.com', 'pooky', '2020-01-01 00:01:03', '2022-05-25', '2022-05-29', 70, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dale@gmail.com', 'mariann@gmail.com', 'freedom', '2020-01-01 00:01:04', '2021-05-03', '2021-05-05', 50, 53, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('feodora@gmail.com', 'gilly@gmail.com', 'skittles', '2020-01-01 00:01:05', '2022-08-08', '2022-08-11', 100, 109, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('goldi@gmail.com', 'birgit@gmail.com', 'hank', '2020-01-01 00:01:06', '2022-11-10', '2022-11-11', 148, 172, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('starla@gmail.com', 'coraline@gmail.com', 'buddie', '2020-01-01 00:01:07', '2021-05-30', '2021-05-30', 140, 161, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('carmelina@gmail.com', 'germana@gmail.com', 'nikita', '2020-01-01 00:01:08', '2021-09-18', '2021-09-20', 140, 147, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beck@gmail.com', 'melosa@gmail.com', 'koko', '2020-01-01 00:01:09', '2022-01-04', '2022-01-04', 110, 117, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('tonye@gmail.com', 'fredia@gmail.com', 'aires', '2020-01-01 00:01:10', '2021-11-18', '2021-11-22', 55, 75, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hersh@gmail.com', 'odelle@gmail.com', 'pirate', '2020-01-01 00:01:11', '2021-01-30', '2021-02-01', 42, 60, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('carleton@gmail.com', 'rockie@gmail.com', 'pooh-bear', '2020-01-01 00:01:12', '2022-08-01', '2022-08-03', 77, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felizio@gmail.com', 'cathlene@gmail.com', 'red', '2020-01-01 00:01:13', '2022-05-24', '2022-05-29', 75, 82, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('hurley@gmail.com', 'davon@gmail.com', 'biscuit', '2020-01-01 00:01:14', '2022-07-07', '2022-07-11', 52, 68, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('tedman@gmail.com', 'willy@gmail.com', 'bits', '2020-01-01 00:01:15', '2022-05-26', '2022-05-29', 120, 132, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alex@gmail.com', 'finn@gmail.com', 'nathan', '2020-01-01 00:01:16', '2022-12-24', '2022-12-25', 121, 128, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sigrid@gmail.com', 'farand@gmail.com', 'bodie', '2020-01-01 00:01:17', '2022-09-12', '2022-09-14', 57, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('elsinore@gmail.com', 'camilla@gmail.com', 'pickles', '2020-01-01 00:01:18', '2022-03-29', '2022-04-04', 60, 85, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cora@gmail.com', 'reid@gmail.com', 'belle', '2020-01-01 00:01:19', '2022-10-25', '2022-10-30', 140, 148, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('andrus@gmail.com', 'lois@gmail.com', 'bj', '2020-01-01 00:01:20', '2021-10-12', '2021-10-15', 80, 93, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('eddy@gmail.com', 'samaria@gmail.com', 'jasmine', '2020-01-01 00:01:21', '2022-03-05', '2022-03-09', 60, 65, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dominga@gmail.com', 'cathlene@gmail.com', 'megan', '2020-01-01 00:01:22', '2022-08-15', '2022-08-21', 208, 230, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('cordell@gmail.com', 'delphinia@gmail.com', 'kibbles', '2020-01-01 00:01:23', '2021-04-08', '2021-04-13', 55, 72, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('deeyn@gmail.com', 'sonny@gmail.com', 'baxter', '2020-01-01 00:01:24', '2021-11-09', '2021-11-09', 80, 80, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('everett@gmail.com', 'dalston@gmail.com', 'chad', '2020-01-01 00:01:25', '2021-05-17', '2021-05-17', 63, 66, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('patti@gmail.com', 'aubine@gmail.com', 'fancy', '2020-01-01 00:01:26', '2021-03-14', '2021-03-20', 70, 87, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alano@gmail.com', 'remy@gmail.com', 'reggie', '2020-01-01 00:01:27', '2022-01-21', '2022-01-26', 130, 158, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('audry@gmail.com', 'sandro@gmail.com', 'copper', '2020-01-01 00:01:28', '2022-10-05', '2022-10-08', 50, 59, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rafaellle@gmail.com', 'zebulen@gmail.com', 'queen', '2020-01-01 00:01:29', '2022-06-05', '2022-06-07', 102, 119, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('sigfrid@gmail.com', 'cello@gmail.com', 'peanut', '2020-01-01 00:01:30', '2021-01-13', '2021-01-13', 96, 117, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('borg@gmail.com', 'biron@gmail.com', 'bizzy', '2020-01-01 00:01:31', '2021-11-03', '2021-11-05', 90, 118, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('marie-ann@gmail.com', 'craig@gmail.com', 'sasha', '2020-01-01 00:01:32', '2021-03-09', '2021-03-09', 36, 37, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rafi@gmail.com', 'calley@gmail.com', 'max', '2020-01-01 00:01:33', '2022-09-23', '2022-09-29', 227, 234, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('nickey@gmail.com', 'levey@gmail.com', 'hardy', '2020-01-01 00:01:34', '2022-09-20', '2022-09-20', 96, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charyl@gmail.com', 'dre@gmail.com', 'buttons', '2020-01-01 00:01:35', '2021-09-29', '2021-10-02', 47, 47, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('veda@gmail.com', 'charlotte@gmail.com', 'dixie', '2020-01-01 00:01:36', '2021-09-26', '2021-09-28', 138, 158, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('benedicto@gmail.com', 'francklyn@gmail.com', 'fido', '2020-01-01 00:01:37', '2022-11-20', '2022-11-21', 70, 82, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('toiboid@gmail.com', 'kylila@gmail.com', 'niki', '2020-01-01 00:01:38', '2022-05-16', '2022-05-18', 60, 88, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gui@gmail.com', 'shem@gmail.com', 'persy', '2020-01-01 00:01:39', '2021-11-02', '2021-11-05', 109, 132, NULL, False, '1', '1', NULL, NULL);




--==================================================== END GENERATED DATA HERE ====================================================

-- ================================================ second half of triggers ================================================





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

-- ============================================= end second half of triggers ========================================

























-- ============================================ HANDCRAFTED DATA ============================================




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
-- give him avail on months 10, 11, 12 of 2020
INSERT INTO Users(name, email, description, password) VALUES ('cain', 'cain@gmail.com', 'cain is a User of PCS', 'cainpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cain@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cain@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cain@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cain@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'cain@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cain@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-06');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-07');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-08');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-09');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-10');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-11');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-12');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-13');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-14');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-15');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-16');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-17');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-18');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-19');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-20');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-21');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-22');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-23');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-24');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-25');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-26');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-27');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-28');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-29');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-30');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-10-31');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-06');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-07');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-08');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-09');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-10');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-11');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-12');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-13');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-14');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-15');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-16');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-17');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-18');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-19');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-20');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-21');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-22');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-23');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-24');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-25');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-26');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-27');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-28');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-29');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-11-30');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-06');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-07');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-08');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-09');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-10');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-11');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-12');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-13');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-14');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-15');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-16');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-17');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-18');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-19');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-20');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-21');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-22');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-23');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-24');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-25');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-26');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-27');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-28');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-29');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-30');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('cain@gmail.com', '2020-12-31');

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




