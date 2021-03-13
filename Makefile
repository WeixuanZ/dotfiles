DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH)

link:
	for file in $$(git ls-files | egrep '^\/?(?:\w+\/)*(\.\w+)'); do \
		ln -vsf $(DOTFILES_DIR)/$$file $(HOME)/.$${file#*.}; done

packages: brew-packages python-packages

brew:
	is-executable brew || sh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

quicklook_lib_dir = $(HOME)/Library/QuickLook
brew-packages: brew
	brew bundle --file $(DOTFILES_DIR)/install/Brewfile
	[ -d "$(quicklook_lib_dir)" ] && xattr -d -r com.apple.quarantine $(quicklook_lib_dir) || echo "QuickLook folder not found"

python-packages: brew
	is-brew-package python || brew install python
	pip3 install -r $(DOTFILES_DIR)/install/requirements.txt

zsh_plugin_dir = $(HOME)/.oh-my-zsh/custom/plugins
zsh: brew
	is-brew-package zsh || brew install zsh
	ZSH= sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	mkdir -vp $(zsh_plugin_dir)
	git clone https://github.com/nyquase/vi-mode $(zsh_plugin_dir)/vi-mode
	git clone https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git $(zsh_plugin_dir)/autoswitch_virtualenv
	git clone https://github.com/zsh-users/zsh-autosuggestions $(zsh_plugin_dir)/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $(zsh_plugin_dir)/zsh-syntax-highlighting
	tic $(DOTFILES_DIR)/zsh/terminfo
	ln -vsf $(DOTFILES_DIR)/zsh/.zshrc $(HOME)/.zshrc

vim: brew
	is-brew-package vim || brew install vim
	ln -vsf $(DOTFILES_DIR)/vim/.vimrc $(HOME)/.vimrc
	mkdir -vp $(HOME)/.vim/undo
	curl -fLso $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +qall

vim_ycm_dir = $(HOME)/.vim/plugged/youcompleteme
vim-ycm: vim brew-packages
	(cd $(vim_ycm_dir) && git submodule update --init --recursive)
	python3 $(vim_ycm_dir)/install.py --all

haskell:
	is-executable ghc || curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
	is-executable stack || curl -sSL https://get.haskellstack.org/ | sh
