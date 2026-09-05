# Ambulance Dispatch & Emergency Transportation

Production ambulance module layered on the existing 1mg Doctors platform. It extends the previous ambulance listing/booking foundation into a dispatch system:

**User → Ambulance Provider → Ambulance → Driver → Dispatch → Live Tracking → Hospital → Trip Completion**

This is a transportation/dispatch product, not a medical decision system. It does not diagnose patients, recommend treatment, or replace 112 / 108.

---

## 1. Database changes

### Extended collections

- **`ambulances`** (provider): `fcmTokens`, `serviceRadiusKm`, `supportedCities`, `emergencyAvailable`, operating hours, `cashPaymentEnabled`, `isDisabled`, `isSuspended`, ratings. Vehicles and drivers now include status, equipment, live location, assignment, and driver PIN/online flags.
- **`ambulancebookings`**: full emergency/scheduled payload, requirements, destination, dispatch fields, fare, payment, trip timestamps, and expanded status enum. Partial unique index prevents one vehicle from being on two active trips.

### New collections

| Collection | Purpose |
|---|---|
| `ambulancedispatches` | Offer / accept / reject / timeout rounds |
| `ambulancelocations` | Throttled GPS points with TTL retention (default 48h) |
| `ambulancetrips` | Completed trip summary |
| `ambulancefareconfigs` | Admin-configurable pricing rules |
| `ambulancestatushistories` | Every status transition |
| `ambulancereviews` | Post-trip ratings |
| `ambulanceauditlogs` | Sensitive operational actions |

Indexes are created on startup via `backend/src/db/migrations/ambulanceIndexes.js`.

---

## 2. API endpoints

Base: `/api/v1/ambulance`

### Public / patient

| Method | Path | Purpose |
|---|---|---|
| GET | `/catalog` | Types, equipment, categories, disclaimer |
| GET | `/verified` | Existing verified provider list |
| GET | `/providers` | Public provider profiles |
| GET | `/providers/:id` | Provider + reviews |
| GET | `/hospitals` | Verified clinic/hospital destinations |
| GET | `/nearby` | Requirement-aware nearby matches |
| POST | `/fare/estimate` | Configurable fare estimate |
| POST | `/emergency` | Emergency request + auto-dispatch |
| POST | `/scheduled` | Scheduled booking |
| GET | `/my-bookings` | Patient history (`?group=active\|upcoming\|completed`) |
| GET | `/my-bookings/:id` | Trip + timeline + location freshness |
| GET | `/my-bookings/:id/location` | Live location (active trips only) |
| POST | `/my-bookings/:id/cancel` | Patient cancel |
| POST | `/my-bookings/:id/retry-dispatch` | Expand search |
| POST | `/my-bookings/:id/review` | Ratings after completion |
| POST | `/payments/create-order` | Razorpay/mock order |
| POST | `/payments/verify` | Server-side payment confirm |
| POST | `/bookings` | Legacy direct request (still supported) |

### Provider / driver

| Method | Path | Purpose |
|---|---|---|
| GET | `/dashboard` | Overview cards |
| GET | `/analytics` | Utilization / revenue |
| PUT | `/operations` | Radius, hours, emergency availability |
| GET/POST/PATCH | `/fleet/vehicles` | Ambulance CRUD + status |
| GET/POST/PATCH | `/fleet/drivers` | Driver CRUD + PIN |
| POST | `/driver/login` | Driver JWT (`type=ambulance_driver`) |
| POST | `/driver/presence` | Online / offline + GPS |
| GET | `/requests` | Incoming / scheduled |
| POST | `/requests/:id/accept` | Atomic accept |
| POST | `/requests/:id/reject` | Reject + fallback dispatch |
| POST | `/trips/:id/{start\|arrived\|pickup\|enroute\|destination\|complete}` | Trip states |
| POST | `/trips/:id/location` | Throttled GPS |
| POST | `/trips/:id/cash` | Manual/cash payment |
| POST | `/device-token` | FCM |

### Admin

| Method | Path | Purpose |
|---|---|---|
| GET | `/admin/overview` | Ops metrics |
| GET | `/admin/analytics` | Demand / completion / revenue |
| GET | `/admin/bookings` | All trips |
| GET | `/admin/live` | Live map payload (authorized admin only) |
| GET | `/admin/audit` | Audit log |
| GET/PUT | `/admin/pricing` | Fare rules |
| POST | `/admin/dispatch/:id/reassign` | Override + audit |
| POST | `/admin/bookings/:id/cancel` | Admin cancel |
| POST | `/admin/bookings/:id/refund` | Refund |
| POST | `/admin/providers/:id/suspend\|enable` | Access control |

