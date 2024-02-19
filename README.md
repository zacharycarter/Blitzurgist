# Blitzurgist

### League of Legends Statistics Thaumaturgist

## Installation
1. Visit the [Riot Developer Portal](https://developer.riotgames.com/) and create an account.
2. Refresh your API key if necessary, and copy it to your clipboard.
3. Set the `RIOT_API_KEY` environment variable from your clipboard.
```console
dev@blitz:~$ export RIOT_API_KEY=<YOUR_API_KEY_HERE>
```
4. Clone this repository.
```console
dev@blitz:~$ git clone git@github.com:zacharycarter/blitzurgist.git && cd blitzurgist
```
4. Install mix dependencies.
```console
dev@blitz:~/blitzurgist$ mix deps.get
```

## Running unit test

```console
dev@blitz:~$ MIX_ENV=test mix test test/invoker_test.exs
```

## Environment Variables

To run this project in `prod`, the following environment variable must be set for your shell session. If running in `dev` the environment variable can be set or the value assigned to `config :blitzurgist, :magic_word` in `config.exs` can be updated.

`RIOT_API_KEY`


## Usage/Examples
#### Summon a summoner
```console
dev@blitz:~/blitzurgist$ MIX_ENV=prod iex -S mix
Erlang/OTP 26 [erts-14.2.2] [source] [64-bit] [smp:16:16] [ds:16:16:10] [async-threads:1] [jit:ns]

Interactive Elixir (1.16.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)> Blitzurgist.summon("blitz", "NA1")
["bruhexe12", "evrynyan", "celestiae", "kmadkilla", "oxymoronic", "kazakhstan",
 "632146p", "enough_said", "kirkbusch", "worsethanaminion", "baw", "eg_ppmd",
 "serec", "skysoap", "claireinsync", "flealip", "covidhabits", "fineapril",
 "supportive_main", "h1t_the_turret", "sir_robert_saget", "206", "aœ_ªssin",
 "obi_meow_catnobi", "donald_1v9_trump", "pikamew", "xchengood", "rift_heraid",
 "tribadism", "breakfast8868", "iixin5aniityxii", "vorgue", "ketaketish",
 "on_jahseh", "lezbionage", "charles_kean", "lady_maría", "lite_work",
 "mushygas22", "lorddinkleman"]
iex(2)>
```

## Features

- Supplied with a `summoner_name` and `region`, Blitzurgist will fetch all summoners the provided summoner has played with during the last five matches.
- The list of summoner names is returned to the caller in the following format: `[summoner_name_1, summoner_name_2, ...]`
- Once a summoner is fetched, it is monitored for new matches every minute, for the  next hour.
- When a summoner completes a new match, the match's id is logged to the console, ex: `Summoner <summoner name> completed match <match id>`
