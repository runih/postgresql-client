if has('win32')
	call plug#begin('~/vimfiles/plugged')
else
	call plug#begin('~/.vim/plugged')
endif
" Install Plug by running the following command:
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

" Git plugins
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'Xuyuanp/nerdtree-git-plugin'
Plug 'junegunn/gv.vim'

" Markdown plugins
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown'

" Importanted plugins
Plug 'tpope/vim-surround'
Plug 'tomtom/tcomment_vim'
Plug 'xolox/vim-misc'
Plug 'xolox/vim-session'

" Search helpers
Plug 'ctrlpvim/ctrlp.vim' ", { 'tag': '1.79' }

" airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Colorschemes
Plug 'chankaward/vim-railscasts-theme'
Plug 'mhartington/oceanic-next'
Plug 'rafi/awesome-vim-colorschemes'
Plug 'rainglow/vim'
Plug 'nightsense/vimspectr'
Plug 'chriskempson/base16-vim'
Plug 'mswift42/vim-themes'
Plug 'mkarmona/colorsbox'
Plug 'xolox/vim-colorscheme-switcher'

Plug 'forevernull/vim-json-format'

" Css coloring
Plug 'ap/vim-css-color'

call plug#end()

set t_Co=256
"colorscheme gotham256
if has_key(g:plugs, 'vim-airline-themes') && isdirectory(g:plugs['vim-airline-themes'].dir)
	colorscheme lucius
endif

let g:session_autosave = 'no'

set relativenumber
set number
set history=700
set fileencoding=utf-8
set encoding=utf-8
set termencoding=utf-8
set fileencodings=utf-8,iso8859-1
set nocompatible
set showcmd
set undofile
let mapleader="§"
syntax on
set wildmenu
set wildmode=longest,full
set nowrap
set autoindent
set background=dark
set backspace=2
set backup
if has('win32')
	if !isdirectory($HOME . '/vimfiles/backup')
		call mkdir($HOME . '/vimfiles/backup', 'p')
	endif
else
	if !isdirectory($HOME . '/.vim/backup')
		call mkdir($HOME . '/.vim/backup', 'p')
	endif
endif
if has('win32')
	set backupdir=~/vimfiles/backup
else
	set backupdir=~/.vim/backup
endif
if has('win32')
	if !isdirectory($HOME . '/vimfiles/tmp')
		call mkdir($HOME . '/vimfiles/tmp', 'p')
	endif
else
	if !isdirectory($HOME . '/.vim/tmp')
		call mkdir($HOME . '/.vim/tmp', 'p')
	endif
endif
if has('win32')
	set dir=~/vimfiles/tmp
else
	set dir=~/.vim/tmp
endif
" The terminal needs to be in UTF-8
"set listchars=tab:▸\ ,eol:¬
"highlight NonText guifg=#4a4a59
"highlight SpecialKey guifg=#4a4a59
set ts=4 sts=4 sw=4 noexpandtab
set laststatus=2
set showtabline=0
set ruler

tnoremap <C-W><C-N> <C-\><C-N>

" Markdown options
let g:vim_markdown_toc_autofit = 1
let g:vim_markdown_folding_style_pythonic = 1

" Custom Statusline
set statusline =%0*\[%n]                          " buffer no.
set statusline+=\ %<%F\                           " file path
set statusline+=\ %y\                             " file type
set statusline+=\ %{''.(&fenc!=''?&fenc:&enc).''} " encoding 1
set statusline+=\ %{(&bomb?\",BOM\":\"\")}\       " encoding 2
set statusline+=\ %{&ff}\                         " format
set statusline+=\ \[%{v:register}]\               " active reg
set statusline+=\ %=chr(%b)\                      " current position char value
set statusline+=\ [0x%02.B]\                      " current position hex value
set statusline+=\ \ %l\ /\ %L\ (%3p%%)\           " line no. and pct
set statusline+=\ :%03v\                          " column no.
set statusline+=\ \ %m%r%w\ %P\ \                 " modified, ro, screen pos

" airline configuration
if has_key(g:plugs, 'vim-airline') && isdirectory(g:plugs['vim-airline'].dir)
	let g:airline_powerline_fonts = 1

	if !exists('g:airline_symbols')
		let g:airline_symbols = {}
	endif

	" unicode symbols
	let g:airline_left_sep = '»'
	let g:airline_left_sep = '▶'
	let g:airline_right_sep = '«'
	let g:airline_right_sep = '◀'
	let g:airline_symbols.linenr = '␊'
	let g:airline_symbols.linenr = '␤'
	let g:airline_symbols.linenr = '¶'
	let g:airline_symbols.branch = '⎇'
	let g:airline_symbols.paste = 'ρ'
	let g:airline_symbols.paste = 'Þ'
	let g:airline_symbols.paste = '∥'
	let g:airline_symbols.whitespace = 'Ξ'

	" airline symbols
	let g:airline_left_sep = ''
	let g:airline_left_alt_sep = ''
	let g:airline_right_sep = ''
	let g:airline_right_alt_sep = ''
	let g:airline_symbols.branch = ''
	let g:airline_symbols.readonly = ''
	let g:airline_symbols.linenr = ''
endif

if has("autocmd")
  " Enable file type detection
  filetype on

  " Syntax of these languages is fussy over tabs vs spaces
  autocmd FileType make setlocal ts=8 sts=8 sw=8 noexpandtab
  autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType ruby setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType eruby setlocal ts=2 sts=2 sw=2 expandtab

  " Customisations based on house-style (arbitrary)
  autocmd FileType html setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType css setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType javascript setlocal ts=2 sts=2 sw=2 expandtab
  autocmd FileType xml setlocal ts=2 sts=2 sw=2 expandtab

  autocmd FileType pgsql setlocal ts=4 sts=4 sw=4 expandtab
  autocmd FileType markdown setlocal ts=4 sts=4 sw=4 expandtab

  " Treat .rss files as XML
  autocmd BufNewFile,BufRead *.rss,*.atom set filetype=xml

  autocmd BufReadPost fugitive://* set bufhidden=delete

  " Treat .sql files as psql files
  autocmd BufNewFile,BufRead *.sql set filetype=pgsql

  " Treat .fish files as fish files
  autocmd BufNewFile,BufRead *.fish set filetype=fish
endif

if has('win32')
	set shell=powershell
else
	set shell=/bin/bash
endif

