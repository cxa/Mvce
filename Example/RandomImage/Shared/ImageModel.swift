//
//  ImageModel.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation
import Mvce

class ImageModel: NSObject {
  @objc var isImageHidden: Bool {
    if case .finished(_) = imageState { return false }
    return true
  }

  @objc var isIndicatorHidden: Bool {
    if case .downloading(.undetermined) = imageState { return false }
    return true
  }

  @objc var isProgressHidden: Bool {
    if case .downloading(.fractionCompleted(_)) = imageState { return false }
    return true
  }

  @objc var downloadProgress: Float {
    if case .downloading(.fractionCompleted(let p)) = imageState { return p }
    return 0
  }

  @objc var downloadedImage: Image? {
    if case .finished(let img) = imageState { return img }
    return nil
  }

  @objc var downloadError: Error? {
    if case .error(let err) = imageState { return err }
    return nil
  }

  @objc var downloadTitle: String {
    switch imageState {
    case .downloading(_):
      return NSLocalizedString("Stop", comment: "")
    case .finished(_):
      return NSLocalizedString("Download Another Image", comment: "")
    default:
      return NSLocalizedString("Download Image", comment: "")
    }
  }

  enum ImageState {
    enum Progress {
      case undetermined
      case fractionCompleted(Float)
    }

    case none
    case downloading(Progress)
    case finished(Image)
    case error(Error)
  }

  var imageState: ImageState = .none {
    willSet {
      for key in ImageModel.keyPathsAffectedByImageState { willChangeValue(forKey: key._kvcKeyPathString!) }
    }
    didSet {
      for key in ImageModel.keyPathsAffectedByImageState { didChangeValue(forKey: key._kvcKeyPathString!) }
    }
  }

  private static let keyPathsAffectedByImageState: [AnyKeyPath] = [
    \ImageModel.isImageHidden,
    \ImageModel.isIndicatorHidden,
    \ImageModel.isProgressHidden,
    \ImageModel.downloadProgress,
    \ImageModel.downloadedImage,
    \ImageModel.downloadError,
    \ImageModel.downloadTitle
  ]
}
