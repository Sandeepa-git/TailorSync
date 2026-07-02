import numpy as np
import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

# Ensure the models directory exists
os.makedirs("app/ai_models", exist_ok=True)

print("Generating synthetic body measurement data...")
# Synthetic data for measurement prediction (regression)
# Features: height (cm), weight (kg)
# Targets: chest, waist, hip, shoulder, sleeve_length, inseam
np.random.seed(42)
n_samples = 1000

height = np.random.normal(170, 10, n_samples)
weight = height * 0.4 + np.random.normal(0, 5, n_samples)

# Simplified proportional relationships with some noise
chest = height * 0.55 + np.random.normal(0, 3, n_samples)
waist = weight * 1.1 + np.random.normal(0, 4, n_samples)
hip = waist * 1.2 + np.random.normal(0, 3, n_samples)
shoulder = height * 0.25 + np.random.normal(0, 1.5, n_samples)
sleeve_length = height * 0.35 + np.random.normal(0, 2, n_samples)
inseam = height * 0.45 + np.random.normal(0, 2, n_samples)

X_meas = pd.DataFrame({'height': height, 'weight': weight})
y_meas = pd.DataFrame({
    'chest': chest, 'waist': waist, 'hip': hip, 
    'shoulder': shoulder, 'sleeve_length': sleeve_length, 'inseam': inseam
})

print("Training Measurement Prediction Model (Linear Regression)...")
model_meas = LinearRegression()
model_meas.fit(X_meas, y_meas)
joblib.dump(model_meas, "app/ai_models/measurement_predictor.joblib")
print("Measurement model saved.")

print("Generating synthetic data for Fabric Recommendation...")
# Features: Garment Type (encoded), Occasion (encoded)
# Classes: Fabric ID
# For simplicity, we'll map strings to integers for training.
# Garments: 0=Shirt, 1=Trouser, 2=Suit, 3=Dress
# Occasions: 0=Casual, 1=Formal, 2=Party, 3=Summer
# Fabrics: 0=Cotton, 1=Wool, 2=Silk, 3=Linen

# Synthesize rules:
# Casual + Shirt -> Cotton (0) or Linen (3)
# Formal + Suit -> Wool (1)
# Party + Dress -> Silk (2)
# Summer + Shirt -> Linen (3)
X_fab = []
y_fab = []
for _ in range(500):
    garment = np.random.choice([0, 1, 2, 3])
    occasion = np.random.choice([0, 1, 2, 3])
    X_fab.append([garment, occasion])
    
    if occasion == 1 and garment == 2:
        y_fab.append(1) # Wool
    elif occasion == 3:
        y_fab.append(3) # Linen
    elif occasion == 2 and garment == 3:
        y_fab.append(2) # Silk
    else:
        y_fab.append(0) # Cotton

print("Training Fabric Recommendation Model (Random Forest)...")
model_fab = RandomForestClassifier(n_estimators=50, random_state=42)
model_fab.fit(X_fab, y_fab)
joblib.dump(model_fab, "app/ai_models/fabric_recommender.joblib")
print("Fabric recommendation model saved.")

print("All synthetic models trained successfully!")
