# Dynamic Authentication in SAP CAPM

## Overview

This document explains how to implement **Dynamic Authentication** in an SAP CAPM application where different external systems may use different authentication mechanisms.

The CAPM application is secured using an **SAP XSUAA instance**, while some external systems may only support **Basic Authentication**.

The objective is to allow the CAPM application to handle both:

* **OAuth 2.0 / XSUAA authentication**
* **Basic Authentication for specific endpoints**

The application dynamically identifies the authentication method and, when required, exchanges valid Basic Authentication credentials for an XSUAA access token before allowing the request to continue to the CAPM service.

---

# 1. Authentication Architecture

The application uses the following authentication architecture:

```text
                    External Systems
                           |
             +-------------+-------------+
             |                           |
       OAuth 2.0 / XSUAA          Basic Authentication
             |                           |
             |                           |
             +-------------+-------------+
                           |
                           v
                  SAP CAPM Application
                           |
                    Authentication
                     Middleware
                           |
              +------------+------------+
              |                         |
         Bearer Token              Basic Credentials
              |                         |
              |                  Validate Credentials
              |                         |
              |                  Generate XSUAA
              |                  Client Credentials Token
              |                         |
              +------------+------------+
                           |
                           v
                    CAPM Service
                           |
                           v
                    Protected Endpoint
```

The important concept is that **Basic Authentication is not directly used by the CAPM service**.

Instead, the middleware can convert valid Basic Authentication credentials into an **XSUAA Bearer Token**.

---

# 2. XSUAA Instance

The CAPM application contains an **XSUAA service instance**.

The XSUAA service provides OAuth 2.0 capabilities and is responsible for issuing access tokens.

The XSUAA credentials generally contain:

* Client ID
* Client Secret
* XSUAA URL

These credentials are used by the CAPM application when it needs to obtain an access token.

---

# 3. OAuth 2.0 Client Credentials Flow

The **Client Credentials Grant** is generally used for server-to-server communication.

There is no end-user involved in this flow.

### Configuration

| Property              | Value                                   |
| --------------------- | --------------------------------------- |
| Grant Type            | Client Credentials                      |
| Client ID             | XSUAA Client ID                         |
| Client Secret         | XSUAA Client Secret                     |
| API Token URL         | XSUAA Token URL                         |
| Client Authentication | Send Client Credentials in Request Body |

### Flow

```text
External System / CAPM Application
              |
              | Client ID + Client Secret
              | grant_type=client_credentials
              v
          XSUAA Token Endpoint
              |
              | Access Token
              v
       CAPM Protected API
```

### Step-by-step

1. The client sends a request to the XSUAA token endpoint.
2. The request contains:

   * Client ID
   * Client Secret
   * `grant_type=client_credentials`
3. XSUAA validates the client credentials.
4. XSUAA generates an access token.
5. The client uses the access token in subsequent API requests.

The API request is then sent using:

```text
Authorization: Bearer <access_token>
```

---

# 4. OAuth 2.0 User Token Exchange / Authorization Code

For scenarios involving an authenticated user, an OAuth 2.0 **Authorization Code** flow can be used.

### Configuration

| Property              | Value                                        |
| --------------------- | -------------------------------------------- |
| Grant Type            | Authorization Code                           |
| Callback URL          | SAP Business Application Studio callback URL |
| Authorization URL     | `<XSUAA URL>/oauth/authorize`                |
| Access Token URL      | `<XSUAA URL>/oauth/token`                    |
| Client ID             | XSUAA Client ID                              |
| Client Secret         | XSUAA Client Secret                          |
| Client Authentication | Send Client Credentials in Request Body      |

### Flow

```text
User
 |
 | 1. Login
 v
XSUAA Authorization Endpoint
 |
 | 2. Authorization
 v
Application Callback URL
 |
 | 3. Authorization Code
 v
Application
 |
 | 4. Code + Client Credentials
 v
XSUAA Token Endpoint
 |
 | 5. Access Token
 v
CAPM Application
```

The Authorization Code flow is different from Client Credentials because it involves a **user authorization context**.

---

# 5. Why Dynamic Authentication Is Required

Consider the following situation.

An external enterprise system needs to call a CAPM API.

The external system supports:

```text
Basic Authentication
```

However, the CAPM application is configured with:

```text
SAP XSUAA
```

and normally expects:

```text
Authorization: Bearer <XSUAA Access Token>
```

The external system may not have the capability to generate an XSUAA OAuth token.

Therefore, a middleware layer can be introduced.

### Without Dynamic Authentication

```text
External System
     |
     | Basic Authentication
     v
CAPM Application
     |
     X
Bearer Token Expected
```

