# Flu

## Start up

* By default, Flu connects a queue automatically.  To disable this behaviour, set `DISABLE_FLU_AUTO_CONNECT` to `false`

## Execute tests

```
  $ docker build . -t flu:test
  $ docker run -v ./:/usr/src/app/ flu:test rspec spec
```
