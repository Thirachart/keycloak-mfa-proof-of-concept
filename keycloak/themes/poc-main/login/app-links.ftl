<#-- Builds oauth2-proxy "start" links from the client's Home URL (Keycloak Admin > Clients > Home URL)
     instead of a hardcoded per-environment domain, so changing environments only means updating
     that one Keycloak setting — never the theme ConfigMap. There is deliberately no hardcoded
     domain fallback here: callers must check (client.baseUrl)?has_content themselves and skip
     rendering the link/button when it's empty. -->

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
        <#return "">
    </#if>
</#function>

<#function appUpdateEmailUrl>
    <#if (client.baseUrl)?has_content>
        <#local base = appBaseUrlNoTrailingSlash()>
        <#return base + "/oauth2/start?rd=" + (base + "/")?url("UTF-8") + "&kc_action=UPDATE_EMAIL">
    <#else>
        <#return "">
    </#if>
</#function>
