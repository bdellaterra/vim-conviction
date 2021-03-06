" File:                 conviction.vim
" Description:  Create mappings and menu items simultaneously
" Author:               Brian Dellatera <github.com/bdellaterra>
" Version:              0.1.1
" License:      Copyright 2015 Brian Dellaterra. This file is part of Conviction.
"                               Distributed under the terms of the GNU Lesser General Public License.
"                               See the file LICENSE or <http://www.gnu.org/licenses/>.


" Guard against repeat sourcing of this script
if exists('g:loaded_convictionPlugin')
    finish
end
let g:loaded_convictionPlugin = 1


" Helper function to convert multi-mode map/menu commands
" to a list of equivalent real commands.
"
" lhs:
" The left-hand-side component of a map command
"
" rhs:
" The right-hand-side component of a map command
"
" command:
" The map command mode. (Ex. - 'nvnoremap') If an 'n' is present for normal-mode
" it must come first to disambiguate from the 'n' in 'noremap' commands
function! s:MultiModeCmd( lhs, rhs, command )
    " Setup parameters
    let [lhs, rhs, command] = [a:lhs, a:rhs, a:command]
    " Pad 'lhs' with spaces
    let lhs = ' ' . lhs . ' '
    " 'a' commands are equivalent to 'nvico' multi-commands
    if command =~ '\v^a(nore)?'
        let command = substitute(command,'^a','nvico','')
    endif
    " If a multi-mode command was given... (Not native to Vim)
    if command =~ '\v^n[vico]+(nore)?.*'
                \ && command !~ '\v^nore'
        " Create an equivalent list of real commands, with 'rhs'
        " surrounded by characters appropriate to the map mode.
        let ncmd = substitute(command,'\v^n[vico]+','n','')
        let cmds = [ ncmd . lhs . rhs ]
        if command =~ '\v^n[ico]*v[ico]*'
            let vcmd = substitute(command,'\v^n[vico]+','v','')
            let cmds += [ vcmd . lhs . '<C-c>'.rhs.'<C-\><C-g>' ]
        endif
        if command =~ '\v^n[vco]*i[vco]*'
            let icmd = substitute(command,'\v^n[vico]+','i','')
            let cmds += [ icmd . lhs . '<C-\><C-o>'.rhs ]
        endif
        if command =~ '\v^n[vio]*c[vio]*'
            let ccmd = substitute(command,'\v^n[vico]+','c','')
            let cmds += [ ccmd . lhs . '<C-c>'.rhs.'<C-\><C-g>' ]
        endif
        if command =~ '\v^n[vic]*o[vic]*'
            let ocmd = substitute(command,'\v^n[vico]+','o','')
            let cmds += [ ocmd . lhs . '<C-c>'.rhs.'<C-\><C-g>' ]
        endif
        " Otherwise...
    else
        " List contains a single mapping using the command as given.
        let cmds = [ command . lhs . rhs ]
    endif
    " Return list of commands
    return cmds
endfunction


" Create a new mapping using the given lhs and rhs components.
"
" lhs:
" A key-sequence (string) or series of key-sequences (list of strings)
" that will be mapped to trigger the associated characters in rhs
"
" rhs:
" A string of characters that will occur in place of the mapped key-sequence.
"
" command:
" Optional map command used to create the mapping. Defaults to 'noremap'.
" New commands 'amap' and 'anoremap' are also supported as a matter of
" convenience.  These function similar to the amenu commands,
" inserting/appending characters for each mode.
"
" Instead of 'amap', a command starting with 'n' and followed by any of
" 'v','i','c' or 'o' can be given. This will behave similarly to 'amap' but
" only the specified modes will be auto-mapped.
"
" Example: 'nvinoremenu' will create non-recursive mappings for 'normal',
"          'visual' and 'insert' mode.
function! conviction#CreateMapping( lhs, rhs, ... )
    " Setup parameters
    let lhs = type(a:lhs) == type([]) ? a:lhs : [a:lhs]  " Coerce to list
    let rhs = a:rhs
    let command = get(a:000,0,'noremap')
    " For each key sequence...
    for l in lhs
        " Perform expansion of possible multi-mode command
        " into a list of real Vim commands
        let cmds = s:MultiModeCmd(l, rhs, command)
        " Execute each command in the  resulting list.
        for c in cmds
            exe c
        endfor
    endfor
