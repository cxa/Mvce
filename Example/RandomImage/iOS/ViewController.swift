//
//  ViewController.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import UIKit
import Mvce
import ReactiveSwift
import ReactiveCocoa

class ViewController: UIViewController {
  @IBOutlet weak var indicatorView: UIActivityIndicatorView!
  @IBOutlet weak var progressBar: UIProgressView!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var downloadButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    Mvce.glue(model: ImageModel(), view: self, controller: ImageController())
  }

  private func alert(error: Error) {
    let alert = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss", comment: ""), style: .cancel, handler: nil))
    present(alert, animated: true, completion: nil)
  }
}

extension ViewController: View {
  typealias Model = ImageModel
  typealias Event = ImageEvent

  func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer {
    // model binding
    imageView.reactive.isHidden <~ model.isImageHidden.skipRepeats()
    imageView.reactive.image <~ model.downloadedImage.skipRepeats()
    indicatorView.reactive.isHidden <~ model.isIndicatorHidden.skipRepeats()
    progressBar.reactive.isHidden <~ model.isProgressHidden.skipRepeats()
    progressBar.reactive.progress <~ model.downloadProgress.skipRepeats()
    downloadButton.reactive.title(for: .normal) <~ model.downloadButtonTitle.skipRepeats()
    let disposer = CompositeDisposable()
    disposer += model.downloadError.skipNil().observe(on: UIScheduler()).observeValues { [weak self] in self?.alert(error: $0) }

    // event binding
    disposer += downloadButton.reactive.controlEvents(.primaryActionTriggered).observeValues { _ in dispatcher.send(event: .handleDownload) }
    return disposer.dispose
  }
}
