" Plugins {{{
call plug#begin('~/.vim/plugged')

" Completion {{{
" ====================================================================
Plug 'ervandew/supertab'
    let g:SuperTabClosePreviewOnPopupClose = 1
    let g:SuperTabDefaultCompletionType = '<C-n>'
Plug 'valloric/youcompleteme'
    let g:ycm_autoclose_preview_window_after_completion = 1
    let g:ycm_complete_in_strings = 1
    let g:ycm_show_diagnostics_ui = 0 " use ALE for linting
    nnoremap <leader>d :YcmCompleter GoTo<CR>
    nnoremap <leader>gr :YcmCompleter GoToReferences<CR>
Plug 'sirver/ultisnips'
    " make YCM compatible with UltiSnips (using supertab)
    let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
    let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']
    " better key bindings for UltiSnipsExpandTrigger
    let g:UltiSnipsExpandTrigger = '<tab>'
    let g:UltiSnipsJumpForwardTrigger = '<Space><tab>'
    let g:UltiSnipsJumpBackwardTrigger = '<s-tab>'
Plug 'honza/vim-snippets'
" }}}

" File Navigation {{{
" ====================================================================
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
    nnoremap <silent> <C-p> :Files<CR>
    nnoremap <silent> <leader>r :RG<CR>
    nnoremap <silent> <leader>f :BLines<CR>
    nnoremap <silent> <leader>b :Buffer<CR>
    nnoremap <silent> <leader>A :Windows<CR>
    nnoremap <silent> <leader>H :History<CR>
    let g:fzf_action = {
                \ 'ctrl-q': 'wall | bdelete!',
                \ 'ctrl-t': 'tab split',
                \ 'ctrl-x': 'split',
                \ 'ctrl-v': 'vsplit' }
    let g:fzf_colors = {
                \ 'fg': ['fg', 'Comment'],
                \ 'hl+': ['fg', 'Function'] }

    let $FZF_DEFAULT_OPTS = '--reverse --cycle --preview-window right:60%' " the defaults are pretty good
    function SetFZFCommand() " ignore the current file
        let $FZF_DEFAULT_COMMAND = printf('rg --files --hidden -g ''!{.git,node_modules,vendor}/*'' -g ''!%s''', shellescape(expand('%'))) " :Files calls this as source
    endfunction
    augroup set_fzf_command
        autocmd!
        autocmd BufEnter * :call SetFZFCommand()
    augroup END
    " {{{ alternatively can use this, but lose some features
    " command! -bang -nargs=* Files
    " \ call fzf#run(fzf#wrap({'source': 'rg --files --hidden -g ''!{.git,node_modules,vendor}/*'' -g ''!'.shellescape(expand('%'))."'"})) " }}}

    " completely delegate search responsiblity to ripgrep process, instead of letting fzf filter source provided by rg
    " this allows for continuous searching in preview window
    command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)
    function! RipgrepFzf(query, fullscreen) " {{{
        " ignore the current file
        let command_fmt = 'rg --color=always --smart-case --no-heading --column --line-number --hidden -g ''!{.git,node_modules,vendor}/*'' -g ''!%s'' -- %s || true'
        let curr_file = shellescape(expand('%'))
        let initial_command = printf(command_fmt, curr_file, shellescape(a:query))
        let reload_command = printf(command_fmt, curr_file, '{q}')
        let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
        call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
    endfunction " }}}

Plug 'airblade/vim-rooter'
Plug 'preservim/nerdtree'
    let g:NERDTreeShowHidden = 1
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
    let g:EasyMotion_use_upper = 1 " using capital letters for targets
    let g:EasyMotion_keys = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ;'
    map <Space>e <Plug>(easymotion-prefix)
    nmap <Space><Space> <Plug>(easymotion-bd-w)
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
Plug 'junegunn/vim-easy-align'
    xmap ga <Plug>(EasyAlign)
    nmap ga <Plug>(EasyAlign)
Plug 'mbbill/undotree'
    let g:undotree_SetFocusWhenToggle = 1
    nnoremap <leader>u :UndotreeToggle<CR>
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
    let g:gitgutter_sign_removed_above_and_below = '▌'
    let g:gitgutter_sign_modified_removed = '▌'
    let g:gitgutter_diff_args = '--ignore-space-at-eol'
    set foldtext=gitgutter#fold#foldtext()
    omap ih <Plug>(GitGutterTextObjectInnerPending)
    omap ah <Plug>(GitGutterTextObjectOuterPending)
    xmap ih <Plug>(GitGutterTextObjectInnerVisual)
    xmap ah <Plug>(GitGutterTextObjectOuterVisual)