endfunction


" Create a new menu item.
"
" location:
" A path identifying where the new item will be listed. For convenience,
" spaces are escaped, but no other special characters are handled.
"
" rhs:
" A string of characters that will occur when the menu item is invoked.
" (Like the rhs in a mapping)
"
" label:
" Optional name or label to be shown in the menu drop-down. This will
" be auto-generated if nothing is specified or an empty-string is passed.
" For convenience, spaces are escaped, but no other special characters
" are handled.
"
" priority:
" Optional priority component that can be used to control ordering of
" menu items
"
" help:
" Optional text tip placed to the right of the label. This is usually the
" key-sequence for an associated mapping that triggers the same behavior
" as the menu item. If 'help' is a list of one-or-more key-sequences, this
" function will map each of them to the same action as the menu item.
" (By calling CreateMapping() with 'help' as the 'lhs')
"
" command:
" Optional menu command used to create the menu item. Defaults to 'noremenu'.
" Multi-mode menu commands are supported. (See CreateMapping() above
" for details.)
function! conviction#CreateMenuItem( location, rhs, ... )
    " Setup parameters
    let location = escape( a:location, ' ' )    " Escaping spaces
    let rhs = a:rhs
    let label = escape( get( a:000, 0, '' ), ' ' )    " Escaping spaces
    let priority = get( a:000, 1, '' )
    let helpArg = get( a:000, 2, '' )
    let command = get( a:000, 3, 'noremenu' )
    " Create mappings also if 'help' argument is a list
    if type(helpArg) == type([])
        " Convert menu command to equivalent map command
        let mapCmd = substitute( command, '^\w*\zsmenu\>', 'map', 'i' )
        " Call CreateMapping() using 'help' as the 'lhs'
        call conviction#CreateMapping( helpArg, rhs, mapCmd )
    endif
    " Use only the first list item as the help tip.
    let help = type(helpArg) == type([]) ? get( helpArg, 0, '' ) : helpArg
    " Add trailing dot to 'location' if necessary
    let location = substitute(location, '\.\?$', '.', '')
    " If no label is specified...
    if label == ''
        " Remove extraneous syntax from 'rhs' to make 'label'
        let label = matchstr( rhs, '^:\zs\w\+\ze\(\s*\|<CR>\)' )
    endif
    " Add trailing space to 'priority' if present
    if priority != ''
        let priority .= ' '
    endif
    " Add Tab before help text if present
    if help != ''
        let help = '<Tab>' . help
    endif
    " Throw exception if label is invalid
    if label == '' | throw "Invalid name for menu item" | endif
    " Perform expansion of possible multi-mode command
    " into a list of real Vim commands
    let cmds = s:MultiModeCmd(' ' . priority . location . label . help . ' ',
                \       rhs, command)
    " Execute each command in the resulting list.
    for c in cmds
        exe c
    endfor
endfunction


" Define Regexes
let s:regex = {}
let s:regex.count = '^\s*\d\+'    " Optional 'count' argument
let s:regex.trim = '^\s*\(.*\)\s*$'
let s:regex.special = '\(\%(\s*<[^>]*>\)*\)\?'    " Regex for special menu/map arguments like <silent>
let s:regex.menu = '\s*\(\%(\%(\\ \)\|\S\)*\)'    " Regex for menu path
let s:regex.dquote = '\%("\%([^"]\|\\\@<="\)*"\)'    " Regex for double-quoted string
let s:regex.squote = "\\%('\\%([^']\\|''\\)*'\\)"    " Regex for single-quoted string
let s:regex.string = '\s*\(' . s:regex.squote . '\|' . s:regex.dquote . '\)'
let s:regex.label = s:regex.string
let s:regex.help = s:regex.string
let s:regex.lhs = '\s*\(\S\+\)'    " FIXME: Need more robust regex for lhs
let s:regex.rhs = '\s*\(.*\)'

