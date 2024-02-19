from flask import Flask, request, jsonify
import os

app = Flask(__name__)

EXPECTED_API_KEY = os.environ.get('EXPECTED_API_KEY')

@app.route('/api/<string:service_name>/v<int:major_version>/DevOps', methods=['POST'])
def devops_endpoint(service_name, major_version):
    api_key = request.headers.get('X-Parse-REST-API-Key')
    if api_key != EXPECTED_API_KEY:
        return jsonify({"message": "Error: Provide correct X-Parse-REST-API-Key HTTP Header, and message/to/from/timeToLifeSec in your request payload"}), 401

    data = request.json
    if not data or 'to' not in data or 'from' not in data:
        return jsonify({"service_name": service_name, "major_version": major_version, "message": "Error: Missing required fields in the request payload"}), 400

    sender_name = data['from']
    receiver_name = data['to']

    response_message = f"Hello {sender_name}, your message will be sent."
    return jsonify({"service_name": service_name, "major_version": major_version, "message": response_message})

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"message": f"This app works supports only POST /api/<string:service_name>/v<int:major_version>/DevOps passing a valid X-Parse-REST-API-Key HTTP header. Received {request.method} {request.url} which I am not prepared to handle"}), 200

# Catch-all for unhandled paths, providing a JSON response
@app.errorhandler(404)
def handle_404(e):
    return jsonify({"message": f"This app works supports only POST /api/<string:service_name>/v<int:major_version>/DevOps passing a valid X-Parse-REST-API-Key HTTP header. Received {request.method} {request.url} which I am not prepared to handle"}), 200

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=8080)

