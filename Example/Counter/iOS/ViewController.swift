//
//  ViewController.swift
//  Counter
//
//  Created by CHEN Xian-an on 2018/6/19.
//  Copyright © 2018 realazy. All rights reserved.
//

import UIKit
import Mvce

final class ViewController: UIViewController {
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var incrButton: UIButton!
  @IBOutlet weak var decrButton: UIButton!

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
      model.bind(\.count, to: label, at: \.text) { String(format: "%d", $0) }
    ])
  }

  func bind(eventEmitter: (CounterEvent) -> Void) {
    incrButton.addTarget(self, action: #selector(incr(_:)), for: .touchUpInside)
    decrButton.addTarget(self, action: #selector(decr(_:)), for: .touchUpInside)
  }
}
