import Foundation
import Vapor

extension FCM {
    func getAccessToken(_ req: Request) -> EventLoopFuture<String> {
        if !gAuthPayload.hasExpired, let token = accessToken { return req.client.eventLoopGroup.future(token) }

        var payload: [String: String] = [:]
        payload["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        do {
            payload["assertion"] = try self.getJWT()
        } catch  {
            return req.eventLoop.makeFailedFuture(FCMError(errorCode: .unableToGenerateJWTToken))
        }

        let uri = URI(path: self.audience)
        return req.client.post(uri) { (request: inout ClientRequest) throws in
                    try request.content.encode(payload, as: .urlEncodedForm)
                }
                .flatMap( { (response: ClientResponse) in
                    guard var body = response.body else {
                        return req.eventLoop.makeFailedFuture(FCMError(errorCode: .unableToGetAccesstoken))
                    }
                    if response.status != .ok {
                        let code = "Code: \(response.status)"
                        let string = body.readString(length: body.readableBytes)
                        let message = "Message: \(string ?? "n/a")"
                        let reason = "[FCM] Unable to refresh access token. \(code) \(message)"
                        req.logger.error("\(reason)")
                        return req.eventLoop.makeFailedFuture(FCMError(errorCode: .unableToGetAccesstoken))
                    }

                    struct Result: Codable {
                        var access_token: String
                    }
                    do {
                        let result = try response.content.decode(Result.self)
                        return req.eventLoop.makeSucceededFuture(result.access_token)
                    } catch {
                        return req.eventLoop.makeFailedFuture(FCMError(errorCode: .unableToParseAccesstoken))
                    }
                })
    }



}
