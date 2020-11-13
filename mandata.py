import os
import datetime
import random

outfile = "temp.sql"

# use to generate a user
def makeUser(name, isPO, isFCT, isPCT):
    email = name + '@gmail.com'
    pw = name + 'pw'
    desc = name + ' is a User of PCS'
    res = f"INSERT INTO Users(name, email, description, password) VALUES ('{name}', '{email}', '{desc}', '{pw}');\n"

    if isPO:
        res += f"INSERT INTO Petowners(email) VALUES ('{email}');\n"
    if isFCT:
        res += f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{email}', {True}, {0});\n"
    if isPCT:
        res += f"INSERT INTO Caretakers(email, is_fulltime, rating) VALUES ('{email}', {False}, {0});\n"
    return res        

def takecare(email, animal, price):
    return f"INSERT INTO TakecarePrice(daily_price, email, species) VALUES ({price}, '{email}', '{animal}');\n"

def owns(email, pname, ptype):
    return f"INSERT INTO Pets(email, pet_name, special_requirements, description, species) VALUES ('{email}', '{pname}', '{pname} needs love!', '{pname} is a {ptype}', '{ptype}');\n"

f = open(outfile, "w")


f.write(makeUser('cain', False, False, True))
f.write(takecare('cain@gmail.com', 'Dog', 100))
f.write(takecare('cain@gmail.com', 'Cat', 100))
f.write(takecare('cain@gmail.com', 'Hamster', 80))
f.write(takecare('cain@gmail.com', 'Mouse', 80))
f.write(takecare('cain@gmail.com', 'Bird', 90))

f.write(makeUser('apple', True, False, False))
f.write(owns('apple@gmail.com', 'digger', 'Dog'))

f.write(makeUser('pearl', True, False, False))
f.write(owns('pearl@gmail.com', 'digger', 'Dog'))
f.write(owns('pearl@gmail.com', 'cookie', 'Cat'))

f.write(makeUser('carmen', True, False, False))
f.write(owns('carmen@gmail.com', 'harry', 'Hamster'))
f.write(owns('carmen@gmail.com', 'mickey', 'Mouse'))

f.write(makeUser('butch', True, False, False))
f.write(owns('butch@gmail.com', 'biscuit', 'Bird'))

f.write(makeUser('billy', True, False, False))
f.write(owns('billy@gmail.com', 'biscuit', 'Bird'))

f.close()