" }}}

" Languages {{{
" ====================================================================
Plug 'dense-analysis/ale'
    let g:ale_hover_cursor = 0 " using ycm hover only
    " let g:ale_hover_to_preview = 0 " balloons don't work
    " this will be merged with the default config dict, note that only unspecified languages will have all linters enabled by default
    let g:ale_linters = {
    \   'python': ['flake8', 'mypy', 'pylint', 'pyright', 'pyls'],
    \   'zsh': ['shell', 'shellcheck']
    \} " add pyls to enabled linters to enable renaming
    " let g:ale_fix_on_save = 0
    let g:ale_fixers = {
    \   'python': ['autopep8'],
    \   'javascript': ['prettier'],
    \   'html': ['prettier'],
    \   'css': ['stylelint'],
    \   'tex': ['latexindent']
    \}
    let g:ale_echo_msg_error_str = 'E'
    let g:ale_echo_msg_warning_str = 'W'
    let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
    let g:ale_languagetool_options = '--disable EN_QUOTES'
    let g:ale_sign_column_always = 1
    let g:ale_sign_error = '•'
    let g:ale_sign_warning = '•'
    augroup ale_sign_highlight
        autocmd!
        autocmd Colorscheme * :highlight ALEErrorSign ctermfg=1 ctermbg=NONE
        autocmd Colorscheme * :highlight ALEWarningSign ctermfg=3 ctermbg=NONE
        autocmd Colorscheme * :highlight ALEError cterm=undercurl
        autocmd Colorscheme * :highlight ALEWarning cterm=undercurl
    augroup END
    nmap <silent> <C-k> <Plug>(ale_previous_wrap)
    nmap <silent> <C-j> <Plug>(ale_next_wrap)
Plug 'sheerun/vim-polyglot'
    " Markdown
    let g:vim_markdown_conceal_code_blocks = 0
    let g:vim_markdown_toc_autofit = 1
    let g:vim_markdown_math = 1
    let g:vim_markdown_frontmatter = 1
    let g:vim_markdown_edit_url_in = 'current'
