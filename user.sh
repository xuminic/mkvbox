#!/bin/bash

if test ! -d $HOME/bin; then
  mkdir -p $HOME/bin
fi

# CENTOS/ARCHLINUX/DEBIAN: Chinese setting in pluma of MATE
if test -e /usr/bin/ibus || test -e /usr/bin/fcitx; then
  if test -e /usr/bin/pluma; then
    gsettings set org.mate.pluma auto-detected-encodings \
	"['GB18030','GB2312','GBK','BIG5','UTF-8','CURRENT','ISO-8859-15']"
    gsettings set org.mate.pluma shown-in-menu-encodings "['GB18030', 'ISO-8859-15']"
  fi
  if test -e /usr/bin/leafpad; then
    cat > $HOME/bin/leafpad << LEAFPAD
#!/bin/sh
/usr/bin/leafpad-gui --codeset=gbk \$*
LEAFPAD
    chmod 755 $HOME/bin/leafpad
    sudo mv /usr/bin/leafpad /usr/bin/leafpad-gui
    sudo cp $HOME/bin/leafpad /usr/bin
  fi
fi


# Initial my git reference
git config --global user.name "Andy Xuming"
git config --global user.email "xuming@users.sf.net"
git config --global core.editor vim
git config --global merge.tool vimdiff
git config --global credential.helper cache

#git remote set-url origin https://github.com/xuminic/ezthumb.git
#git remote add sf ssh://xuming@git.code.sf.net/p/ezthumb/code

# My projects
#git clone ssh://xuming@git.code.sf.net/p/ezthumb/code ezthumb
#git clone ssh://xuming@git.code.sf.net/p/ipblocklist/code ipblocklist
#git clone ssh://xuming@git.code.sf.net/p/libcsoup/code libcsoup
#git clone ssh://xuming@git.code.sf.net/p/mkmap/code mkmap
#git clone ssh://xuming@git.code.sf.net/p/rename/code rename
#git clone ssh://xuming@git.code.sf.net/p/snippetax/code snippetax


