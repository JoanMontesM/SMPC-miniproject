import processing.sound.*;
SoundFile audio;

PFont uiFont;
float TEXT_SMALL  = 16;
float TEXT_LARGE  = 22;

Table table;

String[] wavFiles = {
  "excerpt01.wav",
  "excerpt02.wav",
  "excerpt03.wav",
  "excerpt04.wav"
};

String[] csvFiles = {
  "excerpt01_features.csv",
  "excerpt02_features.csv",
  "excerpt03_features.csv",
  "excerpt04_features.csv"
};

// examples (demo)
String EX_WAV_1 = "excerpt_example2.wav";
String EX_CSV_1 = "excerpt_example2_features.csv";
String EX_WAV_2 = "excerpt_example1.wav";
String EX_CSV_2 = "excerpt_example1_features.csv";

// intro text you can edit
String INTRO_TEXT =
  "INSTRUCTIONS:\n\n" +
  "In this study, you will see and hear a series of short stimuli.\n" +
  "The visualizations are automatically generated from the features \n" +
  "of the corresponding audio.\n" +
  "After each stimulus, your task is to indicate \n" +
  "how it made you feel using the scales indicated in the questionnaire.\n\n" +
  "There are no right or wrong answers, \n" +
  "I am interested in your immediate and subjective experience.\n" +
  "Please keep your attention on the screen during each stimulus,\n" + 
  "and respond as soon as it ends.\n\n" +
  "Now you will see two short examples to familiarize with the type of visuals.\n" +
  "Keep in mind that the visualizations are intentionally simple and abstract.\n\n" +
  "Thank you so much for participating in this exploratory study";

// --------- Playback / experiment logic ----------
int PHASE_AV       = 0;
int PHASE_VIS_ONLY = 1;

int phase = PHASE_AV;

int[] orderAV;
int[] orderVis;
int orderPos = 0;

boolean audioOn = true;
boolean frozenAtEnd = false;

int idx = 0;

// screen flow
final int SCREEN_INTRO = 0;
final int SCREEN_EX1   = 1;
final int SCREEN_EX2   = 2;
final int SCREEN_START = 3;
final int SCREEN_PLAY  = 4;
final int SCREEN_QUEST = 5;

int screenState = SCREEN_INTRO;

int currentExcerpt = 0;

// --------- Visuals ----------
float BASE_RADIUS = 10;
float RADIUS_RANGE = 390;

float radiusSmooth = 0;
final float RADIUS_ALPHA = 0.20;

float centSmooth = 0;
final float CENT_ALPHA = 0.10;

color colorSmooth;
final float COLOR_ALPHA = 0.08;

void setup() {
  size(800, 800);
  smooth();
  colorMode(HSB, 360, 100, 100, 100);

  orderAV  = shuffledOrder(4);
  orderVis = shuffledOrder(4);

  phase = PHASE_AV;
  orderPos = 0;

  screenState = SCREEN_INTRO;
}

