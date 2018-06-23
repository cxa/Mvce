//
//  MvceTests.swift
//  MvceTests
//
//  Created by CHEN Xianan on 6/15/18.
//  Copyright © 2018 CHEN Xianan. All rights reserved.
//

import XCTest
@testable import Mvce

class SampleModel: NSObject {
  @objc dynamic var counter = 0
}

enum SampleEvent {
  case increment
  case decrement
}

struct SampleController: Controller {
  typealias Model = SampleModel
  typealias Event = SampleEvent
  
  func update(model: SampleModel, for event: SampleEvent) {
    switch event {
    case .increment:
      model.counter += 1
    case .decrement:
      model.counter -= 1
    }
  }
}

class SampleView: NSObject, EventEmitter, View {
  typealias Model = SampleModel
  typealias Event = SampleEvent

  var counter = -1000

  func bind(model: SampleModel) -> Invalidator {
    return Mvce.flatKVObservations([
      model.observe(\SampleModel.counter, options: [.initial, .new]) { [weak self] (_, change) in
        if let c = change.newValue {
          self?.counter = c
        }
      }
      ])
  }

  func bind(eventEmitter: (SampleEvent) -> Void) {

  }
}

class MvceTests: XCTestCase {
  let model = SampleModel()
  var view = SampleView()
  let controller = SampleController()

  override func setUp() {
    super.setUp()
    Mvce.glue(model: model, view: view, controller: controller)
  }

  override func tearDown() {
    super.tearDown()
  }

  func testEmittingEvent() {
    XCTAssertEqual(view.counter, 0)
    view.emit(event: .increment)
    XCTAssertEqual(model.counter, 1)
    XCTAssertEqual(view.counter, 1)
    view.emit(event: .increment)
    XCTAssertEqual(model.counter, 2)
    XCTAssertEqual(view.counter, 2)
    view.emit(event: .decrement)
    XCTAssertEqual(model.counter, 1)
    XCTAssertEqual(view.counter, 1)
    view.emit(event: .decrement)
    XCTAssertEqual(model.counter, 0)
    XCTAssertEqual(view.counter, 0)
  }
}
