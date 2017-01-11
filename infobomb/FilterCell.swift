//
//  FilterCell.swift
//  infobomb
//
//  Created by Stephen Muscarella on 1/4/17.
//  Copyright © 2017 samuscarella. All rights reserved.
//

import UIKit

class FilterCell: UITableViewCell {

    @IBOutlet weak var filterOptionImageView: UIImageView!
    @IBOutlet weak var filterOptionLbl: UILabel!
    
    func configureCell(filterName: String, activePostType: String) {
        
        filterOptionLbl.text = filterName

        if filterName == "All" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "all-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "all-black")
            }
        } else if filterName == "Text" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "text-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "text-black")
            }
        } else if filterName == "Link" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "link-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "link-black")
            }
        } else if filterName == "Image" {

            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "camera-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "camera-black")
            }
        } else if filterName == "Video" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "camcorder-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "camcorder-black")
            }
        } else if filterName == "Audio" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "microphone-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "microphone-black")
            }
        } else if filterName == "Quote" {

            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "quote-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "quote-black")
            }
        } else if filterName == "My Posts" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "folder-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "folder-black")
            }
        } else if filterName == "Liked" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "add-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "add")
            }
        } else if filterName == "Disliked" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "minus-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "minus")
            }
        } else if filterName == "Popularity" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "popularity-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "popularity-black")
            }
        } else if filterName == "Rating" {
            
            if activePostType == filterName {
                filterOptionLbl.textColor = FILTER_BLUE
                filterOptionImageView.image = UIImage(named: "rating-blue")
            } else {
                filterOptionLbl.textColor = UIColor.black
                filterOptionImageView.image = UIImage(named: "star-black")
            }
        }
    }
}
