//
//  InAppPurchaseEventsController.swift
//  Feedback
//
//  Created by Rohan Moradiya on 17/07/21.
//

import Foundation
import StoreKit

typealias PaymentObserverComletion = ([IAPEvent]) -> Void

struct IAPEvent: Codable {
    var productID: String
    var quantity: Int?
    var price: Double?
    var subscriptionPeriod: Int?
    var subscriptionUnit: String?
    var localCurrencyPrice: String?
}

protocol InAppPurchaseEventsDelegate: AnyObject {
    func newIAPEventRecorded(_ event: IAPEvent)
}

class InAppPurchaseEventsController: NSObject {
    
    var eventArray = [IAPEvent]()
    weak var delegate: InAppPurchaseEventsDelegate?
    
    override init() {
        super.init()
    }
    
    let observer = PaymentQueueObserver()
    
    func startObserver() {
        FBLogs("In app purchase observer started")
        observer.onPurchaseCompletion = {[weak self] eventArray in
            FBLogs("inapp completion block called")
            guard let self = self else { return }
            var identifires = [String]()
            for event in eventArray {
                self.eventArray.append(event)
                identifires.append(event.productID)
            }
            
            let productIDs = Set(identifires)
            let productsRequest:SKProductsRequest = SKProductsRequest(productIdentifiers: productIDs)
            productsRequest.delegate = self
            productsRequest.start()
        }
        SKPaymentQueue.default().add(observer)
    }
    
    func recordInApppurchaseEvent(event: IAPEvent) {
        FBLogs("New In app purchase event recorded:")
        self.delegate?.newIAPEventRecorded(event)
        self.eventArray.removeAll(where: { $0.productID == event.productID })
    }
    
    func foundPriceFor(_ productID: String, price: Double, numberOfUnit: Int?, unit: Int?, localCurrencyPrice: String?) {
        FBLogs("found price for called")
        if var first = self.eventArray.first(where: { $0.productID == productID }) {
            first.price = price
            first.localCurrencyPrice = localCurrencyPrice
            if let unitNumber = numberOfUnit {
                first.subscriptionPeriod = unitNumber
            }
            if let unit = unit {
                switch unit {
                case 0:
                    first.subscriptionUnit = "day"
                    break
                case 1:
                    first.subscriptionUnit = "week"
                    break
                case 2:
                    first.subscriptionUnit = "month"
                    break
                case 3:
                    first.subscriptionUnit = "year"
                    break
                default:
                    break
//                    first.subscriptionUnit = "\(subscription.unit)"
                }
            }
            self.recordInApppurchaseEvent(event: first)
        }
    }
    
    deinit {
        SKPaymentQueue.default().remove(observer)
    }
    
    private func priceStringForProduct(item: SKProduct) -> String? {
        let price = item.price
        if price == NSDecimalNumber(decimal: 0.00) {
            return "0.0"
        } else {
            let numberFormatter = NumberFormatter()
            let locale = item.priceLocale
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = locale
            return numberFormatter.string(from: price)
        }
    }
}
extension InAppPurchaseEventsController: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        FBLogs("product request response received")
        response.products.forEach { (product) in
            
            let localPrice = self.priceStringForProduct(item: product)
            
            if #available(iOS 11.2, *) {
                if let subscriptionInfo = product.subscriptionPeriod {
                    self.foundPriceFor(product.productIdentifier, price: Double(truncating: product.price), numberOfUnit: subscriptionInfo.numberOfUnits, unit: subscriptionInfo.unit.hashValue, localCurrencyPrice: localPrice)
                } else {
                    self.foundPriceFor(product.productIdentifier, price: Double(truncating: product.price), numberOfUnit: nil, unit: nil, localCurrencyPrice: localPrice)
                }
            } else {
                // Fallback on earlier versions
                self.foundPriceFor(product.productIdentifier, price: Double(truncating: product.price), numberOfUnit: nil, unit: nil, localCurrencyPrice: localPrice)
            }
            
            
            
//            self.foundPriceFor(product.productIdentifier, price: Double(truncating: product.price), numberOfUnit: product.subscriptionPeriod?.numberOfUnits, unit: product.subscriptionPeriod?.unit, localCurrencyPrice: localPrice)
//
//            self.foundPriceFor(product.productIdentifier, price: Double(truncating: product.price), subscriptionPeriod: product.subscriptionPeriod, localCurrencyPrice: localPrice)
        }
    }
}

class PaymentQueueObserver: NSObject, SKPaymentTransactionObserver {
    
    var onPurchaseCompletion: PaymentObserverComletion?
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        FBLogs("payment queue update transactions")
        
        var eventArray = [IAPEvent]()
        for transaction in transactions {
            
            switch transaction.transactionState {
            case .purchased:
                FBLogs("payment queue: purchased")
                let event = IAPEvent(productID: transaction.payment.productIdentifier, quantity: transaction.payment.quantity, price: nil)
                eventArray.append(event)
                break
            case .failed:
                FBLogs("payment queue: Failed")
                break
            case .restored:
                FBLogs("payment queue: restored")
            default:
                break;
            }
        }
        
        if eventArray.count > 0 {
            onPurchaseCompletion!(eventArray)
        }
    }
    
    
}
