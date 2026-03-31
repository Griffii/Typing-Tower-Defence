const { createLobbyManager } = require("../lobby/lobby_manager");
const { createMatchManager } = require("../match/match_manager");

function createMessageRouter(state) {
  const lobbyManager = createLobbyManager(state);
  const matchManager = createMatchManager(state);

  function handle(client, msg) {
    switch (msg.type) {
      case "create_lobby":
        return lobbyManager.createLobby(client);

      case "join_lobby":
        return lobbyManager.joinLobby(client, msg.code);

      case "leave_lobby":
        return lobbyManager.leaveLobby(client);

      case "submit_word":
        return matchManager.submitWord(client, msg);

      case "ping":
        return send(client.ws, {
          type: "pong",
          serverTime: Date.now(),
        });

      default:
        return send(client.ws, {
          type: "error",
          message: "Unknown message type",
        });
    }
  }

  function handleDisconnect(client) {
    lobbyManager.leaveLobby(client);
    matchManager.handleDisconnect(client);
  }

  return { handle, handleDisconnect };
}

const { send } = require("./websocket");

module.exports = { createMessageRouter };
