# Offline Support — Plan (no code)

How the Ocean Delivery app can keep working at ports/yards with no (or
intermittent) internet. **Planning document only — no code changes.**

---

## 1. Goal & scope

Field users (REPRESENTATIVE and SUB_LOGISTICS_OFFICER) must be able to **keep
doing their job with zero signal** and have everything sync automatically once
a connection returns. The critical offline actions are:

- **View** their assigned master POs, steps, vendors, and items.
- **Capture** step proofs (VENDOR / LPO / ITEM photos) with GPS.
- **Resolve** items (missing / rejected).
- **Finish/finalize** and **upload the delivery note**.

Everything above should queue locally and upload later; nothing a user did in
the field should ever be lost because they were offline.

---

## 2. GPS without internet — yes

- GPS/GNSS is **satellite-based**; a lat/lng fix needs **no internet**, only the
  device's location hardware turned on and location permission granted.
- Caveats to design around:
  - **First fix is slower offline** (no A-GPS almanac/ephemeris download over the
    network → cold start can take 10–60s outdoors). Mitigation: start acquiring
    GPS as early as possible (on entering a capture screen, as today) and show a
    clear "acquiring GPS" state; allow a longer timeout offline.
  - **Network/"fused" location** (cell+wifi triangulation) and **reverse
    geocoding** (lat/lng → address) DO need internet. This app stores only
    lat/lng, so this is not a blocker — keep using raw coordinates, never
    reverse-geocode on the critical path.
  - Accuracy may be lower until enough satellites lock; keep recording
    `accuracy_meters` with each capture so the backend/rep can judge quality.
- **Conclusion:** GPS capture works fully offline; only time-to-first-fix and
  accuracy degrade slightly. No change needed to the location approach besides
  more forgiving timeouts + clearer UI.

---

## 3. Connectivity detection

- Add a connectivity watcher (online/offline + reachability of the API host).
  Being on wifi ≠ the API is reachable, so combine OS connectivity with a light
  reachability check (a cheap `GET /health` or the first real request result).
- Expose a single `ConnectivityService` (a provider) with states:
  `online` / `offline` / `syncing`.
- Drive a persistent, non-blocking **status banner** and the sync engine from it.

---

## 4. Local persistence — the two stores

Introduce a local database (see §12) with **two responsibilities**:

### a) Read cache (mirror of server reads)
Cache the payloads the app already fetches so screens render offline:
- `master-pos` list (incl. the inline `steps`, `current_step`, `next_step`,
  people fields).
- per-master `vendor-pos`.
- per-vendor `vendor-pos/:id` detail + `/steps` + `/proofs`.
- assistant `tasks`, `sub-logistics-officers`.
Each cached entry stores `fetchedAt` so the UI can show "last updated X ago"
and so sync can refresh stale entries first.

### b) Outbox (queue of pending writes)
Every mutation becomes a durable **queued operation** instead of a direct HTTP
call. One row per action, with: type, target ids, payload, local file paths,
created-at, attempt count, status (`pending` / `sending` / `failed` / `done`),
and last error. Operation types:
- `vendorStepPhoto`, `lpoStepPhoto`, `itemStepPhoto` (with the captured
  image/PDF file saved to app storage + GPS).
- `itemMissing`, `itemRejected`.
- `startVendor`, `finalizeMaster` (/ `finalizeVendor`).
- `assignSubLogistics`, `uploadDeliveryNote`.

---

## 5. Where this plugs into the current architecture

The app already has a clean seam: **`DeliveryApi`** (abstract) with
`HttpDeliveryApi` / `MockDeliveryApi`, wrapped by **`DeliveryRepository`**,
consumed by providers. Offline slots in cleanly:

- Add an **`OfflineDeliveryRepository`** (or make `DeliveryRepository`
  offline-aware) that:
  - **Reads:** try network → on success update cache & return; on failure return
    cached data (cache-first when offline, network-first when online).
  - **Writes:** when offline (or always, then flush), **enqueue to the outbox**
    and return an optimistic result so the UI advances immediately.
- Providers keep calling the same repository methods — **no provider/UI rewrite**,
  just richer return/状态. This keeps the change contained.

---

## 6. Write path (outbox) in detail

1. User captures a photo → the file is already on disk (camera/temp). **Move it
   into a permanent app directory** (not OS temp, which can be cleared) and
   record its path in the outbox row. The PDF conversion (single image → PDF,
   multi → merged PDF) happens **at enqueue time** so the queued file is final.
2. The provider updates local state optimistically (step marked captured, item
   resolved, etc.) and writes it to the read cache so the UI reflects it offline.
