//
//  FrostedSidebar.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import QuartzCore

/**
 Delegate for FrostedSidebar.
*/
public protocol FrostedSidebarDelegate{
    /**
     Delegate method called when FrostedSidebar will show on screen.
     
     - Parameter sidebar: The sidebar that will be shown.
     - Parameter animated: If the sidebar will be animated.
    */
    func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar was shown on screen.
     
     - Parameter sidebar: The sidebar that was shown.
     - Parameter animated: If the sidebar was animated.
     */
    func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar will be dismissed.
     
     - Parameter sidebar: The sidebar that will be dismissed.
     - Parameter animated: If the sidebar will be animated.
     */
    func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar was dismissed.
     
     - Parameter sidebar: The sidebar that was dismissed.
     - Parameter animated: If the sidebar was animated.
     */
    func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
    /**
     Delegate method called when an item was tapped.
     
     - Parameter sidebar: The sidebar that's item was tapped.
     - Parameter index: The index of the tapped item.
     */
    func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
    /**
     Delegate method called when an item was enabled.
     
     - Parameter sidebar: The sidebar that's item was tapped.
     - Parameter itemEnabled: The enabled status of the tapped item.
     - Parameter index: The index of the tapped item.
     */
    func sidebar(sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int)
}

/**
 Instance representing the last-used FrostedSidebar in the app.
*/
var sharedSidebar: FrostedSidebar?

/**
 Selection behavior for FrostedSidebar.
*/
public enum SidebarItemSelectionStyle{
    /**
     No sidebar items are selected.
    */
    case None
    /**
     Only a single sidebar item is selected.
    */
    case Single
    /**
     All sidebar items are selected at all times.
    */
    case All
}

/**
 Animated Sidebar.
*/
public class FrostedSidebar: UIViewController {
    
    //MARK: Public Properties
    /**
     The width of the sidebar.
    */
    public var width:                   CGFloat                     = 145.0
    /**
     If the sidebar should show from the right.
    */
    public var showFromRight:           Bool                        = false
    /**
     The speed at which the sidebar is presented/dismissed.
    */
    public var animationDuration:       CGFloat                     = 0.25
    /**
     The size of the sidebar items.
    */
    public var itemSize:                CGSize                      = CGSize(width: 90.0, height: 90.0)
    /**
     The background color of the sidebar items.
    */
    public var itemBackgroundColor:     UIColor                     = UIColor(white: 1, alpha: 0.25)
    /**
     The width of the ring around selected sidebar items.
    */
    public var borderWidth:             CGFloat                     = 2
    /**
     The sidebar's delegate.
    */
    public var delegate:                FrostedSidebarDelegate?     = nil
    /**
     A dictionary that holds the actions for each item index.
    */
    public var actionForIndex:          [Int : ()->()]              = [:]
    /**
     The indexes that are selected and have rings around them.
    */
    public var selectedIndices:         NSMutableIndexSet           = NSMutableIndexSet()
    /**
     If the sidebar should be positioned beneath a navigation bar that is on screen.
    */
    public var adjustForNavigationBar:  Bool                        = false
    /**
     Returns whether or not the sidebar is currently being displayed
    */
    public var isCurrentlyOpen:         Bool                        = false
    /**
     The selection style for the sidebar.
    */
    public var selectionStyle:          SidebarItemSelectionStyle   = .None{
        didSet{
            if case .All = selectionStyle{
                selectedIndices = NSMutableIndexSet(indexesInRange: NSRange(location: 0, length: images.count))
            }
        }
    }
    
    //MARK: Private Properties
    
    private var contentView:            UIScrollView                = UIScrollView()
    private var blurView:               UIVisualEffectView          = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    private var dimView:                UIView                      = UIView()
    private var tapGesture:             UITapGestureRecognizer?     = nil
    private var images:                 [UIImage]                   = []
    private var borderColors:           [UIColor]?                  = nil
    private var itemViews:              [CalloutItem]               = []
    
    //MARK: Public Methods
    
    /**
     Returns an object initialized from data in a given unarchiver.
    */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Returns a sidebar initialized with the given data.
     
     - Parameter itemImages: The images that will be used for each item.
     - Parameter colors: The color of rings around each image.
     - Parameter selectionStyle: The selection style for the sidebar.
     
