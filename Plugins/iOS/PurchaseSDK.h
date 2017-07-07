//
//  PurchaseSDK.h
//  Unity-iPhone
//
//  Created by wang guo qing on 2017/3/24.
//
//
#import <Foundation/Foundation.h>
#import "StoreKit/StoreKit.h"
#import"UnityInterface.h"

@interface PurchaseSDK : NSObject <SKProductsRequestDelegate, SKPaymentTransactionObserver>

+(instancetype) Instance;

@property double SystemVersion;
@property NSString* ObjName;
@property NSString* SuccCall;
@property NSString* FailCall;
@property NSMutableDictionary* TransactionDict;

-(void)Init:(NSString*)objName SuccCall:(NSString*)succCall FailCall:(NSString*)failCall;

-(void)BuyProduct:(NSString * )productId Quantity:(NSInteger)quantity SignId:(NSString * )signId;

-(void)FinishTransaction:(NSString*)transactionIdentifier;

-(void)BuyProductBySKProductsRequest:(NSString * )productId;

- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction;

@end

