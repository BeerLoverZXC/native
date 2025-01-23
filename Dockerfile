FROM ubuntu:latest

ENV DAEMON_NAME=gonative \
HOME=/app \
DAEMON_HOME=/app/.gonative \
DAEMON_ALLOW_DOWNLOAD_BINARIES=false \
DAEMON_RESTART_AFTER_UPGRADE=true \
MONIKER="Stake Shark" \
GO_VER="1.23.1" \
PATH="/usr/local/go/bin:/app/go/bin:${PATH}" \
peers="2e2f0def6453e67a5d5872da7f73002caf55a010@195.3.221.110:52656,612e6279e528c3fadfe0bb9916fd5532bc9be2cd@164.132.247.253:56406,f2e45e48f55f649dee0e8dc4adfa445308ae8018@167.235.247.51:26656,a7577f50cdefd9a7a5e4a673278d9004df9b4bb4@103.219.169.97:56406,236946946eacbf6ab8a6f15c99dac1c80db6f8a5@65.108.203.61:52656,13b49060d7ae1375a04a8eaec8602920f47b5a55@37.142.120.99:27656,48bd9b42755de1a3039089c4cb66b9dd01561001@57.129.53.32:40656,0c2926cdac1e31e39ea137ec3438be6485fd58d7@116.202.85.179:10007,b80d0042f7096759ae6aada870b52edf0dcd74af@65.109.58.158:26056,f0e48f295e0d7c7d03943c82ac01bfc54969320b@78.46.185.199:26656,8eb8024d28b070d21844a90c7c2d34ef4b731365@193.34.213.77:15007,b5f52d67223c875947161ea9b3a95dbec30041cb@116.202.42.156:32107,5be5b41a6aef28a7779002f2af0989c7a7da5cfe@165.154.245.110:26656,b07e0482f43a2add3531e9aa7946609386b2e7e7@65.109.113.219:30656,6edabc54e76245af9f8f739303c788bfb23bd09a@95.216.12.106:24096,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@176.9.82.221:30656,d0e0d80be68cec942ad46b36419f0ba76d35d134@94.130.138.41:26444,be5b6092815df2e0b2c190b3deef8831159bb9a2@64.225.109.119:26656,49784fe6a1b812fd45f4ac7e5cf953c2a3630cef@136.243.17.170:38656,40cbf43553e7ee3507814e3110a749a7e638aa83@194.163.169.182:24656,1e9a3f3615ec98ea66c41b7e37a724889067bc05@193.24.209.155:12056,7567880ef17ce8488c55c3256c76809b37659cce@161.35.157.54:26656,d856c6c6f195b791c54c18407a8ad4391bd30b99@142.132.156.99:24096,2dacf537748388df80a927f6af6c4b976b7274cb@148.251.44.42:26656,2c1e6b6b54daa7646339fa9abede159519ca7cae@37.252.186.248:26656,fbc51b668eb84ae14d430a3db11a5d90fc30f318@65.108.13.154:52656,48d0fdcc642690ede0ad774f3ba4dce6e549b4db@142.132.215.124:26656,24d51644ea1a6b91bf745f6767a9079d4b35e3d2@37.27.202.188:26656"

WORKDIR /app

RUN apt-get update && apt-get upgrade -y && \
    apt-get install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool nano -y

RUN wget "https://golang.org/dl/go$GO_VER.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf "go$GO_VER.linux-amd64.tar.gz" && \
    rm "go$GO_VER.linux-amd64.tar.gz" && \
    mkdir -p /app/go/bin /app/.gonative/cosmovisor/upgrades /app/.gonative/cosmovisor/genesis/bin

RUN rm -rf gonative && \
    git clone https://github.com/gonative-cc/gonative && cd gonative && \
    git checkout v0.1.1 && \
    make build && \
    chmod +x /app/gonative/out/gonative && \
    mv /app/gonative/out/gonative /app/.gonative/cosmovisor/genesis/bin/gonative

RUN go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

RUN /app/.gonative/cosmovisor/genesis/bin/gonative init "Stake Shark" --chain-id=native-t1 && \
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
sed -i -e "s/^interval *=.*/interval = \"10\"/" /app/.gonative/config/app.toml && \
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.gonative/config/config.toml

RUN wget https://github.com/gonative-cc/network-docs/raw/refs/heads/master/genesis/genesis-testnet-1.json.gz && \
    gunzip genesis-testnet-1.json.gz && \
    mv genesis-testnet-1.json /app/.gonative/config/genesis.json && \
    wget -O /app/.gonative/config/addrbook.json https://server-4.stavr.tech/Testnet/Native/genesis.json

ENTRYPOINT ["/app/entrypoint.sh"]
