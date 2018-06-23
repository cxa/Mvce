//
//  Platform.swift
//  RandomImage
//
//  Created by CHEN Xian-an on 2018/6/17.
//  Copyright © 2018 realazy. All rights reserved.
//

#if canImport(UIkit)
import UIKit.UIImage
typealias Image = UIImage
#elseif canImport(AppKit)
import AppKit.NSImage
typealias Image = NSImage
#endif
