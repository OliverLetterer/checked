# checked

Checked is a dead simple programming language.

### Variable declarations with type inference

```
func main() {
    let constantVariable = 5
    var variable = 1
}
```

### If-statements

```
func main() {
    let value = false
    if value {

    } else {

    }
}
```

### Functions

```
func myFunction(value: Float) {

}
```

### Functions with anonymous parameters

```
func myFunction(_ value: Float) {

}
```

### If-assignments

```
func myFunction(_ value: Bool) -> String {
    let result = if value {
        "string"
    } else {
        "other string"
    }

    return result
}
```

### If-returns

```
func myFunction(_ value: Bool) -> String {
    return if value {
        "string"
    } else {
        "other string"
    }
}
```

### Complex type inference

```
func myFunction() -> Int64 {
    return 0
}

func main() {
    let variable = myFunction()
}
```

## Getting started

Check out the samples.

```
swift run checked build samples/function-call/main.checked
```