void draw() {
  background(0);

  if (screenState == SCREEN_INTRO) {
    drawCenteredMessage(INTRO_TEXT + "\n\nPress \"SPACE\" to watch the two short examples.");
    return;
  }

  if (screenState == SCREEN_EX1) {
    if (audio == null || table == null) return;

    updateFromAudioTime();
    noStroke();
    fill(colorSmooth);
    ellipse(width/2, height/2, radiusSmooth*2, radiusSmooth*2);

    drawTopLeftLabel("Example 1: ONLY VISUALS");

    if (frozenAtEnd) {
      startExample2();
    }
    return;
  }

  if (screenState == SCREEN_EX2) {
    if (audio == null || table == null) return;

    updateFromAudioTime();
    noStroke();
    fill(colorSmooth);
    ellipse(width/2, height/2, radiusSmooth*2, radiusSmooth*2);

    drawTopLeftLabel("Example 2: AUDIO + VISUALS");

    if (frozenAtEnd) {
      if (audio != null) audio.stop();
      audio = null;
      table = null;
      frozenAtEnd = false;
      screenState = SCREEN_START;
    }
    return;
  }

  if (screenState == SCREEN_START) {
    drawCenteredMessage("Press \"SPACE\" to initiate the visuals");
    return;
  }

  if (screenState == SCREEN_QUEST) {
    drawCornerExcerptLabel();
    drawCenteredMessage("Now you need to answer some questions in the questionnaire.\n\nPress \"SPACE\" to continue");
    return;
  }

  if (audio == null || table == null) return;

  if (!frozenAtEnd) {
    updateFromAudioTime();
  }

  noStroke();
  fill(colorSmooth);
  ellipse(width/2, height/2, radiusSmooth*2, radiusSmooth*2);

  drawCornerExcerptLabel();

  fill(0, 0, 100, 70);
  String phaseName = (phase == PHASE_VIS_ONLY) ? "VISUALS ONLY" : "AUDIO+VISUALS";
  String audioName = audioOn ? "ON" : "OFF";
  String msg = "Phase: " + phaseName
    + " | Audio: " + audioName
    + " | Clip " + (orderPos+1) + "/4"
    + (frozenAtEnd ? "  [ENDED]" : "");
  text(msg, 12, height - 12);
}

void keyPressed() {

  if (key == ' ') {

    if (screenState == SCREEN_INTRO) {
      startExample1();
      return;
    }

    if (screenState == SCREEN_START) {
      // IMPORTANT: this condition starts with AV first
      startExcerpt(getCurrentExcerptIndex(), true);
      screenState = SCREEN_PLAY;
      return;
    }

    if (screenState == SCREEN_QUEST) {
      advanceToNextClip();
      screenState = SCREEN_PLAY;
      return;
    }

    if (screenState == SCREEN_PLAY && frozenAtEnd) {
      advanceToNextClip();
      return;
    }
  }

  if (key == 'r' || key == 'R') {
    resetExperiment();
  }
}

void startExample1() {
  loadCustom(EX_CSV_1, EX_WAV_1, false);
  screenState = SCREEN_EX1;
}

void startExample2() {
  frozenAtEnd = false;
  loadCustom(EX_CSV_2, EX_WAV_2, true);
  screenState = SCREEN_EX2;
}

void loadCustom(String csvName, String wavName, boolean wantAudio) {
  if (audio != null) audio.stop();

  table = loadTable(csvName, "header");
  if (table == null || table.getRowCount() < 2) {
    println("Error loading CSV: " + csvName + " (need at least 2 rows)");
    exit();
  }

  idx = 0;
  radiusSmooth = BASE_RADIUS;
  centSmooth = table.getFloat(0, "centroid");
  colorSmooth = color(0, 0, 0, 100);

  audio = new SoundFile(this, wavName);
  audio.play();

  audioOn = wantAudio;
  audio.amp(audioOn ? 1.0 : 0.0);

  frozenAtEnd = false;
}

void resetExperiment() {
  if (audio != null) audio.stop();

  orderAV  = shuffledOrder(4);
  orderVis = shuffledOrder(4);

  phase = PHASE_AV;
  orderPos = 0;

  frozenAtEnd = false;
  screenState = SCREEN_INTRO;
}

int getCurrentExcerptIndex() {
  if (phase == PHASE_AV) return orderAV[orderPos];
  else return orderVis[orderPos];
}

void advanceToNextClip() {
  frozenAtEnd = false;
  orderPos++;

  if (orderPos >= 4) {
    if (phase == PHASE_AV) {
      phase = PHASE_VIS_ONLY;
      orderPos = 0;
      startExcerpt(getCurrentExcerptIndex(), false);
    } else {
      exit();
    }
    return;
  }

  boolean wantAudio = (phase == PHASE_AV);
  startExcerpt(getCurrentExcerptIndex(), wantAudio);
}

