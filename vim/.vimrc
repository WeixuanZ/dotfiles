" Plugins {{{
call plug#begin('~/.vim/plugged')

" Completion {{{
" ====================================================================
Plug 'ervandew/supertab'
    let g:SuperTabClosePreviewOnPopupClose = 1
Plug 'valloric/youcompleteme'
    let g:ycm_autoclose_preview_window_after_completion = 1
    let g:ycm_complete_in_strings = 1
    nnoremap <leader>g :YcmCompleter GoToDefinitionElseDeclaration<CR>
Plug 'sirver/ultisnips'
    " make YCM compatible with UltiSnips (using supertab)
    let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
    let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
    let g:SuperTabDefaultCompletionType = '<C-n>'

    " better key bindings for UltiSnipsExpandTrigger
    let g:UltiSnipsExpandTrigger = '<tab>'
    let g:UltiSnipsJumpForwardTrigger = '<tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
Plug 'honza/vim-snippets'
" }}}

" File Navigation {{{
" ====================================================================
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
    nnoremap <silent> <C-p> :Files<CR>
    nnoremap <silent> <leader>f :Rg<CR>
    nnoremap <silent> <leader>b :Buffer<CR>
    nnoremap <silent> <leader>A :Windows<CR>
    nnoremap <silent> <leader>; :BLines<CR>
    nnoremap <leader>H :History<CR>
    let $FZF_DEFAULT_OPTS="--ansi --preview-window 'right:60%' --layout reverse --preview 'bat --color=always --style=header,grid --line-range :300 {}'"
    let $FZF_DEFAULT_COMMAND = 'rg --files --ignore-case --hidden -g "!{.git,node_modules,vendor}/*"'
    let g:fzf_action = {
    \ 'ctrl-q': 'wall | bdelete!',
    \ 'ctrl-t': 'tab split',
    \ 'ctrl-x': 'split',
    \ 'ctrl-v': 'vsplit' }
Plug 'preservim/nerdtree'
    let g:NERDTreeShowHidden=1
    let g:NERDTreeAutoDeleteBuffer = 1
    let g:NERDTreeCascadeOpenSingleChildDir = 1
    nnoremap <leader>n :call NERDTreeToggleAndFind()<CR>
    nnoremap <C-n> :NERDTreeFocus<CR>

    function! NERDTreeToggleAndFind() " {{{
        if (exists('t:NERDTreeBufName') && bufwinnr(t:NERDTreeBufName) != -1)
            execute ':NERDTreeClose'
        else
            execute ':NERDTreeFind'
        endif
    endfunction " }}}
" }}}

" Text Navigation {{{
"=====================================================================
Plug 'Lokaltog/vim-easymotion'
    let g:EasyMotion_smartcase = 1
    map <Space><Space> <Plug>(easymotion-prefix)
    map  / <Plug>(easymotion-sn)
    omap / <Plug>(easymotion-tn)
    map  n <Plug>(easymotion-next)
    map  N <Plug>(easymotion-prev)
Plug 'kshenoy/vim-signature'
" }}}

" Text Manipulation {{{
" ====================================================================
Plug 'tpope/vim-surround'
    " cs'", ds", ysiw]
Plug 'alvan/vim-closetag'
Plug 'tmsvg/pear-tree'
    let g:pear_tree_smart_openers = 1
    let g:pear_tree_smart_closers = 1
    let g:pear_tree_smart_backspace = 1
