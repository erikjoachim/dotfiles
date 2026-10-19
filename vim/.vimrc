if filereadable(expand('$VIMRUNTIME/defaults.vim'))
  source $VIMRUNTIME/defaults.vim
endif

set belloff=all

augroup dotfiles_gitcommit
  autocmd!
  autocmd FileType gitcommit setlocal formatoptions-=t
augroup END
