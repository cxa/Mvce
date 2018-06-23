//
//  ViewController.swift
//  Counter-macOS
//
//  Created by CHEN Xian-an on 2018/6/19.
//  Copyright © 2018 realazy. All rights reserved.
//

import Cocoa
import Mvce

class ViewController: NSViewController {
  @IBOutlet weak var label: NSTextField!
  @IBOutlet weak var incrButton: NSButton!
  @IBOutlet weak var decrButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    Mvce.glue(model: CounterModel(), view: self, controller: CounterController())
  }

  @objc private func incr(_ sender: Any?) {
    emit(event: .increment)
  }

  @objc private func decr(_ sender: Any?) {
    emit(event: .decrement)
  }
}

extension ViewController: View, EventEmitter {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func bind(model: CounterModel) -> Invalidator {
    return Mvce.flatKVObservations([
      model.bind(\.count, to: label, at: \.stringValue) { String(format: "%d", $0) }
      ])
  }

  func bind(eventEmitter: (CounterEvent) -> Void) {
    incrButton.target = self
    incrButton.action = #selector(incr(_:))
    decrButton.target = self
    decrButton.action = #selector(decr(_:))
  }
}
