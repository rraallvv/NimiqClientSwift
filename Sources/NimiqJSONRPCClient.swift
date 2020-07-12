//
//  NimiqJSONRPCClient.swift
//  NimiqJSONRPCClient
//
//  Created by Rhody Lugo on 7/12/20.
//  Copyright © 2020 Rhody Lugo. All rights reserved.
//

import Foundation

struct Root<T:Decodable>: Decodable {
    let jsonrpc: String
    let result: T
    let id: Int
}

struct Account: Decodable {
    let id, address: String
    let balance, type: Int
}

struct Wallet: Decodable {
    let id, address, publicKey: String
    let privateKey: String?
}

typealias Address = String

struct OutgoingTransaction {
    let from: Address
    let fromType: Int? = nil
    let to: Address
    let toType: Int? = nil
    let value: Int
    let fee: Int
    let data: String? = nil
}

typealias Hash = String

struct Transaction : Decodable {
    let hash: Hash
    let blockHash: Hash?
    let blockNumber: Int?
    let timestamp: Int?
    let confirmations: Int?
    let transactionIndex: Int?
    let from: String
    let fromAddress: Address
    let to: String
    let toAddress: Address
    let value: Int
    let fee: Int
    let data: String?
    let flags: Int
}

struct Block : Decodable {
    let number: Int
    let hash: Hash
    let pow: Hash
    let parentHash: Hash
    let nonce: Int
    let bodyHash: Hash
    let accountsHash: Hash
    let difficulty: String
    let timestamp: Int
    let confirmations: Int
    let miner: String
    let minerAddress: Address
    let extraData: String
    let size: Int
    let transactions: [Any]
    
    private enum CodingKeys: String, CodingKey {
        case number, hash, pow, parentHash, nonce, bodyHash, accountsHash, difficulty, timestamp, confirmations, miner, minerAddress, extraData, size, transactions
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        number = try container.decode(Int.self, forKey: .number)
        hash = try container.decode(Hash.self, forKey: .hash)
        pow = try container.decode(Hash.self, forKey: .pow)
        parentHash = try container.decode(Hash.self, forKey: .parentHash)
        nonce = try container.decode(Int.self, forKey: .nonce)
        bodyHash = try container.decode(Hash.self, forKey: .bodyHash)
        accountsHash = try container.decode(Hash.self, forKey: .accountsHash)
        difficulty = try container.decode(String.self, forKey: .difficulty)
        timestamp = try container.decode(Int.self, forKey: .timestamp)
        confirmations = try container.decode(Int.self, forKey: .confirmations)
        miner = try container.decode(String.self, forKey: .miner)
        minerAddress = try container.decode(Address.self, forKey: .minerAddress)
        extraData = try container.decode(String.self, forKey: .extraData)
        size = try container.decode(Int.self, forKey: .size)
        do {
            transactions = try container.decode([Transaction].self, forKey: .transactions)
        } catch DecodingError.typeMismatch {
            transactions = try container.decode([Hash].self, forKey: .transactions)
        }
    }
}

struct BlockTemplateHeader : Decodable {
    let version: Int
    let prevHash: Hash
    let interlinkHash: Hash
    let accountsHash: Hash
    let nBits: Int
    let height: Int
}

struct BlockTemplateBody : Decodable {
    let hash: Hash
    let minerAddr: String
    let extraData: String
    let transactions: [String]
    let prunedAccounts: [String]
    let merkleHashes: [Hash]
}

struct BlockTemplate : Decodable {
    let header: BlockTemplateHeader
    let interlink: String
    let body: BlockTemplateBody
    let target: Int
}

struct TransactionReceipt : Decodable {
    let transactionHash: Hash
    let transactionIndex: Int
    let blockHash: Hash
    let blockNumber: Int
    let confirmations: Int
    let timestamp: Int
}

struct WorkInstructions : Decodable {
    let data: String
    let suffix: String
    let target: Int
    let algorithm: String
}

enum LogLevel : String {
    case trace = "trace"
    case verbose = "verbose"
    case debug = "debug"
    case info = "info"
    case warn = "warn"
    case error = "error"
    case assert = "assert"
}

struct MempoolInfo : Decodable {
    let total: Int
    let buckets: [Int]
    var transactions: [Int:Int]
    
