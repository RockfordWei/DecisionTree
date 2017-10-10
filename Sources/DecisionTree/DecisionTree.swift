//
//  DecisionTree.swift
//
//  Created by Rocky Wei on 2017-10-05.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

import Foundation

/// Decision Tree Node Structure
open class DecisionTree {

  /// key field of the objective record
  let _id: String

  /// inner data for subtrees, where id is the key of data record field
  /// and the value can be either a discrete result or another tree node
  let _branches: [String: Any]

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

    /// Unsupported Algorithm
    case Unsupported
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

public protocol DecisionTreeBuilder {
  /// build a tree from a dictionary
  static func Build(byDictionary: [[String: String]]) throws -> DecisionTree
  static func Build(byReference: OpaquePointer) throws -> DecisionTree
}

open class DecisionTreeBuilderID3:DecisionTreeBuilder {

  /// calculate the entropy of a specific column / field, i.e, `sum(p * lg(p))`
  /// - parameters:
  ///   - ofColumn: a discrete column data in a table
  /// - returns: a bit value.
  public static func Entropy(ofColumn: [String]) -> Double {
    let p = Possibility(ofColumn: ofColumn)
    return p.reduce(0) { $0 - $1.value * log2($1.value) }
  }

  /// calculate the conditional entropy of two columns
  /// - parameters:
  ///   - ofColumn: conditional column (factor)
  ///   - forColumn: outcome column
  ///   - dataset: dataset that includes both columns
  /// - returns: a bit value
  public static func Entropy(ofColumn: String, forColumn: String, dataset: [[String: String]]) -> Double {
    var subview: [String:[String]] = [:]
    for rec in dataset {
      if let column = rec[ofColumn],
        let current = rec[forColumn] {
        if let sub = subview[column] {
          var sub2 = sub
          sub2.append(current)
          subview[column] = sub2
        } else {
          subview[column] = [current]
        }
      }
    }

    let primary:[String] = subview.keys.map {$0}
    let distribution = Possibility(ofColumn: primary)
    let sub = Dictionary(uniqueKeysWithValues: subview.map { ($0, Entropy(ofColumn: $1)) })
    var total = 0.0
    for k in primary {
      if let i = distribution[k],
        let j = sub[k] {
        total += (i * j)
      }
    }
    return total
  }
  /// generate regulated possibility distribution based on frequency
  /// - parameters: ofColumn, a column in a data table
  /// - returns: possibilty distribution table, each key has a corresponding possiblity value ranges in [0, 1]
  public static func Possibility(ofColumn: [String]) -> [String: Double] {
    let counters = Frequency(ofColumn: ofColumn)
    let total = Double(counters.reduce(0) { $0 + $1.value })
    return Dictionary(uniqueKeysWithValues: counters.map {
      ($0, Double($1) / total)
    })
  }

  /// enumerate frequency by value string
  /// equivalent to `SELECT field, COUNT(*) FROM table GROUP BY field`
  /// - parameters:
  ///   - ofColumn: column of the data table
  /// - returns: a dictionary of a certain value with its frequency
  public static func Frequency(ofColumn: [String]) -> [String: UInt] {
    var counters : [String: UInt] = [:]
    ofColumn.forEach { value in
      if let existing = counters[value] {
        counters[value] = existing + 1
      } else {
        counters[value] = 1
      }
    }
    return counters
  }

  public static func Build(byDictionary: [[String: String]]) throws -> DecisionTree {
    throw DecisionTree.Exception.Unsupported
  }
  public static func Build(byReference: OpaquePointer) throws -> DecisionTree {
    throw DecisionTree.Exception.Unsupported
  }


}
