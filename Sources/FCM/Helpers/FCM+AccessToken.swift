import Foundation
import Vapor

extension FCM {
    func getAccessToken(_ client: Client) throws -> EventLoopFuture<String> {
        if !gAuthPayload.hasExpired, let token = accessToken { return client.eventLoopGroup.future(token) }

        var payload: [String: String] = [:]
        payload["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        payload["assertion"] = try self.getJWT()

        let uri = URI(path: self.audience)
        return client.post(uri) { (request: inout ClientRequest) throws in
                    try request.content.encode(payload, as: .urlEncodedForm)
                }
                .flatMapThrowing( { (response: ClientResponse) in
                    guard var body = response.body else {
                        throw Abort(.notFound, reason: "Data not found")
                    }
                    if response.status != .ok {
                        let code = "Code: \(response.status)"
                        let string = body.readString(length: body.readableBytes)
                        let message = "Message: \(string ?? "n/a")"
                        let reason = "[FCM] Unable to refresh access token. \(code) \(message)"
                        throw Abort(.internalServerError, reason: reason)
                    }

                    struct Result: Codable {
                        var access_token: String
                    }
                    
                    let result = try response.content.decode(Result.self)
                    return result.access_token
                })
    }



}
