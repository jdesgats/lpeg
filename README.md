This is a fork original LPeg library. It contains unstable modifications.
If you search for original library, see [this page](http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html).

This fork contains some experimental optimizations to the original LPeg
library. It's a drop-in replacement and does not change pattern semantics,
it just optimize them, on demand.

# Introduction

The optimizations provided are focused on cases where a pattern has a lot
of alternatives, for instance `P'foo' + P'bar' + P'baz' + ...`. The vanilla
implementation would place a checkpoint a the beginning of the string and test
each pattern until it fails, rewind to the start of string and try next
pattern.

When you have hundreds or thousands of alternatives, it is *very* inefficient
(but it was not the intended use after all). This repository contains a
collection of patches to transform patterns into more efficient forms by
applying some rules pretty munch like the
[Aho-Corasick algorithm](http://en.wikipedia.org/wiki/Aho%E2%80%93Corasick_string_matching_algorithm).
For instance, the previous example is more efficient as
`(P'ba' * (P'r' + P'z')) + P'foo'`. By merging the common prefix, LPeg virtual
machine can narrow string matching munch faster.

There is also some optimization to the LPeg VM diriectly: the `ITestVector`
has been added to test all alternatives in one go for the current character
rather than each alternative separately.

This is currently a work in progress and is considered unstable. More
documentation and benchmarks will come in the next few weeks. The optimization
ratio depends on the kind of patterns, but it can be up to 500 times faster !

# Usage

Optimizations are not enabled by default, you have to do it manually by calling
the `:optimize` method.

```
local m = require"lpeg"
-- build pattern normally
p = (m.P'aaa' + m.P'bbb' + m.P'acc' + m.P'ddd')
-- now optimize it
opt_p = p:optimize()

print(opt_p:match 'acc')
```

The returned pattern is a regular LPeg pattern, that can still be used to build
larger patterns (optimizations will be kept).

The `optimize()` method takes an optional integer argument to set the limit of
optimization passes. The default limit (500) is more than enough for most
patterns, but huge ones needs up to thousands of passes to be fully optimized.
This can be quite long. the optimizer still needs to be... optimized !

