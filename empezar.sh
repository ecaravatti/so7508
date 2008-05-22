rm -rf $HOME/facu/SistOP/*
mkdir $HOME/facu/SistOP/grupo03
export GRUPO=$HOME/facu/SistOP/grupo03
cp $HOME/SVN/trunk/Ginsta/ginsta.sh $GRUPO/../
cp $HOME/SVN/trunk/Galida/galida.sh $GRUPO/../
cp $HOME/SVN/trunk/Gemoni/gemoni.sh $GRUPO/../
cp $HOME/SVN/trunk/Gontro/gontro.pl $GRUPO/../
cp $HOME/SVN/trunk/Gontro/gontrosub.pm $GRUPO/../
cp $HOME/SVN/trunk/Mover/mover.sh $GRUPO/../
cp $HOME/SVN/trunk/Glog/glog.sh $GRUPO/../
mkdir $GRUPO/../tests
cp -r $HOME/SVN/trunk/Tests/* $GRUPO/../tests
