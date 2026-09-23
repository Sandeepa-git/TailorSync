import os
import pandas as pd
for f in os.listdir('backend/data'):
    if f.endswith('.csv'):
        df = pd.read_csv('backend/data/' + f)
        print(f"--- {f} ---")
        print(list(df.columns))
