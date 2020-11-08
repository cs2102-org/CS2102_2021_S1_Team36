# usage: run python mkdata.py
# this will generate a file called query.sql containing initial insert statements
# we should .gitignore the query.sql

import os
import datetime

outfile = "query.sql"
# outfile = os.path.join("C:\\", "Users", "Jia Hao", "Desktop", outfile)


petownerNames = 'panter peter patty pattison parthia parthus paragon parata pistachio peran perry pearl'.split()

types = 'Dog Cat Hamster Mouse Bird Horse Turtle Snake Monkey Lion'.split()

ftCaretakerNames = 'cassie carrie carl carlos caren canneth cain carmen cejudo celine cevan catarth columbus'.split()

ptCaretakerNames = 'xiaoping xiaoming xiaodong xiaolong xiaobao xiaorong xiaohong xiaozong'.split()

petNames = ['roger', 'boomer', 'jerry', 'tom', 'felix', 'roscoe', 'sammy',
            'cloud', 'millie', 'rufus', 'axa', 'abby', 'alfie', 'bandit', 'biscuit', 'buster',
            'chad', 'charlie', 'chewie', 'chippy', 'choco', 'daisy',
            'digger', 'fergie', 'fido', 'freddie', 'ginger', 'gizmo', 'gus', 'hugo',
            'jacky', 'jake', 'jaxson', 'logan', 'lucky', 'maddie']

def insertPetType(petType):
    return f"INSERT INTO PetTypes(species, base_price) VALUES ('{petType}', {50 + types.index(petType) * 10});\n"

# insert name into users and petowner table
def insertPetowner(name):
    email = name + '@gmail.com'
    desc = name + ' is a petowner of pcs'
    pw = 'pw' + name
    stmt1 = f"INSERT INTO Users(name, email, description, password) VALUES ('{name}', '{email}', '{desc}', '{pw}');\n"
    stmt2 = f"INSERT INTO PetOwners(email) VALUES ('{email}');\n"
    return stmt1 + stmt2

def getRating(name):
    return len(name) % 6

# insert name into users and ft caretaker table
def insertFtCaretaker(name):
    email = name + '@gmail.com'
    desc = name + ' is a full time caretaker of pcs'
    pw = 'pw' + name
    stmt1 = f"INSERT INTO Users(name, email, description, password) VALUES ('{name}', '{email}', '{desc}', '{pw}');\n"

    fulltime = 'true'
    rating = getRating(name)
    stmt2 = f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{email}', {fulltime}, {rating});\n"
    return stmt1 + stmt2

# insert name into users and pt caretaker table
def insertPtCaretaker(name):
    email = name + '@gmail.com'
    desc = name + ' is a part time caretaker of pcs'
    pw = 'pw' + name
    stmt1 = f"INSERT INTO Users(name, email, description, password) VALUES ('{name}', '{email}', '{desc}', '{pw}');\n"

    fulltime = 'false'
    rating = getRating(name)
    stmt2 = f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{email}', {fulltime}, {rating});\n"

    return stmt1 + stmt2

def insertBoth(): # insert a person who is both caretaker and owner
    pass

def getOwner(k): # call to get an owner
    return petownerNames[k % len(petownerNames)]

def getReq(k):
    reqs = ['needs a lot of care',
            'needs alone time',
            'scared of thunder',
            'scared of vaccumm',
            'likes apples',
            'allergic to peanuts',
            'allergic to grass',
            'scared of snakes',
            'hates cats',
            'hates dogs',
            'needs blanket to sleep',
            'needs to drink 100 plus'
            ]
    return reqs[k % len(reqs)]

def getSpecies(k):
    return types[k % len(types)]

def insertPet(petName, k):
    owner = getOwner(k)
    species = getSpecies(k)
    email = owner + '@gmail.com'
    specialReq = getReq(k)
    desc = petName + ' is a ' + species + ' owned by ' + owner
    stmt = f"INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('{email}', '{petName}', '{specialReq}', '{desc}', '{species}');\n"
    return stmt