void startExcerpt(int n, boolean wantAudio) {
  currentExcerpt = n;

  if (audio != null) audio.stop();

  table = loadTable(csvFiles[n], "header");
  if (table == null || table.getRowCount() < 2) {
    println("Error loading CSV: " + csvFiles[n] + " (need at least 2 rows)");
    exit();
  }

  idx = 0;
  radiusSmooth = BASE_RADIUS;
  centSmooth = table.getFloat(0, "centroid");
  colorSmooth = color(0, 0, 0, 100);

  audio = new SoundFile(this, wavFiles[n]);
  audio.play();

  audioOn = wantAudio;
  audio.amp(audioOn ? 1.0 : 0.0);

  frozenAtEnd = false;
}

void updateFromAudioTime() {
  float nowSec = audio.position();
  float lastT = table.getFloat(table.getRowCount() - 1, "t");

  if (nowSec >= lastT) {
    audio.pause();
    frozenAtEnd = true;

    if (screenState == SCREEN_PLAY) {
      screenState = SCREEN_QUEST;
    }
    return;
  }

  while (idx < table.getRowCount() - 2 && table.getFloat(idx + 1, "t") <= nowSec) {
    idx++;
  }

  float t0 = table.getFloat(idx, "t");
  float t1 = table.getFloat(idx + 1, "t");

  float rms0  = table.getFloat(idx, "rms");
  float rms1  = table.getFloat(idx + 1, "rms");

  float c0 = table.getFloat(idx, "centroid");
  float c1 = table.getFloat(idx + 1, "centroid");

  float a = 0.0;
  float dt = t1 - t0;
  if (dt > 0.000001) a = (nowSec - t0) / dt;
  a = constrain(a, 0, 1);

  float rms  = lerp(rms0, rms1, a);
  float cent = lerp(c0, c1, a);

  float rms01  = constrain(rms, 0, 1);
  float cent01 = constrain(cent, 0, 1);

  float radiusTarget = BASE_RADIUS + RADIUS_RANGE * rms01;
  radiusSmooth = lerp(radiusSmooth, radiusTarget, RADIUS_ALPHA);

  centSmooth = centSmooth + CENT_ALPHA * (cent01 - centSmooth);
  float c = constrain(centSmooth, 0, 1);

  final float T1 = 0.08;
  final float T2 = 0.15;

  float hue, sat, bright;

  if (c < T1) {
    float u = c / T1;
    hue    = lerp(280, 210, u);
    bright = lerp(20, 40, u);
    sat    = lerp(90, 85, u);
  } else if (c < T2) {
    float u = (c - T1) / (T2 - T1);
    hue    = lerp(210, 170, u);
    bright = lerp(40, 75, u);
    sat    = lerp(85, 70, u);
  } else {
    float u = (c - T2) / (1.0 - T2);
    hue    = lerp(60, 50, u);
    bright = lerp(75, 100, u);
    sat    = lerp(60, 5, u);
  }

  color colorTarget = color(hue, sat, bright, 100);
  colorSmooth = lerpColor(colorSmooth, colorTarget, COLOR_ALPHA);
}

void drawCornerExcerptLabel() {
  fill(0, 0, 100, 80);
  textAlign(LEFT, TOP);
  textSize(TEXT_SMALL);
  text("Excerpt: " + (currentExcerpt + 1), 12, 12);
}

void drawTopLeftLabel(String s) {
  fill(0, 0, 100, 80);
  textAlign(LEFT, TOP);
  textSize(TEXT_SMALL);
  text(s, 12, 12);
}

void drawCenteredMessage(String msg) {
  fill(0, 0, 100, 90);
  textAlign(CENTER, CENTER);
  textSize(TEXT_LARGE);
  text(msg, width/2, height/2);
}

int[] shuffledOrder(int n) {
  int[] arr = new int[n];
  for (int i = 0; i < n; i++) arr[i] = i;

  for (int i = n - 1; i > 0; i--) {
    int j = int(random(i + 1));
    int tmp = arr[i];
    arr[i] = arr[j];
    arr[j] = tmp;
  }
  return arr;
}
