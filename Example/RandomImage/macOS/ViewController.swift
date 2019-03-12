//
//  ViewController.swift
//  macOS
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import Cocoa
import Mvce
import Result
import ReactiveSwift
import ReactiveCocoa

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

extension ViewController: View {
  typealias Model = ImageModel
  typealias Event = ImageEvent

  func bind(model: ImageModel, dispatcher: Dispatcher<ImageEvent>) -> View.BindingDisposer {
    // model binding
    imageView.reactive.isHidden <~ model.isImageHidden.skipRepeats()
    imageView.reactive.image <~ model.downloadedImage.skipRepeats()

    progresslessIndicator.reactive.isHidden <~ model.isIndicatorHidden.skipRepeats()
    progressIndicator.reactive.isHidden <~ model.isProgressHidden.skipRepeats()
    progressIndicator.reactive.makeBindingTarget { $0.doubleValue = Double($1) * 100 } <~ model.downloadProgress.skipRepeats()
    downloadButton.reactive.stringValue <~ model.downloadButtonTitle.skipRepeats()
    let disposer = CompositeDisposable()
    disposer += model.isIndicatorHidden.producer.observe(on: UIScheduler()).startWithValues { [weak self] in
      if $0 { self?.progresslessIndicator.stopAnimation(nil) }
      else { self?.progresslessIndicator.startAnimation(nil) }
    }
    disposer += model.downloadError.skipNil().observe(on: UIScheduler()).observeValues { [weak self] in self?.alert(error: $0) }

    // event binding
    // ReactiveCocoa doesn't exposed `proxy.ivoked`
    let action = Action<(), (), NoError> { _ in
      SignalProducer { observer, _ in
        dispatcher.send(event: .handleDownload)
        observer.sendCompleted()
      }
    }
    downloadButton.reactive.pressed = CocoaAction(action)
    return disposer.dispose
  }
}
