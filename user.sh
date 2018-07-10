#!/bin/bash

if test ! -d $HOME/bin; then
  mkdir -p $HOME/bin
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



