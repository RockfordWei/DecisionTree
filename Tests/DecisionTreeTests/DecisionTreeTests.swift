import XCTest
@testable import DecisionTree
import PerfectMySQL
extension String {
  public var sysEnv: String {
    guard let e = getenv(self) else { return "" }
    return String(cString: e)
  }
}

class DecisionTreeTests: XCTestCase {
  let discreteRecords: [[String: String]] = [
    ["outlook": "sunny",    "humid": "true", "windy": "false", "play": "false"],
    ["outlook": "sunny",    "humid": "true", "windy": "true",  "play": "false"],
    ["outlook": "overcast", "humid": "true", "windy": "false", "play": "true" ],
    ["outlook": "rain",     "humid": "true", "windy": "false", "play": "true" ],
    ["outlook": "rain",     "humid": "true", "windy": "false", "play": "true" ],
    ["outlook": "rain",     "humid": "false","windy": "true",  "play": "false"],
    ["outlook": "overcast", "humid": "false","windy": "true",  "play": "true" ],
    ["outlook": "sunny",    "humid": "true", "windy": "false", "play": "false"],
    ["outlook": "sunny",    "humid": "false","windy": "false", "play": "true" ],
    ["outlook": "rain",     "humid": "true", "windy": "false", "play": "true" ],
    ["outlook": "sunny",    "humid": "false","windy": "true",  "play": "true" ],
    ["outlook": "overcast", "humid": "true", "windy": "true",  "play": "true" ],
    ["outlook": "overcast", "humid": "true", "windy": "false", "play": "true" ],
    ["outlook": "rain",     "humid": "true", "windy": "true",  "play": "false"],
  ]

  var mysql: MySQL!

  override func setUp() {
    mysql = MySQL()
    let host = "MYHST".sysEnv
    let user = "MYUSR".sysEnv
    let password = "MYPWD".sysEnv
    let port = UInt32("MYPRT".sysEnv) ??  3306

    XCTAssert(mysql.setOption(.MYSQL_SET_CHARSET_NAME, "utf8mb4"), mysql.errorMessage())
    XCTAssert(mysql.connect(host: host,
                            user: user,
                            password: password,
                            port: port),
              mysql.errorMessage())
    guard mysql.selectDatabase(named: "test") else {
      XCTAssert(mysql.query(statement: "SELECT VERSION"), mysql.errorMessage())
      XCTAssert(mysql.selectDatabase(named: "test"), mysql.errorMessage())
      return
    }
    let batch = """
    USE test;
    DROP TABLE IF EXISTS golf;
    CREATE TABLE golf (
      outlook VARCHAR(12) NOT NULL,
      humid VARCHAR(12) NOT NULL,
      windy VARCHAR(12) NOT NULL,
      play VARCHAR(12) NOT NULL
    );
    """
    batch.split(separator: ";").map(String.init).forEach { sql in
      XCTAssert(mysql.query(statement: sql), mysql.errorMessage())
    }
    for r in discreteRecords {
      guard let outlook = r["outlook"],
        let humid = r["humid"],
        let windy = r["windy"],
        let play = r["play"] else {
          break
      }
      let sql = "INSERT INTO golf VALUES('\(outlook)', '\(humid)', '\(windy)', '\(play)');"
      XCTAssert(mysql.query(statement: sql), mysql.errorMessage())
    }
  }

  override func tearDown() {
    super.tearDown()
    if let mysql = mysql {
      mysql.close()
    }
  }

  func testExample() {
    let windy = DecisionTree("windy", branches: ["true": "false", "false": "true"])
    let humid = DecisionTree("humid", branches: ["false": "true", "true": "false"])
    let outlook = DecisionTree("outlook", branches: ["sunny":humid, "overcast": "true", "rain": windy])
    for r in discreteRecords {
      guard let history = r["play"] else {
        XCTFail("Unexpected Null Record")
        break
      }
      do {
        let prediction = try outlook.search(r)
        XCTAssertEqual(prediction, history)
      }catch {
        XCTFail(error.localizedDescription)
      }
    }
  }

  func testTree() {
    do {
      let tree = try DTBuilderID3Memory.Build("play", from: discreteRecords)
      print(tree)
      let windy = DecisionTree("windy", branches: ["true": "false", "false": "true"])
      let humid = DecisionTree("humid", branches: ["false": "true", "true": "false"])
      let outlook = DecisionTree("outlook", branches: ["sunny":humid, "overcast": "true", "rain": windy])
      XCTAssertEqual(tree, outlook)
      for r in discreteRecords {
        guard let history = r["play"] else {
          XCTFail("Unexpected Null Record")
          break
        }
        do {
          let prediction = try tree.search(r)
          XCTAssertEqual(prediction, history)
        }catch {
          XCTFail(error.localizedDescription)
        }
      }
    }catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testMySQL() {
    do {
      let tree = try DTBuilderID3MySQL.Build("play", from: mysql, tag: "golf")
      print(tree)
      let windy = DecisionTree("windy", branches: ["true": "false", "false": "true"])
      let humid = DecisionTree("humid", branches: ["false": "true", "true": "false"])
      let outlook = DecisionTree("outlook", branches: ["sunny":humid, "overcast": "true", "rain": windy])
      XCTAssertEqual(tree, outlook)
    }catch {
      XCTFail(error.localizedDescription)
    }
  }

  func testEntropies() {
    let play:[String] = discreteRecords.map { $0["play"] ?? "" }
    let gain = DTBuilderID3Memory.Entropy(of: play)
    do {
      let gainOutlook = try DTBuilderID3Memory.Entropy(of: "outlook", for: "play", from: discreteRecords)
      print(gain, gainOutlook)
      XCTAssertGreaterThan(gain, gainOutlook)
      let sorted = try DTBuilderID3Memory.Evaluate(for: "play", from: discreteRecords)
      XCTAssertEqual(sorted.sorted, ["outlook", "windy", "humid"])
    }catch {
      XCTFail(error.localizedDescription)
    }
  }

  static var allTests = [
    ("testExample", testExample),
    ("testEntropies", testEntropies),
    ("testTree", testTree),
    ("testMySQL", testMySQL)
    ]
}
