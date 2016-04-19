set nocompatible

" Plugs {{{
" Automatic installation {{{
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !mkdir -p ~/.vim/autoload
    silent !curl -fLo ~/.vim/autoload/plug.vim
          \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    au VimEnter * PlugInstall
endif
" }}}

call plug#begin('~/.vim/plugged')

" File explorer
Plug 'scrooloose/nerdtree'
" Git
Plug 'fugitive.vim'
Plug 'airblade/vim-gitgutter'
" Airline (status bar)
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" Ack (grep-like)
Plug 'mileszs/ack.vim'
" Executing commands in vim
Plug 'Shougo/vimproc'
Plug 'Shougo/vimshell'
" Easy commenting out
Plug 'tpope/vim-commentary'
" Color schemes
Plug 'chriskempson/base16-vim'
" Autocompletion
Plug 'Valloric/YouCompleteMe'
Plug 'rdnetto/YCM-Generator', { 'branch': 'stable' }
" Syntax error reporting
Plug 'scrooloose/syntastic'
" Tag listing
Plug 'majutsushi/tagbar'
" Multiple cursor selection
Plug 'terryma/vim-multiple-cursors'
" Language-specific {{{
Plug 'octol/vim-cpp-enhanced-highlight',{'for': 'cpp'}
Plug 'pangloss/vim-javascript'          " Javascript
Plug 'groenewege/vim-less'              " LESS
Plug 'rust-lang/rust.vim'               " Rust
Plug 'neovimhaskell/haskell-vim',       {'for': 'haskell'}
Plug 'eagletmt/neco-ghc',               {'for': 'haskell'}
Plug 'artoj/qmake-syntax-vim'           " Qmake
Plug 'jakub-olczyk/cpp.vim'             " Qt
Plug 'artur-shaik/vim-javacomplete2',   {'for': 'java'}
" }}}
call plug#end()

" }}}
" Leader {{{

let mapleader=','
let maplocalleader=','

" }}}
" Plugin settings {{{

" NERDTree
nnoremap <leader><leader> :NERDTreeToggle<esc>
let NERDTreeIgnore = ['\.pyc$', '\.hi', '\.o']

" Git
nnoremap <leader>gs :Gstatus<CR>
nnoremap <leader>gd :Gdiff<CR>
nnoremap <leader>gw :Gwrite<CR>
nnoremap <leader>gC :Gcommit<CR>
nnoremap <leader>gP :Git push<CR>

" Airline
let g:airline_powerline_fonts = 1
let g:airline_theme = 'powerlineish'

" Syntastic
let g:syntastic_auto_loc_list=1
let g:syntastic_check_on_open=1
let g:syntastic_cpp_check_header = 1
let g:syntastic_java_javac_classpath = "./lib/*.jar\n./src/"

" Tagbar
nnoremap <leader>l :TagbarToggle<CR>

" YouCompleteMe
nnoremap <F5> :YcmForceCompileAndDiagnostics<CR>
" Do not ask when starting vim
let g:ycm_confirm_extra_conf = 0
let g:syntastic_always_populate_loc_list = 1
let g:ycm_collect_identifiers_from_tags_files = 1
set tags+=./.tags

" make YCM compatible with UltiSnips (using supertab)
let g:ycm_key_list_select_completion = ['<C-n>', '<Down>']
let g:ycm_key_list_previous_completion = ['<C-p>', '<Up>']

" better key bindings for UltiSnipsExpandTrigger
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"

" Haskell autocompletion
let g:haskellmode_completion_ghc = 0

" }}}
" General options {{{
set number
set ruler
syntax on
filetype plugin indent on
set autoindent
set smartindent
set encoding=utf-8
set backspace=indent,eol,start
set modelines=0
set laststatus=2
set showcmd
if v:version > 703
  set undofile
  set undoreload=10000
  set undodir=~/.vim/tmp/undo/     " undo files
endif
set splitright
set splitbelow
set autoread " auto reload file on change
set foldmethod=syntax
set mouse=a
set scrolloff=8 "keep 8 lines below/above cursor
" }}}
" UI options {{{
if has('gui_running')
  set guifont=Source\Code\Pro\ Regular\ 10

  " Remove scrollbars
  set guioptions-=L
  set guioptions-=R
  set guioptions-=T
  set guioptions-=B

  " Remove toolbar
  set guioptions=-t
endif
" }}}
" Colorscheme {{{
set t_Co=256
let base16colorspace=256

