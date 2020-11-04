//
//  DomainResolver.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 02.11.2020.
//

import Foundation
import UnstoppableDomainsResolution
import PromiseKit

class DomainResolver {

    private struct ENSLookupKey: Hashable {
        let name: String
        let server: RPCServer
    }

    private enum AnyError: Error {
        case failureToResolve
        case invalidAddress
        case invalidInput
    }

    private let server: RPCServer
    private static var cache: [ENSLookupKey: AlphaWallet.Address] = [:]
    private lazy var resolution = try? Resolution(providerUrl: server.rpcURL.absoluteString, network: server.web3NetworkName)

    init(server: RPCServer) {
        self.server = server
    }

    func resolveAddress(_ input: String) -> Promise<AlphaWallet.Address> {
        //if already an address, send back the address
        if let value = AlphaWallet.Address(string: input) {
            return .value(value)
        }

        let node = input.lowercased().nameHash
        if let value = cachedResult(forNode: node) {
            return .value(value)
        }

        guard let resolution = resolution else { return .init(error: AnyError.invalidAddress) }

        return Promise { seal in
            resolution.addr(domain: input, ticker: "eth") { result in
                switch result {
                case .success(let value):
                    if let address = AlphaWallet.Address(string: value), CryptoAddressValidator.isValidAddress(value) {
                        self.cache(forNode: node, result: address)

                        seal.fulfill(address)
                    } else {
                        seal.reject(AnyError.invalidAddress)
                    }
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }

    private func cachedResult(forNode node: String) -> AlphaWallet.Address? {
        return DomainResolver.cache[ENSLookupKey(name: node, server: server)]
    }

    private func cache(forNode node: String, result: AlphaWallet.Address) {
        DomainResolver.cache[ENSLookupKey(name: node, server: server)] = result
    }
}
