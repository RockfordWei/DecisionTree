import XCTest
@testable import DecisionTree

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


  func testEntropies() {
    let play:[String] = discreteRecords.map { $0["play"] ?? "" }
    let gain = DecisionTreeBuilderID3.Entropy(ofColumn: play)
    let gainOutlook = DecisionTreeBuilderID3.Entropy(ofColumn: "outlook", forColumn: "play", dataset: discreteRecords)
    print(gain, gainOutlook)
    XCTAssertGreaterThan(gain, gainOutlook)
  }

  static var allTests = [
    ("testExample", testExample),
    ("testEntropies", testEntropies)
    ]
}
