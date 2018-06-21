#!/bin/sh
# Installation:
#  1. minimem installation with root only 
#
# Using the installer script:
#  1. yum update
#  2. yum install git 
#  3. git clone https://github.com/xuminic/mkvbox.git
#  4. run 'centos.sh'
#
# History:
#

#############################################################################
# Configure
#############################################################################
CHN_IM=ibus             # fcitx/ibus
DESKTOP=mate            # mate/xfce/cinnamon/gnome

#############################################################################
# Installer with debugger
#############################################################################
CHROOT=
#CHROOT=./tmp

installer()
{
  echo INSTALLING $* | tee -a install.log
  if test "x$CHROOT" = x; then
    yum -y install $* | tee -a install.log
  else
    echo yum -y install $* | tee -a install.log
  fi
  if ! test "x$?" = "x0"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}

group_plant()
{
  echo INSTALLING "$@" | tee -a install.log
  if test "x$CHROOT" = x; then
    yum -y groupinstall "$@" | tee -a install.log
  else
    echo yum -y groupinstall "$@" | tee -a install.log
  fi
  if ! test "x$?" = "x0"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}

local_plant()
{
  echo INSTALLING "$@" | tee -a install.log
  if test "x$CHROOT" = x; then
    rpm -Uvh "$@" | tee -a install.log
  else
    echo rpm -Uvh "$@" | tee -a install.log
  fi
}

rpm_signature()
{
  echo IMPORT Signature "$@" | tee -a install.log
  if test "x$CHROOT" = x; then
    rpm --import "$@" | tee -a install.log
  else
    echo rpm --import "$@" | tee -a install.log
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
  installer --enablerepo=epel-testing  atril atril-caja

  group_plant "MATE Desktop"
  installer caja-share
}

install_desktop_xfce()
{
  group_plant "Xfce"
}

install_desktop_cinnamon()
{
  installer cinnamon lightdm
}

install_desktop_gnome()
{
  group_plant "Server with GUI"
}


install_vim()
{
  installer vim

  if test -e $CHROOT/usr/bin/vi; then
    echo "Removed the default 'vi'" | tee -a install.log
    rm $CHROOT/usr/bin/vi
  fi
  if test -e $CHROOT/usr/bin/vim; then
    echo "Linked the vi to 'vim'" | tee -a install.log
    ln -s $CHROOT/usr/bin/vim $CHROOT/usr/bin/vi
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
  if test "x$CHROOT" = x; then
    wget --content-disposition "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" | tee -a install.log
    tar xfj firefox-*.tar.bz2 -C /opt | tee -a install.log
    rm -f firefox-*.tar.bz2
    echo "Old Firefox will be renamed to /usr/bin/firefox-52" | tee -a install.log
    mv -f /usr/bin/firefox /usr/bin/firefox-52
    echo ln -s /opt/firefox/firefox /usr/bin/firefox | tee -a install.log
    ln -s /opt/firefox/firefox /usr/bin/firefox
  else
    echo wget --content-disposition "https://download.mozilla.org/?product=firefox-latest&os=linux64&lang=en-US" | tee -a install.log
    echo tar xfj firefox-*.tar.bz2 -C /opt | tee -a install.log
  fi
}

install_virtualbox()
{
  echo INSTALLING Virtualbox | tee -a install.log
  wget http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo | tee -a install.log
  echo "cp virtualbox.repo /etc/yum.repos.d" | tee -a install.log
  cp virtualbox.repo /etc/yum.repos.d
  #installer --enablerepo=epel dkms
  installer VirtualBox-5.2
  echo "usermod -a -G vboxusers `echo /home`" | tee -a install.log
  usermod -a -G vboxusers `echo /home` | tee -a install.log
}

