require "yaml_mapping"

module Crystal2Nix
  alias ShardRecord = Tuple(String, Hash(String, String))

  class ShardLock
    YAML.mapping(
      version: Float32,
      shards: ShardRecord
    )
  end

  class Shard
    def initialize(shard : ShardRecord)
    end

    def rev
    end
  end

  class ShardList
    @shards : Array(Shard)

    def initialize(file : String)
      @shards = ShardLock.from_yaml(File.read(file)).shards.map { |s| Shard.new s }
    end
  end
end
