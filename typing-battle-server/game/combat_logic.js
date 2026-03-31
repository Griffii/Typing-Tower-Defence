const SOLDIER_HEALTH = 10;
const SOLDIER_DAMAGE = 5;
const SOLDIER_SPEED = 80; // units per second
const SOLDIER_ATTACK_COOLDOWN_MS = 600;
const ENGAGE_DISTANCE = 20;
const SIM_TICK_MS = 100;

const LANE_LEFT_X = 108;
const LANE_RIGHT_X = 1174;

const CASTLE_ATTACK_RANGE = 100;
const LEFT_CASTLE_ATTACK_X = LANE_LEFT_X + CASTLE_ATTACK_RANGE;
const RIGHT_CASTLE_ATTACK_X = LANE_RIGHT_X - CASTLE_ATTACK_RANGE;

function createSoldier({ id, side }) {
  const startX = side === "left" ? LANE_LEFT_X : LANE_RIGHT_X;

  return {
    id,
    side,
    x: startX,
    hp: SOLDIER_HEALTH,
    damage: SOLDIER_DAMAGE,
    speed: SOLDIER_SPEED,
    attackCooldownMs: SOLDIER_ATTACK_COOLDOWN_MS,
    attackTimerMs: 0,
    state: "moving", // moving | fighting | attacking_castle | dead
    targetId: null,
  };
}

function simulateCombatTick(match, deltaMs) {
  const events = [];

  if (match.status !== "active") {
    return {
      events,
      matchEnded: false,
      winnerSide: null,
    };
  }

  _moveSoldiers(match, deltaMs);
  _resolveCastleContact(match, events);
  _resolveEngagements(match, events);
  _resolveAttacks(match, deltaMs, events);
  _cleanupDeadSoldiers(match, events);

  events.push({
    type: "soldier_state",
    soldiers: _serializeSoldiers(match),
    castles: {
      left: { hp: match.castles.left.hp },
      right: { hp: match.castles.right.hp },
    },
  });

  if (match.castles.left.hp <= 0) {
    return {
      events,
      matchEnded: true,
      winnerSide: "right",
    };
  }

  if (match.castles.right.hp <= 0) {
    return {
      events,
      matchEnded: true,
      winnerSide: "left",
    };
  }

  return {
    events,
    matchEnded: false,
    winnerSide: null,
  };
}

function _moveSoldiers(match, deltaMs) {
  const distance = (deltaMs / 1000) * SOLDIER_SPEED;

  for (const soldier of match.soldiers.values()) {
    if (soldier.state !== "moving") {
      continue;
    }

    if (soldier.side === "left") {
      soldier.x += distance;
      if (soldier.x > LANE_RIGHT_X) {
        soldier.x = LANE_RIGHT_X;
      }
    } else {
      soldier.x -= distance;
      if (soldier.x < LANE_LEFT_X) {
        soldier.x = LANE_LEFT_X;
      }
    }
  }
}

function _resolveCastleContact(match, events) {
  for (const soldier of match.soldiers.values()) {
    if (soldier.state !== "moving") {
      continue;
    }

    if (soldier.side === "left" && soldier.x >= RIGHT_CASTLE_ATTACK_X) {
      soldier.x = RIGHT_CASTLE_ATTACK_X;
      soldier.state = "attacking_castle";
      soldier.attackTimerMs = 0;
      events.push({
        type: "soldier_attacking_castle",
        soldierId: soldier.id,
        side: soldier.side,
      });
    }

    if (soldier.side === "right" && soldier.x <= LEFT_CASTLE_ATTACK_X) {
      soldier.x = LEFT_CASTLE_ATTACK_X;
      soldier.state = "attacking_castle";
      soldier.attackTimerMs = 0;
      events.push({
        type: "soldier_attacking_castle",
        soldierId: soldier.id,
        side: soldier.side,
      });
    }
  }
}

function _resolveEngagements(match, events) {
  const leftSoldiers = [];
  const rightSoldiers = [];

  for (const soldier of match.soldiers.values()) {
    if (soldier.state === "moving" || soldier.state === "attacking_castle") {
      if (soldier.side === "left") {
        leftSoldiers.push(soldier);
      } else {
        rightSoldiers.push(soldier);
      }
    }
  }

  leftSoldiers.sort((a, b) => a.x - b.x);
  rightSoldiers.sort((a, b) => b.x - a.x);

  const engaged = new Set();

  for (const left of leftSoldiers) {
    if (engaged.has(left.id)) continue;

    for (const right of rightSoldiers) {
      if (engaged.has(right.id)) continue;
      if (Math.abs(left.x - right.x) > ENGAGE_DISTANCE) continue;

      left.state = "fighting";
      right.state = "fighting";
      left.targetId = right.id;
      right.targetId = left.id;

      const leftHomeDistance = Math.abs(left.x - LANE_LEFT_X);
      const rightHomeDistance = Math.abs(right.x - LANE_RIGHT_X);

      if (leftHomeDistance <= rightHomeDistance) {
        left.attackTimerMs = 0;
        right.attackTimerMs = right.attackCooldownMs;
      } else {
        right.attackTimerMs = 0;
        left.attackTimerMs = left.attackCooldownMs;
      }

      engaged.add(left.id);
      engaged.add(right.id);

      events.push({
        type: "combat_started",
        leftSoldierId: left.id,
        rightSoldierId: right.id,
      });

      break;
    }
  }
}

