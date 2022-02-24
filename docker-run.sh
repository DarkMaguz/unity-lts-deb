#!/bin/sh -e

# Find any existing deb files and delete them.
for OLD_DEB in unity-lts*.deb*
do
  rm -f $OLD_DEB
done

# The root folder for the deb file.
BASE_DIR=$(dirname `realpath $0`)/unity-lts

# Install path for Unity.
UNITY_PATH=$BASE_DIR/opt/Unity-LTS

# Make install path if missing.
if [ ! -d "$UNITY_PATH" ]; then
	mkdir -p $UNITY_PATH
fi

# Clean up.
cleanup() {
  rm -rf $BASE_DIR
  rm -f releases-linux.json
  rm -f *.tar.*
}

# Get available versions.
wget -q https://public-cdn.cloud.unity3d.com/hub/prod/releases-linux.json

# Get latest version available.
LATEST_VERSION=$(jshon -F releases-linux.json -e official -e -1 -e version | tr -d "\"")
if [ -z $LATEST_VERSION ]; then
  echo "Failed to get the latest version of Unity!"
  echo "Terminating..."
  cleanup
  exit 1
fi
echo "Latest version: $LATEST_VERSION"

# Get current version.
apt-get update -y
APT_SHOW_DATA=$(apt-cache show unity-lts || echo "")
CURRENT_VERSION=$(echo $APT_SHOW_DATA | grep -i version | cut -d' ' -f2)
echo "Current version: $CURRENT_VERSION"

# Check if we have the latest version.
UPDATE=""
if [ -z $CURRENT_VERSION ]; then
  UPDATE=true
elif [ "$LATEST_VERSION" != "$CURRENT_VERSION" ]; then
  UPDATE=true
fi

if [ $UPDATE ]; then
  # Get the archive URL.
  ARCHIVE_URL=$(jshon -F releases-linux.json -e official -e -1 -e downloadUrl | tr -d "\"" | tr -d "\\")
  if [ -z $ARCHIVE_URL ]; then
    echo "Failed to get the URL for the Unity archive!"
    cleanup
    exit 1
  fi

  # Download unity.
  wget $ARCHIVE_URL

  # Get name of the archive file.
  UNITY_ARCHIVE=$(echo $ARCHIVE_URL | rev | cut -d'/' -f1 | rev)

  # Extract the archive.
  tar -xvf $UNITY_ARCHIVE -C $UNITY_PATH

  # Make applications folder if missing.
  if [ ! -d "$BASE_DIR/usr/share/applications" ]; then
    mkdir -p $BASE_DIR/usr/share/applications
  fi

  # Insert Gnome desktop shortcut.
  cp -f Unity-STL.desktop $BASE_DIR/usr/share/applications/Unity-STL.desktop
  sed -i "s/VERSION/$LATEST_VERSION/g" $BASE_DIR/usr/share/applications/Unity-STL.desktop

  # Make DEBIAN folder if missing.
  if [ ! -d "$BASE_DIR/DEBIAN" ]; then
  	mkdir -p $BASE_DIR/DEBIAN
  fi

  # Generate control file.
  cp -f control.tmpl $BASE_DIR/DEBIAN/control
  sed -i "s/VERSION/$LATEST_VERSION/g" $BASE_DIR/DEBIAN/control

  # Insert post install and remove scripts.
  cp -f postinst $BASE_DIR/DEBIAN/postinst
  cp -f postrm $BASE_DIR/DEBIAN/postrm

  DPKG_NAME=unity-lts_"$LATEST_VERSION"_amd64.deb

  # Build Debian package.
  dpkg-deb --root-owner-group --build $BASE_DIR $DPKG_NAME

  # Change owner of the new deb file.
  chown $USERID:$GROUPID $DPKG_NAME
else
  echo "Unity LTS is up to date: \"$CURRENT_VERSION\""
fi

# Clean up.
cleanup
