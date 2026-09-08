# Hat Labs HALPI2 add-ons

Home Assistant OS add-ons for the HALPI2 Raspberry Pi CM5 carrier board.

| Add-on | Purpose |
|--------|---------|
| [halpid](halpid) | Power monitoring, hardware watchdog, LED and USB port control |

## Installing

Add this repository in Home Assistant under **Settings → Add-ons → Add-on store →
⋮ → Repositories**, then install the add-on from the store.

HAOS does not enable I2C by default, and the add-on cannot enable it. Do that
first; `halpid/DOCS.md` has the two host commands.
