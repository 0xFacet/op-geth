#!/bin/sh

set -e

# Check if the jwtsecret file exists
if [ -f "/tmp/jwtsecret" ]; then
  echo "Using jwtsecret from file"
elif [ ! -z "$JWT_SECRET" ]; then
  echo "Using jwtsecret from environment variable"
  echo "$JWT_SECRET" > /tmp/jwtsecret
else
  echo "JWT_SECRET environment variable is not set and jwtsecret file is not found"
  exit 1
fi

# Update the chainId in genesis3.json with the value of the CHAIN_ID environment variable
if [ -z "$CHAIN_ID" ]; then
  echo "CHAIN_ID environment variable is not set"
  exit 1
fi

jq --arg chainId "$CHAIN_ID" '.config.chainId = ($chainId | tonumber)' /genesis3.json > /tmp/genesis3.json && mv /tmp/genesis3.json /genesis3.json

# Check if the data directory is empty
if [ ! "$(ls -A /root/ethereum)" ]; then
  echo "Initializing new blockchain..."
  geth init --datadir /root/ethereum /genesis3.json
else
  echo "Blockchain already initialized."
fi

# Start geth in server mode without interactive console
exec geth \
  --datadir /root/ethereum \
  --http \
  --http.addr "0.0.0.0" \
  --http.api "eth,net,web3,debug" \
  --http.vhosts="*" \
  --authrpc.addr "0.0.0.0" \
  --authrpc.vhosts="*" \
  --authrpc.port 8551 \
  --authrpc.jwtsecret /tmp/jwtsecret \
  --nodiscover \
  --cache 25000 \
  --cache.preimages=true \
  --maxpeers 0 \
  --syncmode full \
  --gcmode archive \
  --rollup.disabletxpoolgossip=true \
  --history.state "0" \
  --history.transactions "0" \
  