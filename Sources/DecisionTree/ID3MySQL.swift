//
//  ID3MySQL.swift
//
//  Created by Rocky Wei on 2017-10-12.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//
import Dispatch
import Foundation
import PerfectMySQL

class ThreadingLock {
  var mutex = pthread_mutex_t()
  /// Initialize a new lock object.
  public init() {
    var attr = pthread_mutexattr_t()
    pthread_mutexattr_init(&attr)
    pthread_mutexattr_settype(&attr, Int32(PTHREAD_MUTEX_RECURSIVE))
    pthread_mutex_init(&mutex, &attr)
  }

  deinit {
    pthread_mutex_destroy(&mutex)
  }

  /// Acquire the lock, execute the closure, release the lock.
  public func doWithLock<Result>(closure: () throws -> Result) rethrows -> Result {
    _ =  pthread_mutex_lock(&self.mutex)
    defer {
      _ = pthread_mutex_unlock(&self.mutex)
    }
    return try closure()
  }
}

class ThreadSafeMySQL {
  let db: MySQL
  let lock: ThreadingLock
  public init(_ mysql: MySQL) {
    db = mysql
    lock = ThreadingLock()
  }
  public func query(_ statement: String, storeResult: Bool = true ) throws -> MySQL.Results? {
    return try lock.doWithLock {
      guard db.query(statement: statement) else {
          throw DecisionTree.Exception.DataSource(message: db.errorMessage())
      }
      if storeResult, let r = db.storeResults() {
        return r
      } else {
        return nil
      }
    }
  }
}

open class DTBuilderID3MySQL:DecisionTreeBuilder {

  let db: ThreadSafeMySQL
  let table: String
  let objective: String
  var views: [String] = []
  var viewID: UInt = 0
  /// constructor of the tree builder
  /// - parameters:
  ///   - mysqlConnection: mysql data source, assuming active and well connected
  ///   - tableName: the table to learn
  ///   - objectiveField: the goal outcome column name
  public init(_ mysqlConnection: MySQL, tableName: String, objectiveField: String) {
    db = ThreadSafeMySQL(mysqlConnection)
    table = tableName
    objective = objectiveField
  }

  /// destructor, will destroy all temporary views.
  deinit {
    for name in views {
      let sql = "DROP VIEW IF EXISTS " + name
      debugPrint(sql)
      _ = try? db.query(sql, storeResult: false)
    }
  }

  /// Build a decision tree node recursively from a db instance
  /// It will use the objective field and table to perform ID3 tree building
  /// - parameters:
  ///   - from: the table / subview name
  /// - returns: either a String value or a tree node
  /// - throws: Exception
  public func build(_ from: String) throws -> Any {
    let gain = try entropy(from: from)
    guard gain > 0 else {
      guard let r = try
        db.query("SELECT \(self.objective) FROM \(from) LIMIT 1")
        else {
        throw DecisionTree.Exception.EmptyDataset
      }
      var value = ""
      r.forEachRow { row in
        if let v = row[0] {
          value = v
        }
      }
      guard !value.isEmpty else {
        throw DecisionTree.Exception.UnexpectedValue
      }
      return value
    }

    guard let r = try
      db.query("SHOW COLUMNS FROM \(from) WHERE Field <> '\(self.objective)'")
      else {
      throw DecisionTree.Exception.EmptyDataset
    }
    var fields: [String] = []
    r.forEachRow { row in
      if let field = row[0] {
        fields.append(field)
      }
    }
    let gains: [String: Double] = try Dictionary(uniqueKeysWithValues:
      fields.map { field in
      let g = try self.entropy(of: field, from: from)
      return (field, gain - g)
    })
    let sortedFields:[String] = gains.sorted(by: { $0.1 > $1.1} ).map { $0.0 }
    guard let primary = sortedFields.first else {
       throw DecisionTree.Exception.UnexpectedKey
    }

    guard let valueRecords = try
      db.query("SELECT DISTINCT \(primary) FROM \(from)")
      else {
        throw DecisionTree.Exception.EmptyDataset
    }
    var values: [String] = []
    valueRecords.forEachRow { row in
      if let v = row[0] {
        values.append(v)
      }
    }
    guard !values.isEmpty else {
      throw DecisionTree.Exception.UnexpectedValue
    }

    let remains = fields.filter { $0 != primary } + [self.objective]
    let selection = remains.joined(separator: ",")

    var branches: [String: Any] = [:]
    let group = DispatchGroup()
    let queue = DispatchQueue(label: self.table + primary)
    for v in values {
      queue.async(group: group) {
        do {
          let subview = try self.allocateView("SELECT \(selection) FROM \(from) WHERE \(primary) = '\(v)'")
          let branch = try self.build(subview)
          branches[v] = branch
        }catch {
          debugPrint(error.localizedDescription)
        }
      }
    }
    group.wait()
    return DecisionTree(primary, branches: branches)
  }

