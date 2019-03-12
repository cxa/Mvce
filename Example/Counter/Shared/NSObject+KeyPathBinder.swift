//
//  KeyPathBinder.swift
//  Counter
//
//  Created by CHEN Xian-an on 2019/3/8.
//  Copyright © 2019 realazy. All rights reserved.
//

import Foundation

extension NSObjectProtocol where Self: NSObject {
  func bind<V, V2, T>(_ keyPath: KeyPath<Self, V>, skipsInitial: Bool = false, transform: @escaping (V) -> V2, to target: T, using binder: @escaping (T, V2) -> Void) -> NSKeyValueObservation {
    return observe(keyPath, options: skipsInitial ? [.new] : [.initial, .new]) { (_, change) in
      guard let nv = change.newValue else { return }
      DispatchQueue.main.async { binder(target, transform(nv)) }
    }
  }

  func bind<V, T>(_ keyPath: KeyPath<Self, V>, skipsInitial: Bool = false, to target: T, using binder: @escaping (T, V) -> Void) -> NSKeyValueObservation {
    return bind(keyPath, skipsInitial: skipsInitial, transform: {$0}, to: target, using: binder)
  }

  func bind<V, T, U>(_ keyPath: KeyPath<Self, V>, skipsInitial: Bool = false, to target: T, at targetKeyPath: ReferenceWritableKeyPath<T, U>, transform: @escaping (V) -> U) -> NSKeyValueObservation {
    return bind(keyPath, skipsInitial: skipsInitial, to: target) { (t, v) in t[keyPath: targetKeyPath] = transform(v) }
  }

  func bind<V, T>(_ keyPath: KeyPath<Self, V>, skipsInitial: Bool = false, to target: T, at targetKeyPath: ReferenceWritableKeyPath<T, V>) -> NSKeyValueObservation {
    return bind(keyPath, skipsInitial: skipsInitial, to: target) { (t, v) in t[keyPath: targetKeyPath] = v }
  }
}
