#import "YYINetworkMonitor.h"
#import <Network/Network.h>
#import <os/lock.h>

@interface YYINetworkMonitor () {
    nw_path_monitor_t _monitor;
    os_unfair_lock _lock;
}

@property (nonatomic, assign, readwrite) BOOL isConnected;

@property (nonatomic, assign, readwrite) YYINetworkType currentType;

@property (nonatomic, strong) NSMutableDictionary<NSString*, void (^)(YYINetworkType)> *callbackMap;

@end

@implementation YYINetworkMonitor


- (void)startMonitoring {
    os_unfair_lock_lock(&_lock);
    [self _startMonitoring];
    os_unfair_lock_unlock(&_lock);
}

- (NSString *)addObserver:(void (^)(YYINetworkType type))callback {
    if (!callback) return nil;
    NSString *token = NSUUID.UUID.UUIDString;
    // 同步注册，确保 observer 在返回前已加入，避免遗漏注册后的网络变化
    os_unfair_lock_lock(&_lock);
    self.callbackMap[token] = [callback copy];
    os_unfair_lock_unlock(&_lock);
    return token;
}

- (void)removeObserver:(NSString *)token {
    if (!token) return;
    os_unfair_lock_lock(&_lock);
    [self.callbackMap removeObjectForKey:token];
    os_unfair_lock_unlock(&_lock);
}

- (void)removeAllObservers {
    os_unfair_lock_lock(&_lock);
    [self.callbackMap removeAllObjects];
    os_unfair_lock_unlock(&_lock);
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
    NSArray *callbacks;
    // 锁内：只更新数据 + 拷贝回调列表，不执行任何回调
    os_unfair_lock_lock(&_lock);
    self.isConnected = (type != YYINetworkTypeNone);
    self.currentType = type;
    callbacks = [self.callbackMap.allValues copy];
    os_unfair_lock_unlock(&_lock);

    // 锁外：执行回调。回调可任意耗时，甚至同步调用 currentType/isConnected，不会死锁
    for (void (^callback)(YYINetworkType type) in callbacks) {
        if (callback) callback(type);
    }
}

#pragma mark - Thread-safe property getter

- (BOOL)isConnected {
    os_unfair_lock_lock(&_lock);
    BOOL value = _isConnected;
    os_unfair_lock_unlock(&_lock);
    return value;
}

- (YYINetworkType)currentType {
    os_unfair_lock_lock(&_lock);
    YYINetworkType type = _currentType;
    os_unfair_lock_unlock(&_lock);
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
        _lock = OS_UNFAIR_LOCK_INIT;
        _callbackMap = [NSMutableDictionary dictionary];
    }
    return self;
}

@end