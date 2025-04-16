#import "YYINetworkMonitor.h"
#import <Network/Network.h>

@interface YYINetworkMonitor () {
    nw_path_monitor_t _monitor;
    dispatch_queue_t _syncQueue;
}

@property (nonatomic, assign, readwrite) BOOL isConnected;

@property (nonatomic, assign, readwrite) YYINetworkType currentType;

@property (nonatomic, strong) NSMutableDictionary<NSString*, void (^)(YYINetworkType)> *callbackMap;

@end

@implementation YYINetworkMonitor


- (void)startMonitoring {
    dispatch_barrier_async(_syncQueue, ^{
        [self _startMonitoring];
    });
}

- (NSString *)addObserver:(void (^)(YYINetworkType type))callback {
    if (!callback) return nil;
    NSString *token = NSUUID.UUID.UUIDString;
    dispatch_barrier_async(_syncQueue, ^{
        self.callbackMap[token] = [callback copy];
    });
    return token;
}

- (void)removeObserver:(NSString *)token {
    if (!token) return;
    dispatch_barrier_async(_syncQueue, ^{
        [self.callbackMap removeObjectForKey:token];
    });
}

- (void)removeAllObservers {
    dispatch_barrier_async(_syncQueue, ^{
        [self.callbackMap removeAllObjects];
    });
}

#pragma mark - Private

///
- (void)_startMonitoring {
    if (_monitor) return;
    _monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(_monitor, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    //
    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(_monitor, ^(nw_path_t path) {
        __strong typeof(weakSelf) self = weakSelf;
        if (!self) return;
        YYINetworkType type = YYINetworkTypeNone;
        if (nw_path_get_status(path) == nw_path_status_satisfied) {
            if (nw_path_uses_interface_type(path, nw_interface_type_wifi)) {
                type = YYINetworkTypeWiFi;
            } else if (nw_path_uses_interface_type(path, nw_interface_type_cellular)) {
                type = YYINetworkTypeCellular;
            } else if (nw_path_uses_interface_type(path, nw_interface_type_wired)) {
                type = YYINetworkTypeWired;
            } else {
                type = YYINetworkTypeOther;
            }
        }
        [self updateType:type];
    });
    //
    nw_path_monitor_start(_monitor);
}


///
- (void)updateType:(YYINetworkType)type {
    dispatch_barrier_async(_syncQueue, ^{
        self.isConnected = (type != YYINetworkTypeNone);
        self.currentType = type;
        [self performCallbacks:type];
    });
}

/// 回调所有监听者
- (void)performCallbacks:(YYINetworkType)type {
    for (void (^callback)(YYINetworkType type) in _callbackMap.allValues) {
        if (callback) callback(type);
    }
}

#pragma mark - Thread-safe property getter

- (BOOL)isConnected {
    __block BOOL value;
    dispatch_sync(_syncQueue, ^{
        value = _isConnected;
    });
    return value;
}

- (YYINetworkType)currentType {
    __block YYINetworkType type;
    dispatch_sync(_syncQueue, ^{
        type = _currentType;
    });
    return type;
}

#pragma mark - Shared


+ (instancetype)shared {
    static YYINetworkMonitor *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super allocWithZone:NULL] initPrivate];
    });
    return instance;
}

// 禁止外部直接 alloc/init
+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self shared];
}


- (instancetype)init {
    return [self.class shared];
}

- (instancetype)copyWithZone:(NSZone *)zone {
    return self;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone {
    return self;
}

// 真正的私有初始化方法
- (instancetype)initPrivate {
    self = [super init];
    if (self) {
        _syncQueue = dispatch_queue_create("com.guoanvision.network_monitor.sync", DISPATCH_QUEUE_CONCURRENT);
        _callbackMap = [NSMutableDictionary dictionary];
    }
    return self;
}

@end
