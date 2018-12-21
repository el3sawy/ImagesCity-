//
//  VCImage.swift
//  AppForMap
//
//  Created by Ahmed on 9/29/1397 AP.
//  Copyright © 1397 Ahmed. All rights reserved.
//

import UIKit

class VCImage: UIViewController  , UIGestureRecognizerDelegate{

    @IBOutlet weak var imagePlace: UIImageView!
    
    var passedImage : UIImage!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imagePlace.image = passedImage
        
        let doubleClick = UITapGestureRecognizer(target: self, action: #selector(clickImageToClocse))
        doubleClick.delegate = self
        doubleClick.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(doubleClick)
    }
    
    //Set Image
    func setImage(image : UIImage){
        self.passedImage = image
    }
    
    @objc func clickImageToClocse(){
        self.dismiss(animated: true, completion: nil)
    }
    

    

}
