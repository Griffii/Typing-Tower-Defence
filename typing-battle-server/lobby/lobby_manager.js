const { send } = require("../network/websocket");
const { generateLobbyCode } = require("../utils/ids");

function createLobbyManager(state, matchManager) {
  function createLobby(client, playerName = "") {
    const code = generateLobbyCode(state.lobbies);

    client.playerName = normalizePlayerName(playerName);
    client.lobbyCode = code;
    client.side = "left";
    client.isReady = false;

    const lobby = {
      code,
      players: [client],
    };

    state.lobbies.set(code, lobby);
    _broadcastLobbyState(lobby);
  }

  function joinLobby(client, code, playerName = "") {
    const normalizedCode = String(code || "")
      .trim()
      .toUpperCase();
    const lobby = state.lobbies.get(normalizedCode);

    if (!lobby || lobby.players.length >= 2) {
      return send(client.ws, {
        type: "error",
        message: "Lobby invalid or full",
      });
    }

    client.playerName = normalizePlayerName(playerName);
    client.lobbyCode = normalizedCode;
    client.side = "right";
    client.isReady = false;

    lobby.players.push(client);
    _broadcastLobbyState(lobby);
    _tryStartMatch(lobby);
  }

  function updateLobbyName(client, playerName) {
    if (!client.lobbyCode) return;

    const lobby = state.lobbies.get(client.lobbyCode);
    if (!lobby) return;

    client.playerName = normalizePlayerName(playerName);
    client.isReady = false;

    _broadcastLobbyState(lobby);
    _tryStartMatch(lobby);
  }

  function setLobbyReady(client, isReady) {
    if (!client.lobbyCode) return;

    const lobby = state.lobbies.get(client.lobbyCode);
    if (!lobby) return;

    if (!String(client.playerName || "").trim()) {
      client.isReady = false;
    } else {
      client.isReady = Boolean(isReady);
    }

    _broadcastLobbyState(lobby);
    _tryStartMatch(lobby);
  }

  function leaveLobby(client) {
    if (!client.lobbyCode) return;

    const lobby = state.lobbies.get(client.lobbyCode);
    const oldLobbyCode = client.lobbyCode;

    client.lobbyCode = null;
    client.side = null;
    client.isReady = false;

    if (!lobby) return;

    lobby.players = lobby.players.filter((p) => p !== client);

    if (lobby.players.length === 0) {
      state.lobbies.delete(oldLobbyCode);
      return;
    }

    _broadcastLobbyState(lobby);
  }

  function _tryStartMatch(lobby) {
    if (!_canStartMatch(lobby)) {
      return;
    }

    matchManager.startMatch(lobby);
  }

  function _canStartMatch(lobby) {
    if (lobby.players.length !== 2) {
      return false;
    }

    return lobby.players.every((p) => {
      return String(p.playerName || "").trim() !== "" && p.isReady === true;
    });
  }

  function _broadcastLobbyState(lobby) {
    const phase = lobby.players.length < 2 ? "waiting" : "ready_room";

    const payload = {
      type: "lobby_state",
      code: lobby.code,
      phase,
      players: lobby.players.map((p) => ({
        playerId: p.playerId,
        playerName: p.playerName || "",
        side: p.side || "",
        isReady: Boolean(p.isReady),
      })),
    };

    lobby.players.forEach((p) => send(p.ws, payload));
  }

  function normalizePlayerName(value) {
    return String(value || "")
      .trim()
      .slice(0, 24);
  }

  return {
    createLobby,
    joinLobby,
    updateLobbyName,
    setLobbyReady,
    leaveLobby,
  };
}

module.exports = { createLobbyManager };
