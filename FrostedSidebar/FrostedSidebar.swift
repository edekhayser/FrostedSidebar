//
//  FrostedSidebar.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit
import QuartzCore

public protocol FrostedSidebarDelegate{
    func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
    func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
    func sidebar(sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int)
}

var sharedSidebar: FrostedSidebar?

public class FrostedSidebar: UIViewController {
    
    //MARK: Public Properties
    
    public var width:                   CGFloat                     = 145.0
    public var showFromRight:           Bool                        = false
    public var animationDuration:       CGFloat                     = 0.25
    public var itemSize:                CGSize                      = CGSize(width: 90.0, height: 90.0)
    public var tintColor:               UIColor                     = UIColor(white: 0.2, alpha: 0.73)
    public var itemBackgroundColor:     UIColor                     = UIColor(white: 1, alpha: 0.25)
    public var borderWidth:             CGFloat                     = 2
    public var delegate:                FrostedSidebarDelegate?     = nil
    public var actionForIndex:         [Int : ()->()]              = [:]
    public var selectedIndices:        NSMutableIndexSet           = NSMutableIndexSet()
    //Only one of these properties can be used at a time. If one is true, the other automatically is false
    public var isSingleSelect:          Bool                        = false{
        didSet{
            if isSingleSelect{ calloutsAlwaysSelected = false }
        }
    }
    public var calloutsAlwaysSelected:  Bool                        = false{
        didSet{
            if calloutsAlwaysSelected{
                isSingleSelect = false
                selectedIndices = NSMutableIndexSet(indexesInRange: NSRange(location: 0,length: images.count) )
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
    
    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(itemImages: [UIImage], colors: [UIColor]?, selectedItemIndices: NSIndexSet?){
        contentView.alwaysBounceHorizontal = false
        contentView.alwaysBounceVertical = true
        contentView.bounces = true
        contentView.clipsToBounds = false
        contentView.showsHorizontalScrollIndicator = false
        contentView.showsVerticalScrollIndicator = false
        if colors != nil{
            assert(itemImages.count == colors!.count, "If item color are supplied, the itemImages and colors arrays must be of the same size.")
        }
        
        selectedIndices = selectedItemIndices != nil ? NSMutableIndexSet(indexSet: selectedItemIndices!) : NSMutableIndexSet()
        borderColors = colors
        images = itemImages
        
        for (index, image) in enumerate(images){
            let view = CalloutItem(index: index)
            view.clipsToBounds = true
            view.imageView.image = image
            contentView.addSubview(view)
            itemViews += [view]
            if borderColors != nil{
                if selectedIndices.containsIndex(index){
                    let color = borderColors![index]
                    view.layer.borderColor = color.CGColor
                }
            } else{
                view.layer.borderColor = UIColor.clearColor().CGColor
            }
        }
        
        super.init(nibName: nil, bundle: nil)
        
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
    
    public override func shouldAutorotate() -> Bool {
        return true
    }
    
    public override func supportedInterfaceOrientations() -> Int {
        return Int(UIInterfaceOrientationMask.All.rawValue)
    }
    
    public override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        super.willAnimateRotationToInterfaceOrientation(toInterfaceOrientation, duration: duration)
        
        if isViewLoaded(){
            dismissAnimated(false, completion: nil)
        }
    }
    
    public func showInViewController(viewController: UIViewController, animated: Bool){
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
            UIView.animateWithDuration(NSTimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.allZeros, animations: animations, completion: completion)
        } else{
            animations()
            completion(true)
        }
        
        for (index, item) in enumerate(itemViews){
            item.layer.transform = CATransform3DMakeScale(0.3, 0.3, 1)
            item.alpha = 0
            item.originalBackgroundColor = itemBackgroundColor
            item.layer.borderWidth = borderWidth
            animateSpringWithView(item, idx: index, initDelay: animationDuration)
        }
    }
    
    public func dismissAnimated(animated: Bool, completion: ((Bool) -> Void)?){
        let completionBlock: (Bool) -> Void = {finished in
            self.removeFromParentViewControllerCallingAppearanceMethods(true)
            self.delegate?.sidebar(self, didDismissFromScreenAnimated: true)
            self.layoutItems()
            if completion != nil{
                completion!(finished)
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
    }
    
    //MARK: Private Classes
    
    private class CalloutItem: UIView{
        var imageView:              UIImageView                 = UIImageView()
        var itemIndex:              Int
        var originalBackgroundColor:UIColor? {
        didSet{
            self.backgroundColor = originalBackgroundColor
        }
        }
        
        required init(coder aDecoder: NSCoder) {
            self.itemIndex = 0
            super.init(coder: aDecoder)
        }
        
        init(index: Int){
            imageView.backgroundColor = UIColor.clearColor()
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            itemIndex = index
            super.init(frame: CGRect.zeroRect)
            addSubview(imageView)
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            let inset: CGFloat = bounds.size.height/2
            imageView.frame = CGRect(x: 0, y: 0, width: inset, height: inset)
            imageView.center = CGPoint(x: inset, y: inset)
        }
        
        override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
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
        
        override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
            super.touchesEnded(touches, withEvent: event)
            backgroundColor = originalBackgroundColor
        }
        
        override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
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
            if tapIndex != nil{
                didTapItemAtIndex(tapIndex!)
            }
        }
    }
    
    private func didTapItemAtIndex(index: Int){
        let didEnable = !selectedIndices.containsIndex(index)
        if borderColors != nil{
            let stroke = borderColors![index]
            let item = itemViews[index]
            if didEnable{
                if isSingleSelect{
                    selectedIndices.removeAllIndexes()
                    for (index, item) in enumerate(itemViews){
                        item.layer.borderColor = UIColor.clearColor().CGColor
                    }
                }
                item.layer.borderColor = stroke.CGColor
                
                var borderAnimation = CABasicAnimation(keyPath: "borderColor")
                borderAnimation.fromValue = UIColor.clearColor().CGColor
                borderAnimation.toValue = stroke.CGColor
                borderAnimation.duration = 0.5
                item.layer.addAnimation(borderAnimation, forKey: nil)
                selectedIndices.addIndex(index)
				
            } else{
                if !isSingleSelect{
                    if !calloutsAlwaysSelected{
                        item.layer.borderColor = UIColor.clearColor().CGColor
                        selectedIndices.removeIndex(index)
                    }
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
    
    private func layoutSubviews(){
        let x = showFromRight ? parentViewController!.view.bounds.size.width - width : 0
        contentView.frame = CGRect(x: x, y: 0, width: width, height: parentViewController!.view.bounds.size.height)
        blurView.frame = contentView.frame
        layoutItems()
    }
    
    private func layoutItems(){
        let leftPadding: CGFloat = (width - itemSize.width) / 2
        let topPadding: CGFloat = leftPadding
        for (index, item) in enumerate(itemViews){
            let idx: CGFloat = CGFloat(index)
            let frame = CGRect(x: leftPadding, y: topPadding*idx + itemSize.height*idx + topPadding, width:itemSize.width, height: itemSize.height)
            item.frame = frame
            item.layer.cornerRadius = frame.size.width / 2
			item.layer.borderColor = UIColor.clearColor().CGColor
			item.alpha = 0
			if selectedIndices.containsIndex(index){
				if borderColors != nil{
					item.layer.borderColor = borderColors![index].CGColor
				}
			}
        }
        let itemCount = CGFloat(itemViews.count)
        contentView.contentSize = CGSizeMake(0, itemCount * (itemSize.height + topPadding) + topPadding)
    }
    
    private func indexOfTap(location: CGPoint) -> Int? {
        var index: Int?
        for (idx, item) in enumerate(itemViews){
            if CGRectContainsPoint(item.frame, location){
                index = idx
                break
            }
        }
        return index
    }
    
    private func addToParentViewController(viewController: UIViewController, callingAppearanceMethods: Bool){
        if (parentViewController != nil){
            removeFromParentViewControllerCallingAppearanceMethods(callingAppearanceMethods)
        }
        if callingAppearanceMethods{
            beginAppearanceTransition(true, animated: false)
        }
        viewController.addChildViewController(self)
        viewController.view.addSubview(self.view)
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