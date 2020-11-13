# usage: run python mkdata.py
# this will generate a file called query.sql containing initial insert statements
# we should .gitignore the query.sql

import os
import datetime
import random

outfile = "query2.sql"

userNames = 'alice alex arnold bob becky beth connor cassie carrie caleb charlie dick dawson emma felix gordon hassan ian jenny konstance rupert ronald romeo rick xiaoping xiaoming xiaodong xiaolong xiaobao xiaorong xiaohong xiaozong'.split()

types = 'Dog Cat Hamster Mouse Bird Horse Turtle Snake Monkey Lion'.split()

basePrices = dict(zip(types, range(50, 50 + 10*len(types), 10)))

moreNames = 'cassie carrie carl carlos caren canneth cain carmen cejudo celine cevan catarth columbus xiaoping xiaoming xiaodong xiaolong xiaobao xiaorong xiaohong xiaozong'

petNames = ['roger', 'boomer', 'jerry', 'tom', 'felix', 'roscoe', 'sammy',
            'cloud', 'millie', 'rufus', 'axa', 'abby', 'alfie', 'bandit', 'biscuit', 'buster',
            'chad', 'charlie', 'chewie', 'chippy', 'choco', 'daisy',
            'digger', 'fergie', 'fido', 'freddie', 'ginger', 'gizmo', 'gus', 'hugo',
            'jacky', 'jake', 'jaxson', 'logan', 'lucky', 'maddie']

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

months = list(range(1, 13)) # list repesenting the 12 months

class Pet:
    def __init__(self, name, species):
        self.name = name
        self.species = species
        self.desc = f'{name} is a {species}'
        self.req = f'{name} needs love!'
    
    def __str__(self):
        return f'{self.name} the {self.species}'

class User:
    def __init__(self, name):
        self.name = name
        self.email = f'{name}@gmail.com'
        self.desc = f'A user of PCS'
        self.pw = f'{name}pw'
        self.isPO = False
        self.isFCT = False
        self.isPCT = False

        # petowner
        self.pets = []

        # caretaker
        self.rating = 0 
        self.caresFor = {}

        # ft caretaker
        self.leave = []

        # pt caretaker
        self.avail = []

    def __str__(self):
        return f'User {self.name}. isPO={isPO}, isFCT={isFCT}, isPCT={isPCT}.\n\
                 rating = {u.rating}, numPets={len(u.pets)}, numCaresFor={len(caresFor)}\n\
                 numLeave={len(u.leave)}, numAvail={len(u.avail)}'

def getRandomBool():
    return random.choice([True, False])

# returns a list of n different (in name) random Pets
# random name and random species
def makePets(n):
    return [Pet(pname, random.choice(types)) for pname in random.sample(petNames, n)]

# returns a random time period of the given length starting somewhere in the year
# randomly pick a startdate in the given year
def getRandomPeriod(yr, length):
    sd = datetime.datetime(yr, 1, 1)
    ed = datetime.datetime(yr, 12, 31)
    n = random.randint(0, (ed - sd).days - length)
    firstDay = sd + datetime.timedelta(n)
    xs = []
    for i in range(length):
        xs.append(firstDay + datetime.timedelta(i))
    return xs

# returns adds numBlocks random day blocks of given length in the yr
def getRandomAvail(yr, length):
    numBlocks = 2
    mths = random.sample(months, numBlocks)
    res = []
    for m in mths:
        sd = datetime.datetime(yr, m, 1)
        for i in range(length):
            res.append(sd + datetime.timedelta(i))
    return res

# adds a random week in 2021 and a random week in 2022 to this User's leave
def giveLeave(u):
    leaveLen = 3
    u.leave.extend(getRandomPeriod(2021, leaveLen))
    u.leave.extend(getRandomPeriod(2022, leaveLen))

# adds random avail in 2021 and in 2022 to this User's avail
def giveAvail(u):
    availLen = 5
    u.avail.extend(getRandomAvail(2021, availLen))
    u.avail.extend(getRandomAvail(2022, availLen))

# give User u a random set of animals he can care for
# if u is part time, we randomly choose some daily price
# else, use the global basePrice
def giveCareFor(u):
    num = random.randint(2, 5) # from 1 to 5 pets
    careList = random.sample(types, num)
    if u.isFCT:
        for animal in careList:
            u.caresFor[animal] = basePrices[animal]
    if u.isPCT:
        for animal in careList:
            u.caresFor[animal] = random.randint(30, 2*basePrices[animal])


