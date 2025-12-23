import os, glob
import numpy as np
import pandas as pd
import librosa

def moving_average(x, win):
    win = int(win)
    if win <= 1:
        return x
    win = min(win, len(x))
    return np.convolve(x, np.ones(win) / win, mode="same")


def minmax_01(x):
    x = np.asarray(x, dtype=float)
    mn, mx = np.nanmin(x), np.nanmax(x)
    return (x - mn) / (mx - mn + 1e-12)


def normalize(x, mn, mx):
    if mn is None or mx is None:
        return minmax_01(x)
    return (x - mn) / (mx - mn + 1e-12)


def extract_features(wav_path, duration_s, offset_s, sr, hop_length, frame_length, smooth_s):
    # Load signal
    y, sr = librosa.load(wav_path, sr=sr, mono=True, offset=offset_s, duration=duration_s)

    # Extract RMS and centroid from frames
    rms = librosa.feature.rms(y=y, frame_length=frame_length, hop_length=hop_length)[0]
    cent = librosa.feature.spectral_centroid(y=y, sr=sr, n_fft=frame_length, hop_length=hop_length)[0]
    t = librosa.frames_to_time(np.arange(len(rms)), sr=sr, hop_length=hop_length)

    # Normalize and smoothen outputs
    smooth_win = max(1, int(round(smooth_s * (sr / hop_length))))
    rms = moving_average(rms, smooth_win)
    cent = moving_average(cent, smooth_win)

    # Compute local tempo
    onset_env = librosa.onset.onset_strength(
        y=y,
        sr=sr,
        hop_length=hop_length
    )

    tempo_t = librosa.beat.tempo(onset_envelope=onset_env, sr=sr, hop_length=hop_length, aggregate=None)

    t_tempo = librosa.times_like(tempo_t, sr=sr, hop_length=hop_length)

    # Interpolate tempo to RMS timeline
    bpm_local = np.interp(t, t_tempo, tempo_t, left=tempo_t[0], right=tempo_t[-1])

    tempo_local = moving_average(bpm_local, smooth_win)
    
    return t, rms, cent, tempo_local


def main(in_dir="audio", out_dir="features", duration_s=40.0, offset_s=0.0, sr=44100, hop_length=512, frame_length=2048, smooth_s=0.30, global_normalize=True):
    
    os.makedirs(out_dir, exist_ok=True)
    wavs = sorted(glob.glob(os.path.join(in_dir, "*.wav")))
    if not wavs:
        raise SystemExit(f"No WAV files found in {in_dir}")

    extracted = [ (wav, *extract_features(wav, duration_s, offset_s, sr, hop_length, frame_length, smooth_s)) for wav in wavs ]

    rms_mn = rms_mx = cent_mn = cent_mx = None
    if global_normalize:
        all_rms = np.concatenate([rms for _, _, rms, _, _ in extracted])
        all_cent = np.concatenate([cent for _, _, _, cent, _ in extracted])
        rms_mn, rms_mx = float(all_rms.min()), float(all_rms.max())
        cent_mn, cent_mx = float(all_cent.min()), float(all_cent.max())

    for wav, t, rms, cent, tempo_local in extracted:
        df = pd.DataFrame({
            "t": t,
            "rms": normalize(rms, rms_mn, rms_mx),
            "centroid": normalize(cent, cent_mn, cent_mx),
            "tempo": tempo_local.astype(float)
        })
        base = os.path.splitext(os.path.basename(wav))[0]
        out_csv = os.path.join(out_dir, f"{base}_features.csv")
        df.to_csv(out_csv, index=False)

if __name__ == "__main__":
    #main(in_dir="audio", out_dir="visuals", duration_s=40.0)
    main(in_dir="example", out_dir="example", duration_s=10.0)
    
    
