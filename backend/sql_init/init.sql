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

INSERT INTO Users(name, email, description, password) VALUES ('alice', 'alice@gmail.com', 'A user of PCS', 'alicepw');
INSERT INTO PetOwners(email) VALUES ('alice@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alice@gmail.com', 'jake', 'jake needs love!', 'jake is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alice@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Lion', 'Lion');

INSERT INTO Users(name, email, description, password) VALUES ('alex', 'alex@gmail.com', 'A user of PCS', 'alexpw');
INSERT INTO PetOwners(email) VALUES ('alex@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'freddie', 'freddie needs love!', 'freddie is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'jake', 'jake needs love!', 'jake is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('alex@gmail.com', 'felix', 'felix needs love!', 'felix is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('alex@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'alex@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (33, 'alex@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (135, 'alex@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'alex@gmail.com', 'Hamster');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-04-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-04-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-04-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-04-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2021-10-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('alex@gmail.com', '2022-08-05');

INSERT INTO Users(name, email, description, password) VALUES ('arnold', 'arnold@gmail.com', 'A user of PCS', 'arnoldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('arnold@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (180, 'arnold@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'arnold@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (173, 'arnold@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (98, 'arnold@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (32, 'arnold@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-08-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-05-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('arnold@gmail.com', '2022-12-05');

INSERT INTO Users(name, email, description, password) VALUES ('bob', 'bob@gmail.com', 'A user of PCS', 'bobpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('bob@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (165, 'bob@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (224, 'bob@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (143, 'bob@gmail.com', 'Bird');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('bob@gmail.com', '2022-08-05');

INSERT INTO Users(name, email, description, password) VALUES ('becky', 'becky@gmail.com', 'A user of PCS', 'beckypw');
INSERT INTO PetOwners(email) VALUES ('becky@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('becky@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Horse', 'Horse');

INSERT INTO Users(name, email, description, password) VALUES ('beth', 'beth@gmail.com', 'A user of PCS', 'bethpw');
INSERT INTO PetOwners(email) VALUES ('beth@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beth@gmail.com', 'boomer', 'boomer needs love!', 'boomer is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('beth@gmail.com', 'jake', 'jake needs love!', 'jake is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('beth@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'beth@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'beth@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'beth@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2021-12-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('beth@gmail.com', '2022-02-07');

INSERT INTO Users(name, email, description, password) VALUES ('connor', 'connor@gmail.com', 'A user of PCS', 'connorpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('connor@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'connor@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'connor@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'connor@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'connor@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (70, 'connor@gmail.com', 'Hamster');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2021-12-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('connor@gmail.com', '2022-11-07');

INSERT INTO Users(name, email, description, password) VALUES ('cassie', 'cassie@gmail.com', 'A user of PCS', 'cassiepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('cassie@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'cassie@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'cassie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'cassie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'cassie@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2021-06-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('cassie@gmail.com', '2022-06-07');

INSERT INTO Users(name, email, description, password) VALUES ('carrie', 'carrie@gmail.com', 'A user of PCS', 'carriepw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('carrie@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (153, 'carrie@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (157, 'carrie@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (103, 'carrie@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (91, 'carrie@gmail.com', 'Dog');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2021-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-08-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('carrie@gmail.com', '2022-09-05');

INSERT INTO Users(name, email, description, password) VALUES ('caleb', 'caleb@gmail.com', 'A user of PCS', 'calebpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('caleb@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'caleb@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'caleb@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (66, 'caleb@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2021-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('caleb@gmail.com', '2022-09-05');

INSERT INTO Users(name, email, description, password) VALUES ('charlie', 'charlie@gmail.com', 'A user of PCS', 'charliepw');
INSERT INTO PetOwners(email) VALUES ('charlie@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'abby', 'abby needs love!', 'abby is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'daisy', 'daisy needs love!', 'daisy is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'lucky', 'lucky needs love!', 'lucky is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('charlie@gmail.com', 'chippy', 'chippy needs love!', 'chippy is a Hamster', 'Hamster');

INSERT INTO Users(name, email, description, password) VALUES ('dick', 'dick@gmail.com', 'A user of PCS', 'dickpw');
INSERT INTO PetOwners(email) VALUES ('dick@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dick@gmail.com', 'jacky', 'jacky needs love!', 'jacky is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('dick@gmail.com', 'axa', 'axa needs love!', 'axa is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('dawson', 'dawson@gmail.com', 'A user of PCS', 'dawsonpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('dawson@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'dawson@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (133, 'dawson@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (260, 'dawson@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (43, 'dawson@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-08-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-08-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-08-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-08-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('dawson@gmail.com', '2022-08-05');

INSERT INTO Users(name, email, description, password) VALUES ('emma', 'emma@gmail.com', 'A user of PCS', 'emmapw');
INSERT INTO PetOwners(email) VALUES ('emma@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('emma@gmail.com', 'sammy', 'sammy needs love!', 'sammy is a Monkey', 'Monkey');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('emma@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (164, 'emma@gmail.com', 'Monkey');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'emma@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (76, 'emma@gmail.com', 'Snake');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2021-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('emma@gmail.com', '2022-02-05');

INSERT INTO Users(name, email, description, password) VALUES ('felix', 'felix@gmail.com', 'A user of PCS', 'felixpw');
INSERT INTO PetOwners(email) VALUES ('felix@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('felix@gmail.com', 'digger', 'digger needs love!', 'digger is a Cat', 'Cat');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('felix@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'felix@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'felix@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-04-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-04-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-04-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('felix@gmail.com', '2022-04-05');

INSERT INTO Users(name, email, description, password) VALUES ('gordon', 'gordon@gmail.com', 'A user of PCS', 'gordonpw');
INSERT INTO PetOwners(email) VALUES ('gordon@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'axa', 'axa needs love!', 'axa is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('gordon@gmail.com', 'ginger', 'ginger needs love!', 'ginger is a Snake', 'Snake');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('gordon@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (52, 'gordon@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'gordon@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (71, 'gordon@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (230, 'gordon@gmail.com', 'Lion');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-04-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-04-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-04-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-04-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-04-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-05-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('gordon@gmail.com', '2022-03-05');

INSERT INTO Users(name, email, description, password) VALUES ('hassan', 'hassan@gmail.com', 'A user of PCS', 'hassanpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('hassan@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (35, 'hassan@gmail.com', 'Mouse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (223, 'hassan@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (126, 'hassan@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (68, 'hassan@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (218, 'hassan@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2021-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-01-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-01-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-01-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-01-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-01-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-10-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-10-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-10-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('hassan@gmail.com', '2022-10-05');

INSERT INTO Users(name, email, description, password) VALUES ('ian', 'ian@gmail.com', 'A user of PCS', 'ianpw');
INSERT INTO PetOwners(email) VALUES ('ian@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('ian@gmail.com', 'roscoe', 'roscoe needs love!', 'roscoe is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ian@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'ian@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (48, 'ian@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (40, 'ian@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (188, 'ian@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (85, 'ian@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-03-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-05-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-05-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-05-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-05-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2021-05-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('ian@gmail.com', '2022-02-05');

INSERT INTO Users(name, email, description, password) VALUES ('jenny', 'jenny@gmail.com', 'A user of PCS', 'jennypw');
INSERT INTO PetOwners(email) VALUES ('jenny@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'gus', 'gus needs love!', 'gus is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Lion', 'Lion');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'maddie', 'maddie needs love!', 'maddie is a Hamster', 'Hamster');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('jenny@gmail.com', 'ginger', 'ginger needs love!', 'ginger is a Turtle', 'Turtle');

INSERT INTO Users(name, email, description, password) VALUES ('konstance', 'konstance@gmail.com', 'A user of PCS', 'konstancepw');
INSERT INTO PetOwners(email) VALUES ('konstance@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('konstance@gmail.com', 'roger', 'roger needs love!', 'roger is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('konstance@gmail.com', 'biscuit', 'biscuit needs love!', 'biscuit is a Mouse', 'Mouse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('konstance@gmail.com', 'chad', 'chad needs love!', 'chad is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('konstance@gmail.com', 'rufus', 'rufus needs love!', 'rufus is a Dog', 'Dog');

INSERT INTO Users(name, email, description, password) VALUES ('rupert', 'rupert@gmail.com', 'A user of PCS', 'rupertpw');
INSERT INTO PetOwners(email) VALUES ('rupert@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('rupert@gmail.com', 'chad', 'chad needs love!', 'chad is a Turtle', 'Turtle');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rupert@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'rupert@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rupert@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rupert@gmail.com', 'Cat');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2021-01-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rupert@gmail.com', '2022-06-07');

INSERT INTO Users(name, email, description, password) VALUES ('ronald', 'ronald@gmail.com', 'A user of PCS', 'ronaldpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('ronald@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'ronald@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'ronald@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'ronald@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2021-11-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('ronald@gmail.com', '2022-01-07');

INSERT INTO Users(name, email, description, password) VALUES ('romeo', 'romeo@gmail.com', 'A user of PCS', 'romeopw');
INSERT INTO PetOwners(email) VALUES ('romeo@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('romeo@gmail.com', 'chewie', 'chewie needs love!', 'chewie is a Snake', 'Snake');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('romeo@gmail.com', 'felix', 'felix needs love!', 'felix is a Dog', 'Dog');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('romeo@gmail.com', 'jacky', 'jacky needs love!', 'jacky is a Lion', 'Lion');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('romeo@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (100, 'romeo@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'romeo@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'romeo@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'romeo@gmail.com', 'Bird');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2021-11-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('romeo@gmail.com', '2022-01-07');

INSERT INTO Users(name, email, description, password) VALUES ('rick', 'rick@gmail.com', 'A user of PCS', 'rickpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('rick@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (140, 'rick@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (110, 'rick@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (60, 'rick@gmail.com', 'Cat');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (120, 'rick@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (130, 'rick@gmail.com', 'Monkey');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2021-07-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('rick@gmail.com', '2022-06-07');

INSERT INTO Users(name, email, description, password) VALUES ('xiaoping', 'xiaoping@gmail.com', 'A user of PCS', 'xiaopingpw');
INSERT INTO PetOwners(email) VALUES ('xiaoping@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoping@gmail.com', 'roger', 'roger needs love!', 'roger is a Snake', 'Snake');

INSERT INTO Users(name, email, description, password) VALUES ('xiaoming', 'xiaoming@gmail.com', 'A user of PCS', 'xiaomingpw');
INSERT INTO PetOwners(email) VALUES ('xiaoming@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoming@gmail.com', 'bandit', 'bandit needs love!', 'bandit is a Horse', 'Horse');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoming@gmail.com', 'abby', 'abby needs love!', 'abby is a Turtle', 'Turtle');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaoming@gmail.com', 'choco', 'choco needs love!', 'choco is a Mouse', 'Mouse');

INSERT INTO Users(name, email, description, password) VALUES ('xiaodong', 'xiaodong@gmail.com', 'A user of PCS', 'xiaodongpw');
INSERT INTO PetOwners(email) VALUES ('xiaodong@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaodong@gmail.com', 'hugo', 'hugo needs love!', 'hugo is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('xiaolong', 'xiaolong@gmail.com', 'A user of PCS', 'xiaolongpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaolong@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (147, 'xiaolong@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (123, 'xiaolong@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (93, 'xiaolong@gmail.com', 'Dog');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (198, 'xiaolong@gmail.com', 'Horse');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-06-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-06-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-06-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-06-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2021-06-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaolong@gmail.com', '2022-09-05');

INSERT INTO Users(name, email, description, password) VALUES ('xiaobao', 'xiaobao@gmail.com', 'A user of PCS', 'xiaobaopw');
INSERT INTO PetOwners(email) VALUES ('xiaobao@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaobao@gmail.com', 'chad', 'chad needs love!', 'chad is a Cat', 'Cat');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaobao@gmail.com', 'cloud', 'cloud needs love!', 'cloud is a Dog', 'Dog');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaobao@gmail.com', True, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (90, 'xiaobao@gmail.com', 'Bird');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'xiaobao@gmail.com', 'Mouse');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2021-07-07');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-01');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-02');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-03');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-04');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-05');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-06');
INSERT INTO FullTimeLeave(email, leave_date) VALUES ('xiaobao@gmail.com', '2022-01-07');

INSERT INTO Users(name, email, description, password) VALUES ('xiaorong', 'xiaorong@gmail.com', 'A user of PCS', 'xiaorongpw');
INSERT INTO PetOwners(email) VALUES ('xiaorong@gmail.com');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaorong@gmail.com', 'charlie', 'charlie needs love!', 'charlie is a Bird', 'Bird');
INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('xiaorong@gmail.com', 'roger', 'roger needs love!', 'roger is a Bird', 'Bird');

INSERT INTO Users(name, email, description, password) VALUES ('xiaohong', 'xiaohong@gmail.com', 'A user of PCS', 'xiaohongpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaohong@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (174, 'xiaohong@gmail.com', 'Horse');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (46, 'xiaohong@gmail.com', 'Turtle');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-03-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-12-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-12-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-12-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-12-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2021-12-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-02-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-02-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-02-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-02-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-02-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-03-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-03-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-03-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-03-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaohong@gmail.com', '2022-03-05');

INSERT INTO Users(name, email, description, password) VALUES ('xiaozong', 'xiaozong@gmail.com', 'A user of PCS', 'xiaozongpw');
INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('xiaozong@gmail.com', False, 0);
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (45, 'xiaozong@gmail.com', 'Turtle');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (80, 'xiaozong@gmail.com', 'Snake');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (105, 'xiaozong@gmail.com', 'Hamster');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (187, 'xiaozong@gmail.com', 'Lion');
INSERT INTO TakecarePrice(daily_price, email, species) VALUES (148, 'xiaozong@gmail.com', 'Monkey');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-11-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-11-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-11-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-11-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-11-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2021-09-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-10-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-10-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-10-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-10-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-10-05');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-09-01');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-09-02');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-09-03');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-09-04');
INSERT INTO PartTimeAvail(email, work_date) VALUES ('xiaozong@gmail.com', '2022-09-05');

INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'dawson@gmail.com', 'rufus', '2020-01-01 00:00:00', '2021-04-29', '2021-05-04', 48, 57, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'carrie@gmail.com', 'cloud', '2020-01-01 00:00:01', '2021-05-26', '2021-05-30', 91, 117, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'cassie@gmail.com', 'gus', '2020-01-01 00:00:02', '2022-02-12', '2022-02-14', 90, 99, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'rick@gmail.com', 'chad', '2020-01-01 00:00:03', '2022-01-15', '2022-01-16', 110, 116, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'connor@gmail.com', 'roger', '2020-01-01 00:00:04', '2021-08-14', '2021-08-19', 120, 127, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'bob@gmail.com', 'axa', '2020-01-01 00:00:05', '2021-04-07', '2021-04-13', 143, 149, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'xiaohong@gmail.com', 'lucky', '2020-01-01 00:00:06', '2022-09-29', '2022-10-01', 174, 178, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'carrie@gmail.com', 'rufus', '2020-01-01 00:00:07', '2022-05-25', '2022-05-26', 91, 114, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'felix@gmail.com', 'chad', '2020-01-01 00:00:08', '2022-11-16', '2022-11-16', 90, 94, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'rick@gmail.com', 'chad', '2020-01-01 00:00:09', '2022-03-05', '2022-03-05', 60, 71, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'alex@gmail.com', 'chad', '2020-01-01 00:00:10', '2021-10-21', '2021-10-27', 48, 72, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'ian@gmail.com', 'digger', '2020-01-01 00:00:11', '2021-05-07', '2021-05-10', 48, 48, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'ian@gmail.com', 'ginger', '2020-01-01 00:00:12', '2021-03-05', '2021-03-07', 188, 218, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'emma@gmail.com', 'digger', '2020-01-01 00:00:13', '2022-09-05', '2022-09-05', 45, 53, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'xiaolong@gmail.com', 'daisy', '2020-01-01 00:00:14', '2021-11-04', '2021-11-08', 93, 120, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'bob@gmail.com', 'ginger', '2020-01-01 00:00:15', '2022-11-19', '2022-11-20', 224, 246, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'carrie@gmail.com', 'bandit', '2020-01-01 00:00:16', '2022-01-01', '2022-01-01', 157, 165, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'beth@gmail.com', 'hugo', '2020-01-01 00:00:17', '2022-02-07', '2022-02-09', 90, 115, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'caleb@gmail.com', 'roscoe', '2020-01-01 00:00:18', '2022-01-17', '2022-01-18', 66, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beth@gmail.com', 'hassan@gmail.com', 'boomer', '2020-01-01 00:00:19', '2021-08-03', '2021-08-05', 126, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'alex@gmail.com', 'digger', '2020-01-01 00:00:20', '2021-08-06', '2021-08-11', 48, 48, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'romeo@gmail.com', 'roscoe', '2020-01-01 00:00:21', '2021-09-09', '2021-09-09', 140, 166, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'xiaozong@gmail.com', 'roger', '2020-01-01 00:00:22', '2022-12-15', '2022-12-17', 80, 107, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'rick@gmail.com', 'chad', '2020-01-01 00:00:23', '2021-03-24', '2021-03-28', 60, 84, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'connor@gmail.com', 'chad', '2020-01-01 00:00:24', '2021-07-09', '2021-07-14', 110, 114, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'xiaolong@gmail.com', 'cloud', '2020-01-01 00:00:25', '2021-11-11', '2021-11-14', 93, 111, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'arnold@gmail.com', 'roger', '2020-01-01 00:00:26', '2021-08-15', '2021-08-19', 173, 174, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'arnold@gmail.com', 'roger', '2020-01-01 00:00:27', '2022-07-27', '2022-07-31', 32, 44, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaorong@gmail.com', 'arnold@gmail.com', 'roger', '2020-01-01 00:00:28', '2021-05-14', '2021-05-17', 180, 194, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beth@gmail.com', 'ian@gmail.com', 'jake', '2020-01-01 00:00:29', '2022-02-10', '2022-02-12', 48, 76, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'ronald@gmail.com', 'axa', '2020-01-01 00:00:30', '2021-08-23', '2021-08-23', 80, 81, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'rick@gmail.com', 'roscoe', '2020-01-01 00:00:31', '2022-03-30', '2022-04-03', 140, 148, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'rick@gmail.com', 'bandit', '2020-01-01 00:00:32', '2022-08-17', '2022-08-20', 140, 153, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'arnold@gmail.com', 'jake', '2020-01-01 00:00:33', '2021-12-09', '2021-12-09', 32, 61, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'rupert@gmail.com', 'bandit', '2020-01-01 00:00:34', '2021-04-06', '2021-04-11', 100, 125, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('emma@gmail.com', 'arnold@gmail.com', 'sammy', '2020-01-01 00:00:35', '2021-09-17', '2021-09-21', 223, 227, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beth@gmail.com', 'emma@gmail.com', 'jake', '2020-01-01 00:00:36', '2022-07-29', '2022-08-03', 45, 65, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'ian@gmail.com', 'axa', '2020-01-01 00:00:37', '2021-10-25', '2021-10-31', 148, 172, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'caleb@gmail.com', 'roscoe', '2020-01-01 00:00:38', '2022-10-24', '2022-10-25', 66, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'connor@gmail.com', 'roscoe', '2020-01-01 00:00:39', '2022-06-04', '2022-06-08', 140, 146, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'alex@gmail.com', 'axa', '2020-01-01 00:00:40', '2021-05-25', '2021-05-30', 33, 42, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'arnold@gmail.com', 'hugo', '2020-01-01 00:00:41', '2022-02-10', '2022-02-10', 180, 182, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'rupert@gmail.com', 'jacky', '2020-01-01 00:00:42', '2022-06-14', '2022-06-19', 60, 81, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'ian@gmail.com', 'chad', '2020-01-01 00:00:43', '2021-08-09', '2021-08-11', 188, 195, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'alex@gmail.com', 'hugo', '2020-01-01 00:00:44', '2022-10-17', '2022-10-23', 33, 38, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoming@gmail.com', 'xiaolong@gmail.com', 'bandit', '2020-01-01 00:00:45', '2022-05-06', '2022-05-07', 198, 212, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('romeo@gmail.com', 'dawson@gmail.com', 'felix', '2020-01-01 00:00:46', '2021-02-07', '2021-02-13', 48, 60, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'ian@gmail.com', 'ginger', '2020-01-01 00:00:47', '2022-05-30', '2022-06-02', 40, 48, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'bob@gmail.com', 'roger', '2020-01-01 00:00:48', '2022-03-04', '2022-03-07', 224, 249, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'caleb@gmail.com', 'roscoe', '2020-01-01 00:00:49', '2022-11-20', '2022-11-25', 66, 81, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'dawson@gmail.com', 'jake', '2020-01-01 00:00:50', '2021-09-19', '2021-09-24', 48, 70, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('emma@gmail.com', 'emma@gmail.com', 'sammy', '2020-01-01 00:00:51', '2021-01-04', '2021-01-04', 164, 173, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'rick@gmail.com', 'digger', '2020-01-01 00:00:52', '2022-07-15', '2022-07-15', 60, 66, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'carrie@gmail.com', 'jake', '2020-01-01 00:00:53', '2022-09-19', '2022-09-24', 91, 119, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'felix@gmail.com', 'chad', '2020-01-01 00:00:54', '2021-01-14', '2021-01-18', 90, 113, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'bob@gmail.com', 'axa', '2020-01-01 00:00:55', '2021-09-23', '2021-09-25', 143, 173, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'gordon@gmail.com', 'ginger', '2020-01-01 00:00:56', '2022-09-27', '2022-10-01', 52, 52, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'carrie@gmail.com', 'hugo', '2020-01-01 00:00:57', '2021-02-15', '2021-02-18', 153, 160, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'rick@gmail.com', 'chad', '2020-01-01 00:00:58', '2022-12-06', '2022-12-09', 60, 88, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'arnold@gmail.com', 'jake', '2020-01-01 00:00:59', '2022-01-03', '2022-01-08', 32, 41, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoming@gmail.com', 'xiaohong@gmail.com', 'abby', '2020-01-01 00:01:00', '2022-10-08', '2022-10-13', 46, 54, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'alex@gmail.com', 'hugo', '2020-01-01 00:01:01', '2021-04-28', '2021-04-30', 33, 36, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('romeo@gmail.com', 'dawson@gmail.com', 'felix', '2020-01-01 00:01:02', '2022-08-30', '2022-09-05', 48, 59, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'gordon@gmail.com', 'maddie', '2020-01-01 00:01:03', '2022-01-25', '2022-01-25', 93, 105, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'dawson@gmail.com', 'cloud', '2020-01-01 00:01:04', '2021-04-11', '2021-04-11', 48, 49, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('becky@gmail.com', 'xiaohong@gmail.com', 'bandit', '2020-01-01 00:01:05', '2022-02-02', '2022-02-08', 174, 179, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'arnold@gmail.com', 'roger', '2020-01-01 00:01:06', '2022-06-18', '2022-06-24', 32, 38, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'arnold@gmail.com', 'ginger', '2020-01-01 00:01:07', '2022-11-13', '2022-11-14', 173, 173, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'caleb@gmail.com', 'roscoe', '2020-01-01 00:01:08', '2021-09-24', '2021-09-29', 66, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'arnold@gmail.com', 'chad', '2020-01-01 00:01:09', '2021-12-18', '2021-12-24', 32, 46, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'ronald@gmail.com', 'axa', '2020-01-01 00:01:10', '2021-04-07', '2021-04-09', 80, 95, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('romeo@gmail.com', 'xiaozong@gmail.com', 'jacky', '2020-01-01 00:01:11', '2021-05-05', '2021-05-09', 187, 191, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('beth@gmail.com', 'felix@gmail.com', 'boomer', '2020-01-01 00:01:12', '2021-11-18', '2021-11-24', 68, 68, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaorong@gmail.com', 'bob@gmail.com', 'charlie', '2020-01-01 00:01:13', '2022-08-14', '2022-08-20', 143, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'cassie@gmail.com', 'lucky', '2020-01-01 00:01:14', '2022-05-07', '2022-05-11', 100, 110, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('felix@gmail.com', 'rick@gmail.com', 'digger', '2020-01-01 00:01:15', '2021-07-29', '2021-08-03', 60, 71, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaodong@gmail.com', 'ian@gmail.com', 'hugo', '2020-01-01 00:01:16', '2021-09-11', '2021-09-15', 148, 158, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoming@gmail.com', 'cassie@gmail.com', 'bandit', '2020-01-01 00:01:17', '2022-09-11', '2022-09-15', 100, 103, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('emma@gmail.com', 'cassie@gmail.com', 'sammy', '2020-01-01 00:01:18', '2021-02-09', '2021-02-09', 130, 159, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'emma@gmail.com', 'chewie', '2020-01-01 00:01:19', '2022-01-01', '2022-01-02', 76, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'cassie@gmail.com', 'abby', '2020-01-01 00:01:20', '2021-03-14', '2021-03-15', 140, 159, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'xiaolong@gmail.com', 'chad', '2020-01-01 00:01:21', '2022-04-26', '2022-04-30', 147, 160, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('romeo@gmail.com', 'bob@gmail.com', 'chewie', '2020-01-01 00:01:22', '2021-10-31', '2021-11-04', 224, 248, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoming@gmail.com', 'carrie@gmail.com', 'choco', '2020-01-01 00:01:23', '2022-02-15', '2022-02-15', 103, 129, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'hassan@gmail.com', 'maddie', '2020-01-01 00:01:24', '2021-10-06', '2021-10-10', 68, 74, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaobao@gmail.com', 'rick@gmail.com', 'chad', '2020-01-01 00:01:25', '2022-03-20', '2022-03-25', 60, 79, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'gordon@gmail.com', 'ginger', '2020-01-01 00:01:26', '2022-02-01', '2022-02-07', 52, 71, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'gordon@gmail.com', 'axa', '2020-01-01 00:01:27', '2022-03-08', '2022-03-10', 71, 76, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'dawson@gmail.com', 'roger', '2020-01-01 00:01:28', '2022-07-03', '2022-07-08', 43, 56, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'carrie@gmail.com', 'axa', '2020-01-01 00:01:29', '2021-05-14', '2021-05-15', 103, 113, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('xiaoping@gmail.com', 'bob@gmail.com', 'roger', '2020-01-01 00:01:30', '2022-06-22', '2022-06-28', 224, 254, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('jenny@gmail.com', 'bob@gmail.com', 'gus', '2020-01-01 00:01:31', '2021-04-16', '2021-04-16', 143, 171, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('alice@gmail.com', 'gordon@gmail.com', 'bandit', '2020-01-01 00:01:32', '2021-08-16', '2021-08-17', 230, 250, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('ian@gmail.com', 'xiaozong@gmail.com', 'roscoe', '2020-01-01 00:01:33', '2021-06-06', '2021-06-08', 187, 187, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('rupert@gmail.com', 'connor@gmail.com', 'chad', '2020-01-01 00:01:34', '2021-08-02', '2021-08-05', 110, 133, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('charlie@gmail.com', 'romeo@gmail.com', 'abby', '2020-01-01 00:01:35', '2022-10-31', '2022-11-02', 140, 151, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('romeo@gmail.com', 'carrie@gmail.com', 'felix', '2020-01-01 00:01:36', '2022-01-10', '2022-01-12', 91, 98, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('dick@gmail.com', 'bob@gmail.com', 'axa', '2020-01-01 00:01:37', '2022-03-08', '2022-03-14', 143, 146, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('konstance@gmail.com', 'arnold@gmail.com', 'roger', '2020-01-01 00:01:38', '2021-10-05', '2021-10-10', 32, 47, NULL, False, '1', '1', NULL, NULL);
INSERT INTO BidsFor VALUES ('gordon@gmail.com', 'arnold@gmail.com', 'ginger', '2020-01-01 00:01:39', '2021-03-10', '2021-03-15', 173, 179, NULL, False, '1', '1', NULL, NULL);




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
