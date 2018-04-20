//
//  StripeClient.swift
//  App
//
//  Created by suvorov on 11/25/17.
//

import Foundation
import Jay
import Dispatch
import HTTP

public class StripeClient {
    let stripeKey: String
    let client: Vapor.Responder
    
    static public func getStripeKey(_ config: Config) -> String {
        let key = "stripeKey"
        let token = config["appkeys", key]?.string
        if token == nil {
            analytics?.logError("FAILED TO GET \(key) from configuration files!")
        }
        
        return token!
    }

    public init(config: Vapor.Config, responder: Responder) {
        stripeKey = StripeClient.getStripeKey(config)
        client = responder
    }
    
    public convenience init(droplet: Vapor.Droplet) {
        self.init(config: droplet.config, responder: droplet.client)
    }
    
    @discardableResult
    private func postToStripe(payload: [String: Any],
                              endpoint: String,
                              subscriber: Subscriber) -> Response? {
        do {
            let url = "https://api.stripe.com/v1/\(endpoint)"
            let data = try Jay().dataFromJson(anyDictionary: payload)
            let finalJSON = try JSON(bytes: data)
            let node = try Node(node: finalJSON)
            let urlEncodedForm = Body.data(try! node.formURLEncoded())
            let headers = [
                HeaderKey("Authorization"): "Bearer \(stripeKey)",
                HeaderKey("Content-Type"): "application/x-www-form-urlencoded"
            ]
            
            let result = try client.post(url, query: [:], headers, urlEncodedForm, through: [])
            if result.status != .ok {
                analytics?.logError("Error when posting charge to Stripe, response = \(result)")
                analytics?.logResponse(result, endpoint: endpoint)
                var errorDict = subscriber.toDictionary()
                let message = result.json?["error.message"]?.string  ?? "Unknown error, please try later"
                errorDict["message"] = message
                analytics?.logResponse(result, endpoint: endpoint, dict: errorDict)
            }
            return result
        } catch let error {
            analytics?.logException(error)
        }
        return nil
    }
    
    public func createStripeClient(token: String, subscriber: Subscriber) -> Response? {
        analytics?.logDebug("Creating Stripe customer for \(subscriber)")
        let payload: [String: Any] = [
            "description": subscriber.description,
            "source": token
        ]
        
        let endpoint = "customers"
        return postToStripe(payload: payload, endpoint: endpoint, subscriber: subscriber)
    }
    
    
    public func stripeCustomerForSubscriber(subscriber: Subscriber,
                                            token: String,
                                            reusePaymentInfo: Bool) -> StripeCustomer? {
        if reusePaymentInfo == true, let stripe_customer_id = subscriber.stripe_customer_id {
            do {
                let result = try StripeCustomer.find(stripe_customer_id)
                return result
            } catch let error {
                analytics?.logException(error,  dict: ["endpoint": "stripe_charge"])
                return nil
            }
        } else {
            guard let clientResponse = createStripeClient(token: token, subscriber: subscriber) else {
                return nil
            }
            
            if clientResponse.status != .ok {
                return nil
            }
            
            guard let stripeCustomerId = clientResponse.json?["id"]?.string else {
                return nil
            }
            
            do {
                let stripeCustomer = StripeCustomer(stripe_customer_id: stripeCustomerId,
                                                    user_id: subscriber.fb_messenger_id)
                try stripeCustomer.save()
                subscriber.stripe_customer_id = stripeCustomerId
                subscriber.remember_card_on_file = reusePaymentInfo
                subscriber.forceSave()
                return stripeCustomer
            } catch let error {
                analytics?.logError("Failed to save stripe client for \(subscriber), customer=\(stripeCustomerId), error=\(error)")
            }
            return nil
        }
    }
    
    
    public func processChargeFor(subscriber: Subscriber,
                                 token: String,
                                 description: String,
                                 amount: Int,
                                 reusePaymentInfo: Bool = false) -> Response? {
        
        guard let stripeCustomer = stripeCustomerForSubscriber(subscriber: subscriber, token: token, reusePaymentInfo: reusePaymentInfo) else {
            return Response(status: .internalServerError,
                            body: "failed to get stripe customer".makeBody())
        }
        
        let customer_id = stripeCustomer.stripe_customer_id
        guard let chargeResponse = stripeCharge(subscriber: subscriber,
                                                description: description,
                                                amount: amount,
                                                stripeCustomerId: customer_id) else {
            return Response(status: .internalServerError,
                            body: "failed to get chargeResponse customer id".makeBody())
        }
        
        guard let json = chargeResponse.json,
            let chargeId = json["id"]?.string,
            let last4 = json["source.last4"]?.string,
            let brand = json["source.brand"]?.string,
            let expMonth = json["source.exp_month"]?.int,
            let expYear = json["source.exp_year"]?.int else {
            return chargeResponse
        }

        let paymentInfo = "\(brand) ending on \(last4) expiry \(expMonth)/\(expYear)"
        do {
            stripeCustomer.default_paymet_info = paymentInfo
            try stripeCustomer.save()
            try StripeCharge(charge_id: chargeId,
                             payment_info: paymentInfo,
                             price: amount,
                             stripe_customer_id: customer_id).save()
        } catch let error {
            analytics?.logError("Failed to save stripe charge or client for \(subscriber), customer=\(customer_id), charge=\(chargeId), error=\(error)")
            analytics?.logException(error,  dict: ["endpoint": "stripe_charge"])
        }

        return chargeResponse
    }
    
    @discardableResult
    public func stripeCharge(subscriber: Subscriber,
                             description: String,
                             amount: Int,
                             stripeCustomerId: String) -> Response? {
        analytics?.logDebug("Charging \(amount)")
        let payload: [String: Any] = [
            "amount": "\(amount)",
            "currency": "usd",
            "description": description,
            "customer": stripeCustomerId
        ]
        
        return postToStripe(payload: payload, endpoint: "charges", subscriber: subscriber)
    }
}


