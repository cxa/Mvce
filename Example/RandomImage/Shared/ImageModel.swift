//
//  ImageModel.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation
import Mvce
import Result
import ReactiveSwift

struct ImageModel {
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

  let imageState = MutableProperty(ImageState.none)
  let isImageHidden: Property<Bool>
  let isIndicatorHidden: Property<Bool>
  let isProgressHidden: Property<Bool>
  let downloadProgress: Property<Float>
  let downloadedImage: Property<Image?>
  let downloadError: Signal<Error?, NoError>
  let downloadButtonTitle: Property<String>

  init() {
    isImageHidden = imageState.map {
      switch $0 {
      case .finished(_): return false
      default: return true
      }
    }
    isIndicatorHidden = imageState.map {
      switch $0 {
      case .downloading(.undetermined): return false
      default: return true
      }
    }
    isProgressHidden = imageState.map {
      switch $0 {
      case .downloading(.fractionCompleted(_)): return false
      default: return true
      }
    }
    downloadProgress = imageState.map {
      switch $0 {
      case .downloading(.fractionCompleted(let p)): return p
      default: return 0
      }
    }
    downloadedImage = imageState.map {
      switch $0 {
      case .finished(let image): return .some(image)
      default: return nil
      }
    }
    downloadError = imageState.signal.map {
      switch $0 {
      case .error(let err): return .some(err)
      default: return nil
      }
    }
    downloadButtonTitle = imageState.map {
      switch $0 {
      case .downloading(_):
        return NSLocalizedString("Stop", comment: "")
      case .finished(_):
        return NSLocalizedString("Download Another Image", comment: "")
      default:
        return NSLocalizedString("Download Image", comment: "")
      }
    }
  }
}
