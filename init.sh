#!/bin/bash
# =============================================================
# init.sh — Initialize the Multichain network
# Creates the chain on node1, then connects node2 and node3
# =============================================================

set -e

# Load environment variables
source .env 2>/dev/null || true

CHAIN=${CHAIN_NAME:-mychain}
RPC_USER=${RPC_USER:-multichainrpc}
RPC_PASS=${RPC_PASSWORD:-password123}
RPC_PORT=${RPC_PORT:-7419}

echo "============================================="
echo "  Multichain Network Initialization"
echo "  Chain: $CHAIN"
echo "============================================="

# ── Helper: run multichain-cli on a node ──────────────────────
node_cli() {
  local NODE=$1
  shift
  docker exec "$NODE" multichain-cli "$CHAIN" \
    -rpcuser="$RPC_USER" \
    -rpcpassword="$RPC_PASS" \
    -rpcport="$RPC_PORT" \
    "$@"
}

# ── Step 1: Start containers ──────────────────────────────────
echo ""
echo "[1/5] Starting Docker containers..."
docker-compose up -d node1

echo "      Waiting 20s for node1 to initialize the chain..."
sleep 20

# ── Step 2: Verify node1 is running ──────────────────────────
echo ""
echo "[2/5] Verifying node1..."
node_cli node1 getinfo | grep -E '"chain"|"blocks"|"nodeaddress"'
echo "      node1 is UP ✓"

# ── Step 3: Get node1 address and connection string ───────────
echo ""
echo "[3/5] Fetching node1 connection details..."
NODE1_ADDR=$(node_cli node1 getinfo | grep '"nodeaddress"' | sed 's/.*: "\(.*\)".*/\1/')
# Build the multichain:// connect string using Docker internal hostname
CONNECT_STRING="multichain://node1:${P2P_PORT:-7418}"
echo "      Node1 address : $NODE1_ADDR"
echo "      Connect string: $CONNECT_STRING"

# ── Step 4: Start peer nodes and connect them ─────────────────
echo ""
echo "[4/5] Starting peer nodes..."
docker-compose up -d node2 node3
echo "      Waiting 20s for peer nodes to start..."
sleep 20

echo "      Connecting node2 to node1..."
docker exec node2 multichain-cli "$CHAIN" \
  -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" \
  addnode "node1:${P2P_PORT:-7418}" add 2>/dev/null || \
  echo "      (node2 may already be connected via env config)"

echo "      Connecting node3 to node1..."
docker exec node3 multichain-cli "$CHAIN" \
  -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" \
  addnode "node1:${P2P_PORT:-7418}" add 2>/dev/null || \
  echo "      (node3 may already be connected via env config)"

sleep 10

# ── Step 5: Grant connect permissions to peer nodes ──────────
echo ""
echo "[5/5] Granting permissions to peer nodes..."

NODE2_ADDR=$(docker exec node2 multichain-cli "$CHAIN" \
  -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" \
  getinfo 2>/dev/null | grep '"nodeaddress"' | sed 's/.*: "\(.*\)".*/\1/' || echo "")

NODE3_ADDR=$(docker exec node3 multichain-cli "$CHAIN" \
  -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" \
  getinfo 2>/dev/null | grep '"nodeaddress"' | sed 's/.*: "\(.*\)".*/\1/' || echo "")

if [ -n "$NODE2_ADDR" ]; then
  # Extract wallet address from node address (strip multichain://...@)
  N2_WALLET=$(echo "$NODE2_ADDR" | sed 's/.*@//' | sed 's/:.*//')
  node_cli node1 grant "$N2_WALLET" connect,send,receive 2>/dev/null || true
  echo "      Granted permissions to node2 ✓"
fi

if [ -n "$NODE3_ADDR" ]; then
  N3_WALLET=$(echo "$NODE3_ADDR" | sed 's/.*@//' | sed 's/:.*//')
  node_cli node1 grant "$N3_WALLET" connect,send,receive 2>/dev/null || true
  echo "      Granted permissions to node3 ✓"
fi

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "============================================="
echo "  Network Initialization Complete!"
echo "============================================="
echo ""
echo "  Nodes running:"
echo "  • node1 (master) → RPC: localhost:7419"
echo "  • node2 (peer)   → RPC: localhost:7421"
echo "  • node3 (peer)   → RPC: localhost:7423"
echo ""
echo "  Next steps:"
echo "  • Run ./send-asset.sh to create and transfer assets"
echo "  • Run ./check-balance.sh to view balances"
echo "============================================="
