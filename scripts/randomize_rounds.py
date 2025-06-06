import pandas as pd
import os
import random
import shutil
from pathlib import Path

def randomize_video_rounds(csv_path, video_directory, dry_run=False):
    """
    Randomize video file names within their difficulty groups based on CSV data.
    Renames files in the same directory using temp files to avoid naming conflicts.
    
    Args:
        csv_path (str): Path to the CSV file containing round data
        video_directory (str): Directory containing video files (1.mp4, 2.mp4, etc.)
        dry_run (bool): If True, only print what would be done without actually renaming files
    """
    
    # Read the CSV file
    print("Reading CSV file...")
    df = pd.read_csv(csv_path)
    
    # Clean column names (remove whitespace)
    df.columns = df.columns.str.strip()
    
    # Print CSV info
    print(f"Loaded {len(df)} rounds from CSV")
    print(f"Difficulty distribution:")
    difficulty_counts = df['Difficulty'].value_counts().sort_index()
    for difficulty, count in difficulty_counts.items():
        print(f"  Difficulty {difficulty}: {count} rounds")
    
    # Group by difficulty and create simple mapping
    difficulty_groups = df.groupby('Difficulty')
    
    print("\nRandomizing within difficulty groups...")
    round_mapping = {}
    
    for difficulty, group in difficulty_groups:
        # Get all rounds in this difficulty
        rounds_in_difficulty = group['Fapland Round'].tolist()
        
        # Create shuffled copy
        shuffled_rounds = rounds_in_difficulty.copy()
        random.shuffle(shuffled_rounds)
        
        # Create mapping: old -> new
        for old_round, new_round in zip(rounds_in_difficulty, shuffled_rounds):
            round_mapping[old_round] = new_round
        
        print(f"Difficulty {difficulty}: {len(rounds_in_difficulty)} rounds shuffled")
    
    print(f"Mapping created: {len(round_mapping)} unique 1:1 mappings")

    # Setup directory
    video_dir = Path(video_directory)

    # Find video, gif, funscript, and sprite sheet files
    video_extensions = ['.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm']
    found_videos = {}
    found_gifs = {}
    found_funscripts = {}
    found_sprites = {}
    
    # Setup sprite sheets directory
    sprite_dir = Path("sprite_sheets/")
    
    print(f"\nScanning for video, gif, funscript, and sprite files...")
    print(f"Video directory: {video_dir}")
    print(f"Sprite directory: {sprite_dir}")
    
    for round_num in range(1, 104):  # 1 to 103
        # Look for video files
        for ext in video_extensions:
            video_file = video_dir / f"{round_num}{ext}"
            if video_file.exists():
                found_videos[round_num] = video_file
                break
        
        # Look for gif files
        gif_file = video_dir / f"{round_num}.gif"
        if gif_file.exists():
            found_gifs[round_num] = gif_file
        
        # Look for funscript files
        funscript_file = video_dir / f"{round_num}.funscript"
        if funscript_file.exists():
            found_funscripts[round_num] = funscript_file
        
        # Look for sprite sheet files
        sprite_file = sprite_dir / f"{round_num}.png"
        if sprite_file.exists():
            found_sprites[round_num] = sprite_file
    
    print(f"Found {len(found_videos)} video files")
    print(f"Found {len(found_gifs)} gif files")
    print(f"Found {len(found_funscripts)} funscript files")
    print(f"Found {len(found_sprites)} sprite sheet files")

    # Create reverse mapping for easier lookup
    new_to_old_mapping = {v: k for k, v in round_mapping.items()}

    # Process files - Step 1: Rename to temp files
    print(f"\n{'DRY RUN - ' if dry_run else ''}Step 1: Renaming to temporary files...")
    temp_videos = {}
    temp_gifs = {}
    temp_funscripts = {}
    temp_sprites = {}
    renamed_count = 0
    
    for old_round, new_round in round_mapping.items():
        # Handle video files
        if old_round in found_videos:
            old_video = found_videos[old_round]
            temp_video = video_dir / f"temp_{new_round}{old_video.suffix}"
            
            if dry_run:
                print(f"  Would rename: {old_video.name} -> {temp_video.name}")
                temp_videos[new_round] = temp_video
            else:
                try:
                    old_video.rename(temp_video)
                    temp_videos[new_round] = temp_video
                    print(f"  Renamed: {old_video.name} -> {temp_video.name}")
                    renamed_count += 1
                except Exception as e:
                    print(f"  Error renaming {old_video.name}: {e}")
        
        # Handle gif files
        if old_round in found_gifs:
            old_gif = found_gifs[old_round]
            temp_gif = video_dir / f"temp_{new_round}.gif"
            
            if dry_run:
                print(f"  Would rename: {old_gif.name} -> {temp_gif.name}")
                temp_gifs[new_round] = temp_gif
            else:
                try:
                    old_gif.rename(temp_gif)
                    temp_gifs[new_round] = temp_gif
                    print(f"  Renamed: {old_gif.name} -> {temp_gif.name}")
                    renamed_count += 1
                except Exception as e:
                    print(f"  Error renaming {old_gif.name}: {e}")
        
        # Handle funscript files
        if old_round in found_funscripts:
            old_funscript = found_funscripts[old_round]
            temp_funscript = video_dir / f"temp_{new_round}.funscript"
            
            if dry_run:
                print(f"  Would rename: {old_funscript.name} -> {temp_funscript.name}")
                temp_funscripts[new_round] = temp_funscript
            else:
                try:
                    old_funscript.rename(temp_funscript)
                    temp_funscripts[new_round] = temp_funscript
                    print(f"  Renamed: {old_funscript.name} -> {temp_funscript.name}")
                    renamed_count += 1
                except Exception as e:
                    print(f"  Error renaming {old_funscript.name}: {e}")
        
        # Handle sprite sheet files
        if old_round in found_sprites:
            old_sprite = found_sprites[old_round]
            temp_sprite = sprite_dir / f"temp_{new_round}.png"
            
            if dry_run:
                print(f"  Would rename: sprite_sheets/{old_sprite.name} -> sprite_sheets/{temp_sprite.name}")
                temp_sprites[new_round] = temp_sprite
            else:
                try:
                    old_sprite.rename(temp_sprite)
                    temp_sprites[new_round] = temp_sprite
                    print(f"  Renamed: sprite_sheets/{old_sprite.name} -> sprite_sheets/{temp_sprite.name}")
                    renamed_count += 1
                except Exception as e:
                    print(f"  Error renaming sprite_sheets/{old_sprite.name}: {e}")

    # Process files - Step 2: Remove temp prefix
    print(f"\n{'DRY RUN - ' if dry_run else ''}Step 2: Removing temp prefixes...")
    final_count = 0
    
    # Finalize video files
    for new_round, temp_video in temp_videos.items():
        final_video = video_dir / f"{new_round}{temp_video.suffix}"
        
        if dry_run:
            print(f"  Would rename: {temp_video.name} -> {final_video.name}")
            final_count += 1
        else:
            try:
                temp_video.rename(final_video)
                print(f"  Renamed: {temp_video.name} -> {final_video.name}")
                final_count += 1
            except Exception as e:
                print(f"  Error finalizing {temp_video.name}: {e}")
    
    # Finalize gif files
    for new_round, temp_gif in temp_gifs.items():
        final_gif = video_dir / f"{new_round}.gif"
        
        if dry_run:
            print(f"  Would rename: {temp_gif.name} -> {final_gif.name}")
            final_count += 1
        else:
            try:
                temp_gif.rename(final_gif)
                print(f"  Renamed: {temp_gif.name} -> {final_gif.name}")
                final_count += 1
            except Exception as e:
                print(f"  Error finalizing {temp_gif.name}: {e}")
    
    # Finalize funscript files
    for new_round, temp_funscript in temp_funscripts.items():
        final_funscript = video_dir / f"{new_round}.funscript"
        
        if dry_run:
            print(f"  Would rename: {temp_funscript.name} -> {final_funscript.name}")
            final_count += 1
        else:
            try:
                temp_funscript.rename(final_funscript)
                print(f"  Renamed: {temp_funscript.name} -> {final_funscript.name}")
                final_count += 1
            except Exception as e:
                print(f"  Error finalizing {temp_funscript.name}: {e}")
    
    # Finalize sprite sheet files
    for new_round, temp_sprite in temp_sprites.items():
        final_sprite = sprite_dir / f"{new_round}.png"
        
        if dry_run:
            print(f"  Would rename: sprite_sheets/{temp_sprite.name} -> sprite_sheets/{final_sprite.name}")
            final_count += 1
        else:
            try:
                temp_sprite.rename(final_sprite)
                print(f"  Renamed: sprite_sheets/{temp_sprite.name} -> sprite_sheets/{final_sprite.name}")
                final_count += 1
            except Exception as e:
                print(f"  Error finalizing sprite_sheets/{temp_sprite.name}: {e}")

    # Update CSV with new Fapland Round numbers
    print(f"\n{'DRY RUN - ' if dry_run else ''}Updating CSV with new round numbers...")
    
    if not dry_run:
        # Create updated dataframe - go line by line and update Fapland Round
        updated_rows = []
        for _, row in df.iterrows():
            new_row = row.copy()
            old_round = row['Fapland Round']
            new_round = round_mapping[old_round]
            new_row['Fapland Round'] = new_round
            updated_rows.append(new_row)
        
        # Create new dataframe and sort by new Fapland Round
        updated_df = pd.DataFrame(updated_rows)
        updated_df = updated_df.sort_values('Fapland Round').reset_index(drop=True)
        
        # Save updated CSV

        updated_csv_path = "rounds_fapland.csv"
        updated_df.to_csv(updated_csv_path, index=False)   # overwrite previous csv file
        print(f"  Updated CSV saved as: {updated_csv_path}")
    
    # Create mapping report
    report_file = "randomization_report.txt"
    print(f"\nCreating mapping report: {report_file}")
    
    if not dry_run:
        with open(report_file, 'w') as f:
            f.write("Video Randomization Report\n")
            f.write("=" * 30 + "\n\n")
            
            f.write("Files Created:\n")
            f.write("- randomization_report.txt (this report)\n\n")
            
            f.write("Mapping Summary:\n")
            f.write(f"Total rounds: {len(round_mapping)}\n")
            f.write(f"Videos found: {len(found_videos)}\n")
            f.write(f"GIFs found: {len(found_gifs)}\n")
            f.write(f"Funscripts found: {len(found_funscripts)}\n")
            f.write(f"Sprite sheets found: {len(found_sprites)}\n")
            f.write(f"Total files processed: {final_count}\n\n")
            
            f.write("Difficulty Groups:\n")
            for difficulty, group in difficulty_groups:
                f.write(f"Difficulty {difficulty}: {len(group)} rounds\n")
            f.write("\n")
            
            f.write("Round Mapping (Original -> New):\n")
            f.write("-" * 30 + "\n")
            for difficulty, group in difficulty_groups:
                f.write(f"\nDifficulty {difficulty}:\n")
                for _, row in group.iterrows():
                    old_round = row['Fapland Round']
                    new_round = round_mapping[old_round]
                    hero_name = row['FapHero name']
                    f.write(f"  {old_round:3d} -> {new_round:3d} ({hero_name})\n")

    print(f"\n{'DRY RUN COMPLETE' if dry_run else 'RANDOMIZATION COMPLETE'}")
    print(f"Total files processed: {final_count} (videos + gifs + funscripts)")
    print(f"Videos: {len(found_videos)}, GIFs: {len(found_gifs)}, Funscripts: {len(found_funscripts)}")
    if not dry_run:
        print(f"Files renamed in: {video_dir}")
        print(f"Updated CSV: rounds_fapland_randomized.csv")
        print(f"Report saved: {report_file}")
        print("All video, gif, and funscript files have been renamed to match!")
    else:
        print("Note: CSV would be updated with new round numbers")
        print("All video, gif, and funscript files would be renamed to match")

