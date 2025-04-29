#!/usr/bin/perl
#
# DW::Controller::Index
#
# Controller for the site homepage.


package DW::Controller::Index;

use strict;
use warnings;

use DW::Routing;
use DW::Template;
use DW::Controller;
use DW::Panel;
use DW::Widget::QuickUpdate;

DW::Routing->register_string( '/index', \&indexfree_handler,        app => 1 );

sub indexfree_handler {
    my ( $ok, $rv ) = controller( anonymous => 1 );
    return $rv unless $ok;

	my $remote = $rv->{remote};
	my $stuff;
	my $widget;

	if ($remote) {
	    $stuff->{remote} = $remote;
		$stuff->{panel} = DW::Panel->init( u => $remote );
		#$stuff->{widget} = DW::Widget::QuickUpdate->render_body( $remote );
		
        $widget->{primary} = DW::Widget::QuickUpdate->render_body;
		$stuff->{helpme} = DW::Panel->_render( $widget );
	}

	else {
		$stuff->{panel} = DW::Panel->init( u => $remote );
	}

	return DW::Template->render_template( 'index-free.tt', $stuff );
}

#DW::Routing->register_static( '/index',           'index-free.tt',      app => 1 );

1;
