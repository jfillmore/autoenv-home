" Vim Color File
" Maintainer: Michael Wiseman (thestarslookdown at gmail dot com)
" Last Change: August 11, 2005

" Color Help Screens
" h cterm-colors
" h group-name
" h highlight-groups

"      NR-16  NR-8  COLOR NAME ~
"      0    0    Black
"      1    4    DarkBlue
"      2    2    DarkGreen
"      3    6    DarkCyan
"      4    1    DarkRed
"      5    5    DarkMagenta
"      6    3    Brown, DarkYellow
"      7    7    LightGray, LightGrey, Gray, Grey
"      8    0*   DarkGray, DarkGrey
"      9    4*   Blue, LightBlue
"      10   2*   Green, LightGreen
"      11   6*   Cyan, LightCyan
"      12   1*   Red, LightRed
"      13   5*   Magenta, LightMagenta
"      14   3*   Yellow, LightYellow
"      15   7*   White


set bg=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "jonny"

"------------------------------------------------------------------------------
" Highlight Groups
"------------------------------------------------------------------------------

" Cursors
hi Cursor ctermbg=red guibg=#AA0000 ctermfg=white guifg=#FFFFFF
hi CursorIM ctermbg=red guibg=#AA0000 ctermfg=white guifg=#FFFFFF
hi CursorLine ctermbg=darkgrey guibg=#181818 gui=none cterm=none
hi CursorColumn ctermbg=darkgrey guibg=#1a1a1a

" Directory
"hi Directory

" The character under the cursor or just before it, if it is a paired bracket, and its match.
hi MatchParen ctermfg=lightred guifg=#FF5555 cterm=bold gui=bold

" Diff
"hi DiffAdd
"hi DiffChange
"hi DiffDelete
"hi DiffText

" Error Message
"hi ErrorMsg

" Vertical Split
hi VertSplit ctermbg=black guibg=black ctermfg=darkgrey guifg=#999999 term=none gui=none

" Status Line
hi StatusLine ctermfg=darkred guibg=#550000 ctermbg=white guifg=#FFFFFF
hi StatusLineNC ctermbg=grey guibg=#aaaaaa ctermfg=black guifg=#000000 cterm=none gui=none

" Folding
"hi Folded
"hi FoldColumn

" Sign Column
"hi SignColumn

" Incremental Search
"hi IncSearch

" Line Number
hi LineNr ctermfg=grey guifg=#666666 cterm=none gui=none

" Mode Message
"hi ModeMsg

" More Prompt
"hi MoreMsg

" Nontext
hi NonText ctermfg=darkred guifg=#009900

" Normal Text
hi Normal ctermfg=white guifg=#FFFFFF guibg=#000000

" Question
"hi Question

" Search
hi Search ctermbg=darkblue guibg=#0000AA ctermfg=lightcyan guifg=#55FFFF

" Special Key
"hi SpecialKey

" Tab bar
hi TabLineFill ctermfg=grey ctermbg=white
hi TabLine ctermfg=black ctermbg=grey
hi TabLineSel ctermfg=white ctermbg=darkgrey

" Title
"hi Title

" Visual
hi Visual ctermbg=darkblue guibg=#0000AA cterm=bold gui=bold

" warning message
"hi WarningMsg

" wild menu
"hi WildMenu

"------------------------------------------------------------------------------
" Group Name
"------------------------------------------------------------------------------

" Comments
hi Comment ctermfg=brown guifg=#AA5500

" Constants
hi Constant ctermfg=white guifg=#FFFFFF
hi String ctermfg=grey guifg=#AAAAAA
hi Character ctermfg=darkcyan guifg=#00AAAA
hi Number ctermfg=lightgreen guifg=#55FF55
hi Boolean ctermfg=lightgreen guifg=#55FF55
hi Float ctermfg=lightgreen guifg=#55FF55

" Identifier
hi Identifier ctermfg=darkgreen guifg=#00AA00
hi Function ctermfg=cyan guifg=#55FFFF

" Statement
hi Statement ctermfg=darkcyan guifg=#00AAAA
hi Conditional ctermfg=darkcyan guifg=#00AAAA
hi Repeat ctermfg=darkcyan guifg=#00AAAA
hi Label ctermfg=magenta guifg=#AA00AA
hi Operator ctermfg=grey guifg=#AAAAAA
hi Keyword ctermfg=cyan guifg=#55FFFF
" hi Exception

" PreProc
"hi PreProc
" hi Include
" hi Define
" hi Macro
" hi PreCondit

" Type
hi Type ctermfg=darkgreen guifg=#00AA00
hi StorageClass ctermfg=blue guifg=#0000AA
hi Structure ctermfg=darkcyan guifg=#00AAAA
hi Typedef ctermfg=magenta guifg=#AA00AA

" Special
hi Special ctermfg=magenta guifg=#AA00AA
hi SpecialChar ctermfg=magenta guifg=#AA00AA
hi Tag ctermfg=magenta guifg=#AA00AA
hi Delimiter ctermfg=white guifg=#FFFFFF
hi SpecialComment ctermfg=white guifg=#FFFFFF
hi Debug ctermfg=white guifg=#FFFFFF

" Underlined
hi Underlined cterm=underline gui=underline ctermfg=darkcyan guifg=#00AAAA

"Ignore
"hi Ignore

" Error
"hi Error

" Todo
hi Todo ctermfg=yellow guifg=#FFFF55 ctermbg=darkred guibg=#AA0000

" PMenu
hi Pmenu ctermfg=grey guifg=#AAAAAA ctermbg=darkblue guibg=#0000AA
hi PmenuSel ctermfg=black guifg=#000000 cterm=underline gui=underline ctermbg=grey guibg=#AAAAAA
hi PmenuSbar ctermfg=lightcyan guifg=#55FFFF ctermbg=black guibg=#000000
hi PmenuThumb ctermfg=cyan guifg=#55FFFF ctermbg=darkblue guibg=#0000AA
