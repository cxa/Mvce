//
//  ButtonAction.swift
//  Counter
//
//  Created by CHEN Xian-an on 2018/6/26.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation

final class ButtonAction: NSObject {
  let sendEvent: (CounterEvent) -> Void

  init(sendEvent: @escaping (CounterEvent) -> Void) {
    self.sendEvent = sendEvent
  }

  @objc func incr(_ sender: Any?) {
    sendEvent(.increment)
  }

  @objc func decr(_ sender: Any?) {
    sendEvent(.decrement)
  }
}
