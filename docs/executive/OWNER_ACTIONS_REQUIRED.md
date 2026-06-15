# RADHA — Owner Actions Required

> These items **cannot be completed by engineering alone**. Each blocks a specific release gate / score
> category. Provide the input and the program will complete the dependent work and upgrade the evidence.

| # | Action | Unblocks (scorecard) | Why only you can do it | How to provide |
|---|---|---|---|---|
| 1 | Provide **Razorpay TEST-mode** key id + secret (+ webhook secret) | I (payment), part of B | Credentials are account-bound; secrets stay server-side | Put in `server/.env` `RAZORPAY_KEY_ID/SECRET/WEBHOOK_SECRET`, or send them to be placed there |
| 2 | Provide an **Android device/emulator** (or authorize the agent to provision one) | F (android), part of B/I | Native plugin + camera/scan/OCR correctness needs real hardware; widget tests are not evidence | Start an emulator / plug in a device with `adb` visible |
| 3 | Authorize **AWS staging** account + budget | M (deploy/backup/restore), part of K/L | Financial provisioning + production-class infra is owner-owned | Confirm AWS account + a staging budget; agent uses the existing `DEPLOY_AWS.md` runbook |
| 4 | Approve **KMS** usage (real AWS KMS or an approved local stand-in) | J (privacy/encryption) | Key custody is an owner/security decision; key loss = data loss | Confirm KMS key + custody/rotation policy |
| 5 | **Legal/privacy review** of the data inventory, privacy notice, consent & retention (DPDP Act) | J / H | Engineering can implement but not certify legal sufficiency | Engage counsel; agent marks claims `LEGAL_REVIEW_REQUIRED` until cleared |
| 6 | Provide **store listing + data-safety declaration** inputs, support contact, privacy/terms URLs | release acceptance (§26) | Business/legal content owned by you | Send the listing copy + URLs |
| 7 | **Production** Razorpay + AWS production credentials + go-live approval | final release | Real-money + production custody is owner-only | Only when staging gates are green |
| 8 | Decide D3 dashboard `scope` field intent (is it a real feature?) | D | Product intent | One-line answer: yes (keep+wire) / no (remove) |

**Nothing above stops independent work** — the program continues on all non-blocked units and returns to
each item the moment you provide the input.
