
-- some test cases specially crafted to test optimizations edge cases
-- TODO: this checks only general correctness, not whether optimizations
--       really occurs.

local m = require"lpeg"
local p

-- the ITestVector is emited only when there is enough alternatives
p = m.P(false)
for i=97, 122 do -- all ascii lowercase
  p = p + m.P(string.char(i, i, i))
end
p = (p * m.P'e'):optimize()
assert(p:match'aaae')
assert(p:match'bbbe')
assert(p:match'ccce')
assert(p:match'ddde')
assert(not p:match'aaa')

-- redoundant pattern
p = (m.P'aaa' + m.P'bbb' + m.P'acc' + m.P'ddd'):optimize()
assert(p:match'acc')

print "Tree optimizer tests"
-- check that set is copied correctly
-- this may actually pass, only a run with valgrind will exhibit the issue
assert(m.S('abcde'):optimize():match'b')
assert((m.S('abcde') * m.P'f'):optimize():match'bf')

-- this specific type of patterns causes the optimized tree to be bigger than
-- the one from the previous pass at some point. This breaks the original
-- assumption size(optimized) <= size(original) that was made before.
assert((m.P'abc' + m.P'abc'):optimize():match('abc'))

-- test choice reordering
p = (m.P 'foobar' + m.P'foo'):optimize()
assert(p:match('foobar'))

p = (m.P{ m.P'foo' + m.P'bar' + m.P'a' * m.V(1) }):optimize()
assert(p:match('foo') == 4)
assert(p:match('bar') == 4)
assert(p:match('aafoo') == 6)
assert(p:match('aabar') == 6)
assert(p:match('aafoozz') == 6)
assert(p:match('aabarzz') == 6)

-- this pattern caused number of issues with ITestVector
-- * alternatives are not ordered
-- * the final set has nothing after itself
-- TODO: test that the code is not duplicated for each char in sets
p = m.P'aa' + m.P'bb' + m.P'cc' + m.P'dd' + m.P'ee' + (m.P(1) - m.R'az')
assert(p:match('aa') == 3)
assert(p:match('ee') == 3)
assert(p:match('A') == 2)


-- the 'bb' must not come before the 'bbbb' (the capture is not currently handled
-- by the optimizer and should abort at that point)
p = (m.P'cc' + m.P'aa' + m.C'bbbb' + m.P'bb'):optimize()
assert(p:match('bbbb') == 'bbbb')
assert(p:match('bb') == 3)

-- Another tricky one: the 'A' must not be placed first
p = (m.P'AB' + m.P'aa' + m.P'A' + m.P'AC'):optimize()
assert(p:match('AB') == 3)
assert(p:match('aa') == 3)
assert(p:match('A') == 2)
assert(p:match('AC') == 2)

print('now run LPeg test suite with optimizations turned on')
do
  local realmatch = m.match
  m.match = function(self, ...)
    return realmatch(m.P(self):optimize(), ...)
  end
end
lpeg_optimization_enabled = true

dofile 'test.lua'