" Helper function to enable command-line [NVICO]Menumap command
" NOTE: Parsing strings out of command-line is dubious and may only work with simple cases 
function! conviction#CmdMenumap(cmdStr, ...)
    let mode = get(a:000, 0, '')
    let priority = get(a:000, 1, '')
    let createMaps = get(a:000, 2, 1)
    let cmdStr = a:cmdStr
    let cmdStr = substitute(cmdStr, s:regex.count, '', '')    " Consume optional 'count' argument
    let cmdStr = substitute(cmdStr, s:regex.trim, '\1', '')    " trim whitespace
    let helpListStart = createMaps ? '[' : ''
    let helpListEnd = createMaps ? ']' : ''
    " (...Note that submatch captures occur in s:regex entries defined above)
    let special = substitute(cmdStr, '^' . s:regex.special . '.*', '\1', '')
    let menu = '"' . escape(substitute(cmdStr, '^' . s:regex.special . s:regex.menu . '.*', '\2', ''), '"') . '"'
    let label = substitute(cmdStr, '^' . s:regex.special . s:regex.menu . s:regex.label . '.*', '\3', '')
    let help = helpListStart . substitute(cmdStr, '^' . s:regex.special . s:regex.menu . s:regex.label . s:regex.help . '.*', '\4', '') . helpListEnd
    let rhs = '"' . escape(substitute(cmdStr, '^' . s:regex.special . s:regex.menu . s:regex.label . s:regex.help . s:regex.rhs, '\5', ''), '\"') . '"'    " Remainder of string is the 'rhs'
    let maybeSubmenuLevels =  repeat('0.', 1+count(split(menu, '\zs'), '.'))    " Build numeric sublevels (Actual number doesn't matter for predefined menu levels)
    let maybeSpecial = special == '' ? '' : substitute(special, '^\zs\ze\S', ' ', '')  " add leading space
    let maybePriority = priority == '' ? ", ''" : ', "' . escape(maybeSubmenuLevels . priority, '\"') . '"'    " Priority mode is required arg defaulting to empty string
    let maybeMode = mode == '' ? '' : ', "' . escape(mode, '\"') . maybeSpecial . '"'    " Optional command-mode arg
    let createCmd = 'call  conviction#CreateMenuItem(' . menu . ', ' . rhs . ', ' . label . maybePriority . ', ' . help . maybeMode . ')'
    exe createCmd
endfunction


" Helper function to enable command-line [NVICO]Menu commands
" NOTE: Parsing strings out of command-line is dubious and may only work with simple cases 
function! conviction#CmdMenu(cmdStr, ...)
    let mode = get(a:000, 0, '')
    let priority = get(a:000, 1, '')
    let cmdStr = a:cmdStr
    let createMaps = 0
    call conviction#CmdMenumap(a:cmdStr, mode, priority, createMaps)
endfunction


" Helper function to enable command-line [NVICO]Map commands
" NOTE: Parsing strings out of command-line is dubious and may only work with simple cases 
function! conviction#CmdMap(cmdStr, ...)
    let mode = get(a:000, 0, '')
    let cmdStr = a:cmdStr
    " (...Note that submatch captures occur in s:regex entries defined above)
    " let special = substitute(cmdStr, '^' . s:regex.special . '.*', '\1', '')
    let lhs = substitute(cmdStr, '^' . s:regex.lhs . '.*', '\1', '')    " TODO: Deal w/ special map mods? Need to escape anything?
    let rhs = substitute(cmdStr, '^' . s:regex.lhs . s:regex.rhs, '\2', '')    " Remainder of string is the 'rhs'
    call conviction#CreateMapping(lhs, rhs, mode)
endfunction


" Returns unique items from a sorted list
function! s:SortUnique(list)
    let list = sort(deepcopy(a:list))
    let i = 0
    while i < len(list) - 1
        if list[i] == list[i+1]
            call remove(list, i+1)
        endif
        let i += 1
    endwhile
    return list
