-- test.lua - test suite for file_slurp module.

-- 'findbin' -- https://github.com/davidm/lua-find-bin
package.preload.findbin = function()
  local M = {_TYPE='module', _NAME='findbin', _VERSION='0.1.1.20120406'}
  local script = arg and arg[0] or ''
  local bin = script:gsub('[/\\]?[^/\\]+$', '') -- remove file name
  if bin == '' then bin = '.' end
  M.bin = bin
  setmetatable(M, {__call = function(_, relpath) return bin .. relpath end})
  return M
end
package.path = require 'findbin' '/lua/?.lua;' .. package.path

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

