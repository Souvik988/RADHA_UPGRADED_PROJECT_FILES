import { Injectable, Logger } from '@nestjs/common';

import { ConfigService } from '@/config/config.service';

import type { ISmsProvider, SmsResult } from '../sms.types';

interface Msg91Response {
  type?: string;
  message?: string;
  request_id?: string;
}

/**
 * MSG91 OTP provider.
 *
 * Production-only. Mobile numbers are normalised to E.164 (`91XXXXXXXXXX`)
 * before posting because MSG91 rejects leading zeros and `+91`-prefix
 * forms inconsistently across templates.
 */
@Injectable()
export class Msg91SmsProvider implements ISmsProvider {
  private readonly logger = new Logger(Msg91SmsProvider.name);
  private readonly otpUrl = 'https://control.msg91.com/api/v5/otp';

  constructor(private readonly config: ConfigService) {}

  async sendOtp(mobile: string, otp: string): Promise<SmsResult> {
    const sms = this.config.sms;

    // Dev-safety guard: if the MSG91 credentials are obviously dev placeholders
    // (template id "dev-mock" or api key blank/"dev-mock"), short-circuit with a
    // logged success so local OTP flows work without a real MSG91 account. This
    // never runs in production because env.schema.ts rejects placeholder values
    // when NODE_ENV=production.
    const looksDevPlaceholder =
      !sms.apiKey ||
      sms.apiKey === 'dev-mock' ||
      sms.apiKey.startsWith('dev-') ||
      sms.templateId === 'dev-mock' ||
      sms.templateId.startsWith('dev-');

    if (looksDevPlaceholder) {
      this.logger.warn(`[MSG91 DEV-SHORTCIRCUIT] OTP for ${mobile}: ${otp}`);
      return { success: true, messageId: `dev-shortcircuit-${Date.now()}`, provider: 'msg91' };
    }

    const e164 = this.toE164(mobile);

    try {
      const res = await fetch(this.otpUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          authkey: sms.apiKey,
        },
        body: JSON.stringify({
          template_id: sms.templateId,
          mobile: e164,
          otp,
          sender: sms.senderId,
        }),
      });

      const body: Msg91Response = (await res.json()) as Msg91Response;
      if (res.ok && body.type === 'success') {
        return { success: true, messageId: body.request_id, provider: 'msg91' };
      }
      const message = body.message ?? `MSG91 returned status ${res.status}`;
      this.logger.warn('msg91.send.failed', { status: res.status, message });
      return { success: false, provider: 'msg91', error: message };
    } catch (err) {
      const message = err instanceof Error ? err.message : 'unknown';
      this.logger.error('msg91.send.network_error', { message });
      return { success: false, provider: 'msg91', error: message };
    }
  }

  async sendNotification(_mobile: string, _message: string): Promise<SmsResult> {
    // BE-24 (Notifications) extends to MSG91 transactional endpoints.
    return {
      success: false,
      provider: 'msg91',
      error: 'sendNotification not implemented in BE-06',
    };
  }

  private toE164(mobile: string): string {
    const digits = mobile.replace(/\D/g, '');
    if (digits.length === 10) return `91${digits}`;
    if (digits.length === 12 && digits.startsWith('91')) return digits;
    if (digits.length === 11 && digits.startsWith('0')) return `91${digits.slice(1)}`;
    throw new Error(`Cannot normalise mobile to E.164: ${mobile}`);
  }
}
