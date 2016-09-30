//
//  NetworkDataProvider.swift
//  PositionIn
//
//  Created by Alexandr Goncharov on 16/07/15.
//  Copyright (c) 2015 Soluna Labs. All rights reserved.
//

import Foundation
import Alamofire
import ObjectMapper
import BrightFutures
import MobileCoreServices

public struct NewRelicObserverNotifications {
    public static let networkFailureNotification = "networkFailureNotification"
    public static let URLkey = "URL"
    public static let httpMethodKey = "HttpMethod"
    public static let requestDurationKey = "requestDurationKey"
    public static let errorCodeKey = "errorCodeKey"
    public static let errorMessageKey = "errorMessageKey"
}

open class NetworkDataProvider {
    
    /// Singleton instance
    static let sharedInstance = NetworkDataProvider()
    
    /**
    Create request for mappable object
    
    - parameter URLRequest: The URL request
    
    - returns: Tuple with request and future
    */
    open func objectRequest<T: Mappable>
        (_ URLRequest: Alamofire.URLRequestConvertible,
         validation: Alamofire.DataRequest.Validation? = nil) -> (Alamofire.Request, Future<T, NSError>)
    {
            let mapping: (Any?) -> T? = { json in
                return Mapper<T>().map(JSONObject: json)
            }
            return jsonRequest(URLRequest, map: mapping, validation: validation)
    }
    
    /**
    Create request for multiple mappable objects
    
    - parameter URLRequest: The URL request
    
    - returns: Tuple with request and future
    */
    open func arrayRequest<T: Mappable>(
        _ URLRequest: Alamofire.URLRequestConvertible,
        validation: Alamofire.DataRequest.Validation? = nil
        ) -> (Alamofire.Request, Future<[T], NSError>) {
            let mapping: (Any?) -> [T]? = { json in
                return Mapper<T>().mapArray(JSONObject: json)
            }
            return jsonRequest(URLRequest, map: mapping, validation: validation)
    }
    
    /**
    Create request with JSON mapping
    
    - parameter URLRequest: The URL request
    - parameter map:        Response mapping function
    
    - returns: Tuple with request and future
    */
    open func jsonRequest<V>(
        _ URLRequest: Alamofire.URLRequestConvertible,
        map: @escaping ((AnyObject?)->V?),
        validation: Alamofire.DataRequest.Validation? = nil
        ) -> (Alamofire.Request, Future<V, NSError>) {
        let serializer = Alamofire.DataRequest.customResponseSerializer(map)
        return request(URLRequest, serializer: serializer, validation: validation)
    }
    
    
    /**
    Designated initializer
    
    - parameter api:           api service
    - parameter configuration: session configuration
    
    - returns: new instance
    */
    public init(
        configuration: URLSessionConfiguration = URLSessionConfiguration.default,
        trustPolicies: [String: ServerTrustPolicy]? = nil
        ) {
            let serverTrustPolicyManager = trustPolicies.map { ServerTrustPolicyManager(policies: $0) }
            manager = Alamofire.SessionManager(configuration: configuration, serverTrustPolicyManager: serverTrustPolicyManager)
    }

    fileprivate let manager: Alamofire.SessionManager
    fileprivate let activityIndicator = NetworkActivityIndicatorManager()
    
    /**
    Create request with serializer
    
    - parameter URLRequest: The URL request
    - parameter serializer: Response serializer
    
    - returns: Tuple with request and future
    */
    open func request<V, Serializer: Alamofire.DataResponseSerializerProtocol> (
        _ URLRequest: Alamofire.URLRequestConvertible,
        serializer: Serializer,
        validation: Alamofire.DataRequest.Validation?
        ) -> (Alamofire.Request, Future<V, NSError>) where Serializer.SerializedObject == V {
        
        let p = Promise<V, NSError>()
        
        activityIndicator.increment()
        
        let request = self
            .request(URLRequest, validation: validation).response(queue: DispatchQueue.global(), responseSerializer: serializer) { [unowned self] (response) in
                self.activityIndicator.decrement()
                switch response.result {
                case .success(let value):
                    p.success(value)
                case .failure(let error):
                    self.postNetworkErrorInfoNotification(response: response)
                    p.failure(error as NSError)
                }
        }
        
        return (request, p.future)
    }
    
    fileprivate func request(_ URLRequest: Alamofire.URLRequestConvertible, validation: Alamofire.DataRequest.Validation?) -> Alamofire.DataRequest {
        let request = manager.request(URLRequest)
        #if DEBUG
            print("Request:\n\(request.debugDescription)")
        #endif
        if let validation = validation {
            return request.validate(validation)
        } else {
            return request.validate(statusCode: [] + (200..<300) + (400..<600) )
        }
    }
    
    //MARK: - Post notification for new reloc
    fileprivate func postNetworkErrorInfoNotification<V>(response: Alamofire.DataResponse<V>) {
        let userInfo = [
            NewRelicObserverNotifications.URLkey : response.request?.url?.absoluteString ?? "",
            NewRelicObserverNotifications.httpMethodKey: response.request?.httpMethod ?? "",
            NewRelicObserverNotifications.errorCodeKey : String(describing: (response.result.error as? AFError)?._code),
            NewRelicObserverNotifications.errorMessageKey : response.result.error?.localizedDescription ?? "",
            NewRelicObserverNotifications.requestDurationKey : String(response.timeline.requestDuration)
        ]
        NotificationCenter
            .default
            .post(name: Notification.Name(rawValue: NewRelicObserverNotifications.networkFailureNotification), object: nil, userInfo: userInfo)
    }
}


private extension Alamofire.DataRequest {
    
