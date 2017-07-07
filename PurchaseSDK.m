//
//  PurchaseSDK.m
//  Unity-iPhone
//
//  Created by wang guo qing on 2017/3/24.
//
//

#import <Foundation/Foundation.h>
#import "PurchaseSDK.h"

@implementation PurchaseSDK

+(instancetype) Instance{
    static PurchaseSDK*instance=nil;
    static dispatch_once_t onceToken=0;
    dispatch_once(&onceToken,^{
        instance=[[PurchaseSDK alloc] init];
    });
    return instance;
}

-(void)Init:(NSString*)objName SuccCall:(NSString*)succCall FailCall:(NSString*)failCall{
    _ObjName=objName;
    _SuccCall=succCall;
    _FailCall=failCall;
    _TransactionDict=[NSMutableDictionary dictionary];
    NSString *version=[UIDevice currentDevice].systemVersion;
    NSLog(@"系统版本号：%@",version);
    _SystemVersion=[[UIDevice currentDevice] systemVersion].floatValue;
    //NSLog(@"系统版本号：%f",_SystemVersion);
    //注册观察者
    [[SKPaymentQueue defaultQueue]addTransactionObserver:self];
    
    //获取购买过所有的非消耗商品
    //[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

//使用商品查询会有bug，当查询时断网，回调方法productsRequest始终不会被调用，网络恢复后也不会被调用；在上一种情况操作的基础上网络恢复后再次查询商品也不会有回调，大约5-10分钟后再次查询商品才有回调
-(void)BuyProductBySKProductsRequest:(NSString * )productId
{
    
    if([SKPaymentQueue canMakePayments])
    {
        NSLog(@"---------查询商品请求------------");
        //请求商品信息
        NSSet* dataSet = [[NSSet alloc] initWithObjects:productId, nil];
        SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:dataSet];
        request.delegate = self;
        [request start];
    }
    else
    {
        NSLog(@"应用内不允许购买！");
    }
}
// 请求商品信息回调，商品信息
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSLog(@"productsRequest=======");
    NSArray * products = response.products;
    NSLog(@"产品Product count:%d",(int)response.invalidProductIdentifiers.count);
    NSLog(@"产品付费数量: %d", (int)[products count]);
    for(SKProduct *product in products){
        NSLog(@"SKProduct 描述信息%@", [product description]);
        NSLog(@"产品标题 %@" , product.localizedTitle);
        NSLog(@"产品描述信息: %@" , product.localizedDescription);
        NSLog(@"价格: %@" , product.price);
        NSLog(@"Product id: %@" , product.productIdentifier);
    }
    if(products.count>0)
    {
        SKPayment *payment = [SKPayment paymentWithProduct:products[0]];
        //payment.applicationUsername=;
        //NSLog(@"buyProduct::updatedTransactions,applicationUsername:%@",payment.applicationUsername);
         NSLog(@"---------发送购买请求------------");
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    else
    {
        NSLog(@"获取商品信息失败,连接AppStore失败，请稍后再试,或则商品不存在!");
    }
    
}

-(void)BuyProduct:(NSString * )productId  Quantity:(NSInteger)quantity SignId:(NSString * )signId
{
    
    if([SKPaymentQueue canMakePayments])
    {
        NSLog(@"---------发送购买请求------------");
        //请求商品信息
        SKMutablePayment *payment = [[SKMutablePayment alloc] init];
        payment.productIdentifier=productId;
        payment.quantity=quantity;
        payment.applicationUsername=signId;
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] addPayment:payment];
        }
    }
    else
    {
        NSLog(@"游戏内不允许购买！");
        UnitySendMessage([_ObjName UTF8String],[_FailCall UTF8String],[@"游戏内不允许购买!" UTF8String]);
    }
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {

        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"paymentQueue::updatedTransactions,SKPaymentTransactionStatePurchasing");
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"paymentQueue::updatedTransactions,SKPaymentTransactionStatePurchased");
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"paymentQueue::updatedTransactions,SKPaymentTransactionStateFailed");
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                NSLog(@"paymentQueue::updatedTransactions,SKPaymentTransactionStateRestored");
                [self restoreTransaction:transaction];
            //case SKPaymentTransactionStateDeferred:
              //  NSLog(@"paymentQueue::updatedTransactions,SKPaymentTransactionStateDeferred");
            default:
                NSLog(@"paymentQueue::updatedTransactions,default null error");
                UnitySendMessage([_ObjName UTF8String],[_FailCall UTF8String],[@"购买失败!" UTF8String]);
                break;
        }
    }
}

