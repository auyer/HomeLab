from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.compute import Server
from diagrams.onprem.database import PostgreSQL
from diagrams.onprem.inmemory import Redis
from diagrams.onprem.monitoring import Grafana, Prometheus
from diagrams.onprem.network import Nginx
from diagrams.generic.network import Router, Switch, Firewall
from diagrams.generic.os import Raspbian, Debian, LinuxGeneral
from diagrams.generic.compute import Rack
from diagrams.generic.virtualization import Qemu
from diagrams.generic.storage import Storage
from diagrams.generic.device import Mobile, Tablet
from diagrams.generic.blank import Blank
from diagrams.custom import Custom

PIHOLE_LOGO = "logos/Pi-hole_Logo.png"


vms = {
    "HAOS": {
        "name": "Home Assistant OS",
        "layer": 3,
        "hardware_passthrough": ["Sonoff Zigbee 3.0 USB Dongle Plus"],
    },
    "TRUENAS": {
        "name": "TrueNas Scale 25",
        "layer": 3,
        "hardware_passthrough": ["Marvell PCIe 4 port Sata Controller"],
        "storage_pools": [
            {
                "scheme": "Raid Z1",
                "disks": [
                    "Seagate IronWolf 4TB CMR 5400rpm",
                    "Seagate IronWolf 4TB CMR 5400rpm",
                    "WD RED 4TB CMR 5400rpm",
                ],
            }
        ],
    },
}

lxcs = {
    "PiHole 2": {
        "layer": 2,
        "method": "Debian Package",
    },
    "Transmission": {
        "layer": 3,
        "method": "Alpine Package",
    },
    "Jellyfin": {
        "layer": 3,
        "method": "Alpine Package",
    },
    "Nginx Proxy Manager": {
        "layer": 2,
        "method": "podman-compose",
    },
    "Grafana": {
        "layer": 3,
        "method": "podman-compose",
        "services": ["grafana", "prometheus", "unpoller", "matchtower"],
    },
    "PostgreSQL": {
        "layer": 3,
        "method": "Debian Package",
    },
    "KV": {
        "layer": 3,
        "method": "Binary install + Systemd",
    },
    "lore": {
        "layer": 3,
        "method": "podman-compose",
    },
    "Prosody": {
        "layer": 3,
        "method": "podman-compose + Debian Package",
        "services": ["prosody", "biboumi", "slidge"],
        "ansible_roles": ["prosody", "biboumi", "slidge"],
    },
    "Coturn": {"layer": 3, "method": "Debian Package", "ansible_roles": ["coturn"]},
    "Excalidraw": {
        "layer": 3,
        "method": "podman-compose",
    },
    "Copyparty": {
        "layer": 3,
        "method": "podman-compose",
    },
    "Immich": {
        "layer": 3,
        "method": "podman-compose",
    },
    "LanguageTool": {
        "layer": 3,
        "method": "podman-compose",
    },
}


hardware = {
    "pi5": {
        "name": "RaspberryPi 5",
        "os": "Raspberry Pi OS 13",
        "services": {
            "lxc": None,
            "vms": None,
            "packages": {
                "PiHole": {
                    "layer": 2,
                    "method": "Debian Package",
                },
                "Nginx (Angie)": {
                    "layer": 2,
                    "method": "Debian Package",
                    "ansible_roles": ["angie"],
                },
            },
            "containers": {
                "Uptime Kuma": {
                    "layer": 3,
                    "method": "podman-compose",
                },
                "Nebula-sync": {
                    "layer": 3,
                    "method": "podman-compose",
                },
            },
        },
    },
    "pi3b": {
        "name": "RaspberryPi 3b",
        "os": "Raspberry Pi OS 13",
        "services": {
            "lxc": None,
            "vms": None,
            "packages": {
                "squeezelite": {
                    "layer": 3,
                    "method": "Debian Package",
                }
            },
            "containers": {
                "wyoming-satellite": {
                    "layer": 3,
                    "method": "podman-compose",
                },
                "openWakeWord": {
                    "layer": 3,
                    "method": "podman-compose",
                },
            },
        },
    },
    "fbox": {
        "name": "Freebox (HP Mini PC)",
        "os": "Proxmox VE 9",
        "boards": [
            "Marvell PCIe 4 port Sata Controller",
            "Intel PCIe I226-V dual 2.5GBE",
            "Sonoff Zigbee 3.0 USB Dongle Plus",
        ],
        "services": {
            "lxc": lxcs,
            "vms": vms,
            "packages": None,
            "containers": None,
        },
    },
    "darkforce": {
        "name": "Farkforce",
        "layer": 3,
        "os": "Arch Linux",
        "boards": ["AMD Radeon RX 6800 XT"]
    },
    "feebook": {
        "name": "Freebook",
        "layer": 3,
        "os": "Debian"
    },
    "guestbook": {
        "name": "Guestbook",
        "layer": 3,
        "os": "Fedora"
    },
}

