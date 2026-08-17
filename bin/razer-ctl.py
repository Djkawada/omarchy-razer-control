#!/usr/bin/env python3
"""
Razer Universal Controller & Device Detector for Omarchy Linux
Communicates directly with /dev/hidraw devices using the Razer 90-byte protocol.
"""

import sys
import os
import glob
import json
import fcntl
import subprocess
import time
import struct

# Known Razer Product Database & Capabilities
RAZER_DEVICES_DB = {
    # Keyboards
    "011f": {
        "name": "Razer DeathStalker Essential 2014",
        "type": "keyboard",
        "family": "DeathStalker",
        "support_url": "https://mysupport.razer.com/app/answers/detail/a_id/4166",
        "capabilities": {
            "brightness": False,
            "rgb": False,
            "modes": [],
            "game_mode": True,
            "hardware_game_mode": True,
            "polling_rates": [125, 500, 1000],
            "macros": True
        },
        "notes": "Modèle chiclet non rétroéclairé. Le mode Gaming et la LED [G] sont gérés matériellement par le raccourci Fn + F10."
    },
    "0116": {
        "name": "Razer DeathStalker Expert",
        "type": "keyboard",
        "family": "DeathStalker",
        "capabilities": {
            "brightness": True,
            "rgb": False,
            "modes": ["static", "breathing", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "0203": {
        "name": "Razer DeathStalker Chroma",
        "type": "keyboard",
        "family": "DeathStalker",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "0228": {
        "name": "Razer BlackWidow Elite",
        "type": "keyboard",
        "family": "BlackWidow",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "0256": {
        "name": "Razer Huntsman Mini",
        "type": "keyboard",
        "family": "Huntsman",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "022f": {
        "name": "Razer Huntsman Elite",
        "type": "keyboard",
        "family": "Huntsman",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "021e": {
        "name": "Razer Ornata Chroma",
        "type": "keyboard",
        "family": "Ornata",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "0232": {
        "name": "Razer Cynosa Chroma",
        "type": "keyboard",
        "family": "Cynosa",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "wave", "reactive", "off"],
            "game_mode": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    # Mice
    "0084": {
        "name": "Razer DeathAdder Essential",
        "type": "mouse",
        "family": "DeathAdder",
        "capabilities": {
            "brightness": True,
            "rgb": False,
            "modes": ["static", "breathing", "off"],
            "dpi": True,
            "polling_rates": [125, 500, 1000]
        }
    },
    "0078": {
        "name": "Razer Viper Mini",
        "type": "mouse",
        "family": "Viper",
        "capabilities": {
            "brightness": True,
            "rgb": True,
            "modes": ["static", "breathing", "spectrum", "off"],
            "dpi": True,
            "polling_rates": [125, 500, 1000]
        }
    }
}

# State cache file
CACHE_FILE = os.path.expanduser("~/.config/omarchy/razer-state.json")

def load_cached_state():
    if os.path.exists(CACHE_FILE):
        try:
            with open(CACHE_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {"brightness": 255, "mode": "static", "game_mode": False, "polling_rate": 500}

def save_cached_state(state):
    try:
        os.makedirs(os.path.dirname(CACHE_FILE), exist_ok=True)
        with open(CACHE_FILE, "w") as f:
            json.dump(state, f)
    except Exception:
        pass

def build_razer_report(cmd_class, cmd_id, data_size, args=None):
    """Constructs a 90-byte Razer HID packet with XOR checksum."""
    report = bytearray(90)
    report[0] = 0x00  # Status: New command
    report[1] = 0x3F  # Transaction ID
    report[2] = 0x00  # Remaining packets MSB
    report[3] = 0x00  # Remaining packets LSB
    report[4] = 0x00  # Protocol type
    report[5] = data_size
    report[6] = cmd_class
    report[7] = cmd_id

    if args:
        for i, val in enumerate(args[:80]):
            report[8 + i] = val

    # CRC XOR of bytes 2 through 87
    crc = 0
    for b in report[2:88]:
        crc ^= b
    report[88] = crc
    report[89] = 0x00  # Reserved
    return bytes(report)

def send_razer_packet(hidraw_path, report_bytes):
    """Sends a feature report to the hidraw device via ioctl HIDIOCSFEATURE(90)."""
    # HIDIOCSFEATURE(90): _IOC(_IOC_WRITE|_IOC_READ, 'H', 0x06, 90) = 0xc05a4806 on x86_64
    HIDIOCSFEATURE_90 = 0xc05a4806
    try:
        fd = os.open(hidraw_path, os.O_RDWR | os.O_NONBLOCK)
        try:
            # Report buffer prefixed with report ID 0x00
            buf = bytearray(b'\x00' + report_bytes)
            fcntl.ioctl(fd, HIDIOCSFEATURE_90, buf)
            return True
        finally:
            os.close(fd)
    except Exception as e:
        # Fallback to direct write if ioctl fails
        try:
            fd = os.open(hidraw_path, os.O_WRONLY | os.O_NONBLOCK)
            try:
                os.write(fd, report_bytes)
                return True
            finally:
                os.close(fd)
        except Exception:
            return False

def get_razer_hidraw_nodes():
    """Returns all /dev/hidraw* device nodes that belong to Razer (vendor 0x1532)."""
    nodes = []
    for hidraw in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        uevent_path = os.path.join(hidraw, "device", "uevent")
        if not os.path.exists(uevent_path):
            continue
        try:
            with open(uevent_path, "r") as f:
                content = f.read()
            for line in content.splitlines():
                if line.startswith("HID_ID="):
                    parts = line.split("=")[1].split(":")
                    if len(parts) >= 3 and parts[1].lower().lstrip("0").zfill(4) == "1532":
                        dev_name = os.path.basename(hidraw)
                        nodes.append(f"/dev/{dev_name}")
                        break
        except Exception:
            continue
    return nodes

def scan_razer_devices():
    """Scans system for connected Razer USB HID devices."""
    detected = []
    
    # Check /sys/class/hidraw/*
    for hidraw in sorted(glob.glob("/sys/class/hidraw/hidraw*")):
        dev_name = os.path.basename(hidraw)
        hidraw_dev = f"/dev/{dev_name}"
        
        # Read uevent to parse VENDOR and PRODUCT
        uevent_path = os.path.join(hidraw, "device", "uevent")
        if not os.path.exists(uevent_path):
            continue
            
        try:
            with open(uevent_path, "r") as f:
                content = f.read()
                
            vendor = None
            product = None
            for line in content.splitlines():
                if line.startswith("HID_ID="):
                    parts = line.split("=")[1].split(":")
                    if len(parts) >= 3:
                        vendor = parts[1].lower().lstrip("0").zfill(4)
                        product = parts[2].lower().lstrip("0").zfill(4)
            
            if vendor == "1532" and product:
                db_info = RAZER_DEVICES_DB.get(product, {
                    "name": f"Périphérique Razer (0x{product})",
                    "type": "keyboard",
                    "family": "Razer",
                    "capabilities": {
                        "brightness": True,
                        "rgb": False,
                        "modes": ["static", "breathing", "off"],
                        "game_mode": True,
                        "polling_rates": [125, 500, 1000]
                    }
                })
                
                detected.append({
                    "name": db_info["name"],
                    "productId": product,
                    "vendorId": vendor,
                    "hidraw": hidraw_dev,
                    "type": db_info.get("type", "keyboard"),
                    "family": db_info.get("family", "Razer"),
                    "capabilities": db_info.get("capabilities", {}),
                    "support_url": db_info.get("support_url", "https://mysupport.razer.com")
                })
        except Exception:
            continue

    # Deduplicate by productId, keeping primary interface
    unique_devices = {}
    for d in detected:
        pid = d["productId"]
        if pid not in unique_devices:
            unique_devices[pid] = d
            
    return list(unique_devices.values())

def get_lock_states():
    caps = False
    num = False
    scroll = False
    try:
        res = subprocess.check_output(["hyprctl", "devices", "-j"], stderr=subprocess.DEVNULL, timeout=1)
        data = json.loads(res.decode("utf-8"))
        for k in data.get("keyboards", []):
            name = k.get("name", "").lower()
            if "deathstalker" in name or "razer" in name:
                caps = k.get("capsLock", False)
                num = k.get("numLock", False)
                break
    except Exception:
        pass
    for p in glob.glob("/sys/class/leds/*scrolllock/brightness"):
        try:
            with open(p, "r") as f:
                if f.read().strip() == "1":
                    scroll = True
                    break
        except Exception:
            pass
    return {"caps_lock": caps, "num_lock": num, "scroll_lock": scroll}

def cmd_status():
    devices = scan_razer_devices()
    state = load_cached_state()
    locks = get_lock_states()
    
    result = {
        "connected": len(devices) > 0,
        "count": len(devices),
        "devices": devices,
        "active_device": devices[0] if devices else None,
        "state": state,
        "locks": locks
    }
    print(json.dumps(result, indent=2))

def cmd_set_brightness(val):
    val = max(0, min(255, int(val)))
    state = load_cached_state()
    state["brightness"] = val
    save_cached_state(state)
    
    # Class 0x03, Command 0x03: Set brightness
    pkt1 = build_razer_report(0x03, 0x03, 0x03, [0x01, 0x01, val])
    # Class 0x03, Command 0x02: Set LED on/off
    pkt2 = build_razer_report(0x03, 0x02, 0x02, [0x01, 0x01 if val > 0 else 0x00])
    
    success = False
    for hid in get_razer_hidraw_nodes():
        s1 = send_razer_packet(hid, pkt1)
        s2 = send_razer_packet(hid, pkt2)
        if s1 or s2:
            success = True
    print(json.dumps({"success": success, "brightness": val}))

def cmd_set_mode(mode):
    if mode not in ["static", "breathing", "off"]:
        mode = "static"
    state = load_cached_state()
    state["mode"] = mode
    save_cached_state(state)
    
    if mode == "breathing":
        pkt = build_razer_report(0x03, 0x01, 0x03, [0x01, 0x02, 0x00])
    elif mode == "off":
        pkt = build_razer_report(0x03, 0x02, 0x02, [0x01, 0x00])
    else: # static
        pkt = build_razer_report(0x03, 0x01, 0x03, [0x01, 0x00, 0x00])
        
    success = False
    for hid in get_razer_hidraw_nodes():
        if send_razer_packet(hid, pkt):
            success = True
    print(json.dumps({"success": success, "mode": mode}))

def cmd_set_game_mode(enabled):
    is_on = (str(enabled).lower() in ("1", "true", "on", "yes"))
    state = load_cached_state()
    state["game_mode"] = is_on
    save_cached_state(state)
    
    pkt = build_razer_report(0x03, 0x04, 0x02, [0x00, 0x01 if is_on else 0x00])
    success = False
    for hid in get_razer_hidraw_nodes():
        if send_razer_packet(hid, pkt):
            success = True
    print(json.dumps({"success": success, "game_mode": is_on}))

def cmd_set_polling(hz):
    try:
        hz = int(hz)
    except (ValueError, TypeError):
        hz = 500
    rate_code = 0x02
    if hz == 1000:
        rate_code = 0x01
    elif hz == 125:
        rate_code = 0x08
    else:
        hz = 500
        
    state = load_cached_state()
    state["polling_rate"] = hz
    save_cached_state(state)
    
    pkt = build_razer_report(0x00, 0x05, 0x01, [rate_code])
    success = False
    for hid in get_razer_hidraw_nodes():
        if send_razer_packet(hid, pkt):
            success = True
    print(json.dumps({"success": success, "polling_rate": hz}))

HIDIOCSOUTPUT_2 = 0xc002480b

def set_hardware_leds(num_lock=True, caps_lock=False, scroll_lock=False):
    bitmask = 0
    if num_lock:
        bitmask |= 0x01
    if caps_lock:
        bitmask |= 0x02
    if scroll_lock:
        bitmask |= 0x04
        
    buf = bytearray([0x00, bitmask])
    success = False
    for path in get_razer_hidraw_nodes():
        try:
            fd = os.open(path, os.O_RDWR | os.O_NONBLOCK)
            fcntl.ioctl(fd, HIDIOCSOUTPUT_2, buf)
            os.close(fd)
            success = True
        except Exception:
            pass
    return success

def find_razer_event_nodes():
    nodes = []
    for p in sorted(glob.glob("/dev/input/by-id/usb-Razer*-event-kbd")):
        if os.path.exists(p) and "if01" not in p:
            nodes.append(p)
    if not nodes:
        for p in sorted(glob.glob("/dev/input/by-id/usb-Razer*-event-kbd")):
            if os.path.exists(p):
                nodes.append(p)
    return nodes

def inject_key_event(key_code):
    nodes = find_razer_event_nodes()
    if not nodes:
        return False
    success = False
    for node in nodes:
        try:
            fd = os.open(node, os.O_RDWR | os.O_NONBLOCK)
            t = time.time()
            tv_sec = int(t)
            tv_usec = int((t - tv_sec) * 1000000)
            
            # Key Down
            os.write(fd, struct.pack("llHHi", tv_sec, tv_usec, 1, key_code, 1))
            os.write(fd, struct.pack("llHHi", tv_sec, tv_usec, 0, 0, 0))
            time.sleep(0.04)
            # Key Up
            os.write(fd, struct.pack("llHHi", tv_sec, tv_usec, 1, key_code, 0))
            os.write(fd, struct.pack("llHHi", tv_sec, tv_usec, 0, 0, 0))
            os.close(fd)
            success = True
        except Exception:
            pass
    return success

def cmd_toggle_key(key_name):
    # Linux input-event-codes: KEY_CAPSLOCK=58, KEY_NUMLOCK=69, KEY_SCROLLLOCK=70, KEY_INSERT=110
    key_codes = {
        "Caps_Lock": 58,
        "Num_Lock": 69,
        "Scroll_Lock": 70,
        "Insert": 110
    }
    
    code = key_codes.get(key_name)
    success = False
    if code:
        success = inject_key_event(code)
    if not success and subprocess.call(["which", "wtype"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        subprocess.call(["wtype", "-k", key_name], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
    time.sleep(0.08)
    locks = get_lock_states()
    set_hardware_leds(locks["num_lock"], locks["caps_lock"], locks["scroll_lock"])
    print(json.dumps({"success": True, "key": key_name, "locks": locks}))

def cmd_set_lang(lang):
    if lang not in ["fr", "en", "ja"]:
        lang = "en"
    state = load_cached_state()
    state["lang"] = lang
    save_cached_state(state)
    print(json.dumps({"success": True, "lang": lang}))

def main():
    if len(sys.argv) < 2 or sys.argv[1] == "status":
        cmd_status()
    elif sys.argv[1] == "set-brightness" and len(sys.argv) > 2:
        cmd_set_brightness(sys.argv[2])
    elif sys.argv[1] == "set-mode" and len(sys.argv) > 2:
        cmd_set_mode(sys.argv[2])
    elif sys.argv[1] == "set-game-mode" and len(sys.argv) > 2:
        cmd_set_game_mode(sys.argv[2])
    elif sys.argv[1] == "set-polling" and len(sys.argv) > 2:
        cmd_set_polling(sys.argv[2])
    elif sys.argv[1] == "set-lang" and len(sys.argv) > 2:
        cmd_set_lang(sys.argv[2])
    elif sys.argv[1] == "toggle-caps":
        cmd_toggle_key("Caps_Lock")
    elif sys.argv[1] == "toggle-num":
        cmd_toggle_key("Num_Lock")
    elif sys.argv[1] == "toggle-scroll":
        cmd_toggle_key("Scroll_Lock")
    else:
        print("Usage: razer-ctl.py [status|set-brightness <val>|set-mode <mode>|set-game-mode <on/off>|set-polling <125/500/1000>|set-lang <fr/en/ja>|toggle-caps|toggle-num|toggle-scroll]")

if __name__ == "__main__":
    main()
