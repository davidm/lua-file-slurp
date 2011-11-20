--[[ FILE README.txt

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

  Copy file_slurp.lua into your LUA_PATH.  You may optionally run
  "lua file_slurp.lua unpack" to unpack the module into individual files in
  an "out" subdirectory.   To subsequently install into LuaRocks, run
  "cd out && luarocks make file_slurp*.rockspec"
  
Related work

  Similar slurp functions have been implemented in Lua and other languages:
  
    http://rosettacode.org/wiki/Read_entire_file#Lua
    http://snippets.luacode.org/snippets/Write_a_string_to_a_file_123
    https://github.com/stevedonovan/Penlight/blob/master/lua/pl/utils.lua
        (readfile/writefile)
    http://search.cpan.org/perldoc?File::Slurp
    http://search.cpan.org/perldoc?Perl6::Slurp

Copyright

(c) 2011 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

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

--]]---------------------------------------------------------------------

-- file_slurp.lua
-- (c) 2011 David Manura.  Licensed under the same terms as Lua 5.1 (MIT license).

local FS = {_TYPE = 'module', _NAME = 'file_slurp', _VERSION = '000.003.2011-11-19'}

local function check_options(options)
  if not options then return {} end
  local bad = options:match'[^tTsap]'
  if bad then error('ASSERT: invalid option '..bad, 3) end
  local t = {}; for v in options:gmatch'.' do t[v] = true end
  if t.T and t.t then error('ASSERT: options t and T mutually exclusive', 3) end
  return t
end

local function fail(tops, err, code, filename)
  err = err..' [code '..code..']'
  err = err..' [filename '..filename..']' -- maybe make option
  if tops.s then return nil, err else error(err, 3) end
end

function FS.readfile(filename, options)
  local tops = check_options(options)
  local open = tops.p and io.popen or io.open
  local data, ok
  local fh, err, code = open(filename, 'r'..((tops.t or tops.p) and '' or 'b'))
  if fh then
    data, err, code = fh:read'*a'
    if data then ok, err, code = fh:close() else fh:close() end
  end
  if not ok then return fail(tops, err, code, filename) end
  if tops.T then data = data:gsub('\r', '') end
  return data
end

function FS.writefile(filename, data, options)
  local tops = check_options(options)
  local open = tops.p and io.popen or io.open
  local ok
  local fh, err, code = open(filename,
      (tops.a and 'a' or 'w') .. ((tops.t or tops.p) and '' or 'b'))
  if fh then
    ok, err, code = fh:write(data)
    if ok then ok, err, code = fh:close() else fh:close() end
  end
  if not ok then return fail(tops, err, code, filename) end
  return data
end

function FS.testfile(filename, options)
  local fh, err, code = io.open(filename, options or 'r')
  if fh then fh:close(); return true
  else return false, err .. ' [code '..code..']' end
end
  

-- This ugly line will delete itself upon unpacking the module.
if...=='unpack'then assert(loadstring(FS.readfile'file_slurp.lua':gsub('[^\n]*return FS[^\n]*','')))()end

return FS

-- Implementation footnotes: The (optional) stack `level` parameter on
-- functions like `error` and lack of automatic finalization (close) on scope
-- exit is less then elegant, but this module hides such details.

---------------------------------------------------------------------

--[[ FILE file_slurp-$(_VERSION)-1.rockspec

package = 'file_slurp'
version = '$(_VERSION)-1'
source = {
  -- IMPROVE?
  --url = 'https://raw.github.com/gist/1325400/file_slurp.lua', -- latest raw
  --url = 'https://raw.github.com/gist/1325400/$(GITVERSION)/file_slurp.lua',
  --url = 'https://gist.github.com/gists/1325400/download',
  --file = 'file_slurp-$(_VERSION).tar.gz'
  url = '$(URL)'
  md5 = '$(MD5)'
}
description = {
  summary = 'Easily read/write entire files from/to a string.',
  detailed =
    'Provides simple functions to read/write entire files from/to a string.',
  license = 'MIT/X11',
  homepage = 'https://gist.github.com/1325400',
  maintainer = 'David Manura'
}
dependencies = {}
build = {
  type = 'builtin',
  modules = {
    ['file_slurp'] = 'file_slurp.lua'
  }
}

--]]---------------------------------------------------------------------