function _resolveAttacks(match, deltaMs, events) {
  const pendingSoldierDamage = new Map();
  let pendingCastleDamageLeft = 0;
  let pendingCastleDamageRight = 0;

  const fighters = Array.from(match.soldiers.values()).sort((a, b) =>
    a.id.localeCompare(b.id),
  );

  for (const soldier of fighters) {
    if (soldier.state !== "fighting" && soldier.state !== "attacking_castle") {
      continue;
    }

    soldier.attackTimerMs -= deltaMs;
    if (soldier.attackTimerMs > 0) {
      continue;
    }

    soldier.attackTimerMs = soldier.attackCooldownMs;

    if (soldier.state === "fighting") {
      const target = match.soldiers.get(soldier.targetId);
      if (!target || target.state === "dead") {
        soldier.state = "moving";
        soldier.targetId = null;
        continue;
      }

      const prev = pendingSoldierDamage.get(target.id) || 0;
      pendingSoldierDamage.set(target.id, prev + soldier.damage);

      events.push({
        type: "soldier_attack",
        attackerId: soldier.id,
        targetId: target.id,
        side: soldier.side,
        damage: soldier.damage,
      });
    }

    if (soldier.state === "attacking_castle") {
      if (soldier.side === "left") {
        events.push({
          type: "soldier_attack",
          attackerId: soldier.id,
          targetId: "",
          targetType: "castle",
          side: soldier.side,
          damage: soldier.damage,
        });

        pendingCastleDamageRight += soldier.damage;
        events.push({
          type: "castle_damaged",
          side: "right",
          amount: soldier.damage,
        });
      } else {
        events.push({
          type: "soldier_attack",
          attackerId: soldier.id,
          targetId: "",
          targetType: "castle",
          side: soldier.side,
          damage: soldier.damage,
        });

        pendingCastleDamageLeft += soldier.damage;
        events.push({
          type: "castle_damaged",
          side: "left",
          amount: soldier.damage,
        });
      }
    }
  }

  for (const [targetId, damage] of pendingSoldierDamage.entries()) {
    const target = match.soldiers.get(targetId);
    if (!target || target.state === "dead") {
      continue;
    }

    target.hp -= damage;

    events.push({
      type: "soldier_damaged",
      soldierId: target.id,
      side: target.side,
      hp: Math.max(0, target.hp),
      amount: damage,
    });

    if (target.hp <= 0) {
      target.state = "dead";
    }
  }

  if (pendingCastleDamageLeft > 0) {
    match.castles.left.hp = Math.max(
      0,
      match.castles.left.hp - pendingCastleDamageLeft,
    );
    events.push({
      type: "castle_hp_updated",
      side: "left",
      hp: match.castles.left.hp,
    });
  }

  if (pendingCastleDamageRight > 0) {
    match.castles.right.hp = Math.max(
      0,
      match.castles.right.hp - pendingCastleDamageRight,
    );
    events.push({
      type: "castle_hp_updated",
      side: "right",
      hp: match.castles.right.hp,
    });
  }
}

function _cleanupDeadSoldiers(match, events) {
  const toDelete = [];

  for (const soldier of match.soldiers.values()) {
    if (soldier.state !== "dead") {
      continue;
    }

    match.stats[soldier.side].soldiersDied += 1;
    toDelete.push(soldier.id);

    events.push({
      type: "soldier_died",
      soldierId: soldier.id,
      side: soldier.side,
    });
  }

  for (const deadId of toDelete) {
    match.soldiers.delete(deadId);

    for (const survivor of match.soldiers.values()) {
      if (survivor.targetId === deadId) {
        survivor.targetId = null;
        if (survivor.state === "fighting") {
          survivor.state = "moving";
        }
      }
    }
  }
}

function _serializeSoldiers(match) {
  return Array.from(match.soldiers.values()).map((soldier) => ({
    id: soldier.id,
    side: soldier.side,
    x: soldier.x,
    hp: soldier.hp,
    state: soldier.state,
    targetId: soldier.targetId,
  }));
}

module.exports = {
  SIM_TICK_MS,
  createSoldier,
  simulateCombatTick,
};