install_guest_addition()
{
  echo INSTALLING Virtualbox Guest Addition | tee -a install.log
  #install GNU GCC Compiler, kernel module and Development Environment
  group_plant "Development Tools"
  installer kernel-headers

  if test "x$CHROOT" != "x"; then
    echo This is a simulation | tee -a install.log
    return
  fi

  # try CDROM firstly for best matching the virtualbox host
  mount /dev/sr0 /mnt
  if test "x$?" = "x0"; then
    echo cp -f /mnt/VBoxLinuxAdditions.run /root | tee -a install.log
    cp -f /mnt/VBoxLinuxAdditions.run /root
  fi
  umount /mnt

  if test -e /root/VBoxLinuxAdditions.run; then
    chmod 755 /root/VBoxLinuxAdditions.run
    /root/VBoxLinuxAdditions.run | tee -a install.log

    local DEFUSER=`echo /home`
    echo usermod -a -G sudo,vboxsf $DEFUSER | tee -a install.log
    usermod -a -G sudo,vboxsf $DEFUSER | tee -a install.log
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
      --vboxguest   install Virtualbox Guest Addition (insert iso first)
      --vboxhost    install Virtualbox machine

my_usage
  exit 0
}

#create a log file
touch install.log

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage_exit;;

    -d|--desktop) DESKTOP="$2"; shift;;

    -i|--ime) CHN_IM="$2"; shift;;

    --vboxguest) install_guest_addition; exit 0;;
    --vboxhost) install_virtualbox; exit 0;;

    -*) echo Unknown parameter [$@]; exit 1;;
    *) break;;
  esac
  shift
done

#install extra repos
installer epel-release

#install Nux Dextop
local_plant http://li.nux.ro/download/nux/dextop/el7/x86_64/nux-dextop-release-0-5.el7.nux.noarch.rpm

#install RPM Fusion
if test ! -e /etc/yum.repos.d/
local_plant https://download1.rpmfusion.org/free/el/rpmfusion-free-release-7.noarch.rpm
local_plant https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-7.noarch.rpm

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
if test "x$CHROOT" = x; then
  yum -y update | tee -a install.log
fi

#install ifconfig
installer net-tools
installer wget

#install lspci
installer pciutils

#install CIFS to support samba file system
installer cifs-utils

#install system enhancement tool
installer arj

#install vim
install_vim

#install the C/C++ tool chains
group_plant "Development Tools"

#install s-record for firmware binary process
installer srecord

#install ffmpeg and libgd
#installer libavformat-dev libswscale-dev libgd2-dev libx11-dev zlib1g-dev

#install python related. In default the python2 and python3 were all installed.
# matplotlib requires python-dev
#installer python-pip python-dev python-virtualenv python3-virtualenv
# install machine learn kit
#installer python2.7-scipy python3-scipy  python-sklearn python2.7-sklearn

# setting the bash
setup_bash

#############################################################################
# install the X11 desktop environment
#############################################################################
group_plant "X Window system"
#installer xorg-fonts-100dpi xorg-fonts-75dpi
case $DESKTOP in
  mate) install_desktop_mate ;;
  xfce) install_desktop_xfce ;;
  cinnamon) install_desktop_cinnamon ;;
  gnome) install_desktop_gnome ;;
  *) exit ;;
esac
systemctl set-default graphical.target | tee -a install.log
#systemctl isolate graphical.target


case $CHN_IM in
  ibus) #install the Chinese input method: IBus
    installer ibus ibus-qt ibus-libpinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    installer fcitx fcitx-anthy fcitx-cloudpinyin fcitx-configtool ;;
esac

if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
  installer wqy-microhei-fonts cjkuni-ukai-fonts cjkuni-uming-fonts 
  installer horai-ume-*-fonts ipa-*-fonts
fi

#install vim gui
installer vim-gtk

#install the GUI of git
installer qgit

#install other tools
installer meld 
#installer qbittorrent

#install the browsers
#installer firefox-esr 
#installer chromium
#install_firefox_latest
#installer google-chrome-stable

#install image viewers and editors
installer geeqie imagemagick
installer gimp
#installer inkscape

#install libre-office
installer libreoffice 

#install CADs
installer librecad
#installer freecad
#installer openscad
#installer blender

#install the Virtualbox or Guest Addition
#install_virtualbox
#install_guest_addition
#installer qemu-kvm qemu-kvm-common qemu-kvm-tools qemu-system-x86

#############################################################################
# Setup Extra repos
# ELRepo breaks X Window system so it must be postponed
#############################################################################
#install ELRepo
#rpm_signature https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
#local_plant http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm

#############################################################################
# Setup the useful scripts
#############################################################################

#############################################################################
# The last part would be adding the default user
#############################################################################

