//
//  MenuModel.swift
//  Jarvis
//
//  Created by Hien Nguyen on 6/3/17.
//  Copyright © 2017 hienn. All rights reserved.
//

import ObjectMapper

class LunchMenu: Mappable {
    var date: Date?
    var menu: [Menu]?
    var dateString: String?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        dateString <- map["day"]
        menu <- map["menu"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        date = dateFormatter.date(from: dateString!)
    }
}

class Menu: Mappable {
    var food: String?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        food <- map["food"]
    }
}

