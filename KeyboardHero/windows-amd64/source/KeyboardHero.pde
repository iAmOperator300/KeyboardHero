// HIGH SCORE: 1500 - iAmOperator
// Scores: 1350 - iAmOperator, 1230 - iAmOperator, 800 - iAmOperator, 580 - iAmOperator

// Import the ArrayList library
import java.util.ArrayList;

// === GAME STATE MANAGEMENT ===
// An enumeration to manage the different states of the game
enum GameState {
  MAIN_MENU,
  PLAYING,
  PAUSED,
  LEVEL_END,
  GAME_OVER
}
GameState currentState = GameState.MAIN_MENU;

// === DIFFICULTY SETTINGS ===
enum Difficulty {
  EASY,
  MEDIUM,
  HARD
}
Difficulty currentDifficulty = Difficulty.MEDIUM;
int attemptNumber = 1; // To be incremented with each new game

// === CORE GAME VARIABLES ===
int score = 0;
int totalScore = 0;
int level = 1;
float gameSpeed; // Initial speed of the targets
int maxNotesInChord; // Max notes that can spawn at once
boolean allowSameColorChords; // Difficulty setting for chords

int deathPoints = 0;
final int MAX_DEATH_POINTS = 25;

// === TIMING ===
int levelDuration = 30000; // 30 seconds in milliseconds
int levelStartTime;
int levelEndTransitionTime; // To time the "Level End" screen
ArrayList<Long> spawnTimestamps; // To track spawn rate
int MAX_SPAWNS_PER_SECOND = 1; // Increased to allow for harder difficulties

// === TARGETS & LANES ===
ArrayList<Target> targets; // List to hold all active targets
final int NUM_LANES = 8;
float laneWidth;
long[] laneCooldowns = new long[NUM_LANES]; // To track when a target last appeared in a lane
final int TARGET_COOLDOWN = 1000; // Reduced cooldown to allow for more notes
final int TARGET_DIAMETER = 50;
final int TARGET_RADIUS = TARGET_DIAMETER / 2;

// === HIT ZONE ===
// Make the green box taller (1.5x the size of a target)
final int HIT_ZONE_HEIGHT = (int)(TARGET_DIAMETER * 1.5);
int hitZoneY;

// === COLORS ===
// Symmetrical colors: a-;, s-l, d-k, f-j
color[] laneColors = {
  color(255, 0, 0),    // Red (A)
  color(0, 0, 255),    // Blue (S)
  color(255, 255, 0),  // Yellow (D)
  color(0, 255, 255),  // Cyan (F)
  color(0, 255, 255),  // Cyan (J)
  color(255, 255, 0),  // Yellow (K)
  color(0, 0, 255),    // Blue (L)
  color(255, 0, 0)     // Red (;)
};
color hitZoneColor = color(0, 150, 0, 150); // Translucent green
color separatorColor = color(50);
color bgColor = color(10);

// === KEYS ===
char[] keys = {'a', 's', 'd', 'f', 'j', 'k', 'l', ';'};

// =================================================================================
// SETUP FUNCTION: Runs once when the program starts
// =================================================================================
void setup() {
  size(800, 600); // Set the window size
  
  // Initialize game variables
  targets = new ArrayList<Target>();
  spawnTimestamps = new ArrayList<Long>();
  laneWidth = (float)width / NUM_LANES;
  hitZoneY = height - HIT_ZONE_HEIGHT;
  
  applyDifficulty(currentDifficulty); // Set initial difficulty
  
  textAlign(CENTER, CENTER);
  textSize(24);
}

/**
 * Resets all game variables to start a fresh game.
 */
void resetGame() {
  score = 0;
  totalScore = 0;
  level = 1;
  deathPoints = 0;
  targets.clear();
  spawnTimestamps.clear();
  
  applyDifficulty(currentDifficulty); // Apply selected difficulty settings
  
  // Initialize all lane cooldowns to 0
  for (int i = 0; i < NUM_LANES; i++) {
    laneCooldowns[i] = 0;
  }
  
  levelStartTime = millis(); // Start the first level timer
  currentState = GameState.PLAYING;
}


