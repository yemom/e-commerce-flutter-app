# Firebase Email OTP Setup

The app now writes 4-digit verification emails to the Firestore `mail` collection and stores active codes in `auth_verification_codes`.

To actually send the email, install the Firebase Extension `Trigger Email` on the same Firebase project.

## Required Firebase Extension

Install:

- `firebase/firestore-send-email`

Recommended collection settings:

- Mail collection: `mail`
- Use your SMTP provider or email service credentials during extension setup.

## Email Content

The app writes documents in this shape:

```json
{
  "to": ["user@example.com"],
  "message": {
    "subject": "Your Gulit verification code",
    "text": "Your Gulit verification code is 1234. It expires in 10 minutes.",
    "html": "<p>Your Gulit verification code is <strong>1234</strong>.</p><p>It expires in 10 minutes.</p>"
  }
}
```

## Verification Code Storage

The app stores the active code here:

- Collection: `auth_verification_codes`
- Document ID: Firebase Auth user id

Fields:

- `userId`
- `email`
- `code`
- `expiresAt`
- `createdAt`

## Important

Without the Trigger Email extension or an equivalent backend email sender, Firebase will not send the 4-digit code email. The app side is ready, but delivery depends on that backend service.
