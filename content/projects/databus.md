---
title: Flask databus application
date: '2024-12-02T14:10:00+02:00'
---
Here’s the English translation of the article:

---
## Databus for Scrapers – Part 2

### Introduction

In the first part, we discussed a project that automates data collection from listing websites using modular web scrapers in Flask. Now, we’ll add a centralized data exchange mechanism — the **databus**.

Instead of having scrapers interact directly with end consumers (such as a Telegram bot or a dashboard), we use **RabbitMQ** as a message broker and **Redis** to prevent duplicate data. This approach ensures scalability, fault tolerance, and ease of extension.

---

### Databus Implementation

#### Overview

Our system consists of two key components:
1. **RabbitMQ** — a centralized message broker for data exchange.
2. **Redis** — a cache for checking the uniqueness of data before publishing.

The Flask application provides two API endpoints:
- `/add` — adds data to the queue if it is unique.
- `/fetch` — retrieves data from the queue for processing.

---

### Code

**`app.py`** — Flask application:

```python
import pika
import json
import hashlib
from flask import Flask, request, jsonify
import redis
import logging

log = logging.getLogger(__name__)

def create_app():
    app = Flask(__name__)

    # RabbitMQ settings
    RABBITMQ_HOST = 'rabbitmq'
    QUEUE_NAME = 'Apartment_ads'

    # Redis settings
    REDIS_HOST = 'redis'
    REDIS_PORT = 6379
    REDIS_DB = 0

    redis_client = redis.StrictRedis(
        host=REDIS_HOST, port=REDIS_PORT, db=REDIS_DB, decode_responses=True
    )
    log.info("Configure redis connection")

    def get_channel():
        connection = pika.BlockingConnection(
            pika.ConnectionParameters(host=RABBITMQ_HOST)
        )
        channel = connection.channel()
        channel.queue_declare(queue=QUEUE_NAME, durable=True)
        log.info("Connected to rabbitmq")
        return channel, connection

    @app.route('/add', methods=['POST'])
    def add_data():
        if not request.json:
            return jsonify({'error': 'Invalid JSON format'}), 400

        if isinstance(request.json, list):
            return jsonify({'error': 'JSON object expected, got list'}), 400

        data = request.json
        if not data:
            return jsonify({'error': 'Content is required'}), 400

        data_hash = hashlib.sha256(json.dumps(data).encode()).hexdigest()

        if redis_client.exists(data_hash):
            return jsonify({'error': 'Duplicate data'}), 409

        TWO_WEEKS_IN_SECONDS = 14 * 24 * 60 * 60  # 1209600 seconds
        redis_client.set(data_hash, 1, ex=TWO_WEEKS_IN_SECONDS)

        channel, connection = get_channel()
        channel.basic_publish(
            exchange='',
            routing_key=QUEUE_NAME,
            body=json.dumps({'content': data}),
            properties=pika.BasicProperties(delivery_mode=2),
        )
        connection.close()
        return jsonify({'message': 'Data added successfully'}), 201

    @app.route('/fetch', methods=['GET'])
    def fetch_data():
        channel, connection = get_channel()
        method_frame, header_frame, body = channel.basic_get(
            queue=QUEUE_NAME, auto_ack=True
        )

        if not method_frame:
            connection.close()
            return jsonify({'message': 'No data available'}), 200

        data = json.loads(body)
        connection.close()
        return jsonify({'data': data}), 200

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host="0.0.0.0", port=5001)
```

---

### Key Features

1. **Uniqueness Check with Redis**:
   Each entry is hashed using SHA-256 and stored in Redis with a TTL (14 days). This prevents adding duplicate data.

2. **Message Queue with RabbitMQ**:
   Data is sent to the `Apartment_ads` queue using persistent storage (`durable=True`), which protects it from loss during broker restarts.

3. **Simple Interaction via API**:
   - `/add`: Accepts JSON data, checks for uniqueness, and adds it to the queue.
   - `/fetch`: Retrieves data from the queue for processing.

---

### Testing

#### Running the Service

1. **Setting up RabbitMQ and Redis with Docker**:

```bash
docker network create databus_network
docker run -d --name rabbitmq --network databus_network -p 5672:5672 -p 15672:15672 rabbitmq:3-management
docker run -d --name redis --network databus_network -p 6379:6379 redis
```

2. **Starting the Flask Application**:

```bash
python app.py
```

#### Testing the Functionality

1. **Adding Data**:

```bash
curl -X POST -H "Content-Type: application/json" -d '{"ad_id": 123, "title": "Apartment in Belgrade"}' http://127.0.0.1:5001/add
```

2. **Fetching Data**:

```bash
curl -X GET http://127.0.0.1:5001/fetch
```

---

### Conclusion

The databus service adds a layer of robustness and scalability to the scraper project. By using RabbitMQ and Redis, we ensure reliable message delivery, while Flask provides a convenient API for interacting with the system.

In the next part, we will add notifications via a Telegram bot and discuss service monitoring.
