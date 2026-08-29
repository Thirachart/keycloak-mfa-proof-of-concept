FROM maven:3.9.9-eclipse-temurin-21 AS extension-builder
WORKDIR /work
COPY extension/pom.xml ./pom.xml
COPY extension/src ./src
RUN mvn -q -DskipTests package

FROM quay.io/keycloak/keycloak:26.6.2

ADD --chown=keycloak:keycloak https://repo1.maven.org/maven2/io/github/mesutpiskin/keycloak-2fa-email-authenticator/26.4.3-KC26.6.2/keycloak-2fa-email-authenticator-26.4.3-KC26.6.2.jar /opt/keycloak/providers/keycloak-2fa-email-authenticator.jar
COPY --from=extension-builder --chown=keycloak:keycloak /work/target/poc-keycloak-extension.jar /opt/keycloak/providers/poc-keycloak-extension.jar
COPY --chown=keycloak:keycloak themes /opt/keycloak/themes

RUN /opt/keycloak/bin/kc.sh build
