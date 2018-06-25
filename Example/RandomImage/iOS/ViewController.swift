//
//  ViewController.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import UIKit
import Mvce

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

  func bind(model: ImageModel) -> Invalidator {
    return Mvce.flatKVObservations([
      model.bind(\.isImageHidden, to: imageView, at: \.isHidden),
      model.bind(\.isIndicatorHidden, to: indicatorView) {
        $0?.isHidden = $1
        if $1 { $0?.stopAnimating() }
        else { $0?.startAnimating() }
      },
      model.bind(\.isProgressHidden, to: progressBar, at: \.isHidden),
      model.bind(\.downloadProgress, to: progressBar, at: \.progress),
      model.bind(\.downloadedImage, to: imageView, at: \.image),
      model.bind(\.downloadError, to: self) { (s, e) in e.map { s.alert(error: $0) } },
      model.bind(\.downloadTitle, to: downloadButton){ $0.setTitle($1, for: .normal) },
   ])
  }

  func bind(eventEmitter: @escaping (ImageEvent) -> Void) {
    let action = ButtonAction(emit: eventEmitter)
    downloadButton.addTarget(action, action: #selector(action.handleDownload(_:)), for: .touchUpInside)
    // Need to retain target
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
  }
}
