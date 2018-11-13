#!/bin/sh
set -e
if [ -f "$HOME/BYOND-${BYOND_VERSION}.${BYOND_BUILD}/byond/bin/DreamMaker" ];
then
  echo "Using cached BYOND directory."
else
  echo "Installing BYOND."
  mkdir -p "$HOME/BYOND-${BYOND_VERSION}.${BYOND_BUILD}"
  cd "$HOME/BYOND-${BYOND_VERSION}.${BYOND_BUILD}"
  echo "Installing BYOND to $PWD"
  curl "http://www.byond.com/download/build/${BYOND_VERSION}/${BYOND_VERSION}.${BYOND_BUILD}_byond_linux.zip" -o byond.zip
  sudo apt-get update
  sudo apt-get install zip unzip
  unzip -o byond.zip
  cd byond
  make here
fi