//购买成功
- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    
    //获取receipt
    //NSString* receipt=@"";
    NSString*base64Receipt=@"";
    //NSLog(@"completeTransaction productId::%@",transaction.payment.productIdentifier);
    if(_SystemVersion>=8.0)
    {
        //NSURLRequest*request=[NSURLRequest requestWithURL:[[NSBundle mainBundle]appStoreReceiptURL]];
        //NSError*error=nil;
        //NSData * receiptData=[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:&error ];
        
        
        // appStoreReceiptURL iOS7.0增加的，购买交易完成后，会将凭据存放在该地址
        NSURL *receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
        // 从沙盒中获取到购买凭据
        NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
        //receipt=[[NSString alloc] initWithData:receiptData encoding:NSASCIIStringEncoding];
        base64Receipt=[[NSString alloc] initWithData:[receiptData base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed] encoding:NSUTF8StringEncoding];
    }
    else
    {
        //receipt=[[NSString alloc] initWithData:[transaction transactionReceipt] encoding:NSUTF8StringEncoding];
        base64Receipt=[[NSString alloc] initWithData:[[transaction transactionReceipt]  base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed] encoding:NSUTF8StringEncoding];
    }
    
    //NSLog(@"completeTransaction Receipt::%@",base64Receipt);
    NSLog(@"购买成功::transactionIdentifier:%@,applicationUsername:%@, quantity::%d",transaction.transactionIdentifier,transaction.payment.applicationUsername,(int)transaction.payment.quantity);

    
    //缓存当前订单数据，直到业务层将订单处理完成才通知appstore该订单已经成功处理；不通知则认为该订单未完成，在下次打开应用的时候appstore重新下发未完成的订单
    [_TransactionDict setObject:transaction forKey:transaction.transactionIdentifier];
    
    //回调unity
	NSString* userName=transaction.payment.applicationUsername;
	if(userName==nil)
	{
		userName=@"";
	}
    NSString* res=@"";
    res=[res stringByAppendingFormat:@"%@,%@,%d,%@,%@", transaction.transactionIdentifier,transaction.payment.productIdentifier,(int)transaction.payment.quantity,userName,base64Receipt];
    UnitySendMessage([_ObjName UTF8String],[_SuccCall UTF8String],[res UTF8String]);
    
}

//通知appstore该订单已经成功处理,不通知则appstore认为该订单未完成，在下次打开应用的时候appstore重新下发未完成的订单
-(void)FinishTransaction:(NSString*)transactionIdentifier
{
    SKPaymentTransaction* transaction=[_TransactionDict objectForKey:transactionIdentifier];
    if(transaction!=nil)
    {
        if ([SKPaymentQueue defaultQueue]) {
            [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        }
        
        [_TransactionDict removeObjectForKey:transactionIdentifier];
    }
}

//购买失败
- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    
    NSString* errStr=@"";
    if (transaction.error.code == SKErrorPaymentCancelled) {
        NSLog(@"SKErrorPaymentCancelled");
        errStr=@"SKErrorPaymentCancelled";
    }else if (transaction.error.code == SKErrorClientInvalid) {
        NSLog(@"SKErrorClientInvalid");
        errStr=@"SKErrorClientInvalid";
    }else if (transaction.error.code == SKErrorPaymentInvalid) {
        NSLog(@"SKErrorPaymentInvalid");
        errStr=@"SKErrorPaymentInvalid";
    }else if (transaction.error.code == SKErrorPaymentNotAllowed) {
        NSLog(@"SKErrorPaymentNotAllowed");
        errStr=@"SKErrorPaymentNotAllowed";
    }else if (transaction.error.code == SKErrorStoreProductNotAvailable) {
        NSLog(@"SKErrorStoreProductNotAvailable");
        errStr=@"SKErrorStoreProductNotAvailable";
    }else{
        //商品不存在，支付中断网，支付中应用被切到后台自动终止支付
        errStr=@"支付失败!!!";
    }
		  NSLog(@"SKPaymentTransactionStateFailed：%@",transaction.error.description);
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
    }
    
    
    UnitySendMessage([_ObjName UTF8String],[_FailCall UTF8String],[errStr UTF8String]);
}


//恢复购买
- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"------恢复购买-----------");
    //[self provideContentWithTransaction:transaction];
    
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
        
        
    }
    
}
- (void)provideContentWithTransaction:(SKPaymentTransaction *)transaction {
    
    NSString* productIdentifier = @"";
    
    if (transaction.originalTransaction) {
        productIdentifier = transaction.originalTransaction.payment.productIdentifier;
    }
    else {
        productIdentifier = transaction.payment.productIdentifier;
    }
    
    //check productIdentifier exist or not
    //it can be possible nil
    if (productIdentifier) {
        //[SFHFKeychainUtils storeUsername:productIdentifier andPassword:@"YES" forServiceName:@"IAPHelper" updateExisting:YES error:nil];
        //[_purchasedProducts addObject:productIdentifier];
    }
}

// Sent when transactions are removed from the queue (via finishTransaction:).
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    
}
// Sent when an error is encountered while adding transactions from the user's purchase history back to the queue.
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    
    NSLog(@"支付失败：%d,%@",(int)error.code,error.localizedDescription);
}
// Sent when all transactions from the user's purchase history have successfully been added back to the queue.
- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"已购买商品数量：%i",(int)queue.transactions.count);
    for (SKPaymentTransaction*transaction in queue.transactions) {
        NSString*productId=transaction.payment.productIdentifier;
        NSString*transactionId=transaction.transactionIdentifier;
        NSLog(@"已购买商品,id:%@,productId:%@",transactionId,productId);
    }
}

// Sent when the download state has changed.
- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads
{
    
}


- (void)dealloc
{
    if ([SKPaymentQueue defaultQueue]) {
        [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    }
}



@end
