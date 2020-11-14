appendingDROP DATABASE IF EXISTS pcs;

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
--==================================================== GENERATED DATA HERE ====================================================
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
--==================================================== GENERATED DATA HERE ====================================================
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
--==================================================== GENERATED DATA HERE ====================================================
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
