import Config

config :logger, level: :debug

config :blitzurgist, :match_api_base_url, "localhost:8081/matches"
config :blitzurgist, :summoner_api_base_url, "localhost:8081/summoners"
config :blitzurgist, :spell_caster, Blitzurgist.MockSpell
