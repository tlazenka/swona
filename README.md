# Swona

A Swift port of the lovely [Siilinkari](https://github.com/komu/siilinkari).

## Launch the REPL

`cd Repl && swift run && cd -`

_or_

`docker-compose run --rm repl`

### Example

```
var a = stringArrayOfSize(3, "")
var done = false
var i = 0

while (!done) { stringArraySet(a, i, "item" + i); i = i + 1; if (i==stringArrayLength(a)) done=true }

stringArrayGet(a, 2)

fun pow(a: Int, n: Int): Int = unless (n == 0 ) a * pow(a, n-1) else 1

pow(2, 8)
```

More in the [Prelude](Resources/prelude.sk).

## Run the tests

`swift test`

_or_

`docker-compose run --rm tests`

# Acknowledgements

Juha Komulainen and others listed in the [LICENSE](LICENSE).
