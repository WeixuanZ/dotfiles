" Plugins {{{
call plug#begin(has('ivim') ? '~/ivim' : '~/.vim/plugged')

" Completion {{{
" ====================================================================
Plug 'valloric/youcompleteme'
    set completeopt-=preview
    let g:ycm_min_num_of_chars_for_completion = 4  " ycm conflicts with UltiSnips auto snippet
    let g:ycm_autoclose_preview_window_after_completion = 1
    let g:ycm_show_diagnostics_ui = 0 " use ALE for linting
    " trigger for everything, maybe not a good idea though, we will see about speed...
    let g:ycm_semantic_triggers = { 'python': ['re!\w{2,}\.?'] }
    nnoremap <leader>d :YcmCompleter GoTo<CR>
    nnoremap <leader>gr :YcmCompleter GoToReferences<CR>
Plug 'sirver/ultisnips'
    let g:UltiSnipsExpandTrigger = '<C-j>'
    let g:UltiSnipsJumpForwardTrigger = '<C-j>'
    let g:UltiSnipsJumpBackwardTrigger = '<C-k>'
" }}}

" File Navigation {{{
" ====================================================================
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
    nnoremap <silent> <C-p> :Files<CR>
    nnoremap <silent> <leader>R :RG<CR>
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
        let $FZF_DEFAULT_COMMAND = printf('rg --files --hidden -g ''!%s'' -g ''!{.git,node_modules}/*''', len(expand('%')) != 0 ? shellescape(expand('%')) : '_') " :Files calls this as source
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
Plug 'aymericbeaumet/vim-symlink'
Plug 'preservim/nerdtree'
    let g:NERDTreeShowHidden = 1
    let g:NERDTreeAutoDeleteBuffer = 1
    let g:NERDTreeCascadeOpenSingleChildDir = 1
    nnoremap <leader>n :call NERDTreeToggleAndFind()<CR>
    nnoremap <leader>N :NERDTreeFocus<CR>
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
Plug 'kshenoy/vim-signature'
" }}}

" Text Manipulation {{{
" ====================================================================
Plug 'tpope/vim-surround'
    " cs'", ds", ysiw]
Plug 'alvan/vim-closetag'
Plug 'jiangmiao/auto-pairs'
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
    noremap <leader>gs :Git<CR>
    noremap <leader>gb :Git blame<CR>
    noremap <leader>gd :Git diff<CR>
    noremap <leader>gt :Git diff --staged<CR>
    nnoremap <leader>gu :Gread<CR>
    nnoremap <leader>gw :Gwrite<CR>
    nnoremap <leader>gh :diffget //2<CR>
    nnoremap <leader>gl :diffget //3<CR>
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
    " linter options
    let g:ale_vhdl_ghdl_options = '--ieee=synopsys --std=08'
    let g:ale_languagetool_options = '--disable EN_QUOTES'
    let g:ale_tex_chktex_options = '-I -n3'
    " appearance
    let g:ale_echo_msg_error_str = 'E'
    let g:ale_echo_msg_warning_str = 'W'
    let g:ale_echo_msg_format = '[%linter%] %s [%severity%]'
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
    augroup markdown
        autocmd!
        autocmd FileType markdown call MarkdownConfig()
    augroup END
    function MarkdownConfig()
        setlocal wrap
        setlocal linebreak
        setlocal showbreak=↪
        vmap <buffer>j gj
        vmap <buffer>k gk
        nmap <buffer>j gj
        nmap <buffer>k gk
        nnoremap <buffer><leader>lt :Toc<CR>
        nnoremap <buffer><leader>v :MarkdownPreview<CR>
    endfunction
    " SQL
    let g:sql_type_default = 'pgsql'
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && yarn install'  }
    let g:mkdp_echo_preview_url = 1
