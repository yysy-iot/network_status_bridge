typedef NS_ENUM(NSInteger, YYINetworkType) {
    YYINetworkTypeNone = 0,
    YYINetworkTypeWiFi,
    YYINetworkTypeCellular,
    YYINetworkTypeWired,
    YYINetworkTypeOther,
};

@interface YYINetworkMonitor : NSObject

@property (nonatomic, assign, readonly) BOOL isConnected;

@property (nonatomic, assign, readonly) YYINetworkType currentType;

/// 单例访问
@property (nonatomic, class, readonly, nonnull) YYINetworkMonitor* shared;


- (instancetype _Nullable)init NS_UNAVAILABLE;

/// 启动监听
- (void)startMonitoring;
/// 添加网络状态监听者（支持多回调） 返回 token
- (NSString *_Nonnull)addObserver:(void (^_Nonnull)(YYINetworkType type))callback;
/// 移除网络状态监听者（支持多回调）
- (void)removeObserver:(NSString *_Nonnull)token;
/// 清除所有监听者
- (void)removeAllObservers;

@end
