# Decision Tree in Server Side Swift


<p align="center">
    <a href="http://perfect.org/get-involved.html" target="_blank">
        <img src="http://perfect.org/assets/github/perfect_github_2_0_0.jpg" alt="Get Involved with Perfect!" width="854" />
    </a>
</p>

<p align="center">
    <a href="https://github.com/PerfectlySoft/Perfect" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_1_Star.jpg" alt="Star Perfect On Github" />
    </a>  
    <a href="http://stackoverflow.com/questions/tagged/perfect" target="_blank">
        <img src="http://www.perfect.org/github/perfect_gh_button_2_SO.jpg" alt="Stack Overflow" />
    </a>  
    <a href="https://twitter.com/perfectlysoft" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_3_twit.jpg" alt="Follow Perfect on Twitter" />
    </a>  
    <a href="http://perfect.ly" target="_blank">
        <img src="http://www.perfect.org/github/Perfect_GH_button_4_slack.jpg" alt="Join the Perfect Slack" />
    </a>
</p>

<p align="center">
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Swift-4.0-orange.svg?style=flat" alt="Swift 4.0">
    </a>
    <a href="https://developer.apple.com/swift/" target="_blank">
        <img src="https://img.shields.io/badge/Platforms-OS%20X%20%7C%20Linux%20-lightgray.svg?style=flat" alt="Platforms OS X | Linux">
    </a>
    <a href="http://perfect.org/licensing.html" target="_blank">
        <img src="https://img.shields.io/badge/License-Apache-lightgrey.svg?style=flat" alt="License Apache">
    </a>
    <a href="http://twitter.com/PerfectlySoft" target="_blank">
        <img src="https://img.shields.io/badge/Twitter-@PerfectlySoft-blue.svg?style=flat" alt="PerfectlySoft Twitter">
    </a>
    <a href="http://perfect.ly" target="_blank">
        <img src="http://perfect.ly/badge.svg" alt="Slack Status">
    </a>
</p>


This is a Swift 4.0 version of Decision Tree data structure automation library according to the [wikipedia](https://zh.wikipedia.org/wiki/决策树)


The tree node has been abstracted into such an interface:

``` swift
class DecisionTree {
  public init(_ id: String, branches: [String: Any])
  public func search(_ data:[String: String]) throws -> String
}
```

All values in the objective data source must be discrete and converted into String.

## Quick Start

Package.swift:

``` swift
.package(url: "https://github.com/RockfordWei/DecisionTree.git", from: "0.3.0")
```

Please also **note** that it is necessary to modify the `Package.swift` file with explicit dependency declaration:

```
dependencies: ["DecisionTree"]
```

Then you can import the library:

```
import DecisionTree
```

## Machine Learning

Currently there are two ways of tree building by scanning the data tables.

Assuming that we expected to build a tree like:

``` swift
let windy = DecisionTree("windy", 
	branches: ["true": "false", "false": "true"])
      
let humid = DecisionTree("humid", 
	branches: ["false": "true", "true": "false"])
      
let outlook = DecisionTree("outlook", 
	branches: ["sunny":humid, "overcast": "true", "rain": windy])
```

Which is coming from a data table as below:

``` swift
  let discreteRecords: [[String: String]] = [
    ["outlook": "sunny",    "humid": "true", "windy": "false", "play": "false"],
    ["outlook": "sunny",    "humid": "true", "windy": "true",  "play": "false"],
    ["outlook": "overcast", "humid": "true", "windy": "false", "play": "true" ],
...
    ["outlook": "rain",     "humid": "true", "windy": "true",  "play": "false"],
  ]

```

Perfect DecisionTree module provides two different solutions depending on type of the data source - in memory Array/Dictionary or a database connection.

### In-Memory Toy

You can use `DTBuilderID3Memory` to create such a tree by a Swift Dictionary - Array:

``` swift
let tree = try DTBuilderID3Memory.Build(
	"play", from: discreteRecords)
```

This method is single threaded function which is aiming on educational purposes to help developers understand the textbook algorithm.

Please check the testing script for sample data.

### Production Builder with MySQL

This library also provides a powerful builder powered by mysql, which can scan the whole table in an amazing speed and get the job done - assuming the above data has been transferred to a `golf` table stored in the database.

``` swift
let tree = try DTBuilderID3MySQL.Build(
	"play", from: mysqlConnection, tag: "golf")
```

It will split the table into views recursively without moving or writing any data, in a threading queue. The major cost is the memory of stacks for deep walking with nothing else.

Please check the testing script to understand how it works.

## Further Information
For more information on the Perfect project, please visit [perfect.org](http://perfect.org).


## Now WeChat Subscription is Available (Chinese)
<p align=center><img src="https://raw.githubusercontent.com/PerfectExamples/Perfect-Cloudinary-ImageUploader-Demo/master/qr.png"></p>