Existing admin KYC (`/api/v1/admin/ambulances/...`) is unchanged.

---

## 3. User app screens

| Screen | Route |
|---|---|
| Ambulance home | `/ambulance` |
| Emergency request | `/ambulance-emergency` |
| Scheduled booking | `/ambulance-scheduled` |
| Live tracking | `/ambulance-track?bookingId=` |
| My bookings | `/my-ambulance-bookings` |
| Trip details / pay / review | `/ambulance-trip?id=` |
| Provider search (existing) | `/ambulance-search` |

Home emergency CTA and the Ambulance service card now open the hub.

---

## 4. Provider screens (admin_app)

Ambulance providers still use **1mg Admin** (there is no separate provider app).

| Screen | Route |
|---|---|
| Dashboard | `/ambulance-dashboard` |
| Operations (emergency, trips, fleet, drivers) | `/ambulance-operations` |
| Driver mode | `/ambulance-driver-mode` |
| Existing registration / KYC | unchanged |

Login now lands on the dashboard instead of `/provider-profile`.

---

## 5. Admin screens

| Screen | Route |
|---|---|
| Ambulance operations / metrics / reassign | `/admin-ambulance-ops` |
| Live operations map | `/admin-ambulance-live` |
| Pricing JSON configuration | `/admin-ambulance-pricing` |
| Existing KYC list/detail | unchanged |

---

## 6. Real-time events

Emitted over existing Socket.IO (`/socket.io`). Ambulance and driver identities are now accepted.

- `ambulance_request_created`
- `ambulance_dispatch_started`
- `ambulance_assigned`
- `ambulance_driver_accepted`
- `ambulance_driver_rejected`
- `ambulance_driver_en_route`
- `ambulance_arrived`
- `patient_picked_up`
- `ambulance_trip_started`
- `ambulance_location_updated`
- `ambulance_destination_reached`
- `ambulance_trip_completed`
- `ambulance_request_cancelled`
- `ambulance_reassigned`
- `ambulance_payment_updated`
- `ambulance_event` (envelope)
- Existing `app_notification` / booking chat events

---

## 7. Notification events

| Audience | Types |
|---|---|
| User | request created, searching, assigned, accepted, en route, arrived, picked up, destination, completed, cancel, payment, chat |
| Provider | emergency offer, scheduled request, accept/reject, cancel, payment, completed |
| Driver | new trip, cancel, destination update (via provider/driver room) |

Emergency offers are high-priority and throttled (`AMBULANCE_ALERT_THROTTLE_MS`, default 8s). They do not ring indefinitely.

---

## 8. Dispatch algorithm

1. Emergency booking is created as `searching_ambulance` (idempotency key supported).
2. Verified, unsuspended providers are loaded.
3. Candidates must match **type + required equipment + availability + online driver + service radius**. Distance-only matches are discarded if requirements fail.
4. Ranked by ETA / distance.
5. Offers go out in **batches** (`AMBULANCE_DISPATCH_BATCH_SIZE`, default 2).
6. Offer timeout (`AMBULANCE_DISPATCH_OFFER_TIMEOUT_MS`, default 25s) → next batch and optional radius expansion.
7. Accept is atomic:
   - booking can be claimed only while unassigned and searching
   - vehicle can be locked only while `AVAILABLE`/`EMERGENCY_ONLY` and not on another trip
   - losing racer gets `409`
8. After max rounds / search window: `no_answer` or `expired`. User can expand search or call 112 / 108. The app never claims government emergency services.

---

## 9. Location-tracking architecture

- Driver/provider posts `{ latitude, longitude, accuracy, heading, speed }`.
- Minimum interval 4s and 20m (configurable).
- Latest point lives on the booking and vehicle.
- History is stored in `ambulancelocations` and TTL-expired (default 48 hours).
- Users see live location **only during an active assigned trip**.
- Stale GPS shows “Ambulance location temporarily unavailable” / “last updated X seconds ago”.
- After completion, user-facing live tracking stops.

---

## 10. Payment flow

Pricing is **not hardcoded**. Admin edits `AmbulanceFareConfig` (base, per-km, per-minute, type, equipment, optional emergency/night/waiting).

