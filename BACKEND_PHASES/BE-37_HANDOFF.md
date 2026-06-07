# BE-37 Handoff — Allergen Profile

- CRUD endpoints live; encrypted display names.
- Matcher tested against curated allergen taxonomy.
- BE-12 v2 consumes via injected `IAllergenProfileService`.

## Context for BE-38
Expiry Calendar will share the same per-user/family scoping pattern.

## Rollback
DROP TABLE allergen_profiles;

**End of BE-37 Handoff**
