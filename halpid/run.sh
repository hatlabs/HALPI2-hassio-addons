#!/usr/bin/with-contenv bashio
set -e

readonly CONF=/etc/halpid/halpid.conf

if bashio::config.true 'shutdown_host'; then
    poweroff_command=/usr/bin/ha-poweroff
else
    poweroff_command=""
    bashio::log.warning "shutdown_host is off: a blackout will not halt the host."
fi

# The socket lives on the share so that other add-ons can reach the API. The
# bundled halpi CLI has no --socket flag and always opens the path below.
mkdir -p /share/halpid /run/halpid
ln -sf /share/halpid/halpid.sock /run/halpid/halpid.sock

cat > "${CONF}" <<CONFEOF
i2c-bus: $(bashio::config 'i2c_bus')
i2c-addr: $(bashio::config 'i2c_addr')
socket: /share/halpid/halpid.sock
led-socket: /share/halpid/led.sock
socket-group: adm
blackout-time-limit: $(bashio::config 'blackout_time_limit')
blackout-voltage-limit: $(bashio::config 'blackout_voltage_limit')
poweroff: "${poweroff_command}"
CONFEOF

bashio::log.info "Starting halpid"
export RUST_LOG="halpid=$(bashio::config 'log_level')"
exec /usr/bin/halpid --conf "${CONF}"
