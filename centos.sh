#!/bin/bash
# Installation:
#  1. minimem installation with root only 
#
# Using the installer script:
#  1. yum update
#  2. yum install git 
#  3. git clone https://github.com/xuminic/mkvbox.git
#  4. run 'centos.sh'
#
# Notes:
#  * matplotlib requires python-dev
#  * gstreamer1-vaapi seems a trouble maker
#
# History:
#

#############################################################################
# Configure
#############################################################################
CFG_IME=ibus		# fcitx/ibus
CFG_DESKTOP=mate	# mate/xfce/cinnamon/gnome
CFG_VMCN=		# vbox/vbgst/kvm
CFG_WEB=		# firefox-quantum 

# ifconfig/lspci/samba/... always needed
CFG_CLI="net-tools wget pciutils cifs-utils arj git"
# firmware tools
#CFG_CLI="$CFG_CLI srecord"				
# ffmpeg & libgd
#CFG_CLI="$CFG_CLI libavformat-dev libswscale-dev libx11-dev zlib1g-dev"
#CFG_CLI="$CFG_CLI libgd2-dev"
# python basic
#CFG_CLI="$CFG_CLI python-pip python-dev python-virtualenv python3-virtualenv"
# python machine learn
#CFG_CLI="$CFG_CLI python2.7-scipy python3-scipy python-sklearn python2.7-sklearn"

# general tools
CFG_GUI="vim-gtk qgit meld qbittorrent"
# old style X fonts
#CFG_GUI="$CFG_GUI xorg-fonts-100dpi xorg-fonts-75dpi"
# chinese fonts and japanese fonts
#CFG_GUI="$CFG_GUI wqy-microhei-fonts cjkuni-ukai-fonts cjkuni-uming-fonts"
#CFG_GUI="$CFG_GUI horai-ume-*-fonts ipa-*-fonts"
# browers
#CFG_GUI="$CFG_GUI firefox chromium google-chrome-stable"
# image and picture tools
#CFG_GUI="$CFG_GUI geeqie imagemagick gimp inkscape"
# office suite
#CFG_GUI="$CFG_GUI libreoffice"	
# CAD suites
#CFG_GUI="$CFG_GUI librecad freecad openscad blender"
# video player
#CFG_GUI="$CFG_GUI vlc smplayer"
# GStreamer codec collection
#CFG_GUI="$CFG_GUI gstreamer gstreamer-ffmpeg gstreamer-plugins-base gstreamer-plugins-good \
#	  gstreamer-plugins-bad gstreamer-plugins-bad-free gstreamer-plugins-bad-nonfree \
#	  gstreamer-plugins-ugly gstreamer-plugins-base-tools \
#	  gstreamer1 gstreamer1-libav gstreamer1-plugins-base streamer1-plugins-base-tools \
#	  gstreamer1-plugins-good gstreamer1-plugins-bad-free gstreamer1-plugins-bad-freeworld \
#	  gstreamer1-plugins-ugly gstreamer1-plugins-ugly-free


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
  logdo yum -y install "$@"
  if ! test "x$?" = "x0"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}

group_install()
{
  echo -e \\nINSTALLING "$@" | tee -a install.log
  logdo yum -y groupinstall \"$@\"
  if ! test "x$?" = "x0"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}


#############################################################################
# Install packages
#############################################################################
install_desktop_mate()
{
  # Weird break in "MATE Desktop" by EPEL
  # some one removed libwebkitgtk so it broken the atril
  # currently the atril can be recovered from the test repo
  # https://bugzilla.redhat.com/show_bug.cgi?id=1589486
  
  #installer --enablerepo=epel-testing  atril atril-caja
  logdo yum -y --enablerepo=epel-testing install atril atril-caja

  group_install "MATE Desktop"
  installer caja-share
}

install_desktop_xfce()
{
  group_install "Xfce"
}

install_desktop_cinnamon()
{
  installer cinnamon lightdm
}

install_desktop_gnome()
{
  group_install "Server with GUI"
}


install_vim()
{
  installer vim

  if test -e $CHROOT/usr/bin/vi; then
    logdo rm $CHROOT/usr/bin/vi
  fi
  if test -e $CHROOT/usr/bin/vim; then
    logdo ln -s $CHROOT/usr/bin/vim $CHROOT/usr/bin/vi
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
  if test ! -e firefox-*.tar.bz2; then
    echo ERROR: firefox not downloaded! | tee -a install.log
    exit
  fi

  logdo tar xfj firefox-*.tar.bz2 -C /opt 
  logdo rm -f firefox-*.tar.bz

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
  local DEFUSER=`/bin/ls /home`
  
  group_install "Development Tools"
  installer kernel-devel dkms wget

  echo INSTALLING Virtualbox | tee -a install.log
  logdo wget \"http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo\"
  if test -e virtualbox.repo; then
    logdo cp -f virtualbox.repo /etc/yum.repos.d
  fi

  installer VirtualBox-5.2
  if test "$DEFUSER" != ""; then
    logdo usermod -a -G vboxusers $DEFUSER
  fi
}