// =================================================================================
// DRAW FUNCTION: Main game loop, runs continuously
// =================================================================================
void draw() {
  // Use a switch statement to handle different game states
  switch (currentState) {
    case MAIN_MENU:
      showMainMenu();
      break;
    case PLAYING:
      runGame();
      break;
    case PAUSED:
      showPauseMenu();
      break;
    case LEVEL_END:
      showLevelEndScreen();
      break;
    case GAME_OVER:
      showGameOverScreen();
      break;
  }
}

// =================================================================================
// GAME LOGIC & STATE SCREENS
// =================================================================================

/**
 * Manages all game logic while in the PLAYING state.
 */
void runGame() {
  background(bgColor); // Clear the screen with a dark background
  
  // --- Draw Game Elements ---
  drawLanes();
  drawHitZone();
  
  // --- Game Logic ---
  spawnNewTargets();
  updateAndDrawTargets();
  checkLevelTimer();
  checkDeathPoints(); // Check if the game should end due to mistakes
  
  // --- Display UI ---
  drawHUD();
}

/**
 * Displays the main menu with Play, Settings, and Exit buttons.
 */
void showMainMenu() {
  background(bgColor);
  textSize(72);
  fill(255);
  text("Keyboard Hero", width / 2, height / 2 - 150);
  
  // Simple buttons
  textSize(40);
  // Play Button
  if (mouseX > 300 && mouseX < 500 && mouseY > 300 && mouseY < 350) {
    fill(255, 255, 0); // Highlight
  } else {
    fill(255);
  }
  text("Play", width / 2, 325);
  
  // Settings Button
  if (mouseX > 300 && mouseX < 500 && mouseY > 380 && mouseY < 430) {
    fill(255, 255, 0);
  } else {
    fill(255);
  }
  text("Settings", width/2, 405);
  
  // Exit Button
   if (mouseX > 300 && mouseX < 500 && mouseY > 460 && mouseY < 510) {
    fill(255, 255, 0);
  } else {
    fill(255);
  }
  text("Exit", width/2, 485);
}

/**
 * Displays the pause menu, which also includes difficulty settings.
 */
void showPauseMenu() {
    background(bgColor);
    textSize(64);
    fill(255);
    text("Paused", width / 2, height / 2 - 150);
    
    textSize(32);
    text("Difficulty:", width / 2, height / 2 - 50);
    
    // Difficulty options
    // Easy
    if (currentDifficulty == Difficulty.EASY) fill(0, 255, 0); else fill(255);
    if (mouseX > 150 && mouseX < 250 && mouseY > 350 && mouseY < 390) fill(255, 255, 0);
    text("Easy", 200, 370);
    
    // Medium
    if (currentDifficulty == Difficulty.MEDIUM) fill(0, 255, 0); else fill(255);
    if (mouseX > 350 && mouseX < 450 && mouseY > 350 && mouseY < 390) fill(255, 255, 0);
    text("Medium", 400, 370);
    
    // Hard
    if (currentDifficulty == Difficulty.HARD) fill(0, 255, 0); else fill(255);
    if (mouseX > 550 && mouseX < 650 && mouseY > 350 && mouseY < 390) fill(255, 255, 0);
    text("Hard", 600, 370);

    textSize(28);
    fill(255);
    text("Press 'P' to Resume", width / 2, height - 50);
}


/**
 * Displays the screen shown between levels.
 */
void showLevelEndScreen() {
  background(bgColor);
  textSize(48);
  fill(255);
  text("Level " + (level - 1) + " Complete!", width / 2, height / 2 - 50);
  textSize(32);
  text("Level Score: " + score, width / 2, height / 2 + 20);
  
  // Wait for 3 seconds before starting the next level
  if (millis() - levelEndTransitionTime > 3000) {
    totalScore += score; // Add level score to total
    score = 0; // Reset score for the next level
    levelStartTime = millis(); // Reset the level timer
    currentState = GameState.PLAYING; // Go back to playing
  }
}

