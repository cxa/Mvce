//
//  CounterController.swift
//  Counter
//
//  Created by CHEN Xian-an on 2018/6/19.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation
import Mvce

enum CounterEvent {
  case increment
  case decrement
}

struct CounterController: Controller {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func update(model: Model, for event: Event, dispatcher: Dispatcher<Event>) {
    switch event {
    case .increment:
      model.count += 1
    case .decrement:
      model.count -= 1
    }
  }
}
