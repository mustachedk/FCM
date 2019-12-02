import Foundation
import Vapor

extension FCM {

    public func sendMessage(_ client: Client, message: FCMMessageDefault) throws -> EventLoopFuture<String> {
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
        return try getAccessToken(client).flatMap { accessToken in
            var headers = HTTPHeaders()
            headers.add(name: "Authorization", value: "Bearer "+accessToken)
            headers.add(name: "Content-Type", value: "application/json")
            return client.post(URI(string: url), headers: headers) { (request: inout ClientRequest) throws in

                struct Payload: Codable {
                       var validate_only: Bool
                       var message: FCMMessageDefault
                   }

                let payload = Payload(validate_only: false, message: message)
                try request.content.encode(payload, as: .json)
            }
            .flatMapThrowing( { (response: ClientResponse) in
                guard var body = response.body else {
                    throw Abort(.notFound, reason: "Data not found")
                }

                guard 200 ..< 300 ~= response.status.code else {
                    if let googleError = try? response.content.decode(GoogleError.self) {
                        throw googleError
                    } else {
                        let string = body.readString(length: body.readableBytes)
                        let reason = string ?? "Unable to decode Firebase response"
                        throw Abort(.internalServerError, reason: reason)
                    }
                }
                struct Result: Codable {
                    var name: String
                }
                
                return try response.content.decode(Result.self).name
            })
        }
    }





}
