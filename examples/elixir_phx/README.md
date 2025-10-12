# ElixirPhx

## Dependecies

- Docker
- watch

`cd examples/elixir_phx`

## Local Startup

Start psql

```bash
./run.sh
```

Now you can visit [`http://localhost:4000/rolldice`](http://localhost:4000/rolldice) from your browser

## Generate Traffic

```bash
ab -n 100 -c 5 http://127.0.0.1:4000/rolldice
```
