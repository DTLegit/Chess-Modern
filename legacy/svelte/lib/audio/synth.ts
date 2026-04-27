// Tiny procedural sound module — every sound is rendered at runtime from
// short oscillator/noise envelopes. Keeps the bundle binary-free and matches
// the hand-crafted aesthetic. Honors the global Settings (enabled + volume).

import { settingsStore } from "../stores/settingsStore.svelte";

type SoundKind = "move" | "capture" | "check" | "castle" | "promote" | "end";

let ctx: AudioContext | null = null;

function ac(): AudioContext | null {
  if (typeof window === "undefined") return null;
  if (!ctx) {
    const Ctor =
      window.AudioContext ||
      (window as unknown as { webkitAudioContext?: typeof AudioContext })
        .webkitAudioContext;
    if (!Ctor) return null;
    ctx = new Ctor();
  }
  if (ctx.state === "suspended") {
    void ctx.resume();
  }
  return ctx;
}

function master(volume: number): GainNode | null {
  const c = ac();
  if (!c) return null;
  const g = c.createGain();
  g.gain.setValueAtTime(0, c.currentTime);
  // Soft attack to avoid clicks
  g.gain.linearRampToValueAtTime(volume, c.currentTime + 0.005);
  g.connect(c.destination);
  return g;
}

/** A short woody "click" — two damped oscillators + brief noise transient. */
function woodClick(volume: number, pitch: number, dur: number) {
  const c = ac();
  const out = master(volume);
  if (!c || !out) return;

  const t0 = c.currentTime;

  // Body: low sine with rapid decay.
  const body = c.createOscillator();
  body.type = "sine";
  body.frequency.setValueAtTime(pitch, t0);
  body.frequency.exponentialRampToValueAtTime(pitch * 0.5, t0 + dur);
  const bg = c.createGain();
  bg.gain.setValueAtTime(0.0001, t0);
  bg.gain.exponentialRampToValueAtTime(0.6, t0 + 0.005);
  bg.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
  body.connect(bg).connect(out);
  body.start(t0);
  body.stop(t0 + dur + 0.02);

  // Attack: short noise burst through a peak filter.
  const noiseDur = 0.03;
  const buf = c.createBuffer(1, Math.ceil(c.sampleRate * noiseDur), c.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < data.length; i++) {
    data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
  }
  const noise = c.createBufferSource();
  noise.buffer = buf;
  const nf = c.createBiquadFilter();
  nf.type = "bandpass";
  nf.frequency.value = pitch * 4;
  nf.Q.value = 4;
  const ng = c.createGain();
  ng.gain.setValueAtTime(0.55, t0);
  ng.gain.exponentialRampToValueAtTime(0.001, t0 + noiseDur);
  noise.connect(nf).connect(ng).connect(out);
  noise.start(t0);
}

function chord(volume: number, freqs: number[], dur: number) {
  const c = ac();
  const out = master(volume);
  if (!c || !out) return;
  const t0 = c.currentTime;
  freqs.forEach((f, i) => {
    const o = c.createOscillator();
    o.type = i === 0 ? "triangle" : "sine";
    o.frequency.value = f;
    const g = c.createGain();
    g.gain.setValueAtTime(0.0001, t0);
    g.gain.exponentialRampToValueAtTime(0.4 / freqs.length, t0 + 0.02);
    g.gain.exponentialRampToValueAtTime(0.0001, t0 + dur);
    o.connect(g).connect(out);
    o.start(t0);
    o.stop(t0 + dur + 0.02);
  });
}

function shimmer(volume: number) {
  const c = ac();
  const out = master(volume);
  if (!c || !out) return;
  const t0 = c.currentTime;
  const o = c.createOscillator();
  o.type = "sine";
  o.frequency.setValueAtTime(880, t0);
  o.frequency.linearRampToValueAtTime(1320, t0 + 0.18);
  const g = c.createGain();
  g.gain.setValueAtTime(0.0001, t0);
  g.gain.exponentialRampToValueAtTime(0.45, t0 + 0.02);
  g.gain.exponentialRampToValueAtTime(0.0001, t0 + 0.32);
  o.connect(g).connect(out);
  o.start(t0);
  o.stop(t0 + 0.4);
}

export function playSound(kind: SoundKind) {
  const s = settingsStore.settings;
  if (!s.sound_enabled) return;
  const v = Math.max(0, Math.min(1, s.sound_volume));
  if (v <= 0) return;
  switch (kind) {
    case "move":
      woodClick(v * 0.85, 220, 0.16);
      break;
    case "capture":
      woodClick(v * 1.0, 150, 0.22);
      // small secondary click
      setTimeout(() => woodClick(v * 0.45, 320, 0.08), 18);
      break;
    case "castle":
      woodClick(v * 0.9, 200, 0.18);
      setTimeout(() => woodClick(v * 0.7, 260, 0.14), 70);
      break;
    case "check":
      chord(v * 0.55, [660, 880, 1100], 0.32);
      break;
    case "promote":
      shimmer(v * 0.6);
      break;
    case "end":
      chord(v * 0.6, [392, 523, 659, 784], 0.9);
      break;
  }
}

/** Resume the audio context on first user gesture. */
export function unlockAudioOnGesture() {
  const handler = () => {
    ac();
    window.removeEventListener("pointerdown", handler);
    window.removeEventListener("keydown", handler);
  };
  window.addEventListener("pointerdown", handler, { once: true });
  window.addEventListener("keydown", handler, { once: true });
}