3. The sync engine drains the outbox when online.

**Ordering & dependencies:** operations for one vendor PO must apply in order
(e.g. `startVendor` before step photos; step photos before `finalize`). Keep a
per-vendor FIFO; a failed op blocks only its own vendor's queue, not others.

---

## 7. Sync engine

- Triggers: app foreground, connectivity regained, a periodic timer, and a manual
  "sync now" button.
- For each pending op (respecting per-vendor order): send → on success mark
  `done`, delete the local file, refresh affected cache; on failure increment
  attempts with **exponential backoff**.
- **Classify failures:**
  - *Transient* (no network, 5xx, timeout) → retry later, keep queued.
  - *Auth* (401) → pause queue, prompt re-login, resume after.
  - *Conflict/validation* (409/422/404) → mark the op `failed`, surface it to the
    user in a "needs attention" list; never silently drop. e.g. a step already
    completed server-side, or finalize blocked.
- After a successful drain, re-pull the affected master/vendor to reconcile
  truth (server is authoritative; local optimistic state is replaced).

---

## 8. Auth while offline

- The JWT is already stored in secure storage and attached by `AuthInterceptor`.
  Offline, the cached token keeps the app usable **until it expires**.
- Can't refresh/login offline → if the token is expired when a request finally
  goes out, that op hits 401 → queue pauses and the user is asked to sign in when
  back online (their queued work stays intact).
- Keep the user "signed in" offline (don't force logout just because `/auth/me`
  can't be reached); only react to a real 401 from the server.

---

## 9. Media handling offline

- Photos & generated PDFs live in a dedicated app folder, referenced by the
  outbox until uploaded, then deleted on success.
- Guard disk usage: cap retained pending media, warn if storage is low (the
  container/device can run out), and never block capture on upload.
- Proof thumbnails already load via authenticated network image — offline they
  won't render; show a local placeholder / the just-captured local file instead.

---

## 10. UI / UX

- **Global banner:** "You're offline — changes will sync when you reconnect."
- **Per-item sync state:** small badges (queued ⏳ / sent ✓ / failed ⚠) on steps,
  captures, and the master card so users trust what's saved.
- **Pending/sync center:** a screen listing queued and failed operations with a
  retry and a clear error per failed item.
- **"Last updated"** timestamps on cached screens.
- Disable or clearly mark actions that genuinely need the server (e.g. nothing
  here strictly does, but re-login does).

---

## 11. Edge cases & risks

- **GPS cold start offline** → longer timeouts + "still locating" UI; allow the
  user to retry; record accuracy.
- **Partial captures** (multi-photo step) must queue as one op (one merged PDF),
  not several half-states.
- **Step/finalize ordering** across a flaky connection — enforce per-vendor FIFO.
- **Server-side scoping** (assistant sees only incomplete tasks) means the cache
  can go stale after a sync; always reconcile from the server post-drain.
- **Clock skew / created-at** — stamp ops with device time but let the server set
  authoritative timestamps.
- **Token expiry mid-field** — unavoidable; mitigate with a long-lived token or a
  pre-trip "stay signed in" refresh, and never lose queued work.
- **Conflict** (someone else finalized, or step completed elsewhere) → show it,
  don't overwrite.

---

## 12. Suggested packages (Flutter)

- Connectivity: `connectivity_plus` (OS state) + a reachability ping.
- Local DB / outbox: `drift` (typed SQL, best for a real queue) or `sembast`
  (simple document store); `hive` acceptable for a lighter cache.
- Media dir: `path_provider` (already used).
- Background sync (optional, later): `workmanager` for OS-scheduled flushes.
- Keep `dio` (already used); add retry/backoff around the queue, not per call.

---

## 13. Phased rollout

1. **Read cache** — browse master POs / steps / vendors offline (view-only).
   Lowest risk, immediate value.
2. **Capture outbox** — queue step photos + GPS offline; auto-upload on
   reconnect; per-item sync badges. The core win.
3. **Full write queue** — item missing/rejected, start, finalize, assign, note.
4. **Sync center + conflict handling** — failed-op list, retries, reconciliation.
5. **Background sync & polish** — scheduled flush, storage guards, "last updated".

Each phase ships independently and leaves the app working online as today.

---

## 14. Explicitly out of scope / won't work offline

- First-time **login** (needs the auth server).
- **Downloading** the delivery-note template / proof images not already cached.
- Anything requiring a **fresh server decision** at the moment of action
  (the app instead queues and lets the server decide at sync, surfacing
  rejections afterward).
