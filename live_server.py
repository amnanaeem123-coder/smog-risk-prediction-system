"""
Live data server for the Smog Risk Prediction System.

What it does:
    The forecast script writes latest_risk.json.
    This server reads that file EVERY time the app asks,
    so the app always gets the newest predictions
    without restarting anything.

How to run:
    pip install flask flask-cors
    python live_server.py

Then open http://localhost:5000/latest in a browser to check.
"""

import json
import os

from flask import Flask, jsonify
from flask_cors import CORS

# Change this path if your forecast script saves the file somewhere else.
DATA_FILE = r"C:\Users\Admin\Desktop\smog-risk-prediction-system\assets\data\latest_risk.json"

app = Flask(__name__)
CORS(app)  # Allows the Flutter web app (different port) to call this server.


@app.route("/latest")
def latest():
    if not os.path.exists(DATA_FILE):
        return jsonify({"error": f"File not found: {DATA_FILE}"}), 404

    try:
        with open(DATA_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
    except json.JSONDecodeError:
        # Happens if the forecast script is in the middle of writing the file.
        return jsonify({"error": "File is being updated, try again"}), 503

    return jsonify(data)


@app.route("/health")
def health():
    return jsonify({"status": "ok", "data_file_exists": os.path.exists(DATA_FILE)})


if __name__ == "__main__":
    print(f"Serving predictions from: {DATA_FILE}")
    print("Open http://localhost:5000/latest to check")
    app.run(host="0.0.0.0", port=5000, debug=False)
