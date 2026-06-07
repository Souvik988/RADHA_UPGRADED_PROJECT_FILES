# Phase BE-37: Allergen Profile (per-family-member)

## Phase Metadata
- **Phase ID**: BE-37
- **Depends On**: BE-09 v2 (RLS), BE-12 v2 (comprehensive scoring), BE-36 (family sharing), BE-33 v2 (KMS)
- **Blocks**: BE-12 comprehensive scoring matches
- **Estimated Duration**: 2 days

## Goal
Implement Allergen_Profile (Req 32). Each Consumer can create profiles per family member, tagged with allergens (e.g., peanut, gluten, dairy) and conditions (e.g., diabetes, hypertension). Free Consumer = 1 profile, Premium Consumer = up to 5 (matches Family Sharing). Encrypted at rest under tenant scope. Used by BE-12 to flag matching ingredients in Comprehensive scan output.

## Schema
```sql
CREATE TABLE allergen_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  family_member_user_id UUID REFERENCES users(id),  -- null for self
  display_name_encrypted BYTEA NOT NULL,            -- AES-256 envelope
  age_band TEXT NOT NULL CHECK (age_band IN ('infant','toddler','child','adolescent','adult','senior')),
  allergy_tags TEXT[] NOT NULL DEFAULT '{}',
  condition_tags TEXT[] NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE allergen_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY allergen_tenant_isolation ON allergen_profiles
  USING (tenant_id::text = current_setting('app.tenant_id', true));
```

## Files to Create
- `server/src/modules/allergen/allergen.module.ts`
- `server/src/modules/allergen/services/allergen-profile.service.ts`
- `server/src/modules/allergen/services/allergen-matcher.service.ts`
- `server/src/modules/allergen/controllers/allergen.controller.ts`
- `server/src/modules/allergen/dto/upsert-allergen-profile.dto.ts`

## Service
```typescript
@Injectable()
export class AllergenProfileService implements IAllergenProfileService {
  async upsert(userId: string, dto: UpsertAllergenProfileDto): Promise<AllergenProfile> {
    const max = await this.entitlements.maxAllergenProfilesFor(userId);
    const existing = await this.repo.countByUser(userId);
    if (existing >= max && !dto.id) throw new ConflictException(`Max ${max} profiles`);
    const displayNameCipher = await this.kms.encrypt(dto.displayName);
    return this.repo.upsert({ ...dto, displayNameEncrypted: displayNameCipher });
  }

  async match(profileId: string, ingredients: string[], productAllergens: string[]): Promise<AllergenMatch[]> {
    const profile = await this.repo.findOneByOrFail({ id: profileId });
    return this.matcher.match(profile, ingredients, productAllergens);
  }
}
```

## API
| Method | Path |
|---|---|
| POST | `/api/v1/allergen/profiles` |
| PUT | `/api/v1/allergen/profiles/:id` |
| GET | `/api/v1/allergen/profiles` |
| DELETE | `/api/v1/allergen/profiles/:id` |
| GET | `/api/v1/allergen/profiles/:id/active` (set as active for next scan) |

## Mandatory Testing/Q&A SOP
**Tests (15)**: profile CRUD, free quota=1, premium quota=5, encryption verifiable, decryption only via KMS, family-member-scoped, matcher detects nuts in "peanut oil", matcher case-insensitive, matcher handles synonyms, profile age-band gates child-suitability output, deletion is soft, RLS denies cross-tenant, matched flags appear in BE-12 comprehensive output, performance < 50ms, audit log entry per write.

**Q&A (8)**: How are allergens normalized (e.g., peanut/groundnut)? How does encryption interact with App Owner Dashboard's privacy boundary? What is the master allergen taxonomy and where is it sourced? How does the matcher handle "may contain" trace warnings? Can a profile be transferred between accounts? How do we test the matcher without leaking PII into test fixtures? How does the active-profile selection persist across devices? What is the migration plan when allergen taxonomy adds new tags?

### Sign-off block (standard).

---
**END OF BE-37**