endfunction


" Return a list containing all permutations of a given string
function! conviction#Permutations(string, ...)
    if len(a:string) <= 1
        return [a:string]    " RETURN
    elseif len(a:string) == 2
        let chars = split(a:string, '\zs')
        let perms = chars + [a:string] + [join(reverse(chars), '')]
        return s:SortUnique(perms)    " RETURN
    else
        let perms = []
        let chars = split(a:string, '\zs')
        let i = 0
        while i < len(chars)
            let subPerms = []
            let tail = deepcopy(chars)
            let head = remove(tail, i)    " 'tail' is affected by the remove
            for p in conviction#Permutations(join(tail, ''))
                call add(subPerms, p)
            endfor
            let morePerms = map(deepcopy(subPerms), '"' . escape(head, '\"') . '" . v:val')
            let perms = perms + subPerms + morePerms
            let i += 1
        endwhile
        return s:SortUnique(perms)
    endif
endfunction


" Generate menu/map commands
let s:commandPermutations = conviction#Permutations('vico')
let s:commandPermutations = ['a', 'n'] + map(deepcopy(s:commandPermutations), '"n" . v:val') + s:commandPermutations

exe 'command! -count=500 -complete=menu -nargs=+ Menumap call conviction#CmdMenumap(<q-args>, "menu", "<count>")'
exe 'command! -count=500 -complete=menu -nargs=+ Noremenumap call conviction#CmdMenumap(<q-args>, "noremenu", "<count>")'
for s:mode in s:commandPermutations
    " Normal Version
    exe 'command! -count=500 -complete=menu -nargs=+ ' . toupper(s:mode) . 'Menumap'
                \ .     ' call conviction#CmdMenumap(<q-args>, "' . s:mode . 'menu", "<count>")'
    " 'Nore' version
    exe 'command! -count=500 -complete=menu -nargs=+ ' . toupper(s:mode) . 'Noremenumap'
                \ .     ' call conviction#CmdMenumap(<q-args>, "' . s:mode . 'noremenu", "<count>")'
endfor

exe 'command! -count=500 -complete=menu -nargs=+ Menu call conviction#CmdMenu(<q-args>, "menu", "<count>")'
exe 'command! -count=500 -complete=menu -nargs=+ Noremenu call conviction#CmdMenu(<q-args>, "noremenu", "<count>")'
for s:mode in s:commandPermutations
    " Normal Version
    exe 'command! -count=500 -complete=menu -nargs=+ ' . toupper(s:mode) . 'Menu'
                \ .     ' call conviction#CmdMenu(<q-args>, "' . s:mode . 'menu", "<count>")'
    " 'Nore' version
    exe 'command! -count=500 -complete=menu -nargs=+ ' . toupper(s:mode) . 'Noremenu'
                \ .     ' call conviction#CmdMenu(<q-args>, "' . s:mode . 'noremenu", "<count>")'
endfor

exe 'command! -complete=mapping -nargs=+ Map call conviction#CmdMap(<q-args>, "map")'
exe 'command! -complete=mapping -nargs=+ Noremap call conviction#CmdMap(<q-args>, "noremap")'
for s:mode in s:commandPermutations
    " Normal Version
    exe 'command! -complete=mapping -nargs=+ ' . toupper(s:mode) . 'Map'
                \ .     ' call conviction#CmdMap(<q-args>, "' . s:mode . 'map")'
    " 'Nore' version
    exe 'command! -complete=mapping -nargs=+ ' . toupper(s:mode) . 'Noremap'
                \ .     ' call conviction#CmdMap(<q-args>, "' . s:mode . 'noremap")'
endfor


" Define the Ex-mode commands such as ANoremenumap
" (Without this the first command invocation may fail with an error)
" NOTE: Calling any autoload-function will source this script,
" thus defining the Ex commands with no additional work required.
function conviction#DefineExCommands()
    return
endfunction