--[[ FILE test.lua

-- test.lua - test suite for file_slurp module.

package.loaded.file_slurp = M
local FS = require 'file_slurp'

local function checkeq(a, b, e)
  if a ~= b then error(
    'not equal ['..tostring(a)..'] ['..tostring(b)..'] ['..tostring(e)..']')
  end
end

-- test round-trip write/read
FS.writefile('tmp1', 'test\nfile')
checkeq(FS.readfile('tmp1'), 'test\nfile')

-- test round-trip write/read text format
FS.writefile('tmp1', 'test\nfile', 't')
checkeq(FS.readfile('tmp1', 't'), 'test\nfile')

-- test round-trip write/read portable text format
FS.writefile('tmp1', 'test\r\nfile', 'T')
checkeq(FS.readfile('tmp1', 'T'), 'test\nfile')

-- test append
FS.writefile('tmp1', 'test\r\nfile')
FS.writefile('tmp1', 'test\r\nfile', 'a')
checkeq(FS.readfile('tmp1', 'T'), ('test\nfile'):rep(2))

-- test pipe
checkeq(FS.readfile('echo 123', 'ps'):gsub('[\r\n]*', ''), '123')
if not FS.readfile('echo', 'ps'):match('ECHO is') then -- posix
  FS.writefile('cat - > tmp1', 'ok', 'p')
  checkeq(FS.readfile('cat tmp1', 'p'), 'ok')
end

-- test raise
assert(not pcall(function() FS.writefile('', 'test') end))
assert(not pcall(function() FS.readfile('') end))

-- test no raise
local t = {FS.writefile('', 'test', 's')}
assert(not t[1] and t[2])
local t = {FS.readfile('', 's')}
assert(not t[1] and t[2])

-- test bad options
local _, e = pcall(function() FS.readfile('', 'tT') end)
checkeq(e:match't and T mutually exclusive' ~= nil, true, e)
local _, e = pcall(function() FS.readfile('', 'tX') end)
checkeq(e:match'invalid option X' ~= nil, true, e)

-- testfile and cleanup
assert(FS.testfile'tmp1')
assert(FS.testfile'tmp1', 'r')
os.remove'tmp1'
local ok, err = FS.testfile'tmp1'; assert(not ok and err)
assert(FS.testfile('tmp1', 'w'))
assert(FS.testfile'tmp1')
os.remove'tmp2'
assert(not FS.testfile'tmp2')

print 'OK'

--]]---------------------------------------------------------------------

--[[ FILE CHANGES.txt
000.004.2011-11-19
  Add `testfile` function.
  Change `_VERSION` to string.
  minor: Generalize unpack.lua; add CHANGES.txt

0.001001 2011-11-05
  Initial public release
--]]

--[[ FILE unpack.lua  -- return FS

-- This optional code unpacks files into an "out" subdirectory for deployment.
local M = FS
local name = arg[0]:match('[^/\\]+')
local code = FS.readfile(name, 'T')
code = code:gsub('%-*\n*%-%-%[%[%s*FILE%s+(%S+).-\n\n?(.-)%-%-%]%]%-*%s*',
 function(filename, text)
  filename = filename:gsub('%$%(_VERSION%)', M._VERSION)
  text = text:gsub('%$%(_VERSION%)', M._VERSION)
  if filename ~= 'unpack.lua' then
    if not FS.writefile('out/.test', '', 's') then os.execute'mkdir out' end
    os.remove'out/.test'
    print('writing out/' .. filename)
    FS.writefile('out/' .. filename, text)
  end
  return ''
end)
code = code:gsub('%-%- ?This ugly line[^\n]*\n[^\n]*\n', '')
print('writing out/' .. name)
FS.writefile('out/' .. name, code)
print('testing...')
assert(loadfile('out/test.lua'))()

--]]---------------------------------------------------------------------
