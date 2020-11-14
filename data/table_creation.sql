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