    private enum CodingKeys: String, CodingKey {
        case total, buckets
        case bucket10000 = "10000"
        case bucket5000 = "5000"
        case bucket2000 = "2000"
        case bucket1000 = "1000"
        case bucket500 = "500"
        case bucket200 = "200"
        case bucket100 = "100"
        case bucket50 = "50"
        case bucket20 = "20"
        case bucket10 = "10"
        case bucket5 = "5"
        case bucket2 = "2"
        case bucket1 = "1"
        case bucket0 = "0"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try container.decode(Int.self, forKey: .total)
        buckets = try container.decode([Int].self, forKey: .buckets)
        transactions = [Int:Int]()
        for key in container.allKeys {
            guard let intKey = Int(key.stringValue) else {
                continue
            }
            transactions[intKey] = try container.decode(Int.self, forKey: key)
        }
    }
}

enum HashOrTransaction : Decodable {
    case hash(Hash)
    case transaction(Transaction)
    
    var value: Any {
         switch self {
         case .hash(let value):
             return value
         case .transaction(let value):
             return value
         }
    }
    
    private enum CodingKeys: String, CodingKey {
        case hash, transaction
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .transaction(try container.decode(Transaction.self))
        } catch DecodingError.typeMismatch {
            self = .hash(try container.decode(Hash.self))
        }
    }
}

enum PeerConnectionState : Int, Decodable {
    case new = 1
    case connecting = 2
    case connected = 3
    case negotiating = 4
    case established = 5
    case closed = 6
}

struct Peer : Decodable {
    let id: String
    let address: String
    let addressState: Int
    let connectionState: PeerConnectionState?
    let version: Int?
    let timeOffset: Int?
    let headHash: Hash?
    let latency: Int?
    let rx: Int?
    let tx: Int?
}

enum PoolConnectionState : Int, Decodable {
    case connected = 0
    case connecting = 1
    case closed = 2
}

struct SyncStatus : Decodable {
    let startingBlock: Int
    let currentBlock: Int
    let highestBlock: Int
}

enum SyncStatusOrBool : Decodable {
    case syncStatus(SyncStatus)
    case bool(Bool)
    
    var value: Any {
         switch self {
         case .syncStatus(let value):
             return value
         case .bool(let value):
             return value
         }
    }
    
    private enum CodingKeys: String, CodingKey {
        case syncStatus, bool
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .syncStatus(try container.decode(SyncStatus.self))
        } catch DecodingError.typeMismatch {
            self = .bool(try container.decode(Bool.self))
        }
    }
}

public class NimiqJSONRPCClient {

    static var id: Int = 0
    
