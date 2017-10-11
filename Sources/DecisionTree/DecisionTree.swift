//
//  DecisionTree.swift
//
//  Created by Rocky Wei on 2017-10-05.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

import Foundation

/// Decision Tree Node Structure
open class DecisionTree: Equatable, CustomStringConvertible {

  /// key field of the objective record
  let _id: String

  /// inner data for subtrees, where id is the key of data record field
  /// and the value can be either a discrete result or another tree node
  let _branches: [String: Any]

  /// convert the tree node into a string
  public var description: String {
    return "{'\(_id)': \(_branches)}"
  }

  /// compare two trees
  public static func == (left: DecisionTree, right: DecisionTree) -> Bool {
    guard left._id == right._id else { return false }
    let keyA:[String] = left._branches.keys.sorted()
    let keyB:[String] = right._branches.keys.sorted()
    guard keyA == keyB else { return false }
    for k in keyA {
      if left._branches[k] is String {
        guard let a = left._branches[k] as? String,
          right._branches[k] is String,
          let b = right._branches[k] as? String,
          a == b else {
          return false
        }
        continue
      } else if left._branches[k] is DecisionTree {
        guard let a = left._branches[k] as? DecisionTree,
        right._branches[k] is DecisionTree,
        let b = right._branches[k] as? DecisionTree,
          a == b else {
            return false
        }
        continue
      } else {
        return false
      }
    }
    return true
  }

  /// constructor. **Note** The best practice shall be created a tree from
  /// leat to root. For example:
  /// ```
  /// let leafA = DecisionTree("fieldA", branches: ["0": "1", "1": "0"])
  /// let leafB = DecisionTree("fieldB", branches: ["1": "1", "0": "0"])
  /// let root  = DecisionTree("fieldC", branches: ["A":leafA, "B": leafB])
  /// ```
  /// - parameters:
  ///   - id: key of data record field
  ///   - branches: subtrees
  public init(_ id: String, branches: [String: Any]) {
    _id = id
    _branches = branches
  }

  /// Error Handle of Decision Tree
  public enum Exception: Error {

    /// The node is neither a discrete string nor a tree node.
    case InvalidNode

    /// Current dataset doesn't contain such a field key.
    case UnexpectedKey

    /// The data contains an unexpected value
    case UnexpectedValue

    /// Unsupported Algorithm
    case Unsupported

    /// No data records
    case EmptyDataset

    /// No columns available
    case EmptyColumnset

    /// No evalation necessary, goal reached
    case ObjectiveSatisfied

    /// General Failure
    case GeneralFailure
  }

  /// search for the decision by providing the data set
  /// - parameters:
  ///   - data: the data set to input
  /// - returns: a string value as a prediction
  /// - throws: exceptions
  public func search(_ data:[String: String]) throws -> String {
    if let value = data[_id] {
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

/// General form of a decision tree builder
public protocol DecisionTreeBuilder {
  /// build a tree from a dictionary
  /// - parameters:
  ///   - for: outcome field name
  ///   - from: data source
  /// - returns: a DecisionTree instance
  /// - throws: Exception
  static func Build(_ `for`: String, from: Any) throws -> DecisionTree
}