     - Precondition: `colors` is either `nil` or contains the same number of elements as `itemImages`.
    */
    public init(itemImages: [UIImage], colors: [UIColor]?, selectionStyle: SidebarItemSelectionStyle){
        contentView.alwaysBounceHorizontal = false
        contentView.alwaysBounceVertical = true
        contentView.bounces = true
        contentView.clipsToBounds = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        if let colors = colors{
            assert(itemImages.count == colors.count, "If item color are supplied, the itemImages and colors arrays must be of the same size.")
        }
        
        self.selectionStyle = selectionStyle
        borderColors = colors
        images = itemImages
        
        for (index, image) in images.enumerate(){
            let view = CalloutItem(index: index)
            view.clipsToBounds = true
            view.imageView.image = image
            contentView.addSubview(view)
            itemViews += [view]
            if let borderColors = borderColors{
                if selectedIndices.containsIndex(index){
                    let color = borderColors[index]
                    view.layer.borderColor = color.CGColor
                }
            } else{
                view.layer.borderColor = UIColor.clearColor().CGColor
            }
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    public override func shouldAutorotate() -> Bool {
        return true
    }
    
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
    
    public override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        if isViewLoaded(){
            dismissAnimated(false, completion: nil)
        }
    }
    
    public override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.clearColor()
        view.addSubview(dimView)
        view.addSubview(blurView)
        view.addSubview(contentView)
        tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        view.addGestureRecognizer(tapGesture!)
    }
    
    /**
     Shows the sidebar in a view controller.
     
     - Parameter viewController: The view controller in which to show the sidebar.
     - Parameter animated: If the sidebar should be animated.
    */
    public func showInViewController(viewController: UIViewController, animated: Bool){
        layoutItems()
        if let bar = sharedSidebar{
            bar.dismissAnimated(false, completion: nil)
        }
        
        delegate?.sidebar(self, willShowOnScreenAnimated: animated)
        
        sharedSidebar = self
        
        addToParentViewController(viewController, callingAppearanceMethods: true)
        view.frame = viewController.view.bounds
        
        dimView.backgroundColor = UIColor.blackColor()
        dimView.alpha = 0
        dimView.frame = view.bounds
        
        let parentWidth = view.bounds.size.width
        var contentFrame = view.bounds
        contentFrame.origin.x = showFromRight ? parentWidth : -width
        contentFrame.size.width = width
        contentView.frame = contentFrame
        contentView.contentOffset = CGPoint(x: 0, y: 0)
        layoutItems()
        
        var blurFrame = CGRect(x: showFromRight ? view.bounds.size.width : 0, y: 0, width: 0, height: view.bounds.size.height)
        blurView.frame = blurFrame
        blurView.contentMode = showFromRight ? UIViewContentMode.TopRight : UIViewContentMode.TopLeft
        blurView.clipsToBounds = true
        view.insertSubview(blurView, belowSubview: contentView)
        
        contentFrame.origin.x = showFromRight ? parentWidth - width : 0
        blurFrame.origin.x = contentFrame.origin.x
        blurFrame.size.width = width
        
        let animations: () -> () = {
            self.contentView.frame = contentFrame
            self.blurView.frame = blurFrame
            self.dimView.alpha = 0.25
        }
        let completion: (Bool) -> Void = { finished in
            if finished{
                self.delegate?.sidebar(self, didShowOnScreenAnimated: animated)
            }
        }
        
        if animated{
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions(), animations: animations, completion: completion)
        } else{
            animations()
            completion(true)
        }
        
