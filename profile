#!/bin/bash

if test ! -d $HOME/bin; then
  mkdir -p $HOME/bin
fi

# setting to support Chinese in pluma
if test -e /usr/bin/ibus || test -e /usr/bin/fcitx; then
  if test -e /usr/bin/pluma; then
    echo "PLUMA: support Chinese display"
    gsettings get org.mate.pluma auto-detected-encodings | grep GB18030 > /dev/null
    if test "x$?" = "x0"; then
      echo "PLUMA: GB18030 found in schema"
    else
      gsettings set org.mate.pluma auto-detected-encodings \
         "['GB18030','GB2312','GBK','BIG5','UTF-8','CURRENT','ISO-8859-15']"
      gsettings set org.mate.pluma shown-in-menu-encodings "['GB18030', 'ISO-8859-15']"
    fi
  fi

  # gtk3 theme might cause IME background issue.
  # https://github.com/ibus/ibus/issues/1871
  if test -d ~/.config/gtk-3.0; then
    echo "IBUS: fine tune the background color"
    grep "gtk-secondary-caret-color" ~/.config/gtk-3.0/gtk.css > /dev/null
    if test "x$?" = "x0"; then
      echo "IBUS: Found gtk-secondary-caret-color in ~/.config/gtk-3.0/gtk.css"
    else
      echo '* { -gtk-secondary-caret-color: #dbdee6; }' >> ~/.config/gtk-3.0/gtk.css
      echo "IBUS: Please reload IBUS"
    fi
  fi
fi

# set pidgin to auto-start
if test -e /usr/share/applications/pidgin.desktop; then
  if test ! -d $HOME/.config/autostart; then
    mkdir $HOME/.config/autostart
  fi
  if test ! -e $HOME/.config/autostart/pidgin.desktop; then
    echo PIDGIN: auto start
    cp /usr/share/applications/pidgin.desktop $HOME/.config/autostart
  fi
fi

# Initial my git references
if test -x /usr/bin/git; then
  echo GIT: Initial my references
  git config -l | grep xuming > /dev/null
  if test "x$?" = "x0"; then
    echo GIT: references been set
  else
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
  fi
fi


