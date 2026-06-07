# Phase BE-49: DB Backups + PITR

## Phase Metadata
- **Phase ID**: BE-49
- **Depends On**: BE-33 v2
- **Estimated Duration**: 1-2 days

## Goal
Per Req 50, enable PostgreSQL WAL archiving, automated daily snapshots to S3, 30-day retention, and a monthly automated restore test.

## Implementation
- AWS RDS Automated Backups: enable, retention 30 days
- WAL archiving: continuous to S3 via `archive_command`
- Daily snapshot: managed by RDS
- Monthly restore test: GitHub Actions cron → restores latest snapshot to a temporary RDS instance, runs schema sanity checks, tears down

## Files
- `infra/rds/backups.tf` — RDS automated-backup config
- `.github/workflows/monthly-restore-test.yml`
- `server/scripts/restore-test.sh`

## SOP
**Tests (15)**: snapshot exists daily; WAL archived continuously; PITR to T-30s succeeds in staging; restore test workflow runs monthly; failure alarm to RADHA_Owner within 1 hour; storage encryption verified on snapshots; KMS key references correct; cross-region copy (optional) configured; recovery RTO < 1h; recovery RPO < 5 min; documentation up to date; rehearsed scenarios documented; cost monitoring on backup storage; lifecycle expiration after 30 days; runbook validated.

**Q&A (8)**: RTO/RPO targets accepted by stakeholders? Cross-region DR strategy? Snapshot encryption key rotation impact? Restore-test cadence justification? Cost trajectory for 30-day retention? Compliance requirements (DPDP/GDPR) for backups? Anomaly detection on backup size? Runbook owner?

### Sign-off (standard).

---
**END OF BE-49**
