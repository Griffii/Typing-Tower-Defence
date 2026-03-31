const { createWordBag, drawWord } = require("../game/word_logic");

const MATCH_COUNTDOWN_MS = 3000;
const DEFAULT_HP = 100;

function createMatchState({ matchId, left, right }) {
  const wordBag = createWordBag();

  return {
    matchId,
    status: "countdown",
    winner: null,
    countdownMs: MATCH_COUNTDOWN_MS,
    countdownTimer: null,
    simulationInterval: null,
    lastSimulationAt: 0,
    startedAt: 0,

    wordBag,
    drawNextWord: () => drawWord(wordBag),

    rematchVotes: {
      left: false,
      right: false,
    },

    castles: {
      left: { hp: DEFAULT_HP },
      right: { hp: DEFAULT_HP },
    },

    nextSoldierId: 1,
    soldiers: new Map(),

    stats: {
      left: {
        wordsTyped: [],
        soldiersSent: 0,
        soldiersDied: 0,
      },
      right: {
        wordsTyped: [],
        soldiersSent: 0,
        soldiersDied: 0,
      },
    },

    players: {
      left: {
        playerId: left.playerId,
        playerName: left.playerName || "Left Player",
        session: left,
        currentWord: drawWord(wordBag),
      },
      right: {
        playerId: right.playerId,
        playerName: right.playerName || "Right Player",
        session: right,
        currentWord: drawWord(wordBag),
      },
    },
  };
}

function resetMatchForRematch(match) {
  if (match.countdownTimer) {
    clearTimeout(match.countdownTimer);
    match.countdownTimer = null;
  }

  if (match.simulationInterval) {
    clearInterval(match.simulationInterval);
    match.simulationInterval = null;
  }

  const wordBag = createWordBag();

  match.status = "countdown";
  match.winner = null;
  match.startedAt = 0;
  match.lastSimulationAt = 0;

  match.wordBag = wordBag;
  match.drawNextWord = () => drawWord(wordBag);

  match.rematchVotes.left = false;
  match.rematchVotes.right = false;

  match.castles.left.hp = DEFAULT_HP;
  match.castles.right.hp = DEFAULT_HP;

  match.nextSoldierId = 1;
  match.soldiers = new Map();

  match.stats.left.wordsTyped = [];
  match.stats.left.soldiersSent = 0;
  match.stats.left.soldiersDied = 0;

  match.stats.right.wordsTyped = [];
  match.stats.right.soldiersSent = 0;
  match.stats.right.soldiersDied = 0;

  match.players.left.currentWord = drawWord(wordBag);
  match.players.right.currentWord = drawWord(wordBag);
}

function serializeMatch(match) {
  return {
    matchId: match.matchId,
    status: match.status,
    winner: match.winner,
    startedAt: match.startedAt,
    players: {
      left: {
        playerId: match.players.left.playerId,
        name: match.players.left.playerName,
        castleHp: match.castles.left.hp,
        currentWord: match.players.left.currentWord,
      },
      right: {
        playerId: match.players.right.playerId,
        name: match.players.right.playerName,
        castleHp: match.castles.right.hp,
        currentWord: match.players.right.currentWord,
      },
    },
    castles: {
      left: { hp: match.castles.left.hp },
      right: { hp: match.castles.right.hp },
    },
    soldiers: Array.from(match.soldiers.values()).map((soldier) => ({
      id: soldier.id,
      side: soldier.side,
      x: soldier.x,
      hp: soldier.hp,
      state: soldier.state,
      targetId: soldier.targetId,
    })),
    rematchVotes: {
      left: match.rematchVotes.left,
      right: match.rematchVotes.right,
    },
    stats: {
      left: {
        wordsTyped: [...match.stats.left.wordsTyped],
        soldiersSent: match.stats.left.soldiersSent,
        soldiersDied: match.stats.left.soldiersDied,
      },
      right: {
        wordsTyped: [...match.stats.right.wordsTyped],
        soldiersSent: match.stats.right.soldiersSent,
        soldiersDied: match.stats.right.soldiersDied,
      },
    },
  };
}

function getSide(match, playerId) {
  if (match.players.left.playerId === playerId) {
    return "left";
  }
  return "right";
}

function getOpponent(match, playerId) {
  return match.players.left.playerId === playerId
    ? match.players.right.playerId
    : match.players.left.playerId;
}

function getOpponentSide(match, playerId) {
  return match.players.left.playerId === playerId ? "right" : "left";
}

module.exports = {
  createMatchState,
  resetMatchForRematch,
  serializeMatch,
  getSide,
  getOpponent,
  getOpponentSide,
};