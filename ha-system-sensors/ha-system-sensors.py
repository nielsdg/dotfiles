#!/usr/bin/env python3

import abc
import argparse
import getpass
import json
import logging
import psutil
import re
import socket
import subprocess
import time
from urllib.error import URLError
from urllib.request import Request, urlopen

import gi
gi.require_version('Secret', '1')
from gi.repository import Secret
from websockets.sync.client import connect as ws_connect

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
log = logging.getLogger("ha-system-sensors")

HOSTNAME = socket.gethostname()
HOSTNAME_SLUG = re.sub(r"[^a-z0-9]", "_", HOSTNAME.lower())

KEYRING_SCHEMA = Secret.Schema.new(
    "be.nielsdg.ha-system-sensors",
    Secret.SchemaFlags.NONE,
    {"application": Secret.SchemaAttributeType.STRING},
)
KEYRING_ATTRS = {"application": "ha-system-sensors"}


def store_credentials(url, token):
    Secret.password_store_sync(
        KEYRING_SCHEMA, KEYRING_ATTRS,
        Secret.COLLECTION_DEFAULT,
        "System Sensors - Home Assistant",
        json.dumps({"url": url, "token": token}),
        None,
    )


def load_credentials():
    secret = Secret.password_lookup_sync(KEYRING_SCHEMA, KEYRING_ATTRS, None)
    if not secret:
        log.error("No credentials found. Run 'ha-system-sensors login' first.")
        raise SystemExit(1)
    return json.loads(secret)


class Collector(abc.ABC):
    """Base class for sensor collectors.

    Subclasses implement collect() to return a list of sensor dicts.
    Use _sensor() to build each dict with the correct structure for the HA API.
    """

    @abc.abstractmethod
    def collect(self):
        """Return a list of sensor dicts, or an empty list if unavailable."""

    def _sensor(self, sensor_id, state, *, unit=None, device_class=None,
                state_class=None, friendly_name=None, icon=None):
        attrs = {}
        if unit:
            attrs["unit_of_measurement"] = unit
        if device_class:
            attrs["device_class"] = device_class
        if state_class:
            attrs["state_class"] = state_class
        if friendly_name:
            attrs["friendly_name"] = friendly_name
        if icon:
            attrs["icon"] = icon
        unique_id = f"{HOSTNAME_SLUG}_{sensor_id}"
        attrs["unique_id"] = unique_id
        return {
            "entity_id": f"sensor.{unique_id}",
            "state": str(state),
            "attributes": attrs,
        }


class BatteryCollector(Collector):
    def collect(self):
        battery = psutil.sensors_battery()
        if battery is None:
            return []
        return [self._sensor(
            "battery", round(battery.percent),
            unit="%", device_class="battery",
            friendly_name=f"{HOSTNAME} Battery",
        )]


class CpuCollector(Collector):
    def collect(self):
        return [self._sensor(
            "cpu", psutil.cpu_percent(interval=1),
            unit="%", state_class="measurement",
            friendly_name=f"{HOSTNAME} CPU", icon="mdi:cpu-64-bit",
        )]


class RamCollector(Collector):
    def collect(self):
        return [self._sensor(
            "ram", psutil.virtual_memory().percent,
            unit="%", state_class="measurement",
            friendly_name=f"{HOSTNAME} RAM", icon="mdi:memory",
        )]


class UptimeCollector(Collector):
    def collect(self):
        uptime_seconds = int(time.time() - psutil.boot_time())
        return [self._sensor(
            "uptime", uptime_seconds,
            unit="s", device_class="duration",
            friendly_name=f"{HOSTNAME} Uptime", icon="mdi:clock-outline",
        )]


