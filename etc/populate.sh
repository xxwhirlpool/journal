#!/bin/bash

$LJHOME/bin/upgrading/update-db.pl -r --innodb
$LJHOME/bin/upgrading/update-db.pl -r --innodb # at least for now we have to run this twice
$LJHOME/bin/upgrading/update-db.pl -r --cluster=all --innodb
$LJHOME/bin/upgrading/update-db.pl -p
#$LJHOME/bin/upgrading/texttool.pl load
#$LJHOME/bin/build-static.sh