def main():
    """Main function with example usage"""
    
    # Configuration - UPDATE THESE PATHS
    csv_file = "rounds_fapland.csv"  # Path to your CSV file
    video_folder = "media/"  # Current directory, change to your video folder path
    
    print("Video Round Randomizer")
    print("=" * 30)
    
    # Check if CSV exists
    if not os.path.exists(csv_file):
        print(f"Error: CSV file '{csv_file}' not found!")
        print("Please update the csv_file path in the script.")
        return
    
    # Check if video directory exists
    if not os.path.exists(video_folder):
        print(f"Error: Video directory '{video_folder}' not found!")
        print("Please update the video_folder path in the script.")
        return
    
    
    print(f"CSV file: {csv_file}")
    print(f"Video directory: {video_folder}")
    print("Files will be renamed in the same directory using temp files to avoid conflicts.")
    
    '''choice = input("\nRun dry run first? (y/n): ").lower().strip()
    if choice in ['y', 'yes']:
        print("\n" + "="*50)
        print("DRY RUN - No files will be renamed")
        print("="*50)
        randomize_video_rounds(csv_file, video_folder, dry_run=True)
        
        proceed = input("\nProceed with actual randomization? (y/n): ").lower().strip()
        if proceed not in ['y', 'yes']:
            print("Cancelled.")
            return'''
    
    print("\n" + "="*50)
    print("EXECUTING RANDOMIZATION")
    print("="*50)
    randomize_video_rounds(csv_file, video_folder, dry_run=False)

if __name__ == "__main__":
    main()