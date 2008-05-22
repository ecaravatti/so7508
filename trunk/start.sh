#!/bin/bash

GRUPO="$HOME/Desktop/grupo03"
PRUEBA="$HOME/Desktop/prueba"
REPO="$HOME/Documentos/Facu/Sistemas Operativos/TPSO1C08"

rm -r -f $GRUPO
rm -r -f $PRUEBA
mkdir $GRUPO
mkdir -p $PRUEBA/tests
cp "$REPO/Galida/galida.sh" $PRUEBA
cp "$REPO/Gemoni/gemoni.sh" $PRUEBA
cp "$REPO/Ginsta/ginsta.sh" $PRUEBA
cp "$REPO/Glog/glog.sh" $PRUEBA
cp "$REPO/Gontro/gontro.pl" $PRUEBA
cp "$REPO/Gontro/gontrosub.pm" $PRUEBA
cp "$REPO/Mover/mover.sh" $PRUEBA
cp -r "$REPO/Tests/arridir/tests a entregar/invalidos/." $PRUEBA/tests/arridir
cp -r "$REPO/Tests/arridir/tests a entregar/validos/." $PRUEBA/tests/arridir
cp -r "$REPO/Tests/arridir/tests a entregar/validos/los que deberian procesar el periodo xq sus reg estan bien/." $PRUEBA/tests/arridir
cp -r "$REPO/Tests/confdir" $PRUEBA/tests
rm -r -f "$PRUEBA/tests/arridir/los que deberian procesar el periodo xq sus reg estan bien"