Plug 'lervag/vimtex'
    let g:tex_flavor = 'latex'
    let g:vimtex_view_method = 'skim'
    let g:vimtex_syntax_nospell_comments = 1
    let g:vimtex_format_enabled = 1
    let g:vimtex_fold_enabled = 1
    let g:vimtex_fold_manual = 1
    let g:vimtex_quickfix_open_on_warning = 0
    let g:vimtex_quickfix_autoclose_after_keystrokes = 5
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
        setlocal foldlevel=3
        nnoremap <buffer><leader>L :VimtexCompile<CR>
        nnoremap <buffer><leader>v :VimtexView<CR>
        nnoremap <buffer><leader>Z :VimtexRefreshFolds<CR>
        " The second argument extends the default vimtex#fzf#run options
        " nnoremap <buffer><leader>lt :call vimtex#fzf#run('ctli', { 'left': '20%' })<CR>
    endfunction " }}}
    function TexQuit() " {{{
        call vimtex#compiler#clean(0)
        call system('osascript -e ''tell application "Skim" to close first window''')
    endfunction " }}}
    if has('nvim') " nvim for easy backward synchronisation
        let g:vimtex_compiler_progname = 'nvr'
    endif
Plug 'ap/vim-css-color'
Plug 'goerz/jupytext.vim'
" }}}

" Utilities {{{
" ====================================================================
Plug 'skywind3000/asyncrun.vim'
    let g:asyncrun_open = 10
    nnoremap <leader>r :call AsyncRunOrExecute()<CR>
    function AsyncRunOrExecute() " {{{
        :AsyncStop
        if &filetype ==# 'python'
            execute ':AsyncRun python3 '.expand('%:t')
        elseif &filetype ==# 'sh'
            execute ':AsyncRun ./'.expand('%:t')
        else
            let l:command = input('Command: ')
            if !empty(l:command)
                " execute ':AsyncRun -mode=term -focus=0 -rows=10 '.l:command
                execute ':AsyncRun '.l:command
            else
                echom 'No command given'
            endif
        endif
    endfunction " }}}
Plug 'tpope/vim-unimpaired'
    " [<Space> and ]<Space>
Plug 'tpope/vim-repeat'
Plug 'junegunn/vim-peekaboo'
Plug 'kristijanhusak/vim-carbon-now-sh'
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
    let g:airline_symbols = {'colnr': ':'}
Plug 'vim-airline/vim-airline-themes'
    let g:airline_theme='monokai_tasty'
Plug 'Yggdroot/indentLine', { 'for': ['python'] }
    let g:indentLine_char = '▏'
    let g:indentLine_setConceal = 0 " prevent indentLine from messing stuff up
    " let g:indentLine_setColors = 0
Plug 'wfxr/minimap.vim'
    nnoremap <leader>m :MinimapToggle<cr>
    let g:minimap_highlight_range = 1
    let g:minimap_git_colors = 1
    let g:minimap_cursor_color = 'minimapRange'
    let g:minimap_range_color = 'minimapCursor'
" }}}

" Initialize plugin system
call plug#end()
"}}}


" General Config {{{
" ===================================================================
set encoding=utf-8
set conceallevel=0
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
set maxmempattern=10000

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
    let rel_number_ignore = ['help', 'nerdtree', 'undotree']
    if index(rel_number_ignore, &filetype) == -1
        set relativenumber
    endif
endfunction " }}}
augroup set_relative_number
    autocmd!
    autocmd BufEnter,FocusGained * call SetRelativenumber()
    autocmd BufLeave,FocusLost   * set norelativenumber
augroup END

highlight Cursor ctermbg=green guibg=#a4e400
highlight CursorLine ctermbg=0 guibg=NONE
highlight CursorLineNr cterm=bold ctermfg=green gui=bold guifg=#a4e400
augroup cursor_line_highlight
    autocmd!
    autocmd InsertEnter * hi CursorLineNr ctermfg=yellow guifg=#ffff87
    autocmd InsertLeave * hi CursorLineNr ctermfg=green guifg=#a4e400
augroup END
highlight MatchParen ctermfg=green guifg=#a4e400
highlight SpecialKey ctermbg=0 guibg=NONE
highlight Conceal ctermfg=yellow guifg=#ffff87
highlight ColorColumn ctermbg=236
highlight SpellBad cterm=undercurl ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
highlight SpellCap cterm=undercurl ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
highlight SpellLocal cterm=underline ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE
highlight SpellRare ctermbg=NONE ctermfg=NONE guibg=NONE guifg=NONE

