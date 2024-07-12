module Crystal2Nix
  SHARDS_NIX = "shards.nix"

  class Worker
    def initialize(@lock_file : String, @debug : Bool, @format : UInt8)
    end

    def run
      File.open SHARDS_NIX, "w+" do |file|
        file.puts %({)
        ShardLock.from_yaml(File.read(@lock_file)).shards.each do |name, shard|
          error "Invalid shard" unless shard.valid?
          repo = RepoBuilder.build name, shard, @format
          error "Unable to parse repository entry" if repo.nil?

          Process.run(repo.cmd, args: repo.args) do |x|
            x.error.each_line { |e| puts e } if @debug
            repo.parse x.output
          end

          file.puts repo.to_nix
        end
        file.puts %(})
      end
    end

    def error(msg)
      STDERR.puts msg
      exit 1
    end
  end
end