set background=dark
colorscheme base16-eighties
syntax enable
" }}}
" Wrapping {{{
set nowrap
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set list
set listchars=tab:\ \ ,trail:·

function! s:setupWrapping()
  setlocal wrap
  setlocal wrapmargin=2
  setlocal textwidth=80
  if v:version > 703
    setlocal colorcolumn=+1
  endif
endfunction

" }}}
" Searching and movement {{{
" Use sane regexes.
nnoremap / /\v
vnoremap / /\v

set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch

" Easier to type, and I never use the default behavior. <3 sjl
noremap H ^
noremap L g_
" }}}
" Easy line moving {{{
function! MoveLineUp()
  call MoveLineOrVisualUp(".", "")
endfunction

function! MoveLineDown()
  call MoveLineOrVisualDown(".", "")
endfunction

function! MoveVisualUp()
  call MoveLineOrVisualUp("'<", "'<,'>")
  normal gv
endfunction

function! MoveVisualDown()
  call MoveLineOrVisualDown("'>", "'<,'>")
  normal gv
endfunction

function! MoveLineOrVisualUp(line_getter, range)
  let l_num = line(a:line_getter)
  if l_num - v:count1 - 1 < 0
    let move_arg = "0"
  else
    let move_arg = a:line_getter." -".(v:count1 + 1)
  endif
  call MoveLineOrVisualUpOrDown(a:range."move ".move_arg)
endfunction

function! MoveLineOrVisualDown(line_getter, range)
  let l_num = line(a:line_getter)
  if l_num + v:count1 > line("$")
    let move_arg = "$"
  else
    let move_arg = a:line_getter." +".v:count1
  endif
  call MoveLineOrVisualUpOrDown(a:range."move ".move_arg)
endfunction

function! MoveLineOrVisualUpOrDown(move_arg)
  let col_num = virtcol(".")
  execute "silent! ".a:move_arg
  execute "normal! ".col_num."|"
endfunction