# gives User u some random pets
def givePOData(u):
    numPets = random.randint(1, 5) # from 1 to 5 pets
    u.pets = makePets(numPets)

# gives u pets that u can take care of
# gives u leave dates
def giveFCTData(u):
    u.rating = 0
    giveLeave(u)
    giveCareFor(u)

def givePCTData(u):
    u.rating = 0
    giveAvail(u)
    giveCareFor(u)    

# make a random user
# can be either petowner and or ft/pt caretaker
def makeUser(name):
    u = User(name)

    isPO = getRandomBool()
    if isPO:
        u.isPO = True
        givePOData(u)

    if not isPO or getRandomBool(): # if is caretaker
        isFCT = getRandomBool() # decide which type
        if isFCT:
            u.isFCT = True
            u.isPCT = False
            giveFCTData(u)
        else:
            u.isFCT = False
            u.isPCT = True
            givePCTData(u)    
    return u


def sqlInsertPetTypes():
    res = ""
    for k, v in basePrices.items():
        res += f"INSERT INTO PetTypes(species, base_price) VALUES ('{k}', {v});\n"
    return res

def sqlInsertUser(u):
    res = f"INSERT INTO Users(name, email, description, password) VALUES ('{u.name}', '{u.email}', '{u.desc}', '{u.pw}');\n"
    if u.isPO: #insert into petowner table, and then insert the pets
        res += f"INSERT INTO PetOwners(email) VALUES ('{u.email}');\n"
        for p in u.pets:
            res += f"INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('{u.email}', '{p.name}', '{p.req}', '{p.desc}', '{p.species}');\n"

    if u.isFCT: # insert TakecarePrice, Leave
        res += f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{u.email}', {True}, {u.rating});\n"
        for species, price in u.caresFor.items():
            res += f"INSERT INTO TakecarePrice(daily_price, email, species) VALUES ({price}, '{u.email}', '{species}');\n"
        for le in u.leave:
            s = le.strftime("%Y-%m-%d")
            res += f"INSERT INTO FullTimeLeave(email, leave_date) VALUES ('{u.email}', '{s}');\n"
    
    if u.isPCT:
        res += f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{u.email}', {False}, {u.rating});\n"
        for species, price in u.caresFor.items():
            res += f"INSERT INTO TakecarePrice(daily_price, email, species) VALUES ({price}, '{u.email}', '{species}');\n"
        for av in u.avail:
            s = av.strftime("%Y-%m-%d")
            res += f"INSERT INTO PartTimeAvail(email, work_date) VALUES ('{u.email}', '{s}');\n"
    return res


# make all the users
users = []
for un in userNames:
    users.append(makeUser(un))

# categorize the users
petowners = []
caretakers = []
animalCaretakers = dict(zip(types, [[] for t in types]))
for u in users:
    if u.isPO:
        petowners.append(u)
    if u.isFCT or u.isPCT:
        caretakers.append(u)
        for animal in u.caresFor:
            animalCaretakers[animal].append(u)

def getRandomBid(submissionTime):
    yr = random.choice([2021, 2022])
    bidPeriod = getRandomPeriod(yr, random.randint(1, 7))
    sd = bidPeriod[0].strftime("%Y-%m-%d")
    ed = bidPeriod[-1].strftime("%Y-%m-%d")
    
    petowner = random.choice(petowners)
    pet = random.choice(petowner.pets)

    if len(animalCaretakers[pet.species]) > 0:
        caretaker = random.choice(animalCaretakers[pet.species])
        dailyPrice = caretaker.caresFor[pet.species]
        amountBidded = dailyPrice + random.randint(0, 30) # randomly bid higher
    
        return f"INSERT INTO BidsFor VALUES ('{petowner.email}', '{caretaker.email}', '{pet.name}', '{submissionTime}', '{sd}', '{ed}', {dailyPrice}, {amountBidded}, NULL, False, '1', '1', NULL, NULL);\n"
    else:
        return False

# makes everything generated into sql
def run():
    N = len(types)
    f = open(outfile, "w");

    f.write(sqlInsertPetTypes())
    f.write("\n")
    
    for u in users:
        f.write(sqlInsertUser(u))
        f.write("\n")

    bidCount = 0
    for i in range(100):
        start = datetime.datetime(2020, 1, 1)
        t = start + datetime.timedelta(seconds=i)
        b = getRandomBid(t.strftime('%Y-%m-%d %H:%M:%S'))
        if b:
            bidCount += 1
            f.write(b)
    f.write("\n")

    f.close()
    print('done')
    print(f'bids={bidCount}')

run()