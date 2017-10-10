//
//  main.swift
//  DecisionTreeDemo
//
//  Created by Rocky Wei on 2017-10-05.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

let regulatedRecords: [[String: String]] = [
  ["outlook": "sunny", "humid": "true", "windy": "false", "play": "false"],
  ["outlook": "sunny", "humid": "true", "windy": "true", "play": "false"],
  ["outlook": "overcast", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "rain", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "rain", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "rain", "humid": "true", "windy": "true", "play": "false"],
  ["outlook": "overcast", "humid": "false", "windy": "false", "play": "true"],
  ["outlook": "sunny", "humid": "true", "windy": "false", "play": "false"],
  ["outlook": "sunny", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "rain", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "sunny", "humid": "true", "windy": "true", "play": "true"],
  ["outlook": "overcast", "humid": "true", "windy": "true", "play": "true"],
  ["outlook": "overcast", "humid": "true", "windy": "false", "play": "true"],
  ["outlook": "rain", "humid": "true", "windy": "true", "play": "false"],
]


open class Tree {
  let _branches: [String: Any]
  let _key: String

  public init(_ key: String, branches: [String: Any]) {
    _key = key
    _branches = branches
  }

  public enum Exception: Error {
    case InvalidNode
    case UnexpectedKey
  }
  public func search(_ data:[String: String]) throws -> String {
    if let value = data[_key] {
      if _branches[value] is Tree,
        let node = _branches[value] as? Tree {
        return try node.search(data)
      } else if _branches[value] is String,
        let result = _branches[value] as? String {
          return result
      } else {
        throw Exception.InvalidNode
      }
    } else {
      throw Exception.UnexpectedKey
    }
  }
}

let windy = Tree("windy", branches: ["true": "false", "false": "true"])
let humid = Tree("humid", branches: ["false": "true", "true": "false"])
let outlook = Tree("outlook", branches: ["sunny":humid, "overcast": "true", "rain": windy])

func test(_ record: [String: String]) -> String {
  return (try? outlook.search(record)) ?? ""
}

regulatedRecords.forEach { r in
  print(r, " ->", test(r))
}