nnoremap <silent> <A-Up> :<C-u>call MoveLineUp()<CR>
nnoremap <silent> <A-Down> :<C-u>call MoveLineDown()<CR>
inoremap <silent> <A-Up> <C-o>:call MoveLineUp()<CR>
inoremap <silent> <A-Down> <C-o>:call MoveLineDown()<CR>
"vnoremap <silent> <A-Up> :<C-u>call MoveVisualUp()<CR>
""vnoremap <silent> <A-Down> :<C-u>call MoveVisualDown()<CR>
xnoremap <silent> <A-Up> :<C-u>call MoveVisualUp()<CR>
xnoremap <silent> <A-Down> :<C-u>call MoveVisualDown()<CR>
" }}}
" Backups and undo {{{
set backupdir=~/.vim/tmp/backup/ " backups
set directory=~/.vim/tmp/swap/   " swap files
set backup                       " enable backups
set backupskip=/tmp/*,/private/tmp/*"
" }}}
" Folding {{{
" Space to toggle folds.
nnoremap <Space> za
vnoremap <Space> za

function! MyFoldText() " {{{
    let line = getline(v:foldstart)

    let nucolwidth = &fdc + &number * &numberwidth
    let windowwidth = winwidth(0) - nucolwidth - 3
    let foldedlinecount = v:foldend - v:foldstart

    " expand tabs into spaces
    let onetab = strpart('          ', 0, &tabstop)
    let line = substitute(line, '\t', onetab, 'g')

    let line = strpart(line, 0, windowwidth - 2 -len(foldedlinecount))
    let fillcharcount = windowwidth - len(line) - len(foldedlinecount)
    return line . ' ' . repeat(" ",fillcharcount) . ' ' . foldedlinecount . ' '
endfunction " }}}
set foldtext=MyFoldText()

" }}}
" I hate K {{{
nnoremap K <nop>
" }}}
" Filetype specific {{{
" Config files {{{
augroup config_files
  au!
  au BufRead {init.vim,.vimrc,vimrc} set foldmethod=marker
  au BufRead .zshrc set foldmethod=marker
  au BufRead .tmux.conf set foldmethod=marker
augroup END
" }}}
" C# {{{
augroup c_sharp
  au!
  au Filetype cs setlocal ts=4 sw=4 sts=4
augroup END
" }}}
" C {{{
augroup c_lang
  au!
  au Filetype cpp setlocal ts=4 sw=4 sts=4
  au Filetype c setlocal ts=4 sw=4 sts=4
augroup END
" }}}
" Haskell {{{
augroup haskell
  au!
  au Filetype haskell setlocal ts=4 sw=4 sts=4
  au FileType haskell setlocal omnifunc=necoghc#omnifunc
augroup END
" }}}
" HTML {{{
  au BufRead *.html setlocal ts=2 sw=2 sts=2
  au BufRead *.html set ft=html
" }}}
" Java {{{
augroup ft_java
  au!
  au Filetype java setlocal ts=4 sw=4 sts=4
  au FileType java let g:syntastic_java_javac_classpath = getcwd() . "/src/"
  au FileType java setlocal omnifunc=javacomplete#Complete
augroup END
" }}}
" Javascript {{{
augroup ft_javascript
  au!
  au BufNewFile,BufRead *.json set ft=javascript
augroup END
" }}}
" Latex {{{
augroup ft_latex
  au!

  au Filetype tex call s:setupWrapping()
  au Filetype tex setlocal spell

augroup END
" }}}
" Markdown {{{
augroup ft_markdown
  au!

  au BufNewFile,BufRead *.m*down setlocal filetype=markdown
  au BufNewFile,BufRead *.md setlocal filetype=markdown
  au Filetype markdown call s:setupWrapping()

  " Use <localleader>1/2/3 to add headings.
  au Filetype markdown nnoremap <buffer> <localleader>1 yypVr=
  au Filetype markdown nnoremap <buffer> <localleader>2 yypVr-
  au Filetype markdown nnoremap <buffer> <localleader>3 I### <ESC>
augroup END
" }}}
" Nginx {{{
augroup ft_nginx
  au!

  au FileType nginx setlocal ts=4 sts=4 sw=4

augroup END
" }}}
" Php {{{
augroup ft_php
  au!
  au BufRead *.inc setlocal ts=2 sw=2 sts=2
  au BufRead *.inc set ft=php
  au BufRead *.module setlocal ts=2 sw=2 sts=2
  au BufRead *.module set ft=php
augroup END
" }}}
" Python {{{
augroup ft_python
  au!

  au FileType python setlocal ts=4 sw=4 sts=4
  au FileType python setlocal wrap wrapmargin=2 textwidth=120 colorcolumn=+1

augroup END
" }}}
" Ruby {{{
augroup ft_ruby
  au!

  au FileType ruby call s:setupWrapping()

  " Thorfile, Rakefile, Vagrantfile and Gemfile are Ruby
  au BufRead,BufNewFile {Gemfile,Rakefile,Vagrantfile,Thorfile,config.ru} set ft=ruby

augroup END
" }}}
" Qt {{{
augroup ft_qt
  au!
  au BufRead *.qml set ft=javascript
  au BufRead *.qrc set ft=xml
  au BufRead *.qss set ft=css
augroup END
" }}}
" }}}
" Mappings {{{
nnoremap <silent> <C-l> :noh<CR><C-L>
" edit and source vimrc easily
nnoremap <leader>ev :vsplit $MYVIMRC<CR>
nnoremap <leader>sv :source $MYVIMRC<cr>

" rewrite file with sudo
cmap w!! w !sudo tee % >/dev/null
nnoremap _md :set ft=markdown<CR>

" open shell
nnoremap <leader>sh :VimShellPop<CR>

" Allow copy-pasting to X11 in visual mode
vnoremap <C-c> "+y
" }}}
" Tab completion for commands {{{
set wildmode=list:longest,list:full
set wildignore+=*.o,*.obj,.git,*.rbc,*.class,.svn,vendor/gems/*
" }}}
" some autocommands {{{
augroup unrelated_au
  au!

  " function to remove trailing whitespace without moving to it
  function! s:removeTrailingWhitespace()
    normal! ma
    :%s/\s\+$//e
    normal! `a
  endfunction

  " Remove trailing whitespace
  autocmd BufWritePre * :call s:removeTrailingWhitespace()

augroup END
"}}}
" Relative number toggle {{{
function! ToggleNumberRel()
  if &relativenumber
    setlocal number
  else
    setlocal relativenumber
  endif
endfunction

" Quickly toggle between relativenumber and number
noremap <leader>rr :call ToggleNumberRel()<CR>
" }}}
" Inline mathematics {{{
function! PipeToBc()
  let saved_unnamed_register = @@

  silent execute 'r !echo ' . shellescape(getline('.')) . ' | bc'
  normal! dw
  execute "normal! kA = \<ESC>p"
  normal! jdd

  let @@ = saved_unnamed_register
endfunction
nnoremap <leader>bc :call PipeToBc()<CR>
" }}}

" for some reason vim searches for something
:noh

