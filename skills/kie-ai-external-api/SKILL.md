---
name: kie-ai-external-api
description: >-
  Creates and retrieves AI video and image assets via the kie.ai API (Seedance 2.0, Sora 2, Sora 2 Pro, Veo 3 / 3.1, Kling 2.6/3.0, Nano Banana 2 / Pro). Loads prompts from the bundled prompting guide and per-model prompt library, uses Bearer-token auth from KIE_API_KEY, and polls task status until ready. Use when the user mentions kie.ai, api.kie.ai, Seedance, Sora2, Veo, Kling, Nano Banana, or generating AI marketing creative through kie.ai.
---

# kie.ai external API

## Configuration

- **Base URL:** `https://api.kie.ai` (or `KIE_BASE_URL`).
- **Auth:** HTTP Bearer — send `Authorization: Bearer $KIE_API_KEY` on every call. Create keys at [kie.ai/api-key](https://kie.ai/api-key).
- **Never** print API keys, commit `.env`, or paste keys into `MASTER_CONTEXT.md`.

### If the key is missing or the API returns 401

1. **Editor-first (default):** Ensure `.env` exists (copy from `.env.example` in the repo root). Ask the user to paste `KIE_API_KEY` **only inside** `.env` and save. Do not ask them to paste the key in chat unless they insist.
2. **Chat-assisted:** If they paste the key in chat, write `.env` for them, confirm "saved to `.env`" **without repeating the key**, and remind them that chat history may retain secrets — rotate the key at [kie.ai/api-key](https://kie.ai/api-key) if the chat could be shared.

Before the first call, confirm `.gitignore` excludes `.env`.

## Read order

1. Repo root **`MASTER_CONTEXT.md`** when present (brand voice, decisions, quirks).
2. This skill's **[reference.md](reference.md)** for endpoints, request bodies, polling, and per-model input fields.
3. **[prompting/guide.md](prompting/guide.md)** then the right **`prompting/prompt-library/`** file for the model.

## The shape of the kie.ai API

kie.ai exposes two endpoint families:

1. **Unified task endpoint** — `POST /api/v1/jobs/createTask` with `{"model": "<slug>", "input": {...}}`. Used for Seedance, Sora 2, Kling 3.0, Nano Banana, and most marketplace models. Poll via the unified task-details endpoint. See [reference.md](reference.md) for the exact slug per model.
2. **Veo legacy endpoint** — `POST /api/v1/veo/generate` (different body shape). Poll via `GET /api/v1/veo/record-info?taskId=...`.

In both families, a successful create returns `{ taskId, code, msg }`. Poll until `successFlag` transitions from `0` (generating) to `1` (success) or `2|3` (failure). The final asset URLs are on `data.response.resultUrls[]`.

## Decision tree: which flow?

| User goal | Endpoint + model slug | Prompt library |
|-----------|-----------------------|----------------|
| **Seedance 2.0 UGC video** — selfie-style product review / testimonial | `POST /api/v1/jobs/createTask` with `"model": "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) + [seedance-2-ugc.md](prompting/prompt-library/seedance-2-ugc.md) |
| **Seedance 2.0 premium product reveal** — dark-void, no person | `POST /api/v1/jobs/createTask` with `"model": "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) + [seedance-2-premium-reveal.md](prompting/prompt-library/seedance-2-premium-reveal.md) |
| **Seedance 2.0 product hero** — elemental effects, no person | `POST /api/v1/jobs/createTask` with `"model": "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) + [seedance-2-product-hero.md](prompting/prompt-library/seedance-2-product-hero.md) |
| **Seedance 2.0 studio lookbook** — polished, voiceover, multi-look | `POST /api/v1/jobs/createTask` with `"model": "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) + [seedance-2-studio-lookbook.md](prompting/prompt-library/seedance-2-studio-lookbook.md) |
| **Seedance 2.0 feature walkthrough** — fast-paced feature demo | `POST /api/v1/jobs/createTask` with `"model": "bytedance/seedance-2"` | [seedance-2.md](prompting/prompt-library/seedance-2.md) + [seedance-2-feature-walkthrough.md](prompting/prompt-library/seedance-2-feature-walkthrough.md) |
| **Reverse-engineer a video style** into a reusable Seedance 2.0 template | Follow the analyze-video skill | [prompting/analyze-video/SKILL.md](prompting/analyze-video/SKILL.md) |
| **Clone/replicate an existing video ad** for a different product | Follow the clone-ad skill | [prompting/clone-ad/SKILL.md](prompting/clone-ad/SKILL.md) |
| Raw **Sora 2** video from text | `POST /api/v1/jobs/createTask` with `"model": "sora-2-text-to-video"` | [sora-2.md](prompting/prompt-library/sora-2.md) |
| **Sora 2** image-to-video (product photo as starting context) | `POST /api/v1/jobs/createTask` with `"model": "sora-2-image-to-video"` | [sora-2.md](prompting/prompt-library/sora-2.md) |
| **Veo 3.1** video | `POST /api/v1/veo/generate` with `"model": "veo3"` (or `veo3_fast`) | [veo-3-1.md](prompting/prompt-library/veo-3-1.md) |
| **Kling 3.0** video | `POST /api/v1/jobs/createTask` with `"model": "kling-3.0/video"` | [kling-3.md](prompting/prompt-library/kling-3.md) |
| **Nano Banana 2 still image** (standalone or as starting frame for video) | `POST /api/v1/jobs/createTask` with `"model": "nano-banana-2"` (default) or `"nano-banana-pro"` for Pro | [nano-banana.md](prompting/prompt-library/nano-banana.md) |
| **Recreate an influencer** from a reference photo | **Two-step:** (1) `POST /api/v1/jobs/createTask` with `nano-banana-2` and the reference as `image_input[]` to generate a **still image** via Nano Banana, get user approval; (2) use approved still's public URL as `first_frame_url` (Seedance) / `imageUrls[]` (Veo) in the video call. **Never skip the approval step.** | [influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) |
| **Product showcase** — AI person holds/uses a product and talks about it | **Two-step:** (1) Nano Banana still of person with product; (2) user approves; (3) still URL → video via Seedance 2.0 (`first_frame_url`) or Veo 3.1 (`imageUrls[0]`). | [product-showcase.md](prompting/prompt-library/product-showcase.md) |
| **UGC / selfie-style** (authentic reels, cross-model) | Seedance 2.0 or Sora 2 via `createTask` | [ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) — cross-model UGC guide. For Seedance 2.0 specifically, use [seedance-2-ugc.md](prompting/prompt-library/seedance-2-ugc.md). |
| **Create a new AI influencer** from text (character sheet) | **Two-pass:** (1) hero portrait via `nano-banana-2`, get approval; (2) 9 angles with hero as `image_input[]`. Save to `references/influencers/`. | [character-sheet.md](prompting/prompt-library/character-sheet.md) |
| **UGC product selfie** — AI influencer holding a product | Combine character hero + product photo + style references as `image_input[]`. | [ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) |

Prefer the **shortest** path: if the user only needs a single model, generate directly instead of adding extra steps.

## Creative layer

- **MANDATORY:** Before composing any prompt for the API, **read the relevant `prompting/prompt-library/*.md` file** for the chosen model/workflow. Every prompt must align with the vendor guide's formula and best practices.
- Build **one** clear prompt paragraph; avoid keyword soup.
- For Seedance 2.0 / Sora 2 / Veo 3.1 / Kling / Nano Banana, align with the **official vendor guides** linked in each `prompting/prompt-library/*.md` file (do not paste full vendor docs into chat — summarize checks).
- Merge slot values from the user and from **`MASTER_CONTEXT.md`** when it conflicts with defaults.

## Reference images: hosting and public URLs

kie.ai requires reference images (`first_frame_url`, `last_frame_url`, `reference_image_urls[]`, `image_input[]`, `imageUrls[]` for Veo) to be **publicly accessible HTTPS URLs** — unlike Arcads' presigned-S3 flow. The user hosts the image, you pass the URL.

**When the user provides a local file path:**

1. Check `MASTER_CONTEXT.md` → Reference image hosting for a pre-configured host. If Supabase Storage is set up (`SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` + `SUPABASE_BUCKET` in `.env`), **upload directly via the helper**:
   ```bash
   URL=$(./scripts/upload-to-supabase.sh <local-file> [remote-path] [bucket])
   ```
   The helper reads creds from `.env`, uploads via Supabase Storage API, probes the resulting public URL, and prints the URL to stdout. Everything else goes to stderr, so the URL is safe to capture. Use the returned URL as `first_frame_url`, `image_input[]`, `reference_audio_urls[]`, etc.
2. If no host is configured yet, walk the user through the options and offer to populate `MASTER_CONTEXT.md` once:
   - **Supabase Storage** (recommended — handles images AND audio, repeat use). Setup in `.env.example`; upload via `./scripts/upload-to-supabase.sh`.
   - **Imgur** (images only, fastest for one-off tests): upload at [imgur.com](https://imgur.com/upload), copy the direct link (`https://i.imgur.com/xxx.jpg`). Does NOT host audio.
   - **Cloudflare R2 / AWS S3 / Backblaze B2** (own your hosting, scale-friendly): upload once, paste the object's public URL.
   - **GitHub raw** (small public files only): commit to a public repo, use `https://raw.githubusercontent.com/...`.
3. **Do NOT ever** suggest pasting the image as base64 in chat — kie.ai doesn't accept base64 anywhere in this repo's supported flows.
4. **Never ask the user to paste the Supabase service_role key (or any API key) into chat.** It goes into `.env` only. If a key needs configuring, walk them through opening `.env` in their editor, not pasting it at you.
5. Once a URL is resolved (whether from the helper or a manual paste), sanity-check it (HEAD request; 200 OK and `Content-Type: image/*` or `audio/*`). If it 403s or redirects to HTML, the URL is wrong (common Imgur gotcha: use `i.imgur.com/*.jpg`, not `imgur.com/*`).
6. Validate the URL is **HTTPS** (not HTTP) and on the **public internet** (not `localhost`, `127.0.0.1`, or a private IP).

**Generated assets** (returned by kie.ai in `resultUrls[]`) are already public URLs — you can pipe them straight into the next call as `first_frame_url` or `imageUrls[]` without re-hosting.

**Image minimum size:** kie.ai accepts images down to ~512 px on the longest side. If the user's reference is smaller, warn them; if they want, offer to upscale locally (`sips -Z 1080 img.jpg` on macOS) before they re-host.

## Credit cost estimation (MANDATORY — show before generating)

Before firing **any** generation calls, calculate and present the total credit cost to the user as an **estimate**. **Do not generate until the user confirms.**

> **ALWAYS label credit totals as estimates and tell the user to confirm the exact cost in their kie.ai account before generating if precision matters.** kie.ai does not return `creditsCharged` on every task — you price from a static table.

### Cost data sources (in priority order)

1. **`MASTER_CONTEXT.md` → Credit costs** — user-provided pricing rules (e.g. "Seedance 2.0 ≈ $0.06/sec"). This is the primary source.
2. **`logs/kie-api.jsonl`** — historical record of what we've fired. Kie.ai doesn't return a per-call credit figure, but historical config (model, duration, resolution) helps cross-check the rate table. Use this as a secondary sanity check.
3. **Ask the user** — if neither source has a rate for the model, ask the user (or point them at [kie.ai pricing](https://kie.ai/pricing)) and write the answer into `MASTER_CONTEXT.md`.

Never invent numbers. Always cite the source of the estimate ("from MASTER_CONTEXT.md rate table" or "per kie.ai pricing page, confirmed by user on YYYY-MM-DD").

### How to calculate

```
total_credits ≈ sum(credits_per_model × duration_multiplier × variations_requested) for each model
```

### Example output to user

```
Estimated cost:
  Seedance 2.0 (15s i2v) × 1 = ~$0.90  (from MASTER_CONTEXT.md: $0.06/sec)
  Veo 3.1 (auto ~8s)     × 2 = ~$2.00  (from MASTER_CONTEXT.md: $1.00/gen)
  ───────────────────────────────
  Estimated total: ~$2.90

⚠️ Estimate only — confirm exact cost at kie.ai/pricing before proceeding.
Proceed? (yes/no)
```

Always wait for confirmation before firing. If the user has a credit/dollar balance visible in `MASTER_CONTEXT.md`, warn them if the total would exceed it.

**Exception — QA-fix retries (still images only):** After the user has confirmed the initial batch, **automatic regeneration to fix visible defects** (see [Generated image QA](#generated-image-qa-mandatory) below) does **not** require asking again for cost confirmation. Each retry is still billed — note the extra cost when summarizing the session.

## Generation count: multiple variations per prompt

Before firing any generation call, **ask the user how many variations** they want for this prompt. Default is 1 if they don't specify.

When the count is greater than 1, send **N separate `createTask` calls** with the identical payload. kie.ai has no batch parameter on the unified endpoint. Fire them in parallel where possible, then poll all `taskId`s concurrently.

Present results as a numbered list so the user can compare and pick favorites.

## Nano Banana image: model choice (`nano-banana-2` vs `nano-banana-pro`)

For image generation via `POST /api/v1/jobs/createTask`:

- **Default:** `"model": "nano-banana-2"` (Nano Banana 2).
- **Optional:** `"model": "nano-banana-pro"` when the user asks for **Nano Banana Pro**.

Before the first Nano Banana image call in a workflow, ask: *"Use default Nano Banana 2, or Nano Banana Pro?"* If they have no preference, use `nano-banana-2`. Include the chosen `model` in the credit estimate (separate rows in `MASTER_CONTEXT.md` if pricing differs).

### Google safety-filter triggers (MANDATORY prompt scrub)

Nano Banana runs on Google's Gemini. Before every call, scan the prompt for these known triggers — they cause the call to fail with `failMsg: "...Google's Generative AI Prohibited Use policy"` after burning ~25s of compute:

- **`bare skin` / `bare-faced` / `naked face` / `stripped of makeup`** — sexual-content filter. Replace with `no makeup`, `natural face`, `unmade face`, `makeup-free`.
- **`nude` in ANY context** — "nude lipstick", "nude palette", "nude eyeshadow" all flag. Replace with `beige`, `neutral`, `rosy`, `pink`.
- **`bedroom` in a young-woman prompt** — minor-safety combo. Replace with `vanity desk`, `makeup corner`, `dressing area`.
- **Real-photo references of identifiable people in `image_input[]`** — likeness/consent filter, especially in beauty/makeup contexts. If the first attempt fails with the Google policy error, drop `image_input[]` and describe the character in text only. AI-generated stills from prior Nano Banana calls are generally safe as refs.
- **Named brands on products** (e.g. "CAIA palette") — even with "no logos" negatives. Describe abstractly: "generic pink/neutral palette".
- **`young` + fine-skin descriptors + makeup context** — minor-safety heuristics. Use "adult woman in her 20s" / "woman in her mid-20s" explicitly.
- **Persistent post-generation refusals on `nano-banana-2` for beauty-selfie content** — even with all above scrubbed, Gemini 2.5 Flash (backing `nano-banana-2`) frequently post-filters woman + selfie + makeup prompts at 16–34s compute. Escalate to `nano-banana-pro` (different Gemini variant, looser thresholds) before giving up.

Full list and examples: [prompting/prompt-library/ugc-product-selfie.md → Gemini / Nano Banana filter gotchas](prompting/prompt-library/ugc-product-selfie.md#gemini--nano-banana-filter-gotchas).

## Script and dialogue

For any video that features a person speaking, **ask the user for the script** (the exact words the AI person should say). This is separate from the visual prompt — it's the dialogue.

### MANDATORY — dialogue iteration gate

Before generating **any** video that contains spoken dialogue, the agent MUST run the dialogue iteration gate. **Iteration is the default, not the exception** — text is free, video is expensive. The agent should expect 2–4 rounds of edits before the user locks.

**Core rules:**

1. **Never present a single take.** Always show **3 labeled variants** (A / B / C) per dialogue line or per clip. Variants must actually differ — a different hook, a different register, a different structure. Not three versions of the same sentence with one word swapped.
2. **Every variant carries timing metadata**: word count, estimated duration at natural pace, and a one-line tone tag. Use ~2.5 words/sec for German, ~2.8 words/sec for English, ~2.3 words/sec for Spanish/Italian as rough rates (adjust for the target language).
3. **Flag duration fit**: if a variant exceeds the clip's target duration, say so explicitly and offer to bump the clip (Seedance supports up to 15s continuous; Sora 2 picks from 4/8/12/16/20s; Veo 3.1 auto ~8s).
4. **Maintain a visible round log** in your response from round 2 onward. Users need to see what's been tried so they can pull back to an earlier variant.
5. **Only advance on an explicit lock phrase**: `lock A` / `ship B` / `final: <custom text>` / `use A as-is`. Anything ambiguous ("looks good", "yes", "nice") triggers a clarification: *"Lock which variant — A, B, or C?"* **Never assume approval from earlier confirmations** (tone, template, cost). Dialogue lock is its own gate.
6. **After lock, show the final line one more time with a ✅ banner** before proceeding to the next gate. This gives the user one last chance to catch something before cost/voice-source/fire gates kick in.

**Round 1 format (opening take — use this exact structure):**

```
📝 Dialogue iteration — Clip 1 (target 7s, de-DE)

A — polished influencer
   "Hi Babes! Heute zeig ich euch mein absolutes Glow-Up mit dieser Palette — damit seh' ich endlich aus wie—"
   ~18 words · ~7s · cuts off for wrecking-ball beat ✅

B — hook-forward
   "Hey meine Loves, diese Palette hat mein ganzes Gesicht verändert — schaut, ich seh' jetzt aus wie—"
   ~16 words · ~6s · stronger open

C — tutorial mode (shortest)
   "Okay girls, drei Produkte, zwei Minuten, und ich sehe aus wie—"
   ~11 words · ~4s · leaves more beats for the smash

Pick one (`lock A` / `lock B` / `lock C`), mix ("B-open + A-close"), or redirect ("too formal", "drop the 'Babes'").
```

**Round 2+ format (after user feedback — always include the round log):**

```
📝 Dialogue iteration — Clip 1 (round 2)

Round log:
  R1 — A/B/C shown (polished / hook-forward / tutorial-mode)
  R1 feedback — "B but without 'meine Loves', start with 'Babes'"

B′ — revised
   "Hey Babes, diese Palette hat mein ganzes Gesicht verändert — schaut, ich seh' jetzt aus wie—"
   ~15 words · ~6s

B″ — more energy
   "Babes! Diese Palette. Mein Leben. Schaut mal, ich seh' jetzt aus wie—"
   ~12 words · ~4.5s

Lock one (`lock B'` / `lock B''`) or keep iterating.
```

**Lock confirmation format:**

```
✅ Clip 1 dialogue locked (de-DE)

   "Hi Babes! Heute zeig ich euch mein absolutes Glow-Up mit dieser Palette — damit seh' ich endlich aus wie—"
   ~18 words · ~7s

Moving to next gate.
```

This gate applies to **Seedance 2.0**, **Veo 3.1**, and **Sora 2** — any flow where the model speaks. Skip for silent flows (Kling 3.0 has no native speech; Nano Banana images). For multi-clip ads, run the gate **per clip** (each clip locks independently before moving to the voice source gate).

### Model-specific notes

- For **Seedance 2.0**, **Veo 3.1**, and **Sora 2**: embed the dialogue in the `prompt` field using a `Dialogue: "..."` or `She speaks: "..."` pattern (these models generate speech from the text prompt).
- For **Seedance 2.0** specifically: after the dialogue gate, run the **Voice source gate** (see next section) to pick inline TTS vs ElevenLabs Path A vs Path B vs Path C per clip.
- For **Kling 3.0**: no native speech output — silent only. If the user wants speech, redirect to Seedance 2.0, Veo 3.1, or Sora 2.
- For **Nano Banana images**: no speech — these are still images. Speech is handled in the subsequent video generation step.

## MANDATORY — voice source gate (Seedance 2.0 only)

Immediately after the dialogue gate passes, run this gate. It picks **where the audio comes from** for each Seedance clip, independently per clip. This gate applies to Seedance 2.0 only — Veo 3.1 and Sora 2 currently only support inline prompt-driven speech, so for those models there is nothing to ask.

The four options, in order of fidelity to the user's desired voice:

| Path | How it works | Lip sync | Audio fidelity | When to use |
|------|--------------|----------|----------------|-------------|
| **Inline** | `audio: true`, dialogue in prompt. Seedance generates its own speech. | Auto | Generic | Default. User has no specific voice in mind. |
| **A — Voice clone** | Upload ElevenLabs audio → host → pass via `reference_audio_urls[]`. Seedance regenerates speech *in that voice timbre*. `audio: true`. | Auto | Voice sounds like ElevenLabs, but wording/pacing/emotion may drift. | User wants a specific voice and lip sync matters. Face is focal point. |
| **B — Direct mux** | Generate ElevenLabs audio. Seedance runs with `audio: false`. `scripts/mux-audio.sh` overlays the audio on the silent MP4 in post. | None (audio is external) | Bit-exact ElevenLabs | User wants exact audio, face is partially obscured (brush, hands, head turn, B-roll over VO). Cheapest to iterate. |
| **C — Strict lip sync** | Generate ElevenLabs audio + silent Seedance clip → run an external lip-sync tool (Wav2Lip / HeyGen / Synclabs). | Tool-driven | Bit-exact ElevenLabs AND mouth sync | **Not yet scaffolded in this repo.** Tell the user, log the gap in `MASTER_CONTEXT.md` Changelog, and fall back to Path A. |

### Gate format

Present as a per-clip block. For a two-clip ad:

```
🎤 Voice source gate

For each clip, pick one of: Inline / A / B / C.
See SKILL.md → "Voice source gate" for details on the tradeoffs.

  Clip 1 — [scene one-liner]         →  [ask: Inline / A / B / C]
  Clip 2 — [scene one-liner]         →  [ask: Inline / A / B / C]

Wait for explicit choice per clip before proceeding.
```

### If the user picks Path A or B

Ask for the ElevenLabs audio file. Two sub-paths:

1. **User already has the file:** ask them to save it to `references/audio/<character-slug>-<clip-purpose>.mp3`. For Path A, also ask them to host at a public HTTPS URL (use the host from `MASTER_CONTEXT.md` → Reference image hosting; audio uses the same host). For Path B, local file is sufficient.
2. **User needs to generate it:** walk them through ElevenLabs briefly — pick a voice, paste the confirmed dialogue from the dialogue gate, export as mp3 (128 kbps for Path A references, 256 kbps+ for Path B finals), save to `references/audio/`.

Then record in session state:
- Path A: the hosted HTTPS URL → add to `input.reference_audio_urls` in the Seedance payload
- Path B: the local file path + the Seedance `taskId` → post-mux step runs after Seedance completes

### If the user picks Path C

Tell them: "That needs an external lip-sync tool not yet integrated in this repo. Falling back to Path A — Seedance will use the voice timbre but generate its own speech." Append a dated note to `MASTER_CONTEXT.md` Changelog (Decision / What changed / Why) flagging the demand so a future skill can pick it up.

### Per-character voice library

When a character's voice is locked in, save the canonical `references/audio/<character-slug>-voice-ref.mp3` (5–15 s clean speech) and record the ElevenLabs voice ID in `MASTER_CONTEXT.md` → Voice library. Reuse the same ref across clips so the character's voice stays consistent.

## Script length → video duration (auto-select)

Use the script's word count to automatically pick the best duration. Average speaking pace: **~2.5 words per second** (~150 WPM). Round **up** to the next available duration to give breathing room.

### Sora 2 — duration: `[4, 8, 12, 16, 20]` seconds

| Script length | Duration |
|---------------|----------|
| 1–8 words | 4s |
| 9–18 words | 8s |
| 19–28 words | 12s |
| 29–38 words | 16s |
| 39–48 words | 20s |
| **49+ words** | **Too long** — offer to split (see below) |

### Veo 3.1 — duration enum via kie.ai: `[8]` (most common)

Kie.ai's Veo wrapper exposes limited duration control — Veo 3.1 auto-determines length (~8s). If the script exceeds ~20 words, warn the user Veo may truncate dialogue and offer to split or switch to Sora 2.

### Seedance 2.0 — duration: 4–15 seconds (continuous)

Seedance 2.0 supports any integer from 4 to 15. Use ~2.5 words/second, round up to the nearest second.

| Script length | Duration |
|---------------|----------|
| 1–8 words | 4–5s |
| 9–15 words | 6–8s |
| 16–25 words | 9–12s |
| 26–35 words | 13–15s |
| **36+ words** | **Too long** — offer to split into multiple clips |

For no-dialogue styles (product hero, premium reveal), default to **15s**.

**Resolution:** Default to `720p`. Only use `480p` if the user asks for a faster/cheaper test generation.

**Aspect ratio:** `9:16` (vertical, default for UGC/social) or `16:9` (landscape).

### Kling 3.0 — duration: `[5, 10]` seconds (typical)

Kling is silent. For timed clips:

| Script length | Duration |
|---------------|----------|
| 1–12 words | 5s |
| 13–24 words | 10s |
| **25+ words** | **Too long** — redirect to Sora 2 / Veo 3.1 for speech |

## Splitting long scripts into multiple videos

If the script exceeds the maximum duration for the chosen model:

1. **Tell the user** the script is too long for a single video and show the word/duration math.
2. **Offer two options:**
   - **Split into segments** — the agent breaks the script at natural sentence boundaries into chunks that each fit within the model's max duration. Each chunk becomes a separate `createTask` call.
   - **Switch models** — if they're on Kling (10s max), suggest Sora 2 (up to 20s).
3. If the user chooses to split, generate each segment as a separate video (respecting the generation count — if they asked for 3 variations, generate 3 of *each* segment).
4. **Offer to stitch** the final segments together using `ffmpeg`:
   - Download all segment videos locally from the `resultUrls[]`.
   - Concatenate using `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4` (re-encode if codecs differ).
   - Present the stitched file alongside the individual segments so the user has both.

## Veo 3.1: generationType — pick one

Kie.ai's Veo wrapper exposes a `generationType` field that controls how `imageUrls[]` is interpreted.

| Mode | `generationType` | `imageUrls[]` meaning | When to use |
|------|------------------|------------------------|-------------|
| **Text-to-video** | `TEXT_2_VIDEO` | Ignored | No reference image — pure text prompt. |
| **First-and-last frames** | `FIRST_AND_LAST_FRAMES_2_VIDEO` | `[firstFrameUrl, lastFrameUrl]` | Frame-to-frame morph; video animates between two images. |
| **Reference-to-video** | `REFERENCE_2_VIDEO` | Up to 3 style/mood references | Style/mood inspiration, not literal first-frame animation. |

**Default rule:** When the user provides a single reference photo of a person or scene they want the video to **start from**, use `FIRST_AND_LAST_FRAMES_2_VIDEO` with `imageUrls: [startFrameUrl]` (omit the second entry — kie.ai accepts a one-element array for first-frame-only). For pure style/mood, use `REFERENCE_2_VIDEO`.

## Generated image QA (mandatory)

Applies to **still images** from kie.ai, especially `nano-banana-2` / `nano-banana-pro` via `createTask`. After each task reaches `successFlag: 1`, **visually inspect the output** (download or open the image URL from `resultUrls[0]` / use the agent's image-reading capability).

**Look for:** extra or missing hands or fingers; wrong limb count; distorted, duplicated, or merged facial features; melted or fused objects; impossible anatomy; stray limbs; obvious texture or boundary artifacts; unreadable or garbled text if text was requested.

**If something looks wrong:** Do **not** hand off the bad frame as the final deliverable without trying again. **Regenerate** with a **revised prompt** that explicitly corrects the issue (e.g. "exactly two hands, five fingers each, anatomically correct arms," "single face, no duplicate features"). Do **not** resend the identical payload and expect a different outcome.

**Retry cap:** Up to **2 regeneration attempts per originally requested image** (3 attempts total including the first). If defects remain after the cap, stop auto-retries, tell the user what still looks wrong, show the best attempt or URLs for all attempts, and ask how they want to proceed.

**Credits:** Each attempt is a separate generation and is billed. Summarize total cost used for that image after the QA loop ends. See **Exception — QA-fix retries** under [Credit cost estimation](#credit-cost-estimation-mandatory--show-before-generating).

**Video (optional quick check):** Before spending heavily on downstream video, you may spot-check generated-video thumbnails or extracted frames for the same kinds of defects; scope is lighter than for hero stills.

Details and checklist items: [prompting/prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md).

## Execution checklist (agent)

1. **Ask for script/dialogue:** If the output is a video with a person speaking, ask the user for the exact words. Count words to auto-select duration (see "Script length → video duration" above). If too long, offer to split. (Skip for Nano Banana image-only requests.)
   - **MANDATORY dialogue iteration gate (before cost / before generation):** Present **3 labeled variants (A/B/C) per clip** with word count + duration estimate + tone tag. Iterate as many rounds as the user needs — show the round log from R2 onward. Only advance on an explicit lock phrase (`lock A` / `ship B` / `final: <text>`). Ambiguous approvals ("looks good", "yes") must trigger a clarification. Follow the format in [Script and dialogue → MANDATORY dialogue iteration gate](#mandatory--dialogue-iteration-gate). This gate is separate from the cost confirmation — both must be satisfied.
   - **MANDATORY voice source gate (Seedance 2.0 only, immediately after dialogue gate):** Ask per clip whether the voice is Inline / Path A (ElevenLabs voice clone via `reference_audio_urls[]`) / Path B (ElevenLabs direct ffmpeg mux on silent Seedance) / Path C (strict lip sync — not yet integrated, falls back to A). Follow the format in [MANDATORY — voice source gate](#mandatory--voice-source-gate-seedance-20-only). For Path A, collect the hosted HTTPS URL. For Path B, collect the local file path and flag the clip for post-mux. Wait for explicit choice per clip. Skip entirely for Veo 3.1, Sora 2, Kling, Nano Banana.
2. **Nano Banana image model:** For image calls, confirm Nano Banana 2 (default) vs Nano Banana Pro per the section above. Skip if not an image call.
3. **Ask for generation count:** Ask how many variations the user wants for this prompt. Default to 1.
4. **Show cost and get confirmation:** Calculate total cost from `MASTER_CONTEXT.md`. Present the breakdown to the user. Include any per-clip voice-source notes ("Clip 2: Path A — voice-clone ref at <host>" or "Clip 1: Path B — post-mux with ElevenLabs audio"). **Do NOT proceed until they confirm.**
5. **Resolve reference image URLs:** Before composing the prompt, check the repo-root `references/` folder for relevant images: `references/influencers/` for person recreation, `references/products/` for product showcase, `references/aesthetics/` for style/mood. If the user hasn't provided an image but a relevant one exists in `references/`, offer to use it — but remind them it must be hosted at a public HTTPS URL before kie.ai can consume it. Follow the flow in [Reference images: hosting and public URLs](#reference-images-hosting-and-public-urls). For Veo, choose `generationType` per the section above.
6. Compose JSON per [reference.md](reference.md):
   - **Seedance 2.0, Sora 2, Kling 3.0, Nano Banana:** `POST /api/v1/jobs/createTask` with `{"model": "<slug>", "input": {...}}`.
   - **Veo 3.1:** `POST /api/v1/veo/generate` with the Veo-specific body.
   - Include `callBackUrl` only if the user has a public webhook endpoint — otherwise omit and poll.
7. `POST` **N times** (once per requested variation) with the same payload. Fire in parallel where possible. **Immediately after each POST succeeds, append a log entry to `logs/kie-api.jsonl`** with the request config (endpoint, model, duration, resolution, aspect_ratio, audio, reference-URL counts, promptWordCount, taskId). Do NOT log the full prompt text, API keys, Authorization headers, or reference URLs (log the count, not the URLs — they may be private).
8. **Poll:** for Veo, `GET /api/v1/veo/record-info?taskId=...`; for everything else, use the unified task-details endpoint (see [reference.md](reference.md)). Poll all task IDs concurrently, every 3–5 seconds, until `successFlag` is `1` (success) or `2|3` (failure). **When polling completes, update the log entry** with `response.status`, `response.generationTimeSec`, `response.resultUrls` (count only, not the URLs), and `response.error` (if failed). See `logs/README.md` for the schema.
9. **Generated image QA:** For each **still image** produced in this turn (Nano Banana outputs), follow [Generated image QA](#generated-image-qa-mandatory): inspect the image; if defective, regenerate with a refined prompt until pass or **2 retries** are exhausted. Skip this step for video-only outputs with no still to review.
10. **Present results:** Return the `resultUrls[]` from each task for **QA-passed** stills (or the best attempt after max retries, with a clear note). If multiple variations, present as a numbered list for comparison. Explain `failed` with moderation/validation hints when appropriate. For Nano Banana images used as starting frames, show the image and **wait for user approval** before proceeding to video generation.
    - **ALWAYS open the output folder** on the user's machine after saving generated files so they can immediately review: `open "<output_directory>"` (macOS). Save videos to `outputs/` with a descriptive subfolder (e.g. `outputs/seedance-tests/`, `outputs/clone-ad-tests/`). Result URLs from kie.ai eventually expire — download locally for anything you want to keep.
11. **Post-mux (Seedance + Path B only):** For every clip flagged as Path B in the voice source gate, run `scripts/mux-audio.sh <silent-seedance.mp4> <elevenlabs-audio.mp3> <output.mp4>` after the Seedance clip has been downloaded. The script muxes the ElevenLabs audio onto the silent video with `ffmpeg` (AAC re-encode, `-shortest`). The muxed file is the canonical deliverable for that clip — use it (not the raw silent Seedance output) for stitching and review.
12. **Stitch if split:** If the script was split into segments, offer to stitch the final videos together with `ffmpeg` and provide both the stitched file and individual segments. For mixed-path ads (e.g. Clip 1 Path A, Clip 2 Path B), stitch using the Path-A Seedance output and the Path-B muxed output.

## Errors (user-facing)

- **401:** Bad or missing `KIE_API_KEY` — fix in `.env` (setup flow above).
- **402:** Out of credits on kie.ai — top up at [kie.ai/billing](https://kie.ai/billing).
- **400 / 422:** Validation or moderation — tighten prompt, remove disallowed content, check required enums (aspect ratio, duration). Kie.ai returns a human-readable message in `msg`.
- **429:** Rate limit — back off and retry. Default kie.ai rate limits are generous for paid accounts.
- **500 / 503:** Upstream model error — retry later; if repeated on a specific prompt, try tightening the prompt (content checker may be flagging it silently).
- **`successFlag: 2` or `3`:** Task-level failure. Read `data.error` for the reason. Common causes: content-checker rejection, stale or unreachable reference URL, invalid field combination.

## Supporting files

- [reference.md](reference.md) — endpoints, auth detail, polling, per-model `input` schemas, URL-hosting notes.
- [prompting/guide.md](prompting/guide.md) — marketing brief → API.
- **Seedance 2.0:**
  - [prompting/prompt-library/seedance-2.md](prompting/prompt-library/seedance-2.md) — main Seedance 2.0 model guide (platform rules, API parameters, style template directory).
  - [prompting/prompt-library/seedance-2-ugc.md](prompting/prompt-library/seedance-2-ugc.md) — 9-layer UGC selfie-style formula.
  - [prompting/prompt-library/seedance-2-premium-reveal.md](prompting/prompt-library/seedance-2-premium-reveal.md) — dark-void premium product reveal (no person).
  - [prompting/prompt-library/seedance-2-product-hero.md](prompting/prompt-library/seedance-2-product-hero.md) — elemental product hero with splash/effects (no person).
  - [prompting/prompt-library/seedance-2-studio-lookbook.md](prompting/prompt-library/seedance-2-studio-lookbook.md) — studio lookbook with voiceover.
  - [prompting/prompt-library/seedance-2-feature-walkthrough.md](prompting/prompt-library/seedance-2-feature-walkthrough.md) — fast-paced feature walkthrough demo.
  - [prompting/analyze-video/SKILL.md](prompting/analyze-video/SKILL.md) — reverse-engineer a reference video into a reusable Seedance 2.0 prompting template.
  - [prompting/clone-ad/SKILL.md](prompting/clone-ad/SKILL.md) — clone a reference video ad for a different product (end-to-end: analyze → adapt → generate).
- **Other models:**
  - [prompting/prompt-library/influencer-recreation.md](prompting/prompt-library/influencer-recreation.md) — analyze a reference photo and recreate the influencer.
  - [prompting/prompt-library/ugc-selfie-style.md](prompting/prompt-library/ugc-selfie-style.md) — cross-model UGC guide (iPhone aesthetic, negative prompts, per-model formulas).
  - [prompting/prompt-library/product-showcase.md](prompting/prompt-library/product-showcase.md) — product-in-hand video workflow (Nano Banana image → approve → video).
  - [prompting/prompt-library/nano-banana.md](prompting/prompt-library/nano-banana.md) — Nano Banana image prompting guide.
  - [prompting/prompt-library/character-sheet.md](prompting/prompt-library/character-sheet.md) — generate a 10-image character sheet for a new AI influencer from a text description.
  - [prompting/prompt-library/ugc-product-selfie.md](prompting/prompt-library/ugc-product-selfie.md) — UGC selfie-style still image: character + product + style references.
- [prompting/brand-voice-starter.md](prompting/brand-voice-starter.md) — template to copy into `MASTER_CONTEXT.md`.
