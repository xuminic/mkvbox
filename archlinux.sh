#!/bin/sh
# Initial the Virtualbox:
#  1. fdisk /dev/sda
#  2. mkfs.ext4 /dev/sda1
#  3. mount /dev/sda1 /mnt
#  4. vi /etc/pacman.d/mirrorlist
#  5. pacstrap /mnt base
#  6. genfstab -U /mnt >> /mnt/etc/fstab
#  7. arch-chroot /mnt
#  8. ln -sf /usr/share/zoneinfo/Australia/Sydney /etc/localtime
#  9. hwclock --systohc
# 10. vi /etc/locale.gen
#     en_US.UTF8 UTF-8
#     zh_CN.UTF8 UTF-8
#     zh_CN.GBK GBK
#     zh_CN.GB2312 GB2312
#     zh_CN.GB18030 GB18030
# 11. locale-gen
# 12. vi /etc/locale.conf
#     LANG=en_US.UTF-8
# 13. echo myarchlinux > /etc/hostname
# 14. echo "127.0.1.1	myarchlinux.localdomain	myarchlinux" >> /etc/hosts
# 15. cp /etc/netctl/examples/ethernet-dhcp /etc/netctl/
# 16. vi /etc/netctl/ethernet-dhcp
#     Interface=enp0s3
# 17. netctl enable ethernet-dhcp
# 18. passwd root
# 19. pacman -S grub
# 20. grub-install --target=i386-pc /dev/sda
# 21. grub-mkconfig -o /boot/grub/grub.cfg
#
# 22. pacman -S sudo
# 23. "vi /etc/sudoer" or visudo   --> "%wheel    ALL=(ALL) ALL"
#
# 24. pacman -S git
# 25. echo "git clone https://github.com/xuminic/mkvbox.git" > installer.sh
# 26. chmod 755 installer.sh
#
# 27. In Virtualbox manager, Insert Guest Additions 5.1.x than lower version
# 29. mount /dev/sr0 /mnt
# 30. cp /mnt/VBoxLinuxAdditions.run ~
# 31. umount /mnt
# 32. Shutdown the Virtualbox Image and you may ZIP it for future using.
#
# History:
#  20180111:
#    removed virtualbox-guest-modules-arch virtualbox-guest-utils because it's
#    no better that the orale release.
#  20170605: the first workable script in Archlinux

#############################################################################
# Configure
#############################################################################
ADDUSER=
ADDPWD=
CHN_IM=ibus		# fcitx/ibus
DESKTOP=lxde		# lxde/mate

#############################################################################
# Installer with debugger
#############################################################################
CHROOT=
#CHROOT=./tmp

installer()
{
  echo INSTALLING $* | tee -a install.log
  echo pacman -S --noconfirm --needed $* | tee -a install.log
  if test "x$CHROOT" = x; then
    pacman -S --noconfirm --needed $* | tee -a install.log
  fi
  if test "x$?" = "x1"; then
    echo Install failed! | tee -a install.log
    exit 1
  fi
}

add_users()
{
  echo useradd -m -G audio,lp,optical,storage,video,wheel,vboxsf -s /bin/bash "$1" | tee -a install.log
  if test "x$CHROOT" = x; then
    useradd -m -G audio,lp,optical,storage,video,wheel,vboxsf -s /bin/bash "$1" | tee -a install.log
    echo "$1":"$2" | chpasswd
    sudo -u "$1" mkdir "/home/$1/bin"
  else		# debug mode
    echo "$1":"$2"  | tee -a install.log
    echo sudo -u "$1" mkdir "/home/$1/bin" | tee -a install.log
  fi
}

#############################################################################
# Install packages
#############################################################################
install_X11_server()
{
  installer xorg-server xorg-xinit mesa
  installer ttf-dejavu ttf-bitstream-vera 
  installer wqy-zenhei wqy-bitmapfont wqy-microhei wqy-microhei-lite
  #installer otf-ipafont ttf-hanazono  ttf-sazanami
  #installer ttf-baekmuk
  #installer xorg-fonts-100dpi xorg-fonts-75dpi
}

install_desktop_lxde()
{
  installer lxde leafpad xarchiver
  if test ! -d $CHROOT/etc/skel; then
    mkdir -p $CHROOT/etc/skel
  fi
  echo "exec startlxde" > $CHROOT/etc/skel/.xinitrc

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
  installer mate mate-extra 
  if test ! -d $CHROOT/etc/skel; then
    mkdir -p $CHROOT/etc/skel
  fi
  echo "exec mate-session" > $CHROOT/etc/skel/.xinitrc
}

