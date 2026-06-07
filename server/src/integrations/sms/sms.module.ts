import { Global, Module } from '@nestjs/common';

import { MockSmsProvider } from './providers/mock-sms.provider';
import { Msg91SmsProvider } from './providers/msg91.provider';
import { SmsService } from './sms.service';

/**
 * Wires both SMS providers and the public `SmsService` façade.
 *
 * `SmsService` decides at construction time which provider is active.
 * Both providers are still instantiated so BE-09 / BE-24 can pick one
 * directly when they need to bypass the retry/wrap layer (e.g.,
 * sending a Family Sharing invite that doesn't need OTP semantics).
 */
@Global()
@Module({
  providers: [MockSmsProvider, Msg91SmsProvider, SmsService],
  exports: [SmsService, MockSmsProvider, Msg91SmsProvider],
})
export class SmsModule {}
