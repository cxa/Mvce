//
//  Mvce.swift
//  Mvce
//
//  Created by CHEN Xianan on 6/15/18.
//  Copyright © 2018 CHEN Xianan. All rights reserved.
//

import Foundation

public protocol Dispatchable {
  associatedtype Event

  func send(event: Event)
}

private extension Dispatchable where Self: AnyObject {
  typealias SendEvent = (Event) -> Void

  var _mvce_sendEvent: SendEvent? {
    get {
      let key: StaticString = #function
      return objc_getAssociatedObject(self, key.utf8Start) as? SendEvent
    }
    set {
      let key: StaticString = #function
      objc_setAssociatedObject(self, key.utf8Start, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      if let sendEvent = newValue, _mvce_eventsBeforeGlue.count > 0 {
        _mvce_eventsBeforeGlue.forEach { sendEvent(($0 as! Box<Event>).value) }
        _mvce_eventsBeforeGlue.removeAllObjects()
      }
    }
  }

  var _mvce_eventsBeforeGlue: NSMutableArray {
    let key: StaticString = #function
    var list = objc_getAssociatedObject(self, key.utf8Start) as? NSMutableArray
    if (list == nil) {
      list = NSMutableArray(capacity: 1)
      objc_setAssociatedObject(self, key.utf8Start, list, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    return list!
  }
}

public extension Dispatchable where Self: AnyObject {
  func send(event: Event) {
    if let sendEvent = _mvce_sendEvent { sendEvent(event) }
    else { _mvce_eventsBeforeGlue.add(Box(event)) }
  }
}

public struct Dispatcher<E>: Dispatchable {
  public typealias Event = E
  typealias SendEvent = (Event) -> Void

  private let sendEvent: SendEvent
  init(sendEvent: @escaping SendEvent) { self.sendEvent = sendEvent }
  public func send(event: Event) { sendEvent(event) }
}

public protocol Controller {
  associatedtype Model
  associatedtype Event

  func update(model: Model, for event: Event, dispatcher: Dispatcher<Event>) -> Void
}

public protocol View {
  associatedtype Model
  associatedtype Event
  typealias BindingDisposer = () -> Void

  func bind(model: Model, dispatcher: Dispatcher<Event>) -> BindingDisposer
}

public struct Mvce {
  private static func _glue<V: View & AnyObject, C: Controller, Model, Event>(model: Model, view: V, controller: C) -> EventLoop<Model, Event>
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let loop = EventLoop(model: model, view: view, controller: controller)
    let key: StaticString = #function
    objc_setAssociatedObject(view, key.utf8Start, loop, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    return loop
  }

  static public func glue<V: View & AnyObject, C: Controller, Model, Event>(model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let _ = _glue(model: model, view: view, controller: controller)
  }

  static public func glue<V: View & AnyObject & Dispatchable, C: Controller, Model, Event>(model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let loop = _glue(model: model, view: view, controller: controller)
    var v = view
    v._mvce_sendEvent = loop.sendEvent
  }

  static public func glue<V: View & AnyObject, C: Controller & AnyObject & Dispatchable, Model, Event>(model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let loop = _glue(model: model, view: view, controller: controller)
    var c = controller
    c._mvce_sendEvent = loop.sendEvent
  }

  static public func glue<V: View & AnyObject & Dispatchable, C: Controller & AnyObject & Dispatchable, Model, Event>(model: Model, view: V, controller: C)
    where
    V.Model == Model, V.Event == Event,
    C.Model == Model, C.Event == Event
  {
    let loop = _glue(model: model, view: view, controller: controller)
    var v = view
    var c = controller
    v._mvce_sendEvent = loop.sendEvent
    c._mvce_sendEvent = loop.sendEvent
  }
}

private class EventLoop<Model, Event> {
  let dispose: View.BindingDisposer
  let obsever: NSObjectProtocol
  let sendEvent: Dispatcher<Event>.SendEvent

  init<V: View, C: Controller>(model: Model, view: V, controller: C)
    where V.Model == Model, V.Event == Event,
          C.Model == Model, C.Event == Event
  {
    let notiName = Notification.Name(UUID.init().uuidString)
    sendEvent = { event in NotificationCenter.default.post(name: notiName, object: Box(event)) }
    let dispatcher = Dispatcher(sendEvent: sendEvent)
    dispose = view.bind(model: model, dispatcher: dispatcher)
    obsever = NotificationCenter.default.addObserver(forName: notiName, object: nil, queue: nil) { notification in
      guard let event = notification.object as? Box<Event> else { return }
      controller.update(model: model, for: event.value, dispatcher: dispatcher)
    }
  }

  deinit {
    NotificationCenter.default.removeObserver(obsever)
    dispose()
  }
}

private class Box<T> {
  let value: T
  init(_ value: T) { self.value = value }
}
