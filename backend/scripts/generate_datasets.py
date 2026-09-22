import os
import csv
import random

data_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'data')
os.makedirs(data_dir, exist_ok=True)

garment_types = [
    'Dresses',
    'Suits',
    'Jackets',
    'Coats',
    'Waistcoats',
    'School Uniforms',
    'Office Uniforms',
    'Traditional'
]

# Standard fields for garments
fields = ['Shoulder', 'Chest', 'Waist', 'Hips', 'Sleeve Length', 'Height', 'Fabric estimation in meters']

def generate_row():
    shoulder = round(random.uniform(14.0, 20.0) * 2) / 2
    chest = shoulder + round(random.uniform(8.0, 16.0) * 2) / 2
    waist = chest - round(random.uniform(2.0, 8.0) * 2) / 2
    hips = waist + round(random.uniform(2.0, 6.0) * 2) / 2
    sleeve = round(random.uniform(22.0, 26.0) * 2) / 2
    height = round(random.uniform(35.0, 60.0) * 2) / 2
    fabric = round(random.uniform(1.5, 4.0) * 4) / 4
    
    return [shoulder, chest, waist, hips, sleeve, height, fabric]

for garment in garment_types:
    filename = os.path.join(data_dir, f"{garment.lower().replace(' ', '_')}_dataset.csv")
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(fields)
        for _ in range(50):
            writer.writerow(generate_row())

print("Mock datasets generated successfully.")
