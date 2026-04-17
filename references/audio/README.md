# Audio references (ElevenLabs voices, etc.)

Drop ElevenLabs voice clips (or any reference audio) here. Used by **Seedance 2.0** as `reference_audio_urls[]` (voice cloning) or muxed onto silent Seedance video in post via `scripts/mux-audio.sh`.

> **Important:** kie.ai requires **public HTTPS URLs** — it does not host your audio files. For Path A (voice cloning), you host the audio at a public URL before firing. For Path B (direct mux), the file stays local. See `skills/kie-ai-external-api/SKILL.md` → "Voice source gate" for the full flow.

## File naming convention

```
{character-slug}-{clip-purpose}.mp3
```

- **character-slug:** matches the influencer folder name or a custom character (e.g. `emma`, `real-sarah`, `vo-deep-male`)
- **clip-purpose:** short descriptor of what the audio is for (e.g. `makeup-chat`, `layers-vo`, `product-demo`)

**Examples:**
- `emma-makeup-chat.mp3` — Clip 1 influencer saying a makeup tutorial opener
- `real-sarah-layers-vo.mp3` — Clip 2 narrator saying the Layers value prop in German

## Per-character voice library

Record a `<character-slug>-voice-ref.mp3` (5–15 s of clean speech, no background music) the first time you mint a character. This file is the canonical voice-clone reference for Path A; re-use it across clips so the character's voice stays consistent. Keep the ElevenLabs voice ID in `MASTER_CONTEXT.md` → Voice library.

## Recommended settings for Path A (voice cloning via kie.ai)

Seedance's voice-clone reference is a **timbre** source, not a literal audio track. Give it a clean sample:

- **Duration:** 5–15 seconds of speech
- **Format:** mp3 or m4a (wav works but is bigger; kie.ai accepts all three)
- **Sample rate:** 22050 Hz or 44100 Hz mono
- **Content:** clean speech in the target language, normal pace, no background music, no heavy effects
- **ElevenLabs settings:** pick a stable voice, use Instant Voice Clone or one of the Pro voices; export as 128 kbps mp3

## Recommended settings for Path B (direct ffmpeg mux)

For Path B the audio file plays verbatim in the final video, so deliver the full performance:

- **Duration:** exactly matches the Seedance clip duration (or the script's natural length; `mux-audio.sh` uses `-shortest` to trim)
- **Format:** mp3 (256 kbps+) or m4a — both mux cleanly to an MP4 with AAC audio
- **Levels:** normalized to -14 LUFS or thereabouts — Seedance video has no audio, so ElevenLabs levels dictate loudness
- **Breath/pause:** bake in the pauses. `ffmpeg -shortest` cuts at whichever is shorter; plan the audio length accordingly.

## Supported kie.ai audio formats

Based on kie.ai's `reference_audio_urls[]` spec (Seedance 2.0 exclusive):

- `.mp3`, `.m4a`, `.wav` — all accepted
- Base64 is **not** accepted — public HTTPS URL only
- Max 3 audio references per Seedance call

## Hosting flow

Same public-HTTPS requirement as images. Quick paths:

- **Imgur** — does NOT host audio. Use something else.
- **Cloudflare R2** — public bucket, great for repeat use. Upload via `wrangler r2 object put`.
- **Supabase Storage** — public bucket via dashboard or CLI.
- **GitHub Gist / raw** — works for non-sensitive test clips; don't use for real voice clones.
- **S3 / Backblaze B2** — any long-lived public-bucket URL.

The agent will offer to use your preferred host from `MASTER_CONTEXT.md` → Reference image hosting. Audio uses the same host.

## Privacy

This folder's audio files are **gitignored** (`*.mp3`, `*.wav`, `*.m4a`, `*.flac`, `*.ogg`). Your ElevenLabs clones and voice samples stay local and are never committed.
