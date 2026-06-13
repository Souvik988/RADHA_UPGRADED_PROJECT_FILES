# PHASE 10 — Suppliers module

## Goal
Build the Suppliers screen: table with search, bulk import/export, supplier detail with contacts
and a performance chart, and status actions (activate / deactivate / blacklist).

## Depends on
Phases 02, 04, 05. (Phase 09 GRN consumes the supplier picker built here.)

## Doc references
- Doc 1 §6.12 (`/suppliers/*`).
- Doc 2 §5.7 (Suppliers spec), §6 (performance chart), §4.2/4.7 (table, side panel).
- Doc 3 §A.3.6 (supplier functions), §B.7 (destructive/blacklist confirm).

## Scope (in)
- `app/(dash)/suppliers/page.tsx` — table + search + import/export + create CTA.
- `app/(dash)/suppliers/[id]/page.tsx` — detail (info, contacts, performance).
- `features/suppliers/suppliers.queries.ts` / `.actions.ts` / `.schema.ts`.
- Components: `suppliers-table.tsx` (`/suppliers`, `/search`), `supplier-detail.tsx`,
  `contacts-editor.tsx` (`/:id/contacts`, delete `/contacts/:id`), `performance-chart.tsx`
  (`/:id/performance`), `import-export.tsx` (`/import`, `/export`), `status-actions.tsx`
  (activate/deactivate/blacklist), `supplier-create-panel.tsx`.
- `components/pickers/supplier-picker.tsx` — reusable picker (used by GRN).

## Out of scope
Supplier payable ledger / payments (out of V1 scope). Bulk status with undo (🆕, Phase 18 — here
per-item status only).

## Step-by-step
1. Table with debounced search (`/search`), mono codes, status chips; row → detail.
2. Create panel (RHF+Zod). Import wizard (`POST /suppliers/import`) with error feedback; export
   (`GET /suppliers/export`) → presigned download.
3. Detail page: info card, contacts editor (add/list/delete), performance chart (token-themed).
4. Status actions: activate/deactivate/blacklist; blacklist = destructive confirm + reason; audited.
5. Reusable `supplier-picker` for GRN. States: skeleton rows, empty ("Add your first supplier"),
   error retry. Verify.

## API wiring
- `POST/GET /suppliers`, `GET /suppliers/search`, `/export`, `POST /suppliers/import`,
  `GET/PATCH/DELETE /suppliers/:id`, `POST /suppliers/:id/activate|deactivate|blacklist`,
  `GET/POST /suppliers/:id/contacts`, `DELETE /suppliers/contacts/:contactId`,
  `GET /suppliers/:id/performance`. Store/tenant-scoped; write = owner/manager/admin.

## Design spec
- Doc 2 §5.7. Status chips (active/inactive/blacklisted, icon+text). Performance chart per §6 rules.
  Mono codes/amounts/dates. One orange CTA (Add supplier). Side panels for create/contacts.

## Security checks
- Write/status actions permission-gated (owner/manager/admin); API re-enforces. Blacklist confirm + audit.
- Import: validate file client-side (type/size) before upload; backend validates too. Export via
  presigned short-TTL URL (§B.7). Store/tenant scope on all calls.

## Acceptance criteria
- [ ] Table + search render; create works; import/export functions (export = presigned download).
- [ ] Detail shows info, contacts CRUD, performance chart.
- [ ] Status activate/deactivate/blacklist work with confirm + correct gating.
- [ ] Supplier picker reusable in GRN. All states designed; `build`+`typecheck` clean.

## Verification
- `npm run typecheck && npm run build`.
- User: create + edit a supplier, add/remove a contact, view performance, blacklist (confirm),
  import a small CSV (see errors), export, and pick the supplier inside a GRN.

## Rollback note
Additive under `features/suppliers/` + pages + the shared picker. No shared-layer/backend changes.
