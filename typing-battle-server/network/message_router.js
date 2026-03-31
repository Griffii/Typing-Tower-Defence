const { createLobbyManager } = require("../lobby/lobby_manager");
const { createMatchManager } = require("../match/match_manager");
const { send } = require("./websocket");

function createMessageRouter(state) {
  const matchManager = createMatchManager(state);
  const lobbyManager = createLobbyManager(state, matchManager);

  function handle(client, msg) {
    switch (msg.type) {
      case "create_lobby":
        return lobbyManager.createLobby(client, msg.playerName);

      case "join_lobby":
        return lobbyManager.joinLobby(client, msg.code, msg.playerName);

      case "update_lobby_name":
        return lobbyManager.updateLobbyName(client, msg.playerName);

      case "set_lobby_ready":
        return lobbyManager.setLobbyReady(client, msg.isReady);

      case "leave_lobby":
        return lobbyManager.leaveLobby(client);

      case "leave_match":
        return matchManager.leaveMatch(client);

      case "submit_word":
        return matchManager.submitWord(client, msg);

      case "play_again":
        return matchManager.playAgain(client);

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

module.exports = { createMessageRouter };
