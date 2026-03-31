function setupWebSocket(wss, state, router) {
  wss.on("connection", (ws) => {
    const client = {
      playerId: `p${state.nextPlayerId++}`,
      ws,
      lobbyCode: null,
      matchId: null,
      side: null,
    };

    state.clients.set(ws, client);

    send(ws, {
      type: "connected",
      playerId: client.playerId,
    });

    ws.on("message", (raw) => {
      let msg;
      try {
        msg = JSON.parse(raw.toString());
      } catch {
        return send(ws, { type: "error", message: "Invalid JSON" });
      }

      router.handle(client, msg);
    });

    ws.on("close", () => {
      router.handleDisconnect(client);
      state.clients.delete(ws);
    });

    ws.on("error", () => {
      router.handleDisconnect(client);
      state.clients.delete(ws);
    });
  });
}

function send(ws, payload) {
  if (!ws || ws.readyState !== ws.OPEN) return;
  ws.send(JSON.stringify(payload));
}

module.exports = { setupWebSocket, send };
