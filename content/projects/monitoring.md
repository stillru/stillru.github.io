---
date: '2024-12-04T19:00:00+02:00'
title: 'Monitoring for services'
draft: true
---

# Monitoring and Deployment - Part 4

In previous parts [\[1\]](/projects/scrapers) [\[2\]](/projects/databus/) [\[3\]](/projects/telegrambot) I describe process of development microservises. I have intentionally made our services unready for monitoring through any monitoring system. It is time to fix that.

### Monitoring Flask Applications

Flask have module to create monitoring endpoint for Prometheus - `prometheus_flask_exporter`. [Github](https://github.com/rycus86/prometheus_flask_exporter), [Pypi](https://pypi.org/project/prometheus-flask-exporter/) of project.

According documentation, lets modify our applications:

``` python {linenos=table,hl_lines=[4,9,18]}
import logging

from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

from app.log import setup_logging
from app.scheduler import scheduler

metrics = PrometheusMetrics.for_app_factory()
setup_logging()

logger = logging.getLogger("main")


def create_app():
    app = Flask(__name__)
    app.config.from_object("config.Config")
    metrics.init_app(app)

    from app.routes import main_bp

    app.register_blueprint(main_bp)

    scheduler.init_app(app)
    logger.info("Register scheduler...")
    scheduler.start()

    return app
```
