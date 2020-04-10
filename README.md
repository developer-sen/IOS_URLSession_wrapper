# IOS_URLSession_wrapper

A lightweight URLSession wrapper for basic network requirements.

## Installation
Download and drag(or add using Xcode) below Files into **Target**

1. RequestBuilder.swift
2. RestClient.swift
3. Change baseURL in **RequestBuilder.swift** file

```
 fileprivate let baseURL : String = "http://api.com/"
```

## API file

Create an API file with all endpoints. refer **DemoAPI.swift**  

``` swift
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
```

## Usage

With response body
```swift
API().getPath(id: 1)
    .handleResponse(.OnMainThread)
    .execute(onSuccess: { (responce:MyCodableClass) in
        //handle response
    }) { (error) in
        //handle error
}
```
Without response body
```swift
API().getQuery(skip: 0, take: 10)
    .handleResponse(.OnBackground)
    .execute(onSuccess: {
        //handle response
    }) { (error) in
        //handle error
}
```
## License
[MIT](https://github.com/developersen95/SenGenerator/blob/master/LICENSE)
