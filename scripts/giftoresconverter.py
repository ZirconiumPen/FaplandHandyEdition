#!/usr/bin/env python3
"""
GIF to Godot Sprite Sheet and TRES File Generator

This script converts GIF files (1-100).gif to sprite sheets and creates .tres resource files
for use with AnimatedSprite2D in Godot.

Usage:
    python gif_to_tres.py

Requirements:
    - GIF files named as 1.gif, 2.gif, ..., 100.gif
    - PIL (Pillow) for image processing: pip install Pillow

The script will:
1. Extract frames from each GIF
2. Create sprite sheets from the frames
3. Generate .tres files for Godot
"""

import math
import os

from PIL import Image

# Configuration
GIF_COUNT = 103
GIF_DIR = "../media/"  # Directory containing GIF files
SPRITE_SHEET_DIR = "../sprite_sheets"  # Directory to save sprite sheets
TRES_DIR = "../sprites/tres_files"  # Directory to save .tres files
ANIMATION_NAME = "animation"  # Name of the animation in SpriteFrames
MAX_FRAMES_PER_ROW = 10  # Maximum frames per row in sprite sheet


def extract_gif_frames(gif_path):
    """Extract all frames from a GIF file"""
    frames = []
    try:
        with Image.open(gif_path) as gif:
            # Get original duration for each frame (in milliseconds)
            durations = []

            for frame_num in range(gif.n_frames):
                gif.seek(frame_num)

                # Convert to RGBA to handle transparency - NO RESIZING OR QUALITY LOSS
                frame = gif.convert("RGBA")
                frames.append(frame.copy())  # Keep original resolution and quality

                # Get frame duration (default to 100ms if not specified)
                duration = gif.info.get("duration", 100)
                durations.append(duration / 1000.0)  # Convert to seconds

            print(f"Extracted {len(frames)} frames from {os.path.basename(gif_path)}")
            return frames, durations

    except Exception as e:
        print(f"Error extracting frames from {gif_path}: {e}")
        return [], []


def create_sprite_sheet(frames, output_path):
    """Create a sprite sheet from a list of frames"""
    if not frames:
        return None, None, None, None

    # Get frame dimensions (assuming all frames are the same size)
    frame_width, frame_height = frames[0].size
    num_frames = len(frames)

    # Calculate grid layout
    frames_per_row = min(num_frames, MAX_FRAMES_PER_ROW)
    frames_per_col = math.ceil(num_frames / frames_per_row)

    # Create sprite sheet
    sheet_width = frames_per_row * frame_width
    sheet_height = frames_per_col * frame_height
    sprite_sheet = Image.new("RGBA", (sheet_width, sheet_height), (0, 0, 0, 0))

    # Place frames in the sprite sheet
    for i, frame in enumerate(frames):
        row = i // frames_per_row
        col = i % frames_per_row

        x = col * frame_width
        y = row * frame_height

        sprite_sheet.paste(frame, (x, y))

    # Save sprite sheet with maximum quality (no compression, lossless PNG)
    try:
        # Use optimize=False and compress_level=0 for maximum quality
        sprite_sheet.save(output_path, "PNG", optimize=False, compress_level=0)
        print(
            f"Created sprite sheet: {os.path.basename(output_path)} ({frames_per_row}x{frames_per_col} grid)"
        )
        return frame_width, frame_height, frames_per_row, frames_per_col
    except Exception as e:
        print(f"Error saving sprite sheet {output_path}: {e}")
        return None, None, None, None


