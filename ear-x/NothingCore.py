import sys
import socket
import time
import json
import threading
import random

class NothingEarbuds:
    def __init__(self, mac_address=None, mock=True):
        self.mac_address = mac_address
        self.mock = mock
        self.socket = None
        self.running = True
        self.op_id = 0
        self.status = {
            "connected": False,
            "left_battery": 0,
            "right_battery": 0,
            "case_battery": 0,
            "anc_mode": 0, # 0: Off, 1: ANC, 2: Transparency
            "eq_mode": 0, # 0: Balanced, 1: Bass, 2: Treble, 3: Voice, 4: Custom
        }

    def crc16(self, data):
        crc = 0xFFFF
        for byte in data:
            crc ^= byte
            for _ in range(8):
                if crc & 1:
                    crc = (crc >> 1) ^ 0xA001
                else:
                    crc >>= 1
        return crc

    def build_packet(self, cmd_id, payload=[]):
        header = [0x55, 0x60, 0x01, cmd_id & 0xFF, (cmd_id >> 8) & 0xFF, len(payload), 0x00, self.op_id]
        self.op_id = (self.op_id + 1) % 256
        packet = bytes(header + payload)
        crc = self.crc16(packet)
        return packet + bytes([crc & 0xFF, (crc >> 8) & 0xFF])

    def send_command(self, cmd_id, payload=[]):
        if self.mock:
            # Simulate response for mock mode
            self.handle_mock_command(cmd_id, payload)
            return

        if not self.socket:
            return

        packet = self.build_packet(cmd_id, payload)
        try:
            self.socket.send(packet)
        except Exception as e:
            self.log(f"Send failed: {e}")
            self.status["connected"] = False

    def handle_mock_command(self, cmd_id, payload):
        if cmd_id == 0xF00F: # Set ANC
            self.status["anc_mode"] = payload[0] if payload else 0
        elif cmd_id == 0xF010: # Set EQ
            self.status["eq_mode"] = payload[0] if payload else 0
        self.broadcast_status()

    def connect(self):
        if self.mock:
            self.status["connected"] = True
            # Simulate initial battery
            self.status["left_battery"] = 85
            self.status["right_battery"] = 90
            self.status["case_battery"] = 100
            self.broadcast_status()
            return True

        if not self.mac_address:
            self.log("No MAC address provided")
            return False

        try:
            # RFCOMM channel 15 is often used for Nothing Ear buds
            self.socket = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)
            self.socket.connect((self.mac_address, 15))
            self.status["connected"] = True
            self.broadcast_status()
            # Start read thread
            threading.Thread(target=self.receive_loop, daemon=True).start()
            return True
        except Exception as e:
            self.log(f"Connection failed: {e}")
            self.status["connected"] = False
            self.broadcast_status()
            return False

    def receive_loop(self):
        while self.running and self.socket:
            try:
                data = self.socket.recv(1024)
                if not data:
                    break
                self.parse_data(data)
            except Exception as e:
                self.log(f"Read error: {e}")
                break
        self.status["connected"] = False
        self.broadcast_status()

    def parse_data(self, data):
        # Very basic parser for battery status
        if len(data) >= 10 and data[3] == 0x07 and data[4] == 0x40: # Response to C007
            # Payload starts at index 8
            # Assuming [left, right, case]
            self.status["left_battery"] = data[8]
            self.status["right_battery"] = data[9]
            self.status["case_battery"] = data[10] if len(data) > 10 else 0
            self.broadcast_status()

    def broadcast_status(self):
        print(json.dumps({"type": "status", "data": self.status}))
        sys.stdout.flush()

    def log(self, msg):
        print(json.dumps({"type": "log", "message": msg}))
        sys.stdout.flush()

    def run(self):
        self.connect()
        while self.running:
            line = sys.stdin.readline()
            if not line:
                break
            try:
                cmd = json.loads(line)
                if cmd["type"] == "set_anc":
                    self.send_command(0xF00F, [cmd["value"]])
                elif cmd["type"] == "set_eq":
                    self.send_command(0xF010, [cmd["value"]])
                elif cmd["type"] == "refresh":
                    self.send_command(0xC007) # Get Battery
            except Exception as e:
                self.log(f"Cmd error: {e}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--mac", help="Bluetooth MAC address")
    parser.add_argument("--mock", action="store_true", help="Run in mock mode")
    args = parser.parse_args()

    earbuds = NothingEarbuds(mac_address=args.mac, mock=args.mock)
    try:
        earbuds.run()
    except KeyboardInterrupt:
        pass
