import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :blitzurgist, :magic_word, "RGAPI-a29943a1-7976-4df4-bba3-09755d189c60"

config :blitzurgist, :match_api_base_url, "api.riotgames.com/lol/match/v5/matches"
config :blitzurgist, :summoner_api_base_url, "api.riotgames.com/lol/summoner/v4/summoners"

config :blitzurgist, Sentinel,
  sentinel: Blitzurgist.Overseer,
  timeframe_max_observations: 0.8,
  timeframe_units: :seconds,
  timeframe: 1

import_config "#{config_env()}.exs"