The request cannot be authenticated by the normal XSUAA security mechanism.

### With Dynamic Authentication

```text
External System
     |
     | Basic Authentication
     v
CAPM Authentication Middleware
     |
     | Validate Basic Credentials
     v
XSUAA Token Endpoint
     |
     | Client Credentials
     v
XSUAA
     |
     | Access Token
     v
CAPM Application
     |
     v
Protected Endpoint
```

This allows the external system to continue using Basic Authentication while the CAPM application internally works with XSUAA.

---

# 6. Dynamic Authentication Concept

Dynamic Authentication means that the application can process different authentication mechanisms depending on the incoming request.

For example:

```text
Request
   |
   v
Check Endpoint
   |
   +---- Normal Endpoint
   |        |
   |        +--> XSUAA Authentication
   |
   +---- AdminConfigurations
            |
            +--> Basic Authentication
                    |
                    +--> Validate Credentials
                            |
                            +--> Generate XSUAA Token
                                    |
                                    +--> Continue Request
```

The authentication middleware is placed before the CAPM service processing.

---

# 7. Endpoint-Specific Authentication

Dynamic authentication should generally be restricted to the endpoints that actually require it.

For example:

```text
/odata/v4/catalog/Employees
```

may continue to use the standard XSUAA authentication.

Whereas:

```text
/odata/v4/catalog/AdminConfigurations
```

can support Basic Authentication.

This gives the application a model such as:

| Endpoint            | Authentication       |
| ------------------- | -------------------- |
| Employee APIs       | XSUAA Bearer Token   |
| Product APIs        | XSUAA Bearer Token   |
| AdminConfigurations | Basic Authentication |
| Other APIs          | XSUAA Bearer Token   |

This is preferable to globally bypassing XSUAA security.

---

# 8. Basic Authentication Flow

When an external system calls the configured endpoint using Basic Authentication:

```text
Authorization: Basic <Base64(username:password)>
```

the middleware performs the following process.

### Step 1 — Receive Request

The CAPM application receives the request.

### Step 2 — Identify Endpoint

The middleware checks whether the request belongs to the endpoint that supports Basic Authentication.

### Step 3 — Identify Authentication Type

The middleware checks the `Authorization` header.

If it contains:

```text
Basic
```

the request is treated as a Basic Authentication request.

### Step 4 — Validate Credentials

The username and password are validated against the credentials configured for the external integration.

### Step 5 — Reject Invalid Credentials

If the credentials are invalid, the application returns:

```text
401 Unauthorized
```

The request does not continue to the CAPM service.

### Step 6 — Generate XSUAA Token

If the Basic Authentication credentials are valid, the application uses its XSUAA service credentials to request an access token using the **Client Credentials** flow.

### Step 7 — Replace Authentication Context

The middleware changes the authentication context from:

```text
Basic Authentication
```

to:

```text
Bearer <XSUAA Access Token>
```

### Step 8 — Continue Request

The request continues to the CAPM application.

The CAPM service can therefore process the request using its normal XSUAA-based authorization model.

---

# 9. Authentication Transformation

The important concept is the transformation:

```text
External System
      |
      | Basic Authentication
      v
CAPM Middleware
      |
      | Validate credentials
      |
      | Client Credentials Flow
      v
XSUAA
      |
      | Access Token
      v
CAPM Service
```

Therefore:

```text
Basic Authentication
        ↓
Authentication Middleware
        ↓
XSUAA Client Credentials
        ↓
Bearer Token
        ↓
CAPM Authorization
```

The external system does not need to understand the internal XSUAA implementation.

---

# 10. Authentication Responsibilities

The architecture separates the responsibilities between the external system, middleware, XSUAA, and CAPM.

| Component          | Responsibility                                                 |
| ------------------ | -------------------------------------------------------------- |
| External System    | Sends Basic Authentication credentials                         |
| CAPM Middleware    | Detects and validates Basic Authentication                     |
| XSUAA              | Issues OAuth 2.0 access tokens                                 |
| CAPM Service       | Processes the authenticated request                            |
| CAPM Authorization | Determines whether the token is allowed to access the resource |

---

# 11. Security Considerations

Dynamic authentication introduces an additional authentication layer, so the implementation must be designed carefully.

## 11.1 Do Not Hardcode Credentials

Basic Authentication usernames and passwords should not be directly stored in application source code.

Instead, use a secure credential-management mechanism such as:

* Environment variables
* SAP BTP service bindings
* Destination service
* Secure credential stores
* Other approved secret-management mechanisms

---

## 11.2 Use HTTPS

Basic Authentication must only be transmitted over HTTPS.

The credentials are encoded using Base64, but Base64 is **not encryption**.

