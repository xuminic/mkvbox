#!/bin/bash
# Create the Virtualbox Image with the minimum installation of Debian:
#  1. Only install the 'standard system utitlies'
#
# Using the installer script:
#  1. Insert Guest Additions CD image if wish to match the version.
#  2. apt-get install git
#  3. git clone https://github.com/xuminic/mkvbox.git
#  4. run 'debian.sh'
#
# History:
#  20180108: commit into the github for easy accessing.
#

#############################################################################
# Configure
#############################################################################
CFG_IME=ibus            # fcitx/ibus
CFG_DESKTOP=mate        # lxde/mate
CFG_VMCN=               # vbox/vbgst/kvm
CFG_WEB=                # firefox-quantum

# ifconfig/lspci/samba/... always needed
CFG_CLI="net-tools wget pciutils cifs-utils arj git"

# general tools
CFG_GUI="vim-gtk qgit meld qbittorrent"
# old style X fonts
#CFG_GUI="$CFG_GUI xorg-fonts-100dpi xorg-fonts-75dpi"
# chinese fonts and japanese fonts
#CFG_GUI="$CFG_GUI fonts-wqy-microhei fonts-wqy-zenhei"

#############################################################################
# Installer with debugger
#############################################################################
CHROOT=
#CHROOT=./tmp

logdo()
{
  echo $@ | tee -a install.log
  if test "x$CHROOT" = x; then
    eval $@ 2>&1 | tee -a install.log
  fi
}


installer()
{
  echo -e \\nINSTALLING $* | tee -a install.log
  echo apt-get -y install $* | tee -a install.log
  if test "x$CHROOT" = x; then
    apt-get -y install $* 2>&1 | tee -a install.log
  else
    apt-get -s -y install $* 2>&1 | tee -a install.log
  fi
  if ! test "x$?" = "x0"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}


#############################################################################
# Install packages
#############################################################################
install_desktop_lxde()
{
  installer lxde leafpad xarchiver

  if test "x$CFG_IME" = xibus || test "x$CFG_IME" = xfcitx; then
    if test -e $CHROOT/usr/bin/leafpad; then
      mv $CHROOT/usr/bin/leafpad $CHROOT/usr/bin/leafpad-gui
    fi

    if test ! -d $CHROOT/usr/bin; then
      mkdir -p $CHROOT/usr/bin
    fi
    cat > $CHROOT/usr/bin/leafpad << LEAFPAD
#!/bin/sh
/usr/bin/leafpad-gui --codeset=gbk \$*
LEAFPAD
    chmod 755 $CHROOT/usr/bin/leafpad
 fi
}

install_desktop_mate()
{
  installer mate-desktop-environment-extras lightdm

  if test "x$CFG_IME" = xibus || test "x$CFG_IME" = xfcitx; then
    gsettings set org.mate.pluma auto-detected-encodings \
      "['GB18030','GB2312','GBK','BIG5','UTF-8','CURRENT','ISO-8859-15']"
    gsettings set org.mate.pluma shown-in-menu-encodings "['GB18030', 'ISO-8859-15']"
  fi
}

install_vim()
{
  installer vim

  if test -e $CHROOT/usr/bin/vi; then
    logdo rm $CHROOT/usr/bin/vi
  fi
  if test -e $CHROOT/etc/alternatives/vim; then
    logdo ln -s $CHROOT/etc/alternatives/vim $CHROOT/usr/bin/vi
  fi
  
  if test ! -d $CHROOT/etc/skel; then
    mkdir -p $CHROOT/etc/skel
  fi
  cat >  $CHROOT/etc/skel/.vimrc << VIMRC
runtime! vimrc_example.vim
set nobackup
set noundofile
set mouse=
VIMRC
}


install_firefox_latest()
{
  logdo wget --content-disposition \"https://download.mozilla.org/?product=firefox-latest\&os=linux64\&lang=en-US\"

  local FFOX=firefox-*
  if test ! -e $FFOX; then
    echo ERROR: firefox not downloaded! | tee -a install.log
    exit
  fi

  logdo tar xfj $FFOX -C /opt 
  logdo rm -f $FFOX

  if test -L /usr/bin/firefox; then	# firefox has already been linked out
    echo Firefox updated. | tee -a install.log
  elif test -e /usr/bin/firefox; then
    logdo mv -f /usr/bin/firefox /usr/bin/firefox-52
    logdo ln -s /opt/firefox/firefox /usr/bin/firefox
  else
    cat >  $CHROOT/usr/share/applications/firefox.desktop << FIREFOX
[Desktop Entry]
Version=1.0
Name=Firefox Quantum Web Browser
Exec=/opt/firefox/firefox %u
Exec=/opt/firefox/firefox -new-window
Exec=/opt/firefox/firefox -private-window
Icon=firefox
Terminal=false
Type=Application
MimeType=text/html;text/xml;application/xhtml+xml;application/vnd.mozilla.xul+xml;text/mml;x-scheme-handler/http;x-scheme-handler/https;
StartupNotify=true
Categories=Network;WebBrowser;
X-Desktop-File-Install-Version=0.23
FIREFOX
  fi
}


