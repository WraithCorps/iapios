#import <Foundation/Foundation.h>
#import"UnityInterface.h"
#import "PurchaseSDK.h"

#if defined (__cplusplus)
extern "C" {
#endif

    void IosInitPurchaseSDK (char* callbackGameObject, char* callbackSuccFunc,char* callbackFailFunc)
    {
	   NSString* s_callbackGameObject = [NSString stringWithUTF8String: callbackGameObject];
       NSString* s_callbackSuccFunc = [NSString stringWithUTF8String: callbackSuccFunc];
		NSString*s_callbackFailFunc = [NSString stringWithUTF8String: callbackFailFunc];
        [PurchaseSDK.Instance Init:s_callbackGameObject SuccCall:s_callbackSuccFunc FailCall:s_callbackFailFunc];
    }

    void Purchase (char* productId,int count,char*userId)
    {
        NSString* signId=[[NSString alloc] initWithCString:(const char*)userId encoding:NSUTF8StringEncoding];
        NSString *id = [[NSString alloc] initWithCString:(const char*)productId encoding:NSUTF8StringEncoding];
        [[PurchaseSDK Instance] BuyProduct:id Quantity:count SignId:signId];
    }

    
    void FinishTransaction(char* transactionIdentifier)
    {
        NSString* id = [NSString stringWithUTF8String: transactionIdentifier];
         [[PurchaseSDK Instance] FinishTransaction:id];
    }
    
#if defined (__cplusplus)
}
#endif
