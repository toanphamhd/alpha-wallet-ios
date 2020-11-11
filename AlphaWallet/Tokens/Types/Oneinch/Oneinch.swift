//
//  OneinchHolder.swift
//  AlphaWallet
//
//  Created by Vladyslav Shepitko on 11.11.2020.
//

import Foundation
import PromiseKit
import Moya

class Oneinch {
    private(set) static var availableTokens: [Oneinch.ERC20Token] = []

    static func isSupport(token: TokenObject) -> Bool {
        switch token.server {
        case .main:
            return availableTokens.contains(where: { $0.address.sameContract(as: token.contractAddress) })
        case .kovan, .ropsten, .rinkeby, .sokol, .goerli, .artis_sigma1, .artis_tau1, .custom, .poa, .callisto, .xDai, .classic, .binance_smart_chain, .binance_smart_chain_testnet:
            return false
        }
    }

    static func token(address: AlphaWallet.Address) -> Oneinch.ERC20Token? {
        return availableTokens.first(where: { $0.address.sameContract(as: address) })
    }

    static func fetchSupportedTokens() {
        let config = Config()
        let provider = AlphaWalletProviderFactory.makeProvider()

        provider.request(.oneInchTokens(config: config)).map { response -> [String: Oneinch.ERC20Token] in
            try JSONDecoder().decode([String: Oneinch.ERC20Token].self, from: response.data)
        }.map { data -> [Oneinch.ERC20Token] in
            return data.map { $0.value }
        }.done { response in
            Oneinch.availableTokens = response
        }.cauterize()
    }

    private static let baseURL = "https://1inch.exchange/#"
    private static let refferal = "/r/0x98f21584006c79871F176F8D474958a69e04595B"

    private let input: Input

    init(input: Input) {
        self.input = input
    }

    var url: URL? {
        var components = URLComponents()
        components.path = Oneinch.refferal + "/" + input.subpath
        //NOTE: URLComponents doesn't allow path to contain # symbol
        guard let pathWithQueryItems = components.url?.absoluteString else { return nil }
        
        return URL(string: Oneinch.baseURL + pathWithQueryItems)
    }

    enum Input {
        case inputOutput(from: AlphaWallet.Address, to: AlphaWallet.Address)
        case none

        var subpath: String {
            switch self {
            case .inputOutput(let inputAddress, let outputAddress):
                return [Oneinch.token(address: inputAddress), Oneinch.token(address: outputAddress)].compactMap {
                    $0?.symbol
                }.joined(separator: "/")
            case .none:
                return String()
            }
        }
    }
}

extension MoyaProvider {

    func request(_ target: Target, callbackQueue: DispatchQueue? = nil, progress: ProgressBlock? = nil) -> Promise<Moya.Response> {
        return Promise { seal in
            request(target, callbackQueue: callbackQueue, progress: progress) { result in
                switch result {
                case let .success(response):
                    seal.fulfill(response)
                case let .failure(error):
                    seal.reject(error)
                }
            }
        }
    }
}