/**
 * Displays the final game over screen with logged data.
 */
void showGameOverScreen() {
  background(bgColor);
  fill(255, 0, 0);
  textSize(64);
  text("GAME OVER", width / 2, height / 2 - 150);
  
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(32);
  
  // Log final game data
  text("Attempt #: " + attemptNumber, 250, height / 2 - 40);
  text("Difficulty: " + currentDifficulty, 250, height / 2 + 10);
  text("Final Score: " + totalScore, 250, height/2 + 60);
  text("Mistakes: " + deathPoints + " / " + MAX_DEATH_POINTS, 250, height/2 + 110);
  text("Ended on Level: " + level, 250, height/2 + 160);
  
  textAlign(CENTER, CENTER); // Reset alignment
  textSize(24);
  text("Press any key to return to Main Menu", width/2, height - 50);
  
  noLoop(); // Stop the draw loop
}

// =================================================================================
// DRAWING & UI HELPER FUNCTIONS
// =================================================================================

/**
 * Draws the vertical lane dividers.
 */
void drawLanes() {
  stroke(separatorColor);
  strokeWeight(2);
  for (int i = 1; i < NUM_LANES; i++) {
    float x = i * laneWidth;
    line(x, 0, x, height);
  }
}

/**
 * Draws the green hit zone at the bottom of the screen.
 */
void drawHitZone() {
  noStroke();
  fill(hitZoneColor);
  rect(0, hitZoneY, width, HIT_ZONE_HEIGHT);
}

/**
 * Draws the Heads-Up Display (Score, Level, Time, Mistakes).
 */
void drawHUD() {
  textSize(20);
  fill(255);
  textAlign(LEFT, TOP);
  text("Score: " + score, 10, 10);
  text("Level: " + level, 10, 35);
  
  // Display death points
  fill(255, 100, 100); // Make mistakes stand out in red
  text("Mistakes: " + deathPoints + " / " + MAX_DEATH_POINTS, 10, 60);
  
  // Calculate and display time remaining in the level
  fill(255);
  int timePassed = millis() - levelStartTime;
  int timeRemaining = (levelDuration - timePassed) / 1000;
  textAlign(RIGHT, TOP);
  text("Time: " + timeRemaining, width - 10, 10);
  
  textAlign(CENTER, CENTER); // Reset alignment for other text
}


// =================================================================================
// TARGET MANAGEMENT & DIFFICULTY
// =================================================================================

/**
 * Sets game variables based on the chosen difficulty.
 */
void applyDifficulty(Difficulty d) {
    currentDifficulty = d;
    switch(d) {
        case EASY:
            gameSpeed = 1.5;
            maxNotesInChord = 1;
            MAX_SPAWNS_PER_SECOND = 1;
            allowSameColorChords = false;
            break;
        case MEDIUM:
            gameSpeed = 3;
            maxNotesInChord = 3;
            MAX_SPAWNS_PER_SECOND = 1;
            allowSameColorChords = false;
            break;
        case HARD:
            MAX_SPAWNS_PER_SECOND = 1;
            gameSpeed = 3.5;
            maxNotesInChord = 4;
            allowSameColorChords = true;
            MAX_SPAWNS_PER_SECOND = 2;
            break;
    }
}


/**
 * Randomly spawns new targets based on difficulty settings.
 */
