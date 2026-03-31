const { send } = require("../network/websocket");
const { generateLobbyCode } = require("../utils/ids");

function createLobbyManager(state) {
  function createLobby(client) {
    const code = generateLobbyCode(state.lobbies);

    const lobby = {
      code,
      players: [client],
    };

    state.lobbies.set(code, lobby);

    client.lobbyCode = code;
    client.side = "left";

    send(client.ws, {
      type: "lobby_created",
      code,
      side: "left",
    });
  }

  function joinLobby(client, code) {
    const lobby = state.lobbies.get(code?.toUpperCase());

    if (!lobby || lobby.players.length >= 2) {
      return send(client.ws, {
        type: "error",
        message: "Lobby invalid or full",
      });
    }

    client.lobbyCode = code;
    client.side = "right";
    lobby.players.push(client);

    send(client.ws, {
      type: "lobby_joined",
      code,
      side: "right",
    });

    lobby.players.forEach((p) => send(p.ws, { type: "lobby_ready" }));

    require("../match/match_manager")
      .createMatchManager(state)
      .startMatch(lobby);
  }

  function leaveLobby(client) {
    if (!client.lobbyCode) return;

    const lobby = state.lobbies.get(client.lobbyCode);
    client.lobbyCode = null;

    if (!lobby) return;

    lobby.players = lobby.players.filter((p) => p !== client);

    if (lobby.players.length === 0) {
      state.lobbies.delete(lobby.code);
    }
  }

  return { createLobby, joinLobby, leaveLobby };
}

module.exports = { createLobbyManager };
