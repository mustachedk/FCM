import Foundation
import CryptoKit
import JWTKit

extension FCM {
    func generateJWT() throws -> String {
        gAuthPayload.update()
        let pk = try RSAKey.private(pem: key.data(using: .utf8)!)
        let signer = JWTSigner.rs256(key: pk)
        let jwt = JWT<GAuthPayload>(payload: gAuthPayload)
        let jwtData = try jwt.sign(using: signer)
        let data = Data(jwtData)
        return String(data: data, encoding: .utf8)!
    }
    
    func getJWT() throws -> String {
        if !gAuthPayload.hasExpired {
            return _jwt
        }
        _jwt = try generateJWT()
        return _jwt
    }
}
