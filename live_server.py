import json
import os
from datetime import datetime

import requests
from flask import Flask, jsonify
from flask_cors import CORS

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Saved predictions on this laptop (used only if the cloud cannot be reached)
DATA_FILE = os.path.join(
    BASE_DIR, "assets", "data", "latest_risk.json"
)

# Newest predictions. GitHub Actions updates this file every hour in the cloud.
CLOUD_URL = (
    "https://raw.githubusercontent.com/amnanaeem123-coder/"
    "smog-prediction-backend/main/latest_risk.json"
)

# Looks for the API key on Amna's laptop first, then on Ayesha's laptop
BACKEND_DIR = r"C:\Users\Admin\fyp project"
if not os.path.exists(os.path.join(BACKEND_DIR, "api_key.txt")):
    BACKEND_DIR = r"C:\flutter_projects\FYP-APP\smog-prediction-backend-main"
API_KEY_FILE = os.path.join(BACKEND_DIR, "api_key.txt")

CITIES = {
    "Lahore": (31.5204, 74.3587),
    "Islamabad": (33.6844, 73.0479),
    "Faisalabad": (31.4504, 73.1350),
    "Multan": (30.1575, 71.5249)
}

def classify_risk(visibility):
    if visibility < 0.5:
        return "CRITICAL"
    elif visibility < 2.0:
        return "HIGH"
    elif visibility < 5.0:
        return "MODERATE"
    elif visibility < 10.0:
        return "LOW"
    return "SAFE"


recommendation_map = {
    "CRITICAL": "Motorway Closure Required",
    "HIGH": "Speed Limit 40 km/h - Caution Required",
    "MODERATE": "Speed Limit 60 km/h - Caution Required",
    "LOW": "Reduced Speed Advised - Monitor Conditions",
    "SAFE": "Normal Operations"
}

aqi_labels = {
    1: "Good",
    2: "Fair",
    3: "Moderate",
    4: "Poor",
    5: "Very Poor"
}

app = Flask(__name__)
CORS(app)


def read_local_file():
    """Saved predictions on this laptop."""
    if not os.path.exists(DATA_FILE):
        return None
    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError:
        return None


@app.route("/latest")
def latest():
    # 1. Newest predictions from the cloud (updated every hour)
    try:
        response = requests.get(CLOUD_URL, timeout=5)
        response.raise_for_status()
        data = response.json()
        if isinstance(data, list) and data:
            # Keep a copy on this laptop, so the app still works without internet
            try:
                with open(DATA_FILE, "w", encoding="utf-8") as f:
                    json.dump(data, f, indent=2, ensure_ascii=False)
            except OSError:
                pass
            return jsonify(data)
    except Exception:
        pass  # No internet or GitHub not reachable. Use the saved file below.

    # 2. Saved predictions on this laptop
    data = read_local_file()
    if data is None:
        return jsonify({"error": "Prediction file not found"}), 404
    return jsonify(data)


@app.route("/current")
def current():
    if not os.path.exists(API_KEY_FILE):
        return jsonify({"error": "API key file not found"}), 500

    with open(API_KEY_FILE, "r", encoding="utf-8") as f:
        api_key = f.read().strip()

    if not api_key:
        return jsonify({"error": "API key is empty"}), 500

    results = []

    for city, (lat, lon) in CITIES.items():
        try:
            weather_response = requests.get(
                "https://api.openweathermap.org/data/2.5/weather",
                params={
                    "lat": lat,
                    "lon": lon,
                    "appid": api_key,
                    "units": "metric"
                },
                timeout=20
            )
            weather_response.raise_for_status()
            weather = weather_response.json()

            pollution_response = requests.get(
                "http://api.openweathermap.org/data/2.5/air_pollution",
                params={
                    "lat": lat,
                    "lon": lon,
                    "appid": api_key
                },
                timeout=20
            )
            pollution_response.raise_for_status()
            pollution = pollution_response.json()["list"][0]

            visibility = weather.get("visibility")

            if visibility is None:
                raise ValueError("Visibility unavailable")

            visibility_km = round(visibility / 1000, 2)
            risk = classify_risk(visibility_km)
            aqi = pollution["main"]["aqi"]
            components = pollution["components"]

            results.append({
                "city": city,
                "datetime": datetime.now().astimezone().isoformat(),
                "visibility_km": visibility_km,
                "risk_level": risk,
                "recommendation": recommendation_map[risk],
                "aqi": aqi,
                "aqi_label": aqi_labels.get(aqi, "Unknown"),
                "pm2_5": components.get("pm2_5"),
                "pm10": components.get("pm10"),
                "no2": components.get("no2"),
                "o3": components.get("o3"),
                "so2": components.get("so2"),
                "co": components.get("co"),
                "temperature_c": weather.get("main", {}).get("temp"),
                "humidity": weather.get("main", {}).get("humidity")
            })

        except Exception:
            results.append({
                "city": city,
                "risk_level": "UNAVAILABLE",
                "error": "Current data could not be fetched"
            })

    return jsonify({
        "source": "OpenWeather Current Weather and Air Pollution APIs",
        "updated_at": datetime.now().astimezone().isoformat(),
        "data": results
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "ok",
        "data_file_exists": os.path.exists(DATA_FILE),
        "api_key_file_exists": os.path.exists(API_KEY_FILE)
    })


if __name__ == "__main__":
    print("Serving future predictions and current conditions")
    print("Future predictions: http://localhost:5000/latest  (from the cloud, laptop file as backup)")
    print("Current conditions: http://localhost:5000/current")
    app.run(host="0.0.0.0", port=5000, debug=False)
