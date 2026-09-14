# HALPI2 daemon

## Before you install: enable I2C on the host

The RP2040 controller answers on `/dev/i2c-1` at address `0x6D`. Stock Home
Assistant OS reaches neither, and an add-on cannot change either setting. Both
commands below run from the Advanced SSH & Web Terminal add-on with protection
mode off.

Uncomment the I2C boot parameter:

```bash
sudo docker run --rm -v /mnt/boot:/boot alpine \
  sed -i "s/^#dtparam=i2c_arm=on/dtparam=i2c_arm=on/" /boot/config.txt
```

Load the `i2c-dev` module at every boot. `/mnt/overlay/etc` is the persistent
source of the host's `/etc`; the rest of `/etc` is read-only:

```bash
sudo docker run --rm -v /mnt/overlay:/ov alpine \
  sh -c 'echo i2c-dev > /ov/etc/modules-load.d/i2c-dev.conf'
```

Reboot the host. Confirm the result before installing the add-on:

```bash
ls /dev/i2c-1
```

RAUC rewrites the `os_prefix` line of the same `config.txt` when Home Assistant
OS updates, so check the I2C parameter after an OS update.

## The watchdog

halpid arms the controller's hardware watchdog at startup, with a 10 second
timeout, and feeds it with every I2C read. That is the daemon's purpose: if the
operating system stops responding, the controller power-cycles the board.

Stopping the add-on is safe. halpid disables the watchdog when it receives
SIGTERM, which is how the Supervisor stops it, and a stopped add-on does not
power-cycle anything.

Killing the add-on is not safe, and that is deliberate. If the container is
killed rather than stopped — SIGKILL, an out-of-memory kill, a kernel hang —
the watchdog stays armed and the controller cuts power about 10 seconds later.
The board reboots and all five LEDs turn solid red.

## Options

| Option | Default | Meaning |
|--------|---------|---------|
| `i2c_bus` | `1` | I2C bus the controller is on |
| `i2c_addr` | `0x6D` | Controller address |
| `blackout_time_limit` | `5.0` | Seconds below the voltage limit before shutdown starts |
| `blackout_voltage_limit` | `9.0` | DC input voltage that counts as a blackout |
| `shutdown_host` | `true` | Halt the host on a blackout |
| `mqtt` | `true` | Publish readings and USB switches over MQTT |
| `mqtt_interval` | `5` | Seconds between MQTT state publishes |
| `log_level` | `info` | `error`, `warn`, `info`, `debug` or `trace` |

Set `shutdown_host` to `false` to watch the blackout logic without it halting
the machine. The daemon still detects the blackout and still tells the
controller; it just runs no command.

## Reaching the API

halpid serves an HTTP API over a UNIX socket. The add-on puts both of its
sockets on the shared `/share` directory so other add-ons can reach them:

- `/share/halpid/halpid.sock` — the daemon API, group `adm`
- `/share/halpid/led.sock` — LED override, group `adm`

The bundled `halpi` CLI has no option for the socket path and always opens
`/run/halpid/halpid.sock`, so the add-on symlinks that path to the one on the
share. From the Advanced SSH add-on:

```bash
sudo docker exec app_local_halpid halpi status
sudo docker exec app_local_halpid halpi usb
```

A container that reaches the socket directly needs to run as root or as a
member of the `adm` group.

## Home Assistant entities

The add-on publishes to the MQTT broker the Supervisor gives it, using Home
Assistant discovery, so the entities appear on their own without any YAML. The
service is declared `mqtt:want`: with no broker installed the add-on still runs
the daemon and the watchdog, and publishes nothing.

One device, `HALPI2`, carrying:

| Entity | Kind |
|--------|------|
| DC input voltage, DC input current, supercapacitor voltage | sensor |
| Controller temperature, board temperature | sensor |
| Controller state, watchdog elapsed, watchdog, 5 V output | diagnostic |
| USB port 0 to USB port 3 | switch |

The controller reports temperatures in kelvin; the add-on converts them to
degrees Celsius before publishing.

**A USB switch cuts power to whatever is plugged into that port.** On a machine
whose Z-Wave or Zigbee coordinator is a USB stick, turning off the wrong port
takes that network down until it is turned back on. Check which port holds what
before using the switches.

Topics, for anything that wants them directly:

- `halpi2/<device_id>/state` — every value as one retained JSON message
- `halpi2/<device_id>/availability` — `online` or `offline`
- `halpi2/<device_id>/usb/<0-3>/set` — `ON` or `OFF`

## Shutting the host down

An add-on cannot halt Home Assistant OS itself. When the DC input stays below
`blackout_voltage_limit` for `blackout_time_limit` seconds, halpid runs
`/usr/bin/ha-poweroff`, which posts to the Supervisor's `/host/shutdown`
endpoint. That is why the add-on asks for `hassio_role: manager`.
