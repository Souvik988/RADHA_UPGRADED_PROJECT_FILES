# Phase BE-07: Admin Authentication & Session Management

## Phase Metadata

- **Phase ID**: BE-07
- **Phase Name**: Admin Authentication & Session Management
- **Section**: Backend Execution — Security & Identity Layer
- **Depends On**: BE-01 to BE-06
- **Blocks**: BE-08, BE-09, admin panel features
- **Estimated Duration**: 2 days
- **Complexity**: Medium

## Goal

Implement email/password authentication for admin users with: secure password hashing (bcrypt cost 12), password complexity policy, password reset flow, email verification, account locking, password history, MFA preparation hooks, and admin invitation system.

## Why This Phase Matters

While retail users (Owner/Manager/Staff/Auditor) authenticate via OTP, **admin users need email/password** for:
- RADHA platform owner dashboard access
- Customer support workflows  
- Audit and compliance access
- Headless API access for integrations

Without proper admin auth:
- No way to access admin features
- Password security risks (weak hashing, no policy)
- Account compromise from password reuse
- No password recovery mechanism
- No audit trail for admin actions

## Prerequisites

- [ ] BE-06 completed: OTP auth working
- [ ] Users table exists with role enum
- [ ] Email service ready (or mock)
- [ ] JWT service ready

## Files to Create

| File Path | Purpose |
|---|---|
| `server/src/db/schema/admin_invitations.ts` | Admin invitation tracking |
| `server/src/db/schema/password_reset_tokens.ts` | Password reset tokens |
| `server/src/db/schema/email_verification_tokens.ts` | Email verification |
| `server/src/db/schema/password_history.ts` | Prevent password reuse |
| `server/src/modules/auth/services/password.service.ts` | Password hashing/policy |
| `server/src/modules/auth/services/password-reset.service.ts` | Reset flow |
| `server/src/modules/auth/services/email-verification.service.ts` | Email verification |
| `server/src/modules/auth/services/admin-invitation.service.ts` | Admin invitations |
| `server/src/modules/auth/repositories/admin-invitations.repository.ts` | Invitation data |
| `server/src/modules/auth/repositories/password-reset.repository.ts` | Reset tokens |
| `server/src/modules/auth/repositories/email-verification.repository.ts` | Email tokens |
| `server/src/modules/auth/repositories/password-history.repository.ts` | Password history |
| `server/src/modules/auth/dto/admin-login.dto.ts` | Admin login DTO |
| `server/src/modules/auth/dto/password-reset.dto.ts` | Reset DTOs |
| `server/src/modules/auth/dto/email-verification.dto.ts` | Email verify DTOs |
| `server/src/modules/auth/dto/admin-invitation.dto.ts` | Invitation DTOs |
| `server/src/modules/auth/dto/change-password.dto.ts` | Change password |
| `server/src/modules/auth/utils/password.utils.ts` | Password utilities |
| `server/src/integrations/email/email.module.ts` | Email module |
| `server/src/integrations/email/email.service.ts` | Email abstraction |
| `server/src/integrations/email/providers/ses.provider.ts` | AWS SES |
| `server/src/integrations/email/providers/mock.provider.ts` | Mock for dev |
| `server/src/integrations/email/templates/` | Email HTML templates |
| All `__tests__/` files |

## Service Interfaces

```typescript
// server/src/modules/auth/services/password.service.ts

export interface IPasswordService {
  hash(plainPassword: string): Promise<string>;
  verify(plainPassword: string, hash: string): Promise<boolean>;
  validatePolicy(password: string): PasswordValidationResult;
  generateRandom(length?: number): string;
  isInHistory(userId: string, password: string): Promise<boolean>;
  saveToHistory(userId: string, hash: string): Promise<void>;
}

export interface PasswordValidationResult {
  valid: boolean;
  errors: string[];
  strength: 'weak' | 'medium' | 'strong' | 'very-strong';
  score: number; // 0-100
}

// server/src/modules/auth/services/password-reset.service.ts

export interface IPasswordResetService {
  requestReset(email: string, ipAddress: string): Promise<void>;
  validateToken(token: string): Promise<{ userId: string; email: string }>;
  completeReset(token: string, newPassword: string, ipAddress: string): Promise<void>;
  revokeAllTokensForUser(userId: string): Promise<void>;
}

// server/src/modules/auth/services/admin-invitation.service.ts

export interface IAdminInvitationService {
  invite(dto: InviteAdminDto, invitedBy: string): Promise<AdminInvitation>;
  acceptInvitation(token: string, dto: AcceptInvitationDto): Promise<AuthResult>;
  resend(invitationId: string): Promise<void>;
  revoke(invitationId: string, revokedBy: string): Promise<void>;
  list(filters: ListInvitationsFilter): Promise<PaginatedResult<AdminInvitation>>;
}

// server/src/integrations/email/email.service.ts

export interface IEmailService {
  send(params: SendEmailParams): Promise<EmailResult>;
  sendTemplate<T extends EmailTemplate>(
    template: T,
    to: string,
    data: EmailTemplateData[T],
  ): Promise<EmailResult>;
}

export type EmailTemplate =
  | 'password-reset'
  | 'email-verification'
  | 'admin-invitation'
  | 'login-alert'
  | 'account-locked';

export interface EmailTemplateData {
  'password-reset': { name: string; resetLink: string; expiresIn: string };
  'email-verification': { name: string; verifyLink: string };
  'admin-invitation': { inviterName: string; acceptLink: string; tenantName: string };
  'login-alert': { name: string; ipAddress: string; deviceInfo: string; loginTime: string };
  'account-locked': { name: string; unlockAt: string; reason: string };
}
```

