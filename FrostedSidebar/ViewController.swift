//
//  ViewController.swift
//  CustomStuff
//
//  Created by Evan Dekhayser on 7/9/14.
//  Copyright (c) 2014 Evan Dekhayser. All rights reserved.
//

import UIKit

class ViewController: UIViewController, FrostedSidebarDelegate {
    
	var frostedSidebar: FrostedSidebar = FrostedSidebar(itemImages: [
			UIImage(named: "gear"),
			UIImage(named: "globe"),
			UIImage(named: "profile"),
			UIImage(named: "star"),
			UIImage(named: "gear"),
			UIImage(named: "globe"),
			UIImage(named: "profile"),
			UIImage(named: "star"),
			UIImage(named: "gear"),
			UIImage(named: "globe"),
			UIImage(named: "profile"),
			UIImage(named: "star")],
		colors: [
			UIColor(red: 240/255, green: 159/255, blue: 254/255, alpha: 1),
			UIColor(red: 255/255, green: 137/255, blue: 167/255, alpha: 1),
			UIColor(red: 126/255, green: 242/255, blue: 195/255, alpha: 1),
			UIColor(red: 119/255, green: 152/255, blue: 255/255, alpha: 1),
			UIColor(red: 240/255, green: 159/255, blue: 254/255, alpha: 1),
			UIColor(red: 255/255, green: 137/255, blue: 167/255, alpha: 1),
			UIColor(red: 126/255, green: 242/255, blue: 195/255, alpha: 1),
			UIColor(red: 119/255, green: 152/255, blue: 255/255, alpha: 1),
			UIColor(red: 240/255, green: 159/255, blue: 254/255, alpha: 1),
			UIColor(red: 255/255, green: 137/255, blue: 167/255, alpha: 1),
			UIColor(red: 126/255, green: 242/255, blue: 195/255, alpha: 1),
			UIColor(red: 119/255, green: 152/255, blue: 255/255, alpha: 1)],
		selectedItemIndices: NSIndexSet())
	
	override func viewDidLoad() {
		super.viewDidLoad()
		frostedSidebar.delegate = self
		
		frostedSidebar.calloutsAlwaysSelected = true
		//			frostedSidebar.showFromRight = true
		//			frostedSidebara.isSingleSelect = true
		
		frostedSidebar.actionForIndex[0] = { self.frostedSidebar.dismissAnimated(true, completion: nil) }
	}
	
	@IBAction func onBurger() {
        frostedSidebar.showInViewController(self, animated: true)
    }

    func sidebar(sidebar: FrostedSidebar, willShowOnScreenAnimated animated: Bool){

	}
    func sidebar(sidebar: FrostedSidebar, didShowOnScreenAnimated animated: Bool){
        
    }
    func sidebar(sidebar: FrostedSidebar, willDismissFromScreenAnimated animated: Bool){
        
    }
    func sidebar(sidebar: FrostedSidebar, didDismissFromScreenAnimated animated: Bool){

	}
    func sidebar(sidebar: FrostedSidebar, didTapItemAtIndex index: Int){
        
    }
    func sidebar(sidebar: FrostedSidebar, didEnable itemEnabled: Bool, itemAtIndex index: Int){
        
    }
    
}

