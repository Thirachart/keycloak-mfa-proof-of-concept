<#-- Builds oauth2-proxy "start" links from the client's Home URL (Keycloak Admin > Clients > Home URL)
     instead of a hardcoded per-environment domain, so changing environments only means updating
     that one Keycloak setting — not the theme ConfigMap. Falls back to the theme.properties values
     only when no client context is available (client.baseUrl empty). -->

<#function appBaseUrlNoTrailingSlash>
    <#if client.baseUrl?ends_with("/")>
        <#return client.baseUrl[0..<client.baseUrl?length - 1]>
    <#else>
        <#return client.baseUrl>
    </#if>
</#function>

<#function appLoginUrl>
    <#if (client.baseUrl)?has_content>
        <#local base = appBaseUrlNoTrailingSlash()>
        <#return base + "/oauth2/start?rd=" + (base + "/")?url("UTF-8")>
    <#else>
        <#return properties.pocLoginUrl>
    </#if>
</#function>

<#function appUpdateEmailUrl>
    <#if (client.baseUrl)?has_content>
        <#local base = appBaseUrlNoTrailingSlash()>
        <#return base + "/oauth2/start?rd=" + (base + "/")?url("UTF-8") + "&kc_action=UPDATE_EMAIL">
    <#else>
        <#return properties.pocUpdateEmailUrl>
    </#if>
</#function>
