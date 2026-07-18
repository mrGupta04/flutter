# 1mg Care Platform — Implementation Document

**Document type:** Feature implementation summary  
**Audience:** Product, engineering, QA  
**Repository:** `user_app` · `admin_app` · `backend`  
**Product scope:** Practo-like healthcare marketplace (MVP / production-ready core)

---

## 1. Purpose

This document describes the features that have been implemented across the 1mg Care patient application, the 1mg Admin / provider application, and the Node.js backend API. It is intended as a single reference for what is available today, how major journeys work, and where the product remains intentionally limited relative to a full commercial marketplace.

For environment setup, MongoDB Atlas, Maps keys, and run instructions, see the root `README.md`.

---

## 2. System overview

The platform is delivered as three cooperating components:

1. **Patient app (`user_app`)** — marketplace branded as 1mg Care, used by patients to discover providers, book services, pay, chat, track care, and manage their health profile.
2. **Admin / provider app (`admin_app`)** — used for provider registration and KYC, day-to-day provider dashboards, and platform-admin marketplace operations.
3. **Backend (`backend`)** — Express REST API with MongoDB persistence, Razorpay payment integration, push notifications, and email providers.

Providers register and are verified in the admin app. Once approved, they appear in the patient marketplace. Patients book and pay through the user app; providers fulfill bookings from their dashboards.

---

## 3. Patient application

### 3.1 Authentication and account

Patients can register and sign in with email credentials. Password recovery is supported through a forgot-password and OTP-based reset flow. After login, patients may edit basic profile details and maintain an extended **health profile** that includes family members, saved addresses, medical history (allergies, chronic conditions, medications, notes), and insurance details (provider, policy number, member ID, validity).

Theme preference supports light and dark mode and is persisted on device. Device push tokens can be registered for notifications.

### 3.2 Discovery and booking

Patients can browse verified doctors, nurses, diagnostic labs, scan centers, blood banks, and ambulance services.

Supported booking journeys include:

- **Online consultation** — select a slot, apply an optional coupon, pay with Razorpay, and receive a confirmed booking.
- **Hospital / clinic visit** — pay-first clinic appointment with optional coupon.
- **Doctor or nurse home visit** — submit a request with address and location; after provider approval, complete payment (coupon may be entered at request time and applied when payment is created).
- **Lab tests** — real booking API; unpaid bookings can be settled later via Pay Now.
- **Scan procedures** — real booking API with the same Pay Now pattern.
- **Blood bank orders** — ordering with coupon support.
- **Ambulance** — call the service and/or submit a pickup request through the booking API.

Default promotional codes seeded for demos include `CARE10`, `HEALTH50`, and `FIRST100`.

### 3.3 After booking

The patient dashboard consolidates bookings across consultation, home visit, lab, scan, blood, and ambulance categories. From a booking card, patients can:

- Pay outstanding amounts (home visit after approval; unpaid lab/scan).
- Join an online video consult when eligible.
- Open **booking chat** with the assigned doctor or nurse (messages refresh automatically about every three seconds).
- View visit timeline and progress.
- Access prescriptions and previously uploaded reports.
- Leave post-session feedback.

Favorites and an in-app notification list are available. Notification taps deep-link into chat or relevant booking screens where booking metadata is present.

### 3.4 Tracking, loyalty, and support

For active ambulance bookings, patients can open a **live tracking** map that polls the provider’s shared GPS position.

A **rewards and referrals** screen shows points balance and the patient’s referral code. New registrations may accept a referral code; points are awarded when eligible bookings are paid. A simple redeem action is available when the balance meets the threshold.

The home screen hero carousel loads **CMS banners** from the API and falls back to built-in slides if none are configured. Patients can create and review **support tickets**.

---

## 4. Provider and admin application

### 4.1 Onboarding and verification

Providers can register as doctor, nurse, ambulance operator, blood bank, diagnostic lab, or scan center. Registration supports document upload and map-based location capture. Platform admins review applications, verify documents, and approve, reject, or suspend providers. Approved profiles are published to the patient app.

### 4.2 Provider dashboards

Each provider type has an operational dashboard appropriate to their service:

- **Doctors** manage bookings, approve or reject home-visit requests, chat with patients, run video consults, issue prescriptions, and update visit progress.
- **Nurses** manage home-visit bookings, chat, and visit progress.
- **Labs and scan centers** manage incoming bookings and update status (scan dashboard is aligned with lab booking management).
- **Blood banks** handle orders and emergency requests.
- **Ambulance providers** update booking status through the dispatch lifecycle and can **share live location** so patients can track the vehicle.
- Earnings and provider notifications are available where wired for the role.

