//
//  HelperImages.swift
//  SapCiscoTuto
//
//  Created by Guillaume Henique on 09/08/2018.
//  Copyright © 2018 SAP. All rights reserved.
//

import UIKit

class HelperImages {
    
    
    
    
    static func imageFromCategory(category: String) -> UIImage? {
        switch category {
        case "Notebooks":
            return #imageLiteral(resourceName: "Notebook")
        case "PDAs & Organizers":
            return #imageLiteral(resourceName: "pda")
        case "Flat Screen Monitors":
            return #imageLiteral(resourceName: "flatscreen")
        case "Laser Printers":
            return #imageLiteral(resourceName: "laserprinter")
        case "Ink Jet Printers":
            return #imageLiteral(resourceName: "inkjetprinter")
        case "Multifunction Printers":
            return #imageLiteral(resourceName: "multiprinter")
        case "Mice":
            return #imageLiteral(resourceName: "mice")
        case "Keyboards":
            return #imageLiteral(resourceName: "keyboard")
        case "Mousepads":
            return #imageLiteral(resourceName: "mousepad")
        case "Graphic Cards":
            return #imageLiteral(resourceName: "graphiccards")
        case "Scanners":
            return #imageLiteral(resourceName: "scanner")
        case "Speakers":
            return #imageLiteral(resourceName: "speakers")
        case "Projectors":
            return #imageLiteral(resourceName: "JVC_D-ILA_projector")
        case "Computer System Accessories":
            return #imageLiteral(resourceName: "cheap-computer-accessories")
        case "Software":
            return #imageLiteral(resourceName: "software")
        case "Portable Players":
            return #imageLiteral(resourceName: "playerPortable")
        case "PCs":
            return #imageLiteral(resourceName: "PCs")
        case "Servers":
            return #imageLiteral(resourceName: "Servers")
        case "Smartphones":
            return #imageLiteral(resourceName: "Smartphones")
        case "Tablets":
            return #imageLiteral(resourceName: "Tablets")
        case "Telecommunications":
            return #imageLiteral(resourceName: "Telecommunications")
        default:
            return #imageLiteral(resourceName: "not-available")
        }
    }
    
    
}
