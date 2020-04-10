//
//  BestDinnerAPI.swift
//  BestDinner
//
//  Created by Bourke Technlogies on 3/6/19.
//  Copyright © 2019 Bourke Technlogies. All rights reserved.
//

import Foundation

class API {
    
    //GET Query parameters
    func getQuery(skip:Int,take:Int) -> Request {
        return  RequestBuilder(method: .GET, url: "api/get")
            .setHeaders(["Content-Type":"application/json", "Accept":"application/json"])
            .addHeader(name: "Authorization", value: "access_token")
            .addQuery(name: "skip", value: skip)
            .addQuery(name: "take", value: take)
            .build()
    }
    
    //GET path parameters
    func getPath(id:Int) -> Request {
        return  RequestBuilder(method: .GET, url: "api/issue/{id}")
            .setHeaders(["Content-Type":"application/json", "Accept":"application/json"])
            .addHeader(name: "Authorization", value: "access_token")
            .addPath(name: "id", value: id)
            .build()
    }
    //POST fields
    func post1(username:String,password:String) -> Request {
        return  RequestBuilder(method: .POST, url: "token")
            .addField(name: "username", value: username)
            .addField(name: "password", value: password)
            .addField(name: "grant_type", value: "password")
            .build()
    }
    //POST Model as request body, Model must be a type of Codable
    func post2(model: [String : String]) -> Request {
        return  RequestBuilder(method: .POST, url: "api/user")
            .setHeaders(["Content-Type":"application/json", "Accept":"application/json"])
            .addHeader(name: "Authorization", value: "access_token")
            .setBody(body: model)
            .build()
    }
    
    //multipart file upload
    func uploadFile(withParams: [String : String]?, media: [Media]?) -> Request {
        return  RequestBuilder(method: .POST, url: "tempfiles")
            .setMultipartData(withParameters: withParams, media:media)
            .build()
    }
}
