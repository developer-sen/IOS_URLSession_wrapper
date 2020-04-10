//
//  RestClient.swift
//  BestDinner
//
//  Created by SEN on 2/8/19.
//  Copyright © 2019 SEN. All rights reserved.
//

import Foundation

final class RestClientError {
    
    let restClientErrorType:RestClient.ErrorType
    let httpResponseCode:Int
    let errorMessage:String
    
    init(restClientErrorType:RestClient.ErrorType,httpResponseCode:Int,errorMessage:String) {
        self.restClientErrorType = restClientErrorType
        self.httpResponseCode = httpResponseCode
        self.errorMessage = errorMessage
    }
}

final class RestClient{
    
    enum ErrorType {
        case HttpError
        case JsonParsingError
        case RequestTimedOut
        case OtherError
    }
    
    enum ResponseHandle {
        case OnMainThread
        case OnBackground
    }
    
    let request:URLRequest
    fileprivate var responseHandle:RestClient.ResponseHandle
    
    init(request:URLRequest,handleOn:RestClient.ResponseHandle) {
        self.request = request
        self.responseHandle = handleOn
    }
    
    func execute(onSuccess:@escaping () -> (),onFailure:@escaping (RestClientError) -> ()){
        
        executeDataTask (onSuccess: { (data, urlResponse) in
            switch self.responseHandle{
            case .OnBackground:
                onSuccess()
            case .OnMainThread:
                DispatchQueue.main.async {
                    onSuccess()
                }
            }
        },onFailure: onFailure)
    }
    
    func execute<T:Codable>(onSuccess:@escaping (T)->(),onFailure:@escaping (RestClientError) -> ()){
        
        executeDataTask (onSuccess: { (data, httpResponse) in
            if let data = data{
                
                var object:T? = nil
                
                if T.self == Data.self{
                    object = (data as! T)
                }else if T.self == String.self{
                    var responseString = String(data: data, encoding: String.Encoding.utf8) ?? " Error converting to String "
                    responseString = String(responseString.dropLast().dropFirst())
                    object = (responseString as! T)
                }else{
                    do{
                        object = try JSONDecoder().decode(T.self,from: data)
                    }catch let jsonError{
                        print("Json Parsing Exception: \(jsonError.localizedDescription)")
                        self.handleFailure(RestClientError(restClientErrorType: .JsonParsingError, httpResponseCode: httpResponse.statusCode, errorMessage: jsonError.localizedDescription), onFailure)
                        return
                    }
                }
                
                switch self.responseHandle{
                case .OnBackground:
                    onSuccess(object!)
                case .OnMainThread:
                    DispatchQueue.main.async {
                        onSuccess(object!)
                    }
                }
            }else{
                print("Response data nill")
                self.handleFailure(RestClientError(restClientErrorType: .JsonParsingError, httpResponseCode: httpResponse.statusCode, errorMessage: ""), onFailure)
            }
        },onFailure: onFailure)
    }
    
    fileprivate func executeDataTask(onSuccess:@escaping (Data?,HTTPURLResponse)->(),onFailure:@escaping (RestClientError) -> ()){
        
        self.printRequest()
        URLSession.shared.dataTask(with:self.request) { (data, urlResponse, error) in
            if let httpResponse = urlResponse as? HTTPURLResponse {
                var responseString = NSString()
                if let data = data{
                    responseString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? ""
                }
                if httpResponse.statusCode == 200 {
                    onSuccess(data,httpResponse)
                }else{
                    self.handleFailure(RestClientError(restClientErrorType: .HttpError,httpResponseCode: httpResponse.statusCode,errorMessage: responseString as String),onFailure)
                }
                print("\(httpResponse.url!.absoluteString)#\(httpResponse.statusCode) : \(responseString)")
            }else{
                print("Request timed out")
                self.handleFailure(RestClientError(restClientErrorType: .RequestTimedOut, httpResponseCode: 0, errorMessage: error?.localizedDescription ?? ""),onFailure)
            }
        }.resume()
    }
    
    fileprivate func handleFailure(_ erorr:RestClientError,_ onFailure:@escaping (RestClientError) -> ()){
        
        switch self.responseHandle{
        case .OnBackground:
            onFailure(erorr)
        case .OnMainThread:
            DispatchQueue.main.async {
                onFailure(erorr)
            }
        }
    }
    
    fileprivate func printRequest(){
        #if DEBUG
        if let url = self.request.url{
            print("\(request.httpMethod!) \(url.absoluteString)")
        }
        if let headers = self.request.allHTTPHeaderFields{
            print("Headers:\(headers)")
        }
        if let body = self.request.httpBody{
            let bodyString = NSString(data: body, encoding: String.Encoding.utf8.rawValue) ?? ""
            print("HttpBody:\(bodyString)")
        }
        #endif
    }
}
