" --- Plugins ---
filetype off
execute pathogen#infect()
call pathogen#helptags()
filetype plugin indent on


" --- General ---
set backspace=indent,eol,start
set cinoptions+=#1 cinkeys-=0#
set cursorcolumn
set cursorline
set encoding=utf-8
set guioptions-=T
set guioptions-=m
set hlsearch
set incsearch
set modeline
set modelines=5
set nocompatible
set redrawtime=8000
set ruler
set viminfo='20,\"50
set wrap

set showmatch
set number " setting both causes the current line to be the line number, not 0
set relativenumber


" --- Indendation ---
"set smartindent  " assumes c-style which forces #-style comments to be left-aligned
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
"inoremap # x# " don't force comments to start of line when smartindent is on
fixdel


" --- Shortcuts ---
" make it easy to paste formatted text
nnoremap <F4> :set paste!<CR>
" show/hide relative line numbers
nnoremap <F5> :set relativenumber!<CR>
" show/hide search highlighting
nnoremap <F6> :set hlsearch!<CR>
" refresh syntax highlighting
nnoremap <F9> :syntax sync fromstart<CR>
" faster moves between splits
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>


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
autocmd BufEnter,BufRead,BufNewFile * match BadWhitespace /\s\+$/
autocmd BufRead *.txt set tw=78
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o formatoptions-=t
colorscheme jonny
let c_minlines=4096
let &colorcolumn="80,".join(range(120,999),",")
