DOTFILES_DIR := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PATH := $(DOTFILES_DIR)/bin:$(PATH) # some helper shell scripts
.PHONY: link brew haskell help

COM_COLOR   = \033[0;34m
OBJ_COLOR   = \033[0;36m
OK_COLOR    = \033[0;32m
ERROR_COLOR = \033[0;31m
WARN_COLOR  = \033[0;33m
color = $(1)$(2)\033[m


link: ## Link all the dot files tracked by git into HOME
	@for file in $$(git ls-files | egrep '^\/?(?:\w+\/)*(\.\w+)'); do \
		filename=.$${file#*.}; \
		if [ -f "$(HOME)/$$filename" ] && [ ! -L "$(HOME)/$$filename" ]; then \
			echo "$(call color,$(WARN_COLOR),$$filename already exist: renaming it to $$filename.orig)"; mv $(HOME)/$$filename $(HOME)/$$filename.orig; fi; \
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


ZSH_PLUGINS = jeffreytse/zsh-vi-mode MichaelAquilina/zsh-autoswitch-virtualenv zsh-users/zsh-autosuggestions zsh-users/zsh-syntax-highlighting
ZSH_THEMES = denysdovhan/spaceship-prompt
ZSH_CUSTOM_DIR = $(HOME)/.oh-my-zsh/custom
clone = $(foreach plugin,$(1),echo "$(call color,$(COM_COLOR),Cloning $(plugin))"; git clone --depth=1 --quiet https://github.com/$(plugin) $(2)/$(notdir $(plugin));)
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
	ln -vsf $(DOTFILES_DIR)/zsh/.zshrc $(HOME)/.zshrc


vim: brew ## Install VimPlug and plugins in .vimrc, which is also symlinked into HOME
	is-brew-package vim || brew install vim
	# link .vimrc
	ln -vsf $(DOTFILES_DIR)/vim/.vimrc $(HOME)/.vimrc
	# undodir
	mkdir -vp $(HOME)/.vim/undo
	# VimPlug, install all plugins
	curl -fLso $(HOME)/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +qall
	# link other *.vim files
	for file in $$(find $(DOTFILES_DIR)/vim/plugged -name '*.vim'); do\
		ln -vsf $$file $(HOME)/.vim/$${file#"$(DOTFILES_DIR)/vim/"}; done

VIM_YCM_DIR = $(HOME)/.vim/plugged/youcompleteme
vim-ycm: vim brew-packages ## Install YouCompleteMe for all languages
	(cd $(VIM_YCM_DIR) && git submodule update --init --recursive)
	python3 $(VIM_YCM_DIR)/install.py --all


iterm2: brew ## Install and configure iTerm2, install JetBrainsMono font
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


haskell: ## Install Haskell Platform and Stack
	is-executable ghc || curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
	is-executable stack || curl -sSL https://get.haskellstack.org/ | sh


# This target: MIT (c) Jess Frazelle, https://github.com/jessfraz/dotfiles/blob/master/Makefile
help: ## Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