# base price is just length of caretaker name * 10 + species index * 10
# daily price is base price + 10 * rating
def insertTakeCare(name, species):
    rating = getRating(name)
    email = name + '@gmail.com'
    basePrice = 50 + types.index(species) * 10
    dailyPrice = basePrice + rating * 5
    stmt = f"INSERT INTO TakecarePrice(daily_price, email, species) VALUES ({dailyPrice}, '{email}', '{species}');\n"
    return stmt

# returns the animals that name can take care of
def getTakecare(name, k):
    T = len(types)
    spec = 2 + (k % (T - 2)) # everyone can take care of first two types, and a random third type
    return [types[0], types[1], types[spec]]


def insertFtLeave(email, dateString):
    stmt = f"INSERT INTO FullTimeLeave(email, leave_date) VALUES ('{email}', '{dateString}');\n"
    return stmt

start = datetime.datetime(2020, 1, 1)
def getLeave(name, k):
    email = name + '@gmail.com'
    stmt = ''
    startDate = start + datetime.timedelta(7 * k)
    for i in range(9): # book 9 consecutive days
        curDate = startDate + datetime.timedelta(i)
        stmt += insertFtLeave(email, curDate.strftime("%Y-%m-%d"))    

    startDate += datetime.timedelta(len(ftCaretakerNames) * 7)
    for i in range(9): # book 9 consecutive days
        curDate = startDate + datetime.timedelta(i)
        stmt += insertFtLeave(email, curDate.strftime("%Y-%m-%d"))
    return stmt 

# get the list of caretakers who can take care of this type
def getValidCaretakers(petType):
    res = []
    for k, name in enumerate(ftCaretakerNames):
        if petType in getTakecare(name, k):
            res.append(name)
    for k, name in enumerate(ptCaretakerNames):
        if petType in getTakecare(name, k):
            res.append(name)
    return res

def insertBid(ownerEmail, caretakerEmail, petName, submissionTime, startDate, endDate, price, amountBidded, isConfirmed, isPaid, paymentType, transferType, rating):
    stmt = f"INSERT INTO BidsFor(owner_email, caretaker_email, pet_name, \
        submission_time, start_date, end_date, \
        price, amount_bidded, \
        is_confirmed, is_paid, payment_type, transfer_type, rating) \
        VALUES (\
        '{ownerEmail}', '{caretakerEmail}', '{petName}', \
        '{submissionTime}', '{startDate}', '{endDate}', \
        {price}, {amountBidded}, \
        {isConfirmed}, {isPaid}, '{paymentType}', '{transferType}', {rating});"
    return stmt

# get the bids involving this pet
def getBids(petName, k):
    owner = getOwner(k)
    ownerEmail = owner + '@gmail.com'
    species = getSpecies(k)
    caretakers = getValidCaretakers(species)
    ct = caretakers[0]
    durations = [1, 3, 5]
    startDate = start + datetime.timedelta(7 * k)
    timeBetweenBids = 7

def run():
    N = len(types)
    f = open(outfile, "w");

    for name in petownerNames:
        stmt = insertPetowner(name)
        f.write(stmt)
    f.write('\n')
    
    for name in ftCaretakerNames:
        stmt = insertFtCaretaker(name)
        f.write(stmt)
    f.write('\n')

    for name in ptCaretakerNames:
        stmt = insertPtCaretaker(name)
        f.write(stmt)
    f.write('\n')

    for t in types:
        stmt = insertPetType(t)
        f.write(stmt)
    f.write('\n')

    for k, petName in enumerate(petNames):
        stmt = insertPet(petName, k)
        f.write(stmt)
    f.write('\n')

    for k, name in enumerate(ftCaretakerNames):
        ctTypes = getTakecare(name, k)
        for t in ctTypes:
            stmt = insertTakeCare(name, t)
            f.write(stmt)
    f.write('\n')

    for k, name in enumerate(ptCaretakerNames):
        ctTypes = getTakecare(name, k)
        for t in ctTypes:
            stmt = insertTakeCare(name, t)
            f.write(stmt)
    f.write('\n')

    for k, name in enumerate(ftCaretakerNames):
        stmt = getLeave(name, k)
        f.write(stmt)
    f.write('\n')

    f.close()
    print('done')
run()

