import subprocess
from flask import Flask, request, jsonify
from functools import wraps
from dotenv import load_dotenv
import os
import requests

load_dotenv()

app = Flask(__name__)
API_TOKEN = os.getenv("API_TOKEN")
DEVICE = os.getenv("DEVICE")

def token_required(f):
    """Decorator to require API token authentication."""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        if token != f"Bearer {API_TOKEN}":
            return jsonify({"error": "Unauthorized"}), 401
        return f(*args, **kwargs)
    return decorated

def send_webhook_status(status: str, callback_url: str) -> None:
    """Send a status update to Home Assistant webhook."""
    if not callback_url:
        return
    payload = {"status": status}
    try:
        response = requests.post(callback_url, json=payload, timeout=10)
        response.raise_for_status()  # Raise an exception if the HTTP request failed
        print(f"Request to callback url finished with status: {status}")
    except requests.RequestException as e:
        print(f"Failed to send callback request: {e}")

@app.route('/webhook', methods=['POST'])
@token_required
def webhook():
    """Trigger the scan process and notify Home Assistant."""
    data = request.get_json()
    print("Received:", data)

    callback_url = data.get("callback_url", None)  # You could use this for a custom callback logic

    # Notify Home Assistant that the scan is starting
    send_webhook_status("running", callback_url)

    # Simulate scan process (e.g., call a shell script to run the scan)
    try:
        # Get the current script directory (where app.py is located)
        script_dir = os.path.dirname(os.path.abspath(__file__))

        # Construct the full path to the shell script
        shell_script_path = os.path.join(script_dir, 'scan_adf_to_pdf.sh')

        # Run the shell script with subprocess
        result = subprocess.run([shell_script_path, DEVICE], capture_output=True, text=True, check=True)
        scan_output = result.stdout

        # After successful scan, notify Home Assistant
        send_webhook_status("success", callback_url)
    except subprocess.CalledProcessError as e:
        scan_output = e.stderr
        # If the scan fails, notify Home Assistant
        send_webhook_status("error", callback_url)

    # Return scan result or error message to the client
    return jsonify({
        "message": "Scan completed",
        "output": scan_output
    }), 200

@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "ok"})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5050)
