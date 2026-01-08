import pandas as pd
import os

base_results_path = r"..\data_analysis\results"
os.makedirs(base_results_path, exist_ok=True)

df = pd.read_csv(r"..\test\questionnaire_answers\testing answers.csv", sep=";")

df = df.rename(columns={
    "Participant ID": "participant",
    "Select the excerpt you visualized": "excerpt",
    "Select the type of stimuli you visualized": "condition"
})

df["condition"] = df["condition"].replace({
    "Audio + Visual": "AV",
    "Visual": "V"
})

df["excerpt"] = df["excerpt"].astype(int)

visual_columns = [
    "How intense did the movement of the visualization feel?",
    "How intense did the colors of the visualization feel?",
    "How confident are you in your answer?(V)"
]

df_visual = df[df["condition"] == "V"].copy()

visual_means = (
    df_visual
    .groupby("excerpt")[visual_columns]
    .mean()
    .reset_index()
)

visual_means.to_csv(
    os.path.join(base_results_path, "complementary_data_visualonly.csv"),
    index=False
)

df_av = df[df["condition"] == "AV"].copy()

av_numeric_columns = [
    "How well did the audio and the visualization match?",
    "How confident are you in your answer?(AV)"
]

av_means = (
    df_av
    .groupby("excerpt")[av_numeric_columns]
    .mean()
    .reset_index()
)

av_categorical_column = ("Which element influenced your emotional responses the most when answering the previous questions?")

df_av[av_categorical_column] = (
    df_av[av_categorical_column]
    .str.lower()
    .str.strip()
)

av_counts = (
    df_av
    .groupby(["excerpt", av_categorical_column])
    .size()
    .reset_index(name="count")
)

av_mode = (
    av_counts
    .sort_values(["excerpt", "count"], ascending=[True, False])
    .groupby("excerpt")
    .first()
    .reset_index()
)

av_results = (
    av_means
    .merge(av_mode, on="excerpt")
)

av_results = av_results.rename(columns={
    av_categorical_column: "dominant_influencing_element",
    "count": "dominant_count"
})

av_results.to_csv(
    os.path.join(base_results_path, "complementary_data_audiovisual.csv"),
    index=False
)