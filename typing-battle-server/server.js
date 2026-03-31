const http = require("http");
const { WebSocketServer } = require("ws");

const { setupWebSocket } = require("./network/websocket");
const { createMessageRouter } = require("./network/message_router");

const PORT = process.env.PORT || 8080;

// Shared state (single source of truth)
const state = {
  clients: new Map(),
  lobbies: new Map(),
  matches: new Map(),
  nextPlayerId: 1,
  nextMatchId: 1,
};

const server = http.createServer();
const wss = new WebSocketServer({ server });

// Router (inject shared state)
const router = createMessageRouter(state);

// Setup WS handling
setupWebSocket(wss, state, router);

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
