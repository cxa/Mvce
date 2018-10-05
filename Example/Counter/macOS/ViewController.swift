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
}

extension ViewController: Mvce.View {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func bind(model: Model) -> Invalidator {
    return Mvce.batchInvalidate(observations: [
      model.bind(\.count, to: label, at: \.stringValue) { String(format: "%d", $0) }
    ])
  }

  func bind(emitter: Mvce.EventEmitter<Event>) {
    let action = ButtonAction(emit: emitter.emit)
    incrButton.target = action
    incrButton.action = #selector(action.incr(_:))
    decrButton.target = action
    decrButton.action = #selector(action.decr(_:))
    // Need to retain target
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
