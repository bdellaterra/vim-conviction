" File:			conviction.vim
" Description:	Create mappings and menu items simultaneously
" Author:		Brian Dellatera <github.com/bdellaterra>
" Version:		0.1
" License:      Copyright 2015 Brian Dellaterra. This file is part of Conviction.
" 				Distributed under the terms of the GNU Lesser General Public License.
"				See the file LICENSE or <http://www.gnu.org/licenses/>.


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
" The map command mode. (Ex. - 'vnoremap')
function! MultiModeCmd( lhs, rhs, command )
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
" inserting/appending the characters for each mode.
"
" Instead of 'amap', a command starting with 'n' and followed by any of
" 'v','i','c' or 'o' can be given. This will behave similarly to 'amap' but
" only the specified modes will be auto-mapped.
"
" Example: 'nvinoremenu' will create non-recursive mappings for 'normal',
"          'visual' and 'insert' mode.
function! CreateMapping( lhs, rhs, ... )
	" Setup parameters
	let lhs = type(a:lhs) == type([]) ? a:lhs : [a:lhs]  " Coerce to list
	let rhs = a:rhs
	let command = get(a:000,0,'noremap')
	" For each key sequence...
	for l in lhs
		" Perform expansion of possible multi-mode command
		" into a list of real Vim commands
		let cmds = MultiModeCmd(l, rhs, command)
		" Execute each command in the  resulting list.
		for c in cmds
		  exe c
		endfor
	endfor
endfunction


" Create a new menu item.
"
" location:
" A path identifying where the new item will be listed
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
function! CreateMenuItem( location, rhs, ... )
	" Setup parameters
	let location = a:location
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
		call CreateMapping( helpArg, rhs, mapCmd )
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
	let cmds = MultiModeCmd(' ' . priority . location . label . help . ' ',
							\	rhs, command)
	" Execute each command in the resulting list.
	for c in cmds
	  exe c
	endfor
endfunction


" Copy working directory to the clipboard with mapping '<Leader>wd'
call CreateMenuItem('&Extra',
	\ ":silent! let @+=fnamemodify(bufname(''),':p:h')<CR>",
	\ 'Copy working directory to clipboard', '', ['<Leader>wd'],
	\ 'noremenu <silent>')