  /// calculate the field specified entropy from a table / view
  /// - parameters:
  ///   - of: the field to weight
  ///   - from: name of the table / view to look up
  /// - returns: an entropy value in unit of bits
  /// - throws: db exceptions
  public func entropy(of: String, from: String) throws -> Double {
    let columnFreq = try frequency("SELECT \(of), COUNT(*) FROM \(from) GROUP BY \(of)")
    var sum = 0.0
    for (value, possibility) in columnFreq {
      let sql = """
      SELECT \(self.objective), COUNT(*) FROM \(from)
      WHERE \(of) = '\(value)'
      GROUP BY \(self.objective)
      """
      let freq = try frequency(sql)
      let gain = freq.reduce(0.0) { $0 - $1.value * log2($1.value) }
      sum += gain * possibility
    }
    return sum
  }

  /// calculate the general entropy of the objective field
  /// - parameters:
  ///   - from: name of the table / view to look up
  /// - returns: an entropy value in unit of bits
  /// - throws: db exceptions
  public func entropy(from: String) throws -> Double {
    let of = self.objective
    let sql = "SELECT \(of), COUNT(*) FROM \(from) GROUP BY \(of)"
    let freq = try frequency(sql)
    return freq.reduce(0.0) { $0 - $1.value * log2($1.value) }
  }

  /// return the value possibility distribution of a sql query, threaded safely
  /// - parameters:
  ///   - sql: the sql statement to perform, must contain two fields in the result set,
  /// i.e., `SELECT A, COUNT(*) FROM B GROUP BY A`
  /// - returns: a frequent distribution table, each key goes with its possibility in [0,1]
  /// - throws: db exceptions.
  public func frequency(_ sql: String) throws -> [String: Double] {
    guard let rec = try db.query(sql) else {
      throw DecisionTree.Exception.EmptyDataset
    }
    var freq: [String: UInt] = [:]
    rec.forEachRow { row in
      if let value = row[0], let count = row[1] {
        freq[value] = UInt(count)
      }
    }
    let sum = Double(freq.reduce(0) { $0 + $1.value })
    return Dictionary(uniqueKeysWithValues:
      freq.map { ($0.key, Double($0.value) / sum)} )
  }

  /// allocate a subview by the given sql statement
  /// - parameters:
  ///   - bySQL: sql statement for the new sub view
  /// - returns: name of the new created view
  /// - throws: db exceptions.
  public func allocateView(_ bySQL: String) throws -> String {
    let now = time(nil)
    let name = table + "\(now)\(viewID)"
    viewID += 1
    let sql = "CREATE VIEW \(name) AS \(bySQL);"
    _ = try db.query(sql, storeResult: false)
    views.append(name)
    return name
  }

  public static func Build(_ for: String, from: Any, tag: String) throws -> DecisionTree {
    guard from is MySQL, let db = from as? MySQL else {
      throw DecisionTree.Exception.Unsupported
    }
    let builder = DTBuilderID3MySQL(db, tableName: tag, objectiveField: `for`)
    guard let b = try builder.build(tag) as? DecisionTree else {
      throw DecisionTree.Exception.GeneralFailure
    }
    return b
  }
}

