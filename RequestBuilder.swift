//
//  RequestFactory.swift
//  BestDinner
//
//  Created by Bourke Technlogies on 3/6/19.
//  Copyright © 2019 Bourke Technlogies. All rights reserved.
//

import Foundation

class RequestBuilder {
    
    fileprivate let baseURL : String = "http://api.com/"
    
    fileprivate struct Header{
        let name:String
        let value:String
    }
    
    fileprivate let urlString:String
    fileprivate let method:Request.HttpMethod
    fileprivate var requestHeaders:[String:String] = [:]
    fileprivate var querryParameters:[String:Any] = [:]
    fileprivate var pathParameters:[String:Any] = [:]
    fileprivate var fields:[Header] = []
    fileprivate var httpBodyModel:Data?
    fileprivate var isMultipart = false
    fileprivate var multipartParameters:[String:String]? = nil
    fileprivate var multipartData:[Media]? = nil
    
    init(method:Request.HttpMethod,url:String){
        self.urlString = "\(self.baseURL)\(url)"
        self.method = method
    }
    
    func setHeaders(_ headers:[String:String]) -> RequestBuilder {
        for (name,value) in headers{
           self.requestHeaders[name] = value
        }
        return self
    }
    
    func addHeader(name:String,value:String) -> RequestBuilder {
        self.requestHeaders[name] = value
        return self
    }
    
    func addField(name:String,value:String) -> RequestBuilder {
        fields.append(Header(name: name, value: value))
        httpBodyModel = nil
        return self
    }
    
    func setBody<T:Codable>(body: T) -> RequestBuilder {
        fields.removeAll()
        do{
            httpBodyModel = try JSONEncoder().encode(body)
        }catch let jsonError{
            print(jsonError.localizedDescription)
        }
        return self
    }
    
    func setMultipartData(withParameters params: [String: String]?, media: [Media]?) -> RequestBuilder {
        fields.removeAll()
        isMultipart = true
        self.multipartParameters = params
        self.multipartData = media
        return self
    }
    
    func addQuery(name:String,value:Any) -> RequestBuilder {
        querryParameters[name] = value
        return self
    }
    
    func addPath(name:String,value:Any) -> RequestBuilder{
        pathParameters[name] = value
        return self
    }
    
    func build() -> Request {
        
        var urlBuild = urlString
        if method==Request.HttpMethod.GET {
            if querryParameters.count > 0{
                var queries = ""
                for (key,value) in querryParameters{
                    queries = "\(queries)&\(key)=\(value)"
                }
                urlBuild = "\(urlBuild)?\(queries)"
            }
            for (name,value) in pathParameters{
                urlBuild = urlBuild.replacingOccurrences(of: "{\(name)}", with: "\(value)")
            }
        }
        
        let url = URL(string: urlBuild)
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = self.method.rawValue
        
        for (key,value) in self.requestHeaders{
            request.setValue(value, forHTTPHeaderField: key)
        }
        if method == Request.HttpMethod.POST || method == Request.HttpMethod.PUT{
            if isMultipart {
                let boundary = generateBoundary()
                 request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                request.httpBody = createMultipartBody(withParameters: multipartParameters, media: multipartData, boundary: boundary)
            }else {
                request.httpBody = createHttpBody()
            }
            
        }
        
        return Request(request: request)
    }
    
    fileprivate func createHttpBody() -> Data? {
        
        if fields.count>0{
            var body = ""
            for field in self.fields{
                body = "\(body)\(field.name)=\(field.value)&"
            }
            body = String(body.dropLast())
            return body.data(using: String.Encoding.utf8)
        } else if (httpBodyModel != nil) {
            return httpBodyModel
        }else {
            return nil
        }
    }
    
    fileprivate func createMultipartBody(withParameters params: [String: String]?, media: [Media]?, boundary: String) -> Data {
    
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        if let media = media {
            for file in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(file.key)\"; filename=\"\(file.filename)\"\(lineBreak)")
                body.append("Content-Type: \(file.mimeType + lineBreak + lineBreak)")
                body.append(file.data)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}

class Request {
    
    enum HttpMethod:String {
        case GET = "GET"
        case POST = "POST"
        case PUT = "PUT"
    }
    
    fileprivate let request:NSMutableURLRequest
    fileprivate var handleResponseOn:RestClient.ResponseHandle = RestClient.ResponseHandle.OnMainThread
    
    fileprivate init(request:NSMutableURLRequest){
        self.request = request
    }
    
    func handleResponse(_ handleResponseOn:RestClient.ResponseHandle)->Request {
        self.handleResponseOn = handleResponseOn
        return self
    }
    
    func execute<T:Codable>(onSuccess:@escaping (T)->(),onFailure:@escaping (RestClientError)->()) {
        RestClient(request: request as URLRequest,handleOn: handleResponseOn)
            .execute(onSuccess: onSuccess, onFailure: onFailure)
    }
    
    func execute(onSuccess:@escaping ()->(),onFailure:@escaping (RestClientError)->()) {
        RestClient(request: request as URLRequest,handleOn: handleResponseOn)
            .execute(onSuccess: onSuccess, onFailure: onFailure)
    }
}

class Response: Codable {
    fileprivate init(){}
}

struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init(with data: Data,mimeType: String,filename: String,forKey key: String) {
        self.key = key
        self.mimeType = mimeType
        self.filename = filename
        self.data = data
    }
    
}

fileprivate extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
