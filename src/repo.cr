module Crystal2Nix
  class RepoBuilder
    def self.build(name : String, shard : Shard, format : UInt8) : Repo
      case
      when shard.fossil then RepoFossil.new(name, shard, format)
      when shard.git    then RepoGit.new(name, shard, format)
      when shard.hg     then RepoHg.new(name, shard, format)
      else
        raise ArgumentError.new "Unknown repository type:\n#{shard.inspect}"
      end
    end
  end

  abstract class Repo
    @fetcher : String = ""
    @hash : String?
    @key : String = ""
    @name : String
    @rev : String
    @url : URI
    getter args : Array(String) = [] of String
    getter cmd : String = ""

    def initialize(@name : String, entry : Shard, @format : UInt8)
      @url = URI.parse(entry.url).normalize
      @rev = if entry.version =~ /^(?<version>.+)\+(git|hg)\.commit\.(?<rev>.+)$/
               $~["rev"]
             else
               "v#{entry.version}"
             end
    end

    abstract def parse(io : IO::FileDescriptor)

    def url : String
      @url.to_s
    end

    def to_nix : String
      String.build do |s|
        s << %(  #{@name} = {)
        s << %(    url = "#{url}";)
        s << %(    rev = "#{@rev}";)
        s << %(    #{
  @key
} = "#{@hash}";)
        s << %(    fetcher = "#{@fetcher}";) if @format >= 2
        s << %(  })
      end
    end

    def valid?
      !(name.nil? || rev.nil? || hash.nil?)
    end
  end

  class RepoFossil < Repo
    def initialize(name : String, shard : Shard, format : UInt8)
      super(name, shard, format)
      @cmd = "nix-prefetch-git"
      @key = "hash"
      @fetcher = "fetchfossil"
      @args = [@fetcher, "--url", url, "--rev", @rev]
    end

    def parse(io : IO::FileDescriptor)
      @hash = io.gets
    end
  end

  class RepoGit < Repo
    def initialize(name : String, shard : Shard, format : UInt8)
      super(name, shard, format)
      @cmd = "nix-prefetch"
      @key = "hash"
      @fetcher = "fetchgit"
      @args = ["--no-deepClone", "--url", url, "--rev", @rev]
    end

    def parse(io : IO::FileDescriptor)
      # @hash = GitJSON.from_json(io).hash
      json = GitJSON.from_json(io)
      @hash = json.hash
      pp json
    end
  end

  class RepoHg < Repo
    def initialize(name : String, shard : Shard, format : UInt8)
      super(name, shard, format)
      @cmd = "nurl"
      @key = "sha256"
      @fetcher = "fetchhg"
      @args = [@fetcher, "--url", url, "--rev", @rev]
    end

    def parse(io : IO::FileDescriptor)
      @hash = io.gets
    end
  end
end
