" =============================================================================
" 1. THE FIX: Stop Comments from messing up indentation
" =============================================================================
" This prevents Vim from jumping to column 0 or re-indenting when you type
" specific characters like # or start a comment.
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
autocmd FileType * setlocal cinkeys-=0#
autocmd FileType * setlocal indentkeys-=0#

" =============================================================================
" 2. General Settings
" =============================================================================
set nocompatible            " Disable compatibility with old Vi
filetype plugin indent on   " Enable filetype detection and plugins
syntax on                   " Enable syntax highlighting
set encoding=utf-8          " Force UTF-8

" =============================================================================
" 3. UI and Visuals
" =============================================================================
"set number                  " Show line numbers
"set relativenumber          " Show relative line numbers (great for jumps)
set cursorline              " Highlight the current line
" Clear the background color and force an underline
highlight CursorLine cterm=underline gui=underline ctermbg=NONE guibg=NONE
"set ruler                   " Show cursor position in footer
set showmatch               " Highlight matching parenthesis
set scrolloff=8             " Keep 8 lines of context above/below cursor
"set signcolumn=yes          " Always show the sign column (prevents text shifting)
set termguicolors           " Enable true colors support

" =============================================================================
" 4. Tabs and Indentation (Standard 4-space equivalent)
" =============================================================================
set tabstop=4               " Visual width of a tab
set shiftwidth=4            " Indentation amount for < and >
set softtabstop=4           " Backspace deletes 4 spaces acting like a tab
set expandtab               " Convert tabs to spaces
set smartindent             " New lines inherit indentation of previous lines
set autoindent              " Keep indent level from previous line

" =============================================================================
" 5. Search Behavior
" =============================================================================
set incsearch               " Search as you type
set hlsearch                " Highlight matches
set ignorecase              " Ignore case when searching...
set smartcase               " ...unless you type a capital letter

" =============================================================================
" 6. System Clipboard & Mouse
" =============================================================================
" Allows copy-pasting between Vim and your OS
" (Requires vim-gtk or vim-gnome installed on Linux, works default on Mac)
set clipboard=unnamedplus   
set mouse=a                 " Enable mouse support in all modes

" =============================================================================
" 7. Useful Key Mappings
" =============================================================================
" Set Leader key to Space (easier to reach than \)
let mapleader = " "

" Press Space + Enter to remove search highlights
nnoremap <Leader><CR> :nohlsearch<CR>

" Fast saving with Space + w
nnoremap <Leader>w :w<CR>

" Fast quitting with Space + q
nnoremap <Leader>q :q<CR>

" Easier split navigation (Ctrl + h/j/k/l)
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Indentation in visual mode (keeps selection active after indenting)
vnoremap < <gv
vnoremap > >gv
