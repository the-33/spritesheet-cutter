#!/bin/bash
set -e

### CONFIG ###
OWNER="the-33"
REPO="spritesheet-cutter"
APP_NAME="Spritesheet Cutter"
INSTALL_DIR="/opt/$APP_NAME"
BIN_PATH="/usr/local/bin/$APP_NAME"
DESKTOP_FILE="/usr/share/applications/$APP_NAME.desktop"

echo "→ Obteniendo última release de GitHub…"

LATEST_TAR=$(curl -s "https://api.github.com/repos/$OWNER/$REPO/releases/latest" \
  | grep browser_download_url \
  | grep ".tar.gz" \
  | cut -d '"' -f 4 | head -n 1)

if [ -z "$LATEST_TAR" ]; then
  echo "ERROR: No se encontró ningún archivo .tar.gz en la última release."
  exit 1
fi

echo "→ Última release encontrada:"
echo "  $LATEST_TAR"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

echo "→ Descargando release…"
curl -L -O "$LATEST_TAR"

FILE_NAME=$(basename "$LATEST_TAR")

echo "→ Extrayendo archivos…"
tar xzf "$FILE_NAME"

APP_DIR=$(find . -maxdepth 1 -type d ! -name '.' | head -n 1)

if [ -z "$APP_DIR" ]; then
  echo "ERROR: No se detectó carpeta dentro del tar.gz."
  exit 1
fi

echo "→ Instalando en $INSTALL_DIR …"
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"
sudo cp -r "$APP_DIR"/. "$INSTALL_DIR"

echo "→ Creando lanzador en $BIN_PATH …"
sudo bash -c "cat > '$BIN_PATH' << 'EOF'
#!/bin/bash
cd '$INSTALL_DIR'
yarn install
yarn dev &
xdg-open http://localhost:1234
EOF"
sudo chmod +x "$BIN_PATH"

echo "→ Creando entrada de escritorio…"
sudo bash -c "cat > '$DESKTOP_FILE' << EOF
[Desktop Entry]
Type=Application
Name=Spritesheet Cutter
Exec=$BIN_PATH
Icon=$APP_NAME
Terminal=false
Categories=Development;Graphics;
EOF"

sudo cp "$INSTALL_DIR/icon.png" "/usr/share/pixmaps/$APP_NAME.png"

echo "→ Limpiando archivos temporales…"
rm -rf "$TMP_DIR"

echo ""
echo "✓ Instalación completada correctamente."
echo "Puedes iniciar la app desde el menú o escribiendo: $APP_NAME"