    //MARK: - Custom serializer -
    static func customResponseSerializer<T>(_ mapping: @escaping ((AnyObject?) -> T?)) -> DataResponseSerializer<T> {
        return DataResponseSerializer { request, response, data, error in
            guard error == nil else { return .failure(error!) }
            
            let jsonResponseSerializer = DataRequest.jsonResponseSerializer(options: .allowFragments)
            let result = jsonResponseSerializer.serializeResponse(request, response, data, error)
            
            switch result {
            case .success(let json):
                guard let object = mapping(json as AnyObject?) else {
                    if  let jsonDict = json as? [String: AnyObject],
                        let msg = jsonDict["error"] as? String {
                            if let statusCode = response?.statusCode , statusCode == 400 || statusCode == 401 {
                                return .failure(NetworkDataProvider.ErrorCodes.invalidSessionError.error(localizedDescription: msg))
                            } else {
                                return .failure(NetworkDataProvider.ErrorCodes.transferError.error(localizedDescription: msg))
                            }
                    }
                    return .failure(NetworkDataProvider.ErrorCodes.invalidResponseError.error())
                }
                return .success(object)
            case .failure(let error):
                return .failure(NetworkDataProvider.ErrorCodes.parsingError.error(error as NSError?))
            }
        }
    }
}

//MARK: - Network error codes -

extension NetworkDataProvider {
    /**
    Network error codes
    
    - UnknownError:    Unknown error
    - InvalidRequestError:  Invalid request error
    - TransferError:   Transfer error
    - InvalidResponseError: Invalid response error
    - ParsingError:    Response Parsing error
    */
    public enum ErrorCodes: Int {
        public static let errorDomain = "com.bekitzur.network"
        
        case unknownError, invalidRequestError, transferError, invalidResponseError, parsingError, invalidSessionError, sessionRevokedError
        
        /**
        Trying to construct Error code from NSError
        
        - parameter error: NSError instance
        
        - returns: Error code or nil
        */
        public static func fromError(_ error: NSError) -> ErrorCodes? {
            if error.domain == ErrorCodes.errorDomain {
                return ErrorCodes(rawValue: error.code)
            }
            return nil
        }
        
        /**
        Converting Error code to the NSError
        
        - parameter underlyingError: underlying error
        - parameter description: Localized description
        
        - returns: NSError instance
        */
        public func error(_ underlyingError: NSError? = nil, localizedDescription: String? = nil) -> NSError {
            let description = localizedDescription ?? NSString(
                format: NSLocalizedString("Network error: %@", comment: "Localized network error description") as NSString,
                self.reason) as String
        
            var userInfo: [AnyHashable: Any] = [
                NSLocalizedDescriptionKey: description,
                NSLocalizedFailureReasonErrorKey: self.reason,
            ]
            
            if let underlyingError = underlyingError {
                userInfo[NSUnderlyingErrorKey] = underlyingError
            }
            return NSError(domain:ErrorCodes.errorDomain, code: self.rawValue, userInfo: userInfo)
        }
        
        /// Localized failure reason
        var reason: String {
            switch self {
            case .invalidRequestError:
                return NSLocalizedString("InvalidRequestError", comment: "Invalid request")
            case .invalidResponseError:
                return NSLocalizedString("InvalidResponseError", comment: "Invalid response")
            case .parsingError:
                return NSLocalizedString("ParsingError", comment: "Parsing error")
            case .transferError:
                return NSLocalizedString("TransferError", comment: "Data transfer error")
            case .invalidSessionError:
                return NSLocalizedString("InvalidSessionError", comment: "Session error")
            case .sessionRevokedError:
                return NSLocalizedString("SessionRevokedError", comment: "Session Revoked")
            case .unknownError:
                fallthrough
            default:
                return NSLocalizedString("UnknownError", comment: "Unknown error")
            }
        }
    }
}

//MARK: Upload
extension NetworkDataProvider {
    
    /// File upload info
    final public class FileUpload {
        let data: Data
        let name: String
        let filename: String
        let mimeType: String
        
        public init (data: Data, dataUTI: String, name: String = "file") {
            self.name = name
            self.data = data
            mimeType = copyTag(kUTTagClassMIMEType, fromUTI: dataUTI, defaultValue: "application/octet-stream")
            let fileExtension = copyTag(kUTTagClassFilenameExtension, fromUTI: dataUTI, defaultValue: "png")
            filename = (name as NSString).appendingPathExtension(fileExtension) ?? name
        }
    }
    
    /**
    Uploads a files
    
    - parameter URLRequest: url request
    - parameter urls:       files info
    
    - returns: Request future
    */
    public func upload(
        _ URLRequest: Alamofire.URLRequestConvertible,
        files: [FileUpload]
        ) -> (Future<AnyObject?, NSError>) {
            let p = Promise<AnyObject?, NSError>()
        
        manager.upload(multipartFormData: { multipartFormData in
            for fileInfo in files {
                multipartFormData.append(
                    fileInfo.data,
                    withName: fileInfo.name,
                    fileName: fileInfo.filename,
                    mimeType: fileInfo.mimeType
                )
            }
            }, with: URLRequest, encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    print("Request:\n\(upload.debugDescription)")
                    upload.validate(statusCode: [201]).responseJSON { response in
                        switch response.result {
                        case .success(let JSON):
                            p.success(JSON as AnyObject?)
                        case .failure(let error):
                            p.failure(error as NSError)
                        }
                    }
                case .failure(let encodingError):
                    p.failure(encodingError as NSError)
                }
        })
            return p.future
    }
}

private func copyTag(_ tag: CFString!, fromUTI dataUTI: String, defaultValue: String) -> String {
    guard let str = UTTypeCopyPreferredTagWithClass(dataUTI as CFString, tag) else {
        return defaultValue
    }
    return str.takeRetainedValue() as String
}
