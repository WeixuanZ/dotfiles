SHELL := /bin/bash
DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
override PATH := $(DOTFILES_DIR)/bin:$(PATH) # some helper shell scripts
.PHONY: link brew haskell help

COM_COLOR   = \033[0;34m
OBJ_COLOR   = \033[0;36m
OK_COLOR    = \033[0;32m
ERROR_COLOR = \033[0;31m
WARN_COLOR  = \033[0;33m
colorize = $(1)$(2)\033[m

create_symlink = if [ -f "$(2)" ] && [ ! -L "$(2)" ]; then \
		printf "$(call colorize,$(WARN_COLOR),$(2) already exist: renaming it to $(2).orig)\n"; \
		mv $(2) $(2).orig; fi; \
	ln -vsf $(1) $(2)


link: ## Link all dot files tracked by git into HOME and all files in misc/.config/ into HOME/.config/
	@for file in $$(git ls-files | egrep '^\/?(((\w+\/)*(\.\w+))|(misc\/\.\w+\/.+))$$'); do \
		if [[ $$file == misc/.*/* ]]; then \
			filename=$${file#*misc/}; \
			mkdir -p $(HOME)/$${filename%/*}; \
		else \
			filename=.$${file#*.}; \
		fi; \
		$(call create_symlink,$(DOTFILES_DIR)/$$file,$(HOME)/$$filename); \
	done


brew: ## Install Homebrew
	@if ! is-executable brew; then \
		bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		is-macos || echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile; \
	fi


update-brewfile: brew ## Update install/Brewfile and install/Appfile with packages/apps installed
	(cd $(DOTFILES_DIR) && brew bundle dump)
	egrep '^(tap|brew)\s.*' $(DOTFILES_DIR)/Brewfile > $(DOTFILES_DIR)/install/Brewfile
	egrep '^(tap|cask|mas)\s.*' $(DOTFILES_DIR)/Brewfile > $(DOTFILES_DIR)/install/Appfile
	@echo '# vim: syntax=brewfile' >> $(DOTFILES_DIR)/install/Appfile
	rm $(DOTFILES_DIR)/Brewfile


packages: brew-packages python-packages node-packages ## Install Homebrew, Python and Node packages

brew-packages: brew ## Install Homebrew packages listed in install/Brewfile
	brew bundle --file $(DOTFILES_DIR)/install/Brewfile

python-packages: brew ## Install Python packages listed in install/Pythonfile
	is-brew-package python3 || brew install python3
	pip3 install -r $(DOTFILES_DIR)/install/Pythonfile

node-packages: brew ## Install Node packages listed in install/Nodefile
	is-brew-package node || brew install node
	npm install -g $(shell cat $(DOTFILES_DIR)/install/Nodefile)


QUICKLOOK_LIB_DIR = $(HOME)/Library/QuickLook
apps: brew ## Install all casks and mas apps listed in install/Appfile
	@is-macos || (printf "$(call colorize,$(ERROR_COLOR),Not macOS)\n";  exit 1;)
	is-brew-package mas || brew install mas
	brew bundle --file $(DOTFILES_DIR)/install/Appfile
	[ -d "$(QUICKLOOK_LIB_DIR)" ] && xattr -d -r com.apple.quarantine $(QUICKLOOK_LIB_DIR)


ZSH_PLUGINS = jeffreytse/zsh-vi-mode MichaelAquilina/zsh-autoswitch-virtualenv zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting Aloxaf/fzf-tab
ZSH_THEMES = denysdovhan/spaceship-prompt
ZSH_CUSTOM_DIR = $(HOME)/.oh-my-zsh/custom
clone = $(foreach plugin,$(1),printf "$(call colorize,$(COM_COLOR),Cloning $(plugin))\n"; git clone --depth=1 --quiet https://github.com/$(plugin) $(2)/$(notdir $(plugin));)
zsh: brew ## Install oh-my-zsh and plugins, also symlink .zshrc into HOME
	is-brew-package zsh || brew install zsh
	# oh-my-zsh
	ZSH= sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	# plugins
	@$(call clone,$(ZSH_PLUGINS),$(ZSH_CUSTOM_DIR)/plugins)
	@mv $(ZSH_CUSTOM_DIR)/plugins/zsh-autoswitch-virtualenv $(ZSH_CUSTOM_DIR)/plugins/autoswitch_virtualenv
	# themes
	@$(call clone,$(ZSH_THEMES),$(ZSH_CUSTOM_DIR)/themes)
	@ln -s "$(ZSH_CUSTOM_DIR)/themes/spaceship-prompt/spaceship.zsh-theme" "$(ZSH_CUSTOM_DIR)/themes/spaceship.zsh-theme"
	# terminal italic support
	tic $(DOTFILES_DIR)/zsh/terminfo
	# link .zshrc
	@$(call create_symlink,$(DOTFILES_DIR)/zsh/.zshrc,$(HOME)/.zshrc)
	# add zsh to valid shells
	is-macos || command -v zsh | sudo tee -a /etc/shell


vim: brew ## Install VimPlug and plugins in .vimrc, which is also symlinked into HOME
	is-brew-package vim || brew install vim
	# link .vimrc
	@$(call create_symlink,$(DOTFILES_DIR)/vim/.vimrc,$(HOME)/.vimrc)
	# undodir
	mkdir -vp $(HOME)/.vim/undo
	# VimPlug, install all plugins
	curl -fLso $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +qall
	# link other *.vim files
	@for file in $$(git ls-files | egrep '^vim\/\w+\/.+$$'); do \
		filename=$${file#*vim/}; \
		mkdir -p $(HOME)/.vim/$${filename%/*}; \
		$(call create_symlink,$(DOTFILES_DIR)/$$file,$(HOME)/.vim/$$filename); \
	done

VIM_YCM_DIR = $(HOME)/.vim/plugged/youcompleteme
vim-ycm: vim brew-packages ## Install YouCompleteMe for all languages
	(cd $(VIM_YCM_DIR) && git submodule update --init --recursive)
	python3 $(VIM_YCM_DIR)/install.py --all


iterm2: brew ## Install and configure iTerm2, install JetBrainsMono font
	@is-macos || (printf "$(call colorize,$(ERROR_COLOR),Not macOS)\n";  exit 1;)
	is-installed iTerm || brew install iterm2
	# install JetBrainsMono
	curl -fLso font.zip https://download.jetbrains.com/fonts/JetBrainsMono-2.225.zip
	unzip -o font.zip -d tmp/
	mv tmp/fonts/ttf/* $(HOME)/Library/Fonts
	rm -rf font.zip tmp
	# config iTerm to load preferences
	defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$(DOTFILES_DIR)/iterm2/"
	defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true
	open -a "iTerm"


hammerspoon: brew link ## Install Hammmerspoon and Spoons
	@is-macos || (printf "$(call colorize,$(ERROR_COLOR),Not macOS)\n";  exit 1;)
	is-installed hammerspoon || brew install hammerspoon
	bash <(curl -s https://raw.githubusercontent.com/dbalatero/VimMode.spoon/master/bin/installer)


haskell: ## Install Haskell Platform and Stack
	is-executable ghc || curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
	is-executable stack || curl -sSL https://get.haskellstack.org/ | sh


# This target: MIT (c) Jess Frazelle, https://github.com/jessfraz/dotfiles/blob/master/Makefile
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "$(call colorize,$(OBJ_COLOR),%-30s) %s\n", $$1, $$2}'