void spawnNewTargets() {
  long currentTime = millis();
  for (int i = spawnTimestamps.size() - 1; i >= 0; i--) {
    if (currentTime - spawnTimestamps.get(i) > 1000) {
      spawnTimestamps.remove(i);
    }
  }

  if (random(1) < 0.05) {
    int notesInChord = int(random(1, maxNotesInChord + 1));
    ArrayList<Integer> usedLanesInChord = new ArrayList<Integer>();
    ArrayList<Integer> usedColorsInChord = new ArrayList<Integer>();

    for (int i = 0; i < notesInChord; i++) {
      if (spawnTimestamps.size() >= MAX_SPAWNS_PER_SECOND) {
        break; 
      }

      int attempts = 0;
      int lane;
      boolean laneIsValid;
      do {
        lane = int(random(NUM_LANES));
        attempts++;
        
        // Check all conditions for a valid lane
        boolean isOnCooldown = millis() - laneCooldowns[lane] < TARGET_COOLDOWN;
        boolean isAlreadyUsedInChord = usedLanesInChord.contains(lane);
        boolean isColorAlreadyUsed = !allowSameColorChords && usedColorsInChord.contains(laneColors[lane]);

        laneIsValid = !isOnCooldown && !isAlreadyUsedInChord && !isColorAlreadyUsed;

      } while (!laneIsValid && attempts < 20);
      
      if (laneIsValid) {
        float x = lane * laneWidth + (laneWidth / 2);
        float y = -TARGET_RADIUS;
        color c = laneColors[lane];
        targets.add(new Target(x, y, gameSpeed, c, lane));
        
        laneCooldowns[lane] = millis();
        spawnTimestamps.add((long) millis());
        usedLanesInChord.add(lane);
        if (!allowSameColorChords) {
          usedColorsInChord.add(c);
        }
      }
    }
  }
}


/**
 * Updates the position of all targets and draws them.
 * Also removes targets that have gone off-screen and penalizes for misses.
 */
void updateAndDrawTargets() {
  // Iterate backwards to safely remove items from the list while iterating
  for (int i = targets.size() - 1; i >= 0; i--) {
    Target t = targets.get(i);
    t.update();
    t.display();
    
    // PENALTY: Check for missed targets that have passed the hit zone
    if (!t.wasHit && !t.missed && t.y > hitZoneY + HIT_ZONE_HEIGHT) {
      deathPoints++;
      t.missed = true; // Mark as missed to avoid multiple penalties
    }
    
    // If a target is completely off the bottom of the screen, remove it
    if (t.y > height + t.radius) {
      targets.remove(i);
    }
  }
}

// =================================================================================
// GAME STATE AND INPUT HANDLING
// =================================================================================

/**
 * Checks if the 30-second level duration has passed.
 */
void checkLevelTimer() {
  if (millis() - levelStartTime > levelDuration) {
    level++;
    gameSpeed += 0.5; // Increase game speed for the next level
    currentState = GameState.LEVEL_END;
    levelEndTransitionTime = millis(); // Start the transition timer
  }
}

/**
 * Checks if the player has made too many mistakes.
 */
void checkDeathPoints() {
  if (deathPoints >= MAX_DEATH_POINTS) {
    totalScore += score; // Add current score to total before ending
    currentState = GameState.GAME_OVER;
    loop(); // Ensure the draw loop is running for the game over screen
  }
}

/**
 * Handles mouse clicks for UI interaction.
 */
void mousePressed() {
    if (currentState == GameState.MAIN_MENU) {
        // Play Button
        if (mouseX > 300 && mouseX < 500 && mouseY > 300 && mouseY < 350) {
            resetGame();
        }
        // Settings Button
        else if (mouseX > 300 && mouseX < 500 && mouseY > 380 && mouseY < 430) {
            currentState = GameState.PAUSED; // Go to the pause/settings screen
        }
        // Exit Button
        else if (mouseX > 300 && mouseX < 500 && mouseY > 460 && mouseY < 510) {
            exit();
        }
    } else if (currentState == GameState.PAUSED) {
        // Easy
        if (mouseX > 150 && mouseX < 250 && mouseY > 350 && mouseY < 390) {
            applyDifficulty(Difficulty.EASY);
        }
        // Medium
        else if (mouseX > 350 && mouseX < 450 && mouseY > 350 && mouseY < 390) {
            applyDifficulty(Difficulty.MEDIUM);
        }
        // Hard
        else if (mouseX > 550 && mouseX < 650 && mouseY > 350 && mouseY < 390) {
            applyDifficulty(Difficulty.HARD);
        }
    }
}


