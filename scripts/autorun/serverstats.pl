use Irssi;
use strict;
use vars qw($VERSION %IRSSI %servers);

$VERSION = '1.00';
%IRSSI = (
    authors 	=> 'Eric Jansen',
    contact 	=> 'chaos@sorcery.net',
    name 	=> 'serverstats',
    description => 'Displays the top servers for a channel',
    license 	=> 'GPL',
    modules	=> '',
    url		=> 'http://xyrion.org/irssi/',
    changed 	=> 'Sun Mar 16 17:44:26 CET 2003'
);

sub cmd_serverstats {

    my ($data, $server, $witem) = @_;

    $server->redirect_event('who', 1, undef, 0, undef,
	{
	    'event 352' => 'redir who_line',
	    'event 315' => 'redir who_done'
	}
    );
    $server->send_raw("WHO $data");
}

sub event_who_line {

    my ($server, $data, $from, $address) = @_;

    if($data =~ /^[^\s]+ [^\s]+ [^\s]+ [^\s]+ ([^\s]+)/) {

	$servers{$1} = defined $servers{$1} ? $servers{$1} + 1 : 1;
    }
}

sub event_who_done {

    my ($server, $data, $target, $address) = @_;

    my @top = sort {$servers{$b} <=> $servers{$a}} keys %servers;
    my $rank = 1;

    $server->printformat($target, MSGLEVEL_CRAP, 'serverstats_head');

    foreach my $key (@top) {

	$server->printformat($target, MSGLEVEL_CRAP, 'serverstats_line', $rank++, $key, $servers{$key});
    }

    undef %servers;
}

Irssi::command_bind('serverstats', 'cmd_serverstats');
Irssi::signal_add('redir who_line', 'event_who_line');
Irssi::signal_add('redir who_done', 'event_who_done');
Irssi::Irc::Server::redirect_register('who', 0, 0,
    {
	'event 352' => -1
    },
    {
	'event 315' => -1
    },
    undef
);
Irssi::theme_register([
    'serverstats_head', '     Server                Users',
    'serverstats_line', '[$[-2]0] {hilight $[30]1} [$[-5]2]'
]);
