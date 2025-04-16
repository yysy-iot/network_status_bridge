package com.yueying.network_status_bridge

import android.content.Context
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

object NetworkMonitor {

    @Volatile
    private var connectivityManager: ConnectivityManager? = null
    @Volatile
    private var currentType: NetworkType = NetworkType.NONE

    private val callbacks = ConcurrentHashMap<String, (NetworkType) -> Unit>()

    val isConnected: Boolean
        get() = currentType != NetworkType.NONE

    val type: NetworkType
        get() = currentType

    private val callbackWrapper = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) {
            notifyUpdate()
        }

        override fun onLost(network: Network) {
            notifyUpdate()
        }

        override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
            notifyUpdate()
        }
    }

    fun startMonitoring(context: Context) {
        if (connectivityManager != null) return
        connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val request = NetworkRequest.Builder().build()
        connectivityManager?.registerNetworkCallback(request, callbackWrapper)
        notifyUpdate() // trigger once
    }

    fun addObserver(callback: (NetworkType) -> Unit): String {
        val token = UUID.randomUUID().toString()
        callbacks[token] = callback
        return token
    }

    fun removeObserver(token: String) {
        callbacks.remove(token)
    }

    fun removeAllObservers() {
        callbacks.clear()
    }

    private fun notifyUpdate() {
        val capabilities = connectivityManager?.getNetworkCapabilities(connectivityManager?.activeNetwork)
        val newType = when {
            capabilities == null -> NetworkType.NONE
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> NetworkType.WIFI
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> NetworkType.CELLULAR
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> NetworkType.WIRED
            else -> NetworkType.OTHER
        }
        currentType = newType
        callbacks.values.forEach { it(newType) }
    }
}
