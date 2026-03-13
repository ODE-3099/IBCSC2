#!/bin/bash
# entrypoint-peer.sh — Connects a peer node to the master

CHAIN=${CHAIN_NAME:-mychain}
RPC_USER=${RPC_USER:-multichainrpc}
RPC_PASS=${RPC_PASSWORD:-password123}
RPC_PORT=${RPC_PORT:-7419}
P2P_PORT=${P2P_PORT:-7418}
MASTER=${MASTER_NODE:-node1}
MASTER_P2P=${P2P_PORT:-7418}

echo "[peer] Waiting for master node ($MASTER) to be ready..."
sleep 15

echo "[peer] Connecting to $CHAIN @ $MASTER:$MASTER_P2P ..."

# Connect to master — this downloads the chain params automatically
multichaind "$CHAIN"@"$MASTER":"$MASTER_P2P" \
  -daemon=0 \
  -port=$P2P_PORT \
  -rpcport=$RPC_PORT \
  -rpcuser=$RPC_USER \
  -rpcpassword=$RPC_PASS \
  -rpcallowip=0.0.0.0/0 \
  -autosubscribe=assets &

# Wait for the node to write its address, then print it
sleep 10
echo ""
echo "[peer] ================================================"
echo "[peer] This node needs to be granted connect permission"
echo "[peer] by the master node. Check init.sh output."
echo "[peer] ================================================"

# Keep container alive
wait
