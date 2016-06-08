# TP 3: Chatroom with actors

## Requirements
[Link](https://docs.google.com/document/d/1KiFR3stOFVJqpOnEU9NCCyhONzbkD8aBWRjRbnax_Us/edit)

## Running
To start the process, do it with `iex`

```bash
iex start.ex
```

## TODOS
* Avoid duplicate code!
* Add the concept of "Global Message ID", which is a unique ID generated for each message in the IRC. With this one, the receptor should only notify with the `global_message_id` and the IRC will know which message was and who send it.