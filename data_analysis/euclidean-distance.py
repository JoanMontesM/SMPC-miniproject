import pandas as pd
import numpy as np
import os

base_results_path = r"..\data_analysis\results"
os.makedirs(base_results_path, exist_ok=True)

df = pd.read_csv(r"..\test\questionnaire_answers\testing answers.csv", sep=";")

df = df.rename(columns={
    "Participant ID": "participant",
    "Select the excerpt you visualized": "excerpt",
    "Select the type of stimuli you visualized": "condition",
    "How positive or negative did this stimulus make you feel?": "valence",
    "How energetic did this stimulus make you feel?": "arousal"
})

df["condition"] = df["condition"].replace({
    "Audio + Visual" : "AV",
    "Visual": "V"
    })

means = (df.groupby(["excerpt", "condition"])[["valence", "arousal"]].mean().reset_index())

print(means)

V = means[means["condition"] == "V"].set_index("excerpt")
AV = means[means["condition"] == "AV"].set_index("excerpt")

common = V.index.intersection(AV.index)
V = V.loc[common]
AV = AV.loc[common]

distance = np.sqrt(
    (AV["valence"] - V["valence"])**2 +
    (AV["arousal"] - V["arousal"])**2
)

dist = distance.reset_index()
dist.columns = ["excerpt", "euclidean_distance_V_to_AV"]

dist.to_csv(
    os.path.join(base_results_path, "euclidean_distances.csv"),
    index=False
)