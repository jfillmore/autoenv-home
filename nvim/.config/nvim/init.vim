" # COPILOT
" git clone https://github.com/github/copilot.vim ~/.config/nvim/pack/github/start/copilot.vim
" :Copilot setup
" :Copilot enable

" https://github.com/neovim/neovim/issues/16569 - restore Y to yank full line
unmap Y

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath
source ~/.vimrc
