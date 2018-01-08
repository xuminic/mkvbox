#!/bin/sh
#  1. Install with base utitlies
#  2. apt-get install build-essential module-assistant
#  3. m-a prepare
#  4. install virtualbox guest addition by 'VBoxLinuxAdditions.run'
#  5. copy VBoxLinuxAdditions.run to /root/GuestAddition-4
#  6. copy this file to /root
#
# History:

#############################################################################
# Configure
#############################################################################
ADDUSER=andy
CHN_IM=ibus             # fcitx/ibus
DESKTOP=lxde            # lxde/mate

#############################################################################
# Installer with debugger
#############################################################################
CHROOT=
#CHROOT=./tmp

if test "x$CHROOT" = x; then
  INSTALL="apt-get -y install"
  SUDO="sudo -u $ADDUSER"
else            # debug mode
  INSTALL="apt-get -s -y install"
  SUDO="echo sudo -u $ADDUSER"
fi

#############################################################################
# Install packages
#############################################################################
install_X11_server()
{
  $INSTALL xinit
  $INSTALL fonts-wqy-microhei fonts-wqy-zenhei
  #$INSTALL xorg-fonts-100dpi xorg-fonts-75dpi
}

install_desktop_lxde()
{
  $INSTALL lxde leafpad xarchiver

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
  $INSTALL mate-desktop-environment-extras lightdm

  if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
    gsettings set org.mate.pluma auto-detected-encodings \
      "['GB18030','GB2312','GBK','BIG5','UTF-8','CURRENT','ISO-8859-15']"
    gsettings set org.mate.pluma shown-in-menu-encodings "['GB18030', 'ISO-8859-15']"
  fi
}

install_vim()
{
  $INSTALL vim vim-gtk

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

  if test ! -d $CHROOT/home/$ADDUSER; then
    mkdir -p $CHROOT/home/$ADDUSER
  fi
  $SUDO cp -f $CHROOT/etc/skel/.vimrc $CHROOT/home/$ADDUSER
}

init_git_reference()
{
  if test -d $CHROOT/home/$ADDUSER; then
    cd $CHROOT/home/$ADDUSER
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
  usermod -a -G sudo,vboxsf $ADDUSER
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

#install GNU GCC Compiler and Development Environment
$INSTALL build-essential manpages-dev
install_vim

#install the git
$INSTALL git qgit

#install ffmpeg and libgd
$INSTALL libavformat-dev libgd2-dev libx11-dev zlib1g-dev

#install other tools
$INSTALL arj meld ghex

#install the browsers
$INSTALL firefox-esr chromium

case $CHN_IM in
  ibus) #install the Chinese input method: IBus
    $INSTALL ibus ibus-qt4 ibus-libpinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    $INSTALL fcitx fcitx-libpinyin fcitx-googlepinyin fcitx-config-common fcitx-mozc ;;
esac

if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
  $INSTALL fonts-arphic-ukai fonts-arphic-uming
  $INSTALL fonts-arphic-gkai00mp fonts-arphic-bkai00mp
  $INSTALL fonts-ipafont fonts-hanazono fonts-sawarabi-mincho
fi
  
#install image viewers and editors
$INSTALL geeqie gimp imagemagick
$INSTALL inkscape

#install libre-office
$INSTALL libreoffice 

#install CADs
$INSTALL librecad
$INSTALL freecad
$INSTALL openscad
$INSTALL blender

#install python related. In default the python2 and python3 were all installed.
# matplotlib requires python-dev
$INSTALL python-pip python-dev python-virtualenv python3-virtualenv
# install machine learn kit
$INSTALL python2.7-scipy python3-scipy  python-sklearn python2.7-sklearn

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
alias path='echo \$PATH'
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

if test ! -d $CHROOT/home/$ADDUSER/bin; then
  $SUDO mkdir -p $CHROOT/home/$ADDUSER/bin
fi
if test ! -d $CHROOT/home/$ADDUSER; then
  $SUDO mkdir -p $CHROOT/home/$ADDUSER
fi
$SUDO cp -f $CHROOT/etc/skel/.bashrc $CHROOT/home/$ADDUSER


#############################################################################
# The last part would be adding the default user
#############################################################################
echo Initial Git references
init_git_reference

echo ReInstall Virtualbox Guest Addition
if test "x$CHROOT" = x; then
  cd ~
  cd GuestAddition-*
  if test -e ./VBoxLinuxAdditions.run; then
    ./VBoxLinuxAdditions.run
  fi
fi

