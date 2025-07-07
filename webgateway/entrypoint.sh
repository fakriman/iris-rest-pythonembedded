#!/bin/bash
# entrypoint.sh
if [ ! -f "/gwfiles/irissrv.key" ]; then
  echo "Error: /gwfiles/irissrv.key no está disponible."
  exit 1
fi

# Continuar con el proceso de arranque
exec "$@"
