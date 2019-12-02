import Foundation
import Vapor

extension FCM {

    public func sendMessage(_ req: Request, message: FCMMessageDefault) -> EventLoopFuture<String> {
        if message.apns == nil,
            let apnsDefaultConfig = apnsDefaultConfig {
            message.apns = apnsDefaultConfig
        }
        if message.android == nil,
            let androidDefaultConfig = androidDefaultConfig {
            message.android = androidDefaultConfig
        }
        if message.webpush == nil,
            let webpushDefaultConfig = webpushDefaultConfig {
            message.webpush = webpushDefaultConfig
        }
        let url = actionsBaseURL + projectId + "/messages:send"
        return getAccessToken(req).flatMap { accessToken in
            var headers = HTTPHeaders()
            headers.add(name: "Authorization", value: "Bearer "+accessToken)
            headers.add(name: "Content-Type", value: "application/json")
            return req.client.post(URI(string: url), headers: headers) { (request: inout ClientRequest) throws in

                struct Payload: Codable {
                       var validate_only: Bool
                       var message: FCMMessageDefault
                   }

                let payload = Payload(validate_only: false, message: message)
                try request.content.encode(payload, as: .json)
            }
            .flatMap( { (response: ClientResponse) in

//                do {
//                    let result = try response.content.decode(Result.self)
//                    return req.eventLoop.makeSucceededFuture(result.access_token)
//                } catch {
//                    return req.eventLoop.makeFailedFuture(FCMError(errorCode: .emptyBodyResponse))
//                }

                guard var body = response.body else {
                    return req.eventLoop.makeFailedFuture(FCMError(errorCode: .emptyBodyResponse))
                }

                guard 200 ..< 300 ~= response.status.code else {
                    if let googleError = try? response.content.decode(GoogleError.self) {
                        return req.eventLoop.makeFailedFuture(googleError)
                    } else {
                        let string = body.readString(length: body.readableBytes)
                        let reason = string ?? "Unable to decode Firebase response"
                        req.logger.error("\(reason)")
                        return req.eventLoop.makeFailedFuture(FCMError(errorCode: .`internal`))
                    }
                }
                struct Result: Codable {
                    var name: String
                }
                do {
                    let result = try response.content.decode(Result.self)
                    return req.eventLoop.makeSucceededFuture(result.name)
                } catch {
                    return req.eventLoop.makeFailedFuture(FCMError(errorCode: .`internal`))
                }

            })
        }
    }





}
