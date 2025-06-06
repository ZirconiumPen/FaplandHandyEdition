import json
import logging
import os
import sys
import threading
import time
import traceback
from datetime import datetime
from pathlib import Path

import keyboard  # pip install keyboard
import requests
import vlc

# Clear log file on startup
LOG_FILE = "handy_sync.log"
if os.path.exists(LOG_FILE):
    os.remove(LOG_FILE)

# Setup comprehensive logging
logging.basicConfig(
    level=logging.DEBUG,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
        logging.StreamHandler(sys.stdout),
    ],
)

logger = logging.getLogger(__name__)


# Redirect stderr to log file as well
class LoggingWriter:
    def __init__(self, level):
        self.level = level

    def write(self, message):
        if message.strip():
            self.level(message.strip())

    def flush(self):
        pass


sys.stderr = LoggingWriter(logger.error)

# Configuration
# Load firmware version from config and set appropriate API
def get_handy_api():
    try:
        with open("handy_config.json", "r") as f:
            config = json.load(f)
        firmware = config.get("firmware", 4)
        if firmware == 3:
            return "https://www.handyfeeling.com/api/handy/v2", firmware
        else:
            return "https://www.handyfeeling.com/api/handy-rest/v3", firmware
    except:
        return "https://www.handyfeeling.com/api/handy-rest/v3", 4  # Default to v3

HANDY_API, FIRMWARE_VERSION = get_handy_api()
estimated_offset_ms = 0
round_trip_time = 0


# Load from config file only - no defaults
def load_handy_config():
    try:
        with open("handy_config.json", "r") as f:
            config = json.load(f)
        access_token = config.get("access_token", "")
        app_id = config.get("app_id", "")
        if not access_token or not app_id:
            logger.info("❌ Please configure your Handy API keys using the game menu first!")
            sys.exit(1)
        return access_token, app_id
    except FileNotFoundError:
        logger.info("❌ No Handy configuration found! Use the game menu to set up your API keys.")
        sys.exit(1)


ACCESS_TOKEN, APP_ID = load_handy_config()

# Read pause configuration from file
original_max_pauses: int = 1
max_pauses: int = 1
pause_duration: int = 5
pauses_used: int = 0


def load_pause_config():
    global max_pauses, pause_duration, pauses_used, original_max_pauses
    try:
        with open("pause_config.json", "r") as f:
            pause_data = json.load(f)

        # Find the most recent entry
        if "entries" in pause_data and pause_data["entries"]:
            # Sort by timestamp to get the latest entry
            latest_entry = max(pause_data["entries"], key=lambda x: x["timestamp"])

            logger.info(
                f"🔍 DEBUG: Found {len(pause_data['entries'])} entries in pause config"
            )
            logger.info(f"🔍 DEBUG: Latest entry: {latest_entry}")

            max_pauses = int(latest_entry["max_pauses"])
            original_max_pauses = max_pauses
            pause_duration = latest_entry["pause_duration"]

            # Log the full history for debugging
            logger.info("📜 PAUSE CONFIG HISTORY:")
            for i, entry in enumerate(
                sorted(pause_data["entries"], key=lambda x: x["timestamp"])
            ):
                logger.info(
                    f"  {i+1}. {entry['timestamp']} | {entry['writer']} | pauses={entry['max_pauses']} | reason={entry.get('reason', 'unknown')}"
                )

        else:
            # Fallback for old format or empty file
            logger.warning("⚠️ No entries found, using defaults")
            max_pauses = 1
            original_max_pauses = 1
            pause_duration = 5

        logger.info(
            f"📝 Loaded pause config: {max_pauses} max, {pause_duration}s duration, {pauses_used} used"
        )

    except FileNotFoundError:
        logger.warning("⚠️ Pause config file not found, using defaults")
        max_pauses = 1
        original_max_pauses = 1
        pause_duration = 5
    except Exception as e:
        logger.error(f"Failed to read pause config file: {e}")
        raise


