const { send } = require("../network/websocket");
const { createWordBag, drawWord, normalize } = require("../game/word_logic");

const MATCH_COUNTDOWN_MS = 3000;
const DEFAULT_HP = 100;

function createMatchManager(state) {
  function startMatch(lobby) {
    const [left, right] = lobby.players;

    const matchId = `m${state.nextMatchId++}`;
    const wordBag = createWordBag();

    const match = {
      matchId,
      status: "countdown",
      winner: null,
      countdownTimer: null,
      wordBag,
      players: {
        left: {
          playerId: left.playerId,
          session: left,
          castleHp: DEFAULT_HP,
          currentWord: drawWord(wordBag),
        },
        right: {
          playerId: right.playerId,
          session: right,
          castleHp: DEFAULT_HP,
          currentWord: drawWord(wordBag),
        },
      },
    };

    state.matches.set(matchId, match);

    left.matchId = matchId;
    right.matchId = matchId;

    state.lobbies.delete(lobby.code);

    broadcast(match, {
      type: "match_countdown",
      state: serialize(match),
    });

    match.countdownTimer = setTimeout(() => {
      if (!state.matches.has(matchId)) {
        return;
      }

      match.status = "active";

      broadcast(match, {
        type: "match_started",
        state: serialize(match),
      });
    }, MATCH_COUNTDOWN_MS);
  }

  function submitWord(client, msg) {
    const match = state.matches.get(client.matchId);
    if (!match || match.status !== "active") {
      return;
    }

    const side = getSide(match, client.playerId);
    const player = match.players[side];

    const text = normalize(msg.text);

    if (text !== player.currentWord.text) {
      return send(client.ws, {
        type: "word_rejected",
        state: serialize(match),
        reason: "Incorrect word",
      });
    }

    player.currentWord = drawWord(match.wordBag);

    broadcast(match, {
      type: "word_resolved",
      attackerSide: side,
      spawnCount: 1,
      damage: 0,
      state: serialize(match),
    });
  }

  function handleDisconnect(client) {
    const match = state.matches.get(client.matchId);
    if (!match) {
      return;
    }

    match.status = "ended";
    match.winner = getOpponent(match, client.playerId);

    broadcast(match, {
      type: "match_ended",
      winnerPlayerId: match.winner,
      state: serialize(match),
    });

    cleanupMatch(match);
  }

  function cleanupMatch(match) {
    if (match.countdownTimer) {
      clearTimeout(match.countdownTimer);
      match.countdownTimer = null;
    }

    if (match.players.left?.session) {
      match.players.left.session.matchId = null;
    }

    if (match.players.right?.session) {
      match.players.right.session.matchId = null;
    }

    state.matches.delete(match.matchId);
  }

  function broadcast(match, payload) {
    send(match.players.left.session.ws, payload);
    send(match.players.right.session.ws, payload);
  }

  function serialize(match) {
    return {
      players: {
        left: {
          playerId: match.players.left.playerId,
          castleHp: match.players.left.castleHp,
          currentWord: match.players.left.currentWord,
        },
        right: {
          playerId: match.players.right.playerId,
          castleHp: match.players.right.castleHp,
          currentWord: match.players.right.currentWord,
        },
      },
      status: match.status,
      winner: match.winner,
    };
  }

  function getSide(match, id) {
    if (match.players.left.playerId === id) {
      return "left";
    }
    return "right";
  }

  function getOpponent(match, id) {
    return match.players.left.playerId === id
      ? match.players.right.playerId
      : match.players.left.playerId;
  }

  return {
    startMatch,
    submitWord,
    handleDisconnect,
  };
}

module.exports = { createMatchManager };