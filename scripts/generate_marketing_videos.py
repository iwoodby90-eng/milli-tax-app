"""
Generate Milli marketing videos using Sora 2.
5 clips × 8 seconds, mixed vertical + landscape for IG/TikTok + YouTube.
"""
import os
import sys
import json
import time
import traceback
from datetime import datetime
from dotenv import load_dotenv

sys.path.insert(0, os.path.abspath(''))
load_dotenv('/app/backend/.env')

from emergentintegrations.llm.openai.video_generation import OpenAIVideoGeneration

OUT_DIR = '/app/marketing_videos'
LOG_PATH = os.path.join(OUT_DIR, 'generation_log.json')
os.makedirs(OUT_DIR, exist_ok=True)

CLIPS = [
    {
        "id": "01_cinematic_luxury",
        "title": "Cinematic Luxury - City Skyline",
        "size": "720x1280",   # vertical, 9:16
        "duration": 8,
        "prompt": (
            "Ultra-cinematic luxury fintech commercial. Slow aerial drone glide over a "
            "rain-slick midnight city skyline, neon turquoise reflections on glass towers. "
            "A polished silver app interface materializes floating in mid-air, showing a "
            "'Tax Vault' balance ticking up with a soft turquoise glow. Volumetric fog, "
            "lens flares, anamorphic bokeh, color palette of obsidian black, brushed silver, "
            "and electric turquoise #13D8D1. The word 'MILLI' fades in as elegant thin serif "
            "letters at the end. Hyperreal, 8k, shot on ARRI Alexa."
        ),
    },
    {
        "id": "02_driver_pov_hud",
        "title": "Driver POV - Night HUD",
        "size": "1280x720",   # landscape, 16:9
        "duration": 8,
        "prompt": (
            "First-person driver POV inside a modern car at night, looking through the "
            "windshield at glowing city streets and traffic light trails. A futuristic "
            "translucent heads-up display in turquoise neon overlays the glass, showing "
            "real-time miles tracked '47.3 mi' and 'Tax Saved $182.40' counting upward. "
            "The HUD pulses softly. Reflections of taillights, light rain on glass. "
            "Color palette black, silver, electric turquoise. Cinematic, photoreal, "
            "Blade Runner inspired, 8k."
        ),
    },
    {
        "id": "03_lifestyle_gigworker",
        "title": "Lifestyle - Gig Worker Smile",
        "size": "720x1280",   # vertical
        "duration": 8,
        "prompt": (
            "A confident gig-economy driver in their late 20s steps out of a clean modern "
            "sedan at golden hour in an upscale urban neighborhood. They glance at their "
            "smartphone screen which clearly shows a luxury black and turquoise banking "
            "app with a growing 'Tax Vault' balance animating from $1,240 to $1,512. "
            "They smile and nod with quiet satisfaction. Shallow depth of field, warm "
            "golden backlight, lifestyle commercial aesthetic, photoreal, cinematic, "
            "color graded with hints of turquoise."
        ),
    },
    {
        "id": "04_product_kinetic_type",
        "title": "Product - Kinetic Typography",
        "size": "1280x720",   # landscape
        "duration": 8,
        "prompt": (
            "Sleek motion-graphics commercial on a deep matte black background. "
            "Bold sans-serif words animate in with sharp kinetic motion: 'EARN.' then "
            "'TRACK.' then 'SAVE 30%.' then 'AUTOMATICALLY.' Each word in brushed "
            "silver and electric turquoise #13D8D1 with subtle particle dust. Between "
            "words, glimpses of a phone screen showing a luxury banking dashboard, "
            "a turquoise progress ring filling up, dollar bills folding into a vault "
            "door. Apple-style product film, ultra clean, 8k, motion blur transitions."
        ),
    },
    {
        "id": "05_hero_montage",
        "title": "Hero Brand Montage",
        "size": "720x1280",   # vertical
        "duration": 8,
        "prompt": (
            "Luxury hero brand film. Fast-cut cinematic montage on dark obsidian "
            "background: a sleek modern sedan accelerating away on a wet midnight "
            "street, close-up of a smartphone displaying a turquoise glowing mileage "
            "ring filling up, hands gripping a leather steering wheel under neon "
            "reflections, an elegant translucent vault door slowly opening to reveal "
            "warm turquoise light pouring out, ending on a polished silver lowercase "
            "wordmark 'milli' crystallizing on pure black. Shallow depth of field, "
            "anamorphic lens flares, palette of obsidian black, brushed silver, "
            "electric turquoise. Hyperreal, 8k, Apple-style product film aesthetic."
        ),
    },
]


def load_log():
    if os.path.exists(LOG_PATH):
        with open(LOG_PATH) as f:
            return json.load(f)
    return {}


def save_log(log):
    with open(LOG_PATH, 'w') as f:
        json.dump(log, f, indent=2)


def main():
    api_key = os.environ.get('EMERGENT_LLM_KEY')
    if not api_key:
        print('EMERGENT_LLM_KEY missing', flush=True)
        sys.exit(1)

    log = load_log()
    for clip in CLIPS:
        cid = clip['id']
        out_path = os.path.join(OUT_DIR, f"{cid}.mp4")
        if log.get(cid, {}).get('status') == 'done' and os.path.exists(out_path):
            print(f"[skip] {cid} already done", flush=True)
            continue

        print(f"[start] {cid} {clip['size']} {clip['duration']}s", flush=True)
        log[cid] = {
            "title": clip['title'],
            "size": clip['size'],
            "duration": clip['duration'],
            "status": "running",
            "started_at": datetime.utcnow().isoformat(),
        }
        save_log(log)

        try:
            gen = OpenAIVideoGeneration(api_key=api_key)
            video_bytes = gen.text_to_video(
                prompt=clip['prompt'],
                model="sora-2",
                size=clip['size'],
                duration=clip['duration'],
                max_wait_time=900,
            )
            if video_bytes:
                gen.save_video(video_bytes, out_path)
                log[cid].update({
                    "status": "done",
                    "path": out_path,
                    "finished_at": datetime.utcnow().isoformat(),
                })
                print(f"[done] {cid} -> {out_path}", flush=True)
            else:
                log[cid].update({
                    "status": "failed",
                    "error": "no video bytes returned",
                    "finished_at": datetime.utcnow().isoformat(),
                })
                print(f"[fail] {cid} returned no bytes", flush=True)
        except Exception as e:
            log[cid].update({
                "status": "failed",
                "error": str(e),
                "trace": traceback.format_exc(),
                "finished_at": datetime.utcnow().isoformat(),
            })
            print(f"[error] {cid}: {e}", flush=True)
        finally:
            save_log(log)

    print("[complete] all clips processed", flush=True)


if __name__ == '__main__':
    main()
