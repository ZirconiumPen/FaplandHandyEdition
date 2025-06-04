from PIL import Image

gif_path = "1.gif"  # Your GIF file
with Image.open(gif_path) as gif:
    print(f"GIF: {gif_path}")
    print(f"Total frames: {gif.n_frames}")

    for frame_num in range(gif.n_frames):
        gif.seek(frame_num)
        duration = gif.info.get("duration", 100)  # milliseconds
        print(f"Frame {frame_num + 1}: {duration}ms ({duration/1000:.3f}s)")

    # Calculate average
    total_duration = sum(gif.info.get("duration", 100) for _ in range(gif.n_frames))
    avg_duration = total_duration / gif.n_frames
    fps = 1000 / avg_duration
    print(f"\nAverage: {avg_duration:.1f}ms per frame")
    print(f"Effective FPS: {fps:.1f}")