install_vim()
{
  installer vim gvim vim-spell-en
  if test -e $CHROOT/usr/bin/vi; then
    echo Removed the default vi | tee -a install.log
    rm $CHROOT/usr/bin/vi
  fi
  if test -e $CHROOT/usr/bin/vim; then
    echo Linked vi to vim | tee -a install.log
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

install_guest_addition()
{
  echo Install Virtualbox Guest Addition | tee -a install.log
  if test "x$CHROOT" = x; then
    installer linux-headers
    # best match the virtualbox guest addition
    mount /dev/sr0 /mnt
    if test "x$?" = "x0"; then
      echo cp -f /mnt/VBoxLinuxAdditions.run /root  | tee -a install.log
      cp -f /mnt/VBoxLinuxAdditions.run /root
    fi
    umount /mnt
    /root/VBoxLinuxAdditions.run | tee -a install.log

    # create the mount point of shared folder
    echo mkdir /media/sf_Shared  | tee -a install.log
    mkdir /media
    mkdir /media/sf_Shared
    echo Added \"Shared /media/sf_Shared vboxsf ...\" to /etc/fstab | tee -a install.log
    echo "Shared /media/sf_Shared vboxsf uid=0,gid=109,rw,dmode=755,fmode=644 0 0" >> /etc/fstab

    local DEFUSER=`echo /home`
    echo usermod -a -G sudo,vboxsf $DEFUSER | tee -a install.log
    usermod -a -G sudo,vboxsf $DEFUSER | tee -a install.log
  fi
}



#############################################################################
# Install starting
#############################################################################
#create a log file
touch install.log

#update and upgrade to the newest releases
installer -yu
installer -c

#install the archive tools
installer p7zip arj zip unzip cpio

#install vim and replace the elvis
install_vim

#install the X11 desktop environment
install_X11_server
case $DESKTOP in
  lxde) install_desktop_lxde;;
  mate) install_desktop_mate;;
esac

case $CHN_IM in
  ibus) #install the Chinese input method: IBus
    installer ibus ibus-qt ibus-libpinyin ibus-googlepinyin ibus-anthy ;;
  fcitx) #install the Chinese input method: Fcitx
    installer fcitx-im fcitx-libpinyin fcitx-googlepinyin fcitx-configtool fcitx-mozc ;;
esac 

#install extra Chinese/Japanese fonts
if test "x$CHN_IM" = xibus || test "x$CHN_IM" = xfcitx; then
  installer ttf-arphic-ukai ttf-arphic-uming opendesktop-fonts
  installer adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts
  installer adobe-source-han-sans-tw-fonts adobe-source-han-serif-tw-fonts
  installer adobe-source-han-sans-jp-fonts adobe-source-han-serif-jp-fonts
  installer adobe-source-han-sans-kr-fonts adobe-source-han-serif-kr-fonts
fi

#install web browser
installer seamonkey

#install the development package
installer base-devel 
installer meld 
installer gdb

#install the git GUI
installer qgit

#install the Internet tools
installer wget
installer openssh

#install Libre Office
installer libreoffice-fresh

#install the document viewer
installer evince

#install CAD softwares
installer librecad
installer freecad
installer openscad
installer blender

#install image viewer and editor
installer geeqie
installer gimp 
installer inkscape

#install ffmpeg and libgd
installer ffmpeg gd

#install SDL and freeimage
installer sdl2 freeimage lsb_release

#install python related. In default the python2 and python3 were all installed.
installer python-pip python2-pip python-virtualenv python2-virtualenv
# install machine learn kit
installer python-scipy python2-scipy python-scikit-learn python2-scikit-learn
installer python-matplotlib python2-matplotlib
pip install tensorflow

#############################################################################
# Setup the useful scripts
#############################################################################
# setting the bash
echo Updating the $CHROOT/etc/skel/.bashrc file. | tee -a install.log
if test ! -d $CHROOT/etc/skel; then
  mkdir -p $CHROOT/etc/skel
fi
cat > $CHROOT/etc/skel/.bashrc << BASHRC
#
# ~/.bashrc
#

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

#auto start X desktop as the default user so no xDM needed
echo Auto-start the X desktop | tee -a install.log
cat > $CHROOT/etc/skel/.bash_profile << AUTOX11
if [ -z "\$DISPLAY" ] && [ -n "\$XDG_VTNR" ] && [ "\$XDG_VTNR" -eq 1 ]; then
	exec startx
fi
AUTOX11

# set up time and date
echo Initial Network Time Control | tee -a install.log
timedatectl set-ntp true 

echo Enable the coredump in sysctl | tee -a install.log
sysctl -w kernel.core_pattern="core"

#############################################################################
# The last part would be adding the default user
#############################################################################
if test "x$ADDUSER" != "x"; then
  echo Adding the defualt user [$ADDUSER].
  add_users $ADDUSER $ADDPWD

  echo Autologin the first console as the default user [$ADDUSER].
  mkdir -p "$CHROOT/etc/systemd/system/getty@tty1.service.d"
  cat > "$CHROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf" << AUTOLOGIN
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $ADDUSER --noclear %I \$TERM
AUTOLOGIN
fi

# Install the Guest Addition so the vboxsf group will be available
install_guest_addition

