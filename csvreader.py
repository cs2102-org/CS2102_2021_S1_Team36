import csv

human_names = []
pet_names = []

with open('md.csv', 'r') as file:
    content = csv.reader(file)
    for c in content:
        human_names.append(c[0].lower())
        pet_names.append(c[2].lower())

for x in range(50):
    print(human_names[x])

human_names.pop(0)
pet_names.pop(0)
print(pet_names)