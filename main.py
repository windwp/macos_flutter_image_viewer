#!/usr/bin/python
import os
import re
import subprocess
import sys
import time

import psutil
import requests

REQUEST_URL = "http://localhost:8765"
APP_PATH = os.path.realpath(os.path.dirname(
    __file__)) + "/release/linux/image_viewer"


def parse_media(media: str) -> str:
    if re.match(r"^https://www.youtube.com/watch\?v=.*$", media):
        # run a command youtube-dl to get the video link
        process = subprocess.Popen(
            ["youtube-dl", "--get-url", "-f", "mp4", media], stdout=subprocess.PIPE
        )
        output, error = process.communicate()
        media = output.decode("utf-8").strip()
        if error:
            print(error)
            sys.exit(1)
        pass
    return media


def is_running() -> bool:
    processes = psutil.process_iter()
    # Iterate over the processes
    for process in processes:
        # Check if the process name matches "image viewer"
        if process.name() == "image_viewer":
            return True
    return False


def update(media: str, x: int, y: int, width: int, height: int) -> None:
    print(media)
    if not is_running():
        start(media, x, y, width, height)
        time.sleep(0.5)

    with open("/tmp/flutter_image_viewer", "w+") as f:
        f.write("")
        pass
    try:
        requests.post(
            REQUEST_URL,
            json={
                "x": x,
                "y": y,
                "width": width,
                "height": height,
                "media": parse_media(media),
            },
        )
    except Exception as e:
        pass
    pass


def start(media: str, x: int, y: int, width: int, height: int) -> None:
    kill()
    # get current process window id
    window_id = subprocess.check_output(
        ["xdotool", "getactivewindow"]).decode("utf-8")

    subprocess.Popen(
        [
            APP_PATH,
            parse_media(media),
            str(x),
            str(y),
            str(width),
            str(height),
        ]
    )
    time.sleep(0.5)
    subprocess.Popen(["xdotool", "windowactivate", window_id])
    pass


def kill():
    # kill all the processes with name image_viewer
    processes = psutil.process_iter()
    # Iterate over the processes
    for process in processes:
        # Check if the process name matches "image viewer"
        if process.name() == "image_viewer":
            # Kill the process
            process.kill()
    pass


def clear():
    with open("/tmp/flutter_image_viewer", "r+") as f:
        if f.read() == "clear":
            return
        f.truncate(0)
        f.write("clear")
        pass
    time.sleep(4)
    with open("/tmp/flutter_image_viewer", "r+") as f:
        data = f.read()
        if data == "clear":
            kill()
            pass
    pass


if __name__ == "__main__":
    # reading command line arguments
    command = sys.argv[1]
    x, y, width, height = 0, 0, 0, 0
    if len(sys.argv) > 2:
        media = sys.argv[2]
    if len(sys.argv) > 5:
        x = int(sys.argv[3])
        y = int(sys.argv[4])
        width = int(sys.argv[5])
        height = int(sys.argv[6])
    if command == "start":
        start(media, x, y, width, height)
    if command == "send" or command == "update":
        update(media, x, y, width, height)
    if command == "clear":
        clear()
    if command == "kill":
        kill()
    pass
