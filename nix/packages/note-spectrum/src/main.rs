//! Prints per-frame dBFS levels of the default sink monitor: C;...;B|C2;...;B6

use std::fmt::Write as _;
use std::io::{self, BufWriter, Read, Write};
use std::process::{Command, Stdio};

use rustfft::num_complex::Complex;
use rustfft::FftPlanner;

const SAMPLE_RATE: usize = 48_000;
const FRAMES_PER_SECOND: usize = 30;
const WINDOW: usize = 8192;
const LOWEST_NOTE: i32 = 36; // C2, so note index % 12 is the pitch class
const NOTE_COUNT: usize = 60; // C2 through B6
const SILENCE_DB: f32 = -120.0;

enum Band {
    Bins(usize, usize),
    Between(usize, f32),
}

fn note_bands() -> Vec<Band> {
    let bin_hz = SAMPLE_RATE as f32 / WINDOW as f32;
    let half_semitone = 2f32.powf(1.0 / 24.0);
    (0..NOTE_COUNT)
        .map(|i| {
            let midi = LOWEST_NOTE + i as i32;
            let centre = 440.0 * 2f32.powf((midi - 69) as f32 / 12.0);
            let lo = (centre / half_semitone / bin_hz).ceil() as usize;
            let hi = (centre * half_semitone / bin_hz).ceil() as usize;
            if hi > lo {
                Band::Bins(lo, hi)
            } else {
                let pos = centre / bin_hz;
                Band::Between(pos as usize, pos.fract())
            }
        })
        .collect()
}

fn push_levels(line: &mut String, powers: &[f32]) {
    for (i, &p) in powers.iter().enumerate() {
        if i > 0 {
            line.push(';');
        }
        let db = (10.0 * p.log10()).max(SILENCE_DB);
        let _ = write!(line, "{db:.1}");
    }
}

fn main() {
    let mut parec = Command::new("parec")
        .args([
            "--raw",
            "--format=float32le",
            "--channels=1",
            "--device=@DEFAULT_MONITOR@",
            "--latency-msec=20",
        ])
        .arg(format!("--rate={SAMPLE_RATE}"))
        .stdout(Stdio::piped())
        .spawn()
        .expect("failed to start parec");
    let mut audio = parec.stdout.take().expect("parec stdout is piped");

    let hop = SAMPLE_RATE / FRAMES_PER_SECOND;
    let hann: Vec<f32> = (0..WINDOW)
        .map(|i| 0.5 - 0.5 * (std::f32::consts::TAU * i as f32 / WINDOW as f32).cos())
        .collect();
    let scale = (4.0 / WINDOW as f32).powi(2);
    let bands = note_bands();

    let fft = FftPlanner::<f32>::new().plan_fft_forward(WINDOW);
    let mut scratch = vec![Complex::default(); fft.get_inplace_scratch_len()];
    let mut spectrum = vec![Complex::default(); WINDOW];
    let mut power = vec![0f32; WINDOW / 2 + 1];
    let mut samples = vec![0f32; WINDOW];
    let mut bytes = vec![0u8; hop * 4];
    let mut notes = [0f32; NOTE_COUNT];
    let mut line = String::new();
    let mut out = BufWriter::new(io::stdout().lock());

    while audio.read_exact(&mut bytes).is_ok() {
        samples.copy_within(hop.., 0);
        for (sample, raw) in samples[WINDOW - hop..].iter_mut().zip(bytes.chunks_exact(4)) {
            *sample = f32::from_le_bytes([raw[0], raw[1], raw[2], raw[3]]);
        }

        for ((bin, &sample), &w) in spectrum.iter_mut().zip(&samples).zip(&hann) {
            *bin = Complex::new(sample * w, 0.0);
        }
        fft.process_with_scratch(&mut spectrum, &mut scratch);
        for (p, bin) in power.iter_mut().zip(&spectrum) {
            *p = bin.norm_sqr() * scale;
        }

        for (note, band) in notes.iter_mut().zip(&bands) {
            *note = match *band {
                Band::Bins(lo, hi) => power[lo..hi].iter().sum(),
                Band::Between(bin, t) => power[bin] + (power[bin + 1] - power[bin]) * t,
            };
        }

        let mut chroma = [0f32; 12];
        for (i, &p) in notes.iter().enumerate() {
            chroma[i % 12] += p;
        }

        line.clear();
        push_levels(&mut line, &chroma);
        line.push('|');
        push_levels(&mut line, &notes);
        line.push('\n');
        if out.write_all(line.as_bytes()).and_then(|_| out.flush()).is_err() {
            break;
        }
    }

    let _ = parec.kill();
    let _ = parec.wait();
}
