# Tenfold SRE Eval

© Evin Callahan

# Quickstart

To get up and running quickly with this service, run the following:

```
$ docker run -it --rm -v $(pwd)/app:/usr/src/app -p 1234:1234/udp gaieges/sreeval
```

# Building locally

```bash
$ docker build -t gaieges/sreeval app
```

# Using the service

```bash
$ echo -n  '[17/06/2016 12:30] Fun message here' | nc -u 127.0.0.1 1234
```


# Deploying

- Ensure that you have proper credentials for AWS in your env vars: either `AWS_PROFILE` or (`AWS_ACCESS_KEY_ID`+`AWS_SECRET_ACCESS_KEY`)
- Ensure you have the aws cli installed: `pip install awscli`