## Implementation Code

### 1. Password Service

```typescript
// server/src/modules/auth/services/password.service.ts
import { Injectable, Logger } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';
import { ConfigService } from '../../../config/config.service';
import { PasswordHistoryRepository } from '../repositories/password-history.repository';
import {
  IPasswordService,
  PasswordValidationResult,
} from '../types/password.types';

@Injectable()
export class PasswordService implements IPasswordService {
  private readonly logger = new Logger(PasswordService.name);
  private readonly BCRYPT_ROUNDS = 12;
  private readonly MIN_LENGTH = 12;
  private readonly MAX_LENGTH = 128;
  private readonly HISTORY_SIZE = 5;

  constructor(
    private readonly config: ConfigService,
    private readonly historyRepo: PasswordHistoryRepository,
  ) {}

  async hash(plainPassword: string): Promise<string> {
    return bcrypt.hash(plainPassword, this.BCRYPT_ROUNDS);
  }

  async verify(plainPassword: string, hash: string): Promise<boolean> {
    try {
      return await bcrypt.compare(plainPassword, hash);
    } catch {
      return false;
    }
  }

  validatePolicy(password: string): PasswordValidationResult {
    const errors: string[] = [];
    let score = 0;

    // Length check
    if (password.length < this.MIN_LENGTH) {
      errors.push(`Password must be at least ${this.MIN_LENGTH} characters`);
    } else {
      score += 20;
      if (password.length >= 16) score += 10;
      if (password.length >= 20) score += 10;
    }

    if (password.length > this.MAX_LENGTH) {
      errors.push(`Password must not exceed ${this.MAX_LENGTH} characters`);
    }

    // Complexity checks
    const hasLowercase = /[a-z]/.test(password);
    const hasUppercase = /[A-Z]/.test(password);
    const hasDigit = /\d/.test(password);
    const hasSpecial = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password);

    if (!hasLowercase) errors.push('Must contain lowercase letter');
    else score += 15;
    
    if (!hasUppercase) errors.push('Must contain uppercase letter');
    else score += 15;
    
    if (!hasDigit) errors.push('Must contain number');
    else score += 15;
    
    if (!hasSpecial) errors.push('Must contain special character');
    else score += 15;

    // Common password check
    if (this.isCommonPassword(password)) {
      errors.push('Password is too common');
      score = Math.max(0, score - 30);
    }

    // Entropy bonus
    const uniqueChars = new Set(password).size;
    if (uniqueChars >= 8) score += 5;
    if (uniqueChars >= 12) score += 5;

    // Determine strength
    let strength: PasswordValidationResult['strength'];
    if (score < 40) strength = 'weak';
    else if (score < 60) strength = 'medium';
    else if (score < 80) strength = 'strong';
    else strength = 'very-strong';

    return {
      valid: errors.length === 0,
      errors,
      strength,
      score: Math.min(100, score),
    };
  }

  generateRandom(length: number = 16): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
    const bytes = randomBytes(length);
    let result = '';
    for (let i = 0; i < length; i++) {
      result += chars[bytes[i] % chars.length];
    }
    return result;
  }

  async isInHistory(userId: string, password: string): Promise<boolean> {
    const history = await this.historyRepo.findRecentForUser(userId, this.HISTORY_SIZE);
    
    for (const entry of history) {
      const matches = await this.verify(password, entry.passwordHash);
      if (matches) return true;
    }
    
    return false;
  }

  async saveToHistory(userId: string, hash: string): Promise<void> {
    await this.historyRepo.create({ userId, passwordHash: hash });
    
    // Cleanup old entries (keep only last N)
    await this.historyRepo.deleteOldForUser(userId, this.HISTORY_SIZE);
  }

  private isCommonPassword(password: string): boolean {
    const common = new Set([
      'password', 'password123', '123456', '12345678', 'qwerty',
      'abc123', 'letmein', 'admin', 'welcome', 'monkey',
      'password1', 'password!', 'admin@123', 'india@123',
    ]);
    return common.has(password.toLowerCase());
  }
}
```

