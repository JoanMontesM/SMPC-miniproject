import processing.sound.*;
SoundFile audio;

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

int currentExcerpt = 0;

int idx = 0;

boolean audioOn = true;

// Visuals (size from RMS)
float BASE_RADIUS = 10;
float RADIUS_RANGE = 390;

// Smooth radius (frame-based)
float radiusSmooth = 0;
final float RADIUS_ALPHA = 0.20;

// Smooth centroid (frame-based)
float centSmooth = 0;
final float CENT_ALPHA = 0.10;

// Smooth color
color colorSmooth;
final float COLOR_ALPHA = 0.08;

void setup() {
  size(800, 800);
  smooth();
  colorMode(HSB, 360, 100, 100, 100);
  loadExcerpt(0);
}

void draw() {
  background(0);

  if (audio == null || table == null) return;

  float nowSec = audio.position();

  float lastT = table.getFloat(table.getRowCount() - 1, "t");
  if (nowSec >= lastT) {
    exit();
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

  float rms = lerp(rms0, rms1, a);
  float cent = lerp(c0, c1, a);

  float rms01 = constrain(rms, 0, 1);
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

  noStroke();
  fill(colorSmooth);
  ellipse(width/2, height/2, radiusSmooth*2, radiusSmooth*2);

  fill(0, 0, 100, 70);
  text("Excerpt: " + (currentExcerpt+1) + " | Audio: " + (audioOn ? "ON" : "OFF") + "  (1-4 / A)", 12, height - 12);
}

void keyPressed() {
  if (key == '1') loadExcerpt(0);
  if (key == '2') loadExcerpt(1);
  if (key == '3') loadExcerpt(2);
  if (key == '4') loadExcerpt(3);

  if (key == 'a' || key == 'A') {
    audioOn = !audioOn;
    if (audio != null) {
      audio.amp(audioOn ? 1.0 : 0.0);
    }
  }
}

void loadExcerpt(int n) {
  n = constrain(n, 0, 3);
  currentExcerpt = n;

  if (audio != null) {
    audio.stop();
  }

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

  audio.amp(audioOn ? 1.0 : 0.0);
}
