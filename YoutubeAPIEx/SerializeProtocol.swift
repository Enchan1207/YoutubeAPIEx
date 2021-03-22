//
//  SerializeProtocol.swift
//  YoutubeAPIEx
//
//  Created by EnchantCode on 2021/03/22.
//

import Foundation

protocol Serializable: Codable {
    func selialize() -> String?
    static func deselialize(object: String) -> Self?
}

extension Serializable{
    func selialize() -> String?{
        guard let selializedData = try? JSONEncoder().encode(self) else {return nil}
        return String(data: selializedData, encoding: .utf8)
    }
    
    static func deselialize(object: String) -> Self?{
        let selialized = try? JSONDecoder().decode(Self.self, from: object.data(using: .utf8)!)
        return selialized
    }
}
