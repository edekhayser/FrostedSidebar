FrostedSidebar
==============

Hamburger Menu using Swift and iOS 8 API's

Heavily influenced by @_ryannystrom's [RNFrostedSidebar](https://github.com/rnystrom/RNFrostedSidebar)

This implementation uses iOS 8's new UIVisualEffectView to apply the blur to the sidebar. Among other changes, this sidebar has a view that dims the background to shift the focus to the presented content.

<p align="center"><img title="Open and close animation" src="https://raw.githubusercontent.com/edekhayser/FrostedSidebar/master/entrance.gif"/></p>

The buttons have the same ring effect on click. The buttons are more customizable as I will go into later.

<p align="center"><img title="Button click animation" src="https://raw.githubusercontent.com/edekhayser/FrostedSidebar/master/callouts.gif"/></p>

##Usage##

In the example project, the sidebar is added quite easily.

Create a property in your UIViewController subclass.

```swift
var frostedSidebar: FrostedSidebar = FrostedSidebar(images: imageArray, colors: colorArray, selectedItemIndices: NSIndexSet())
```

where imageArray contains the icons for the buttons, and colorArray contains the border colors for the icons. 

The colors parameter is optional, and can either be nil, or be the same length as the imageArray.

In viewDidLoad, set the remaining properties that you want, including,

```swift
frostedSidebar.delegate                   //instance that receives delegate methods
frostedSidebar.showFromRight              //default = false
frostedSidebar.calloutsAlwaysSelected     //default = false, decides if the border is always shown
frostedSidebar.isSingleSelect             //default = false, if true, only 1 border shown at a time
```

calloutsAlwaysSelected and isSingleSelect are mutually exclusive. If one is true, the other is automatically set to false. 

The buttons can be set to perform a closure using

```swift
frostedSidebar.actionForIndex[idx] = { /* actions */ }
```

To show the sidebar, use the following code in your view controller:

```swift
frostedSidebar.showInViewController( self, animated: true )
```

The class that conforms to the FrostedSidebarDelegate must implement the following methods:
```swift
func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
func sidebar(sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int)
```

##Conclusion##

This would not be possible without the impressive work by Ryan Nystrom, and the great design by [Jakub Antalík on Dribbble](https://dribbble.com/shots/1194205-Sidebar-calendar-animation). 

Hopefully someone finds this useful!
