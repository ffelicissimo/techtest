from __future__ import print_function

import os
import sys
import redis

from flask import Flask
from flask import jsonify


app = Flask(__name__)
app.redis = redis.StrictRedis(host=os.getenv('REDIS_HOST', 'localhost'), socket_timeout=5)

@app.route('/set', methods=['POST'])
def set_value():
    try:
        app.redis.incr('total')
    except redis.ConnectionError as e:
        return jsonify({"status": "redis connection error"})
    else:
        return jsonify({"status": "ok"})

@app.route('/get')
def get_value():
    try:
        data = app.redis.get('total')
    except redis.ConnectionError as e:
        return jsonify({"status": "redis connection error"})
    else:
        return jsonify({"status": "ok", "data": data})


if __name__ == "__main__":
    env = os.getenv('ENV', 'production')
    if env == 'production':
        app.run(host='0.0.0.0')
    elif env == 'development':
        app.run(host='0.0.0.0', port=6000, debug=True)
    else:
        print("ERROR: env {} not supported".format(env))
        sys.exit(1)
