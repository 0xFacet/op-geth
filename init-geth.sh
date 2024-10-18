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

# Check if the genesis file is specified
if [ -z "$GENESIS_FILE" ]; then
  echo "GENESIS_FILE environment variable is not set"
  exit 1
fi

# Check if the genesis file exists
if [ ! -f "/$GENESIS_FILE" ]; then
  echo "Specified genesis file /$GENESIS_FILE does not exist"
  exit 1
fi

# Update the genesis file with the specified timestamp and mixHash if they are set
if [ ! -z "$GENESIS_TIMESTAMP" ]; then
  # Check if the timestamp is in hexadecimal format (starts with "0x")
  if [[ "$GENESIS_TIMESTAMP" =~ ^0x ]]; then
    echo "Using hexadecimal timestamp: $GENESIS_TIMESTAMP"
    timestamp_hex="$GENESIS_TIMESTAMP"
  else
    # Convert base 10 timestamp to hexadecimal
    echo "Converting base 10 timestamp to hexadecimal"
    timestamp_hex=$(printf "0x%x" "$GENESIS_TIMESTAMP")
  fi

  echo "Updating timestamp in genesis file"
  sed -i "s/\"timestamp\": \".*\"/\"timestamp\": \"$timestamp_hex\"/" "/$GENESIS_FILE"
else
  echo "GENESIS_TIMESTAMP environment variable is not set, using existing value in genesis file"
fi

if [ ! -z "$GENESIS_MIX_HASH" ]; then
  echo "Updating mixHash in genesis file"
  sed -i "s/\"mixHash\": \".*\"/\"mixHash\": \"$GENESIS_MIX_HASH\"/" "/$GENESIS_FILE"
else
  echo "GENESIS_MIX_HASH environment variable is not set, using existing value in genesis file"
fi

# Check if the data directory is empty
if [ ! "$(ls -A /root/ethereum)" ]; then
  echo "Initializing new blockchain..."
  geth init --cache.preimages --state.scheme=hash --datadir /root/ethereum "/$GENESIS_FILE"
else
  echo "Blockchain already initialized."
fi

# Set default RPC gas cap if not provided
RPC_GAS_CAP=${RPC_GAS_CAP:-500000000}

# Start geth in server mode without interactive console
exec geth \
  --datadir /root/ethereum \
  --http \
  --http.addr "0.0.0.0" \
  --http.api "eth,net,web3,debug" \
  --http.vhosts="*" \
  --http.corsdomain="*" \
  --authrpc.addr "0.0.0.0" \
  --authrpc.vhosts="*" \
  --authrpc.port 8551 \
  --authrpc.jwtsecret /tmp/jwtsecret \
  --nodiscover \
  --cache 25000 \
  --cache.preimages \
  --maxpeers 0 \
  --rpc.gascap $RPC_GAS_CAP \
  --syncmode full \
  --gcmode archive \
  --rollup.disabletxpoolgossip \
  --history.state 0 \
  --history.transactions 0
