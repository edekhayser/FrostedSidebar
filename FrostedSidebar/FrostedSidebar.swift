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
    func sidebar(_ sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar was shown on screen.
     
     - Parameter sidebar: The sidebar that was shown.
     - Parameter animated: If the sidebar was animated.
     */
    func sidebar(_ sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar will be dismissed.
     
     - Parameter sidebar: The sidebar that will be dismissed.
     - Parameter animated: If the sidebar will be animated.
     */
    func sidebar(_ sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool)
    /**
     Delegate method called when FrostedSidebar was dismissed.
     
     - Parameter sidebar: The sidebar that was dismissed.
     - Parameter animated: If the sidebar was animated.
     */
    func sidebar(_ sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool)
    /**
     Delegate method called when an item was tapped.
     
     - Parameter sidebar: The sidebar that's item was tapped.
     - Parameter index: The index of the tapped item.
     */
    func sidebar(_ sidebar: FrostedSidebar, didTapItemAtIndex index: Int)
    /**
     Delegate method called when an item was enabled.
     
     - Parameter sidebar: The sidebar that's item was tapped.
     - Parameter itemEnabled: The enabled status of the tapped item.
     - Parameter index: The index of the tapped item.
     */
    func sidebar(_ sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int)
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
    case none
    /**
     Only a single sidebar item is selected.
    */
    case single
    /**
     All sidebar items are selected at all times.
    */
    case all
}

/**
 Animated Sidebar.
*/
open class FrostedSidebar: UIViewController {
    
    //MARK: Public Properties
    /**
     The width of the sidebar.
    */
    open var width:                   CGFloat                     = 145.0
    /**
     If the sidebar should show from the right.
    */
    open var showFromRight:           Bool                        = false
    /**
     The speed at which the sidebar is presented/dismissed.
    */
    open var animationDuration:       CGFloat                     = 0.25
    /**
     The size of the sidebar items.
    */
    open var itemSize:                CGSize                      = CGSize(width: 90.0, height: 90.0)
    /**
     The background color of the sidebar items.
    */
    open var itemBackgroundColor:     UIColor                     = UIColor(white: 1, alpha: 0.25)
    /**
     The width of the ring around selected sidebar items.
    */
    open var borderWidth:             CGFloat                     = 2
    /**
     The sidebar's delegate.
    */
    open var delegate:                FrostedSidebarDelegate?     = nil
    /**
     A dictionary that holds the actions for each item index.
    */
    open var actionForIndex:          [Int : ()->()]              = [:]
    /**
     The indexes that are selected and have rings around them.
    */
    open var selectedIndices:         NSMutableIndexSet           = NSMutableIndexSet()
    /**
     If the sidebar should be positioned beneath a navigation bar that is on screen.
    */
    open var adjustForNavigationBar:  Bool                        = false
    /**
     Returns whether or not the sidebar is currently being displayed
    */
    open var isCurrentlyOpen:         Bool                        = false
    /**
     The selection style for the sidebar.
    */
    open var selectionStyle:          SidebarItemSelectionStyle   = .none{
        didSet{
            if case .all = selectionStyle{
                selectedIndices = NSMutableIndexSet(indexesIn: NSRange(location: 0, length: images.count))
            }
        }
    }
    
    //MARK: Private Properties
    
    fileprivate var contentView:            UIScrollView                = UIScrollView()
    fileprivate var blurView:               UIVisualEffectView          = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    fileprivate var dimView:                UIView                      = UIView()
    fileprivate var tapGesture:             UITapGestureRecognizer?     = nil
    fileprivate var images:                 [UIImage]                   = []
    fileprivate var borderColors:           [UIColor]?                  = nil
    fileprivate var itemViews:              [CalloutItem]               = []
    
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
        
        for (index, image) in images.enumerated(){
            let view = CalloutItem(index: index)
            view.clipsToBounds = true
            view.imageView.image = image
            contentView.addSubview(view)
            itemViews += [view]
            if let borderColors = borderColors{
                if selectedIndices.contains(index){
                    let color = borderColors[index]
                    view.layer.borderColor = color.cgColor
                }
            } else{
                view.layer.borderColor = UIColor.clear.cgColor
            }
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    open override var shouldAutorotate : Bool {
        return true
    }
    
    open override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        if isViewLoaded{
            dismissAnimated(false, completion: nil)
        }
    }
    
    open override func loadView() {
        super.loadView()
        view.backgroundColor = UIColor.clear
        view.addSubview(dimView)
        view.addSubview(blurView)
        view.addSubview(contentView)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(FrostedSidebar.handleTap(_:)))
        view.addGestureRecognizer(tapGesture!)
    }
    
    /**
     Shows the sidebar in a view controller.
     
     - Parameter viewController: The view controller in which to show the sidebar.
     - Parameter animated: If the sidebar should be animated.
    */
    open func showInViewController(_ viewController: UIViewController, animated: Bool){
        layoutItems()
        if let bar = sharedSidebar{
            bar.dismissAnimated(false, completion: nil)
        }
        
        delegate?.sidebar(self, willShowOnScreenAnimated: animated)
        
        sharedSidebar = self
        
        addToParentViewController(viewController, callingAppearanceMethods: true)
        view.frame = viewController.view.bounds
        
        dimView.backgroundColor = UIColor.black
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
        blurView.contentMode = showFromRight ? UIViewContentMode.topRight : UIViewContentMode.topLeft
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
            UIView.animate(withDuration: TimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions(), animations: animations, completion: completion)
        } else{
            animations()
            completion(true)
        }
        
        for (index, item) in itemViews.enumerated(){
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
    open func dismissAnimated(_ animated: Bool, completion: ((Bool) -> Void)?){
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
            UIView.animate(withDuration: TimeInterval(animationDuration), delay: 0, options: UIViewAnimationOptions.beginFromCurrentState, animations: {
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
    open func selectItemAtIndex(_ index: Int){
        let didEnable = !selectedIndices.contains(index)
        if let borderColors = borderColors{
            let stroke = borderColors[index]
            let item = itemViews[index]
            if didEnable{
                if case .single = selectionStyle{
                    selectedIndices.removeAllIndexes()
                    for item in itemViews{
                        item.layer.borderColor = UIColor.clear.cgColor
                    }
                }
                item.layer.borderColor = stroke.cgColor
                
                let borderAnimation = CABasicAnimation(keyPath: "borderColor")
                borderAnimation.fromValue = UIColor.clear.cgColor
                borderAnimation.toValue = stroke.cgColor
                borderAnimation.duration = 0.5
                item.layer.add(borderAnimation, forKey: nil)
                selectedIndices.add(index)
                
            } else{
                if case .none = selectionStyle{
                        item.layer.borderColor = UIColor.clear.cgColor
                        selectedIndices.remove(index)
                }
            }
            let pathFrame = CGRect(x: -item.bounds.midX, y: -item.bounds.midY, width: item.bounds.size.width, height: item.bounds.size.height)
            let path = UIBezierPath(roundedRect: pathFrame, cornerRadius: item.layer.cornerRadius)
            let shapePosition = view.convert(item.center, from: contentView)
            let circleShape = CAShapeLayer()
            circleShape.path = path.cgPath
            circleShape.position = shapePosition
            circleShape.fillColor = UIColor.clear.cgColor
            circleShape.opacity = 0
            circleShape.strokeColor = stroke.cgColor
            circleShape.lineWidth = borderWidth
            view.layer.addSublayer(circleShape)
            
            let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
            scaleAnimation.fromValue = NSValue(caTransform3D: CATransform3DIdentity)
            scaleAnimation.toValue = NSValue(caTransform3D: CATransform3DMakeScale(2.5, 2.5, 1))
            let alphaAnimation = CABasicAnimation(keyPath: "opacity")
            alphaAnimation.fromValue = 1
            alphaAnimation.toValue = 0
            let animation = CAAnimationGroup()
            animation.animations = [scaleAnimation, alphaAnimation]
            animation.duration = 0.5
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
            circleShape.add(animation, forKey: nil)
        }
        if let action = actionForIndex[index]{
            action()
        }
        delegate?.sidebar(self, didTapItemAtIndex: index)
        delegate?.sidebar(self, didEnable: didEnable, itemAtIndex: index)
    }
    
    //MARK: Private Classes
    
    fileprivate class CalloutItem: UIView{
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
            imageView.backgroundColor = UIColor.clear
            imageView.contentMode = UIViewContentMode.scaleAspectFit
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
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesBegan(touches, with: event)
            
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            let darkenFactor: CGFloat = 0.3
            var darkerColor: UIColor
            if originalBackgroundColor != nil && originalBackgroundColor!.getRed(&r, green: &g, blue: &b, alpha: &a){
                darkerColor = UIColor(red: max(r - darkenFactor, 0), green: max(g - darkenFactor, 0), blue: max(b - darkenFactor, 0), alpha: a)
            } else if originalBackgroundColor != nil && originalBackgroundColor!.getWhite(&r, alpha: &a){
                darkerColor = UIColor(white: max(r - darkenFactor, 0), alpha: a)
            } else{
                darkerColor = UIColor.clear
                assert(false, "Item color should be RBG of White/Alpha in order to darken the button")
            }
            backgroundColor = darkerColor
        }
        
        override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesEnded(touches, with: event)
            backgroundColor = originalBackgroundColor
        }
        
        override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
            super.touchesCancelled(touches, with: event)
            backgroundColor = originalBackgroundColor
        }
        
    }
    
    //MARK: Private Methods
    
    fileprivate func animateSpringWithView(_ view: CalloutItem, idx: Int, initDelay: CGFloat){
        let delay: TimeInterval = TimeInterval(initDelay) + TimeInterval(idx) * 0.1
        UIView.animate(withDuration: 0.5,
            delay: delay,
            usingSpringWithDamping: 10.0,
            initialSpringVelocity: 50.0,
            options: UIViewAnimationOptions.beginFromCurrentState,
            animations: {
                view.layer.transform = CATransform3DIdentity
                view.alpha = 1
            },
            completion: nil)
    }
    
    @objc fileprivate func handleTap(_ recognizer: UITapGestureRecognizer){
        let location = recognizer.location(in: view)
        if !contentView.frame.contains(location){
            dismissAnimated(true, completion: nil)
        } else{
            let tapIndex = indexOfTap(recognizer.location(in: contentView))
            if let tapIndex = tapIndex{
                selectItemAtIndex(tapIndex)
            }
        }
    }
    
    fileprivate func layoutSubviews(){
        let x = showFromRight ? parent!.view.bounds.size.width - width : 0
        contentView.frame = CGRect(x: x, y: 0, width: width, height: parent!.view.bounds.size.height)
        blurView.frame = contentView.frame
        layoutItems()
    }
    
    fileprivate func layoutItems(){
        let leftPadding: CGFloat = (width - itemSize.width) / 2
        let topPadding: CGFloat = leftPadding
        for (index, item) in itemViews.enumerated(){
            let idx: CGFloat = adjustForNavigationBar ? CGFloat(index) + 0.5 : CGFloat(index)
            
            let frame = CGRect(x: leftPadding, y: topPadding*idx + itemSize.height*idx + topPadding, width:itemSize.width, height: itemSize.height)
            item.frame = frame
            item.layer.cornerRadius = frame.size.width / 2
            item.layer.borderColor = UIColor.clear.cgColor
            item.alpha = 0
            if selectedIndices.contains(index){
                if let borderColors = borderColors{
                    item.layer.borderColor = borderColors[index].cgColor
                }
            }
        }
        let itemCount = CGFloat(itemViews.count)
        if adjustForNavigationBar{
            contentView.contentSize = CGSize(width: 0, height: (itemCount + 0.5) * (itemSize.height + topPadding) + topPadding)
        } else {
            contentView.contentSize = CGSize(width: 0, height: itemCount * (itemSize.height + topPadding) + topPadding)
        }
    }
    
    fileprivate func indexOfTap(_ location: CGPoint) -> Int? {
        var index: Int?
        for (idx, item) in itemViews.enumerated(){
            if item.frame.contains(location){
                index = idx
                break
            }
        }
        return index
    }
    
    fileprivate func addToParentViewController(_ viewController: UIViewController, callingAppearanceMethods: Bool){
        if let _ = parent{
            removeFromParentViewControllerCallingAppearanceMethods(callingAppearanceMethods)
        }
        if callingAppearanceMethods{
            beginAppearanceTransition(true, animated: false)
        }
        viewController.addChildViewController(self)
        viewController.view.addSubview(view)
        didMove(toParentViewController: self)
        if callingAppearanceMethods{
            endAppearanceTransition()
        }
    }
    
    fileprivate func removeFromParentViewControllerCallingAppearanceMethods(_ callAppearanceMethods: Bool){
        
        if callAppearanceMethods{
            beginAppearanceTransition(false, animated: false)
        }
        willMove(toParentViewController: nil)
        view.removeFromSuperview()
        removeFromParentViewController()
        if callAppearanceMethods{
            endAppearanceTransition()
        }
    }
}
