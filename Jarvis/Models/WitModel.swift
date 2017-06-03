//
//  WitModel.swift
//  Jarvis
//
//  Created by Hien Nguyen on 6/3/17.
//  Copyright © 2017 hienn. All rights reserved.
//

import ObjectMapper

class WitResponse: Mappable {
    var messageId: String?
    var text: String?
    var entities: Entity?
    
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        messageId <- map["msg_id"]
        text <- map["_text"]
        entities <- map["entities"]
    }
}

class Entity : Mappable {
    var intents: [Intent]?
    var witDateTime: [WitDateTime]?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        intents <- map["intent"]
        witDateTime <- map["wdatetime"]
    }
}

class Intent : Mappable {
    var confidence: Double?
    var value: String?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        confidence <- map["confidence"]
        value <- map["value"]
    }
}

class WitDateTime : Mappable {
    var confidence: Double?
    var values: [WitDateTimeValue]?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        confidence <- map["confidence"]
        values <- map["values"]
    }
}

class WitDateTimeValue : Mappable {
    var value: Date?
    var grain: String?
    var type: String?
    var valueString: String?
    
    required init?(map: Map){
        
    }
    
    func mapping(map: Map) {
        valueString <- map["value"]
        grain <- map["grain"]
        type <- map["type"]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        value = dateFormatter.date(from: valueString!)
    }
}

