//
//  ButtonAction.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/26.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation

class ButtonAction: NSObject {
  let emit: (ImageEvent) -> Void

  init(emit: @escaping (ImageEvent) -> Void) {
    self.emit = emit
  }

  @objc func handleDownload(_ sender: Any?) {
    emit(.handleDownload)
  }
}
