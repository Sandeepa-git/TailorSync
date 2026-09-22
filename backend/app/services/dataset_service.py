import os
import csv
import logging
from typing import List, Dict, Any, Optional

logger = logging.getLogger(__name__)

class DatasetService:
    def __init__(self):
        self.data_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), 'data')
        self._cache = {}

    def _get_filename_for_garment(self, garment_type: str) -> str:
        # Example: 'Short Sleeve Shirt' -> 'shirt_dataset.csv'
        # 'Long Trouser' -> 'trouser_dataset.csv'
        name_lower = garment_type.lower()
        if 'shirt' in name_lower:
            return 'shirt_dataset.csv'
        elif 'trouser' in name_lower:
            return 'trouser_dataset.csv'
        elif 'dress' in name_lower:
            return 'dresses_dataset.csv'
        elif 'suit' in name_lower:
            return 'suits_dataset.csv'
        elif 'jacket' in name_lower:
            return 'jackets_dataset.csv'
        elif 'coat' in name_lower:
            if 'waist' in name_lower:
                return 'waistcoats_dataset.csv'
            return 'coats_dataset.csv'
        elif 'uniform' in name_lower:
            if 'school' in name_lower:
                return 'school_uniforms_dataset.csv'
            return 'office_uniforms_dataset.csv'
        elif 'traditional' in name_lower:
            return 'traditional_dataset.csv'
        
        # Fallback
        return f"{garment_type.lower().replace(' ', '_')}_dataset.csv"

    def _load_csv(self, filename: str) -> List[Dict[str, str]]:
        if filename in self._cache:
            return self._cache[filename]

        filepath = os.path.join(self.data_dir, filename)
        if not os.path.exists(filepath):
            logger.warning(f"Dataset {filepath} not found.")
            return []

        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                reader = csv.DictReader(f)
                rows = [row for row in reader]
                self._cache[filename] = rows
                return rows
        except Exception as e:
            logger.error(f"Failed to read {filename}: {e}")
            return []

    def get_dataset_context(self, garment_type: str) -> str:
        """Returns the full text context of the relevant dataset for the AI prompt."""
        filename = self._get_filename_for_garment(garment_type)
        rows = self._load_csv(filename)
        
        if not rows:
            return f"No dataset available for {garment_type}."
            
        context = f"=== {garment_type.upper()} DATASET ===\n\n"
        # Include headers
        headers = list(rows[0].keys())
        context += ",".join(headers) + "\n"
        
        for row in rows:
            context += ",".join(str(row.get(h, "")) for h in headers) + "\n"
            
        return context

    def get_exact_match(self, garment_type: str, measurements: Dict[str, Any]) -> Optional[Dict[str, str]]:
        """
        Attempts to find a dataset row that exactly matches the provided measurements.
        Measurements should map to dataset columns exactly.
        """
        filename = self._get_filename_for_garment(garment_type)
        rows = self._load_csv(filename)
        if not rows:
            return None

        # Map frontend measurement names to dataset column names for matching
        # Examples based on rules
        for row in rows:
            match = True
            for key, val in measurements.items():
                dataset_key = self._map_to_dataset_key(garment_type, key)
                if dataset_key and dataset_key in row:
                    try:
                        # Compare numerically if possible
                        if float(row[dataset_key]) != float(val):
                            match = False
                            break
                    except ValueError:
                        # Fallback to string match
                        if str(row[dataset_key]).strip() != str(val).strip():
                            match = False
                            break
            if match:
                return row
        return None
        
    def _map_to_dataset_key(self, garment_type: str, field_name: str) -> str:
        """Maps TailorSync application fields to exact Dataset Columns based on rules."""
        mapping = {
            "Height Till Knee": "Height till Knee",
            "Height": "Height",
            "Waist": "Waist",
            "Around Knee": "Round Knee",
            "Trouser Leg Opening": "Round End",
            "Long Trouser Leg Opening": "Round End",
            "Short Trouser Leg Opening": "Round End",
            "Seat": "Seat",
            "Crotch": "Crotch",
            "Shoulder Length": "Shoulder",
            "Short Sleeve Length": "Short Sleeve Length",
            "Long Sleeve Length": "Long Sleeve Length",
            "Chest": "Chest",
            "Collar Size": "Collar Size",
            "Sleeve Opening": "Sleeve Open",
        }
        return mapping.get(field_name, field_name)
