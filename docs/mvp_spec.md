# MapAnytime: MVP Specification & Evaluation

This document defines the Minimum Viable Product (MVP) scope for MapAnytime. It strips away complex systems (payments, real AI, authentication) to focus entirely on validating the two core hypotheses: **Map-based discovery** and **sub-30-second merchant onboarding**.

---

## 1. Core Concept & Objectives
This is a pickup-only, map-native micro-commerce system.
**Primary Validation Goals:**
1. Merchant-side instant product creation (photo → listing).
2. Map-based local discovery for buyers.
3. Basic inventory status tracking (Available / Reserved / Sold).

---

## 2. App Structure (3 Core Tabs)

### Tab 1: Map (Home)
The default buyer discovery interface.
* **Map Engine**: Google Maps (currently integrated via `google_maps_flutter`).
* **Visuals**: Displays nearby product pins (clustered for performance).
* **Interaction**: Tapping a pin opens a bottom sheet showing:
  * Product Image
  * Title & Price
  * Distance from user
  * Status (Available / Reserved)
  * **Action**: "Reserve for Pickup" button.

### Tab 2: Add Product (Merchant Flow)
The core seller acquisition loop.
* **Input**: Camera capture or gallery upload. Must capture **GPS Coordinates (Lat/Lng)** at the moment of upload to drop the pin.
* **Simulated AI Processing**: Display a forced 2.5-second loading overlay ("Analyzing image...") to test user patience and expectation.
* **Auto-generated Form**:
  * Title (editable)
  * Description (optional)
  * Price input
  * Category dropdown
* **Publish**: Save directly to local state/Firebase and instantly appear on the map.

### Tab 3: Profile / Inventory
A simplified dashboard assuming a "dual-sided" user for testing (acting as both buyer and seller without auth).
* **List**: All products created by the current device (`mock_user_1`).
* **Management**: Ability to manually toggle status to **SOLD**, edit price, or delete the listing entirely.

---

## 3. Data Model (MVP Schema)
A lightweight JSON or Firebase schema to support the core loop.

```json
User {
  "id": "mock_user_1",
  "name": "Local Vendor",
  "role": "both"
}

Product {
  "id": "prod_123",
  "userId": "mock_user_1",
  "title": "Handmade Clay Mug",
  "description": "Locally fired clay mug",
  "imageUrl": "https://...",
  "price": 15.00,
  "latitude": 40.7128,
  "longitude": -74.0060,
  "status": "available", // available | reserved | sold
  "createdAt": "2026-06-19T10:00:00Z"
}
```

---

## 4. MVP Constraints & Rules
To ensure development velocity, the following are strictly **out of scope** for v1.0:
* **No Payments**: Transactions happen offline. "Reserve" acts as a hold.
* **No Delivery**: Completely pickup-based.
* **No Real AI**: Mock the API response with a delay.
* **No Auth**: Use a hardcoded user ID.

---

## 5. Evaluation & Success Criteria
This MVP is impeccably scoped. By removing payments and logistics, the team can build this in a fraction of the time normally required for a marketplace app.

**The MVP is considered successful if during user testing:**
1. A merchant can create a listing in under 30 seconds with < 3 taps.
2. The listing appears immediately on the map for another device.
3. A buyer successfully identifies a nearby item and reserves it visually.
4. The merchant easily locates the reserved item in their Inventory tab and marks it as SOLD once picked up.
