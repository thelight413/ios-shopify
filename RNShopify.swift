//

//  RNShopify.swift

//  RNShopify

//

//  Created by Ohr on 5/15/19.

//  Copyright © 2019 Facebook. All rights reserved.

//



import Foundation

import Buy


@objc(RNShopify)

class RNShopify: NSObject {
    
    //    @objc
    
    //    func constantsToExport() -> [AnyHashable : Any]! {
    
    //        return ["initialCount": 0]
    
    //    }
    
    private var client: Graph.Client?
    
    @objc static func requiresMainQueueSetup() -> Bool {
        
        return false
        
    }
    
    @objc
    
    func initialize(_ domain: String, apiKey:String) {
        
        client = Graph.Client(
            
            shopDomain: domain,
            
            apiKey:     apiKey
            
        )
        
    }
    
    @objc
    
    func loginCustomer(_ username:String, password: String, resolve: @escaping RCTPromiseResolveBlock,
                       
                       rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        let input = Storefront.CustomerAccessTokenCreateInput.create(
            
            email:    username,
            
            password: password
            
        )
        
        
        
        let mutation = Storefront.buildMutation { $0
            
            .customerAccessTokenCreate(input: input) { $0
                
                .customerAccessToken { $0
                    
                    .accessToken()
                    
                    .expiresAt()
                    
                    
                    
                }
                
                .customerUserErrors{ $0
                    
                    .message()
                    .field()
                }
            
                
                
            }
            
        }
        
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.customerAccessTokenCreate {
                
                
                
                if let customerAccessToken = mutation.customerAccessToken, mutation.customerUserErrors.count == 0  {
                    
                    let expiresAt = customerAccessToken.expiresAt.description
                    
                    
                    let accessToken = customerAccessToken.accessToken
                    
                    let customerToken = [
                        
                        "customerToken" : accessToken,
                        
                        "expiresAt": expiresAt
                        
                        ] as [String: Any]
                    
                    resolve(customerToken)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("Failed to login user")
                    
                    
                    mutation.customerUserErrors.forEach {
                        
                        let fieldPath = $0.field?.joined() ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    let errorList = ["error": errors]
                    
                    resolve(errorList)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Failed to login user: (error)")
                
                reject("Customer login error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
        
        
        
        
        
        
    }
    @objc
    func getCustomerInformation(_ token: String, resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let query = Storefront.buildQuery{$0
        
            .customer(customerAccessToken: token){$0
                .firstName()
                .lastName()
                .email()
                .phone()
                .addresses(first: 10){$0
                    .edges{$0
                        .node{$0
                            .address1()
                            .address2()
                            .phone()
                            .city()
                            .company()
                            .country()
                            .countryCodeV2()
                            .id()
                            .province()
                            .zip()
                        }
                    }
                }
            }
        }
        let task = client?.queryGraphWith(query) { response, error in
            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                let checkoutInfo = ["error": "Get Customer Info Error"]
                resolve(checkoutInfo)
            }
            
            let customer = response?.customer
            let edges = customer?.addresses.edges
            var addresses = [Any]()
            for edge in edges ?? []{
                addresses.append(self.convertEdge(fields: edge.fields))
            }
            let email = customer?.email ?? ""
            let firstName = customer?.firstName ?? ""
            let lastName = customer?.lastName ?? ""
           
          
            let checkoutInfo = [
                "email": email ,
                "addresses": addresses,
                "firstName": firstName ,
                "lastName": lastName ,
                ] as [String: Any]
            resolve(checkoutInfo)
        }
        
        task?.resume()
    }
    
    @objc
    func checkout(_ cartItems:Array<NSDictionary>, resolve: @escaping RCTPromiseResolveBlock,
                  
                  rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        
        
        var inputs: [Storefront.CheckoutLineItemInput] = []
        
        for cartItem:NSDictionary in cartItems {
            
            let variant = cartItem.value(forKey: "variant") as? NSDictionary
            
            let quantity = cartItem.value(forKey: "quantity") as? Int32
            
            let variantId = variant?.value(forKey: "id") as? String
            
           
            
            let item = Storefront.CheckoutLineItemInput.create(quantity: quantity! , variantId: GraphQL.ID(rawValue: variantId!) )
            
            inputs.append(item)
            
        }
        
        
       
        
        let input = Storefront.CheckoutCreateInput.create(
           
            lineItems: Input.value(inputs)
        )
        
        let mutation = Storefront.buildMutation { $0
            
            .checkoutCreate(input: input){ $0
                
                .checkout { $0
                    
                    .id()
                    .webUrl()
                }
                
                .checkoutUserErrors{ $0
                    
                    .field()
                    
                    .message()
                    
                }
                
                
                
            }
            
        }
        
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.checkoutCreate {
                
                
                
                if let checkout = mutation.checkout, mutation.checkoutUserErrors.count == 0  {
                    
                    let weburl = checkout.webUrl
                    
                    
                    let checkoutId = checkout.id
                    
                    let checkout = [
                        
                        "checkoutId" : checkoutId.description,
                        
                        "weburl": weburl.absoluteString
                        
                        ] as [String: Any]
                    resolve(checkout)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("Failed to create Checkout")
                    
                    
                    mutation.checkoutUserErrors.forEach {
                        
                        let fieldPath = $0.field?.joined(separator: "-") ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    let errorList = ["error": errors]
                    
                    resolve(errorList)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Create Checkout: (error)")
                
                reject("Create Checkout error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
        
        
        
        
    }
    @objc
    func updateCheckoutLineItems(_ checkoutid: String, cartItems:Array<NSDictionary>, resolve: @escaping RCTPromiseResolveBlock,
                             
                             rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        var inputs: [Storefront.CheckoutLineItemInput] = []
        
        for cartItem:NSDictionary in cartItems {
            
            let variant = cartItem.value(forKey: "variant") as? NSDictionary
            
            let quantity = cartItem.value(forKey: "quantity") as? Int32
            
            let variantId = variant?.value(forKey: "id") as? String
            
           
            let item = Storefront.CheckoutLineItemInput.create(quantity:quantity!, variantId:GraphQL.ID(rawValue: variantId!))
            
            inputs.append(item)
        }
            let mutation = Storefront.buildMutation { $0
                
                .checkoutLineItemsReplace(lineItems: inputs, checkoutId: GraphQL.ID.init(rawValue: checkoutid)) {$0
                    .checkout { $0
                        .id()
                        .webUrl()
                    }
                    
                    .userErrors{ $0
                        
                        .field()
                        
                        .message()
                        
                    }
                    
                    
                    
                }
                
            }
            
            let task = client?.mutateGraphWith(mutation) { response, error in
                
                if let mutation = response?.checkoutLineItemsReplace {
                    
                    
                    
                    if let checkout = mutation.checkout, mutation.userErrors.count == 0  {
                        
                        let weburl = checkout.webUrl
                        
                        
                        let checkoutId = checkout.id
                        
                        let checkout = [
                            
                            "checkoutId" : checkoutId.description,
                            
                            "weburl": weburl.absoluteString
                            
                            ] as [String: Any]
                        resolve(checkout)
                        
                    } else {
                        
                        var errors = [String:String]()
                        
                        print("Failed to update Checkout")
                        
                      
                        
                        mutation.userErrors.forEach {
                            
                            let fieldPath = $0.field?.joined(separator: "-") ?? ""
                            
                            print("  \(fieldPath): \($0.message)")
                            
                            errors[fieldPath] = $0.message
                            
                        }
                        
                        let errorList = ["error": errors]
                        
                        resolve(errorList)
                        
                        
                        
                    }
                    
                    
            
            
        
                }
        }
        task?.resume()
    }
    
    @objc
    func newcheckout(_ cartItems:Array<NSDictionary>, email: String, shippingAddress:[String: Any] , resolve: @escaping RCTPromiseResolveBlock,
                     
                     rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        
        
        var inputs: [Storefront.CheckoutLineItemInput] = []
        
        for cartItem:NSDictionary in cartItems {
            
            let variant = cartItem.value(forKey: "variant") as? NSDictionary
            
            let quantity = cartItem.value(forKey: "quantity") as? Int32
            
            let variantId = variant?.value(forKey: "id") as? String
            
            
            
            let item = Storefront.CheckoutLineItemInput.create(quantity: quantity! , variantId: GraphQL.ID(rawValue: variantId!) )
            
            inputs.append(item)
            
        }
       
    var theemail: Input<String>? = nil
    
        
    if !email.isEmpty{
        theemail = Input<String>.init(orNull: email)
    }
    var theshippingaddress:Input<Storefront.MailingAddressInput>? = nil
    if shippingAddress.count > 0{
        let address1 = shippingAddress["address1"] as? String
        let address2 = shippingAddress["address2"] as? String
        let city = shippingAddress["city"] as? String
        let company = shippingAddress["company"] as? String
        let country = shippingAddress["country"] as? String
        let firstName = shippingAddress["country"] as? String
        let lastName = shippingAddress["lastName"] as? String
        let phone = shippingAddress["phone"] as? String
        let province = shippingAddress["province"] as? String
        let zip = shippingAddress["zip"] as? String
        
        let sa = Storefront.MailingAddressInput.create(address1: Input<String>.init(orNull:address1), address2: Input<String>.init(orNull:address2), city: Input<String>.init(orNull:city) , company: Input<String>.init(orNull:company), country: Input<String>.init(orNull:country), firstName: Input<String>.init(orNull:firstName), lastName: Input<String>.init(orNull:lastName), phone: Input<String>.init(orNull:phone), province: Input<String>.init(orNull:province), zip: Input<String>.init(orNull:zip))
        
        theshippingaddress = Input<Storefront.MailingAddressInput>.init(orNull: sa)
    }
    let input:Storefront.CheckoutCreateInput
    
        if (theemail != nil) && (theshippingaddress != nil){
        input = Storefront.CheckoutCreateInput.create(
            email: theemail!,
            lineItems: Input.value(inputs),
            shippingAddress: theshippingaddress!
        )
    }else{
            input = Storefront.CheckoutCreateInput.create(
            lineItems: Input.value(inputs)
        )
    }
        let mutation = Storefront.buildMutation { $0
            
            .checkoutCreate(input: input){ $0
                
                .checkout { $0
                    
                    .id()
                    .webUrl()
                }
                
                .checkoutUserErrors{ $0
                    
                    .field()
                    
                    .message()
                    
                }
                
                
                
            }
            
        }
        
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.checkoutCreate {
                
                
                
                if let checkout = mutation.checkout, mutation.checkoutUserErrors.count == 0  {
                    
                    let weburl = checkout.webUrl
                    
                    
                    let checkoutId = checkout.id
                    
                    let checkout = [
                        
                        "checkoutId" : checkoutId.description,
                        
                        "weburl": weburl.absoluteString
                        
                        ] as [String: Any]
                    resolve(checkout)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("Failed to create Checkout")
                    
                    
                    mutation.checkoutUserErrors.forEach {
                        
                        let fieldPath = $0.field?.joined(separator: "-") ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    let errorList = ["error": errors]
                    
                    resolve(errorList)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Create Checkout: (error)")
                
                reject("Create Checkout error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
        
        
        
        
    }
    
    
    @objc
    func associateCustomer(_ checkoutId: String, accessToken: String, resolve: @escaping RCTPromiseResolveBlock,
                           
                           rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        
        
        
        let mutation = Storefront.buildMutation{ $0
            
            .checkoutCustomerAssociateV2(checkoutId: GraphQL.ID(rawValue: checkoutId), customerAccessToken: accessToken){ $0
                
                .checkout{ $0
                    .id()
                    .webUrl()
                    .email()
                  
                }
                
                .checkoutUserErrors{ $0
                    
                    .field()
                    
                    .message()
                    
                }
                
            }
            
            
            
        }
        
        
        
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.checkoutCustomerAssociateV2 {
                
                
                
                if let checkout = mutation.checkout, mutation.checkoutUserErrors.count == 0  {
                    
                    let weburl = checkout.webUrl
                    
                    
                    let checkoutId = checkout.id
                    
                    let checkoutInfo = [
                        
                        "checkoutId" : checkoutId.description,
                        
                        "weburl": weburl.absoluteString
                        
                        ] as [String: Any]
                    resolve(checkoutInfo)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("Failed to create Checkout")
                    
                    
                    mutation.checkoutUserErrors.forEach {
                        
                        let fieldPath = $0.field?.joined() ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    let errorList = ["error": errors]
                    
                    resolve(errorList)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Associate Customer Checkout: (error)")
                
                reject("Associate Customer Checkout error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
        
        
    }
    @objc
    func createCustomer(_ email:String, password: String, resolve:@escaping  RCTPromiseResolveBlock,
                        
                        rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let customerInput = Storefront.CustomerCreateInput.create(email: email, password: password,  acceptsMarketing: Input.init(orNull:true))
        let mutation = Storefront.buildMutation{$0
            .customerCreate(input: customerInput){ $0
                .customer{$0
                    .email()
                }
                .customerUserErrors{$0
                    .field()
                    .message()
                }
            }
        }
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.customerCreate {
                
                
                
                if mutation.customerUserErrors.count == 0  {
                    
                    
                    resolve(true)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("failed Renew Customer Token")
                    
                    mutation.customerUserErrors.forEach {
                        
                        let fieldPath = $0.field?.joined() ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    
                    resolve(errors)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Create Customer: (error)")
                reject("Create Customer error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
        
    }
    @objc
    func renewCustomerToken(_ accessToken: String ,resolve: @escaping RCTPromiseResolveBlock,
                            
                            rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        
        
        let mutation = Storefront.buildMutation{$0
            
            .customerAccessTokenRenew(customerAccessToken: accessToken){$0
                
                .customerAccessToken{$0
                    
                    .accessToken()
                    
                    .expiresAt()
                    
                    
                    
                }
                
                .userErrors{ $0
                    
                    .field()
                    
                    .message()
                    
                    
                    
                }
                
                
                
            }
            
            
            
        }
        
        let task = client?.mutateGraphWith(mutation) { response, error in
            
            if let mutation = response?.customerAccessTokenRenew {
                
                
                
                if let customerAccessToken = mutation.customerAccessToken, mutation.userErrors.count == 0  {
                    
                    let expiresAt = customerAccessToken.expiresAt.description
                    
                    
                    let accessToken = customerAccessToken.accessToken
                    
                    let customerToken = [
                        
                        "customerToken" : accessToken,
                        
                        "expiresAt": expiresAt
                        
                        ] as [String: Any]
                    
                    resolve(customerToken)
                    
                } else {
                    
                    var errors = [String:String]()
                    
                    print("failed Renew Customer Token")
                    
                    
                    mutation.userErrors.forEach {
                        
                        let fieldPath = $0.field?.joined() ?? ""
                        
                        print("  \(fieldPath): \($0.message)")
                        
                        errors[fieldPath] = $0.message
                        
                    }
                    
                    let errorList = ["error": mutation.userErrors.debugDescription]
                    
                    resolve(errorList)
                    
                    
                    
                }
                
                
                
            } else {
                
                print("Renew Customer Token: (error)")
                
                reject("Renew Customer Token error","errors",error)
                
                
                
            }
            
            
            
        }
        
        task?.resume()
        
    }
    
    
    @objc
    func getOrders(_ accessToken: String ,cursor: String,newOrders: Bool,resolve: @escaping RCTPromiseResolveBlock,
                            
                            rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        
        let query: Storefront.QueryRootQuery;
        if newOrders{
            query = Storefront.buildQuery{ $0
                .customer(customerAccessToken: accessToken){ $0
                    .orders(last: 10, before: cursor,reverse: true){ $0
                        .edges{$0
                            .cursor()
                            .node{$0
                                .id()
                                .orderNumber()
                                .statusUrl()
                                .processedAt()
                                .totalPriceV2{$0
                                    .amount()
                                }
                            }
                            
                        }
                    }
                }
                
            }

        }else{
            if(cursor != ""){
                
                query = Storefront.buildQuery{ $0
                    .customer(customerAccessToken: accessToken){ $0
                        .orders(first: 10, after: cursor,reverse: true){ $0
                            .edges{$0
                                .cursor()
                                .node{$0
                                    .id()
                                    .orderNumber()
                                    .statusUrl()
                                    .processedAt()
                                    .totalPriceV2{$0
                                        
                                        .amount()
                                    }
                                }
                                
                                
                            }
                            
                            .pageInfo{$0
                                .hasNextPage()
                                
                            }
                            
                        }
                        
                    }
                    
                    
                    
                }
            }else{
            query = Storefront.buildQuery{ $0
                .customer(customerAccessToken: accessToken){ $0
                    .orders(first: 10, reverse: true){ $0
                        .edges{$0
                            .cursor()
                            .node{$0
                                .id()
                                .orderNumber()
                                .statusUrl()
                                .processedAt()
                                .totalPriceV2{$0
                                    .amount()
                                }
                            }
                            
                            
                        }
                        .pageInfo{$0
                            .hasNextPage()
                            
                        }
                        
                    }
                    
                }
                
                
                
            }
            }
        }

        let task = client?.queryGraphWith(query) { response, error in
            var orderInfo:[String: Any]

            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                orderInfo = ["error": "Get Orders Error"]
            }
            let customer = response?.customer as Storefront.Customer?
            
            if let edges = customer?.orders.edges
                {
                    var orders = [Any]()
                    for edge in edges{
                        orders.append(self.convertEdge(fields: edge.fields))
                    }
                let hasNextPage = customer?.orders.pageInfo.hasNextPage
                orderInfo = [
                    "orders": orders,
                    "hasNextPage": hasNextPage!
                    ]
            }else{
            orderInfo = ["error": "Get Orders Error"]
            
        }
           resolve(orderInfo)
        }
            
        task?.resume()
        
        
        
    }
    @objc
    func getOrderLineItems(_ orderId: String, cursor: String, resolve: @escaping RCTPromiseResolveBlock,
                           
                           rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let id = GraphQL.ID.init(rawValue: orderId)
    
        let query = Storefront.buildQuery{$0
            .node(id: id){ $0
                .onOrder{ $0
                    .lineItems(first: 10, after: cursor){$0
                        .edges{$0
                            .cursor()
                            .node{$0
                                .quantity()
                                .title()
                                .variant{$0
                                    .compareAtPriceV2{$0
                                        .amount()
                                        
                                    }
                                    .priceV2{$0
                                        .amount()
                                    }
                                    .sku()
                                    .title()
                                }
                            }
                        }
                        .pageInfo{$0
                            .hasNextPage()
                        }
                    }
                    .totalPriceV2{ $0
                        .amount()
                        
                    }
                    
                    
                    
                }
                
            }
        }
        let task = client?.queryGraphWith(query){ response, error in
            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                let lineItemsInfo = ["error": "Get Line Items Error"]
                resolve(lineItemsInfo)
            }
            let order = response?.node as? Storefront.Order
            let lineitems = order?.lineItems.edges.map{$0.node}
            let hasNextPage = order?.lineItems.pageInfo.hasNextPage
            let lineItemsInfo = [
                "lineitems": lineitems!,
                "hasNextPage": hasNextPage!
            ] as [String: Any]
            resolve(lineItemsInfo)
        }
        task?.resume()
    }
    @objc
    func getCheckoutInfo(_ checkout: String, cursor: String, resolve: @escaping RCTPromiseResolveBlock,
                     
                     rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let checkoutId = GraphQL.ID.init(rawValue: checkout)
        let query = Storefront.buildQuery{$0
            .node(id: checkoutId){ $0
                .onCheckout{ $0
                    .id()
                    .webUrl()
                    .email()
                    .shippingAddress{$0
                        .address1()
                        .address2()
                        .city()
                        .company()
                        .country()
                        .firstName()
                        .lastName()
                        .phone()
                        .province()
                        
                    }
                    .lineItems(first: 10){$0
                        .edges{$0
                            .cursor()
                            
                            .node{$0
                                .quantity()
                                .title()
                                .id()
                                
                                .variant{$0
                                    .id()
                                    .compareAtPriceV2{$0
                                        .amount()
                                        
                                    }
                                    .product{$0
                                        .id()
                                    }
                                    .image{$0
                                        .id()
                                        .transformedSrc()
                                    }
                                    .priceV2{$0
                                        .amount()
                                    }
                                    .sku()
                                    .title()
                                }
                            }
                        }
                        .pageInfo{$0
                            .hasNextPage()
                        }
                    }
                }
            }
            
        }
        let task = client?.queryGraphWith(query){ response, error in
            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                let checkoutInfo = ["error": "Get Checkout Error"]
                
                resolve(checkoutInfo)
            }
            
            let checkout = response?.node as? Storefront.Checkout
            let weburl = checkout?.webUrl.absoluteString
            let id = checkout?.id.description
            let edges = checkout?.lineItems.edges
            var checkoutLineItems = [Any]()
            for edge in edges ?? []{
                checkoutLineItems.append(self.convertEdge(fields: edge.fields))
            }
            let shippingAddress = checkout?.shippingAddress?.fields
            let email = checkout?.email
            let hasNextPage = checkout?.lineItems.pageInfo.hasNextPage
            let checkoutInfo = [
                "weburl": weburl ?? "",
                "email": email ?? "",
                "id": id ?? "",
                "shippingAddress":shippingAddress ?? "",
                "lineitems": checkoutLineItems,
                "hasNextPage": hasNextPage ?? false
                ] as [String: Any]
            resolve(checkoutInfo)
        }
        task?.resume()
        
        
    }
    @objc
    func getCardVaultUrl(_ resolve: @escaping RCTPromiseResolveBlock,
                         
                         rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
    
         let query = Storefront.buildQuery{$0
            .shop{$0
                .paymentSettings{$0
                    .cardVaultUrl()
                    }
                    
                }
                
            }
        let task = client?.queryGraphWith(query){ response, error in
            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                let checkoutInfo = ["error": "Get vault url Error"]
                resolve(checkoutInfo)
            }
            let vaulturl = response?.shop.paymentSettings.cardVaultUrl.absoluteString
            resolve(vaulturl)
        }
        task?.resume()
    }
    
    @objc
    func sendPayment(_ vaultUrl: String, resolve: @escaping RCTPromiseResolveBlock,
    
    rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let cardClient =  Card.Client()
        let creditCard = Card.CreditCard(
            firstName:        "John",
            middleName:       "Singleton",
            lastName:         "Smith",
            number:           "1234567812345678",
            expiryMonth:      "07",
            expiryYear:       "19",
            verificationCode: "1234"
        )
        
        let task = cardClient.vault(creditCard, to: URL(string: vaultUrl)!) { token, error in
            if let token = token {
                // proceed to complete checkout with `token`
                resolve(token)
            } else {
                // handle error
                print(error ?? "")
            }
        }
        task.resume()
    
    
    }
    
    @objc
    func getProductByID(_ productid: String, cursor: String, resolve: @escaping RCTPromiseResolveBlock,
                            
                            rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        let query:Storefront.QueryRootQuery
        if productid != "dailydeal"{
            
            let productId = GraphQL.ID.init(rawValue: productid)

            query = Storefront.buildQuery{$0
            .node(id: productId){ $0
            
                .onProduct{$0
                    .descriptionHtml()
                    .availableForSale()
                    .handle()
                    .id()
                    .title()
                    .vendor()
                    .metafields(first: 10){$0
                        .edges{$0
                            .node{$0
                                .namespace()
                                .key()
                                .value()
                            }
                        }
                    }
                    .variants(first: 30){$0
                        .edges{$0
                            .node{$0
                                .id()
                                .availableForSale()
                                .compareAtPriceV2{$0
                                    .amount()
                                    .currencyCode()
                                }
                                .priceV2{$0
                                    .amount()
                                    .currencyCode()
                                }
                                .title()
                                
                            }
                        }
                    }
                    .images(first: 10){$0
                        .edges{$0
                            .node{$0
                                .id()
                                .originalSrc()
                                .transformedSrc()
                            }
                        }
                        
                    }
                        }
                }
            }
            
        }else{
            
            
            query = Storefront.buildQuery{$0
                .products( first: 1,query: "tag:dailydeal"){$0
                    .edges{$0
                        .node{$0
                        .descriptionHtml()
                        .availableForSale()
                        .handle()
                        .vendor()
                        .id()
                        .title()
                        .metafields(first: 10){$0
                            .edges{$0
                                .node{$0
                                    .namespace()
                                    .key()
                                    .value()
                                }
                            }
                        }
                        .variants(first: 30){$0
                            .edges{$0
                                .node{$0
                                    .id()
                                
                                    .availableForSale()
                                    .compareAtPriceV2{$0
                                        .amount()
                                        .currencyCode()
                                    }
                                    .priceV2{$0
                                        .amount()
                                        .currencyCode()
                                    }
                                    .title()
                                    
                                }
                            }
                        }
                        .images(first: 10){$0
                            .edges{$0
                                .node{$0
                                    .id()
                                    .originalSrc()
                                    .transformedSrc()
                                }
                            }
                            
                        }
                    }
                }
            }
            }
        }
        let task = client?.queryGraphWith(query){ response, error in
            if let error = error, case .invalidQuery(let reasons) = error {
                reasons.forEach {
                    print("Error on \($0.line ?? 0):\(String(describing: $0.column)) - \($0.message)")
                }
                let checkoutInfo = ["error": "Couldn't get product information"]
                resolve(checkoutInfo)
            }
            let product: [String: Any]
            if(productid == "dailydeal"){
                product = self.convertEdge(fields: (response?.products.edges.first!.fields)!)
            }else{
                let p = response?.node as? Storefront.Product
                let f = p?.fields
                if f != nil{
                    product = self.convertNode(fields: f!)
                }else{
                    product=["product":false]
                }
            }
            resolve(product)
        }
        task?.resume()
    
    }
    func convertNode(fields: [String: Any]) -> [String: Any] {
        var nodeArray = [:] as [String: Any]

        for field in fields{
            
                nodeArray[field.key] = field.value
            
            
        }
        
        return nodeArray
    }
    func convertEdge(fields: [String: Any]) -> [String:Any] {
        let nodeFields = fields["node"] as! [String:Any]
        var node = convertNode(fields: nodeFields)
        if(fields["cursor"] != nil){
            node["cursor"] = fields["cursor"]
        }
        return node
        
    }
}
