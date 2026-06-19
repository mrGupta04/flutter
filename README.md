# 1mg Doctors - Registration & Verification

Doctor onboarding: two self-contained **Flutter** apps + **Node.js/Express** API + **MongoDB Atlas**.

## Repository layout

| Path | Purpose |
|------|---------|
| `user_app/` | **1mg Care** - patient marketplace (browse verified doctors & nurses) |
| `admin_app/` | **1mg Admin** - doctor/nurse registration, provider dashboard, admin verification |
| `backend/` | Node.js API (`start-backend.ps1` helper included) |

Each Flutter app is standalone (no shared Dart package). Run `flutter pub get` inside the app directory you are working on.

## Quick start

**Terminal 1 - API**
```powershell
cd backend
npm install
```

Add your MongoDB Atlas URI to `backend/.env` (see below), then:
```powershell
npm start
```

Or from repo root:
```powershell
.\backend\start-backend.ps1
```

**Terminal 2 - User app (1mg Care)**
```powershell
cd user_app
flutter pub get
flutter run
```

**Terminal 3 - Admin app (1mg Admin)**
```powershell
cd admin_app
flutter pub get
flutter run
```

Physical device (either app):
```powershell
flutter run --dart-define=API_BASE_URL=http://YOUR_PC_IP:3000/api/v1
```

### Google Maps (Android)

Add to `user_app/android/local.properties` and `admin_app/android/local.properties`:

```properties
MAPS_API_KEY=your_google_maps_key
```

## MongoDB Atlas setup

1. Go to [MongoDB Atlas](https://cloud.mongodb.com) and create a free cluster.
2. **Database Access** → Add user (username + password).
3. **Network Access** → Add IP Address → your IP (or `0.0.0.0/0` for local dev only).
4. **Connect** → Drivers → copy the connection string.
5. Paste into `backend/.env`:

```env
MONGODB_URI=mongodb+srv://myuser:mypassword@cluster0.xxxxx.mongodb.net/1mg_doctors?retryWrites=true&w=majority
```

Replace `USERNAME`, `PASSWORD`, and cluster host. URL-encode special characters in the password.

Optional sample data:
```powershell
# In .env: SEED_DATABASE=true then npm start
# Or once:
npm run seed
```

## Where data is stored

| Data | Location |
|------|----------|
| Doctors, documents metadata | **MongoDB Atlas** (`1mg_doctors` database) |
| Uploaded files (PDF/images) | `backend/uploads/` on your server |

## Admin login

`backend/.env`:
```env
ADMIN_EMAIL=admin@1mgdoctors.com
ADMIN_PASSWORD=Admin@123456
```

Use the **Admin app** (`cd admin_app` → `flutter run`) → **Admin portal - sign in**, with credentials from `backend/.env`.

## App architecture

| App | Directory | Android ID | Purpose |
|-----|-----------|------------|---------|
| **1mg Care** | `user_app/` | `com.onemg.care` | Patients browse verified doctors & nurses |
| **1mg Admin** | `admin_app/` | `com.onemg.admin` | Registration, provider dashboard, admin verification |

Flow: **Admin app** → register as doctor/nurse → admin verifies → approved profiles appear in **User app**.

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/doctor/register` | Submit application |
| POST | `/api/v1/doctor/upload-document` | Upload document |
| GET | `/api/v1/admin/doctors` | List doctors |
| POST | `/api/v1/admin/login` | Admin sign-in |

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `MONGODB_URI is required` | Add connection string to `backend/.env` |
| Network error in app | `npm start` running? Correct API URL on phone? |
| Atlas connection timeout | Whitelist your IP in Atlas Network Access |
| Plugin symlink warning on Windows | Enable **Developer Mode** in Windows settings |
