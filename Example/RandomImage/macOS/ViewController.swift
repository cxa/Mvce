//
//  ViewController.swift
//  macOS
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import Cocoa
import Mvce

class ViewController: NSViewController {
  @IBOutlet weak var timerLabel: NSTextField!
  @IBOutlet weak var imageView: NSImageView!
  @IBOutlet weak var progresslessIndicator: NSProgressIndicator!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  @IBOutlet weak var downloadButton: NSButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    Mvce.glue(model: ImageModel(), view: self, controller: ImageController())
  }

  private func alert(error: Error) {
    let alert = NSAlert(error: error)
    alert.addButton(withTitle: NSLocalizedString("Dismiss", comment: ""))
    alert.beginSheetModal(for: view.window!, completionHandler: nil)
  }
}

extension ViewController: Mvce.View, Mvce.EventEmitter {
  typealias Model = ImageModel
  typealias Event = ImageEvent

  func bind(model: ImageModel) -> Invalidator {
    return Mvce.batchInvalidate(observations: [
      model.bind(\.isImageHidden, to: imageView, at: \.isHidden),
      model.bind(\.isIndicatorHidden, to: progresslessIndicator) {
        $0?.isHidden = $1
        if $1 { $0?.stopAnimation(nil) }
        else { $0?.startAnimation(nil) }
      },
      model.bind(\.isProgressHidden, to: progressIndicator, at: \.isHidden),
      model.bind(\.downloadProgress, to: progressIndicator, at: \.doubleValue) { Double($0) * 100 },
      model.bind(\.downloadedImage, to: imageView, at: \.image),
      model.bind(\.downloadError, to: self) { (s, e) in e.map { s.alert(error: $0) } },
      model.bind(\.downloadTitle, to: downloadButton, at: \.title),
    ])
  }

  func bind(eventEmitter: @escaping (ImageEvent) -> Void) {
    let action = ButtonAction(emit: eventEmitter)
    downloadButton.target = action
    downloadButton.action = #selector(action.handleDownload(_:))
    // Need to retain target
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