def save_pause_config(reason="unknown"):
    global max_pauses, pause_duration, pauses_used
    try:
        # FIX: Use UTC time instead of local time
        timestamp = datetime.utcnow().isoformat() + "Z"

        logger.info(
            f"🔍 DEBUG: About to save - max_pauses={max_pauses}, pauses_used={pauses_used}, reason={reason}"
        )

        # Read existing data
        try:
            with open("pause_config.json", "r") as f:
                pause_data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            pause_data = {"entries": []}

        # Add new entry
        new_entry = {
            "timestamp": timestamp,
            "max_pauses": max_pauses,
            "pause_duration": pause_duration,
            "writer": "python",
            "reason": reason,
        }

        pause_data["entries"].append(new_entry)

        # Keep only last 50 entries to prevent file from getting too large
        if len(pause_data["entries"]) > 50:
            pause_data["entries"] = pause_data["entries"][-50:]

        # Write back to file
        with open("pause_config.json", "w") as f:
            json.dump(pause_data, f, indent=2)

        logger.info(f"💾 Saved pause config: {new_entry}")

    except Exception as e:
        logger.error(f"Error saving pause config: {e}")


load_pause_config()


def log_system_info():
    """Log system and dependency information"""
    logger.info("=== SYSTEM INFO ===")
    logger.info(f"Python version: {sys.version}")
    logger.info(f"Working directory: {os.getcwd()}")
    logger.info(f"Script arguments: {sys.argv}")

    # Check dependencies
    try:
        import requests

        logger.info(f"Requests version: {requests.__version__}")
    except Exception as e:
        logger.error(f"Requests import error: {e}")

    try:
        import vlc

        logger.info(f"VLC Python binding available")

        # Try to get VLC version info
        try:
            version_info = (
                vlc.libvlc_get_version().decode()
                if hasattr(vlc, "libvlc_get_version")
                else "Unknown"
            )
            logger.info(f"VLC version info: {version_info}")
        except Exception as e:
            logger.warning(f"Could not get VLC version: {e}")

        # Test creating a basic VLC instance
        try:
            test_instance = vlc.Instance(["--intf", "dummy"])
            if test_instance is not None:
                logger.info("✅ VLC instance creation test: SUCCESS")
                test_player = test_instance.media_player_new()
                if test_player is not None:
                    logger.info("✅ VLC media player creation test: SUCCESS")
                else:
                    logger.warning("⚠️ VLC media player creation test: FAILED")
            else:
                logger.warning("⚠️ VLC instance creation test: FAILED")
        except Exception as e:
            logger.warning(f"⚠️ VLC test failed: {e}")

    except Exception as e:
        logger.error(f"VLC import error: {e}")
        logger.error("💡 VLC is required! Install with:")
        logger.error("   1. Download VLC: https://www.videolan.org/vlc/")
        logger.error("   2. Install python-vlc: pip install python-vlc")

    try:
        import keyboard

        logger.info(f"Keyboard library available")
    except Exception as e:
        logger.error(f"Keyboard import error: {e}")
        logger.error("💡 Install keyboard library: pip install keyboard")

    logger.info("===================")


def check_network_connectivity():
    """Test basic network connectivity"""
    try:
        logger.info("Testing network connectivity...")
        response = requests.get("https://www.google.com", timeout=5)
        logger.info(f"Network test successful: {response.status_code}")
        return True
    except Exception as e:
        logger.error(f"Network connectivity failed: {e}")
        return False


def get_server_time():
    """Get server time from Handy API"""
    try:
        logger.debug("Getting server time...")
        resp = requests.get(
            f"https://www.handyfeeling.com/api/handy/v2/servertime", timeout=10
        )
        resp.raise_for_status()
        server_time = resp.json()["serverTime"]
        logger.debug(f"Server time received: {server_time}")
        return server_time
    except requests.exceptions.Timeout:
        logger.error("Timeout getting server time")
        raise
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error getting server time: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error getting server time: {e}")
        raise


def sync_server_time(tries=10):
    """Sync with Handy server time"""
    global estimated_offset_ms, round_trip_time
    try:
        logger.info(f"Syncing server time with {tries} attempts...")
        total_offset = 0
        successful_syncs = 0

        for attempt in range(tries):
            try:
                t_start = int(time.time() * 1000)
                t_server = get_server_time()
                t_end = int(time.time() * 1000)
                rtd = t_end - t_start
                round_trip_time += rtd
                offset = (t_server + rtd / 2) - t_end
                total_offset += offset
                successful_syncs += 1
                logger.debug(
                    f"Sync attempt {attempt + 1}: offset = {offset}ms, RTD = {rtd}ms"
                )
            except Exception as e:
                logger.warning(f"Sync attempt {attempt + 1} failed: {e}")
                continue

        if successful_syncs == 0:
            raise Exception("All server time sync attempts failed")

        estimated_offset_ms = round(total_offset / successful_syncs)
        round_trip_time = round(round_trip_time / successful_syncs)
        logger.info(f"⏱️ Server time synced successfully: {estimated_offset_ms}ms offset ({successful_syncs}/{tries} attempts succeeded)")
        return True

    except Exception as e:
        logger.error(f"Failed to sync server time: {e}")
        return False


