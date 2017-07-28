# 256

A Telegram bot for a groupchat of 256 people where you can pay to purchase a spot from a user already in the chat.

## Setup

Start by creating your bot and groupchat. Write down the API token and your groupchat's ID.

```
$ sqlite3 256.db < schema.sql
$ echo $MY_BOT_API_TOKEN > bot.token
$ echo $MY_GROUP_ID > group.id
$ ruby bot.rb
```

Add your bot to the group then leave and rejoin.
