module Crystal2Nix
  # nix-prefetch-git returns JSON
  class GitJSON
    include JSON::Serializable

    # we are only interested in the hash
    property hash : String
  end

  # The contents of the shard.lock file
  class ShardLock
    include YAML::Serializable

    property version : Float32
    property shards : Hash(String, Shard)
  end

  # Each shard entry in shard.lock
  class Shard
    include YAML::Serializable

    property git : String?
    property hg : String?
    property fossil : String?

    property version : String

    def url : String
      return fossil.to_s unless fossil.nil?
      return git.to_s unless git.nil?
      return hg.to_s unless hg.nil?

      ""
    end

    # Although we don't support fossil, the entry itself is valid with a fossil source
    def valid? : Bool
      !fossil.nil? || !git.nil? || !hg.nil?
    end
  end
end
