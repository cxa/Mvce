# Mvce — Event driven MVC

Mvce can be pronounced as **/myo͞oz/**.

An event driven MVC library to glue decoupled Model, View, and Controller for UIKit/AppKit. Minimal, simple, and unobtrusive.

本文档同时提供[简体中文版](README.zh_CN.md)。

## Why

UIKit/AppKit is mainly about view. Don't be misled by the `Controller` in `UIViewController`/`NSViewController` and descendants, they are all views, should be avoided things that belong to a real controller, such as networking, model updating.

How to glue view, model, and controller is upon to you, UIKit/AppKit has no strong options on that. Typically, as the (bad) official examples show to us, we define a model, refer it inside `UIViewController`/`NSViewController`s, and manipulate the model directly. It works like a...charm?

No, it's M-VC without C, it's strong coupling, it's not reusable(for crossing UIKit and AppKit), if you care, it's also untestable.

## How

The key idea of MVC is the separation of Model, View, and Controller. To glue 'em, Mvce provides an alternative way.

Let's take a taste of Mvce first, here is a simple counter app:

![iOS Sample App](Assets/iOSCounterApp.png)

All code shows below (whole project [here](Example/Counter)):

```swift
// CounterModel.swift:
// Model to represent count
final class CounterModel: NSObject {
  @objc dynamic var count = 0
}

// CounterController.swift:
// Event to represent behavior for button ++ and --
enum CounterEvent {
  case increment
  case decrement
}

// Controller to represent how to update model
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
// View to represent model state, and emit event to notify controller to update model
final class ViewController: UIViewController {
  @IBOutlet weak var label: UILabel!
  @IBOutlet weak var incrButton: UIButton!
  @IBOutlet weak var decrButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
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
// Helper for button actions
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

### Decouple View and Model

Take a careful look at our `ViewController`, there's no any reference to model! Just adopt `View` protocol and bind model's count to label inside `func bind(model: Model, dispatcher: Dispatcher<Event>) -> View.BindingDisposer`. And bind event dispatcher to the increment and decrement buttons.

You can use KVO (this example) or other binding framework/library e.g. ReactiveCocoa w/ ReactiveSwift, RxSwift to bind model to view.

Check [Example/RandomImage](Example/RandomImage), which uses ReactiveCocoa for binding.

### Decouple View and Controller

There is no any reference to controller inside view too! `View` protocol also requires you bind event dispatcher. What's an event dispatcher? Just a wrapper for `(Event) -> Void`, you can use it to send event, Mvce will dispatch event to controller and inform it to update model.

### Glue Model, View, and Controller together

Glue 'em all with `Mvce.glue(model:view:controller:)`, inject to `loadView` or `viewDidLoad` in `UIViewController`/`NSViewController`. And lifetime is managed by Mvce.

### Cross-Platform (iOS & macOS)?

Sure, that's _REAL_ MVC's advantage! Model and Controller can be shared, only platform-independent view is required to rewrite.

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

That's it! Remember to check out [Example](Example) directory for a more complex one.

Don't forget to run `git submodule update --init --recursive` in order to install 3rd dependencies if you want to run the `RandomImage` sample project.

### `Dispatchable` protocol

If you really, really need to access event dispatcher anywhere in View or Controller, just adopt `Dispatchable`. This's last resort, I don't recommend this way, it's easily to mess up code, violate MVC rules.

## License

MIT

## Author

- Blog: [realazy.com](https://realazy.com) (Chinese)
- Github: [@cxa](https://github.com/cxa)
- Twitter: [@\_cxa](https://twitter.com/_cxa) (Chinese mainly)
