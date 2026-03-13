#!/bin/bash
# =============================================================
# check-balance.sh — Check asset balances on all three nodes
# =============================================================

source .env 2>/dev/null || true

CHAIN=${CHAIN_NAME:-mychain}
RPC_USER=${RPC_USER:-multichainrpc}
RPC_PASS=${RPC_PASSWORD:-password123}
RPC_PORT=${RPC_PORT:-7419}

echo "============================================="
echo "  Multichain Network — Balance Check"
echo "  Chain: $CHAIN"
echo "============================================="

# ── Helper ────────────────────────────────────────────────────
node_cli() {
  local NODE=$1; shift
  docker exec "$NODE" multichain-cli "$CHAIN" \
    -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" -rpcport="$RPC_PORT" "$@" 2>/dev/null
}

check_node() {
  local NODE=$1
  echo ""
  echo "─── $NODE ───────────────────────────────────"

  # Node info
  local BLOCKS
  BLOCKS=$(node_cli "$NODE" getinfo | grep '"blocks"' | sed 's/[^0-9]//g')
  echo "  Blocks synced : $BLOCKS"

  # Peer count
  local PEERS
  PEERS=$(node_cli "$NODE" getpeerinfo | grep -c '"addr"' || echo "0")
  echo "  Connected peers: $PEERS"

  # Asset balances
  echo "  Asset balances:"
  local BALANCES
  BALANCES=$(node_cli "$NODE" gettotalbalances)
  if echo "$BALANCES" | grep -q '"name"'; then
    echo "$BALANCES" | grep -E '"name"|"qty"' | paste - - | \
      sed 's/.*"name": "\(.*\)".*/\1/' | \
      awk '{print "    •", $0}'
    # Simpler fallback display
    echo "$BALANCES" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if not data:
    print('    (no assets yet)')
for a in data:
    print(f'    • {a.get(\"name\",\"?\")} : {a.get(\"qty\",0)}')
" 2>/dev/null || echo "$BALANCES"
  else
    echo "    (no assets yet or node still syncing)"
  fi
}

# ── Check all nodes ───────────────────────────────────────────
check_node node1
check_node node2
check_node node3

# ── Network-wide asset list ───────────────────────────────────
echo ""
echo "─── Network Assets (from node1) ─────────────"
node_cli node1 listassets | python3 -c "
import sys, json
try:
    assets = json.load(sys.stdin)
    if not assets:
        print('  No assets issued yet.')
    for a in assets:
        print(f'  Asset : {a.get(\"name\",\"?\")}')
        print(f'  Supply: {a.get(\"issueqty\",0)}')
        print(f'  TxID  : {a.get(\"issuetxid\",\"?\")}')
        print()
except:
    print('  Could not parse asset list.')
" 2>/dev/null || echo "  Run after issuing assets with ./send-asset.sh"

echo ""
echo "============================================="
echo "  Tip: Re-run this script anytime to refresh"
echo "============================================="
