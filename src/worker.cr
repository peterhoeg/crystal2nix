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
          repo = Repo.new shard
          error "Unable to parse repository entry" if repo.nil?

          hash = ""
          Process.run(repo.cmd, args: repo.args) do |x|
            x.error.each_line { |e| puts e } if @debug
            case repo.kind
            in RepoKind::Git
              hash = GitJSON.from_json(x.output).hash
            in RepoKind::Mercurial, RepoKind::Fossil
              hash = x.output.gets
            end
          end

          file.puts %(  #{name} = {)
          file.puts %(    url = "#{repo.url}";)
          file.puts %(    rev = "#{repo.rev}";)
          file.puts %(    #{repo.key} = "#{hash}";)
          file.puts %(    fetcher = "#{repo.fetcher}";) if @format >= 2
          file.puts %(  };)
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