install_virtualbox()
{
  echo -e \\nINSTALLING Virtualbox | tee -a install.log
}

install_guest_addition()
{
  local DEFUSER=`/bin/ls /home`

  #install GNU GCC Compiler, kernel module and Development Environment
  installer build-essential manpages-dev linux-headers-$(uname -r)

  # try CDROM firstly for best matching the virtualbox host
  logdo mount /dev/sr0 /mnt
  if test -e /mnt/VBoxLinuxAdditions.run; then
    logdo cp -f /mnt/VBoxLinuxAdditions.run /root
  fi
  logdo umount /mnt

  if test -e /root/VBoxLinuxAdditions.run; then
    echo -e \\nINSTALLING Virtualbox Guest Addition | tee -a install.log
    logdo chmod 755 /root/VBoxLinuxAdditions.run
    logdo /root/VBoxLinuxAdditions.run

    if test "x$?" = "x0" -a "x$DEFUSER" != "x"; then
      logdo usermod -a -G vboxsf $DEFUSER
    fi
  fi
}

setup_bash()
{
  echo Updating the $CHROOT/etc/skel/.bashrc file. | tee -a install.log
  if test ! -d $CHROOT/etc/skel; then
    mkdir -p $CHROOT/etc/skel
  fi
  cat >> $CHROOT/etc/skel/.bashrc << BASHRC
# If not running interactively, don't do anything
[[ \$- != *i* ]] && return

PS1='\u:\w\\$ '

alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias path='echo \$PATH'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

ulimit -c unlimited

PATH="\$PATH:\$HOME/bin:." 

BASHRC
}

#############################################################################
# Install starting
#############################################################################
#create a log file
touch install.log

#update and upgrade to the newest releases
if test "x$CHROOT" = x; then
  apt-get -y update | tee -a install.log
  apt-get -y upgrade | tee -a install.log
else
  apt-get -s -y update | tee -a install.log
  apt-get -s -y upgrade | tee -a install.log
fi

#install the X11 desktop environment
installer xinit
case $CFG_DESKTOP in
  lxde) install_desktop_lxde;;
  mate) install_desktop_mate;;
esac

case $CFG_IME in
  ibus) #install the Chinese input method: IBus
    installer ibus ibus-qt4 ibus-libpinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    installer fcitx fcitx-libpinyin fcitx-googlepinyin fcitx-config-common fcitx-mozc ;;
esac

if test "x$CFG_IME" = xibus || test "x$CFG_IME" = xfcitx; then
  installer fonts-arphic-ukai fonts-arphic-uming
  installer fonts-arphic-gkai00mp fonts-arphic-bkai00mp
  installer fonts-ipafont fonts-hanazono fonts-sawarabi-mincho
fi

#install aptitude
installer aptitude

#install ifconfig
installer net-tools

#install CIFS to support samba file system
installer cifs-utils

#install vim
install_vim

#install the GUI of git
installer qgit

#install the autoconfig tools
installer autoconf
installer libtool

#install s-record for firmware binary process
installer srecord

#install ffmpeg and libgd
installer libavformat-dev libswscale-dev libgd2-dev libx11-dev zlib1g-dev

#install other tools
installer arj meld ghex
installer qbittorrent

#install the browsers
installer firefox-esr 
installer chromium

#install image viewers and editors
installer geeqie imagemagick
installer gimp
installer inkscape

#install libre-office
installer libreoffice 

#install CADs
installer librecad
installer freecad
installer openscad
installer blender

#install python related. In default the python2 and python3 were all installed.
# matplotlib requires python-dev
installer python-pip python-dev python-virtualenv python3-virtualenv
# install machine learn kit
installer python2.7-scipy python3-scipy  python-sklearn python2.7-sklearn

#############################################################################
# Setup the useful scripts
#############################################################################
# setting the bash
echo Updating the $CHROOT/etc/skel/.bashrc file. | tee -a install.log
if test ! -d $CHROOT/etc/skel; then
  mkdir -p $CHROOT/etc/skel
fi
cat >> $CHROOT/etc/skel/.bashrc << BASHRC
# If not running interactively, don't do anything
[[ \$- != *i* ]] && return

PS1='\u:\w\\$ '

alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias path='echo \$PATH'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'

ulimit -c unlimited

PATH=\$PATH:\$HOME/bin:.

BASHRC


#############################################################################
# The last part would be adding the default user
#############################################################################
echo Install Virtualbox Guest Addition
install_virtualbox_guest_addition

