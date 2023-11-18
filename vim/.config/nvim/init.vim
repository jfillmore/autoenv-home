" # COPILOT
" git clone https://github.com/github/copilot.vim ~/.config/nvim/pack/github/start/copilot.vim
" :Copilot setup
" :Copilot enable

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc

let g:python_indent = {}
" Better than in .vimrc: that version doesn't work quite as well
let g:python_indent.closed_paren_align_last_line = v:false
" Redundant with .vimrc, but just incase...
"let g:python_indent.open_paren = 'shiftwidth()'
"let g:python_indent.nested_paren = 'shiftwidth()'
"let g:python_indent.continue = 'shiftwidth()'

" https://github.com/neovim/neovim/issues/16569 - restore Y to yank full line
silent! unmap Y