### 4.3 Platform admin operations

Administrators have a marketplace control surface that includes:

- Overview metrics (patients, bookings, revenue, pending KYC).
- Cross-service booking list and patient search.
- Coupon create and update.
- Support ticket inbox with reply and status changes.
- Refund recording (booking payment status marked refunded; funds are not automatically returned through Razorpay).
- CMS management for home hero banners.

---

## 5. Backend capabilities

The API exposes authenticated and public routes covering the domains below.

**Identity and access.** JWT authentication for patients, providers, and admins; patient password reset.

**Consultations and payments.** Slot availability and holds; online, clinic, and home-visit booking; Razorpay order creation and payment verification; coupon validation and application.

**Diagnostics and blood.** Lab and scan bookings with payment and status updates; blood orders with coupon-aware pricing.

**Ambulance.** Booking creation, status transitions, and live location updates.

**Communication and lifecycle.** Booking chat (list, send, incremental `after` query); cancel and reschedule; timelines; home-visit progress; push notifications on key events including new chat messages.

**Patient data.** Medical profile, family members, saved addresses, insurance fields.

**Growth and content.** Referral application at registration; reward points on paid bookings; redeem endpoint; public CMS banners and admin CRUD.

**Support and ops.** Patient support tickets; admin ticket handling; refund recording; marketplace overview endpoints.

**Infrastructure integrations.** FCM device tokens; email via SMTP, Gmail API, or mock mode for local development.

---

## 6. Recent implementations and fixes

This section records UI/UX and onboarding work delivered after the core marketplace MVP. Items are grouped by area.

### 6.1 Provider registration (admin_app)

| Item | Status | Summary |
|------|--------|---------|
| Registration acknowledgment | Implemented | Required checkbox on the final review step before submit. Shared widget: `RegistrationAcknowledgmentSection` in `admin_app/lib/shared/widgets/healthcare_ui.dart`. Applied to doctor, nurse, ambulance, lab, scan, and blood bank flows. Submit stays disabled until checked; snackbar if submit is attempted without acknowledgment. |
| Patient signup acknowledgment | Implemented | Same acknowledgment pattern above **Create account** in `user_app` patient registration. |
| System back = previous step | Fixed | Registration screens use `PopScope` so Android/system back moves to the previous step instead of exiting. Exit only from step 1. Lab / scan / blood bank AppBar leading also navigates to the previous step. |
| Nurse languages spoken | Implemented | Replaced chip-only language picker with a searchable multi-select dropdown matching the doctor flow (search, tap to add, removable chips). Clinical skills remain chip-based. |
| Location toggle styling | Fixed | Selected **Use location** segment uses green primary styling in `registration_location_input.dart`. |
| Enable Location Services dialog | Implemented | When GPS is off, apps show **Enable Location Services** with **Turn On** / Cancel. Helpers: `LocationService.ensureReady` / `getCurrentPositionWithPrompt` in both apps. Wired into admin map picker and patient home / nearby search flows. |

### 6.2 Admin verification screens (admin_app)

| Item | Status | Summary |
|------|--------|---------|
| Doctor verify detail rows | Fixed | Personal / Professional / Address rows use a fixed-width label column so values align consistently. |
| Nurse verify application | Implemented / fixed | Nurse detail screen aligned with doctor verify layout: profile header card, status badge, sectioned cards (Personal, Professional, Address), document review, and publish action bar. Includes **Languages**, skills, fees, and related fields. |
| Nurse registration review | Fixed | Review & submit uses label/value rows (same alignment pattern) instead of unstructured text lines; languages shown under Personal Information. |
| Doctor review & submit rows | Fixed | Doctor registration review items use the same fixed label-column alignment. |

### 6.3 Doctor provider experience (admin_app)

| Item | Status | Summary |
|------|--------|---------|
| Dashboard header alignment | Fixed | Pending banner and green profile card vertically aligned; verification badge padding/centering cleaned up. Same treatment on provider profile header. |
| Three consultation fees | Implemented | Practice overview and edit-profile sheet show Online / Clinic / Home fees when those services are offered. Admin doctor details shows matching fee rows. |

### 6.4 Patient marketplace — labs and scans (user_app)

