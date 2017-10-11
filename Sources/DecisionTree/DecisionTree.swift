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

    /// No data records
    case EmptyDataset
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
  ///   - from: data source, all values must be discrete
  /// - returns: a DecisionTree instance
  /// - throws: Exception
  static func Build(_ `for`: String, from: [[String: String]]) throws -> DecisionTree
}

open class DecisionTreeBuilderID3:DecisionTreeBuilder {

  public static func Build(_ `for`: String, from: [[String: String]]) throws -> DecisionTree {
    throw DecisionTree.Exception.Unsupported
  }

  /// evaluate all factors for a specific outcome
  /// - parameters:
  ///   - for: outcome field name
  ///   - from: data source
  /// - returns: an array of field names other than the outcome, sorted by its entropy
  /// - throws: Exceptions:
  ///   - EmptyDataset: when data source is empty
  ///   - UnexpectedKey: when data source hasn't a valid outcome field
  public static func Evaluate(`for`: String, from: [[String: String]]) throws -> [String] {
    guard let sample = from.first else {
      throw DecisionTree.Exception.EmptyDataset
    }
    let fields: [String] = sample.keys.map { $0 }
    guard fields.contains(`for`) else {
      throw DecisionTree.Exception.UnexpectedKey
    }
    let factors = fields.filter { $0 != `for` }
    guard factors.count > 1 else {
      return factors
    }//end if
    let objective:[String] = from.map { $0[`for`] ?? "" }
    let gain = Entropy(of: objective)
    var gains: [String: Double] = [:]
    factors.forEach { factor in
      gains[factor] = gain - Entropy(of: factor, for: `for`, from: from)
    }
    debugPrint(gains)
    let sorted:[String] = gains.sorted { i, j in
      return i.value > j.value
      }.map { $0.key }
    return sorted
  }

  /// calculate the entropy of a specific column / field, i.e, `sum(p * lg(p))`
  /// - parameters:
  ///   - of: a discrete column data in a table
  /// - returns: a bit value.
  public static func Entropy(of: [String]) -> Double {
    let p = Possibility(of: of)
    return p.reduce(0) { $0 - $1.value * log2($1.value) }
  }

  /// calculate the conditional entropy of two columns
  /// - parameters:
  ///   - of: conditional column (factor)
  ///   - for: outcome column
  ///   - from: dataset that includes both columns
  /// - returns: a bit value
  public static func Entropy(of: String, `for`: String, from: [[String: String]]) -> Double {
    var subview: [String:[String]] = [:]
    for rec in from {
      if let column = rec[of],
        let current = rec[`for`] {
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
    let distribution = Possibility(of: primary)
    let sub = Dictionary(uniqueKeysWithValues: subview.map { ($0, Entropy(of: $1)) })
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
  /// - parameters:
  ///   - of: a column in a data table
  /// - returns: possibilty distribution table, each key has a corresponding possiblity value ranges in [0, 1]
  public static func Possibility(of: [String]) -> [String: Double] {
    let counters = Frequency(of: of)
    let total = Double(counters.reduce(0) { $0 + $1.value })
    return Dictionary(uniqueKeysWithValues: counters.map {
      ($0, Double($1) / total)
    })
  }

  /// enumerate frequency by value string
  /// equivalent to `SELECT field, COUNT(*) FROM table GROUP BY field`
  /// - parameters:
  ///   - of: column of the data table
  /// - returns: a dictionary of a certain value with its frequency
  public static func Frequency(of: [String]) -> [String: UInt] {
    var counters : [String: UInt] = [:]
    of.forEach { value in
      if let existing = counters[value] {
        counters[value] = existing + 1
      } else {
        counters[value] = 1
      }
    }
    return counters
  }

}
