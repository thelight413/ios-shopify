// RNShopify.m
//  Use this file to import your target's public headers that you would like to expose to Swift.
//
#import "React/RCTBridgeModule.h"

@interface RCT_EXTERN_MODULE(RNShopify, NSObject)
RCT_EXTERN_METHOD(initialize:(NSString)domain apiKey:(NSString)apiKey)
RCT_EXTERN_METHOD(loginCustomer:(NSString)username password:(NSString)password resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getCustomerInformation:(NSString)token resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(checkout:(NSArray<NSDictionary>)cartItems resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(updateCheckoutLineItems:(NSString)checkoutid cartItems:(NSArray<NSDictionary>)cartItems
                  resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(newcheckout:(NSArray<NSDictionary>)cartItems email:(NSString)email shippingAddress:(NSDictionary)shippingAddress resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(associateCustomer:(NSString)checkoutId accessToken: (NSString)accessToken resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(createCustomer:(NSString)email password:(NSString)password resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(renewCustomerToken:(NSString)accessToken resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getOrders:(NSString)accessToken cursor: (NSString)cursor newOrders:(Bool)newOrders resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getOrderLineItems:(NSString)orderId cursor: (NSString)cursor resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
RCT_EXTERN_METHOD(getCheckoutInfo:(NSString)checkout cursor: (NSString)cursor resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)

RCT_EXTERN_METHOD(getProductByID:(NSString)productid cursor:(NSString)cursor resolve: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
@end