Therefore:

```text
Basic Authentication + HTTP
```

should not be used for production communication.

Use:

```text
Basic Authentication + HTTPS
```

---

## 11.3 Restrict Basic Authentication

Basic Authentication should not automatically be enabled for every CAPM endpoint.

Instead, configure it only for the required integration endpoints.

For example:

```text
/admin-configurations
```

rather than:

```text
/*
```

This reduces the authentication surface of the application.

---

## 11.4 Preserve XSUAA Authorization

Dynamic Basic Authentication should not become a mechanism for bypassing CAPM authorization.

The intended architecture is:

```text
Basic Authentication
        ↓
Validate External System
        ↓
XSUAA Token
        ↓
CAPM Authorization
        ↓
Business Operation
```

The XSUAA token should still be subject to the application's scopes and authorization rules.

---

# 12. Authentication Decision Flow

The overall decision process can be represented as:

```text
Incoming Request
       |
       v
Is this a Dynamic Authentication Endpoint?
       |
    +--+--+
    |     |
   No    Yes
    |     |
    |     v
    |   Check Authorization Header
    |     |
    |     +------------------+
    |     |                  |
    |   Basic              Bearer
    |     |                  |
    |     v                  v
    | Validate          Continue with
    | Credentials       XSUAA Token
    |     |
    |     v
    | Valid?
    |  +--+--+
    |  |     |
    | No     Yes
    |  |     |
    | 401     v
    |      Request XSUAA
    |      Client Credentials Token
    |          |
    |          v
    |      Obtain Access Token
    |          |
    |          v
    |      Continue Request
    |
    v
Normal XSUAA Authentication
```

---

# 13. Example Integration Scenario

### External System

The external system only supports:

```text
Username
Password
```

It sends:

```text
Basic Authentication
```

### CAPM Application

The CAPM application has:

```text
XSUAA Instance
```

and normally expects:

```text
Bearer Token
```

### Dynamic Authentication Layer

The middleware bridges the difference:

```text
External System
       |
       | Basic Authentication
       v
CAPM Middleware
       |
       | Validate credentials
       v
XSUAA
       |
       | Client Credentials
       v
Access Token
       |
       v
CAPM Service
```

This allows legacy or Basic-Authentication-only integrations to communicate with a CAPM application that is secured through XSUAA.

---

# 14. Client Credentials vs Authorization Code

| Feature                                   | Client Credentials                | Authorization Code                           |
| ----------------------------------------- | --------------------------------- | -------------------------------------------- |
| User involved                             | No                                | Yes                                          |
| Typical usage                             | Server-to-server                  | User-based authentication                    |
| Client ID                                 | Required                          | Required                                     |
| Client Secret                             | Required for confidential clients | Required for confidential clients            |
| Authorization Code                        | No                                | Yes                                          |
| Access Token                              | Yes                               | Yes                                          |
| Suitable for external backend integration | Yes                               | Usually not when no user context is required |
| XSUAA                                     | Yes                               | Yes                                          |

---

# 15. Overall Architecture

The complete architecture can be summarized as:

```text
                     ┌──────────────────────┐
                     │   External System    │
                     └──────────┬───────────┘
                                │
                         Basic Authentication
                                │
                                v
                     ┌──────────────────────┐
                     │   CAPM Application   │
                     │                      │
                     │ Dynamic Auth Layer   │
                     └──────────┬───────────┘
                                │
                         Validate Credentials
                                │
                                v
                     ┌──────────────────────┐
                     │       XSUAA          │
                     │                      │
                     │ Client Credentials   │
                     │      Grant           │
                     └──────────┬───────────┘
                                │
                           Access Token
                                │
                                v
                     ┌──────────────────────┐
                     │    CAPM Service      │
                     │                      │
                     │ XSUAA Authorization  │
                     └──────────┬───────────┘
                                │
                                v
                         Business Operation
```

---

# 16. Key Takeaway

The main purpose of Dynamic Authentication is to provide a **bridge between an external system that supports Basic Authentication and a CAPM application secured with SAP XSUAA**.

The external system can continue using:

```text
Basic Authentication
```

while the CAPM application internally uses:

```text
OAuth 2.0
      +
XSUAA
      +
Bearer Access Token
```

The complete authentication chain is:

```text
Basic Authentication
        ↓
Credential Validation
        ↓
XSUAA Client Credentials
        ↓
OAuth 2.0 Access Token
        ↓
CAPM Service
        ↓
XSUAA Authorization
        ↓
Business API
```

This approach allows authentication requirements of different integration partners to coexist while keeping the CAPM application's protected APIs under XSUAA-based authorization.
