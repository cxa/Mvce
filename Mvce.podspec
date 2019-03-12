Pod::Spec.new do |s|
  s.name                  = "Mvce"
  s.version               = "5.0.0"
  s.summary               = "A minimal, simple, unobtrusive, and event driven MVC library to glue decoupled Model, View, and Controller for UIKit/AppKit."
  s.homepage              = "https://github.com/cxa/Mvce"
  s.license               = "MIT"
  s.author                = { "CHEN Xian-an" => "xianan.chen@gmail.com" }
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.source                = { :git => "https://github.com/cxa/Mvce.git", :tag => "#{s.version}" }
  s.source_files          = "Mvce/*.{h,swift}"
  s.swift_version         = "4.2"
end
