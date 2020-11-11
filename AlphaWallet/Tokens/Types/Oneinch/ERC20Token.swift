//
//  OneinchERC20Token.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 11.11.2020.
//

import Foundation
import TrustKeystore

extension Oneinch {
    struct ERC20Token: Decodable {
        private enum AnyError: Error {
            case invalidAddress
        }

        private enum Keys: String, CodingKey {
            case symbol
            case name
            case address
            case decimals
        }

        let symbol: String
        let name: String
        let address: AlphaWallet.Address
        let decimal: Int

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: Keys.self)

            let addressValue = try container.decode(String.self, forKey: .address)

            if let value = AlphaWallet.Address(uncheckedAgainstNullAddress: addressValue) {
                address = value
                symbol = try container.decode(String.self, forKey: .symbol)
                name = try container.decode(String.self, forKey: .name)
                decimal = try container.decode(Int.self, forKey: .decimals)
            } else {
                throw AnyError.invalidAddress
            }
        }
    }
}
