#!/bin/sh
# Create the Virtualbox Image with the minimum installation of Debian:
#  1. Hostname is default 'debian' and Domain name is empty
#  2. Create a user account, for example, 'andy'. See DEFUSER below.
#  3. Partition the HDD to one partition only without SWAP volumn.
#  4. Only install the 'standard system utitlies'
#  5. Boot the Virtualbox Image and login as root
#  6. apt-get install git
#  7. echo "git clone https://github.com/xuminic/mkvbox.git" > installer.sh
#  8. chmod 755 installer.sh
#  9. In Virtualbox manager, choose 'Devices->Insert Guest Additions CD image'
# 9a. Debian 9 requires Guest Additions over 5.1.x so 5.2.4 has been tested.
# 10. mount /dev/sr0 /mnt
# 11. cp /mnt/VBoxLinuxAdditions.run ~
# 12. umount /mnt
# 13. Shutdown the Virtualbox Image and you may ZIP it for future using.
#
# Using the installer script:
#  1. Boot the Virtualbox Image and login as root
#  2. Insert Guest Additions CD image if wish to match the version.
#  2. run ./installer.sh to retrieve the laster version of the 'debian.sh'
#  3. Edit the 'Configure' section, and/or add/remove the packages you want.
#  4. run 'debian.sh'
#
# History:
#  20180108: commit into the github for easy accessing.
#

#############################################################################
# Configure
#############################################################################
DEFUSER=andy
CHN_IM=ibus             # fcitx/ibus
DESKTOP=lxde            # lxde/mate

#############################################################################
# Installer with debugger
#############################################################################
CHROOT=
#CHROOT=./tmp

if test "x$CHROOT" = x; then
  SUDO="sudo -u $DEFUSER"
else            # debug mode
  SUDO="echo sudo -u $DEFUSER"
fi

installer()
{
  echo INSTALLING $*
  if test "x$CHROOT" = x; then
    apt-get -y install $*
  else
    apt-get -s -y install $*
  fi
  if ! test "x$?" = "x0"; then
    echo Install failed!
    exit 1
  fi
}


#############################################################################
# Install packages
#############################################################################
install_X11_server()
{
  installer xinit
  installer fonts-wqy-microhei fonts-wqy-zenhei
  #installer xorg-fonts-100dpi xorg-fonts-75dpi
}

install_desktop_lxde()
{
  installer lxde leafpad xarchiver

  if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
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

  if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
    gsettings set org.mate.pluma auto-detected-encodings \
      "['GB18030','GB2312','GBK','BIG5','UTF-8','CURRENT','ISO-8859-15']"
    gsettings set org.mate.pluma shown-in-menu-encodings "['GB18030', 'ISO-8859-15']"
  fi
}

install_vim()
{
  installer vim vim-gtk

  if test -e $CHROOT/usr/bin/vi; then
    rm $CHROOT/usr/bin/vi
  fi
  if test -e $CHROOT/etc/alternatives/vim; then
    ln -s $CHROOT/etc/alternatives/vim $CHROOT/usr/bin/vi
  fi
  
  if test ! -d $CHROOT/etc/skel; then
    mkdir -p $CHROOT/etc/skel
  fi
  cat >  $CHROOT/etc/skel/.vimrc << VIMRC
runtime! vimrc_example.vim
set nobackup
set mouse=
VIMRC

  if test ! -d $CHROOT/home/$DEFUSER; then
    mkdir -p $CHROOT/home/$DEFUSER
  fi
  $SUDO cp -f $CHROOT/etc/skel/.vimrc $CHROOT/home/$DEFUSER
}

install_virtualbox_guest_addition()
{
  #install GNU GCC Compiler, kernel module and Development Environment
  installer build-essential manpages-dev
  installer linux-headers-$(uname -r)

  if test "x$CHROOT" = x; then
      # best match the virtualbox guest addition
      mount /dev/sr0 /mnt
      if test "x$?" = "x0"; then
        cp -f /mnt/VBoxLinuxAdditions.run /root
      fi
      umount /mnt
      /root/VBoxLinuxAdditions.run
  fi
}

init_git_reference()
{
  if test -d $CHROOT/home/$DEFUSER; then
    cd $CHROOT/home/$DEFUSER
  fi
  $SUDO git config --global user.name "Andy Xuming"
  $SUDO git config --global user.email "xuming@users.sf.net"
  $SUDO git config --global core.editor vim
  $SUDO git config --global merge.tool vimdiff
  $SUDO git config --global credential.helper cache
  
  #$SUDO git remote set-url origin https://github.com/xuminic/ezthumb.git
  #$SUDO git remote add sf ssh://xuming@git.code.sf.net/p/ezthumb/code
}


#update and upgrade to the newest releases
if test "x$CHROOT" = x; then
  apt-get -y update
  apt-get -y upgrade
  usermod -a -G sudo,vboxsf $DEFUSER
else
  apt-get -s -y update
  apt-get -s -y upgrade
fi

#install the X11 desktop environment
install_X11_server
case $DESKTOP in
  lxde) install_desktop_lxde;;
  mate) install_desktop_mate;;
esac

case $CHN_IM in
  ibus) #install the Chinese input method: IBus
    installer ibus ibus-qt4 ibus-libpinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    installer fcitx fcitx-libpinyin fcitx-googlepinyin fcitx-config-common fcitx-mozc ;;
esac

if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
  installer fonts-arphic-ukai fonts-arphic-uming
  installer fonts-arphic-gkai00mp fonts-arphic-bkai00mp
  installer fonts-ipafont fonts-hanazono fonts-sawarabi-mincho
fi

#install aptitude
installer aptitude

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
echo Updating the .bashrc file.
if test ! -d $CHROOT$HOME; then
  mkdir -p $CHROOT$HOME
fi
cat >> $CHROOT$HOME/.bashrc << BASHRC
# If not running interactively, don't do anything
[[ \$- != *i* ]] && return

PS1='\u:\w\\$ '

alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias grep='grep --color=auto'
alias l.='ls -d .* --color=auto'
alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias path='echo $PATH'
alias which='alias | /usr/bin/which --tty-only --read-alias --show-dot --show-tilde'
BASHRC

if test ! -d $CHROOT/etc/skel; then
  mkdir -p $CHROOT/etc/skel
fi
cp $CHROOT$HOME/.bashrc $CHROOT/etc/skel
echo "PATH=\$PATH:\$HOME/bin:." >> $CHROOT/etc/skel/.bashrc
echo "PATH=\$PATH:\$HOME/bin" >> $CHROOT$HOME/.bashrc

if test ! -d $CHROOT$HOME/bin; then
  mkdir -p $CHROOT$HOME/bin
fi

if test ! -d $CHROOT/home/$DEFUSER/bin; then
  $SUDO mkdir -p $CHROOT/home/$DEFUSER/bin
fi
if test ! -d $CHROOT/home/$DEFUSER; then
  $SUDO mkdir -p $CHROOT/home/$DEFUSER
fi
$SUDO cp -f $CHROOT/etc/skel/.bashrc $CHROOT/home/$DEFUSER


#############################################################################
# The last part would be adding the default user
#############################################################################
echo Initial Git references
init_git_reference

echo Install Virtualbox Guest Addition
install_virtualbox_guest_addition

