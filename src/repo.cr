module Crystal2Nix
  enum RepoKind
    Git
    Mercurial
    Fossil
  end

  class Repo
    @url : URI
    getter kind : RepoKind
    getter rev : String

    def initialize(entry : Shard)
      @url = URI.parse(entry.url).normalize
      @kind = case
              when entry.fossil then RepoKind::Fossil
              when entry.git    then RepoKind::Git
              when entry.hg     then RepoKind::Mercurial
              else
                raise ArgumentError.new "Unknown repository type:\n#{entry.inspect}"
              end
      @rev = if entry.version =~ /^(?<version>.+)\+(git|hg)\.commit\.(?<rev>.+)$/
               $~["rev"]
             else
               "v#{entry.version}"
             end
    end

    def cmd : String
      case @kind
      in RepoKind::Fossil    then "nix-prefetch"
      in RepoKind::Git       then "nix-prefetch-git"
      in RepoKind::Mercurial then "nix-prefetch-hg"
      end
    end

    def args
      case @kind
      in RepoKind::Fossil    then ["fetchfossil", "--url", url, "--rev", rev]
      in RepoKind::Git       then ["--no-deepClone", "--url", url, "--rev", rev]
      in RepoKind::Mercurial then [url, rev]
      end
    end

    def key : String
      case @kind
      in RepoKind::Fossil    then "sha256"
      in RepoKind::Git       then "hash"
      in RepoKind::Mercurial then "sha256"
      end
    end

    def fetcher
      case @kind
      in RepoKind::Fossil    then "fetchfossil"
      in RepoKind::Git       then "fetchgit"
      in RepoKind::Mercurial then "fetchhg"
      end
    end

    def url : String
      @url.to_s
    end
  end
end
