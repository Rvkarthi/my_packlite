================================================================================
                     PACKLITE APP - FEATURES DOCUMENTATION
================================================================================

================================================================================
1. BOTTOM NAVIGATION BAR ITEMS
================================================================================

| #  | Label    | Icon                           | Route         |
|---|---------|-------------------------------|--------------|
| 0 | Home    | Icons.home_rounded              | /            |
| 1 | Trips   | Icons.luggage_rounded          | /trips       |
| 2 | Tasks   | Icons.check_circle_outline_rounded | /todo    |
| 3 | Containers | Icons.inventory_2_rounded   | /containers  |
| 4 | AI Chat | Icons.auto_awesome_rounded    | /chat        |


================================================================================
2. DRAWER MENU ITEMS
================================================================================

| Item           | Icon                      | Action           |
|----------------|---------------------------|------------------|
| Profile        | Icons.person_rounded     | Navigate to /profile |
| Group Packing  | Icons.group_rounded      | Navigate to /group   |
| All Settings   | Icons.settings_rounded   | Navigate to /settings|
| Sign Out       | Icons.logout_rounded     | Sign out action    |

DRAWER APPEARANCE SECTION:
- Dark/Light Mode Toggle (switch with animated icon)
- Theme Color Picker (8 preset color schemes - selectable via circle gestures)


================================================================================
3. CORE FEATURES
================================================================================

TRIP MANAGEMENT:
- Create/delete trips
- Add locations to trips
- Individual and Group trip types
- Trip date management
- Trip progress tracking

CONTAINER/BAG MANAGEMENT:
- Add multiple containers per trip
- Color-coded containers
- Add items/objects to containers
- Categorize items:
  * General
  * Clothing
  * Electronics
  * Toiletries
  * Documents
  * Food & Snacks
  * Medicine
  * Accessories
  * Other
- Quantity tracking
- Mark items as packed/unpacked
- Move items between containers

TODO/TASK MANAGEMENT:
- Individual tasks (per trip)
- Group tasks (synced via Firebase)
- Progress indicator
- Complete/incomplete toggle
- Edit/delete tasks (slidable actions)

GROUP PACKING (COLLABORATIVE):
- Create group from existing trip
- Share 6-digit invite code
- Join group with code
- Firebase-synced group containers
- Firebase-synced group tasks

DATA & SYNC:
- Local-first SQLite database
- Firebase Cloud Firestore sync
- Offline capable


================================================================================
4. AI FEATURES
================================================================================

A. ON-DEVICE AI CHAT (GEMMA 3 1B):
- Model: Gemma 3 1B (int4 quantized)
- Size: ~700MB download
- Source: HuggingFace (no API token needed)
- Running: Fully on-device
- Offline: Yes (after first download)
- Backend: GPU preferred

Capabilities:
- Travel assistant chat
- Packing advice
- Travel tips
- Destination recommendations
- Streaming responses
- Clear chat history
- Suggestion chips for quick queries

Model Status States:
- Idle: "Tap to load model"
- Downloading: Shows progress percentage
- Loading: Initializing model
- Ready: "Gemma 3 1B - On-device"
- Error: Error message display


B. RULE-BASED OFFLINE AI SUGGESTIONS:
- Type: Deterministic rule-based engine
- Dataset: Local JSON at assets/data/ai_dataset.json
- Network calls: None
- Suggestion types: Location-based, weather-based, trip-type-based

Inputs:
- Location name
- Temperature (Celsius)
- Weather condition
- Trip type

Outputs:
- Suggested places to visit
- Suggested packing items
- Reasoning for suggestions


C. WEATHER SERVICE:
- Provider: Open-Meteo API (free, no API key)
- Geocoding: Yes
- Data: Temperature, weather code, condition
- Icon mapping: Weather emoji mapping


================================================================================
5. SCREENS AND THEIR FEATURES
================================================================================

A. HOME SCREEN (/)
-----------------
- App bar with menu/drawer trigger
- PackLite branding
- Profile button
- Weather card (current location weather)
- Group actions row:
  * Create Group button
  * Join Group button (6-digit code entry)
- Group invites banner (shows joined groups)
- Recent trips list with weather info
- Trip cards showing:
  * Trip type (INDIVIDUAL/GROUP badge)
  * Trip title
  * Locations
  * Weather for location
  * Dates
  * Packing progress


B. TRIPS SCREEN (/trips)
-----------------------
- Trip list with trip cards
- Create trip FAB
- Swipe to delete trips
- Individual/group type icons


C. TODO SCREEN (/todo)
---------------------
- Trip selector
- Two tabs:
  * Individual (local tasks)
  * Group (Firebase-synced)
- Add task FAB
- Progress indicator
- Slidable task tiles (edit left, delete right)
- Toggle complete/incomplete


D. CONTAINERS SCREEN (/containers)
---------------------------------
- Trip selector
- Create containers (bags) with custom name and color
- Add items/objects with:
  * Name
  * Description
  * Category selection
  * Quantity
  * Notes
- Assign to container
- Move items between containers
- Mark packed/unpacked
- Item count per container


E. AI CHAT SCREEN (/chat)
-----------------------
- Model load button (~700MB)
- Download progress indicator
- Message bubbles (user & AI)
- Streaming response animation
- Input bar with send button
- Suggestion chips:
  * "What should I pack for a beach trip?"
  * "Packing tips for cold weather"
  * "How to pack light for 2 weeks?"
  * "Essential travel documents checklist"


F. SETTINGS SCREEN (/settings)
----------------------------
- Dark mode toggle
- Sync status display
- Local database info
- Push notifications toggle
- Version info (1.0.0)
- Privacy policy link


G. OTHER SCREENS
---------------
- Login (/login) - Firebase auth
- Signup (/signup) - Firebase auth
- Create Trip (/trips/create)
- Trip Detail (/trips/:id)
- Packing (/trips/:id/packing)
- Profile (/profile)
- Group (/group)
- Join Group (/group/join)
- Group Todos (/group/:groupId/todos)
- Group Containers (/group/:groupId/containers)


================================================================================
6. TECH STACK & DEPENDENCIES
================================================================================

Flutter Packages:
- flutter_riverpod (State management)
- go_router (Navigation)
- firebase_core, firebase_auth, cloud_firestore (Backend/Auth)
- sqflite (Local SQLite database)
- flutter_gemma (On-device AI - Gemma)
- google_nav_bar (Bottom navigation)
- flutter_slidable (Swipe actions)
- http (Weather API calls)
- geolocator (Location services)
- intl (Date formatting)
- gap (Spacing utilities)


================================================================================
7. APP SUMMARY
================================================================================

App Name:    PackLite
Version:    1.0.0
Firebase:   Enabled
Local DB:   SQLite
AI Model:   Gemma 3 1B (int4)
Theme:      Material 3 with custom colors
Architecture: Clean Architecture (data/domain/presentation)

Key Highlights:
- True offline AI chat using Gemma 3 1B running on-device
- Collaborative group packing via Firebase
- Comprehensive trip/container/task management
- Local-first SQLite database with optional cloud sync

================================================================================