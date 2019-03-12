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
}

extension ViewController: View {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer {
    let observation = model.bind(\CounterModel.count, to: label, at: \UILabel.text) { String(format: "%d", $0) }
    let action = ButtonAction(sendEvent: dispatcher.send(event:))
    incrButton.addTarget(action, action: #selector(action.incr(_:)), for: .touchUpInside)
    decrButton.addTarget(action, action: #selector(action.decr(_:)), for: .touchUpInside)
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) // Need to retain target
    return observation.invalidate
  }
}
