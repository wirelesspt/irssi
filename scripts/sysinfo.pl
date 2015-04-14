#!/usr/bin/perl
# ----------------------------------------------------------------
# sysinfo for irssi and xchat
# usage : /sys
# Optional requirements: xdpyinfo, nvclock, sensors, lspci Wink
#
# Uses code from different scripts:
# whoo's hacked up sysinfo whoo owneratowenmeanydotcom
# System Info from wolssiloa rubenkatemaildotcom
# xchatinfo Laurens "Law" Buhler and Alain "Doos" van Acker
# email: Lawatnixhelpdotorg and A.v.aathomedotnl
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#

my $VERSION = "1.7.4";
my $IRSSI = (
authors => "h3k/Bigun",
contact => "bigun@cybergrunge.com",
name => "Sysinfo",
description => "Linux system information",
license => "GPL",
url => "",
changed => "Added ability to change gender inside irc client"
);

use strict;

BEGIN{
use vars '$irssi','$xchat';
eval q{
use Irssi;
Irssi::version();
};
$irssi = !$@;
eval q{
IRC::get_info(1);
};
$xchat = !$@;
}

# show what v<genitalia> information
my $show_vpenis = 0;
my $show_vboobies = 0;

# to nerv oder not to nerv
my $config_file ="$ENV{HOME}/.sysinfo.conf" ;
my $color = 1;

# proc directory
my $procloc = "/proc";

# S.M.A.R.T. HDD
my $SMARTDRIVE = "/dev/sdb";
my $SMARTDRIVE_SUDO = "sudo";

if ( -e "$config_file" ) {
open (CONFIGF, "<$config_file");
$color = <CONFIGF>;
close (CONFIGF);
}

sub set_gender
{
	my $input = shift;
	if ($input eq "m") {
		$show_vpenis = 1;
		$show_vboobies = 0;
		IRC::print ("gender set to male");
	} if ($input eq "f") {
		$show_vpenis = 0;
		$show_vboobies = 1;
		IRC::print ("gender set to female");
	} if ($input eq "1") {
		$show_vpenis = 1;
		$show_vboobies = 1;
		IRC::print ("gender set to hermaphrodite");
	} if ($input eq "0") {
		$show_vpenis = 0;
		$show_vboobies = 0;
		IRC::print ("gender turned off");
	}
	return 1;
}

sub set_color
{
$color = shift;
open (CONFIGF, ">$config_file");
print CONFIGF "$color";
close (CONFIGF);
if ($xchat) {
IRC::print ("sysinfo color set to $color");
} else {
print "sysinfo color set to $color";
}
return 1 ;
}

sub file_executable
{
my $command = shift;
my @directories=split(/:/, $ENV{'PATH'} );
for (@directories) {
if ( -x "$_/$command" ) {
return 1;
}
}
return 0;
}

