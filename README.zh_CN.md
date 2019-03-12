# Mvce — 事件驱动的 MVC 库

Mvce 可读作 **/缪斯/**。

Mvce 是一个事件驱动的 MVC 辅助库，用于组合模块、视图和控制器。适用于 UIKit 和 AppKit。

Also available in [English](README.md).

## 缘由

UIKit/AppKit 提供的主要是视图。不要被 `UIViewController`/`NSViewController` 及其子类中的 `Controller` 误导，它们都属于视图，永远不该有属于控制器的逻辑，比如网络请求、更新模块等。

UIKit/AppKit 没有强制规定组合模型、视图和控制器的方法，如何去做取决于你。通常做法是，就像官方提供的那些（坏）例子，定义模型，在 `UIViewController`/`NSViewController` 引用，直接操作模型。如丝般……柔滑？

并不！这只不过是没有 C 的 M-VC，强耦合、无重用、难测试！

## 大法

MVC 模式强调的是模型、视图和控制器分离，如何组合它们，Mvce 提供一套以事件为核心的方法。

以这款长这样的计数程序为例，

![iOS Sample App](Assets/iOSCounterApp.png)

先品品 Mvce 的风味，有码奉上：

```swift
// CounterModel.swift:
// 表示计数的模型
final class CounterModel: NSObject {
  @objc dynamic var count = 0
}

// CounterController.swift:
// 按钮 ++ 和 -- 的事件
enum CounterEvent {
  case increment
  case decrement
}

// 处理不同的事件，更新模型的控制器
struct CounterController: Mvce.Controller {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func update(model: Model, for event: Event, dispatcher: Dispatcher<Event>) {
    switch event {
    case .increment:
      model.count += 1
    case .decrement:
      model.count -= 1
    }
  }
}

// ViewContorller.swift:
// 呈现模型状态的视图，用「事件传送器」（event dispatcher）传送事件通知控制器更新模型
final class ViewController: UIViewController {
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var incrButton: UIButton!
  @IBOutlet weak var decrButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    // 别忘了在这里组合模型、视图和控制器，别担心，Mvce 管理它们生命周期
    Mvce.glue(model: CounterModel(), view: self, controller: CounterController())
  }
}

extension ViewController: View {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer {
    let observation = model.bind(\CounterModel.count, to: label, at: \UILabel.text) { String(format: "%d", $0) }
    let action = ButtonAction(sendEvent: dispatcher.send(event:))
    incrButton.addTarget(action, action: #selector(action.incr(_:)), for: .touchUpInside)
    decrButton.addTarget(action, action: #selector(action.decr(_:)), for: .touchUpInside)
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) // Need to retain target
    return observation.invalidate
  }
}

// ButtonAction.swift:
// 按钮事件处理器
final class ButtonAction: NSObject {
  let sendEvent: (CounterEvent) -> Void

  init(sendEvent: @escaping (CounterEvent) -> Void) {
    self.sendEvent = sendEvent
  }

  @objc func incr(_ sender: Any?) {
    sendEvent(.increment)
  }

  @objc func decr(_ sender: Any?) {
    sendEvent(.decrement)
  }
}

```

### 分离模型和视图

仔细看视图 `ViewController` 的代码，你会发现没有任何模型的引用！只需遵循 `View` 协议，并在 `func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer` 里绑定模型到视图上。这个协议还提供事件传送器，让按钮可以发送相应的事件。

一旦你返回 `() -> Void`（Mvce 另名为 `View.BindingDisposer`），Mvce 会帮你管理这些绑定的生命周期。

### 分离视图和控制器

视图中也没有控制器的任何引用！`View` 协议除了要求绑定模型，还要求绑定事件传送器。何为事件传送器？只不过是一个 `(Event) -> Void` 函数包装器。用它来传送事件，Mvce 会分发给控制器，通知控制器更新模型。

### 组合模型、视图和控制器

在 `UIViewController`/`NSViewController` 的 `loadView` or `viewDidLoad` 里使用 `Mvce.glue(model:view:controller:)` 来组合它们。Mvce 会管理它们的生命周期。

### 跨平台（iOS & macOS）？

开玩笑，这可是「真·MVC」的最大好处之一。模型和控制器可共用，重写平台特定的视图就行了：

```swift
// macOS/viewController.swift
class ViewController: NSViewController {
  @IBOutlet weak var label: NSTextField!
  @IBOutlet weak var incrButton: NSButton!
  @IBOutlet weak var decrButton: NSButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    Mvce.glue(model: CounterModel(), view: self, controller: CounterController())
  }
}

extension ViewController: View {
  typealias Model = CounterModel
  typealias Event = CounterEvent

  func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer {
    let observation = model.bind(\.count, to: label, at: \.stringValue) { String(format: "%d", $0) }
    let action = ButtonAction(sendEvent: dispatcher.send(event:))
    incrButton.target = action
    incrButton.action = #selector(action.incr(_:))
    decrButton.target = action
    decrButton.action = #selector(action.decr(_:))
    let key: StaticString = #function
    objc_setAssociatedObject(self, key.utf8Start, action, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) // Need to retain target
    return observation.invalidate
  }
}
```

![macOS Sample App](Assets/macOSCounterApp.png)

就这么多！[Example](Example) 目录下还有复杂点儿的例子，不妨看看。需要注意的是，`RandomImage` 例子用到 ReactiveCocoa 来做绑定，需运行 `git submodule update --init --recursive` 来拉取。

### `Dispatchable` 协议

如果真的非常需要在 View 和 Controller 的任何角落里使用事件传送器，只需遵循让它们 `Dispatchable`。然而我不建议你这么做，这非常容易导致混乱的代码，破坏 MVC 的法则。

## 授权

MIT

## 作者

- Blog: [realazy.com](https://realazy.com)
- Github: [@cxa](https://github.com/cxa)
- Twitter: [@\_cxa](https://twitter.com/_cxa)