| Item | Status | Summary |
|------|--------|---------|
| Scan modality logos | Implemented | Custom modality illustrations (MRI, CT, X-Ray, ultrasound, etc.) via `scan_modality_logos.dart`; used on category badges, headers, and procedure cards. |
| Lab organ logos | Implemented | Custom organ / health-risk illustrations in `lab_organ_logos.dart`; browse group cards use `LabOrganLogoIcon` instead of generic Material icons. |
| Lab detail search | Implemented | Search field on lab detail (under Book Test) filters packages, browse groups, and individual tests; empty state when no matches. About / reviews / FAQs stay visible when not searching. |
| Top Categories grid | Implemented | Shared `TopCategoriesGrid` (`user_app/lib/shared/widgets/top_categories_grid.dart`): 3-column pastel cards, title top-left, illustration bottom. **Lab Tests** explore shows Diabetes, Digestive, Heart, Respiratory, Kidney, Joints & Muscle (opens category test list). **Imaging & Scans** shows MRI, CT, X-Ray, Ultrasound, PET, Mammography (filters procedure list; selected border highlight). |

### 6.5 Key files touched

**Admin / provider**

- `admin_app/lib/shared/widgets/healthcare_ui.dart` — acknowledgment section  
- `admin_app/lib/core/widgets/enable_location_services_dialog.dart`  
- `admin_app/lib/core/services/location_service.dart`  
- `admin_app/lib/features/nurse_registration/presentation/widgets/nurse_registration_step_widgets.dart`  
- `admin_app/lib/features/admin/presentation/screens/admin_doctor_details_screen.dart`  
- `admin_app/lib/features/admin/presentation/screens/admin_nurse_details_screen.dart`  
- `admin_app/lib/features/doctor_dashboard/presentation/screens/doctor_dashboard_screen.dart`  
- Provider registration screens (doctor, nurse, ambulance, lab, scan, blood bank) — `PopScope` / acknowledgment wiring  

**Patient app**

- `user_app/lib/core/widgets/enable_location_services_dialog.dart`  
- `user_app/lib/core/services/location_service.dart`  
- `user_app/lib/features/labs/presentation/screens/lab_detail_screen.dart`  
- `user_app/lib/features/labs/presentation/screens/lab_explore_screen.dart`  
- `user_app/lib/features/labs/presentation/widgets/lab_top_categories_section.dart`  
- `user_app/lib/features/labs/data/lab_catalog_metadata.dart` — featured Top Categories  
- `user_app/lib/features/scans/presentation/screens/scans_screen.dart`  
- `user_app/lib/shared/widgets/top_categories_grid.dart`  
- Lab organ / scan modality logo modules under `features/labs` and `features/scans`  

---

## 7. Known MVP limitations

The following items are implemented at a practical MVP level and should not be described as full commercial equivalents:

1. **Chat** uses periodic polling rather than WebSockets or Socket.io.
2. **Ambulance live map** depends on the provider sharing location and the patient app polling; it is not a continuous background GPS stream.
3. **Refunds** update internal payment status only; they do not automatically execute Razorpay payouts.
4. **CMS** covers home hero banners only; there is no article or multi-page content system.
5. **Dark mode** is enabled at the app theme level; some screens still use fixed light color tokens.
6. **Home-visit “tracking”** is status-based (for example en route / arrived), not a live map of the clinician.
7. **Rewards** are a lightweight points and referral model, not a full loyalty marketplace.

---

## 8. Suggested verification checklist

1. Start the backend (`npm start` in `backend/`).
2. As a patient, complete an online consult using coupon `CARE10`, open chat, and confirm messages update without manual refresh.
3. Create an unpaid lab or scan booking and complete payment with **Pay now** from My Bookings.
4. Request an ambulance; as provider, accept and share location; as patient, open **Track live**.
5. In admin, open marketplace overview, coupons, support tickets, refunds, and CMS banners.
6. From the patient profile menu, open Rewards, toggle dark mode, and save insurance fields on the health profile.
7. Provider registration: step back with system back; acknowledgment required on submit; nurse languages use searchable dropdown.
8. Admin: open Verify doctor / Verify nurse and confirm aligned label/value rows and languages on nurse.
9. Patient labs: search on lab detail; Top Categories on Lab Tests and Imaging & Scans.

---

## 9. Related documents

| Document | Contents |
|----------|----------|
| `README.md` | Repository layout, quick start, Atlas, Maps API key, troubleshooting |
| `user_app/README.md` | Patient app notes |
| `admin_app/README.md` | Admin / provider app notes |

---

*End of document.*
