import csv

def readNames():
    with open('names.csv', 'r') as file:
        content = csv.reader(file)
        human_names = []
        pet_names = []

        for c in content:
            human_names.append(c[0].lower())
            pet_names.append(c[2].lower())

        # remove the header row
        human_names.pop(0)
        pet_names.pop(0)
        return human_names, pet_names

