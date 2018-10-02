//
//  Mvce.swift
//  Mvce
//
//  Created by CHEN Xianan on 6/15/18.
//  Copyright © 2018 CHEN Xianan. All rights reserved.
//

import Foundation

public typealias Model = NSObjectProtocol

public extension Model where Self: NSObject {
  func bind<V, V2, T>(_ keyPath: KeyPath<Self, V>, transform: @escaping (V) -> V2, to target: T, using binder: @escaping (T, V2) -> Void) -> NSKeyValueObservation {
    return observe(keyPath, options: [.initial, .new]) { (_, change) in
      guard let nv = change.newValue else { return }
      DispatchQueue.main.async { binder(target, transform(nv)) }
    }
  }

  func bind<V, T>(_ keyPath: KeyPath<Self, V>, to target: T, using binder: @escaping (T, V) -> Void) -> NSKeyValueObservation {
    return bind(keyPath, transform: {$0}, to: target, using: binder)
  }

  func bind<V, T, U>(_ keyPath: KeyPath<Self, V>, to target: T, at targetKeyPath: ReferenceWritableKeyPath<T, U>, transform: @escaping (V) -> U) -> NSKeyValueObservation {
    return bind(keyPath, to: target) { (t, v) in t[keyPath: targetKeyPath] = transform(v) }
  }

  func bind<V, T>(_ keyPath: KeyPath<Self, V>, to target: T, at targetKeyPath: ReferenceWritableKeyPath<T, V>) -> NSKeyValueObservation {
    return bind(keyPath, to: target) { (t, v) in t[keyPath: targetKeyPath] = v }
  }
}

public protocol MvceEventEmitter {
  associatedtype Event

  func emit(event: Event)
}

private extension MvceEventEmitter where Self: AnyObject {
  typealias Emitter = (Event) -> Void

  var emitter: Emitter {
    get {
      let key: StaticString = #function
      return objc_getAssociatedObject(self, key.utf8Start) as! Emitter
    }
    set {
      let key: StaticString = #function
      objc_setAssociatedObject(self, key.utf8Start, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

public extension MvceEventEmitter where Self: AnyObject {
  func emit(event: Event) {
    emitter(event)
  }
}

public protocol MvceController {
  associatedtype Model
  associatedtype Event
  typealias Emitter = (Event) -> Void

  func update(model: Model, for event: Event, eventEmitter: @escaping Emitter) -> Void
}

public typealias Invalidator = () -> Void

public protocol MvceView {
  associatedtype Model
  associatedtype Event
  typealias Emitter = (Event) -> Void

  func bind(model: Model) -> Invalidator
  func bind(eventEmitter: @escaping Emitter) -> Void
}

public struct Mvce {
  public typealias Controller = MvceController
  public typealias EventEmitter = MvceEventEmitter
  public typealias View = MvceView

  private static func _glue<V: View & AnyObject, C: Controller, Model, Event>
    (model: Model, view: V, controller: C) -> EventLoop<Model, Event>
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let loop = EventLoop(model: model, view: view, controller: controller)
    let key: StaticString = #function
    objc_setAssociatedObject(view, key.utf8Start, loop, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return loop
  }

  static public func glue<V: View & AnyObject, C: Controller, Model, Event>
    (model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let _ = _glue(model: model, view: view, controller: controller)
  }

  static public func glue<V: View & AnyObject & EventEmitter, C: Controller, Model, Event>
    (model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let glue = _glue(model: model, view: view, controller: controller)
    var makeCompilerHappyView = view
    makeCompilerHappyView.emitter = glue.emit(event:)
  }

  static public func glue<V: View & AnyObject, C: Controller & AnyObject & EventEmitter, Model, Event>
    (model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let glue = _glue(model: model, view: view, controller: controller)
    var makeCompilerController = controller
    makeCompilerController.emitter = glue.emit(event:)
  }

  static public func glue<V: View & AnyObject & EventEmitter, C: Controller & AnyObject & EventEmitter, Model, Event>
    (model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let glue = _glue(model: model, view: view, controller: controller)
    var makeCompilerHappyView = view
    makeCompilerHappyView.emitter = glue.emit(event:)
    var makeCompilerController = controller
    makeCompilerController.emitter = glue.emit(event:)
  }

  static public func batchInvalidate(observations: [NSKeyValueObservation]) -> Invalidator {
    return {
      for o in observations { o.invalidate() }
    }
  }
}

private class EventLoop<Model, Event> {
  let model: Model
  let notiName = Notification.Name(UUID.init().uuidString)
  let invaldateBinding: Invalidator
  var obsever: NSObjectProtocol?

  init<V: MvceView, C: MvceController>(model: Model, view: V, controller: C)
    where V.Model == Model, V.Event == Event,
          C.Model == Model, C.Event == Event
  {
    self.model = model
    invaldateBinding = view.bind(model: model)
    view.bind(eventEmitter: emit(event:))
    obsever = NotificationCenter.default.addObserver(forName: notiName, object: nil, queue: nil) { [weak self] notification in
      guard
        let emitter = self?.emit(event:),
        let model = self?.model,
        let event = notification.object as? Box<Event>
      else { return }
      controller.update(model: model, for: event.value, eventEmitter: emitter)
    }
  }

  deinit {
    obsever.map(NotificationCenter.default.removeObserver)
    invaldateBinding()
  }

  func emit(event: Event) {
    NotificationCenter.default.post(name: notiName, object: Box(event))
  }

  private class Box<T> {
    let value: T

    init(_ value: T) { self.value = value }
  }
}
