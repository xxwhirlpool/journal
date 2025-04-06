#!/bin/bash
#
# Designed to be run as part of the Docker setup. Do not run this
# script manually.
#

$LJHOME/bin/upgrading/update-db.pl -r --innodb
$LJHOME/bin/upgrading/update-db.pl -r --innodb # at least for now we have to run this twice
$LJHOME/bin/upgrading/update-db.pl -r --cluster=all --innodb
$LJHOME/bin/upgrading/update-db.pl -p
$LJHOME/bin/upgrading/texttool.pl load

# Set up Apache2.
rm -rf /etc/apache2
ln -s /dw/ext/local/etc/apache2 /etc/apache2

# Set up Varnish.
rm -rf /etc/varnish/default.vcl
ln -s /dw/ext/local/etc/varnish/dreamwidth.vcl /etc/varnish/default.vcl