network = {
    "isp-modem" :{
        "layer": 1,
        "name": "ISP Modem",
        "connections": ["isp", "ucg-max"]
    },
    "ucg-max" :{
        "layer": 1,
        "name": "Ubiquity Cloud Gateway 2.5GBE",
        "connections": ["isp", "fbox", "darkforce", "pi5", "usw-flex"]
    },
    "usw-flex" :{
        "layer": 1,
        "name": "Ubiquity USW Flex Switch 2.5GBE",
        "connections": ["ucg-max", "tplink-sg108e","u7-pro"]
    },
     "tplink-sg108e":{
         "layer": 1,
         "name": "TPLink sg-108e Switch",
         "connections": ["usw-flex", "tv", "pi3b"]
     },
     "u7-pro" :{
         "layer": 1,
         "name": "Ubiquity U7 Pro WiFi AP",
         "connections": ["usw-flex"]
     }
}

# Node type mapping for known services
def get_node_type(service_name):
    # Custom icons mapping
    custom_icons = {
        "PiHole": PIHOLE_LOGO,
        "PiHole 2": PIHOLE_LOGO,
    }
    if service_name in custom_icons:
        return lambda label: Custom(label, custom_icons[service_name])
    
    mapping = {
        "Grafana": Grafana,
        "Prometheus": Prometheus,
        "Nginx Proxy Manager": Nginx,
        "PostgreSQL": PostgreSQL,
        "Redis": Redis,
        "Jellyfin": Server,
        "Transmission": Server,
        "Excalidraw": Server,
        "Copyparty": Server,
        "Immich": Server,
        "LanguageTool": Server,
        "Prosody": Server,
        "Coturn": Server,
        "KV": Server,
        "lore": Server,
        "Uptime Kuma": Server,
        "Nebula-sync": Server,
        "wyoming-satellite": Server,
        "openWakeWord": Server,
        "squeezelite": Server,
    }
    return mapping.get(service_name, Server)

# Format label from component data
def format_label(name, data):
    label = name
    if data:
        if "method" in data:
            label += f"\n({data['method']})"
        if "services" in data and data["services"]:
            label += f"\n[{', '.join(data['services'])}]"
    return label

# Build diagram - compact layout
with Diagram("HomeLab Infrastructure", show=False, filename="homelab_infra",
            graph_attr={"rankdir": "TB", "nodesep": "0.2", "ranksep": "0.3", "splines": "false", "size": "20,10!"}):

    # LAYER 1: Network Infrastructure (top row)
    isp = Firewall("ISP Modem")
    ucg_max = Router("UCG Max")
    usw_flex = Switch("USW Flex")
    tplink = Switch("TPLink")
    u7_pro = Blank("U7 Pro")
    tv = Blank("TV")

    # LAYER 2: Network Applications (middle)
    pi5_angie = Nginx("Nginx (Angie)")
    pi5_pihole = get_node_type("PiHole")(format_label("PiHole", {"method": "Debian Package"}))
    lxc_pihole2 = get_node_type("PiHole 2")(format_label("PiHole 2", lxcs["PiHole 2"]))

    # LAYER 3: Services (bottom - all flat)
    pi5_uptime = Server("Uptime Kuma")
    pi5_nebula = Server("Nebula-sync")
    haos = Qemu("HAOS\n(Zigbee)")
    truenas = Storage("TrueNAS\n(RAID Z1)")

    for name, data in lxcs.items():
        if data.get("layer") == 3:
            node_type = get_node_type(name)
            label = format_label(name, data)
            node_type(label)

    pi3_squeeze = Server("squeezelite")
    pi3_wyoming = Server("wyoming")
    pi3_openwake = Server("openWakeWord")
    darkforce = Rack("Darkforce\nRX 6800 XT")
    feebook = Debian("Feebook")
    guestbook = LinuxGeneral("Guestbook")

    # Connections (defines top-to-bottom flow)
    isp >> ucg_max
    ucg_max >> usw_flex
    usw_flex >> tplink
    usw_flex >> u7_pro
    tplink >> tv

    ucg_max >> pi5_angie
    ucg_max >> pi5_pihole
    ucg_max >> lxc_pihole2
    ucg_max >> darkforce
