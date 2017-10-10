//
//  DecisionTree.swift
//
//  Created by Rocky Wei on 2017-10-05.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

open class DecisionTree {
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
      if _branches[value] is DecisionTree,
        let node = _branches[value] as? DecisionTree {
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