def get_estimated_server_time():
    """Get estimated server time"""
    server_time = int(time.time() * 1000) + estimated_offset_ms
    logger.debug(f"Estimated server time: {server_time}")
    return server_time


def upload_funscript(funscript_path):
    """Upload funscript to Handy servers"""
    try:
        logger.info(f"Uploading funscript: {funscript_path}")

        if not os.path.exists(funscript_path):
            logger.error(f"Funscript file not found: {funscript_path}")
            return None

        # Check file size
        file_size = os.path.getsize(funscript_path)
        logger.info(f"Funscript file size: {file_size} bytes")

        with open(funscript_path, "rb") as file:
            logger.debug("Making upload request to Handy API...")
            response = requests.post(
                "https://www.handyfeeling.com/api/hosting/v2/upload",
                headers={"accept": "application/json"},
                files={"file": file},
                timeout=30,
            )

        logger.debug(f"Upload response status: {response.status_code}")
        logger.debug(f"Upload response text: {response.text}")

        response.raise_for_status()
        upload_result = response.json()
        script_url = upload_result["url"]

        logger.info(f"✅ Funscript uploaded successfully to: {script_url}")
        return script_url

    except requests.exceptions.Timeout:
        logger.error("Timeout uploading funscript")
        return None
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error uploading funscript: {e}")
        return None
    except Exception as e:
        logger.error(f"Unexpected error uploading funscript: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        return None


def setup_hssp(script_url):
    """Setup HSSP mode on Handy device"""
    try:
        headers = {
            "X-Connection-Key": ACCESS_TOKEN,
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {APP_ID}",
        }

        logger.info("Setting device to HSSP mode...")
        mode_response = requests.put(f"{HANDY_API}/hssp", headers=headers, timeout=10)
        logger.debug(
            f"Mode response: {mode_response.status_code} - {mode_response.text}"
        )
        mode_response.raise_for_status()

        logger.info("Setting up HSSP...")
        setup_response = requests.put(
            f"{HANDY_API}/hssp/setup?timeout=5000",
            headers=headers,
            json={"url": script_url},
            timeout=15,
        )
        logger.debug(
            f"HSSP setup response: {setup_response.status_code} - {setup_response.text}"
        )
        setup_response.raise_for_status()

        logger.info("✅ HSSP setup complete")
        return headers

    except requests.exceptions.Timeout:
        logger.error("Timeout during HSSP setup")
        raise
    except requests.exceptions.RequestException as e:
        logger.error(f"Request error during HSSP setup: {e}")
        raise
    except Exception as e:
        logger.error(f"Unexpected error during HSSP setup: {e}")
        raise


def play_hssp(headers, video_ms):
    """Start HSSP playback"""
    try:
        server_time = get_estimated_server_time()
        logger.info(
            f"🔁 Starting HSSP playback at {video_ms}ms, server time: {server_time}"
        )

        if FIRMWARE_VERSION == 3:
            # Firmware 3 payload format
            play_payload = {
                "estimatedServerTime": server_time,
                "startTime": video_ms + round_trip_time//2
            }
        else:
            # Firmware 4 payload format
            play_payload = {
                "start_time": video_ms + round_trip_time//2,
                "server_time": server_time,
                "playback_rate": 1.0,
                "loop": False
            }

        play_url = f"{HANDY_API}/hssp/play?timeout=5000"
        play_resp = requests.put(
            play_url, headers=headers, json=play_payload, timeout=10
        )

        logger.debug(f"HSSP play response: {play_resp.status_code} - {play_resp.text}")
        play_resp.raise_for_status()
        logger.info("✅ Handy playback started")

        # Note: sync timing will be reset in main loop when this is called

    except Exception as e:
        logger.error(f"Error starting HSSP playback: {e}")
        raise


def stop_hssp(headers):
    """Stop HSSP playback"""
    try:
        logger.info("Stopping HSSP playback...")
        response = requests.put(f"{HANDY_API}/hssp/stop", headers=headers, timeout=10)
        response.raise_for_status()
        logger.info("🛑 Handy script stopped")
    except Exception as e:
        logger.error(f"Error stopping Handy: {e}")


def sync_time_hssp(headers, video_ms):
    """Send time sync update to Handy device for fine-tuning"""
    try:
        server_time = get_estimated_server_time()
        logger.debug(f"🔄 Syncing time: video={video_ms}ms, server={server_time}ms")

        sync_payload = {"start_time": video_ms, "server_time": server_time}

        sync_url = f"{HANDY_API}/hssp/synctime?timeout=5000"
        sync_resp = requests.put(
            sync_url, headers=headers, json=sync_payload, timeout=5
        )

        logger.debug(f"HSSP synctime response: {sync_resp.status_code}")
        sync_resp.raise_for_status()

    except Exception as e:
        logger.debug(
            f"Non-critical sync time error: {e}"
        )  # Don't fail the whole session for sync errors


def check_ejaculation_trigger():
    """Check if ejaculation trigger file was created"""
    ejac_file = "iejaculated.txt"
    if os.path.exists(ejac_file):
        logger.warning("💀 EJACULATION TRIGGER DETECTED!")
        return True
    return False


def create_ejaculation_trigger():
    """Create ejaculation trigger file"""
    try:
        with open("iejaculated.txt", "w") as f:
            f.write(f"ejaculated_at={datetime.now().isoformat()}")
        logger.info("💀 Ejaculation trigger file created")
    except Exception as e:
        logger.error(f"Error creating ejaculation trigger: {e}")


def force_fullscreen(player, max_attempts=15):
    """Force VLC player to fullscreen mode with multiple attempts"""
    logger.info("🖥️ Forcing fullscreen mode...")

    for attempt in range(max_attempts):
        try:
            # Multiple fullscreen methods in sequence
            methods_tried = []

            try:
                player.set_fullscreen(True)
                methods_tried.append("set_fullscreen(True)")
                time.sleep(0.1)
            except Exception as e:
                logger.debug(f"set_fullscreen failed: {e}")

            try:
                # Get current state and force again if needed
                current_fs = player.get_fullscreen()
                if not current_fs:
                    player.toggle_fullscreen()
                    methods_tried.append("toggle_fullscreen()")
                    time.sleep(0.1)
            except Exception as e:
                logger.debug(f"toggle_fullscreen failed: {e}")

            try:
                # Try setting fullscreen again
                player.set_fullscreen(True)
                time.sleep(0.1)
            except Exception as e:
                logger.debug(f"second set_fullscreen failed: {e}")

            logger.debug(f"Attempt {attempt + 1}: Methods tried: {methods_tried}")

            # Check if fullscreen worked
            try:
                is_fullscreen = player.get_fullscreen()
                logger.debug(
                    f"Attempt {attempt + 1}: Fullscreen status: {is_fullscreen}"
                )
                if is_fullscreen:
                    logger.info(
                        f"✅ Successfully entered fullscreen on attempt {attempt + 1}"
                    )
                    return True
            except Exception as e:
                logger.debug(f"Could not check fullscreen status: {e}")

            # Shorter wait between attempts for faster response
            time.sleep(0.2)

        except Exception as e:
            logger.debug(f"Fullscreen attempt {attempt + 1} error: {e}")

    logger.warning("⚠️ Could not force fullscreen after all attempts")
    return False


def monitor_keyboard(player, headers=None):
    """Monitor keyboard input for game controls"""
    global max_pauses, pause_duration, pauses_used, original_max_pauses
    try:
        logger.info(
            f"⏸️ Keyboard monitor started - Pauses: {max_pauses}x{pause_duration}s available"
        )

        # Create overlay for VLC display - smaller and top-left
        def update_vlc_overlay(message, temporary=False):
            try:
                if message:  # Show overlay
                    player.video_set_marquee_int(vlc.VideoMarqueeOption.Enable, 1)
                    player.video_set_marquee_string(
                        vlc.VideoMarqueeOption.Text, message.encode("utf-8")
                    )
                    player.video_set_marquee_int(
                        vlc.VideoMarqueeOption.Position, vlc.Position.TopLeft
                    )
                    player.video_set_marquee_int(
                        vlc.VideoMarqueeOption.Size, 16
                    )  # Smaller text
                    player.video_set_marquee_int(vlc.VideoMarqueeOption.Color, 0x00FF00)
                    player.video_set_marquee_int(
                        vlc.VideoMarqueeOption.Opacity, 200
                    )  # Slightly transparent
                    logger.debug(f"VLC overlay shown: {message}")
                else:  # Hide overlay
                    player.video_set_marquee_int(vlc.VideoMarqueeOption.Enable, 0)
                    logger.debug("VLC overlay hidden")
            except Exception as e:
                logger.debug(f"VLC overlay error (non-critical): {e}")

        def clear_overlay_after_delay(delay_seconds):
            """Clear overlay after specified delay"""

            def delayed_clear():
                time.sleep(delay_seconds)
                update_vlc_overlay("")

            threading.Thread(target=delayed_clear, daemon=True).start()

        # Track pause state to avoid conflicts
        currently_pausing = False

        # Start with clean screen - no overlay
        update_vlc_overlay("")

        while True:
            try:
                # Check for ejaculation key (E)
                if keyboard.is_pressed("e"):
                    logger.warning("💀 EJACULATION KEY PRESSED!")
                    update_vlc_overlay("EJACULATION!")
                    create_ejaculation_trigger()
                    player.stop()
                    break

                # Check for pause key (SPACE) - only if not currently in a pause cycle
                elif keyboard.is_pressed("space") and not currently_pausing:
                    state = player.get_state()
                    if state == vlc.State.Playing:  # Only pause if actually playing
                        available_pauses = original_max_pauses - pauses_used
                        if available_pauses > 0:
                            currently_pausing = True
                            pauses_used += 1
                            max_pauses -= 1
                            save_pause_config("pause_used")
                            logger.info(
                                f"⏸️ PAUSE {pauses_used}/{original_max_pauses} - Starting {pause_duration}s timer"
                            )

                            # Pause the video
                            player.pause()

                            # Wait a moment for pause to take effect
                            time.sleep(0.2)

                            # Show initial pause message
                            update_vlc_overlay(f"PAUSED - {pause_duration}s")

                            # Pause countdown - no early resume allowed
                            pause_start_time = time.time()
                            last_remaining = pause_duration

                            while time.time() - pause_start_time < pause_duration:
                                elapsed = time.time() - pause_start_time
                                remaining = int(pause_duration - elapsed)

                                # Only update overlay if countdown changed (reduce flicker)
                                if remaining != last_remaining:
                                    update_vlc_overlay(f"PAUSED - {remaining}s")
                                    last_remaining = remaining

                                # Check for ejaculation only
                                if keyboard.is_pressed("e"):
                                    logger.warning("💀 EJACULATION DURING PAUSE!")
                                    update_vlc_overlay("EJACULATION!")
                                    create_ejaculation_trigger()
                                    player.stop()
                                    return

                                time.sleep(0.1)  # Check every 100ms

                            # Resume playback after full countdown
                            if player.get_state() == vlc.State.Paused:
                                player.pause()  # This unpauses in VLC
                                update_vlc_overlay("Auto-resumed")
                                clear_overlay_after_delay(1.0)

                            # Wait a moment then show remaining pauses briefly
                            time.sleep(1.2)  # Wait for resume message to clear

                            remaining_pauses = max_pauses
                            if remaining_pauses > 0:
                                update_vlc_overlay(f"Pauses left: {remaining_pauses}")
                                clear_overlay_after_delay(2.0)
                            else:
                                update_vlc_overlay("No pauses remaining!")
                                clear_overlay_after_delay(3.0)

                            currently_pausing = False  # Reset flag

                            # Prevent immediate re-trigger
                            time.sleep(1.0)

                        else:
                            # No pauses left
                            logger.warning("❌ No pauses remaining!")
                            update_vlc_overlay("NO PAUSES LEFT!")
                            clear_overlay_after_delay(3.0)
                            time.sleep(1.0)  # Prevent spam

                # Check for fullscreen toggle (F key)
                elif keyboard.is_pressed("f"):
                    logger.info("🖥️ F key pressed - toggling fullscreen")
                    try:
                        player.toggle_fullscreen()
                        time.sleep(0.5)  # Prevent multiple triggers
                    except Exception as e:
                        logger.debug(f"Fullscreen toggle error: {e}")

                elif keyboard.is_pressed("r"):
                    state = player.get_state()
                    if state == vlc.State.Playing:
                        logger.info("🔄 R key pressed - Quick resync pause")
                        update_vlc_overlay("Resyncing...")

                        # Do exactly what space pause does but for just 0.5 seconds
                        player.pause()
                        time.sleep(0.5)  # Short pause

                        # Resume exactly like space pause does
                        if player.get_state() == vlc.State.Paused:
                            player.pause()  # This unpauses in VLC
                            update_vlc_overlay("Resync complete!")
                            clear_overlay_after_delay(1.5)

                        time.sleep(1.0)  # Prevent multiple triggers
                    else:
                        logger.warning("⚠️ Cannot resync - video not playing")
                        update_vlc_overlay("Cannot resync - not playing")
                        clear_overlay_after_delay(2.0)
                        time.sleep(0.5)

                # General debounce for other keys
                elif keyboard.is_pressed("q") or keyboard.is_pressed("esc"):
                    logger.info("🛑 Exit key pressed (Q or ESC)")
                    player.stop()
                    break

                # Check if video ended naturally
                if player.get_state() in [
                    vlc.State.Ended,
                    vlc.State.Stopped,
                    vlc.State.Error,
                ]:
                    logger.info("🎬 Video ended or stopped")
                    break

                # Small delay to prevent excessive CPU usage
                time.sleep(0.05)  # 50ms delay

            except Exception as e:
                logger.error(f"Keyboard monitor error: {e}")
                break

        logger.info("⌨️ Keyboard monitor ended")

    except Exception as e:
        logger.error(f"Fatal keyboard monitor error: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")


def main():
    """Main function"""
    try:
        logger.info("🚀 FapLand Handy Sync Starting...")

        # Check VLC availability first
        try:
            import vlc

            # Test basic VLC functionality
            test_instance = vlc.Instance(["--intf", "dummy"])
            if test_instance is None:
                raise Exception("VLC instance creation failed")
            test_player = test_instance.media_player_new()
            if test_player is None:
                raise Exception("VLC media player creation failed")
            logger.info("✅ VLC functionality verified")
        except Exception as vlc_error:
            logger.error(f"❌ VLC CHECK FAILED: {vlc_error}")
            logger.error("💡 SOLUTION:")
            logger.error(
                "   1. Download and install VLC: https://www.videolan.org/vlc/"
            )
            logger.error("   2. Install Python VLC bindings: pip install python-vlc")
            logger.error("   3. Restart your computer after installation")
            logger.error("   4. Make sure VLC is in your system PATH")
            sys.exit(1)

        log_system_info()

        # Parse command line arguments
        if len(sys.argv) < 2:
            logger.error("❌ ERROR: No video name provided")
            logger.error(
                "Usage: python sync_handy.py <video_name> [max_pauses] [pause_duration]"
            )
            logger.error("Example: python sync_handy.py 1 1 5")
            sys.exit(1)

        video_name = sys.argv[1]

        # Construct file paths
        video_path = f"media/{video_name}.mp4"
        funscript_path = f"media/{video_name}.funscript"

        logger.info(f"📹 Video path: {os.path.abspath(video_path)}")
        logger.info(f"📜 Funscript path: {os.path.abspath(funscript_path)}")

        # Check if files exist
        if not os.path.exists(video_path):
            logger.error(f"❌ Video file not found: {video_path}")
            logger.error("Make sure your video files are in the media/ folder")
            sys.exit(1)

        if not os.path.exists(funscript_path):
            logger.error(f"❌ Funscript file not found: {funscript_path}")
            logger.error("Make sure your funscript files are in the media/ folder")
            sys.exit(1)

        # Check network connectivity
        if not check_network_connectivity():
            logger.error("❌ Network connectivity check failed")
            sys.exit(1)

        # Clean up any previous ejaculation trigger
        if os.path.exists("iejaculated.txt"):
            os.remove("iejaculated.txt")
            logger.info("🧹 Cleaned up previous ejaculation trigger")

        # Sync server time
        if not sync_server_time(10):
            logger.error("❌ Failed to sync server time")
            sys.exit(1)

        # Upload funscript
        script_url = upload_funscript(funscript_path)
        if not script_url:
            logger.error("❌ Failed to upload funscript")
            sys.exit(1)

        # Setup VLC with progressive fallback options
        logger.info("🎬 Initializing VLC with fullscreen...")

        # Try different VLC argument configurations
        vlc_configs = [
            # Configuration 1: Full options
            [
                "--intf",
                "dummy",
                "--extraintf",
                "http",
                "--fullscreen",
                "--video-on-top",
                "--no-video-title-show",
                "--no-osd",
                "--qt-start-minimized",
            ],
            # Configuration 2: Minimal with fullscreen
            ["--intf", "dummy", "--fullscreen", "--no-video-title-show"],
            # Configuration 3: Basic
            ["--intf", "dummy", "--fullscreen"],
            # Configuration 4: Minimal
            ["--intf", "dummy"],
            # Configuration 5: Empty (default)
            [],
        ]

        instance = None
        player = None

        for i, vlc_args in enumerate(vlc_configs):
            try:
                logger.info(f"🔄 Trying VLC configuration {i + 1}/5...")
                logger.debug(f"VLC args: {vlc_args}")

                # Create VLC instance
                instance = vlc.Instance(vlc_args)

                if instance is None:
                    logger.warning(f"❌ Configuration {i + 1}: VLC instance is None")
                    continue

                # Create media player
                player = instance.media_player_new()

                if player is None:
                    logger.warning(f"❌ Configuration {i + 1}: Media player is None")
                    continue

                # Create media
                media = instance.media_new(str(Path(video_path).resolve()))

                if media is None:
                    logger.warning(f"❌ Configuration {i + 1}: Media is None")
                    continue

                # Set media to player
                player.set_media(media)

                # Try to set fullscreen if supported
                try:
                    player.set_fullscreen(True)
                    logger.debug(
                        f"✅ Configuration {i + 1}: Fullscreen set successfully"
                    )
                except Exception as fs_error:
                    logger.debug(
                        f"⚠️ Configuration {i + 1}: Could not set fullscreen: {fs_error}"
                    )

                logger.info(
                    f"✅ VLC initialized successfully with configuration {i + 1}"
                )
                break

            except Exception as e:
                logger.warning(f"❌ Configuration {i + 1} failed: {e}")
                instance = None
                player = None
                continue

        # Check if VLC initialization was successful
        if instance is None or player is None:
            logger.error("❌ All VLC configurations failed!")
            logger.error("💡 Troubleshooting tips:")
            logger.error(
                "   1. Make sure VLC is installed: https://www.videolan.org/vlc/"
            )
            logger.error("   2. Install VLC Python bindings: pip install python-vlc")
            logger.error("   3. Try reinstalling VLC and python-vlc")
            logger.error("   4. Check if VLC is in your system PATH")
            sys.exit(1)

        # Setup Handy
        headers = setup_hssp(script_url)

        # Start keyboard monitor
        keyboard_thread = threading.Thread(
            target=monitor_keyboard, args=(player, headers), daemon=True
        )
        keyboard_thread.start()
        logger.info("⌨️ Keyboard monitor thread started")

        # Start playback
        logger.info("🎬 Starting video and Handy sync")
        logger.info("💡 Controls: SPACE=pause, E=ejaculate, F=fullscreen, Q/ESC=quit")
        player.play()

        # Immediate fullscreen attempts while video loads
        logger.info("🖥️ Applying immediate fullscreen...")
        for i in range(5):
            try:
                player.set_fullscreen(True)
                time.sleep(0.1)
            except:
                pass

        # Wait for video to start playing with continuous fullscreen enforcement
        logger.info("⏳ Waiting for video to start with fullscreen enforcement...")
        start_time = time.time()
        fullscreen_attempts = 0

        while time.time() - start_time < 10:  # Wait up to 10 seconds
            state = player.get_state()

            # Try fullscreen every 0.2 seconds during startup
            if fullscreen_attempts % 2 == 0:  # Every other loop (0.2s intervals)
                try:
                    player.set_fullscreen(True)
                    fullscreen_attempts += 1
                except:
                    pass

            if state == vlc.State.Playing:
                logger.info("▶️ Video started playing")
                # Extra fullscreen enforcement when video starts
                for i in range(3):
                    try:
                        player.set_fullscreen(True)
                        time.sleep(0.1)
                    except:
                        pass
                break
            elif state == vlc.State.Error:
                logger.error("❌ Video failed to start")
                sys.exit(1)

            time.sleep(0.1)
            fullscreen_attempts += 1

        # Final aggressive fullscreen enforcement
        logger.info("🖥️ Final fullscreen enforcement...")
        force_fullscreen(player)

        # Additional enforcement after 1 second
        def delayed_fullscreen():
            time.sleep(1.0)
            logger.info("🖥️ Delayed fullscreen enforcement...")
            for i in range(5):
                try:
                    player.set_fullscreen(True)
                    time.sleep(0.2)
                except:
                    pass

        fullscreen_thread = threading.Thread(target=delayed_fullscreen, daemon=True)
        fullscreen_thread.start()

        was_playing = False

        # Main playback loop with sync timing
        loop_count = 0
        last_fullscreen_check = 0
        last_sync_time = 0
        sync_start_time = None

        while True:
            loop_count += 1
            current_time = time.time()
            state = player.get_state()

            # Check fullscreen more frequently in the first 30 seconds
            if loop_count < 120:  # First 30 seconds (120 * 0.25s)
                if loop_count % 4 == 0:  # Every 1 second
                    try:
                        if not player.get_fullscreen():
                            logger.debug(
                                f"🖥️ Loop {loop_count}: Not fullscreen, fixing..."
                            )
                            player.set_fullscreen(True)
                    except Exception as e:
                        logger.debug(f"Fullscreen check error: {e}")
            else:
                # Normal periodic check every 10 seconds after initial period
                if loop_count % 40 == 0:  # Every 10 seconds
                    logger.debug(
                        f"Player state: {state}, Position: {player.get_position()}"
                    )

                    # Re-attempt fullscreen every 10 seconds if needed
                    try:
                        if not player.get_fullscreen():
                            logger.debug("🖥️ Not in fullscreen, attempting to fix...")
                            player.set_fullscreen(True)
                    except Exception as e:
                        logger.debug(f"Fullscreen check/fix error: {e}")

            # Check for ejaculation trigger
            if check_ejaculation_trigger():
                logger.warning("💀 Ejaculation detected - ending playback")
                break

            if state == vlc.State.Playing and not was_playing:

                video_time = player.get_time()
                if video_time is not None and video_time >= 0:
                    play_hssp(headers, video_time)
                    sync_start_time = current_time
                    last_sync_time = current_time

                was_playing = True

                # Extra fullscreen enforcement when video starts playing
                try:
                    player.set_fullscreen(True)
                except:
                    pass

            elif state == vlc.State.Paused and was_playing:
                stop_hssp(headers)
                was_playing = False
                sync_start_time = None  # Reset sync timing

            elif state in [vlc.State.Ended, vlc.State.Stopped, vlc.State.Error]:
                logger.info(f"🛑 Video ended/stopped. State: {state}")
                break

            # FINE-TUNING SYNC: Send periodic time updates while playing
            if (
                was_playing
                and state == vlc.State.Playing
                and sync_start_time is not None
            ):
                video_time = player.get_time()
                if video_time is not None and video_time >= 0:
                    time_since_start = current_time - sync_start_time
                    time_since_last_sync = current_time - last_sync_time

                    # Sync strategy as per Handy docs:
                    # - Every 2 seconds for first 10 seconds
                    # - Every 10 seconds after that
                    should_sync = False

                    if time_since_start <= 10.0 and time_since_last_sync >= 2.0:
                        should_sync = True
                        logger.debug("🔄 Initial sync phase: 2s interval")
                    elif time_since_start > 10.0 and time_since_last_sync >= 10.0:
                        should_sync = True
                        logger.debug("🔄 Maintenance sync phase: 10s interval")

                    if should_sync:
                        sync_time_hssp(headers, video_time)
                        last_sync_time = current_time

            time.sleep(0.25)

        # Cleanup
        logger.info("🧹 Cleaning up...")
        stop_hssp(headers)
        player.stop()

        # Check final result
        if check_ejaculation_trigger():
            logger.info("💀 Round ended due to ejaculation")
            sys.exit(2)  # Special exit code for ejaculation
        else:
            logger.info(f"✅ Round {video_name} completed successfully!")
            sys.exit(0)

    except KeyboardInterrupt:
        logger.info("🛑 Interrupted by user (Ctrl+C)")
        if "player" in locals():
            player.stop()
        if "headers" in locals():
            stop_hssp(headers)
        sys.exit(1)

    except Exception as e:
        logger.error(f"❌ FATAL ERROR: {e}")
        logger.error(f"Traceback: {traceback.format_exc()}")
        if "player" in locals():
            try:
                player.stop()
            except:
                pass
        if "headers" in locals():
            try:
                stop_hssp(headers)
            except:
                pass
        sys.exit(1)


if __name__ == "__main__":
    main()