" Cursor
if exists('$TMUX') " tmux will only forward escape sequences to the terminal if surrounded by a DCS sequence
    let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]1337;CursorShape=1\x7\<Esc>\\"
    let &t_SR = "\<Esc>Ptmux;\<Esc>\<Esc>]1337;CursorShape=2\x7\<Esc>\\"
    let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]1337;CursorShape=0\x7\<Esc>\\"
else
    let &t_SI = "\<Esc>]1337;CursorShape=1\x7"
    let &t_SR = "\<Esc>]1337;CursorShape=2\x7"
    let &t_EI = "\<Esc>]1337;CursorShape=0\x7"
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

onoremap in( :<c-u>normal! f(vi(<cr>
onoremap il( :<c-u>normal! F)vi(<cr>
onoremap an( :<c-u>normal! f(va(<cr>
onoremap in{ :<c-u>normal! f{vi{<cr>
onoremap il{ :<c-u>normal! F}vi{<cr>
onoremap ia{ :<c-u>normal! f{va{<cr>

nnoremap <leader>CC :edit ~/.vimrc<CR>
nnoremap <leader>C :cd %:p:h<CR>

nnoremap Y y$
vmap y ygv<Esc>
nnoremap <leader>w :w<CR>
nnoremap <leader>i =ip
nnoremap <leader>z za
nnoremap <leader>s :%s//g<Left><Left>
vnoremap <leader>s :s//g<Left><Left>

" Select all text
noremap vA ggVG

" Clipboard
nnoremap <leader>p "+p
vnoremap <leader>p "+p
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>' "+
vnoremap <leader>' "+

nnoremap <leader>% :call CopyCurrentFilePath()<CR>
function! CopyCurrentFilePath() " {{{
    let @+ = expand('%')
    echo @+
endfunction " }}}

" https://gist.github.com/romainl/3b8cdc6c3748a363da07b1a625cfc666
function! BreakHere()
    s/^\(\s*\)\(.\{-}\)\(\s*\)\(\%#\)\(\s*\)\(.*\)/\1\2\r\1\4\6
    call histdel("/", -1)
endfunction
nnoremap K :<C-u>call BreakHere()<CR>

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
command! What call SynGroup()
function SynGroup()
    let l:s = synID(line('.'), col('.'), 1)
    echo synIDattr(l:s, 'name') . ' -> ' . synIDattr(synIDtrans(l:s), 'name')
endfunction

" Read shell command ouput into a temperary buffer
command! -nargs=* -complete=shellcmd R new | setlocal buftype=nofile bufhidden=hide noswapfile | r !<args>

command! Noindent setl noai nocin nosi inde=

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

augroup languages
    autocmd!
    autocmd FileType python,markdown setlocal conceallevel=1
    autocmd FileType javascript,css,json,yaml setlocal ts=2 sts=2 sw=2
    autocmd BufEnter,BufNew *.cls set filetype=tex
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

augroup hex_editing
    autocmd!
    autocmd BufReadPre  *.bin let &bin=1
    autocmd BufReadPost *.bin if &bin | %!xxd
    autocmd BufReadPost *.bin set filetype=xxd | endif
    autocmd BufWritePre *.bin if &bin | %!xxd -r
    autocmd BufWritePre *.bin endif
    autocmd BufWritePost *.bin if &bin | %!xxd
    autocmd BufWritePost *.bin set nomodified | endif
augroup END

" }}}


" Credits {{{
" * [Alexander Tsygankov](https://github.com/zenbro/dotfiles/blob/master/.nvimrc)
" * [Tim Clifford](https://github.com/tim-clifford/nvimrc/blob/master/init.vim)
" * [Mike Coutermarsh](https://github.com/mscoutermarsh/dotfiles/blob/master/vim/vimrc.symlink)
" * https://vim.fandom.com/wiki/
" }}}

" vim: set foldlevel=1:
