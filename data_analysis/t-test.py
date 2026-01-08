import pandas as pd
from scipy import stats
import numpy as np
import os

base_results_path = r"..\data_analysis\results"
os.makedirs(base_results_path, exist_ok=True)

# First, the CSV with the answers is restructured and ordered to perform the t-test

df_raw = pd.read_csv(r"..\test\questionnaire_answers\testing answers.csv", sep=";")

rename_columns = {
    "Participant ID": "participant",
    "Select the excerpt you visualized": "excerpt",
    "Select the type of stimuli you visualized": "condition",
    "How positive or negative did this stimulus make you feel?": "valence",
    "How energetic did this stimulus make you feel?": "arousal"
}

df = df_raw[list(rename_columns.keys())].rename(columns=rename_columns)

df["condition"] = df["condition"].replace({
    "Audio + Visual" : "AV",
    "Visual": "V"
    })

print(df)

# paired t-test

def paired_ttest(df, metric):
    pivot = df.pivot_table(
        index = ["participant", "excerpt"], 
        columns= "condition", 
        values = metric
    ).dropna()
    
    dif = pivot["AV"] - pivot["V"]
    
    t,p = stats.ttest_rel(pivot["AV"], pivot["V"])
    
    cohens_dz = dif.mean() / dif.std(ddof = 1)
    
    return {
        "N_pairs": len(dif),
        "Mean_V": pivot["V"].mean(),
        "Mean_AV": pivot["AV"].mean(),
        "Mean_Difference_AV_minus_V": dif.mean(),
        "t_value": t,
        "p_value": p,
        "Cohens_dz": cohens_dz
    }
    
valence_ttest = paired_ttest(df, "valence")

pd.DataFrame([valence_ttest]).to_csv(
    os.path.join(base_results_path, "valence_ttest.csv"),
    index=False
)

arousal_ttest = paired_ttest(df, "arousal")
pd.DataFrame([arousal_ttest]).to_csv(
    os.path.join(base_results_path, "arousal_ttest.csv"),
    index=False
)