**Scheduled:** request → provider accept → fare shown → user pays (or cash if enabled) → confirmed.

**Emergency:** request → dispatch/trip → fare confirmed from actual distance/time → pay (online or cash) → complete.

Payment status is confirmed only after server verification (`/payments/verify` or provider cash mark). Razorpay mock mode remains the default.

---

## 11. Environment variables

Optional additions in `backend/.env.example`:

```
AMBULANCE_DISPATCH_BATCH_SIZE=2
AMBULANCE_DISPATCH_OFFER_TIMEOUT_MS=25000
AMBULANCE_DISPATCH_MAX_ROUNDS=5
AMBULANCE_DISPATCH_EXPAND_RADIUS_KM=5
AMBULANCE_DISPATCH_INITIAL_RADIUS_KM=15
AMBULANCE_DISPATCH_POLL_MS=5000
AMBULANCE_SEARCH_EXPIRE_MS=600000
AMBULANCE_LOCATION_MIN_INTERVAL_MS=4000
AMBULANCE_LOCATION_MIN_DISTANCE_M=20
AMBULANCE_LOCATION_RETENTION_HOURS=48
AMBULANCE_LOCATION_STALE_MS=30000
AMBULANCE_ALERT_THROTTLE_MS=8000
AMBULANCE_FALLBACK_KMH=30
```

Reuses existing `MONGODB_URI`, `JWT_SECRET`, `GOOGLE_MAPS_API_KEY`, `RAZORPAY_*`, `PUSH_PROVIDER`.

---

## 12. Migration instructions

1. Deploy backend. On connect, Mongoose applies the expanded schemas and `applyAmbulanceIndexes`.
2. No manual SQL/migration script is required.
3. Existing ambulance providers, vehicles, drivers, and old bookings keep working. Old statuses (`accepted`, `en_route`, `arrived`, `completed`) remain valid aliases.
4. Set driver PINs from Operations → Drivers if using driver login.
5. Mark vehicles `AVAILABLE` and drivers online before emergency dispatch can match them.
6. Optionally PUT `/ambulance/admin/pricing` to replace default fare rules.
7. Flutter apps: `flutter pub get` is enough; no new packages were added.

---

## 13. Test cases

Run:

```powershell
cd backend
npm test
```

Covered now:

- Requirement vs distance matching
- Vehicle type aliases
- Disabled / busy / offline exclusion
- Dispatch batching
- Fare components and disabled emergency surcharge
- Status transitions and cancel rules
- Race-condition accept/vehicle-lock/completion guards

Manual / API cases to exercise:

- Two drivers accepting the same emergency request
- Same ambulance assigned to two trips
- Duplicate completion / payment
- Unauthorized booking or location access
- Provider isolation
- Admin reassign + audit log
- Offline GPS / stale location copy

---

## 14. End-to-end workflow

1. Patient opens **Ambulance** → **Request Emergency Ambulance**.
2. Current location is used when permission exists; destination can be a platform hospital or any place.
3. Minimal dispatch fields + capability requirements are collected (not a diagnosis).
4. Backend searches matching available ambulances and offers a small batch.
5. Provider/driver gets a high-priority alert and ACCEPT / REJECT.
6. On accept, user sees confirmation and live tracking.
7. Driver updates: en route → arrived → picked up → to destination → arrived → complete.
8. Fare is finalized; user pays online or cash if enabled.
9. After completion, user can rate ambulance / driver / provider.
10. If nobody accepts: user is told clearly, can expand search, and is pointed to 112 / 108.

Scheduled bookings skip auto-dispatch: provider accepts, user pays, trip runs at the scheduled time.

---

## 15. Assumptions

- There is no separate hospital-capacity feed; destinations come from verified doctor clinics. Emergency-department availability is **not** claimed.
- Providers and drivers share `admin_app`. Drivers can use Driver mode on a provider session or `POST /ambulance/driver/login` with a PIN.
- Masked calling is not in the existing stack; the apps use `tel:` to the booking contact / driver number already stored for the trip.
- Chat reuses `BookingChatMessage` and is limited to participants of that booking.
- Firebase is used only for the existing FCM push path, not as a second realtime/database.
- Default geography guidance is India (112 / 108).
- Default fare rules are sensible starting values until admin configures them.
- Existing direct `POST /ambulance/bookings` (pick a provider first) remains supported.
