# Tutorial

Before anything, make sure you have docker and compose plugin:

- Docker: <https://docs.docker.com/engine/install/ubuntu/#installation-methods>
- Compose plugin: <https://docs.docker.com/compose/install/linux/>

## Flows

By now we are not sending email and sms (all providers charge for this service). Therefore we must be content with kafka hosted on port 9000 or by see the logs from notification service container.

### Create a user, create an invoice and list both

1. Execute the command `make start` wait until all containers be avaliable. This may take a while.
2. Access your browser on <http://localhost:5003>
3. In the login page you can access with: email=admin@authplus.com and password=7061651770d7b3ad8fa96e7a8bc61447
4. On page <http://localhost:5003/users> there is a button with a plus symbol, click and create a new user (write somewhere the email and password created)
5. Logout (button header right side)
6. Login again but with your recently created user
7. On page <http://localhost:5003/users> you can see your id (write somewhere)
8. Execute code below, but replacing the id for the one you just note it

```bash
curl --location --request POST 'http://localhost:5002/invoice' \
--header 'Content-Type: application/json' \
--data-raw '{
    "external_user_id": "<id-of-your-user>",
    "itens": [
        {
            "description": "cccccc",
            "quantity": 1,
            "amount": 2.78,
            "currency": "BRL"
        }
    ]
}'
```

9. On page <http://localhost:5003/invoices> you can se you newly invocie created

Observation: the user you used on step 3 is admin and therefore he can't have invoice. Tha

### Create a multi factor authentication and use to login (EMAIL)

Step 3 and 7 need to be execute in another tab navigation
Step 4 can be executed on terminal

1. On page <http://localhost:5003/mfa> there is three are squares, each one with a type on authentication
2. Click on square EMAIL
3. Access <http://localhost:9000>
    1. click on topic `2FA_EMAIL_CREATED`, you'll redirect to <http://localhost:9000/topic/2FA_EMAIL_CREATED>
    2. click on "View Messages" button, you'll be redirect to <http://localhost:9000/topic/2FA_EMAIL_CREATED/messages>
    3. click on "View Messages" button
    4. You'll see a json that contains attributes email and content, Copy the value of the key **content**
4. Execute code below, but replacing the hash for the one you just copy it

```bash
curl --location --request POST 'http://localhost:5000/mfa/validate' \
--header 'Content-Type: application/json' \
--data-raw '{
    "id": "<the-hash-you-just-copy-from kafka>"
}'
```

5. Logout (button header right side)
6. Login again, but now you'll see that you have to choose one option. Select `EMAIL`
7. Access <http://localhost:9000>
    1. click on topic `2FA_EMAIL_SENT`, you'll redirect to <http://localhost:9000/topic/2FA_EMAIL_SENT>
    2. click on "View Messages" button, you'll be redirect to <http://localhost:9000/topic/2FA_EMAIL_SENT/messages>
    3. click on "View Messages" button
    4. You'll see a json that contains attributes email and code, Copy the value of the key **code**
8. Paste the code you just copied on form and login

### Create a multi factor authentication and use to login (GOOGLE AUTHENTICATOR)

Before starting this part it's recommended that you have an app that can read QRcode with TOTP algorithm [GoogleAuthenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2)

1. On page <http://localhost:5003/mfa> there is three are squares, each one with a type on authentication
2. Click on square GA
3. Open you smartphone app and point to the QRcode
4. Logout (button header right side)
5. Login again, but now you'll see that you have to choose one option. Select `GOOGLE_AUTHENTICATOR`
6. Insert the code that is in your app

### Create a multi factor authentication and use to login (PHONE)

Before starting this part it necessary that your user have a telephone information, you can do this by executing code below. How to get each info:

- jwt-token: access your sessionStorage there key `token`
- your-user-id: on page User you can see

```bash
curl --location --request PATCH 'http://localhost:5000/user' \
--header 'Content-Type: application/json' \
--header 'Authorization: Bearer <jwt-token> \
--data-raw '{
    "userId": "<your-user-id>",
    "phone": "<any-telephone>"
}'
```

1. On page <http://localhost:5003/mfa> there is three are squares, each one with a type on authentication
2. Click on square PHONE
3. Access <http://localhost:9000>
    1. click on topic `2FA_PHONE_CREATED`, you'll redirect to <http://localhost:9000/topic/2FA_PHONE_CREATED>
    2. click on "View Messages" button, you'll be redirect to <http://localhost:9000/topic/2FA_PHONE_CREATED/messages>
    3. click on "View Messages" button
    4. You'll see a json that contains attributes email and content, Copy the value of the key **content**
4. Execute code below, but replacing the hash for the one you just copy it

```bash
curl --location --request POST 'http://localhost:5000/mfa/validate' \
--header 'Content-Type: application/json' \
--data-raw '{
    "id": "<the-hash-you-just-copy-from kafka>"
}'
```

5. Logout (button header right side)
6. Login again, but now you'll see that you have to choose one option. Select `PHONE`
7. Access <http://localhost:9000>
    1. click on topic `2FA_PHONE_SENT`, you'll redirect to <http://localhost:9000/topic/2FA_PHONE_SENT>
    2. click on "View Messages" button, you'll be redirect to <http://localhost:9000/topic/2FA_PHONE_SENT/messages>
    3. click on "View Messages" button
    4. You'll see a json that contains attributes email and code, Copy the value of the key **code**
8. Paste the code you just copied on form and login
