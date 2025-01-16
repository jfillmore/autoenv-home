" neovim notes:
" - init: python3 -m pip install --upgrade pynvim
" - issues
"   - expand tabs requires overrides for yaml files
"   - `ga` auto-formatting does not retain '# " comment leaders
"


" --- Plugins ---
" https://github.com/junegunn/vim-plug
" TL;DR: run `:PlugInstall` and `:PlugUpdate` to install/update plugins below:

call plug#begin('~/.vim/plugged')

Plug 'https://github.com/davidhalter/jedi-vim'
"Plug 'https://github.com/Vimjas/vim-python-pep8-indent'
Plug 'https://github.com/ctrlpvim/ctrlp.vim'

if has('nvim')
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plug 'nvim-treesitter/playground'
endif

call plug#end()


" `:verbose set tabstop? softtabstop? shiftwidth?` = help figure out settings

" --- Plugin Settings ---
let g:jedi#use_splits_not_buffers = "right"
let g:jedi#popup_on_dot = 0  " avoid annoying/slow automatic completion
let g:jedi#popup_select_first = 0  " auto-select first match on forward autocomplete (but what about back?)
let g:jedi#show_call_signatures = "2"
let g:jedi#show_call_signatures_delay = 200


" --- General ---
set backspace=indent,eol,start
set cinoptions+=#1 cinkeys-=0#
set cursorcolumn
set cursorline
set encoding=utf-8
set guioptions-=T
set guioptions-=m
set hlsearch
set ignorecase
set incsearch
set modeline
set modelines=5
set nocompatible
set redrawtime=8000
set ruler
set viminfo='20,\"50

set noshowmode  " required for show_call_signatures = 2
set showmatch
set number " setting both causes the current line to be the line number, not 0
set relativenumber


" --- Indendation ---
set cindent
set smartindent  " assumes c-style which forces #-style comments to be left-aligned
set autoindent
filetype indent on  " off = python indenting goes wacky

" avoid double indentation shenanigans
let g:pyindent_nested_paren = '&sw'
let g:pyindent_open_paren = '&sw'
let g:pyindent_continue = '&sw'
" ~/.config/nvim/init.vim version works more reliably
"let g:pyindent_disable_parentheses_indenting = 1

" stop yaml from indenting automatically when commenting out a line
augroup filetype_yaml
  autocmd!
  autocmd BufEnter *.yaml,*.yml
  \ setlocal indentkeys-=0#
augroup END


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
" don't force comments to start of line when smartindent is on
inoremap # x#
" another attempt to keep comments from having strange auto-indentation patterns
set indentkeys-=0#


" --- Generic Shortcuts ---
" make it easy to paste formatted text
nnoremap <F4> :set paste!<CR>
" show/hide relative line numbers
nnoremap <F5> :set relativenumber!<CR>
" show/hide search highlighting
nnoremap <F6> :set hlsearch!<CR>
" refresh syntax highlighting
nnoremap <F9> :syntax sync fromstart<CR>
" faster split manipulation
nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>
nnoremap <C-C> <C-W><C-C>
nnoremap <leader>. :source ~/.vimrc<CR>
nnoremap <leader>! /[^\x00-\x7F]<CR>
nnoremap <leader>  :%s/ \+$//e<CR>


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
autocmd BufRead,BufNewFile *.dhtml set syntax=html
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o formatoptions-=t
" neovim somehow ends up disabling this, so force it
autocmd FileType *.yaml set expandtab
autocmd FileType *.yml set expandtab
colorscheme jonny
let c_minlines=4096
let &colorcolumn="81"
