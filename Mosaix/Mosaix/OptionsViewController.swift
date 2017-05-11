//
//  OptionsViewController.swift
//  Mosaix
//
//  Created by Nathan Eliason on 4/11/17.
//  Copyright © 2017 Nathan Eliason. All rights reserved.
//

import UIKit

class OptionsViewController: UIViewController {
    
    @IBOutlet var tpaSwitch: UISwitch! = UISwitch()
    var tpaSwitchParallel: Bool = true
    @IBOutlet var selectionSwitch: UISwitch! = UISwitch()
    var selectionSwitchParallel: Bool = true 

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tpaSwitchParallel = (tpaSwitch.isOn) ? true : false
        selectionSwitchParallel = (selectionSwitch.isOn) ? true : false

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func tpaSwitchChanged() {
        tpaSwitchParallel = (tpaSwitch.isOn) ? true : false
    }
    
    @IBAction func selectionSwitchChanged() {
        selectionSwitchParallel = (selectionSwitch.isOn) ? true : false
    }
    
    @IBAction func onDone() {
        
    }

}
