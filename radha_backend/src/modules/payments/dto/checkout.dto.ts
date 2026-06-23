import { IsIn, IsString, IsUUID } from 'class-validator';
import { z } from 'zod';

/**
 * BE-28 v2 — Checkout DTO.
 *
 * Mobile clients hit `POST /api/v1/payments/checkout` with the plan
 * they want to buy. The backend creates a Razorpay order and hands
 * back the prefill payload so the Flutter app can open native
 * checkout (`razorpay_flutter`).
 */
export class CheckoutDto {
  @IsUUID('4', { message: 'planId must be a valid UUID' })
  planId!: string;

  @IsString()
  @IsIn(['monthly', 'yearly'], { message: "billingCycle must be 'monthly' or 'yearly'" })
  billingCycle!: 'monthly' | 'yearly';
}

export const CheckoutSchema = z.object({
  planId: z.string().uuid({ message: 'planId must be a valid UUID' }),
  billingCycle: z.enum(['monthly', 'yearly'], {
    errorMap: () => ({ message: "billingCycle must be 'monthly' or 'yearly'" }),
  }),
});

export type CheckoutInput = z.infer<typeof CheckoutSchema>;

export interface CheckoutResult {
  razorpayOrderId: string;
  keyId: string;
  amountPaise: number;
  currency: 'INR';
  prefill: {
    name: string;
    email: string;
    contact: string;
  };
  notes: Record<string, string | number | boolean>;
}
