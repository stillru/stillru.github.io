---
title: Creating a Telegram Bot for Publishing Updates
date: '2024-12-03T14:10:00+02:00'
draft: true
---
## How to use scraped data - Part 3

### Introduction

**This is the third article in a series about an automated monitoring and publishing project.**
If you missed the earlier parts:
- In the first article, I described the data collection process using web scraping.
- In the second article, I explained how to organize data exchange between microservices using a data bus.

Today, I will focus on creating a Telegram bot that publishes the collected data in a channel, providing a convenient interface for interaction.

---

## The Main Idea

My Telegram bot performs two main tasks:
1. Periodically fetches new messages from the data bus (in our case, an API provided by the *databus* service).
2. Publishes the fetched data in a Telegram channel, formatting it into a user-friendly message.

A key part of the implementation is breaking the logic into separate modules. This approach simplifies development, testing, and adding new features.

---

## Bot Architecture

The project is divided into the following components:

- **`main.py`**: Entry point for launching the bot.
- **`commands.py`**: Handles user commands (to be implemented in the future).
- **`cron.py`**: Manages background tasks, such as fetching data from the bus.
- **`metrics.py`**: Exports metrics for Prometheus (we'll add this in the next article).
- **`utils.py`**: Utility functions, such as logging and message formatting.
- **`config.py`**: Project configuration, including the bot token, data bus URL, and channel ID.

---

## Implementation Steps

### 1. Creating the Telegram Bot

I use the `python-telegram-bot` library to interact with the Telegram API. Below is the code for launching the bot (`main.py`):

```python
import asyncio
from telegram.ext import Application, CommandHandler
from bot.config import API_TOKEN, DATABUS_URL, CHANNEL_ID, FETCH_INTERVAL
from bot.commands import hello
from bot.cron import fetch_and_publish
from bot.utils import logger

def main():
    """
    Creates and starts the bot.
    """
    # Create the Telegram application
    app = Application.builder().token(API_TOKEN).build()

    # Add command handlers
    app.add_handler(CommandHandler("hello", hello))

    # Start the background task
    loop = asyncio.get_event_loop()
    loop.create_task(fetch_and_publish(app.bot, DATABUS_URL, CHANNEL_ID, FETCH_INTERVAL))

    # Start the bot
    logger.info("Bot started.")
    app.run_polling()

if __name__ == "__main__":
    main()
```

---

### 2. Implementing a Background Task

The background task fetches messages from the data bus and publishes them to the channel (`cron.py`):

```python
import asyncio
import aiohttp
from bot.utils import logger, format_message

async def fetch_and_publish(bot, databus_url, channel_id, interval=60):
    """
    Periodically fetches data from the databus and publishes it to the channel.
    """
    async with aiohttp.ClientSession() as session:
        while True:
            try:
                async with session.get(databus_url) as response:
                    if response.status == 200:
                        data = await response.json()
                        if "content" in data:
                            formatted_message = await format_message(data)
                            await bot.send_message(chat_id=channel_id, text=formatted_message, parse_mode="Markdown")
                            logger.info(f"Published message: {data}")
                        else:
                            logger.info("No valid content in response.")
                    else:
                        logger.error(f"Databus API returned status {response.status}")
            except Exception as e:
                logger.error(f"Error fetching data: {e}")
            await asyncio.sleep(interval)
```

---

### 3. Formatting the Message

Messages published by the bot must be clear and well-structured. I use Markdown for formatting (`utils.py`):

```python
async def format_message(data):
    """
    Formats JSON data into a readable Telegram message.
    """
    content = data.get("content", {})
    title = content.get("title", "No title")
    location = content.get("location", "Unknown location")
    price = content.get("price", "Price not specified")
    provider = content.get("provider", "Unknown source")
    link = content.get("link", "#")

    # Formatting the message
    message = (
        f"*{title}*\n"
        f"📍 *Location:* {location}\n"
        f"💰 *Price:* {price}\n"
        f"🛠️ *Source:* {provider}\n"
        f"[🔗 More details]({link})"
    )
    return message
```

---

### 4. Logging

I use the `logging` module for logging, which helps monitor the bot's operation. This is especially useful for debugging and monitoring (`utils.py`):

```python
import logging

# Logging setup
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)
```

---

## The Result

Now, the bot periodically fetches data from the data bus and publishes it in the channel in the following format:

```
#48274, Izdavanje, Stan, AVIV PARK, 400 EUR
📍 Location: Zvezdara, Beograd, Serbia
💰 Price: 400 €
🛠️ Source: Nekretnine Scraper
🔗 More details: https://www.nekretnine.rs/stambeni-objekti/stanovi/48274-izdavanje-stan-aviv-park-400-eur/NkyO6fr62eC/
```

---

## What's Next?

In the next article, I will integrate monitoring with Prometheus. This will allow me to track:
- The number of processed messages.
- Execution time for background tasks.
- Errors and failures in the bot's operation.
