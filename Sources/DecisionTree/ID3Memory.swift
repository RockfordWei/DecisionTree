//
//  ID3Memory.swift
//
//  Created by Rocky Wei on 2017-10-11.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

import Foundation

public struct ID3EvaluationSheet {
  public var gain = 0.0
  public var distribution: [String: Double] = [:]
  public var sorted: [String] {
    return distribution.map { ($0, self.gain - $1) }
      .sorted(by: { $0.1 > $1.1} ).map { $0.0 }
  }
}

open class DecisionTreeBuilderID3:DecisionTreeBuilder {

  public static func BuildRecursively(_ `for`: String, from: [[String: String]]) throws -> Any {
    let factors = try Evaluate(for: `for`, from: from)
    guard factors.gain > 0 else {
      guard let firstLine = from.first,
        let firstValue = firstLine[`for`] else {
          throw DecisionTree.Exception.UnexpectedValue
      }
      return firstValue
    }
    guard let primary = factors.sorted.first else {
      throw DecisionTree.Exception.UnexpectedKey
    }
    var subviews: [String: [[String: String]]] = [:]
    for record in from {
      var r = record
      guard let value = r.removeValue(forKey: primary) else {
        throw DecisionTree.Exception.UnexpectedKey
      }
      if let sub = subviews[value] {
        var sub2 = sub
        sub2.append(r)
        subviews[value] = sub2
      } else {
        subviews[value] = [r]
      }
    }
    var branches: [String: Any] = [:]
    for (value, view) in subviews {
      let branch = try BuildRecursively(`for`, from: view)
      branches[value] = branch
    }
    return DecisionTree(primary, branches: branches)
  }

  public static func Build(_ `for`: String, from: Any) throws -> DecisionTree {
    guard from is [[String: String]],
      let f = from as? [[String: String]] else {
      throw DecisionTree.Exception.Unsupported
    }
    guard let tree = try BuildRecursively(`for`, from: f) as? DecisionTree else {
      throw DecisionTree.Exception.GeneralFailure
    }
    return tree
  }

  /// evaluate all factors for a specific outcome
  /// - parameters:
  ///   - for: outcome field name
  ///   - from: data source
  /// - returns: an array of field names other than the outcome, sorted by its entropy
  /// - throws: Exceptions:
  ///   - EmptyDataset: when data source is empty
  ///   - UnexpectedKey: when data source hasn't a valid outcome field
  public static func Evaluate(`for`: String, from: [[String: String]]) throws -> ID3EvaluationSheet {
    let objective:[String] = from.map { $0[`for`] ?? "" }
    let gain = Entropy(of: objective)
    guard gain > 0.0 else {
      return ID3EvaluationSheet()
    }
    guard let sample = from.first else {
      throw DecisionTree.Exception.EmptyDataset
    }
    let fields: [String] = sample.keys.map { $0 }
    guard fields.contains(`for`) else {
      throw DecisionTree.Exception.UnexpectedKey
    }
    let factors = fields.filter { $0 != `for` }
    guard factors.count > 1 else {
      throw DecisionTree.Exception.EmptyColumnset
    }//end if
    var gains: [String: Double] = [:]
    for f in factors {
      gains[f] = try Entropy(of: f, for: `for`, from: from)
    }
    return ID3EvaluationSheet(gain: gain, distribution: gains)
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
  /// - throws: Exception.UnexpectedKey
  public static func Entropy(of: String, `for`: String, from: [[String: String]]) throws -> Double {
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
      } else {
        throw DecisionTree.Exception.UnexpectedKey
      }
    }

    let primary:[String] = subview.keys.map {$0}
    let frequencies = Dictionary(uniqueKeysWithValues:
      subview.map { ($0.key, $0.value.count)})
    let total = Double(frequencies.reduce(0) { $0 + $1.value })
    let distribution:[String: Double] = Dictionary(uniqueKeysWithValues: frequencies.map {
      ($0, Double($1) / total) })
    let sub = Dictionary(uniqueKeysWithValues: subview.map { ($0, Entropy(of: $1)) })
    var sum = 0.0
    for k in primary {
      if let i = distribution[k],
        let j = sub[k] {
        sum += (i * j)
      }
    }
    return sum
  }

  /// generate regulated possibility distribution based on frequency
  /// - parameters:
  ///   - of: a column in a data table
  /// - returns: possibilty distribution table, each key has a corresponding possiblity value ranges in [0, 1]
  public static func Possibility(of: [String]) -> [String: Double] {
    let counters = Frequency(of: of)
    let total = Double(counters.reduce(0) { $0 + $1.value })
    let p = Dictionary(uniqueKeysWithValues: counters.map {
      ($0, Double($1) / total)
    })
    return p
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
