" --- Plugins ---
filetype off
execute pathogen#infect()
call pathogen#helptags()
" causing indentation issues on JS
"filetype plugin indent on

" --- General ---
set nocompatible
set viminfo='20,\"50
set encoding=utf-8
set hlsearch
set incsearch
set cursorline
set guioptions-=m
set guioptions-=T
set ruler
set wrap
set backspace=indent,eol,start

set showmatch
set number " setting both causes the current line to be the line number, not 0
set relativenumber

" --- Indendation ---
set smartindent
set autoindent

" --- Spaces/Tabs ---
set softtabstop=4
set shiftwidth=4
set tabstop=4
set smarttab
set expandtab
set noeol " no EOL at end of files

" --- Hacks/Fixes ---
" disable auto-indentation/commenting when adding to lines below existing comments
set formatoptions-=cro
" don't force comments to start of line
inoremap # x#
fixdel

" --- Shortcuts ---
" make it easy to paste formatted text
noremap <F4> :set paste!<CR>
" show/hide relative line numbers
noremap <F5> :set relativenumber!<CR>
" show/hide search highlighting
noremap <F6> :set hlsearch!<CR>
" refresh syntax highlighting
noremap <F9> :syntax sync fromstart<CR>

" --- Macros ---
" git conflict highlighting
let @h = '/^\(=======\|<<<<<<<\|>>>>>>>\)'
" git conflict - keep top portion of conflict
let @t = 'ddnVnxnz.'
" git conflict - keep bottom portion of conflict
let @b = 'Vnxnddnz.'
" python breakpoint
let @x = 'Oimport pdb; pdb.set_trace()'

" --- Style ---
syntax on
autocmd BufEnter * :syntax sync fromstart
colorscheme jonny
autocmd BufRead *.txt set tw=78
let c_minlines=4096
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o formatoptions-=t
let &colorcolumn="80,".join(range(120,999),",")