Plug 'lervag/vimtex'
    let g:tex_flavor = 'latex'
    let g:vimtex_view_method = 'skim'
    let g:vimtex_syntax_nospell_comments = 1
    let g:vimtex_format_enabled = 1
    let g:vimtex_fold_enabled = 1
    " let g:vimtex_quickfix_mode = 1
    let g:vimtex_quickfix_autoclose_after_keystrokes = 5
    let g:vimtex_indent_lists = []
    augroup tex
        autocmd!
        autocmd FileType tex call TexConfig() " set spell and key maps
        if !exists('g:ycm_semantic_triggers')
            let g:ycm_semantic_triggers = {}
        endif
        autocmd VimEnter * let g:ycm_semantic_triggers.tex=g:vimtex#re#youcompleteme
        autocmd BufWritePost *.tex let b:tex_wordcount = vimtex#misc#wordcount() " update word count on save
        autocmd User VimtexEventInitPost silent! call vimtex#compiler#compile() " start compilation on enter
        autocmd User VimtexEventQuit call TexQuit() " clean and quit Skim
    augroup END
    function TexConfig() " {{{
        setlocal spell spelllang=en_gb
        setlocal formatoptions+=t
        nnoremap <buffer><leader>L :VimtexCompile<CR>
        nnoremap <buffer><leader>v :VimtexView<CR>
        nnoremap <silent> <buffer><leader>` :call vimtex#latexmk#errors_open(0)<CR>
        " The second argument extends the default vimtex#fzf#run options
        nnoremap <buffer><leader>lt :call vimtex#fzf#run('ctli', { 'left': '20%' })<CR>
    endfunction " }}}
    function TexQuit() " {{{
        call vimtex#compiler#clean(0)
        call system('osascript -e ''tell application "Skim" to close first window''')
    endfunction " }}}
    if has('nvim') " nvim for easy backward synchronisation
        let g:vimtex_compiler_progname = 'nvr'
    endif
Plug 'ap/vim-css-color'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
Plug 'goerz/jupytext.vim'
" }}}

" Utilities {{{
" ====================================================================
Plug 'tpope/vim-unimpaired'
    " [<Space> and ]<Space>
Plug 'tyru/open-browser.vim'
    let g:netrw_nogx = 1 " disable netrw's gx mapping, which is currently not working on macOS
    nmap gx <Plug>(openbrowser-smart-search)
    vmap gx <Plug>(openbrowser-smart-search)
    command! OpenBrowserCurrent execute "OpenBrowser" "file:///" . expand('%:p:gs?\\?/?')
" }}}

" Appearance {{{
" ====================================================================
Plug 'patstockwell/vim-monokai-tasty'
    let g:vim_monokai_tasty_italic = 1
Plug 'vim-airline/vim-airline'
    let g:airline#extensions#wordcount#formatter = 'custom' " fix tex word count
    let g:airline_powerline_fonts = 1
Plug 'vim-airline/vim-airline-themes'
    let g:airline_theme='monokai_tasty'
Plug 'Yggdroot/indentLine', { 'for': ['python'] }
    let g:indentLine_char = '▏'
    let g:indentLine_setConceal = 0
    " let g:indentLine_setConceal = 0 " prevent indentLine from messing stuff up
    " let g:indentLine_setColors = 0
" }}}

" Initialize plugin system
call plug#end()
"}}}


" General Config {{{
" ===================================================================
set nocompatible
set encoding=utf-8
set conceallevel=2
" set clipboard=unnamed,unnamedplus
set mouse=a
set modeline
set hidden                            " Navigate away without saving
set autoread                          " Auto reload changed files
set wildmenu                          " Tab autocomplete in command mode
set wildmode=longest:full,full
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
set scrolloff=8                       " Leave 8 lines of buffer when scrolling
set sidescrolloff=10                  " Leave 10 characters of horizontal buffer when scrolling
set virtualedit=onemore               " Allow the cursor to move just past the end of the line
set signcolumn=yes
set foldmethod=marker
set foldlevel=2
set noshowmode                        " Don't show editing mode

" Formatting
set expandtab tabstop=4 softtabstop=4 " Four spaces for tabs everywhere
set shiftwidth=4
set textwidth=79
set colorcolumn=80,120
set formatoptions=crqnl1j

" Persistent undo
set undodir=~/.vim/undo/
set undofile
set undolevels=1000
set undoreload=10000

" Ignored files/directories from autocomplete
set wildignore+=*/tmp/*
set wildignore+=*.so
set wildignore+=*.zip
set wildignore+=*/vendor/bundle/*
set wildignore+=*/node_modules/

" Appearance
silent! colorscheme vim-monokai-tasty
set background=dark
set cursorline
set number

function! SetRelativenumber() " {{{
    " Help files don't get numbering so without this check we'll get an
    " annoying shift in the text when going in and out of a help buffer
    if &filetype != 'help'
        set relativenumber
    endif
endfunction " }}}
augroup set_relative_number
    autocmd!
    autocmd BufEnter,FocusGained * call SetRelativenumber()
    autocmd BufLeave,FocusLost   * set norelativenumber
augroup END

highlight CursorLine ctermbg=0
highlight CursorLineNr cterm=bold ctermfg=green
augroup cursor_line_highlight
    autocmd!
    autocmd InsertEnter * hi CursorLineNr ctermfg=yellow
    autocmd InsertLeave * hi CursorLineNr ctermfg=green
augroup END
highlight MatchParen ctermfg=green
highlight SpecialKey ctermbg=0
highlight Conceal ctermfg=yellow
highlight ColorColumn ctermbg=236
highlight SpellBad cterm=undercurl ctermbg=NONE ctermfg=NONE
highlight SpellCap cterm=undercurl ctermbg=NONE ctermfg=NONE
highlight SpellLocal cterm=underline ctermbg=NONE ctermfg=NONE
highlight SpellRare ctermbg=NONE ctermfg=NONE

" Cursor
if exists('$TMUX') " tmux will only forward escape sequences to the terminal if surrounded by a DCS sequence
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
    let &t_SR = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=2\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]50;CursorShape=1\x7"
    let &t_SR = "\<Esc>]50;CursorShape=2\x7"
    let &t_EI = "\<Esc>]50;CursorShape=0\x7"
endif
" Undercurl
let &t_ZH = "\e[3m"
let &t_ZR = "\e[23m"
" Italic
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

onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>
onoremap an( :<c-u>normal! f(va(<cr>
onoremap in{ :<c-u>normal! f{vi{<cr>
onoremap il{ :<c-u>normal! F}vi{<cr>
onoremap ia{ :<c-u>normal! f{va{<cr>

nnoremap <C-c> :edit ~/.vimrc<CR>

nnoremap Y y$
nnoremap E $
nnoremap B ^
nnoremap <leader>w :w<CR>
nnoremap <leader>a =ip
nnoremap <leader>R :retab<CR>
nnoremap <leader>z za
nnoremap <leader>s :%s//g<Left><Left>
vnoremap <leader>s :s//g<Left><Left>

" Select all text
noremap vA ggVG

" Clipboard
nnoremap <leader>p "+p
nnoremap <leader>]p "+]p
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" This unsets the "last search pattern" register by hitting return
nnoremap <CR> :nohlsearch<CR><CR>

nnoremap <leader>% :call CopyCurrentFilePath()<CR>
function! CopyCurrentFilePath() " {{{
    let @+ = expand('%')
    echo @+
endfunction " }}}

" Move visual selection up and down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Apply macros with Q
nnoremap Q @q
vnoremap Q :norm @q<cr>

" Tab {{{
" -------------------------------------------------------------------
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
" -------------------------------------------------------------------
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

" Qickfix {{{
" -------------------------------------------------------------------
nnoremap <silent> <leader>F :call ToggleQuickFix()<CR>
function! ToggleQuickFix() " {{{
    if empty(filter(getwininfo(), 'v:val.quickfix'))
        copen
    else
        cclose
    endif
endfunction " }}}
" }}}

" Capitalization {{{
" -------------------------------------------------------------------
if (&tildeop)
    nnoremap gcw guw~l
    nnoremap gcW guW~l
    nnoremap gciw guiw~l
    nnoremap gciW guiW~l
    nnoremap gcis guis~l
    nnoremap gc$ gu$~l
    nnoremap gcgc guu~l
    nnoremap gcc guu~l
    vnoremap gc gu~l
else
    nnoremap gcw guw~h
    nnoremap gcW guW~h
    nnoremap gciw guiw~h
    nnoremap gciW guiW~h
    nnoremap gcis guis~h
    nnoremap gc$ gu$~h
    nnoremap gcgc guu~h
    nnoremap gcc guu~h
    vnoremap gc gu~h
endif " }}}

" Terminal {{{
" --------------------------------------------------------------------
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


" Commands {{{
" ===================================================================
command! What echo synIDattr(synID(line('.'), col('.'), 1), 'name')

" Read shell command ouput into a temperary buffer
command! -nargs=* -complete=shellcmd R new | setlocal buftype=nofile bufhidden=hide noswapfile | r !<args>

" }}}


" Misc Autocommands {{{
" ===================================================================
augroup reload_vimrc
    autocmd! BufWritePost $MYVIMRC source % | echom "Reloaded " . $MYVIMRC | redraw
augroup END

augroup format
    autocmd!
    autocmd BufWritePre * %s/\s\+$//e
augroup END

augroup help_nav
    autocmd!
    autocmd FileType help call ConfigHelp()
    function ConfigHelp()
        nnoremap <buffer> <CR> <C-]>
        nnoremap <buffer> <BS> <C-T>
        nnoremap <buffer> o /'\l\{2,\}'<CR>
        nnoremap <buffer> O ?'\l\{2,\}'<CR>
        nnoremap <buffer> s /\|\zs\S\+\ze\|<CR>
        nnoremap <buffer> S ?\|\zs\S\+\ze\|<CR>
    endfunction
augroup END

" }}}


" Credits {{{
" * [Alexander Tsygankov](https://github.com/zenbro/dotfiles/blob/master/.nvimrc)
" * [Tim Clifford](https://github.com/tim-clifford/nvimrc/blob/master/init.vim)
" * [Mike Coutermarsh](https://github.com/mscoutermarsh/dotfiles/blob/master/vim/vimrc.symlink)
" * https://vim.fandom.com/wiki/
" }}}

