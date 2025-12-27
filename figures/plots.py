import os
import pandas as pd
import matplotlib.pyplot as plt
    
df1 = pd.read_csv("features/excerpt01_features.csv")
df2 = pd.read_csv("features/excerpt03_features.csv")
   
plt.figure(figsize=(12, 7.2))

ax1 = plt.subplot(2, 1, 1)
ax1.plot(df1["t"], df1["rms"], label="RMS (normalized)")
ax1.plot(df1["t"], df1["centroid"], label="Spectral Centroid (normalized)")
ax1.set_title("RMS and Spectral Centroid curves from Excerpt 1")
ax1.set_ylabel("Value (0–1)")
ax1.set_ylim(-0.05, 1.05)
ax1.legend()

ax2 = plt.subplot(2, 1, 2)
ax2.plot(df2["t"], df2["rms"], label="RMS (normalized)")
ax2.plot(df2["t"], df2["centroid"], label="Spectral Centroid (normalized)")
ax2.set_title("RMS and Spectral Centroid curves from Excerpt 3")
ax2.set_xlabel("Time (s)")
ax2.set_ylabel("Value (0–1)")
ax2.set_ylim(-0.05, 1.05)
ax2.legend()

plt.tight_layout()
plt.savefig("excerpt1_vs_excerpt3_rms_centroid.png", dpi=200)
plt.close()

