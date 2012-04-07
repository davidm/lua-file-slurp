LUA MODULE

  file_slurp v$(_VERSION) - Easily read/write entire files from/to a string.

SYNOPSIS

  -- Example to convert tabs to spaces in a file.
  local FS = require 'file_slurp'
  local s = FS.readfile 'foo.txt'
  s = s:gsub('\t', '    ')
  FS.writefile('foo.txt', s)
  -- Also supports ascii/binary, error policies, and pipes:
  s = FS.readfile('ls -la', 'p')
  -- test for file readable
  assert(FS.testfile'foo.txt')

DESCRIPTION

  This module provides simple functions to read/write entire files from/to
  a string.
 
API
  
  FS.readfile(filename [, options]) --> data

    Reads contents of file with path `filename` and returns as string `data`.
    Optional string of option flags (`options`) may be passed as described
    below.
    
    options:
    't' - read/write in text mode (i.e. converting newlines from/to native OS
          formats) rather than the default binary mode.
    'T' - read/write in binary mode but remove carriage return '\r' characters
          on reading.  This is a more portable form of 't'.
          't' and 'T' are mutually exclusive.
    's' - silence/supress raising errors (described below).
    'a' - append to file rather than overwrite.  Should only be used for write.
    'p' - open a pipe.  `filename` is a command to execute.  'a'/'t' ignored.
    
    Error Handling: Normally, this function will raise an error string on
    failure.  The error string will include the error message, error code, and
    file name.  If 's' is included in `options` then (nil, error_string) is
    returned instead.

  FS.writefile(filename, data [, options])

    Writes contents of string data to file with path `filename` (overwriting
    or creating if necessary).  `options` and error handling are the same as
    for `FS.readfile`.

  FS.testfile(filename [, options]) --> true | false, err

    Tests whether `io.open(filename, options)` succeeds.  Returns `true` on
    success, else `false` and error string (message and error code).
    `options` defaults to 'r' (test readable).  This function does not
    cleanup on write tests.  Warning: testing whether a file is readable
    is not always the same as testing whether a file exists.
    
DESIGN NOTES

  The functions by default operate in binary mode, which is safest when it's
  not known whether the user wants to write in binary or text files.  Even
  if reading text files, it is common today to read Unix text files downloaded
  from the Internet on Windows and vice-versa, and programs should be robust
  for whatever input is provided, which requires using binary mode on text
  files.  The 'T' option will remove '\r' characters on input while reading
  in binary mode.

  The default error handling behavior is to raise on error, but this can be
  changed with the 's' option to return errors instead.  The philosophy
  behind this default is that errors should not be ignored in quick scripts
  that pay little attention to error handling.  However, programs that want
  to pay attention to error handling themselves can afford adding an explicit
  option to enable this.
  
  The module is designed to be self-contained, without much overhead, robust,
  and versatile enough to be used in most situations.  It may be loaded
  as a module or just copied and pasted.

INSTALLATION

  To install with LuaRocks:
  
    luarocks install file-slurp

  Otherwise, download file_slurp.lua:
  
    https://github.com/davidm/lua-file-slurp

  You may simply copy file_slurp.lua into your LUA_PATH.
  
  Otherwise:
  
     make test
     make install   (or make install-local)  -- to install in LuaRocks
     make remove  (or make remove-local)  -- to remove from LuaRocks

Related work

  Similar slurp functions have been implemented in Lua and other languages:
  
    http://rosettacode.org/wiki/Read_entire_file#Lua
    http://snippets.luacode.org/snippets/Write_a_string_to_a_file_123
    https://github.com/stevedonovan/Penlight/blob/master/lua/pl/utils.lua
        (readfile/writefile)
    http://search.cpan.org/perldoc?File::Slurp
    http://search.cpan.org/perldoc?Perl6::Slurp

Copyright

(c) 2011-2012 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