class VolumeCollector(Collector):
    def collect(self):
        try:
            result = subprocess.run(
                ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
                capture_output=True, text=True, timeout=5,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return []
        if result.returncode != 0:
            return []
        volume = result.stdout.removeprefix("Volume: ").strip()
        return [self._sensor(
            "volume", volume,
            unit="%", friendly_name=f"{HOSTNAME} Volume", icon="mdi:volume-high",
        )]


class UpdatesCollector(Collector):
    def collect(self):
        try:
            result = subprocess.run(
                ["pkgcli", "list-updates", "--json"],
                capture_output=True, text=True, timeout=120,
            )
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return []
        if result.returncode != 0:
            return []
        if not result.stdout:
            return []

        updates = json.loads(result.stdout)
        packages = [pkg["name"] for pkg in updates]

        sensor = self._sensor(
            "updates", len(packages),
            unit="updates",
            friendly_name=f"{HOSTNAME} Updates", icon="mdi:package-up",
        )
        sensor["attributes"]["packages"] = packages
        return [sensor]


COLLECTORS = [
    BatteryCollector(),
    CpuCollector(),
    UpdatesCollector(),
    RamCollector(),
    UptimeCollector(),
    VolumeCollector(),
]


class HomeAssistant:
    """Client for the Home Assistant REST and WebSocket APIs."""

    def __init__(self, url, token):
        self.url = url
        self.token = token

    def publish(self, sensor):
        """Create or update a sensor entity via the REST API."""
        entity_id = sensor["entity_id"]
        api_url = f"{self.url}/api/states/{entity_id}"
        data = json.dumps({
            "state": sensor["state"],
            "attributes": sensor["attributes"],
        }).encode()
        req = Request(api_url, data=data, method="POST")
        req.add_header("Authorization", f"Bearer {self.token}")
        req.add_header("Content-Type", "application/json")
        urlopen(req, timeout=10)

    def associate_with_device(self, entity_ids, device_name):
        """Associate entities with a named device via the WebSocket API."""
        ws_url = self.url.replace("http", "ws", 1) + "/api/websocket"

        with ws_connect(ws_url) as ws:
            ws.recv()  # auth_required
            ws.send(json.dumps({"type": "auth", "access_token": self.token}))
            auth_result = json.loads(ws.recv())
            if auth_result.get("type") != "auth_ok":
                log.warning("WebSocket auth failed")
                return

            ws.send(json.dumps({"id": 1, "type": "config/device_registry/list"}))
            devices = json.loads(ws.recv()).get("result", [])
            device_id = None
            for device in devices:
                if device_name in (device.get("name"), device.get("name_by_user")):
                    device_id = device["id"]
                    break
            if not device_id:
                log.warning("Device '%s' not found in Home Assistant", device_name)
                return

            for i, entity_id in enumerate(entity_ids, start=2):
                ws.send(json.dumps({
                    "id": i,
                    "type": "config/entity_registry/update",
                    "entity_id": entity_id,
                    "device_id": device_id,
                }))
                ws.recv()
            log.info("Associated %d entities with device '%s'", len(entity_ids), device_name)

    def remove_entities(self, entity_ids):
        """Remove entities from Home Assistant via the WebSocket API."""
        ws_url = self.url.replace("http", "ws", 1) + "/api/websocket"

        with ws_connect(ws_url) as ws:
            ws.recv()  # auth_required
            ws.send(json.dumps({"type": "auth", "access_token": self.token}))
            auth_result = json.loads(ws.recv())
            if auth_result.get("type") != "auth_ok":
                log.warning("WebSocket auth failed")
                return

            for i, entity_id in enumerate(entity_ids, start=1):
                ws.send(json.dumps({
                    "id": i,
                    "type": "config/entity_registry/remove",
                    "entity_id": entity_id,
                }))
                result = json.loads(ws.recv())
                if result.get("success"):
                    log.info("Removed %s", entity_id)
                else:
                    log.warning("Failed to remove %s: %s", entity_id,
                                result.get("error", {}).get("message", "unknown error"))


def collect_sensors():
    sensors = []
    for collector in COLLECTORS:
        try:
            sensors.extend(collector.collect())
        except Exception as e:
            log.warning("Collector %s failed: %s", type(collector).__name__, e)
    return sensors


def cmd_list(args):
    print(json.dumps(collect_sensors(), indent=2))


def cmd_login(args):
    token = getpass.getpass("Home Assistant long-lived access token: ")
    store_credentials(args.url, token)
    log.info("Credentials stored in keyring")


def cmd_publish(args):
    creds = load_credentials()
    ha = HomeAssistant(creds["url"], creds["token"])
    sensors = collect_sensors()

    published_entities = []
    for sensor in sensors:
        try:
            ha.publish(sensor)
            published_entities.append(sensor["entity_id"])
            log.info("Published %s = %s", sensor["entity_id"], sensor["state"])
        except URLError as e:
            log.warning("Failed to publish %s: %s", sensor["entity_id"], e)

    if published_entities and args.device:
        try:
            ha.associate_with_device(published_entities, args.device)
        except Exception as e:
            log.warning("Failed to associate with device '%s': %s", args.device, e)


def cmd_remove(args):
    creds = load_credentials()
    ha = HomeAssistant(creds["url"], creds["token"])
    sensors = collect_sensors()
    entity_ids = [sensor["entity_id"] for sensor in sensors]
    ha.remove_entities(entity_ids)


def main():
    parser = argparse.ArgumentParser(description="Publish system sensors to Home Assistant")
    subparsers = parser.add_subparsers(required=True)

    login_parser = subparsers.add_parser("login", help="Store Home Assistant credentials in the keyring")
    login_parser.add_argument("url", help="Home Assistant URL (e.g. http://192.168.0.10:8123)")
    login_parser.set_defaults(func=cmd_login)

    subparsers.add_parser("list", help="Collect and print sensors as JSON").set_defaults(func=cmd_list)

    publish_parser = subparsers.add_parser("publish", help="Collect and publish sensors to Home Assistant")
    publish_parser.add_argument("--device", help="Device name in Home Assistant to group sensors under")
    publish_parser.set_defaults(func=cmd_publish)

    subparsers.add_parser("remove", help="Remove all sensors from Home Assistant").set_defaults(func=cmd_remove)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
