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

f.write(makeUser('panter', True, False, False))
f.write(makeUser('peter', False, True, False))
f.write(makeUser('patty', False, False, True))
f.write(makeUser('patrick', True, False, False))
f.write(makeUser('patricia', False, True, False))

f.write('done')
f.close()

