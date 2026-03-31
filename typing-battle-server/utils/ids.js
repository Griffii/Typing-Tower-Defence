function generateLobbyCode(existingLobbies, length = 5) {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

  let code;
  do {
    code = "";
    for (let i = 0; i < length; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
  } while (existingLobbies.has(code));

  return code;
}

module.exports = { generateLobbyCode };
