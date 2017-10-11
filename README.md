# Decision Tree Demo

This is a Swift 4.0 version demo about how to implement a decision tree data structure according to the [wikipedia](https://zh.wikipedia.org/wiki/决策树)


The tree node has been abstracted into such an interface:

``` swift
class DecisionTree {
  public init(_ id: String, branches: [String: Any])
  public func search(_ data:[String: String]) throws -> String
}
```

All values in the objective data source must be discrete and converted into String.

# Build & Test

`git clone` this project then `./test.sh`