---
date: '2024-11-29T09:53:42+02:00' # date in which the content is created - defaults to "today"
title: 'WebScrappers on Flask'
draft: false # set to "true" if you want to hide the content

##link: "https://www.adrianmoreno.info" # optional URL to link the logo to

#params:
#    button:
#        icon: "icon-arrow-right"
#        btnText: "Case Study"
#        URL: "https://www.adrianmoreno.info"
#    image:
#        x: "images/works/robo-advisor.jpg"
#        _2x: "images/works/robo-advisor@2x.jpg"


## The content is used for the description of the project
---

## Web Scrapers on Flask - Part 1

### Introduction

Recently, I faced a challenge to help a friend who is searching for an apartment in Belgrade. The requirements were strict: a limited budget, a specific neighborhood, and minimal time for searching. Manually monitoring dozens of aggregator websites was clearly inefficient. The solution became obvious: automation.

I decided to create a project that gathers all relevant listings from multiple sources and presents them in a convenient format. This would allow my friend to focus on choosing an apartment rather than endlessly searching for one.

---

### Project Structure

The main idea of the project is to create a "black box" that regularly crawls aggregator websites, filters listings, and provides them in a structured format. At this stage, the project consists of the following key components:

```shell
.
├── app
│   ├── __init__.py          # Application initialization
│   ├── logging.py           # Logging configuration
│   ├── manager.py           # Main process management
│   ├── routes.py            # API interaction
│   ├── scheduler.py         # Task scheduler
│   ├── scrapers             # Modules for working with specific websites
│   │   ├── base_scraper.py  # Base class
│   │   ├── 4zida.py         # Scraper for 4zida
│   │   ├── cityexpert.py    # Scraper for CityExpert
│   │   ├── halooglasi.py    # Scraper for Halo Oglasi
│   │   ├── nekretnine.py    # Scraper for Nekretnine
│   │   └── sasomange.py     # Scraper for Sasomange
│   └── version.py           # Application version
├── config.py                # Configuration
├── Dockerfile               # Docker image description
└── requirements.txt         # Dependencies
```

This modular approach simplifies adding new features and streamlines further development.

---

### Scraper Implementation

Each scraper module is responsible for collecting and processing data from a specific website. All scrapers inherit from the base class `base_scraper.py`, which defines a unified interface for operation:

- **Data Collection**: Defines how to fetch HTML pages from the website.
- **Filtering**: Implements the logic to select relevant listings.

Example:

```python
# scrapers/base_scraper.py
class BaseScraper:
    def __init__(self, url):
        self.url = url

    def fetch_data(self):
        raise NotImplementedError("Subclasses must implement this method")

    def filter_data(self, data):
        raise NotImplementedError("Subclasses must implement this method")
```

Each specific scraper overrides these methods based on the website's structure.

! DO NOT USE INTERNAL API'S OF SITES WITHOUT PERMISSIONS !

---

### Future Development

At this stage, the project focuses on data collection. Future plans include:

1. **Adding data processing modules**:
   - Sending notifications about new offers via a Telegram bot.

2. **System optimization**:
   - Configuring fault tolerance and caching.
   - Add monitoring

3. **Integrating additional features**:
   - Custom filters for users.
   - Visualizing data through a dashboard.

---

The project has already proven its usefulness, saving hours of searching and providing a convenient way to analyze listings. The next step is to make it even more user-friendly and functional.

---

### Useful Links

1. [Flask Documentation](https://flask.palletsprojects.com/en/2.3.x/)
2. [Flask-APScheduler](https://pypi.org/project/Flask-APScheduler/)
3. [Dockerizing Flask Apps](https://testdriven.io/blog/dockerizing-flask-with-postgres-gunicorn-and-nginx/)
