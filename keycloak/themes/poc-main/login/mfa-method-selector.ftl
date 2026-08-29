<#import "template.ftl" as layout>
<@layout.registrationLayout displayMessage=!messagesPerField.existsError('mfa_method'); section>
  <#if section = "header">
    Choose verification method
  <#elseif section = "form">
    <form id="kc-mfa-method-selector-form" action="${url.loginAction}" method="post">
      <div class="poc-mfa-intro">Choose how you want to verify this sign-in.</div>

      <label class="poc-mfa-option" for="mfa-email">
        <input id="mfa-email" type="radio" name="mfa_method" value="email" checked />
        <span>
          <strong>Email OTP</strong>
          <small>Send a one-time code to your verified email address.</small>
        </span>
      </label>

      <div class="poc-mfa-option poc-mfa-disabled" aria-disabled="true">
        <input type="radio" disabled />
        <span>
          <strong>Authenticator App</strong>
          <small>Not enabled in this PoC yet.</small>
        </span>
      </div>

      <div class="poc-mfa-option poc-mfa-disabled" aria-disabled="true">
        <input type="radio" disabled />
        <span>
          <strong>Passkey / WebAuthn</strong>
          <small>Not enabled in this PoC yet.</small>
        </span>
      </div>

      <div class="poc-mfa-actions">
        <input class="pf-c-button pf-m-primary pf-m-block btn-lg" type="submit" value="Continue" />
      </div>
    </form>
  </#if>
</@layout.registrationLayout>
