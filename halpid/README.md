# HALPI2 daemon

Runs [halpid](https://github.com/hatlabs/HALPI2-rust-daemon) on Home Assistant
OS. halpid talks to the HALPI2 carrier board's RP2040 controller over I2C, so
the board can shut the host down on a power failure, power-cycle individual USB
ports, and drive the status LEDs.

Read `DOCS.md` before installing: the I2C bus has to be enabled on the host
first, and the hardware watchdog changes what a crash does.