### 2. Password DTOs

```typescript
// server/src/modules/auth/dto/admin-login.dto.ts
import { z } from 'zod';

export const AdminLoginSchema = z.object({
  email: z.string().email('Invalid email').toLowerCase(),
  password: z.string().min(1, 'Password required').max(128),
  deviceId: z.string().max(255).optional(),
});

export type AdminLoginDto = z.infer<typeof AdminLoginSchema>;
```

```typescript
// server/src/modules/auth/dto/password-reset.dto.ts
import { z } from 'zod';

export const RequestPasswordResetSchema = z.object({
  email: z.string().email('Invalid email').toLowerCase(),
});

export const CompletePasswordResetSchema = z.object({
  token: z.string().min(32, 'Invalid reset token'),
  newPassword: z.string()
    .min(12, 'Password must be at least 12 characters')
    .max(128, 'Password too long'),
});

export const ChangePasswordSchema = z.object({
  currentPassword: z.string().min(1).max(128),
  newPassword: z.string().min(12).max(128),
}).refine(data => data.currentPassword !== data.newPassword, {
  message: 'New password must be different from current',
  path: ['newPassword'],
});

export type RequestPasswordResetDto = z.infer<typeof RequestPasswordResetSchema>;
export type CompletePasswordResetDto = z.infer<typeof CompletePasswordResetSchema>;
export type ChangePasswordDto = z.infer<typeof ChangePasswordSchema>;
```

### 3. Email Service

```typescript
// server/src/integrations/email/email.service.ts
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '../../config/config.service';
import {
  IEmailService,
  SendEmailParams,
  EmailResult,
  EmailTemplate,
  EmailTemplateData,
} from './types/email.types';
import { SesProvider } from './providers/ses.provider';
import { MockEmailProvider } from './providers/mock.provider';

@Injectable()
export class EmailService implements IEmailService {
  private readonly logger = new Logger(EmailService.name);
  private provider: IEmailService;

  constructor(
    private readonly config: ConfigService,
    private readonly ses: SesProvider,
    private readonly mock: MockEmailProvider,
  ) {
    const providerName = this.config.get<string>('EMAIL_PROVIDER') || 'mock';
    this.provider = providerName === 'ses' ? this.ses : this.mock;
    this.logger.log(`Email provider: ${providerName}`);
  }

  async send(params: SendEmailParams): Promise<EmailResult> {
    return this.provider.send(params);
  }

  async sendTemplate<T extends EmailTemplate>(
    template: T,
    to: string,
    data: EmailTemplateData[T],
  ): Promise<EmailResult> {
    const html = await this.renderTemplate(template, data);
    const subject = this.getSubject(template);

    return this.send({ to, subject, html });
  }

  private async renderTemplate<T extends EmailTemplate>(
    template: T,
    data: EmailTemplateData[T],
  ): Promise<string> {
    // In production, use a templating engine (Handlebars, EJS)
    const templates: Record<EmailTemplate, (data: any) => string> = {
      'password-reset': (d) => `
        <h1>Reset Your Password</h1>
        <p>Hi ${d.name},</p>
        <p>You requested a password reset. Click the link below:</p>
        <a href="${d.resetLink}">Reset Password</a>
        <p>Link expires in ${d.expiresIn}.</p>
      `,
      'email-verification': (d) => `
        <h1>Verify Your Email</h1>
        <p>Hi ${d.name},</p>
        <a href="${d.verifyLink}">Verify Email</a>
      `,
      'admin-invitation': (d) => `
        <h1>You're Invited to RADHA</h1>
        <p>${d.inviterName} invited you to ${d.tenantName}</p>
        <a href="${d.acceptLink}">Accept Invitation</a>
      `,
      'login-alert': (d) => `
        <h1>New Login Detected</h1>
        <p>Hi ${d.name},</p>
        <p>New login from IP: ${d.ipAddress}</p>
        <p>Device: ${d.deviceInfo}</p>
        <p>Time: ${d.loginTime}</p>
      `,
      'account-locked': (d) => `
        <h1>Account Locked</h1>
        <p>Hi ${d.name},</p>
        <p>Your account is locked due to ${d.reason}.</p>
        <p>Unlocks at: ${d.unlockAt}</p>
      `,
    };

    return templates[template](data);
  }

  private getSubject(template: EmailTemplate): string {
    const subjects: Record<EmailTemplate, string> = {
      'password-reset': 'RADHA — Password Reset Request',
      'email-verification': 'RADHA — Verify Your Email',
      'admin-invitation': 'RADHA — You\'re Invited',
      'login-alert': 'RADHA — New Login Detected',
      'account-locked': 'RADHA — Account Locked',
    };
    return subjects[template];
  }
}
```

