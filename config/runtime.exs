import Config

if config_env() == :prod do
  config :blitzurgist,
         :magic_word,
         System.get_env("RIOT_API_KEY") ||
           raise("""
           environment variable RIOT_API_KEY must be set.
           """)
end
