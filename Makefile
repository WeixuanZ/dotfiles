DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH) # some helper shell scripts
.PHONY: link brew haskell help

link: ## Link all the dot files tracked by git into HOME
	@for file in $$(git ls-files | egrep '^\/?(?:\w+\/)*(\.\w+)'); do \
		filename=.$${file#*.}; \
		if [ -f "$(HOME)/$$filename" ] && [ ! -L "$(HOME)/$$filename" ]; then \
			echo "$$filename already exist, renaming it to $$filename.orig"; mv $(HOME)/$$filename $(HOME)/$$filename.orig; fi; \
		ln -vsf $(DOTFILES_DIR)/$$file $(HOME)/$$filename; done


packages: brew-packages python-packages ## Install Homebrew and Python packages

brew: ## Install Homebrew
	is-executable brew || sh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

quicklook_lib_dir = $(HOME)/Library/QuickLook
brew-packages: brew ## Install Homebrew packages and casks listed in install/Brewfile
	brew bundle --file $(DOTFILES_DIR)/install/Brewfile
	[ -d "$(quicklook_lib_dir)" ] && xattr -d -r com.apple.quarantine $(quicklook_lib_dir)

python-packages: brew ## Install Python packages listed in install/requirements.txt
	is-brew-package python || brew install python
	pip3 install -r $(DOTFILES_DIR)/install/requirements.txt


zsh_plugins = nyquase/vi-mode MichaelAquilina/zsh-autoswitch-virtualenv zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting
zsh_plugin_dir = $(HOME)/.oh-my-zsh/custom/plugins
zsh: brew ## Install oh-my-zsh and plugins, also symlink .zshrc into HOME
	is-brew-package zsh || brew install zsh
	ZSH= sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	mkdir -vp $(zsh_plugin_dir)
	$(foreach plugin,$(zsh_plugins),git clone https://github.com/$(plugin) $(zsh_plugin_dir)/$(notdir $(plugin));)
	mv $(zsh_plugin_dir)/zsh-autoswitch-virtualenv $(zsh_plugin_dir)/autoswitch_virtualenv
	tic $(DOTFILES_DIR)/zsh/terminfo
	ln -vsf $(DOTFILES_DIR)/zsh/.zshrc $(HOME)/.zshrc


vim: brew ## Install VimPlug and plugins in .vimrc, which is also symlinked into HOME
	is-brew-package vim || brew install vim
	ln -vsf $(DOTFILES_DIR)/vim/.vimrc $(HOME)/.vimrc
	mkdir -vp $(HOME)/.vim/undo
	curl -fLso $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +qall
	for file in $$(find $(DOTFILES_DIR)/vim/plugged -name '*.vim'); do\
		ln -vsf $$file $(HOME)/.vim/$${file#"$(DOTFILES_DIR)/vim/"}; done

vim_ycm_dir = $(HOME)/.vim/plugged/youcompleteme
vim-ycm: vim brew-packages ## Install YouCompleteMe for all languages
	(cd $(vim_ycm_dir) && git submodule update --init --recursive)
	python3 $(vim_ycm_dir)/install.py --all


iterm2: brew ## Install and configure iTerm2, install JetBrainsMono font
	is-installed iTerm || brew install iterm2
	curl -fLso font.zip https://download.jetbrains.com/fonts/JetBrainsMono-2.225.zip
	unzip -o font.zip -d tmp/
	mv tmp/fonts/ttf/* $(HOME)/Library/Fonts
	rm -rf font.zip tmp
	defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$(DOTFILES_DIR)/iterm2/"
	defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
	open -a "iTerm"


haskell: ## Install Haskell Platform and Stack
	is-executable ghc || curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
	is-executable stack || curl -sSL https://get.haskellstack.org/ | sh


# This target: MIT (c) Jess Frazelle, https://github.com/jessfraz/dotfiles/blob/master/Makefile
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
