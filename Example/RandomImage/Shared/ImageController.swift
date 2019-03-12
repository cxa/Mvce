//
//  ImageController.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/16.
//  Copyright © 2018 realazy. All rights reserved.
//

import Foundation
import Mvce

enum ImageEvent {
  case handleDownload
  case requestImage
  case cancelRequest
}

class ImageController {
  private var downloadTask: URLSessionDataTask?
}

extension ImageController: Controller {
  typealias Model = ImageModel
  typealias Event = ImageEvent

  func update(model: Model, for event: Event, dispatcher: Dispatcher<Event>) {
    switch event {
    case .handleDownload:
      let next: Event
      if case .downloading(_) = model.imageState.value { next = .cancelRequest }
      else { next = .requestImage }
      dispatcher.send(event: next)
    case .requestImage:
      model.imageState.value = .downloading(.undetermined)
      downloadTask = downloadImage(model: model)
      downloadTask?.resume()
    case .cancelRequest:
      downloadTask?.cancel()
      model.imageState.value = .none
    }
  }
}

private extension ImageController {
  func downloadImage(model: ImageModel) -> URLSessionDataTask? {
    guard let url = URL(string: "https://picsum.photos/2000/1000/?random") else { // Download a large image to show progress
      let uinfo = [NSLocalizedDescriptionKey: NSLocalizedString("Image URL is wrong", comment: "")]
      let err = NSError(domain: "", code: 0, userInfo:uinfo)
      model.imageState.value = .error(err)
      return nil
    }
    let session = URLSession(configuration: .default, delegate: DataTaskDelegate(model), delegateQueue: nil)
    return session.dataTask(with: url)
  }
}

private class DataTaskDelegate: NSObject, URLSessionDataDelegate {
  let model: ImageModel
  var expectLen = NSURLSessionTransferSizeUnknown
  var imageData = Data()

  init(_ model: ImageModel) {
    self.model = model
    super.init()
  }

  func isDeterminated() -> Bool {
    return expectLen != NSURLSessionTransferSizeUnknown
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
    expectLen = response.expectedContentLength
    if isDeterminated() { imageData = Data(capacity: Int(expectLen)) }
    completionHandler(.allow)
  }

  func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
    imageData.append(data)
    if isDeterminated() {
      let fraction = Float(imageData.count) / Float(expectLen)
      model.imageState.value = .downloading(.fractionCompleted(fraction))
    }
  }

  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
    session.invalidateAndCancel()
    if let err = error  {
      if (err as NSError).code == NSURLErrorCancelled { return model.imageState.value = .none }
      return model.imageState.value = .error(err)
    }
    guard let image = Image(data: imageData) else {
      let uinfo = [NSLocalizedDescriptionKey: NSLocalizedString("Can not convert data to Image", comment: "")]
      let err = NSError(domain: "", code: 0, userInfo:uinfo)
      return model.imageState.value = .error(err)
    }

    model.imageState.value = .finished(image)
  }
}
