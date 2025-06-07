import json
import os
import subprocess
import sys

from PIL import Image

FPS = 24
CLIP_DURATION = 1.0
NUM_ROWS = 10
NUM_COLS = int(FPS * CLIP_DURATION)
THUMBNAIL_WIDTH = 320
THUMBNAIL_HEIGHT = 180


def get_video_duration(video_path):
    """Get the duration of a video using ffprobe."""
    cmd = 'ffprobe -i {} -show_entries format=duration -v quiet -of csv="p=0"'.format(
        video_path
    )
    output = subprocess.check_output(
        cmd, shell=True, stderr=subprocess.STDOUT  # Let this run in the shell
    )
    return float(output)


def extract_frame_clip(
    video_path, start_time, duration, output_dir, height, width, fps=FPS
):
    """
    Extract frames from a video, where each frame is taken at a specific timestamp.
    The frames represent a "clip" (duration of time).
    """
    frame_paths = []
    for i in range(int(duration * fps)):
        # Calculate the timestamp for the current frame
        timestamp = start_time + (i / fps)
        frame_path = os.path.join(output_dir, f"frame_{int(start_time * 1000 + i)}.png")

        # Run ffmpeg to extract the frame at the given timestamp
        cmd = [
            "ffmpeg",
            "-ss",
            str(timestamp),
            "-i",
            video_path,
            "-vframes",
            "1",
            "-s",
            f"{width}x{height}",
            "-f",
            "image2",
            frame_path,
        ]
        subprocess.run(cmd)
        frame_paths.append(frame_path)

    return frame_paths


def create_spritesheet(image_paths, rows, cols, thumb_width, thumb_height, output_path):
    """
    Create a spritesheet from extracted frames.
    """
    # Create a blank canvas with the appropriate size
    spritesheet_width = cols * thumb_width
    spritesheet_height = rows * thumb_height
    spritesheet = Image.new("RGB", (spritesheet_width, spritesheet_height))

    # Paste the images onto the canvas
    for i, image_path in enumerate(image_paths):
        row = i // cols
        col = i % cols
        img = Image.open(image_path)
        img = img.resize((thumb_width, thumb_height))  # Resize to thumbnail size
        spritesheet.paste(img, (col * thumb_width, row * thumb_height))

    spritesheet.save(output_path)


def video_to_spritesheet(
    video_path,
    clip_duration,
    fps,
    num_rows,
    num_cols,
    thumb_width,
    thumb_height,
):
    # Get video duration
    duration = get_video_duration(video_path)
    if duration is None:
        raise ValueError("Couldn't get video duration")

    # Calculate the jump between rows
    row_jump = duration / num_rows

    frame_dir = "frames"
    os.makedirs(frame_dir, exist_ok=True)

    image_paths = []

    for row_idx in range(num_rows):
        start_time = row_idx * row_jump
        clip_frames = extract_frame_clip(
            video_path,
            start_time,
            clip_duration,
            frame_dir,
            thumb_height,
            thumb_width,
            fps,
        )
        image_paths.extend(clip_frames)

    output_path = os.path.splitext(video_path)[0] + ".png"
    # Create the spritesheet with all the frames
    create_spritesheet(
        image_paths, num_rows, num_cols, thumb_width, thumb_height, output_path
    )

    # Clean up extracted frames
    for frame_path in image_paths:
        os.remove(frame_path)

    print(f"Spritesheet saved at {output_path}")


if __name__ == "__main__":
    video_to_spritesheet(
        sys.argv[1],
        CLIP_DURATION,
        FPS,
        NUM_ROWS,
        NUM_COLS,
        THUMBNAIL_WIDTH,
        THUMBNAIL_HEIGHT,
    )
