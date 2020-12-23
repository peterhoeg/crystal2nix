require "json_mapping"
require "option_parser"

module Crystal2Nix
  class PrefetchJSON
    JSON.mapping(sha256: String)
  end

  class Cli
    SHARD_LOCK     = "shard.lock"
    SHARDS_NIX     = "shards.nix"
    SUPPORTED_KEYS = %w[git github]

    @lock_file : String

    def initialize
      @lock_file = SHARD_LOCK

      OptionParser.parse do |parser|
        parser.banner = "Usage: crystal2nix [arguments]"
        parser.on("-f", "--file", "Use this file instead of shard.lock") do |f|
          @lock_file = f
        end
        parser.on("-v", "--version", "Show the version") do
          STDERR.puts VERSION
          exit
        end
        parser.on("-h", "--help", "Show this help") do
          STDERR.puts parser
          exit
        end
        parser.invalid_option do |flag|
          STDERR.puts "ERROR: #{flag} is not a valid option."
          STDERR.puts parser
          exit 1
        end
      end

      unless File.exists? @lock_file
        STDERR.puts "ERROR: #{@lock_file} not found"
        exit 1
      end
    end

    def run
      File.open SHARDS_NIX, "w+" do |file|
        file.puts %({)
        ShardList.new(@lock_file).shards.each do |key, value|
          url = nil
          SUPPORTED_KEYS.each do |k|
            url = RepoUrl.new(k, value[k]) if value.has_key?(k)
          end
          if url.nil?
            STDERR.puts "Unable to parse repository entry"
            exit 1
          end
          rev = value["version"]? ? "v#{value["version"]}" : value["commit"]
          sha256 = ""
          args = ["--url", url.to_s, "--rev", rev]
          Process.run("nix-prefetch-git", args: args) do |x|
            x.error.each_line { |e| puts e }
            sha256 = PrefetchJSON.from_json(x.output).sha256
          end

          file.puts %(  #{key} = {)
          file.puts %(    owner = "#{url.owner}";)
          file.puts %(    repo = "#{url.repo}";)
          file.puts %(    rev = "#{rev}";)
          file.puts %(    sha256 = "#{sha256}";)
          file.puts %(  };)
        end
        file.puts %(})
      end
    end
  end
end

Crystal2Nix::Cli.new.run
