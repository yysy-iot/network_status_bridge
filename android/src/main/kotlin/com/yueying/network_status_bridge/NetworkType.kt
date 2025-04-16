package com.yueying.network_status_bridge

enum class NetworkType(val value: Int) {
    NONE(0),
    WIFI(1),
    CELLULAR(2),
    WIRED(3),
    OTHER(4);
}