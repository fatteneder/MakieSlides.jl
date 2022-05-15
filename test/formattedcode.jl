using MakieSlides
using Markdown
using GLMakie

f = Figure()

# md = md"""
# ```julia
# function main()
#   println("Hello, world!")
# end
# ```
# """

md = md"""
```python
from typing import Iterator

# This is an example
class Math:
    @staticmethod
    def fib(n: int) -> Iterator[int]:
        \""" Fibonacci series up to n \"""
        a, b = 0, 1
        while a < n:
            yield a
            a, b = b, a + b

result = sum(Math.fib(42))
print("The answer is {}".format(result))
```
"""

code = md.content[1]

fmtcode = formattedcode(f[1,1], code, maxwidth=300.0)

f
