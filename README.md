# Multichain Blockchain Network

A private blockchain network built on the **MultiChain** platform using Docker and Docker Compose. This setup runs a 3-node network with one master node and two peer nodes.

---

## What is MultiChain?

MultiChain is an open-source platform for creating and deploying private blockchain networks. Unlike public blockchains (Ethereum, Bitcoin), MultiChain lets you:

- Create a **permissioned** blockchain — only approved nodes can join
- Issue and transfer **custom assets** (tokens)
- Set rules for who can connect, mine, send, and receive
- Run entirely **offline / on your own infrastructure**

It is widely used for enterprise use cases like supply chain tracking, document verification, and inter-bank settlements.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│               Docker Network: multichain-net         │
│                                                     │
│   ┌─────────────┐         ┌─────────────┐           │
│   │   node1     │◄───────►│   node2     │           │
│   │  (MASTER)   │         │   (PEER)    │           │
│   │             │         │             │           │
│   │ P2P : 7418  │         │ P2P : 7418  │           │
│   │ RPC : 7419  │         │ RPC : 7419  │           │
│   └──────┬──────┘         └─────────────┘           │
│          │                                          │
│          │               ┌─────────────┐            │
│          └──────────────►│   node3     │            │
│                          │   (PEER)    │            │
│                          │             │            │
│                          │ P2P : 7418  │            │
│                          │ RPC : 7419  │            │
│                          └─────────────┘            │
└─────────────────────────────────────────────────────┘

Host Port Mapping:
  node1 → RPC: localhost:7419  | P2P: localhost:7418
  node2 → RPC: localhost:7421  | P2P: localhost:7420
  node3 → RPC: localhost:7423  | P2P: localhost:7422
```

---

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- Git (to clone the repo)

Check your versions:
```bash
docker --version
docker-compose --version
```

---

## Setup Instructions

### Step 1 — Clone the repository
```bash
git clone https://github.com/your-username/multichain-blockchain-network.git
cd multichain-blockchain-network
```

### Step 2 — Make scripts executable
```bash
chmod +x init.sh send-asset.sh check-balance.sh
```

### Step 3 — Initialize the network
```bash
./init.sh
```
This will:
1. Pull the MultiChain Docker image
2. Start node1 and create the blockchain
3. Start node2 and node3 and connect them to node1
4. Grant permissions to peer nodes

### Step 4 — Create and transfer an asset
```bash
./send-asset.sh
```
This will:
1. Issue 1000 `mytoken` on node1
2. Send 300 tokens to node2
3. Send 200 tokens to node3

### Step 5 — Verify balances
```bash
./check-balance.sh
```

---

## Verifying the Network is Working

### Check all containers are running
```bash
docker ps
```
You should see `node1`, `node2`, `node3` all with status `Up`.

### Check node1 blockchain info
```bash
docker exec node1 multichain-cli mychain getinfo
```
Look for `"blocks"` increasing and `"connections"` showing 2 peers.

### Check peer connections
```bash
docker exec node1 multichain-cli mychain getpeerinfo
```
Should show 2 peers (node2 and node3).

### Check a specific balance manually
```bash
# node1 balance
docker exec node1 multichain-cli mychain gettotalbalances

# node2 balance
docker exec node2 multichain-cli mychain gettotalbalances

# node3 balance
docker exec node3 multichain-cli mychain gettotalbalances
```

---

## Common Commands Reference

| Command | Description |
|---|---|
| `docker-compose up -d` | Start all nodes |
| `docker-compose down` | Stop all nodes |
| `docker-compose down -v` | Stop and delete all data |
| `docker-compose logs -f node1` | View node1 logs live |
| `docker ps` | Check running containers |

| MultiChain CLI Command | Description |
|---|---|
| `getinfo` | General blockchain info |
| `getpeerinfo` | List connected peers |
| `listassets` | List all issued assets |
| `gettotalbalances` | Show this node's balances |
| `issue <addr> <asset> <qty>` | Issue a new asset |
| `sendassettoaddress <addr> <asset> <qty>` | Transfer an asset |
| `listaddresses` | Show this node's wallet addresses |
| `grant <addr> <permissions>` | Grant permissions to an address |

---

## Project Structure

```
multichain-blockchain-network/
├── docker-compose.yml    # Defines all 3 nodes
├── .env                  # Configuration variables
├── init.sh               # Network initialization script
├── send-asset.sh         # Asset creation and transfer demo
├── check-balance.sh      # Balance checker for all nodes
└── README.md             # This file
```

---

## Cleanup

To stop the network:
```bash
docker-compose down
```

To stop and remove all blockchain data (full reset):
```bash
docker-compose down -v
```

---

## Notes

- This is a **development/learning** setup, not production-ready
- All nodes run on a single machine using Docker networking
- The `pranavt61/multichain-docker` image is used for MultiChain
- Chain name is `mychain`, configurable in `.env`
