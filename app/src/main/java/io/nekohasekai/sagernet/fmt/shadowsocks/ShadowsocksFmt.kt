package io.nekohasekai.sagernet.fmt.shadowsocks

import android.util.Log
import io.nekohasekai.sagernet.ktx.*
import moe.matsuri.nb4a.SingBoxOptions
import moe.matsuri.nb4a.utils.Util
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import org.json.JSONObject

fun ShadowsocksBean.fixPluginName() {
    if (plugin.startsWith("simple-obfs")) {
        plugin = plugin.replaceFirst("simple-obfs", "obfs-local")
    }
}

fun parseShadowsocks(url: String): ShadowsocksBean {
    fun parseTLSDirectPort(port: String?): Int? {
        val value = port?.toIntOrNull() ?: return null
        return if (value > 0) value else null
    }

    if (url.substringBefore("#").contains("@")) {
        var link = url.replace("ss://", "https://").toHttpUrlOrNull() ?: error(
            "invalid ss-android link $url"
        )

        if (link.username.isBlank()) { // fix justmysocks's shit link
            link = (("https://" + url.substringAfter("ss://")
                .substringBefore("#")
                .decodeBase64UrlSafe()).toHttpUrlOrNull()
                ?: error("invalid jms link $url")
                    ).newBuilder().fragment(url.substringAfter("#")).build()
        }

        // ss-android style

        if (link.password.isNotBlank()) {
            return ShadowsocksBean().apply {
                serverAddress = link.host
                serverPort = link.port
                method = link.username
                password = link.password
                plugin = link.queryParameter("plugin") ?: ""
                experimentalTlsDirect = link.queryParameter("experimental_tls_direct") == "1"
                experimentalTlsDirectPort = parseTLSDirectPort(
                    link.queryParameter("experimental_tls_direct_port")
                )
                name = link.fragment
                fixPluginName()
            }
        }

        val methodAndPswd = link.username.decodeBase64UrlSafe()

        return ShadowsocksBean().apply {
            serverAddress = link.host
            serverPort = link.port
            method = methodAndPswd.substringBefore(":")
            password = methodAndPswd.substringAfter(":")
            plugin = link.queryParameter("plugin") ?: ""
            experimentalTlsDirect = link.queryParameter("experimental_tls_direct") == "1"
            experimentalTlsDirectPort = parseTLSDirectPort(
                link.queryParameter("experimental_tls_direct_port")
            )
            name = link.fragment
            fixPluginName()
        }
    } else {
        // v2rayN style
        var v2Url = url

        if (v2Url.contains("#")) v2Url = v2Url.substringBefore("#")

        val link = ("https://" + v2Url.substringAfter("ss://")
            .decodeBase64UrlSafe()).toHttpUrlOrNull() ?: error("invalid v2rayN link $url")

        return ShadowsocksBean().apply {
            serverAddress = link.host
            serverPort = link.port
            method = link.username
            password = link.password
            plugin = ""
            val remarks = url.substringAfter("#").unUrlSafe()
            if (remarks.isNotBlank()) name = remarks
        }
    }

}

fun ShadowsocksBean.toUri(): String {

    val builder = linkBuilder().username(Util.b64EncodeUrlSafe("$method:$password"))
        .host(serverAddress)
        .port(serverPort)

    if (plugin.isNotBlank()) {
        builder.addQueryParameter("plugin", plugin)
    }

    if (experimentalTlsDirect) {
        builder.addQueryParameter("experimental_tls_direct", "1")
        experimentalTlsDirectPort?.takeIf { it > 0 }?.let {
            builder.addQueryParameter("experimental_tls_direct_port", it.toString())
        }
    }

    if (name.isNotBlank()) {
        builder.encodedFragment(name.urlSafe())
    }

    return builder.toLink("ss").replace("$serverPort/", "$serverPort")

}

fun JSONObject.parseShadowsocks(): ShadowsocksBean {
    return ShadowsocksBean().apply {
        serverAddress = getStr("server")
        serverPort = getIntNya("server_port")
        password = getStr("password")
        method = getStr("method")
        name = optString("remarks", "")
        experimentalTlsDirect = optBoolean("experimental_tls_direct", false)
        experimentalTlsDirectPort = optInt("experimental_tls_direct_port").takeIf { it > 0 }

        val pId = getStr("plugin")
        if (!pId.isNullOrBlank()) {
            plugin = pId + ";" + optString("plugin_opts", "")
        }
    }
}

fun buildSingBoxOutboundShadowsocksBean(bean: ShadowsocksBean): SingBoxOptions.Outbound_ShadowsocksOptions {
    val selectedServerPort = if (bean.experimentalTlsDirect) {
        bean.experimentalTlsDirectPort?.takeIf { it > 0 } ?: bean.serverPort
    } else {
        bean.serverPort
    }
    Log.w(
        "NekoTLSDirect",
        "build shadowsocks outbound server=${bean.serverAddress} port=$selectedServerPort tlsDirect=${bean.experimentalTlsDirect} tlsDirectPort=${bean.experimentalTlsDirectPort}"
    )
    return SingBoxOptions.Outbound_ShadowsocksOptions().apply {
        type = "shadowsocks"
        server = bean.serverAddress
        server_port = selectedServerPort
        password = bean.password
        method = bean.method
        if (bean.plugin.isNotBlank()) {
            plugin = bean.plugin.substringBefore(";")
            plugin_opts = bean.plugin.substringAfter(";")
            if (plugin == "none") {
                plugin = null
                plugin_opts = null
            }
        }
        if (bean.experimentalTlsDirect) {
            _hack_config_map["experimental_tls_direct"] = true
        }
    }
}
