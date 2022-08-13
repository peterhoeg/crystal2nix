CRFLAGS = -Dpreview_mt

BIN = bin/crystal2nix
YAML = shard.yml
LOCK = shard.lock
NIX = shards.nix
META = meta.json

SRCS = $(shell fd --glob '*.cr' src)

default: bin/crystal2nix

bin/crystal2nix: $(META) $(SRCS)
	@shards build $(CRFLAGS)

$(META): $(YAML) Makefile
	@yaml2json $(YAML) | jq > $@

$(LOCK): $(YAML)
	@shards install

$(NIX): $(LOCK) $(BIN)
	@$(BIN)
