IRSSI is an advanced console irc client program that runs on linux and windows

Documentation @ http://www.irssi.org/documentation/manual

Github @ https://github.com/irssi/irssi

Wikipedia @ http://en.wikipedia.org/wiki/Irssi

Irssi chat support @ /server -ssl irc.freenode.net 7070 
                       /join #irssi


WirelessPT irc support @ http://wirelesspt.net/wiki/IRC

Please note that some of the scripts require that you install aditional perl packages
Read the error log in the status window for details about any missing pakages that
or distro may requeire to be able to use the scripts.

Irssi should be at least version 0.8.17 and compliled with perl proxy socks5 ssl

Git location: https://github.com/wirelesspt.net/unreal.git

Wiki documentation: http://wirelesspt.net/wiki/irc

Instalation as follows. If you do not have irssi you must install it
 
# Gentoo linux and gentoo based operating systems: 
 echo net-irc/irssi perl proxy -selinux socks5 ssl >> /etc/portage/package.keywords
 emerge irssi net-irc/irssi-otr

# Debian and crap based on debian linux such as ubuntu: 
 apt-get install irssi irssi-plugin-otr

# Arch linux
 sudo pacman -S irssi
 wget https://aur.archlinux.org/packages/ir/irssi-otr/irssi-otr.tar.gz
 tar xf irssi-otr.tar.gz
 cd irssi-otr
 makepkg -si
 echo load otr >> ~/.irssi/startup

# Micro$oft windows
 Install Pederasty
 https://support.microsoft.com/en-us/contactus

# Download the archive: 
 git clone https://github.com/wirelesspt/irssi.git

# Copy the contents to yout .irssi user directory which is usually at ~/.irssi: 
 $ cp -a irssi/* ~/.irssi/

Start irssi:
$ irssi 

READ the SETUP file included in this archive

