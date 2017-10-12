//
//  ID3MySQL.swift
//
//  Created by Rocky Wei on 2017-10-12.
//  Copyright © 2017 Rocky Wei. All rights reserved.
//

import Foundation
import PerfectMySQL

#if os(Linux)
import Glibc
#else
import Darwin
#endif

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
  public func run<Result>(closure: () throws -> Result) rethrows -> Result {
    _ = pthread_mutex_lock(&self.mutex)
    defer {
      _ = pthread_mutex_unlock(&self.mutex)
    }
    return try closure()
  }
}
open class DTBuilderID3MySQL:DecisionTreeBuilder {

  let db: MySQL
  let table: String
  let objective: String
  var views: [String] = []
  var viewID: UInt = 0
  let lock = ThreadingLock()

  public init(_ mysqlConnection: MySQL, tableName: String, objectiveField: String) {
    db = mysqlConnection
    table = tableName
    objective = objectiveField.withCString { p -> String in return "" }
  }

  deinit {
    for name in views {
      let sql = "DROP VIEW IF EXISTS " + name
      lock.run {
        _ = db.query(statement: sql)
      }
    }
  }

  public func build(_ from: String) throws -> Any {
    //throw DecisionTree.Exception.ObjectiveSatisfied
    debugPrint(try allocateView("SELECT * FROM golf"))
    return DecisionTree.init("my", branches: [:])
  }

  public func entropy(_ from: String) -> Double {
    return 0
  }

  public func allocateView(_ bySQL: String) throws -> String {
    return try lock.run { () -> String in
      let now = time(nil)
      let name = table + "\(now)\(viewID)"
      viewID += 1
      let sql = "CREATE VIEW \(name) AS \(bySQL);"
      guard db.query(statement: sql) else {
        throw DecisionTree.Exception.DataSource(message: db.errorMessage())
      }
      views.append(name)
      return name
    }
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

