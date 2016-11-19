//
//  QiniuManager.swift
//  VoiceNoteBook
//
//  Created by 牛严 on 2016/11/19.
//  Copyright © 2016年 牛严. All rights reserved.
//

import UIKit
import Qiniu


let kQiniuBucket = "voicenotebook"
let kQiniuAccessKey = "trKd-rnSvKJpjd7fiXkLEvk5KvHKbCGvKGzCGYJX"
let kQiniuSecretKey = "fNbRIqm4ixYH2AcvOG_1itmcEvUc1ZgL9l6XOgWs"

let kQiniuDownloadUrl = "ogwdnxosu.bkt.clouddn.com"

class QiniuManager: NSObject {

    static let sharedInstance = QiniuManager()
    
    var uploader: QNUploadManager = QNUploadManager()

    ///上传音频文件
    func uploadRecord(name:String!,path:String!) {
        uploader.putFile(path, key: name, token: qiniuToken(fileName: name), complete: { (info: QNResponseInfo?, key: String?, resp: [AnyHashable : Any]?) -> Void in
                if info!.isOK {
                    print("上传成功")
                } else {
                    print("Error: \(info?.error!)" )
                }
            }, option: nil)
    }
    
    ///出于演示考虑，先客户端生成token
    private func qiniuToken(fileName: String) -> String {
        let oneHourLater = NSDate().timeIntervalSince1970 + 3600
        let scope = kQiniuBucket + ":" + fileName
        let putPolicy: NSDictionary = ["scope": scope, "deadline": NSNumber(value: UInt64(oneHourLater))]
        let encodedPutPolicy = QNUrlSafeBase64.encode(putPolicy.JSONString())
        let sign = hmacsha1(str: encodedPutPolicy!, secretKey: kQiniuSecretKey)
        let encodedSign = QNUrlSafeBase64.encode(sign as Data!)
        return kQiniuAccessKey + ":" + encodedSign! + ":" + encodedPutPolicy!
    }
    
    private func hmacsha1(str: String, secretKey: String) -> NSData {
        let cKey  = secretKey.cString(using: String.Encoding.ascii)
        let cData = str.cString(using: String.Encoding.ascii)
        var result = [CUnsignedChar](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), cKey!, Int(strlen(cKey!)), cData!, Int(strlen(cData!)), &result)
        let hmacData: NSData = NSData(bytes: result, length: (Int(CC_SHA1_DIGEST_LENGTH)))
        return hmacData
    }
    
    ///批量请求用到的accessToken   http://docs.qiniu.com/api/v6/rs.html#batch
    func accessToken() -> String {
        let path = "http://rsf.qbox.me/list?bucket=voicenotebook\n"
        let signData = hmacsha1(str: path, secretKey: kQiniuSecretKey)
        let encodeSignData = QNUrlSafeBase64.encode(signData as Data!)
        let accessToken = kQiniuAccessKey + ":" + encodeSignData!
        return accessToken
    }
}


extension NSDictionary {
    func JSONString() -> String! {
        let data = try! JSONSerialization.data(withJSONObject: self, options: .prettyPrinted)
        let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        return string as String!
    }
}
