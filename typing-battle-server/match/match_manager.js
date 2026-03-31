const { send } = require("../network/websocket");
const { normalize } = require("../game/word_logic");
const {
  createMatchState,
  resetMatchForRematch,
  serializeMatch,
  getSide,
  getOpponent,
  getOpponentSide,
} = require("./match_state");
const {
  SIM_TICK_MS,
  createSoldier,
  simulateCombatTick,
} = require("../game/combat_logic");

function createMatchManager(state) {
  function startMatch(lobby) {
    const [left, right] = lobby.players;

    const matchId = `m${state.nextMatchId++}`;
    const match = createMatchState({
      matchId,
      left,
      right,
    });

    state.matches.set(matchId, match);

    left.matchId = matchId;
    right.matchId = matchId;

    state.lobbies.delete(lobby.code);

    _beginCountdown(match);
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
        state: serializeMatch(match),
        reason: "Incorrect word",
      });
    }

    match.stats[side].wordsTyped.push(text);
    match.stats[side].soldiersSent += 1;

    const soldierId = `s${match.nextSoldierId++}`;
    const soldier = createSoldier({
      id: soldierId,
      side,
    });

    match.soldiers.set(soldier.id, soldier);
    player.currentWord = match.drawNextWord();

    broadcast(match, {
      type: "word_resolved",
      attackerSide: side,
      typedText: text,
      spawnCount: 1,
      state: serializeMatch(match),
    });

    broadcast(match, {
      type: "soldier_spawned",
      soldier,
      state: serializeMatch(match),
    });
  }

  function playAgain(client) {
    const match = state.matches.get(client.matchId);
    if (!match) {
      return;
    }

    const side = getSide(match, client.playerId);
    match.rematchVotes[side] = true;

    broadcast(match, {
      type: "rematch_waiting",
      rematchVotes: {
        left: match.rematchVotes.left,
        right: match.rematchVotes.right,
      },
      state: serializeMatch(match),
    });

    if (match.rematchVotes.left && match.rematchVotes.right) {
      resetMatchForRematch(match);

      broadcast(match, {
        type: "rematch_ready",
        state: serializeMatch(match),
      });

      _beginCountdown(match);
    }
  }

  function handleDisconnect(client) {
    const match = state.matches.get(client.matchId);
    if (!match) {
      return;
    }

    notifyOpponentPlayerLeft(match, client.playerId);

    match.status = "ended";
    match.winner = getOpponent(match, client.playerId);

    broadcast(match, {
      type: "match_ended",
      winnerPlayerId: match.winner,
      winnerSide: getOpponentSide(match, client.playerId),
      state: serializeMatch(match),
    });

    cleanupMatch(match);
  }

  function leaveMatch(client) {
    const match = state.matches.get(client.matchId);
    if (!match) {
      return;
    }

    notifyOpponentPlayerLeft(match, client.playerId);

    match.status = "ended";
    match.winner = getOpponent(match, client.playerId);

    broadcast(match, {
      type: "match_ended",
      winnerPlayerId: match.winner,
      winnerSide: getOpponentSide(match, client.playerId),
      state: serializeMatch(match),
    });

    cleanupMatch(match);
  }

  function cleanupMatch(match) {
    if (match.countdownTimer) {
      clearTimeout(match.countdownTimer);
      match.countdownTimer = null;
    }

    if (match.simulationInterval) {
      clearInterval(match.simulationInterval);
      match.simulationInterval = null;
    }

    if (match.players.left?.session) {
      match.players.left.session.matchId = null;
    }

    if (match.players.right?.session) {
      match.players.right.session.matchId = null;
    }

    state.matches.delete(match.matchId);
  }

  function _beginCountdown(match) {
    if (match.countdownTimer) {
      clearTimeout(match.countdownTimer);
      match.countdownTimer = null;
    }

    if (match.simulationInterval) {
      clearInterval(match.simulationInterval);
      match.simulationInterval = null;
    }

    match.status = "countdown";

    broadcast(match, {
      type: "match_countdown",
      state: serializeMatch(match),
    });

    match.countdownTimer = setTimeout(() => {
      if (!state.matches.has(match.matchId)) {
        return;
      }

      match.status = "active";
      match.startedAt = Date.now();

      broadcast(match, {
        type: "match_started",
        state: serializeMatch(match),
      });

      _startSimulation(match);
    }, match.countdownMs);
  }

  function _startSimulation(match) {
    if (match.simulationInterval) {
      clearInterval(match.simulationInterval);
    }

    match.lastSimulationAt = Date.now();

    match.simulationInterval = setInterval(() => {
      if (!state.matches.has(match.matchId)) {
        return;
      }

      const now = Date.now();
      const deltaMs = now - match.lastSimulationAt;
      match.lastSimulationAt = now;

      const result = simulateCombatTick(match, deltaMs);

      for (const event of result.events) {
        broadcast(match, event);
      }

      if (result.matchEnded) {
        match.status = "ended";
        match.winner = match.players[result.winnerSide].playerId;

        broadcast(match, {
          type: "match_ended",
          winnerPlayerId: match.winner,
          winnerSide: result.winnerSide,
          state: serializeMatch(match),
        });

        cleanupMatch(match);
      }
    }, SIM_TICK_MS);
  }

  function notifyOpponentPlayerLeft(match, leavingPlayerId) {
    const leftId = match.players.left.playerId;
    const remainingSession =
      leftId === leavingPlayerId
        ? match.players.right.session
        : match.players.left.session;

    send(remainingSession.ws, {
      type: "opponent_left_session",
      leavingPlayerId,
      state: serializeMatch(match),
    });
  }

  function broadcast(match, payload) {
    send(match.players.left.session.ws, payload);
    send(match.players.right.session.ws, payload);
  }

  return {
    startMatch,
    submitWord,
    playAgain,
    handleDisconnect,
    leaveMatch,
  };
}

module.exports = { createMatchManager };
