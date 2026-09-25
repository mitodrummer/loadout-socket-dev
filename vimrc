" socket-dev vimrc: sensible defaults for a TypeScript monorepo, plus fzf
" pickers. The fzf core plugin (fzf.vim beside this file, vendored from
" junegunn/fzf at the catalog's fzf version) provides fzf#run; the commands
" below are thin wrappers over it, so no plugin manager is needed.

set nocompatible
filetype plugin indent on
syntax on

set encoding=utf-8
set hidden
set number
set ruler
set showcmd
set laststatus=2
set wildmenu
set incsearch hlsearch ignorecase smartcase
set expandtab shiftwidth=2 softtabstop=2 tabstop=2 autoindent
set backspace=indent,eol,start
set scrolloff=4
set mouse=a
set updatetime=300
set noswapfile
set undofile undodir=~/.vim/undo//
silent! call mkdir(expand('~/.vim/undo'), 'p')

let mapleader = ' '

" The shell pane's FZF_DEFAULT_COMMAND (fd, hidden files, no .git) also feeds
" :FZF here, so both list the same files.
let g:fzf_layout = { 'down': '40%' }

" :Rg <pattern> greps the repo with ripgrep and opens the picked match at its
" line. Without an argument it asks for the pattern: listing every line of a
" 500-package workspace up front would stall the picker.
function! s:rg_sink(line) abort
  let parts = matchlist(a:line, '\v^([^:]+):(\d+):(\d+):')
  if empty(parts) | return | endif
  execute 'edit' fnameescape(parts[1])
  call cursor(str2nr(parts[2]), str2nr(parts[3]))
  normal! zz
endfunction
function! s:rg(pattern) abort
  let pattern = empty(a:pattern) ? input('Rg> ') : a:pattern
  if empty(pattern) | return | endif
  call fzf#run(fzf#wrap({
        \ 'source': 'rg --vimgrep --hidden --glob "!.git" --color=never -- '
        \           . shellescape(pattern),
        \ 'sink': function('s:rg_sink'),
        \ 'options': ['--delimiter', ':', '--prompt', 'Rg> ',
        \             '--preview', 'bat --color=always --highlight-line {2} {1}',
        \             '--preview-window', '+{2}-/2'],
        \ }))
endfunction
command! -nargs=* Rg call s:rg(<q-args>)

" :Buffers picks an open buffer.
command! Buffers call fzf#run(fzf#wrap({
      \ 'source': map(filter(range(1, bufnr('$')), 'buflisted(v:val)'), 'bufname(v:val)'),
      \ 'sink': 'edit',
      \ 'options': ['--prompt', 'Buffers> '],
      \ }))

nnoremap <silent> <C-p> :FZF<CR>
nnoremap <silent> <leader>f :FZF<CR>
nnoremap <silent> <leader>g :Rg<CR>
nnoremap <silent> <leader>b :Buffers<CR>
nnoremap <silent> <leader>w :Rg <C-r><C-w><CR>
nnoremap <silent> <Esc><Esc> :nohlsearch<CR>
