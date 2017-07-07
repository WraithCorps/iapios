##Unity IAP说明

####Purchase.m脚本提供对外的Api
	**IosInitPurchaseSDK 初始化sdk**
	callbackGameObject：场景物体名字
	callbackSuccFunc:物体上组件内公有方法名，用于接收支付成功的回调
	callbackFailFunc:物体上组件内公有方法名,用于接收支付失败的回调
####
	Purchase:购买商品
	productId:商品id
	userId：该商品购买的用户id，不用则传空字符串
####
	FinishTransaction:购买完成，订单处理完成后要调用该方法，如果不掉用则订单会被重新推送
	transactionIdentifier:订单id
	
	
	
	