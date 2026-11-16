---
title: "Profile and security"
description: "Profile and security | Kang"
---

Open your avatar menu and go to **Profile**. Account pages use their own sidebar: Profile, Preferences, and Security. **Back to workspace** returns to your working context. **Kang License** is a separate System page at `/license`.

## Update your details

Use the edit icons beside username, email, first name, or last name to open the field editor, enter a valid value, and save. Role, organization, and teams are access information; ask an authorized administrator to change them.

**Download My Data** downloads the current user record as JSON. It is not an export of every audit log, gateway configuration, or the whole Kang database. Review the file before sharing.

## Profile photo

Use the photo control to upload or replace an image, crop it, and save. Supported types are **PNG, JPEG, and WebP**, up to **5 MB**. Upload availability depends on the installation's configured media service. If upload fails, check the file format/size and contact the operator rather than putting a private image URL into unrelated fields.

A saved photo appears in the header and user list. Photo changes are self-service; the administrator user form does not offer an avatar editor. Use the photo's remove action if you no longer want it displayed.

## Change your password

Open **Security → Change Password**, fill the fields requested by the dialog, satisfy the displayed policy, and submit. Policies are configurable; the installation's actual form is authoritative. Never share your old or new password in a support message.

## Active sessions

Security shows account/password information and active sessions. Identify the current device, inspect unfamiliar sessions, and use **Revoke** or **Revoke All Other Sessions** as needed. Revoking sessions and changing your password serve different purposes; do both when appropriate for an account compromise.

The current Security page displays MFA status as **Not enabled**; it does not provide an MFA enrollment workflow. Do not assume MFA is enabled because the status label exists.