sub display_sys_info
{
#--COLORS--#
my $TITLE_S = "\002";
my $TITLE_E = "\002";
my $ALERT_S = "\002";
my $NORMAL_S = "";
my $ALERT_E = "\002";
my $NORMAL_E = "";
if ( $color ) {
$ALERT_E = "\003";
$NORMAL_E = "\003";
$ALERT_S = "\0034";
$NORMAL_S = "\0033";
}

#--UNAME--#
open (X, "${procloc}/version");
my $UNAME = <X>;
close (X);

$UNAME =~ s/^(\S+) \S+ (\S+) .*\n$/$1 $2/;

my $SPEW = "${TITLE_S}SysInfo:${TITLE_E} $UNAME ${TITLE_S}";

#--PROCESSOR--#
my $NUM = 0;
my $MIPS = 0;
my ($MODEL,$SYSTEM);
my $CPU = 0;

open (X, "${procloc}/cpuinfo");
while (<X>)
{
if (/^(cpu model|model name).*: (.*)\n$/) {
$MODEL = $2;
$NUM += 1;
} elsif (/^system type.*: (.*)\n$/) {
$SYSTEM = $1;
} elsif (!$CPU && /^cpu MHz.*: (.*)\n$/) {
$CPU = $1;
} elsif (/^bogomips.*: (.*)\n$/i) {
$MIPS += $1;
}
}
close (X);

#--SUPPORT FOR MULTIPLE PROCS--#
if ($NUM == 2 ) { $MODEL="Dual $MODEL"; }
if ($NUM == 4 ) { $MODEL="Quad $MODEL"; }

$MODEL = $SYSTEM . " " . $MODEL;

$SPEW .= "|${TITLE_E} $MODEL $CPU MHz ${TITLE_S}| Bogomips:${TITLE_E} $MIPS ${TITLE_S}";

#--MEMORY--#
my($MEMTOTAL,$MEMFREE);
open(X, "${procloc}/meminfo") or $MEMTOTAL = 1;
while(<X>){
chomp;
if(/^MemTotal:\s+(\d+)/){
$MEMTOTAL = sprintf("%.0f",$1/1024);
}elsif(/^MemFree:\s+(\d+)/){
$MEMFREE = sprintf("%.0f",$1/1024);
}elsif(/^Buffers:\s+(\d+)/){
$MEMFREE += sprintf("%.0f",$1/1024);
}elsif(/^Cached:\s+(\d+)/){
$MEMFREE += sprintf("%.0f",$1/1024);
}
}
close(X);

#--PERCENTAGE OF MEMORY FREE--#
my $MEMPERCENT = sprintf("%.1f",(100/${MEMTOTAL}*${MEMFREE}));

#--BARGRAPH OF MEMORY FREE--#
my $FREEBAR = int(${MEMPERCENT}/10);
my $MEMBAR;
my $x;

$MEMBAR = "${TITLE_S}\[${NORMAL_S}";

for ($x = 0;$x < 10; $x++)
{
if ( $x == $FREEBAR ) {
$MEMBAR .= "${ALERT_S}";
}
$MEMBAR .= "\|";
}
$MEMBAR .= "${ALERT_E}]${TITLE_E}";

$SPEW .= "| Mem:${TITLE_E} ${MEMFREE}/${MEMTOTAL}M $MEMBAR ${TITLE_S}";

#--DISKSPACE--#
my $HDD = 0;
my $HDDFREE = 0;
my $SCSI = 0;
my $SCSIFREE = 0;

for (`df 2>/dev/null`) {
if (/^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|[sh]d[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/) {
$HDD += $2;
$HDDFREE += $3;
}
if (/^\/dev\/(ida\/c[0-9]d[0-9]p[0-9]|sd[a-z][0-9]+)\s+(\d+)\s+\d+\s+(\d+)\s+\d+%/) {
$SCSI += $2;
$SCSIFREE += $3;
}
}

my $ALL = $HDD;
$HDDFREE = sprintf("%.02f", $HDDFREE / 1048576)."G";
$HDD = sprintf("%.02f", $HDD / 1048576)."G";
$SPEW .= "| Diskspace:${TITLE_E} $HDD ${TITLE_S}Free:${TITLE_E} $HDDFREE ${TITLE_S}";

#--PROCS RUNNING--#
opendir(PROC, "${procloc}");
my $PROCS = scalar grep(/^\d/,readdir PROC);
$SPEW .= "| Procs:${TITLE_E} $PROCS ${TITLE_S}";

#--UPTIME--#
open (X, "${procloc}/uptime");
my $up2 = "";
my $uptime = <X>;
close (X);
$uptime =~ s/(\d+\.\d+)\s\d+\.\d+/$1/;

my $years = sprintf ("%.d",$uptime/31536000) || 0;
my $yearbase = sprintf ($years * 31536000);
my $weeks = sprintf ("%.d",($uptime - $yearbase)/6048000) || 0;
my $weekbase = sprintf ($weeks * 6048000);
my $days = sprintf ("%.d",($uptime - $yearbase - $weekbase)/86400) || 0;
my $daybase = sprintf ($days * 86400);
my $hours = sprintf ("%.d",($uptime - $yearbase - $weekbase - $daybase)/3600) || 0;
my $hourbase = sprintf ($hours * 3600);
my $mins = sprintf ("%.d",($uptime - $yearbase - $weekbase - $daybase - $hourbase)/60) || 0;
my $minbase = sprintf ($mins * 60);
my $secs = sprintf ("%.d",($uptime - $yearbase - $weekbase - $daybase - $hourbase - $minbase)) ||0;

if ($years){$up2 .= $years =~ /^1$/ ? "$years yr " : "$years yrs ";}
if ($weeks){$up2 .= $weeks =~ /^1$/ ? "$weeks wk " : "$weeks wks ";}
if ($days){$up2 .= $days =~ /^1$/ ? "$days day " : "$days days ";}
if ($hours){$up2 .= $hours =~ /^1$/ ? "$hours hr " : "$hours hrs ";}
if ($mins){$up2 .= $mins =~/^[01]$/ ? "$mins min " : "$mins mins ";}

$up2 .= $secs =~ /^[01]$/ ? "$secs sec" : "$secs secs";
$SPEW .= "| Uptime:${TITLE_E} $up2 ${TITLE_S}";

#--LOAD--#
if (open (X, "${procloc}/loadavg")) {
my $LOADAVG = <X>;
close (X);
$LOADAVG =~ s/^((\d+\.\d+\s){3}).*\n$/$1/;
$SPEW .= "| Load:${TITLE_E} $LOADAVG ${TITLE_S}";
}

#--Virtual Penis--#
my $VPENIS = 70;
$VPENIS += int($uptime/3600/24)/10;
$VPENIS += $CPU*$NUM/30;
$VPENIS += $MEMTOTAL/3;
$VPENIS += ($ALL+$SCSI)/1024/50/15;
$VPENIS = int($VPENIS)/10;
my $cup = "";
if ( $VPENIS < 10 ) { $cup = "A"; }
if ( $VPENIS > 10 && $VPENIS < 20 ) { $cup = "B"; }
if ( $VPENIS > 20 && $VPENIS < 30 ) { $cup = "C"; }
if ( $VPENIS > 30 && $VPENIS < 40 ) { $cup = "D"; }
if ( $VPENIS > 40 && $VPENIS < 50 ) { $cup = "E"; }
if ( $VPENIS > 50 && $VPENIS < 60 ) { $cup = "F"; }
if ( $VPENIS > 70 ) { $cup = "G"; }
my $vbust = int( ($VPENIS/4) + 28);
if ( $show_vpenis ) {
	$SPEW .= "| Vpenis:${TITLE_E} $VPENIS cm ${TITLE_S}";
} if ( $show_vboobies ) {
	$SPEW .= "| Vboobies:${TITLE_E} $vbust$cup ${TITLE_S}";
}

#--GRAPHICSCARD--#
my $VGA = "unknown";
if (file_executable("lspci") == 1) {
for (`lspci 2>/dev/null`){
if (/VGA compatible controller:\s(.*)$/){
$VGA = $1; }
}
}
elsif ( -e "${procloc}/pci" ){
open(X, "${procloc}/pci") ;
while(<X>){
chomp;
if (/VGA compatible controller:\s(.*)\.$/){
$VGA = $1; }
}
close(X);
}
$SPEW .= "| Screen:${TITLE_E} ${VGA} ";

#--SCREEN RESOLUTION--#
my ($DEPTH,$RES);
if (file_executable("xdpyinfo")) {
for(`xdpyinfo 2>/dev/null`){
if(/\s+dimensions:\s+(\S+)/){
$RES = $1;
}elsif(/\s+depth:\s+(\S+)/){
$DEPTH = $1;
}
}
if ($DEPTH) { $SPEW .= "\@ $RES ($DEPTH bpp) "; }
}


#--NVIDIA CORE FREQUENCY--#
my $NVCLOCK;
if (file_executable("nvclock") == 1) {
for (`nvclock -s 2>/dev/null`){
if (/^GPU clock:\s+(\d+\.\d+\sMHz)$/){
$NVCLOCK = $1;
}
}
$SPEW .= "${TITLE_S}GPU clock:${TITLE_E} $NVCLOCK ";
}

#--NETINFO--#
my $route = "";
my $netdev = "";
my $NETDEVICE = "lo";

open(X, "${procloc}/net/route") or $route = "NA";
while(<X>){
chomp;
if (/^(.*?)\s+\d+\s+.*\s+0003\s+\d\s+/)
{ $NETDEVICE = $1; }
}
close(X);

my $PACKIN;
my $PACKOUT;

if ( open(X, "${procloc}/net/dev")) {
while(<X>){
chomp;
if (/^(\s+)?$NETDEVICE/) {
/^\s+(.*?)(Sad\s+|)(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)\s+/;
$PACKIN = sprintf("%.2f",$3 / 1048576);
$PACKOUT = sprintf("%.2f",$4 / 1048576);
}
}
close(X);
if($PACKIN < 1024) { $PACKIN .= "M"; } else { $PACKIN = sprintf("%.02f", $PACKIN / 1024)."G"; }
if($PACKOUT < 1024) { $PACKOUT .= "M"; } else { $PACKOUT = sprintf("%.02f", $PACKOUT / 1024)."G"; }
$SPEW .= "${TITLE_S}| $NETDEVICE: In:${TITLE_E} $PACKIN ${TITLE_S}Out:${TITLE_E} $PACKOUT ";
}

#--LM_SENSORS--#
my $SPEW2 = "";
my $SENSOR1 = "NA";
my $SENSOR2 = "NA";
my $SENSOR3 = "NA";
my $SENSOR4 = "NA";
if ( -e "${procloc}/sys/dev/sensors" && file_executable("sensors") == 1) {
for (`sensors 2>/dev/null`){
if (/^[tT]emp2.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/) {
if (!$2) { $SENSOR1 = "${NORMAL_S} $1${NORMAL_E}"; }
else { $SENSOR1 = "${ALERT_S} $1${ALERT_E}"; }
} elsif (/^[tT]emp1.*:\s+(.*(\s|.|)[FC])\s+\(.*\)(\s+ALARM)?/) {
if (!$2) { $SENSOR2 = "${NORMAL_S} $1${NORMAL_E}"; }
else { $SENSOR2 = "${ALERT_S} $1${ALERT_E}"; }
} elsif (/^fan1:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/) {
if (!$2) { $SENSOR3 = "${NORMAL_S} $1${NORMAL_E}"; }
else { $SENSOR3 = "${ALERT_S} $1${ALERT_E}"; }
} elsif (/^fan2:\s+(\d+\sRPM)\s+\(.*\)(\s+ALARM)?/) {
if (!$2) { $SENSOR4 = "${NORMAL_S} $1${NORMAL_E}"; }
else { $SENSOR4 = "${ALERT_S} $1${ALERT_E}"; }
}
}
$SPEW2 .= "${TITLE_S}CPU:${TITLE_E}$SENSOR1 ${TITLE_S}Fan:${TITLE_E}$SENSOR3 ${TITLE_S}Case:${TITLE_E}$SENSOR2 ${TITLE_S}Fan:${TITLE_E}$SENSOR4 ";
}

#--HDDTEMP--#
my $HDDTEMP;
if ( file_executable("hddtemp") == 1) {
for (`$SMARTDRIVE_SUDO hddtemp $SMARTDRIVE 2>/dev/null`){
if (/^\/dev\/[sh]d.*:\s+(.*):\s+(.*)$/) {
$HDDTEMP = $2;
}
}
$SPEW2 .= "${TITLE_S}HDD:${TITLE_E} $HDDTEMP";
}


#--CHANNEL OUTPUT--#
if ($irssi) {
Irssi::active_win->command("/say $SPEW");
if ($SPEW2) { Irssi::active_win->command("/say ${TITLE_S}Sensors:${TITLE_E} $SPEW2") };
} elsif ($xchat) {
IRC::command("/say $SPEW");
if ( $SPEW2 ne "") { IRC::command("/say ${TITLE_S}Sensors:${TITLE_E} $SPEW2") };
} else {
print "$SPEW\n";
if ($SPEW2) { print "${TITLE_S}Sensors:${TITLE_E} $SPEW2\n" };
}


return 1;
}

#--END OF SUB--#

if ($irssi) {
Irssi::command_bind('sys', 'display_sys_info');
Irssi::command_bind('syscolor', 'set_color');
Irssi::command_bind('gender', 'set_gender');
} elsif ($xchat) {
IRC::register("Sysinfo", "${VERSION}.1", "", "");
IRC::print ("Loading CyberGrunge's perlified \0034sysinfo\003 script");
IRC::print ("Usage: /sys");
IRC::print (" /syscolor (0|1)");
IRC::print (" /gender (0|1|m|f)");
IRC::add_command_handler("sys", "display_sys_info");
IRC::add_command_handler("syscolor","set_color") ;
IRC::add_command_handler("gender","set_gender") ;
} else {
display_sys_info();
}