## Database Tables Affected

| Table | Created/Modified | Purpose |
|---|---|---|
| `users` | MODIFIED | Add `password_hash`, `email_verified` columns |
| `admin_invitations` | CREATED | Track admin invitations |
| `password_reset_tokens` | CREATED | Reset token storage |
| `email_verification_tokens` | CREATED | Email verification |
| `password_history` | CREATED | Prevent password reuse |

## API Endpoints

| Method | Endpoint | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/auth/admin/login` | Public | Email/password login |
| POST | `/api/v1/auth/password/reset/request` | Public | Request reset email |
| POST | `/api/v1/auth/password/reset/complete` | Public | Complete reset |
| POST | `/api/v1/auth/password/change` | Bearer | Change password |
| POST | `/api/v1/auth/email/verify` | Public | Verify email |
| POST | `/api/v1/auth/email/verify/resend` | Bearer | Resend verification |
| POST | `/api/v1/auth/admin/invitations` | Bearer | Invite admin |
| GET | `/api/v1/auth/admin/invitations` | Bearer | List invitations |
| POST | `/api/v1/auth/admin/invitations/:token/accept` | Public | Accept invitation |
| POST | `/api/v1/auth/admin/invitations/:id/resend` | Bearer | Resend invitation |
| DELETE | `/api/v1/auth/admin/invitations/:id` | Bearer | Revoke invitation |

---

# 🧪 TESTING INSTRUCTIONS & Q&A SESSION (SOP CHECKPOINT)

## ⚠️ STOP — Do Not Proceed to BE-08 Until This Section is Complete

## 🧪 Test Procedures

### Test 1: Admin Login Happy Path ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@radha.com","password":"AdminPass@123!"}'
```

**Expected**: Returns access + refresh tokens
**Pass Criteria**: ✅ Login works for valid credentials

---

### Test 2: Wrong Password ✅

```bash
curl -X POST http://localhost:3000/api/v1/auth/admin/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@radha.com","password":"WrongPassword"}'
```

**Expected**: 401 with `INVALID_CREDENTIALS`
**Pass Criteria**: ✅ Wrong password rejected

---

### Test 3: Password Policy Enforcement ✅

Try weak passwords:
```bash
# Too short
curl -X POST .../admin/register \
  -d '{"password":"short"}'

# No uppercase
curl -X POST .../admin/register \
  -d '{"password":"alllowercase123!"}'

# No special char
curl -X POST .../admin/register \
  -d '{"password":"NoSpecialChar123"}'

# Common password
curl -X POST .../admin/register \
  -d '{"password":"password123"}'
```

**Expected**: All return 400 with detailed error messages
**Pass Criteria**: ✅ Weak passwords rejected

---

### Test 4: Account Lockout ✅

Make 5 failed login attempts in succession:
**Expected**: 6th attempt returns `ACCOUNT_LOCKED`
**Verification**: Check `users.locked_until` is set
**Pass Criteria**: ✅ Account locks after threshold

---

### Test 5: Password Reset Flow ✅

```bash
# Step 1: Request reset
curl -X POST http://localhost:3000/api/v1/auth/password/reset/request \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@radha.com"}'

# Expected: 200 (always, even if email doesn't exist - prevents enumeration)
# Get token from mock email logs

# Step 2: Complete reset
curl -X POST http://localhost:3000/api/v1/auth/password/reset/complete \
  -H "Content-Type: application/json" \
  -d '{"token":"<token>","newPassword":"NewSecure@Pass123!"}'
```

**Expected**: 200 success, can login with new password
**Pass Criteria**: ✅ Reset flow works end-to-end

---

### Test 6: Email Enumeration Prevention ✅

