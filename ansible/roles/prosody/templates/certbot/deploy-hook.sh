#!/bin/sh
# certbot deploy hook: install renewed certificates into Prosody and into the
# private angie TLS store (used for the coturn/5349 stream listener), then
# reload both services. certbot runs every script under
# /etc/letsencrypt/renewal-hooks/deploy/ after each successful issuance.
set -e

CERT_NAME="{{ certbot_cert_name }}"
LE_LIVE="/etc/letsencrypt/live"
ANGIE_TLS="/etc/angie/tls"

# Prosody: import all certificates under /etc/letsencrypt/live into
# /etc/prosody/certs and reload prosody.
/usr/bin/prosodyctl --root cert import "${LE_LIVE}"

# Resolve the certificate source directory. certbot exports RENEWED_LINEAGE
# while running deploy hooks on renewal; otherwise prefer the stable lineage
# name, falling back to the first certificate found (transition window while
# an older lineage name is still in use).
SRC=""
if [ -n "${RENEWED_LINEAGE:-}" ] && [ -f "${RENEWED_LINEAGE}/fullchain.pem" ]; then
	SRC="${RENEWED_LINEAGE}"
elif [ -f "${LE_LIVE}/${CERT_NAME}/fullchain.pem" ]; then
	SRC="${LE_LIVE}/${CERT_NAME}"
else
	for d in "${LE_LIVE}"/*/; do
		if [ -f "${d}fullchain.pem" ]; then
			SRC="${d%/}"
			break
		fi
	done
fi
if [ -z "${SRC}" ]; then
	echo "no certificate found under ${LE_LIVE}" >&2
	exit 1
fi

# Angie (stream ssl for coturn on 5349): angie reads a private copy because
# /etc/letsencrypt/archive is only readable by root.
install -d -o root -g angie -m 0750 "${ANGIE_TLS}"
install -o root -g angie -m 0644 "${SRC}/fullchain.pem" "${ANGIE_TLS}/${CERT_NAME}.crt"
install -o root -g angie -m 0640 "${SRC}/privkey.pem" "${ANGIE_TLS}/${CERT_NAME}.key"

if command -v systemctl >/dev/null 2>&1; then
	systemctl reload angie >/dev/null 2>&1 || true
fi
