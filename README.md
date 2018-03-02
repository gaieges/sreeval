# Tenfold SRE Eval

© Evin Callahan

# Quickstart

```bash
$ docker build -t sreeval app
$ docker run -it --rm -d -v $(pwd)/app:/usr/src/app -p 1234:1234/udp sreeval
```

# Using the service

```bash
$ echo -n  '[17/06/2016 12:30] Time to leave' | nc -u 127.0.0.1 1234
```
