//
//  ButtonAction.swift
//  Counter
//
//  Created by CHEN Xian-an on 2018/6/26.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation

class ButtonAction: NSObject {
  let emit: (CounterEvent) -> Void

  init(emit: @escaping (CounterEvent) -> Void) {
    self.emit = emit
  }

  @objc func incr(_ sender: Any?) {
    emit(.increment)
  }

  @objc func decr(_ sender: Any?) {
    emit(.decrement)
  }
}
