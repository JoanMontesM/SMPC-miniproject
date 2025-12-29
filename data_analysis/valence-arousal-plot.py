import matplotlib.pyplot as plt
import pandas as pd

visualData = {
    "Excerpt": [1, 2, 3, 4],
    "Valence": [4.642857143, 4.785714286, 6.0, 5.571428571],
    "Arousal": [3.285714286, 5.214285714, 7.071428571, 6.571428571]
}

audiovisualData = {
    "Excerpt": [1, 2, 3, 4],
    "Valence": [5.071428571, 5.642857143, 7.142857143, 7.142857143],
    "Arousal": [3.285714286, 4.714285714, 7.571428571, 6.714285714]
}

v_df = pd.DataFrame(visualData)
av_df = pd.DataFrame(audiovisualData)

min_valence = 1
max_valence = 9
min_arousal = 1
max_arousal = 9

v_df = pd.DataFrame(visualData)
av_df = pd.DataFrame(audiovisualData)


colors = {
    1: "#1f77b4",
    2: "#ff7f0e",
    3: "#2ca02c",
    4: "#d62728",
}

fig, axes = plt.subplots(1, 2, figsize=(12, 6), sharex=True, sharey=True)

for ax, df, title in zip(
    axes,
    [v_df, av_df],
    ["Visual Only", "Audio + Visual"]
):
    for excerpt in df["Excerpt"]:
        row = df[df["Excerpt"] == excerpt]
        ax.scatter(
            row["Valence"],
            row["Arousal"],
            s=120,
            color=colors[excerpt],
            label=f"Excerpt {excerpt}"
        )

    ax.axhline(5, color="black", linewidth=0.75)
    ax.axvline(5, color="black", linewidth=0.75)

    ax.set_xlim(1, 9)
    ax.set_ylim(1, 9)

    ax.set_title(title)
    ax.set_xlabel("Valence")
    ax.set_ylabel("Arousal")
    ax.grid(False)

handles, labels = axes[0].get_legend_handles_labels()
fig.legend(handles, labels, loc="upper center", ncol=4)

plt.tight_layout(rect=[0, 0, 1, 0.9])
plt.show()