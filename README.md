# Sundog

Sundog is a fun little app that monitors that big ball of fire in the sky using the Datadog cloud monitoring service.

Once set up, you can watch graphs of the sun's activity, set up monitors to alert you to solar flares in progress, etc.

## Wait, what?  Why?

I like the sun.  I like Elixir.

This is a great chance to monitor the sun and teach myself about Elixir design, testing, supervision, etc.

## Stats logged

### `sundog.goes.xray`

Solar X-ray flux data.  This is retrieved from two URLs (primary/secondary) and aggregated into a single Datadog stat for ease of graphing.

Tags:

* `primary` (true/false): Whether the data was retrieved from the primary dataset, or the secondary one.
  * Generally, it seems the newer satellite is the primary.
* Tag `source` (e.g. "GOES-15"): What satellite the data is from.
* Tag `wavelength` (short/long): What X-ray wavelength is being collected.
  * At the time of writing, `short` is 0.5 to 4.0 Ångströms (tenths of a nanometre), and `long` is 1.0 to 8.0 Ångströms.
  * Thus, there's significant overlap between the two.

## Dependencies

### Erlang and Elixir

Sundog is written in Elixir, which is a language running on top of Erlang.  You'll need both of these to make it work.

If you follow the [Elixir install instructions](https://elixir-lang.org/install.html), you should end up with both of these.  Most of the automatic (i.e. packaged) installs will automatically install Erlang for you.  The manual install methods include instructions on installing Erlang.

If you're installing the Debian/Ubuntu packages, make sure to include `erlang-dev` (the Erlang headers) and `erlang-parsetools` (some development tools for parsing).  These are needed by Sundog's dependencies.

Sundog was written in Elixir 1.5 running on Erlang 20.  You can try running it under older versions, but there's no guarantees it'll work.

## Installation

### Installing

1. Ensure dependencies are installed; see above.
2. Run `mix deps.get` to fetch the libraries Sundog needs.
3. (optional) Edit `config/datadog.example.exs`, add your git credentials, and save it as `config/datadog.exs`.
  * Alternatively, you can supply credentials via environment variables: `DD_API_KEY`, `DD_APPLICATION_KEY`, and `DD_HOST`.

Now, you have two options on how to run Sundog.

### Running on the spot

For beginners, I recommend just running `mix run --no-halt`.  This will launch Sundog right here and now, and it will start fetching results and submitting them to Datadog.  (To exit the server, press control-C twice.)

If you didn't put your Datadog credentials in `config/datadog.exs`, you'll need to supply them via environment variables.  For example:

```
DD_API_KEY="a7318e3aa62fe0b9655c66d67010ae46" DD_APPLICATION_KEY="1f879eff3eb0c6eb9879010385c0293bda8db611" DD_HOST="hostname.exmaple.org" mix run --no-halt
```

### Deploying

The above method should be enough to get you going.  However, if you're an experienced Elixir developer and/or sysadmin, and you want more flexibility, you can try deploying instead.

This is a more complex topic, and is covered in [a separate document](docs/deploying.md).

## Legal stuff

Copyright © 2017, Adrian Irving-Beer.

Sundog is released under the [Apache 2 License](LICENSE) and is provided with **no warranty**.  I don't expect it's possible to exploit Sundog in any way, but there's always the possibility of a bug in Elixir or the HTTPoison library.  I make every effort to write secure code, but you're still using Sundog at your own risk.
