---
date: '2024-12-04T19:00:00+02:00'
title: 'Monitoring for services'
draft: false
---

## Monitoring and Deployment - Part 4

### Introduction

In previous parts [\[1\]](/projects/scrapers) [\[2\]](/projects/databus/) [\[3\]](/projects/telegrambot) , I described the development process for our microservices. Initially, I intentionally omitted monitoring capabilities.

Monitoring ensures system reliability, aids in debugging, and provides operational insights, making it crucial as our system scales.

Now, I’ll address that by integrating monitoring into our system.

## Monitoring Flask Applications

Prometheus is a powerful tool for collecting, querying, and visualizing metrics, making it an excellent choice for microservices monitoring.

Flask has a module to create monitoring endpoint for Prometheus - `prometheus_flask_exporter`. [Github](https://github.com/rycus86/prometheus_flask_exporter), [Pypi](https://pypi.org/project/prometheus-flask-exporter/) of project. This integration automatically tracks request durations, response statuses, and more, providing valuable insight into application performance.

According documentation, lets modify our applications:

``` python {linenos=table,hl_lines=[4,9,18],linenostart=1}
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

So, on line 4, I connect `prometheus_flask_exporter` to my main scraper application.

On line 9 I use `PrometheusMetrics.for_app_factory()` method to connect this exporter to project.

And on line 18 I actually initialize the metrics endpoint. Now my application have metrics on `/metrics` endpoint!

Let's modify another service - `databus`:

``` python {linenos=table,hl_lines=[4,6,18],linenostart=1}
import logging

from flask import Flask
from prometheus_flask_exporter import PrometheusMetrics

metrics = PrometheusMetrics.for_app_factory()

log = logging.getLogger(__name__)


def create_app():
    app = Flask(__name__)

    from app.routes import databus_bp

    app.register_blueprint(databus_bp)

    metrics.init_app(app)

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host="0.0.0.0", port=5001)
```

As you can see - I refactor `databus` project. Now all routes live in different file `routes.py` and initialized with blueprints.

As in `scrapers` microservice I make changes to bring metrics to project.

Now all our flask endpoints monitored.

But what about our internal processes, which don't belong Flask ecosystem? Scheduler, Redis, RabbitMQ & telegrambot?

## Monitoring internal processes

Let's make little refactoring:

 - Create new file `metrics.py`
 - Move import and initialization of metrics there

```python
from prometheus_flask_exporter import PrometheusMetrics

metrics = PrometheusMetrics.for_app_factory()
```
 - make custom metrics in manager.py for example:

```python {linenos=table,hl_lines=[3,11-18, 31, 38],linenostart=1}
import logging

from app.metrics import metrics
from app.scrapers.cityexpert import CityexpertScraper
from app.scrapers.halooglasi import HaloOglasiScraper
from app.scrapers.nekretnine import NekretnineScraper
from app.scrapers.sasomange import SasomangeScraper

logger = logging.getLogger("manager")

run_get_scrapers_counter = metrics.counter(
    "run_get_scrappers", "Number of times the get_scrapers function was executed"
)

run_configure_all_counter = metrics.counter(
    "run_configure_all_counter",
    "Number of times the configure_all function was executed",
)


class ScraperManager:
    def __init__(self):
        self.scrapers = [
            HaloOglasiScraper(),
            CityexpertScraper(),
            SasomangeScraper(),
            NekretnineScraper(),
        ]

    def get_scrapers(self):
        run_get_scrapers_counter.inc()
        return [
            {"name": scraper.name, "version": scraper.version}
            for scraper in self.scrapers
        ]

    def configure_all(self, config):
        run_configure_all_counter.inc()
        for scraper in self.scrapers:
            try:
                scraper.configure(config)
                logger.info(f"Configured {scraper.name} with {config}")
            except Exception as e:
                logger.warn(f"Error configuring {scraper.__class__.__name__}: {e}")

    def collect_all(self):
        results = []
        for scraper in self.scrapers:
            try:
                listings = scraper.scrape()
                results.extend(listings)
            except Exception as e:
                print(f"Error scraping {scraper.__class__.__name__}: {e}")
        return results

```

This is how we can export to Prometheus counter with data "How many times function is called". But more interesting and more useful - how many times was error in functions? Let's implement it:

 - On top of file lets add new counter:

``` python {linenos=table,linenostart=19}
error_count_configure_all = Counter(
    "error_configure_all", "How many times was error in functions", ["scraper"]
)
```

In this snippet I create counter for errors in for function `configure_all`. Additionaly I create label `scraper` to identify which scraper failed for detailed investigation in future.

 - Increment counter, when exception catched:

``` python {linenos=table,hl_lines=[8],linenostart=37}
    def configure_all(self, config):
        run_configure_all_counter.inc()
        for scraper in self.scrapers:
            try:
                scraper.configure(config)
                logger.info(f"Configured {scraper.name} with {config}")
            except Exception as e:
                error_count_configure_all.labels({scraper.__class__.__name__}).inc()
                logger.warn(f"Error configuring {scraper.__class__.__name__}: {e}")
```

Now I have custom counters for errors. It will help me in future faster identify module which have problems .

Time to bring Prometheus in stack to make it working.

## Prometheus

Let's start from creating `monitoring` directory:

``` shell
mkdir monitoring
cd monitoring
```

Next, I need write configuration file with targets for Prometheus:

``` yaml
# monitoring/prometheus.yaml
global:
  scrape_interval:     15s # Global scrape interval
  evaluation_interval: 15s # Rule evaluation interval

# Rule files for custom alerts
rule_files:
  # - "alerts.rules.yml"

# Scrape configurations
scrape_configs:
  # Prometheus monitoring itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Monitoring Flask API
  - job_name: 'flask-api'
    scrape_interval: 15s  # Align with the global scrape interval unless high frequency is needed
    metrics_path: /metrics # Specify metrics path if not default
    static_configs:
      - targets: ['localhost:5000']
    honor_labels: true
  - job_name: 'flask-databus'
    scrape_interval: 15s  # Align with the global scrape interval unless high frequency is needed
    metrics_path: /metrics # Specify metrics path if not default
    static_configs:
      - targets: ['localhost:5001']
    honor_labels: true
```
Step directory up and create docker compose file:

``` yaml
# docker-compose.yaml
version: "3.5"
services:
  prometheus:
    image: prom/prometheus:latest
    restart: unless-stopped
    container_name: prometheus
    ports:
      - 9090:9090
    volumes:
      - ./monitoring/prometheus.yaml:/etc/prometheus/prometheus.yml
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
```

Let's bring it up:

``` shell
docker-compose up
```

In separate terminal - run your services.

Provided configuration is for local testing and would require modifications for production (e.g., security, scaling).

## Conclusion

In this article, we added Prometheus monitoring to Flask microservices using `prometheus_flask_exporter`. We also set up custom counters for internal processes and deployed Prometheus using Docker Compose. With these metrics, we can now gain valuable insights into service performance and errors.

---


Next time I will combine all services in one docker-compose file and bring all this alive.

## References

1. [Monitoring Flask microservices with Prometheus](https://blog.viktoradam.net/2020/05/11/prometheus-flask-exporter/)
2. [Prometheus Client documentation](https://prometheus.github.io/client_python/)