install_guest_addition()
{
  # FIXED: Most guest addition has problem with CentOS7.5/7.6. Only 5.2.x test builds work.
  # https://forums.virtualbox.org/viewtopic.php?f=3&t=87529
  local DEFUSER=`/bin/ls /home`

  #install GNU GCC Compiler, kernel module and Development Environment
  group_install "Development Tools"
  installer kernel-devel dkms

  # try CDROM firstly for best matching the virtualbox host
  logdo mount /dev/sr0 /mnt
  if test -e /mnt/VBoxLinuxAdditions.run; then
    logdo cp -f /mnt/VBoxLinuxAdditions.run /root
  fi
  logdo umount /mnt

  # Fix the error while Building the OpenGL support module in CentOS 6
#  cd /usr/src/kernels/$(uname -r)/include/drm 
#  if test ! -e drm.h; then
#    ln -s /usr/include/drm/drm.h drm.h  
#    ln -s /usr/include/drm/drm_sarea.h drm_sarea.h  
#    ln -s /usr/include/drm/drm_mode.h drm_mode.h  
#    ln -s /usr/include/drm/drm_fourcc.h drm_fourcc.h
#  fi
#  ls -l /usr/src/kernels/$(uname -r)/include/drm/drm.h | tee -a install.log

  if test -e /root/VBoxLinuxAdditions.run; then
    echo INSTALLING Virtualbox Guest Addition | tee -a install.log
    echo WARNING: RHEL/CENTOS 7.5+ require Guest Addition 5.2.x test build | tee -a install.log
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
usage_exit()
{
  cat << my_usage
$0 [OPTION]
OPTION:
  -d, --desktop     choose desktop [mate/xfce/cinnamon/gnome]
  -i, --ime         choose IME input method [ibus/fcitx]
  -v, --vm          choose Virtual Machine type [none/vbox/vbgst/kvm]
      --vboxguest   quick install Virtualbox Guest Addition (insert iso first)
      --vboxhost    quick install Virtualbox machine
      --firefox     install the latest firefox quantum

my_usage
  exit 0
}

#create a log file
date > install.log

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage_exit;;
    -d|--desktop) CFG_DESKTOP="$2"; shift;;
    -i|--ime) CFG_IME="$2"; shift;;
    -v|--vm) CFG_VMCN="$2"; shift;;
    --vboxguest) install_guest_addition; exit 0;;
    --vboxhost) install_virtualbox; exit 0;;
    --firefox) install_firefox_latest; exit 0;;

    -*) echo Unknown parameter [$@]; exit 1;;
    *) break;;
  esac
  shift
done

#install extra repos
installer epel-release

#install Nux Dextop
logdo rpm -Uvh http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

#install RPM Fusion
logdo rpm -Uvh https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
logdo rpm -Uvh https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm

#install google repos
cat >  $CHROOT/etc/yum.repos.d/google.repo << GGLREPO
[google]
name=Google - \$basearch
baseurl=http://dl.google.com/linux/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub

[google-chrome]
name=google-chrome
baseurl=http://dl.google.com/linux/chrome/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub

[google-earth]
name=google-earth
baseurl=http://dl.google.com/linux/earth/rpm/stable/\$basearch
enabled=1
gpgcheck=1
gpgkey=https://dl-ssl.google.com/linux/linux_signing_key.pub

GGLREPO


#update and upgrade to the newest releases
logdo yum -y update

#install the command line applications
if test "$CFG_CLI" != ""; then
  installer $CFG_CLI
fi

#install vim
install_vim

#install the C/C++ tool chains
group_install "Development Tools"

# setting the bash
setup_bash

#############################################################################
# install the X11 desktop environment
#############################################################################
group_install "X Window system"
case $CFG_DESKTOP in
  mate) install_desktop_mate ;;
  xfce) install_desktop_xfce ;;
  cinnamon) install_desktop_cinnamon ;;
  gnome) install_desktop_gnome ;;
  *) exit ;;
esac
logdo systemctl set-default graphical.target
#systemctl isolate graphical.target

case $CFG_IME in
  ibus) #install the Chinese input method: IBus
    installer ibus ibus-qt ibus-libpinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    installer fcitx fcitx-anthy fcitx-cloudpinyin fcitx-configtool ;;
esac

#install the Virtualbox or Guest Addition
case $CFG_VMCN in
  vbox) install_virtualbox ;;
  vbgst) install_guest_addition ;;
  kvm) installer qemu-kvm qemu-kvm-common qemu-kvm-tools qemu-system-x86
esac

# install desktop application
if test "$CFG_GUI" != ""; then
  installer $CFG_GUI
fi

#install the additional browsers
if test "$CFG_WEB" = "firefox-quantum"; then
  install_firefox_latest
elif test "$CFG_WEB" != ""; then
  installer $CFG_WEB
fi

#############################################################################
# Setup Extra repos
# ELRepo breaks X Window system so it must be postponed
#############################################################################
#install ELRepo
#logdo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
#logdo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

#############################################################################
# Setup the useful scripts
#############################################################################

