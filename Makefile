all: brew-packages zsh

brew:
ifdef $(shell command -v brew 2> /dev/null)
	echo "Homebrew not installed"
	sh -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
endif

quicklook_folder_path = ${HOME}/Library/QuickLook
brew-packages: brew
	brew bundle
	[ -d "${quicklook_folder_path}" ] && xattr -d -r com.apple.quarantine ${quicklook_folder_path} || echo "QuickLook folder not found"

python: brew
	brew install python
	pip3 install -r requirements.txt

zsh_plugin_path = ${HOME}/.oh-my-zsh/custom/plugins
zsh: brew
	brew install zsh
	sh -c "$$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	mkdir -vp ${zsh_plugin_path}
	git clone https://github.com/jeffreytse/zsh-vi-mode ${zsh_plugin_path}/zsh-vi-mode
	git clone https://github.com/MichaelAquilina/zsh-autoswitch-virtualenv.git ${zsh_plugin_path}/autoswitch_virtualenv
	git clone https://github.com/zsh-users/zsh-autosuggestions ${zsh_plugin_path}/zsh-autosuggestions
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${zsh_plugin_path}/zsh-syntax-highlighting
	tic ${PWD}/zsh/terminfo
	ln -vsf ${PWD}/zsh/.zshrc ${HOME}/.zshrc

vim: brew
	brew install vim
	ln -vsf ${PWD}/vim/.vimrc ${HOME}/.vimrc
	mkdir -vp ${HOME}/.vim/undo
	curl -fLo ${HOME}/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	vim +PlugInstall +qall

youcompleteme_folder = ${HOME}/.vim/plugged/youcompleteme
youcompleteme: vim brew-packages
	(cd ${youcompleteme_folder} && git submodule update --init --recursive)
	python3 ${youcompleteme_folder}/install.py --all

haskell:
	curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | sh
	curl -sSL https://get.haskellstack.org/ | sh
