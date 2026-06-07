import { ExternalServiceException } from '@/common/errors/business.exception';
import { ErrorCode } from '@/common/errors/error-codes';
import { ConfigService } from '@/config/config.service';

import { MockSmsProvider } from '../providers/mock-sms.provider';
import { Msg91SmsProvider } from '../providers/msg91.provider';
import { SmsService } from '../sms.service';

describe('SmsService', () => {
  let mock: MockSmsProvider;
  let msg91: Msg91SmsProvider;

  const buildSvc = (provider: 'msg91' | 'mock'): SmsService => {
    mock = new MockSmsProvider();
    msg91 = {
      sendOtp: jest.fn(),
      sendNotification: jest.fn(),
    } as unknown as Msg91SmsProvider;
    const cfg = { sms: { provider } } as unknown as ConfigService;
    return new SmsService(cfg, msg91, mock);
  };

  beforeEach(() => {
    jest.useFakeTimers({ doNotFake: ['nextTick', 'setImmediate'] });
  });

  afterEach(() => {
    jest.useRealTimers();
  });

  it('routes to mock provider when configured', async () => {
    const svc = buildSvc('mock');
    const result = await svc.sendOtp('9876543210', '123456');
    expect(result.provider).toBe('mock');
    expect(mock.getOutbox()).toHaveLength(1);
  });

  it('returns success on first MSG91 hit', async () => {
    const svc = buildSvc('msg91');
    (msg91.sendOtp as jest.Mock).mockResolvedValue({
      success: true,
      provider: 'msg91',
      messageId: 'r-1',
    });
    const result = await svc.sendOtp('9876543210', '123456');
    expect(result.success).toBe(true);
    expect(msg91.sendOtp).toHaveBeenCalledTimes(1);
  });

  it('retries up to 3 times with exponential backoff', async () => {
    const svc = buildSvc('msg91');
    (msg91.sendOtp as jest.Mock)
      .mockResolvedValueOnce({ success: false, provider: 'msg91', error: 'fail-1' })
      .mockResolvedValueOnce({ success: false, provider: 'msg91', error: 'fail-2' })
      .mockResolvedValueOnce({ success: true, provider: 'msg91', messageId: 'r-3' });
    const promise = svc.sendOtp('9876543210', '123456');
    await jest.advanceTimersByTimeAsync(2_000);
    await jest.advanceTimersByTimeAsync(4_000);
    const result = await promise;
    expect(result.success).toBe(true);
    expect(msg91.sendOtp).toHaveBeenCalledTimes(3);
  });

  it('throws SMS_DELIVERY_FAILED after 3 failures', async () => {
    // Use real timers for this test — fake timers + multiple retry-chains
    // in one test surface as a timeout because each chain has two
    // setTimeout-based delays that need to be drained sequentially.
    jest.useRealTimers();
    const svc = buildSvc('msg91');
    (msg91.sendOtp as jest.Mock).mockResolvedValue({
      success: false,
      provider: 'msg91',
      error: 'persistent fail',
    });
    await expect(svc.sendOtp('9876543210', '123456')).rejects.toBeInstanceOf(
      ExternalServiceException,
    );
    await expect(svc.sendOtp('9876543210', '123456').catch((e) => e)).resolves.toMatchObject({
      code: ErrorCode.SMS_DELIVERY_FAILED,
    });
  }, 30_000);
});
