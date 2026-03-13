#!/bin/bash
# entrypoint-master.sh — Starts the master node and creates the chain

CHAIN=${CHAIN_NAME:-mychain}
RPC_USER=${RPC_USER:-multichainrpc}
RPC_PASS=${RPC_PASSWORD:-password123}
RPC_PORT=${RPC_PORT:-7419}
P2P_PORT=${P2P_PORT:-7418}

echo "[master] Creating blockchain: $CHAIN"

# Create the chain
multichain-util create "$CHAIN"

# Configure RPC access
cat >> /root/.multichain/$CHAIN/multichain.conf <<EOF
rpcuser=$RPC_USER
rpcpassword=$RPC_PASS
rpcport=$RPC_PORT
rpcallowip=0.0.0.0/0
EOF

echo "[master] Starting multichaind..."
exec multichaind "$CHAIN" \
  -daemon=0 \
  -port=$P2P_PORT \
  -rpcport=$RPC_PORT \
  -rpcuser=$RPC_USER \
  -rpcpassword=$RPC_PASS \
  -rpcallowip=0.0.0.0/0 \
  -autosubscribe=assets