Plug 'scrooloose/nerdcommenter'
    " <leader>c<space>, <leader>c$, <leader>cA
    let g:NERDSpaceDelims = 1
    nnoremap <silent> <leader>c} V}:call NERDComment('x', 'toggle')<CR>
    nnoremap <silent> <leader>c{ V{:call NERDComment('x', 'toggle')<CR>

Plug 'mbbill/undotree'
    nnoremap <leader>u :UndotreeToggle<CR>
Plug 'tpope/vim-unimpaired'
    " [<Space> and ]<Space>
" }}}

" Git {{{
" ====================================================================
Plug 'tpope/vim-fugitive'
    noremap <leader>gs :Gstatus<CR>
    noremap <leader>gb :Git blame<CR>
    noremap <leader>gd :Git diff<CR>
    noremap <leader>gt :Git diff --staged<CR>
    nnoremap <leader>gu :Gread<CR>
    nnoremap <leader>gw :Gwrite<CR>
Plug 'airblade/vim-gitgutter'
    " [c, ]c, <leader>hp, <leader>hs, <leader>hu
    let g:gitgutter_max_signs = 200
    let g:gitgutter_realtime = 1
    let g:gitgutter_eager = 1
    let g:gitgutter_sign_added = '▌'
    let g:gitgutter_sign_modified = '▌'
    let g:gitgutter_sign_removed = '▌'
    let g:gitgutter_sign_modified_removed = '•'
    let g:gitgutter_diff_args = '--ignore-space-at-eol'
" }}}

" Languages {{{
" ====================================================================
Plug 'dense-analysis/ale'
    let g:ale_set_balloons=1
    let g:ale_fix_on_save=0
    let g:ale_linters = {
    \   'python': ['pylint'],
    \   'javascript': ['eslint'],
    \   'sh': ['shellcheck'],
    \   'vim': ['vint']
    \}
    let g:ale_fixers = {
    \   'python': ['autopep8'],
    \   'javascript': ['eslint'],
    \   'css': ['stylelint'],
    \}
    let g:ale_sign_column_always = 1
    let g:ale_sign_error = '◉'
    let g:ale_sign_warning = '◉'
    " let g:ale_set_highlights=0
    highlight clear ALEErrorSign
    highlight clear ALEWarningSign
    augroup ale_sign_highlight
        autocmd!
        autocmd VimEnter,Colorscheme * :highlight! ALEErrorSign ctermfg=1 ctermbg=NONE
        autocmd VimEnter,Colorscheme * :highlight! ALEWarningSign ctermfg=3 ctermbg=NONE
        autocmd VimEnter,Colorscheme * :highlight! ALEError cterm=undercurl
        autocmd VimEnter,Colorscheme * :highlight! ALEWarning cterm=undercurl
    augroup END
    nmap <silent> <C-k> <Plug>(ale_previous_wrap)
    nmap <silent> <C-j> <Plug>(ale_next_wrap)
Plug 'sheerun/vim-polyglot'
Plug 'lervag/vimtex'
    let g:tex_flavor='latex'
    let g:vimtex_view_method='skim'
    let g:vimtex_quickfix_mode=0
    let g:tex_conceal='abdmg'
    augroup latex
        autocmd!
        autocmd FileType tex nnoremap <buffer><leader>B :VimtexCompile<CR>
        autocmd FileType tex map <silent> <buffer><leader>` :call vimtex#latexmk#errors_open(0)<CR>
    augroup END
" Plug 'KeitaNakamura/tex-conceal.vim'
    " set conceallevel=1
    " hi Conceal ctermbg=none
Plug 'ap/vim-css-color'
" }}}

" Appearance {{{
" ====================================================================
Plug 'patstockwell/vim-monokai-tasty'
    let g:vim_monokai_tasty_italic = 1
Plug 'vim-airline/vim-airline'
    let g:airline_powerline_fonts = 1
Plug 'vim-airline/vim-airline-themes'
    let g:airline_theme='monokai_tasty'
Plug 'Yggdroot/indentLine'
    let g:indentLine_char = '▏'
" }}}

" Initialize plugin system
call plug#end()
"}}}


" General Config {{{
" ===================================================================
set nocompatible
set encoding=utf-8
" set clipboard=unnamed,unnamedplus
set modeline
set hidden                            " Navigate away without saving
set autoread                          " Auto reload changed files
set wildmenu                          " Tab autocomplete in command mode
set backspace=indent,eol,start        " http://vi.stackexchange.com/a/2163
set laststatus=2                      " Show status line on startup
set splitright                        " Open new splits to the right
set splitbelow                        " Open new splits to the bottom
set lazyredraw                        " Reduce the redraw frequency
set ttyfast                           " Send more characters in fast terminals
set nowrap                            " Don't wrap long lines
set list                              " show hidden characters
set listchars=tab:•·,trail:·,extends:❯,precedes:❮,nbsp:×
set nobackup nowritebackup noswapfile " Turn off backup files
set noerrorbells novisualbell         " Turn off visual and audible bells
set history=500
set ignorecase smartcase              " Search queries intelligently set case
set incsearch                         " Show search results as you type
set nohlsearch                        " No highlight search results
set timeoutlen=1000 ttimeoutlen=0     " Remove timeout when hitting escape
set showcmd                           " Show size of visual selection
set scrolloff=8                       " Leave 5 lines of buffer when scrolling
set sidescrolloff=10                  " Leave 10 characters of horizontal buffer when scrolling
set virtualedit=onemore               " Allow the cursor to move just past the end of the line
set signcolumn=yes
set foldmethod=marker
set foldlevel=2
set noshowmode                        " don't show editing mode

" Persistent undo
set undodir=~/.vim/undo/
set undofile
set undolevels=1000
set undoreload=10000

" Ignored files/directories from autocomplete (and CtrlP)
set wildignore+=*/tmp/*
set wildignore+=*.so
set wildignore+=*.zip
set wildignore+=*/vendor/bundle/*
set wildignore+=*/node_modules/

" Colours
silent! colorscheme vim-monokai-tasty
set background=dark
hi CursorLine ctermbg=0
hi CursorLineNr term=bold ctermfg=228 guifg=#ffff87
command! What echo synIDattr(synID(line('.'), col('.'), 1), 'name')

" Formatting
set expandtab tabstop=4 softtabstop=4 " Four spaces for tabs everywhere
set shiftwidth=4
set textwidth=79
set colorcolumn=80,120
highlight ColorColumn ctermbg=236
set number
autocmd InsertEnter,InsertLeave * set cul!

function! SetRelativenumber() " {{{
    " Help files don't get numbering so without this check we'll get an
    " annoying shift in the text when going in and out of a help buffer
    if &filetype != 'help'
        set relativenumber
    endif
endfunction " }}}
autocmd BufEnter,FocusGained * call SetRelativenumber()
autocmd BufLeave,FocusLost   * set norelativenumber
autocmd BufWritePre * %s/\s\+$//e

let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"
let &t_ZH = "\e[3m"
let &t_ZR = "\e[23m"
highlight Comment cterm=italic
let &t_Cs = "\e[4:3m"
let &t_Ce = "\e[4:0m"

" }}}


" Key Bindings {{{
" ===================================================================
map <Space> <leader>

inoremap jk <ESC>
inoremap <C-h> <Left>
inoremap <C-j> <Down>
inoremap <C-k> <Up>
inoremap <C-l> <Right>

nnoremap Y y$
nnoremap E $
nnoremap B ^
nnoremap <leader>z za

" Select all text
noremap vA ggVG

nnoremap <leader>w :w<CR>
nnoremap <leader>r :retab<CR>
nnoremap <silent> <leader>x :bd<CR>

" This unsets the "last search pattern" register by hitting return
nnoremap <CR> :nohlsearch<CR><CR>

" Remove trailing whitespaces in current buffer
nnoremap <Leader><BS>s :1,$s/[ ]*$//<CR>:nohlsearch<CR>1G

nnoremap <leader>% :call CopyCurrentFilePath()<CR>

function! CopyCurrentFilePath() " {{{
    let @+ = expand('%')
    echo @+
endfunction " }}}

" Move visual selection up and down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Tab {{{
" ===================================================================
" Easy tab navigation
nnoremap <C-Left> :tabprevious<CR>
nnoremap <C-Right> :tabnext<CR>
" Switch between tabs
nmap <leader>1 1gt
nmap <leader>2 2gt
nmap <leader>3 3gt
nmap <leader>4 4gt
nmap <leader>5 5gt
nmap <leader>6 6gt
nmap <leader>7 7gt
nmap <leader>8 8gt
nmap <leader>9 9gt
" }}}

" Buffer {{{
" ===================================================================
" Creating splits with empty buffers in all directions
nnoremap <Leader>hn :leftabove  vnew<CR>
nnoremap <Leader>ln :rightbelow vnew<CR>
nnoremap <Leader>kn :leftabove  new<CR>
nnoremap <Leader>jn :rightbelow new<CR>

" If split in given direction exists - jump, else create new split
function! JumpOrOpenNewSplit(key, cmd, fzf) " {{{
    let current_window = winnr()
    execute 'wincmd' a:key
    if current_window == winnr()
        execute a:cmd
        if a:fzf
            Files
        endif
    else
        if a:fzf
            Files
        endif
    endif
endfunction " }}}
nnoremap <silent> <Leader>hh :call JumpOrOpenNewSplit('h', ':leftabove vsplit', 0)<CR>
nnoremap <silent> <Leader>ll :call JumpOrOpenNewSplit('l', ':rightbelow vsplit', 0)<CR>
nnoremap <silent> <Leader>kk :call JumpOrOpenNewSplit('k', ':leftabove split', 0)<CR>
nnoremap <silent> <Leader>jj :call JumpOrOpenNewSplit('j', ':rightbelow split', 0)<CR>

" Universal closing behavior
nnoremap <silent> <leader>q :call CloseSplitOrDeleteBuffer()<CR>
function! CloseSplitOrDeleteBuffer() " {{{
    if winnr('$') > 1
        wincmd c
    else
        execute 'bdelete'
    endif
endfunction " }}}

" Delete all hidden buffers
nnoremap <silent> <Leader><BS>b :call DeleteHiddenBuffers()<CR>
function! DeleteHiddenBuffers() " {{{
    let tpbl=[]
    call map(range(1, tabpagenr('$')), 'extend(tpbl, tabpagebuflist(v:val))')
    for buf in filter(range(1, bufnr('$')), 'bufexists(v:val) && index(tpbl, v:val)==-1')
        silent execute 'bwipeout' buf
    endfor
endfunction " }}}
" }}}

" Capitalization {{{
if (&tildeop)
    nmap gcw guw~l
    nmap gcW guW~l
    nmap gciw guiw~l
    nmap gciW guiW~l
    nmap gcis guis~l
    nmap gc$ gu$~l
    nmap gcgc guu~l
    nmap gcc guu~l
    vmap gc gu~l
else
    nmap gcw guw~h
    nmap gcW guW~h
    nmap gciw guiw~h
    nmap gciW guiW~h
    nmap gcis guis~h
    nmap gc$ gu$~h
    nmap gcgc guu~h
    nmap gcc guu~h
    vmap gc gu~h
endif " }}}

" Terminal {{{
" ====================================================================
nnoremap <silent> <leader><Enter> :terminal<CR>

" Opening splits with terminal in all directions
nnoremap <Leader>h<Enter> :leftabove  vnew<CR>:terminal<CR>
nnoremap <Leader>l<Enter> :rightbelow vnew<CR>:terminal<CR>
nnoremap <Leader>k<Enter> :leftabove  new<CR>:terminal<CR>
nnoremap <Leader>j<Enter> :rightbelow new<CR>:terminal<CR>

tnoremap <F1> <C-\><C-n>
tnoremap <C-\><C-\> <C-\><C-n>:bd!<CR>
" }}}

" }}}


" Autocommands {{{
" ===================================================================
augroup Reload_Vimrc
    autocmd! BufWritePost $MYVIMRC source % | echom "Reloaded " . $MYVIMRC | redraw
augroup END
" }}}


" Credits {{{
" * [Alexander Tsygankov](https://github.com/zenbro/dotfiles/blob/master/.nvimrc)
" * [Tim Clifford](https://github.com/tim-clifford/vimrc/blob/master/.vimrc)
" * [Mike Coutermarsh](https://github.com/mscoutermarsh/dotfiles/blob/master/vim/vimrc.symlink)
" }}}

