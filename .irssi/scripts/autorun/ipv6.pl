use Irssi;
use strict;
use vars qw($VERSION %IRSSI);

$VERSION = '1.00';
%IRSSI = (
    authors 	=> 'Eric Jansen',
    contact 	=> 'chaos@sorcery.net',
    name 	=> 'ipv6',
    description => 'Displays all users connected via IPv6',
    commands	=> 'showipv6',
    license 	=> 'GPL',
    modules	=> '',
    url		=> 'http://xyrion.org/irssi/',
    changed 	=> 'Sun May 11 16:11:31 CEST 2003'
);

sub cmd_showipv6 {

    my ($data, $server, $witem) = @_;

    $server->redirect_event('stats l', 1, undef, 0, undef,
	{
	    'event 211' => 'redir ipv6_statsl',
	    'event 219' => 'redir ipv6_statsl'
	}
    );
    $server->send_raw("STATS L *");
}

sub event_statsl {

    my ($server, $data, $from, $address) = @_;

    if($data =~ /(\S+) (\S+)\[\@([^\]]+)\.\d+\] \d+ \d+ \d+ \d+ \d+ \d+ :\d+$/) {

	my($target, $nick, $host) = ($1, $2, $3);

	if($host =~ /:/ && $host ne '0:0:0:0:0:0:0:0') {

	    $server->printformat($target, MSGLEVEL_CRAP, 'ipv6_user', $nick, $host);
        }
    }
}

Irssi::command_bind('showipv6', 'cmd_showipv6');
Irssi::signal_add('redir ipv6_statsl', 'event_statsl');
Irssi::Irc::Server::redirect_register('stats l', 0, 0,
    {
	'event 211' => -1
    },
    {
	'event 219' => -1
    },
    undef
);
Irssi::theme_register([
    'ipv6_user', '[{nick $[17]0}] [{host $1}]'
]);