def create_tres_content(
    sprite_sheet_path,
    frame_durations,
    frame_width,
    frame_height,
    frames_per_row,
    frames_per_col,
    total_frames,
):
    """Generate the content for a .tres file following Godot's exact format"""

    # Calculate load_steps: 1 (ExtResource) + total_frames (SubResources) + 1 (main resource)
    load_steps = 1 + total_frames + 1

    # Start with the header
    tres_content = f"""[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]

[ext_resource type="Texture2D" path="{sprite_sheet_path}" id="1_sprite"]

"""

    # Add SubResource definitions for each frame
    atlas_texture_ids = []
    for i in range(total_frames):
        row = i // frames_per_row
        col = i % frames_per_row

        # Calculate pixel coordinates
        x = col * frame_width
        y = row * frame_height

        # Create unique AtlasTexture ID
        atlas_id = f"AtlasTexture_{i+1:05d}"
        atlas_texture_ids.append(atlas_id)

        tres_content += f"""[sub_resource type="AtlasTexture" id="{atlas_id}"]
atlas = ExtResource("1_sprite")
region = Rect2({x}, {y}, {frame_width}, {frame_height})

"""

    # Add the main resource with animations
    tres_content += """[resource]
animations = [{
"frames": [],
"loop": true,
"name": &"default",
"speed": 1.0
}, {
"frames": ["""

    # Add each frame with 40ms duration (24 FPS)
    for i in range(total_frames):
        # Fixed 40ms duration for 24 FPS (40ms = 0.04 seconds, ignore original GIF timing)
        duration = 0.04

        tres_content += f"""{{
"duration": {duration:.2f},
"texture": SubResource("{atlas_texture_ids[i]}")
}}"""
        if i < total_frames - 1:
            tres_content += ","

    tres_content += f"""],
"loop": true,
"name": &"{ANIMATION_NAME}",
"speed": 1.0
}}]"""

    return tres_content


def process_gif_to_tres(gif_num):
    """Process a single GIF file to sprite sheet and .tres file"""
    gif_filename = f"{gif_num}.gif"
    gif_path = os.path.join(GIF_DIR, gif_filename)

    # Check if GIF exists
    if not os.path.exists(gif_path):
        print(f"Warning: {gif_filename} not found, skipping...")
        return False

    print(f"\nProcessing {gif_filename}...")

    # Extract frames from GIF
    frames, durations = extract_gif_frames(gif_path)
    if not frames:
        return False

    # Create sprite sheet
    sprite_sheet_filename = f"{gif_num}.png"
    sprite_sheet_path = os.path.join(SPRITE_SHEET_DIR, sprite_sheet_filename)

    frame_width, frame_height, frames_per_row, frames_per_col = create_sprite_sheet(
        frames, sprite_sheet_path
    )
    if frame_width is None:
        return False

    # Generate .tres content
    # Use relative path for Godot resource reference
    relative_sprite_path = f"res://sprite_sheets/{sprite_sheet_filename}"
    tres_content = create_tres_content(
        relative_sprite_path,
        durations,
        frame_width,
        frame_height,
        frames_per_row,
        frames_per_col,
        len(frames),
    )

    # Write .tres file
    tres_filename = f"{gif_num}.tres"
    tres_path = os.path.join(TRES_DIR, tres_filename)

    try:
        with open(tres_path, "w", encoding="utf-8") as f:
            f.write(tres_content)
        print(f"Created: {tres_filename}")
        return True
    except Exception as e:
        print(f"Error writing {tres_filename}: {e}")
        return False


def main():
    """Main function to process all GIF files"""

    print("GIF to Godot Sprite Sheet and TRES Converter")
    print("=" * 50)
    print(f"Looking for GIF files: 1.gif to {GIF_COUNT}.gif")
    print(f"Sprite sheets will be saved to: {SPRITE_SHEET_DIR}")
    print(f"TRES files will be saved to: {TRES_DIR}")
    print()

    # Create output directories if they don't exist
    for directory in [SPRITE_SHEET_DIR, TRES_DIR]:
        if not os.path.exists(directory):
            os.makedirs(directory)
            print(f"Created directory: {directory}")

    successful_conversions = 0

    for i in range(1, GIF_COUNT + 1):
        if process_gif_to_tres(i):
            successful_conversions += 1

    print(f"\n" + "=" * 50)
    print(
        f"Conversion complete! Successfully processed {successful_conversions} GIF files."
    )
    print(f"\nGenerated files:")
    print(f"- Sprite sheets: {SPRITE_SHEET_DIR}/")
    print(f"- TRES resources: {TRES_DIR}/")

    print(f"\nTo use in Godot:")
    print(
        f"1. Copy the '{SPRITE_SHEET_DIR}' and '{TRES_DIR}' folders to your Godot project"
    )
    print(f"2. Add an AnimatedSprite2D node to your scene")
    print(f"3. Set the SpriteFrames property to load one of the .tres files")
    print(f"4. The animation will preserve the original GIF timing")
    print(f'5. Call play("{ANIMATION_NAME}") to start the animation')

    print(f"\nNote: Original GIF frame durations are preserved in the TRES files.")


if __name__ == "__main__":
    main()
