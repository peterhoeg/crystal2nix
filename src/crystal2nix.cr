require "json_mapping"
require "yaml_mapping"

require "./crystal2nix/cli"
require "./crystal2nix/repo_url"
require "./crystal2nix/shard"

module Crystal2Nix
  VERSION = "0.1.0"

  SHARD_LOCK     = "shard.lock"
  SHARDS_NIX     = "shards.nix"
  SUPPORTED_KEYS = %w[git github]
end
