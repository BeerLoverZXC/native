FROM ubuntu:latest

ENV DAEMON_NAME=gonatived \
HOME=/app \
DAEMON_HOME=/app/.gonative \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true \
MONIKER="Stake Shark" \
GO_VER="1.23.1" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}"

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && \
    apt-get install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool nano -y

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
    rm "go$GO_VER.linux-amd64.tar.gz" && \
    mkdir -p /app/go/bin /app/.gonative/cosmovisor/upgrades /app/.gonative/cosmovisor/genesis/bin

RUN wget -O /app/.gonative/cosmovisor/genesis/bin/gonative-v0.1.1.gz https://github.com/gonative-cc/gonative/releases/download/v0.1.1/gonative-v0.1.1-linux-amd64.gz && \
    cd /app/.gonative/cosmovisor/genesis/bin/ && \
    gunzip gonative-v0.1.1.gz && \
    mv gonative-v0.1.1 gonatived && \
    chmod +x gonatived

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN /app/.gonative/cosmovisor/genesis/bin/gonatived init "Stake Shark" --chain-id=native-t1 && \
sed -i.bak -e "s%^external_address = \"\"%external_address = \"$(wget -qO- eth0.me):26656\"%" /app/.gonative/config/config.toml && \
sed -i -e "s/prometheus = false/prometheus = true/" /app/.gonative/config/config.toml && \
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" /app/.gonative/config/config.toml && \
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.1untiv\"/;" /app/.gonative/config/app.toml && \
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 40/g' $HOME/.gonative/config/config.toml && \
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 10/g' /app/.gonative/config/config.toml && \
sed -i -e "s/^app-db-backend *=.*/app-db-backend = \"goleveldb\"/;" /app/.gonative/config/app.toml && \
sed -i -e "s/^db_backend *=.*/db_backend = \"pebbledb\"/" /app/.gonative/config/config.toml && \
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" /app/.gonative/config/app.toml && \
sed -i -e "s/^keep-recent *=.*/keep-recent = \"1000\"/" /app/.gonative/config/app.toml && \
sed -i -e "s/^interval *=.*/interval = \"10\"/" /app/.gonative/config/app.toml

RUN wget https://github.com/gonative-cc/network-docs/raw/refs/heads/master/genesis/genesis-testnet-1.json.gz && \
    gunzip genesis-testnet-1.json.gz && \
    mv genesis-testnet-1.json /app/.gonative/config/genesis.json && \
    wget -O /app/.gonative/config/addrbook.json https://server-4.stavr.tech/Testnet/Native/genesis.json

ENTRYPOINT ["/app/entrypoint.sh"]
