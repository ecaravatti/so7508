#!/bin/bash

GRUPO="$HOME/Desktop/grupo03"
INSTALL="$HOME/Desktop/install"
REPO="$HOME/Documentos/Facu/Sistemas Operativos/TPSO1C08"

rm -r -f $GRUPO
rm -r -f $INSTALL
mkdir $GRUPO
mkdir -p $INSTALL/tests
cp "$REPO/Galida/galida.sh" $INSTALL
cp "$REPO/Gemoni/gemoni.sh" $INSTALL
cp "$REPO/Ginsta/ginsta.sh" $INSTALL
cp "$REPO/Glog/glog.sh" $INSTALL
cp "$REPO/Gontro/gontro.pl" $INSTALL
cp "$REPO/Gontro/gontrosub.pm" $INSTALL
cp "$REPO/Mover/mover.sh" $INSTALL
cp -r "$REPO/Tests/arridir/tests a entregar/invalidos/." $INSTALL/tests/arridir
cp -r "$REPO/Tests/arridir/tests a entregar/validos/." $INSTALL/tests/arridir
cp -r "$REPO/Tests/arridir/tests a entregar/validos/los que deberian procesar el periodo xq sus reg estan bien/." $INSTALL/tests/arridir
cp -r "$REPO/Tests/confdir" $INSTALL/tests
rm -r -f "$INSTALL/tests/arridir/los que deberian procesar el periodo xq sus reg estan bien"
