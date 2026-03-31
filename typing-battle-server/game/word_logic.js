const WORDS = [
  // colors
  "red",
  "blue",
  "green",
  "yellow",
  "orange",
  "purple",
  "pink",
  "brown",
  "black",
  "white",
  "gray",
  "silver",
  "gold",
  "navy",
  "teal",
  "cyan",
  "lime",
  "maroon",
  "beige",
  "violet",

  // shapes
  "circle",
  "square",
  "triangle",
  "rectangle",
  "oval",
  "diamond",
  "star",
  "heart",
  "pentagon",
  "hexagon",
  "octagon",
  "sphere",
  "cube",
  "cylinder",
  "cone",

  // animals
  "cat",
  "dog",
  "lion",
  "tiger",
  "bear",
  "wolf",
  "fox",
  "rabbit",
  "monkey",
  "zebra",
  "giraffe",
  "elephant",
  "panda",
  "koala",
  "kangaroo",
  "horse",
  "cow",
  "sheep",
  "goat",
  "deer",
  "mouse",
  "frog",
  "snake",
  "eagle",
  "shark",
  "whale",
  "dolphin",
  "penguin",
  "owl",
  "parrot",

  // fruits
  "apple",
  "banana",
  "orange",
  "grape",
  "melon",
  "peach",
  "pear",
  "plum",
  "mango",
  "lemon",
  "lime",
  "cherry",
  "berry",
  "kiwi",
  "papaya",
  "guava",
  "apricot",
  "coconut",
  "fig",
  "date",

  // vegetables
  "carrot",
  "potato",
  "tomato",
  "onion",
  "garlic",
  "pepper",
  "cabbage",
  "lettuce",
  "spinach",
  "broccoli",
  "celery",
  "radish",
  "pumpkin",
  "corn",
  "pea",
  "bean",
  "turnip",
  "cucumber",
  "zucchini",
  "eggplant",

  // sports
  "soccer",
  "tennis",
  "baseball",
  "basketball",
  "golf",
  "rugby",
  "hockey",
  "boxing",
  "cycling",
  "running",
  "swimming",
  "skating",
  "skiing",
  "surfing",
  "volleyball",
  "badminton",
  "archery",
  "wrestling",
  "bowling",
  "karate",
];

function shuffleArray(source) {
  const arr = [...source];
  for (let i = arr.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function createWordBag() {
  return {
    deck: shuffleArray(WORDS),
    index: 0,
  };
}

function drawWord(wordBag) {
  if (!wordBag || !Array.isArray(wordBag.deck)) {
    throw new Error("Invalid word bag");
  }

  if (wordBag.index >= wordBag.deck.length) {
    wordBag.deck = shuffleArray(WORDS);
    wordBag.index = 0;
  }

  const text = wordBag.deck[wordBag.index];
  wordBag.index += 1;

  return {
    wordId: `w_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
    text,
  };
}

function normalize(str) {
  return (str || "").trim().toLowerCase();
}

module.exports = {
  WORDS,
  createWordBag,
  drawWord,
  normalize,
};