    static func fetch<T:Decodable>(method: String, params: [Any], completionHandler: ((T?, Error?) -> Void)? = nil) -> T? {
        var result: T? = nil

        //Make JSON to send to send to server
        let json:[String:Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params,
            "id": id
        ]

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let url = URL(string: "http://deploy:3rWc7z3k6FQ6aaWvGihv@127.0.0.1:8648")!
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("close", forHTTPHeaderField: "Connection")

            var semaphore: DispatchSemaphore? = nil
            
            if completionHandler == nil {
                semaphore = DispatchSemaphore(value: 0)
            }
                        
            let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
                // Check the response
                //print(response)
                
                // Serialize the data into an object
                do {
                    let json = try JSONDecoder().decode(Root<T?>.self, from: data! )
                    id = id + 1
                    result = json.result
                    
                } catch {
                    let string = String(bytes: data!, encoding: String.Encoding.utf8)
                    print("Response: \(string!)")
                    print("Error: \(error)")
                }
                
                if completionHandler == nil {
                    semaphore!.signal()
                } else {
                    completionHandler!(result, error)
                }
            })
            task.resume()
            if completionHandler == nil {
                semaphore!.wait()
            }
        } catch {
            
        }
        
        return result
    }
    
    @discardableResult static func accounts(completionHandler: (([Account]?, Error?) -> Void)? = nil) -> [Account]? {
        return fetch(method: "accounts", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func blockNumber(completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "blockNumber", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func consensus(completionHandler: ((String?, Error?) -> Void)? = nil) -> String? {
        return fetch(method: "consensus", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func constant(constant: String, value: Int? = nil, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        var params:[Any] = [constant]
        if value != nil {
            params.append(value!)
        }
        return fetch(method: "constant", params: params, completionHandler: completionHandler)
    }
    
    @discardableResult static func createAccount(completionHandler: ((Wallet?, Error?) -> Void)? = nil) -> Wallet? {
        return fetch(method: "createAccount", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func createRawTransaction(transaction: OutgoingTransaction, completionHandler: ((String?, Error?) -> Void)? = nil) -> String? {
        var params:[String:Any] = [
            "from": transaction.from,
            "to": transaction.to,
            "value": transaction.value,
            "fee": transaction.fee
        ]

        if transaction.fromType != nil {
            params["fromType"] = transaction.fromType
        }
        if transaction.toType != nil {
            params["toType"] = transaction.toType
        }
        if transaction.data != nil {
            params["data"] = transaction.data
        }
        
        return fetch(method: "createRawTransaction", params: [params], completionHandler: completionHandler)
    }
    
    @discardableResult static func getAccount(account: Address, completionHandler: ((Account?, Error?) -> Void)? = nil) -> Account? {
        return fetch(method: "getAccount", params: [account], completionHandler: completionHandler)
    }

    @discardableResult static func getBalance(account: Address, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "getBalance", params: [account], completionHandler: completionHandler)
    }
    
    @discardableResult static func getBlockByHash(hash: Hash, fullTransactions: Bool = false, completionHandler: ((Block?, Error?) -> Void)? = nil) -> Block? {
        return fetch(method: "getBlockByHash", params: [hash, fullTransactions], completionHandler: completionHandler)
    }
    
    @discardableResult static func getBlockByNumber(number: Int, fullTransactions: Bool = false, completionHandler: ((Block?, Error?) -> Void)? = nil) -> Block? {
        return fetch(method: "getBlockByNumber", params: [number, fullTransactions], completionHandler: completionHandler)
    }
    
    @discardableResult static func getBlockTemplate(address: Address, extraData: String, completionHandler: ((BlockTemplate?, Error?) -> Void)? = nil) -> BlockTemplate? {
        return fetch(method: "getBlockTemplate", params: [address, extraData], completionHandler: completionHandler)
    }
    
    @discardableResult static func getBlockTransactionCountByHash(hash: Hash, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "getBlockTransactionCountByHash", params: [hash], completionHandler: completionHandler)
    }

    @discardableResult static func getBlockTransactionCountByNumber(number: Int, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "getBlockTransactionCountByNumber", params: [number], completionHandler: completionHandler)
    }
    
    @discardableResult static func getTransactionByBlockHashAndIndex(hash: Hash, index: Int, completionHandler: ((Transaction?, Error?) -> Void)? = nil) -> Transaction? {
        return fetch(method: "getTransactionByBlockHashAndIndex", params: [hash, index], completionHandler: completionHandler)
    }
    
    @discardableResult static func getTransactionByBlockNumberAndIndex(number: Int, index: Int, completionHandler: ((Transaction?, Error?) -> Void)? = nil) -> Transaction? {
        return fetch(method: "getTransactionByBlockNumberAndIndex", params: [number, index], completionHandler: completionHandler)
    }
    
    @discardableResult static func getTransactionByHash(hash: Hash, completionHandler: ((Transaction?, Error?) -> Void)? = nil) -> Transaction? {
        return fetch(method: "getTransactionByHash", params: [hash], completionHandler: completionHandler)
    }
    
    @discardableResult static func getTransactionReceipt(hash: Hash, completionHandler: ((TransactionReceipt?, Error?) -> Void)? = nil) -> TransactionReceipt? {
        return fetch(method: "getTransactionReceipt", params: [hash], completionHandler: completionHandler)
    }
    
    @discardableResult static func getTransactionsByAddress(address: Address, numberOfTransactions: Int = 1000, completionHandler: (([Transaction]?, Error?) -> Void)? = nil) -> [Transaction]? {
        return fetch(method: "getTransactionsByAddress", params: [address, numberOfTransactions], completionHandler: completionHandler)
    }
    
    @discardableResult static func getWork(address: Address, extraData: String, completionHandler: ((WorkInstructions?, Error?) -> Void)? = nil) -> WorkInstructions? {
        return fetch(method: "getWork", params: [address, extraData], completionHandler: completionHandler)
    }
    
    @discardableResult static func hashrate(completionHandler: ((Float?, Error?) -> Void)? = nil) -> Float? {
        return fetch(method: "hashrate", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func log(tag: String, level: LogLevel, completionHandler: ((Bool?, Error?) -> Void)? = nil) -> Bool? {
        return fetch(method: "log", params: [tag, level.rawValue], completionHandler: completionHandler)
    }
    
    @discardableResult static func mempool(completionHandler: ((MempoolInfo?, Error?) -> Void)? = nil) -> MempoolInfo? {
        return fetch(method: "mempool", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func mempoolContent(fullTransactions: Bool = false, completionHandler: (([Any]?, Error?) -> Void)? = nil) -> [Any]? {
        let result: [HashOrTransaction] = fetch(method: "mempoolContent", params: [fullTransactions], completionHandler: completionHandler)!
        var converted: [Any] = [Any]()
        for transaction in result {
            converted.append(transaction.value)
        }
        return converted
    }
    
    @discardableResult static func minerAddress(completionHandler: ((String?, Error?) -> Void)? = nil) -> String? {
        return fetch(method: "minerAddress", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func minerThreads(threads: Int? = nil, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        var params: [Int] = [Int]()
        if threads != nil {
            params.append(threads!)
        }
        return fetch(method: "minerThreads", params: params, completionHandler: completionHandler)
    }
    
    @discardableResult static func minFeePerByte(fee: Int? = nil, completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        var params: [Int] = [Int]()
        if fee != nil {
            params.append(fee!)
        }
        return fetch(method: "minFeePerByte", params: params, completionHandler: completionHandler)
    }
    
    @discardableResult static func mining(completionHandler: ((Bool?, Error?) -> Void)? = nil) -> Bool? {
        return fetch(method: "mining", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func peerCount(completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "peerCount", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func peerList(completionHandler: (([Peer]?, Error?) -> Void)? = nil) -> [Peer]? {
        return fetch(method: "peerList", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func peerState(address: String, completionHandler: ((Peer?, Error?) -> Void)? = nil) -> Peer? {
        return fetch(method: "peerState", params: [address], completionHandler: completionHandler)
    }
    
    @discardableResult static func pool(address: Any? = nil, completionHandler: ((String?, Error?) -> Void)? = nil) -> String? {
        var params: [Any] = [Any]()
        if let stringAddress = address as? String {
            params.append(stringAddress)
        } else if let stringBool = address as? Bool {
            params.append(stringBool)
        }
        return fetch(method: "pool", params: params, completionHandler: completionHandler)
    }
    
    @discardableResult static func poolConfirmedBalance(completionHandler: ((Int?, Error?) -> Void)? = nil) -> Int? {
        return fetch(method: "poolConfirmedBalance", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func poolConnectionState(completionHandler: ((PoolConnectionState?, Error?) -> Void)? = nil) -> PoolConnectionState? {
        return fetch(method: "poolConnectionState", params: [], completionHandler: completionHandler)
    }
    
    @discardableResult static func sendRawTransaction(transaction: String, completionHandler: ((Hash?, Error?) -> Void)? = nil) -> Hash? {
        return fetch(method: "sendRawTransaction", params: [transaction], completionHandler: completionHandler)
    }
    
    @discardableResult static func sendTransaction(transaction: OutgoingTransaction, completionHandler: ((Hash?, Error?) -> Void)? = nil) -> Hash? {
        var params:[String:Any] = [
            "from": transaction.from,
            "to": transaction.to,
            "value": transaction.value,
            "fee": transaction.fee
        ]

        if transaction.fromType != nil {
            params["fromType"] = transaction.fromType
        }
        if transaction.toType != nil {
            params["toType"] = transaction.toType
        }
        if transaction.data != nil {
            params["data"] = transaction.data
        }
        
        return fetch(method: "sendTransaction", params: [params], completionHandler: completionHandler)
    }
    
    @discardableResult static func submitBlock(_ block: String, completionHandler: ((String?, Error?) -> Void)? = nil) -> String? {
        return fetch(method: "submitBlock", params: [block], completionHandler: completionHandler)
    }
    
    @discardableResult static func syncing(completionHandler: ((Any?, Error?) -> Void)? = nil) -> Any? {
        let result: SyncStatusOrBool = fetch(method: "syncing", params: [], completionHandler: completionHandler)!
        return result.value
    }
    
}