        for (index, item) in itemViews.enumerate(){
            item.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1)
            item.alpha = 0
            item.originalBackgroundColor = itemBackgroundColor
            item.layer.borderWidth = borderWidth
            animateSpringWithView(item, idx: index, initDelay: animationDuration)
        }
        
        self.isCurrentlyOpen = true
    }
    
    /**
     Dismisses the sidebar.
     
     - Parameter animated: If the sidebar should be animated.
     - Parameter completion: Completion handler called when the sidebar is dismissed.
    */
    public func dismissAnimated(animated: Bool, completion: ((Bool) -> Void)?){
        let completionBlock: (Bool) -> Void = {finished in
            self.removeFromParentViewControllerCallingAppearanceMethods(true)
            self.delegate?.sidebar(self, didDismissFromScreenAnimated: true)
            self.layoutItems()
            if let completion = completion{
                completion(finished)
            }
        }
        delegate?.sidebar(self, willDismissFromScreenAnimated: animated)
        if animated{
            let parentWidth = view.bounds.size.width
            var contentFrame = contentView.frame
            contentFrame.origin.x = showFromRight ? parentWidth : -width
            var blurFrame = blurView.frame
            blurFrame.origin.x = showFromRight ? parentWidth : 0
            blurFrame.size.width = 0
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.contentView.frame = contentFrame
                self.blurView.frame = blurFrame
                self.dimView.alpha = 0
                }, completion: completionBlock)
        } else{
            completionBlock(true)
        }
        
        self.isCurrentlyOpen = false
    }
    
    /**
     Selects the item at the given index.
     
     - Parameter index: The index of the item to select.
    */
    public func selectItemAtIndex(index: Int){
        let didEnable = !selectedIndices.containsIndex(index)
        if let borderColors = borderColors{
            let stroke = borderColors[index]
            let item = itemViews[index]
            if didEnable{
                if case .Single = selectionStyle{
                    selectedIndices.removeAllIndexes()
                    for item in itemViews{
                        item.layer.borderColor = UIColor.clearColor().CGColor
                    }
                }
                item.layer.borderColor = stroke.CGColor
                
                let borderAnimation = CABasicAnimation(keyPath: "borderColor")
                borderAnimation.fromValue = UIColor.clearColor().CGColor
                borderAnimation.toValue = stroke.CGColor
                borderAnimation.duration = 0.5
                item.layer.addAnimation(borderAnimation, forKey: nil)
                selectedIndices.addIndex(index)
                
            } else{
                if case .None = selectionStyle{
                        item.layer.borderColor = UIColor.clearColor().CGColor
                        selectedIndices.removeIndex(index)
                }
            }
            let pathFrame = CGRect(x: -CGRectGetMidX(item.bounds), y: -CGRectGetMidY(item.bounds), width: item.bounds.size.width, height: item.bounds.size.height)
            let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: item.layer.cornerRadius)
            let shapePosition = view.convertPoint(item.center, fromView: contentView)
            let circleShape = CAShapeLayer()
            circleShape.path = path.CGPath
            circleShape.position = shapePosition
            circleShape.fillColor = UIColor.clearColor().CGColor
            circleShape.opacity = 0
            circleShape.strokeColor = stroke.CGColor
            circleShape.lineWidth = borderWidth
            view.layer.addSublayer(circleShape)
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = NSValue(CATransform3D: CATransform3DIdentity)
            scaleAnimation.toValue = NSValue(CATransform3D: CATransform3DMakeScale(2.5, 2.5, 1))
            let alphaAnimation = CABasicAnimation(keyPath: "opacity")
            alphaAnimation.fromValue = 1
            alphaAnimation.toValue = 0
            let animation = CAAnimationGroup()
            animation.animations = [scaleAnimation, alphaAnimation]
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            circleShape.addAnimation(animation, forKey: nil)
        }
        if let action = actionForIndex[index]{
            action()
        }
        delegate?.sidebar(self, didTapItemAtIndex: index)
        delegate?.sidebar(self, didEnable: didEnable, itemAtIndex: index)
    }
    
    //MARK: Private Classes
    
    private class CalloutItem: UIView{
        var imageView:              UIImageView                 = UIImageView()
        var itemIndex:              Int
        var originalBackgroundColor:UIColor? {
            didSet{
                backgroundColor = originalBackgroundColor
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            itemIndex = 0
            super.init(coder: aDecoder)
        }
        
        init(index: Int){
            imageView.backgroundColor = UIColor.clearColor()
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            itemIndex = index
            super.init(frame: CGRect.zero)
            addSubview(imageView)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let inset: CGFloat = bounds.size.height/2
            imageView.frame = CGRect(x: 0, y: 0, width: inset, height: inset)
            imageView.center = CGPoint(x: inset, y: inset)
        }
        
        override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
            super.touchesBegan(touches, withEvent: event)
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            let darkenFactor: CGFloat = 0.3
            var darkerColor: UIColor
            if originalBackgroundColor != nil && originalBackgroundColor!.getRed(&r, green: &g, blue: &b, alpha: &a){
                darkerColor = UIColor(red: max(r - darkenFactor, 0), green: max(g - darkenFactor, 0), blue: max(b - darkenFactor, 0), alpha: a)
            } else if originalBackgroundColor != nil && originalBackgroundColor!.getWhite(&r, alpha: &a){
                darkerColor = UIColor(white: max(r - darkenFactor, 0), alpha: a)
            } else{
                darkerColor = UIColor.clearColor()
                assert(false, "Item color should be RBG of White/Alpha in order to darken the button")
            }
            backgroundColor = darkerColor
        }
        
        override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
            super.touchesEnded(touches, withEvent: event)
            backgroundColor = originalBackgroundColor
        }
        
        override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
            super.touchesCancelled(touches, withEvent: event)
            backgroundColor = originalBackgroundColor
        }
        
    }
    
    //MARK: Private Methods
    
    private func animateSpringWithView(view: CalloutItem, idx: Int, initDelay: CGFloat){
        let delay: NSTimeInterval = NSTimeInterval(initDelay) + NSTimeInterval(idx) * 0.1
        UIView.animateWithDuration(0.5,
            delay: delay,
            usingSpringWithDamping: 10.0,
            initialSpringVelocity: 50.0,
            options: UIViewAnimationOptions.BeginFromCurrentState,
            animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1
            },
            completion: nil)
    }
    
    @objc private func handleTap(recognizer: UITapGestureRecognizer){
        let location = recognizer.locationInView(view)
        if !CGRectContainsPoint(contentView.frame, location){
            dismissAnimated(true, completion: nil)
        } else{
            let tapIndex = indexOfTap(recognizer.locationInView(contentView))
            if let tapIndex = tapIndex{
                selectItemAtIndex(tapIndex)
            }
        }
    }
    
    private func layoutSubviews(){
        let x = showFromRight ? parentViewController!.view.bounds.size.width - width : 0
        contentView.frame = CGRect(x: x, y: 0, width: width, height: parentViewController!.view.bounds.size.height)
        blurView.frame = contentView.frame
        layoutItems()
    }
    
    private func layoutItems(){
        let leftPadding: CGFloat = (width - itemSize.width) / 2
        let topPadding: CGFloat = leftPadding
        for (index, item) in itemViews.enumerate(){
            let idx: CGFloat = adjustForNavigationBar ? CGFloat(index) + 0.5 : CGFloat(index)
            
            let frame = CGRect(x: leftPadding, y: topPadding*idx + itemSize.height*idx + topPadding, width:itemSize.width, height: itemSize.height)
            item.frame = frame
            item.layer.cornerRadius = frame.size.width / 2
            item.layer.borderColor = UIColor.clearColor().CGColor
            item.alpha = 0
            if selectedIndices.containsIndex(index){
                if let borderColors = borderColors{
                    item.layer.borderColor = borderColors[index].CGColor
                }
            }
        }
        let itemCount = CGFloat(itemViews.count)
        if adjustForNavigationBar{
            contentView.contentSize = CGSizeMake(0, (itemCount + 0.5) * (itemSize.height + topPadding) + topPadding)
        } else {
            contentView.contentSize = CGSizeMake(0, itemCount * (itemSize.height + topPadding) + topPadding)
        }
    }
    
    private func indexOfTap(location: CGPoint) -> Int? {
        var index: Int?
        for (idx, item) in itemViews.enumerate(){
            if CGRectContainsPoint(item.frame, location){
                index = idx
                break
            }
        }
        return index
    }
    
    private func addToParentViewController(viewController: UIViewController, callingAppearanceMethods: Bool){
        if let _ = parentViewController{
            removeFromParentViewControllerCallingAppearanceMethods(callingAppearanceMethods)
        }
        if callingAppearanceMethods{
            beginAppearanceTransition(true, animated: false)
        }
        viewController.addChildViewController(self)
        viewController.view.addSubview(view)
        didMoveToParentViewController(self)
        if callingAppearanceMethods{
            endAppearanceTransition()
        }
    }
    
    private func removeFromParentViewControllerCallingAppearanceMethods(callAppearanceMethods: Bool){
        
        if callAppearanceMethods{
            beginAppearanceTransition(false, animated: false)
        }
        willMoveToParentViewController(nil)
        view.removeFromSuperview()
        removeFromParentViewController()
        if callAppearanceMethods{
            endAppearanceTransition()
        }
    }
}