#!/bin/bash
# =============================================================
# send-asset.sh — Create an asset on node1 and send to peers
# =============================================================

set -e
source .env 2>/dev/null || true

CHAIN=${CHAIN_NAME:-mychain}
RPC_USER=${RPC_USER:-multichainrpc}
RPC_PASS=${RPC_PASSWORD:-password123}
RPC_PORT=${RPC_PORT:-7419}
ASSET_NAME="mytoken"
TOTAL_SUPPLY=1000
UNITS=1

echo "============================================="
echo "  Asset Creation & Transfer Demo"
echo "  Chain : $CHAIN"
echo "  Asset : $ASSET_NAME"
echo "============================================="

# ── Helper ────────────────────────────────────────────────────
node_cli() {
  local NODE=$1; shift
  docker exec "$NODE" multichain-cli "$CHAIN" \
    -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" "$@"
}

get_wallet_address() {
  local NODE=$1
  docker exec "$NODE" multichain-cli "$CHAIN" \
    -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" \
    listaddresses | grep '"address"' | head -1 | sed 's/.*: "\(.*\)".*/\1/'
}

# ── Step 1: Get wallet addresses ──────────────────────────────
echo ""
echo "[1/4] Fetching wallet addresses..."
ADDR1=$(get_wallet_address node1)
ADDR2=$(get_wallet_address node2)
ADDR3=$(get_wallet_address node3)

echo "      node1 address: $ADDR1"
echo "      node2 address: $ADDR2"
echo "      node3 address: $ADDR3"

# ── Step 2: Issue asset on node1 ──────────────────────────────
echo ""
echo "[2/4] Issuing asset '$ASSET_NAME' with supply $TOTAL_SUPPLY on node1..."

TXID=$(node_cli node1 issue "$ADDR1" "$ASSET_NAME" $TOTAL_SUPPLY $UNITS)
echo "      TX ID: $TXID"
echo "      Asset issued ✓"

sleep 5

# ── Step 3: Send 300 tokens to node2 ─────────────────────────
echo ""
echo "[3/4] Sending 300 $ASSET_NAME from node1 → node2..."
TX2=$(node_cli node1 sendassettoaddress "$ADDR2" "$ASSET_NAME" 300)
echo "      TX ID: $TX2"
echo "      Transfer to node2 ✓"

sleep 3

# ── Step 4: Send 200 tokens to node3 ─────────────────────────
echo ""
echo "[4/4] Sending 200 $ASSET_NAME from node1 → node3..."
TX3=$(node_cli node1 sendassettoaddress "$ADDR3" "$ASSET_NAME" 200)
echo "      TX ID: $TX3"
echo "      Transfer to node3 ✓"

sleep 5

# ── Summary ───────────────────────────────────────────────────
echo ""
echo "============================================="
echo "  Transfers Complete!"
echo "  Expected balances:"
echo "  • node1: 500 $ASSET_NAME (issued 1000, sent 500)"
echo "  • node2: 300 $ASSET_NAME"
echo "  • node3: 200 $ASSET_NAME"
echo ""
echo "  Run ./check-balance.sh to verify"
echo "============================================="