/**
 * Handles all keyboard input from the player.
 */
void keyPressed() {
  // If on game over screen, any key returns to menu
  if (currentState == GameState.GAME_OVER) {
    attemptNumber++; // Increment for the next playthrough
    currentState = GameState.MAIN_MENU;
    loop(); // Restart the draw loop
    return;
  }
  
  // Pause/Unpause functionality
  if (key == 'p' || key == 'P') {
      if (currentState == GameState.PLAYING) {
          currentState = GameState.PAUSED;
      } else if (currentState == GameState.PAUSED) {
          currentState = GameState.PLAYING;
          levelStartTime = millis() - (levelDuration - (levelDuration - (millis() - levelStartTime))); // Recalculate start time to not lose progress
      }
      return;
  }

  // Pressing SPACE ends the game at any time
  if (key == ' ') {
    if (currentState == GameState.PLAYING) {
        totalScore += score; // Add current score to total before ending
    }
    currentState = GameState.GAME_OVER;
    loop();
    return; // Exit the function early
  }
  
  // Only process note hits if the game is in the PLAYING state
  if (currentState == GameState.PLAYING) {
    int laneHit = -1;
    // Find which lane corresponds to the key pressed
    for (int i = 0; i < keys.length; i++) {
      if (key == keys[i]) {
        laneHit = i;
        break;
      }
    }
    
    // If a valid key was pressed
    if (laneHit != -1) {
      //boolean successfulHit = false;
      Target targetToHit = null;
      float highestY = -1;
      
      // Find the lowest (highest Y value) unhit target in the correct lane
      for (Target t : targets) {
        if (t.lane == laneHit && !t.wasHit && t.y > highestY) {
            highestY = t.y;
            targetToHit = t;
        }
      }
      
      // If a target was found, check if it's a valid hit
      if (targetToHit != null) {
          // A hit is successful if it's in the hit zone
          if(targetToHit.isHittable()) {
              score += 10; // Increase score
              targetToHit.wasHit = true; // Mark the target as hit
              //successfulHit = true;
          } else {
              // If it's not in the hit zone, it's a miss, but the puck still gets "blanked out"
              targetToHit.wasHit = true; // Visually blanks out the puck
              deathPoints++; // Penalize for bad timing
              //successfulHit = false; // This was not a successful *scoring* hit
          }
      }
      
      // PENALTY: If the key was pressed but there was no target in that lane at all
      if (targetToHit == null) {
        deathPoints++;
      }
    }
  }
}


// =================================================================================
// TARGET CLASS
// Defines the properties and behavior of a single target (note).
// =================================================================================
class Target {
  float x, y;
  float speed;
  color c;
  int radius;
  int lane;
  boolean wasHit; // To prevent scoring multiple times on the same target
  boolean missed; // To prevent multiple penalties for the same missed note

  Target(float x, float y, float speed, color c, int lane) {
    this.x = x;
    this.y = y;
    this.speed = speed;
    this.c = c;
    this.lane = lane;
    this.radius = TARGET_RADIUS;
    this.wasHit = false;
    this.missed = false;
  }

  /**
   * Updates the target's vertical position.
   */
  void update() {
    y += speed;
  }

  /**
   * Draws the target on the screen. If it was hit, draw it differently.
   */
  void display() {
    stroke(255);
    strokeWeight(2);
    // If the target was successfully hit, show a visual confirmation (e.g., white fill)
    if (wasHit) {
      fill(255, 255, 255, 200);
    } else {
      fill(c);
    }
    ellipse(x, y, radius * 2, radius * 2);
  }

  /**
   * Checks if the target is currently within the scorable hit zone.
   * A target is hittable if its center is inside the green box.
   * @return true if the target is in the hit zone, false otherwise.
   */
  boolean isHittable() {
    // The target is hittable if its center is within the vertical bounds of the hit zone.
    return (y > hitZoneY && y < hitZoneY + HIT_ZONE_HEIGHT);
  }
}