```bash
# Existing email
curl ... -d '{"email":"exists@test.com"}'
# Time: 250ms

# Non-existent email
curl ... -d '{"email":"doesntexist@test.com"}'
# Time: 250ms (should be same)
```

**Expected**: Same response and timing for both
**Pass Criteria**: ✅ Cannot enumerate emails

---

### Test 7: Password History ✅

1. Set password to "Pass1@RADHA"
2. Change to "Pass2@RADHA" 
3. Change to "Pass3@RADHA"
4. Try to change back to "Pass1@RADHA"

**Expected**: Step 4 fails with "Password recently used"
**Pass Criteria**: ✅ Last 5 passwords blocked

---

### Test 8: Email Verification ✅

```bash
# Verify with valid token
curl -X POST http://localhost:3000/api/v1/auth/email/verify \
  -H "Content-Type: application/json" \
  -d '{"token":"<from-email>"}'
```

**Expected**: 200, `users.email_verified` set to true
**Pass Criteria**: ✅ Email verification works

---

### Test 9: Admin Invitation ✅

```bash
# Send invitation
curl -X POST http://localhost:3000/api/v1/auth/admin/invitations \
  -H "Authorization: Bearer <admin-token>" \
  -d '{"email":"newadmin@test.com","role":"admin"}'

# Accept invitation
curl -X POST http://localhost:3000/api/v1/auth/admin/invitations/<token>/accept \
  -d '{"name":"New Admin","password":"Secure@Pass123!"}'
```

**Expected**: Invitation flow creates new admin user
**Pass Criteria**: ✅ Invitation system works

---

### Test 10: Login Alert Email ✅

Login from unfamiliar IP:
**Expected**: Email sent to user about new login
**Pass Criteria**: ✅ Security alerts work

---

## 🎯 Q&A Session

### Q1: Why bcrypt cost 12 for passwords vs 10 for OTPs?

**Expected Answer**:
- Passwords are long-term credentials — need stronger protection
- OTPs are short-lived (10 min) — speed matters more
- Cost 12 = ~250ms hash, Cost 10 = ~100ms hash
- Trade-off: Login UX vs security
- 250ms login is acceptable, 1 second is not

---

### Q2: Why password history?

**Expected Answer**:
- Compliance requirement (some industries require)
- Prevents users from cycling through same passwords
- Reduces credential stuffing impact
- Standard: Last 5 passwords blocked
- Stored as hashes, never plain

---

### Q3: Why same response for "email exists" and "email doesn't exist"?

**Expected Answer**:
- Prevents email enumeration attacks
- Attacker can't determine which emails are registered
- Reduces phishing target list value
- Always log internally for monitoring
- Same response time prevents timing attacks

---

### Q4: How to prevent password reset token replay?

**Expected Answer**:
- Tokens are single-use (mark used after first use)
- Tokens have expiration (1 hour default)
- Tokens are random 32+ bytes (cryptographically secure)
- Tokens stored hashed in DB
- All tokens for user revoked after successful reset

---

### Q5: Why complex password policy?

**Expected Answer**:
- 12+ chars: Brute force impractical (10^21 combinations)
- Mixed case: Increases space
- Numbers: Prevents word-only passwords
- Special chars: Prevents simple substitutions
- Common password check: Prevents predictable choices
- Strength score: Helps users understand quality

---

### Q6: How does login alert detection work?

**Expected Answer**:
- Track typical IP/device/location for user
- New login from unknown source triggers alert
- Email sent immediately
- User can revoke session if not them
- Trade-off: Privacy (location data) vs security

---

## 📝 Sign-Off Checklist

### Functional
- [ ] Admin email/password login works
- [ ] Password policy enforced
- [ ] Password reset end-to-end works
- [ ] Email verification works
- [ ] Admin invitation works
- [ ] Account lockout works
- [ ] Password history prevents reuse

### Security
- [ ] bcrypt cost 12 for passwords
- [ ] No email enumeration
- [ ] No timing attacks
- [ ] Reset tokens single-use
- [ ] Reset tokens expire (1 hour)
- [ ] Login alerts for suspicious activity
- [ ] Password history (last 5)

### Tests
- [ ] All 10 tests pass
- [ ] Coverage > 85%

**Developer Signature**: ___________________________

## 👤 Reviewer Approval

**☐ APPROVED — Proceed to BE-08**
**☐ CHANGES REQUESTED**

**Reviewer Signature**: ___________________________

---

**END OF BE-07 — DO NOT PROCEED WITHOUT APPROVAL**
