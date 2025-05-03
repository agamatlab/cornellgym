# RedGym

---

## Authentication & Profile Login

The entry point of the app is the **login screen**, which leverages Google Sign-In to authenticate users. I chose Google over Apple Sign-In to avoid the additional annual Apple Developer Program fee, and because our backend runs on Google Cloud, integrating Google’s official SDK was straightforward.

Behind the scenes, an `AuthManager` singleton handles every aspect of session management:

1. **Session Creation**
   When the user successfully logs in, I generate a unique session token and store it alongside the Google-provided user data (ID, email, first name, last name, profile picture URL) in `UserDefaults`. This persistence ensures that on subsequent launches, the app can silently restore the user’s session without re-prompting for credentials.

2. **Session Restoration**
   On startup, `AuthManager.checkSavedCredentials()` checks `UserDefaults` for an existing token. If found, it marks the user as authenticated and populates all published user properties. The UI then bypasses the login screen and proceeds directly to the main tab view.

3. **Logout Flow**
   Signing out calls `GIDSignIn.sharedInstance.signOut()`, clears all saved keys from `UserDefaults` (including the session token), and resets the authentication flag. SwiftUI reacts by sending the user back to the login screen.

Visually, my login page blends several WWDC 2024 inspirations—mesh gradients, dynamic text-reveal animations, and custom shaders—to provide an engaging first impression.

---

## Global State with `UserModel`

Once authenticated, the app relies on a single shared `UserModel` (injected via `.environmentObject`) to drive personalized content:

* **User Identity**: name, email, and ID are exposed throughout the app so that views like the Profile screen and Social feed can display the correct information.
* **Workout Schedule**: a seven-day dictionary maps each weekday to a default workout type (e.g., Monday → “Chest”). This schedule is editable at runtime and saved back to `UserDefaults`, enabling the Weekly Planner to always reflect the user’s preferences.
* **Selected Context**: transient state—such as which muscle group the user is currently viewing—also lives here, ensuring consistency across navigations.

By centralizing all user-specific data in `UserModel`, I avoid passing state manually between dozens of views, simplifying both development and maintenance.

---

## Networking Layer & Exercise Management

At the heart of the app’s data fetching sits the `ExerciseService` singleton. It communicates with our REST API (hosted on Google Cloud) to retrieve exercise metadata and handles a surprising wrinkle: **string-based IDs**.

### Handling String IDs

Our API returns exercise identifiers as arbitrary strings, but the GIF endpoint expects an integer path component. Because reworking the backend was infeasible late in development, I implemented a **stable ID mapping** on the client:

1. **First Encounter**
   When an exercise is fetched, if its string ID has no mapping, `getSequentialId(for:)` assigns the next available integer and records it in a dictionary.
2. **Persistence**
   Both the mapping dictionary and the next-index counter are saved to `UserDefaults`, ensuring identical assignments across app launches.
3. **Usage**
   Whenever I build a GIF URL—e.g. `http://…/api/gifs/3/`—I call `getSequentialId` to guarantee I reference the correct image.

Beyond ID management, `ExerciseService` exposes two primary methods:

* `fetchAllExercises(completion:)` pulls the full list from `/api/exercises/`, decodes it into `[Exercise]`, assigns any new IDs, and returns the results via a completion handler.
* `fetchExercise(byId:completion:)` fetches a single exercise by its string ID.

Error handling is consolidated in a helper that attempts to decode any `{ message, code }` payload into an `APIError` before wrapping it in an `NSError` for the UI to display.

---

## Core Data Models

### `Exercise`

Each exercise is modeled as:

```swift
struct Exercise: Codable, Identifiable {
  var id: String                 // fallback: a name-derived slug
  let bodyPart, equipment, name, target, gifUrl: String
  let secondaryMuscles, instructions: [String]
}
```

* **Custom Decoding**: the initializer gracefully handles missing fields, JSON-encoded strings for arrays, and generates a slug ID when none is provided.
* **Identifiable**: letting SwiftUI uniquely diff lists of exercises by `id`.

### Social & Workout Entities

* **`WorkoutDay`** bundles a workout type (e.g. “Legs”) with an array of `Exercise` objects.
* **`WorkoutPost`** represents an anonymous social post: it contains a `WorkoutDay`, along with metadata like title, description, and likes.

These models power both the Weekly Planner and the Social Feed.

---

## UI Composition

### Custom Tab Bar

I replaced SwiftUI’s default tab bar with a custom `CustomTabBar` overlay. It uses `matchedGeometryEffect` to animate the background behind the selected icon and integrates seamlessly with a `TabView` in page style, allowing horizontal swipes between screens.

### Exercise Library Screen

In `MuscleSelectionWithPreviewView`, I present the full exercise catalog with:

* **Search Field** and **Filter Panels** (Body Part, Equipment, Target Muscle). Toggling filters is done with a smooth animation that shows or hides the filter controls.
* **Real-time Filtering**: the computed property `filteredExercises` applies your search text and any selected filters. SwiftUI re-renders the list automatically whenever those state variables change.
* **Loading, Error, and Empty States**: each has its own dedicated view so the user knows exactly what’s happening.
* **Exercise Cards**: each card displays a looping GIF (via `AnimatedImage` from SDWebImageSwiftUI) plus summary metadata. Tapping a card sets `selectedExercise` and flips a boolean, which activates a completely hidden `NavigationLink` to push the detailed view onto the navigation stack.

### Weekly Workout & Social Feed

The **WeeklyPlanner** is split into two modes:

1. **My Plan**

   * A horizontally scrolling row of **DayButtons** selects Monday through Sunday.
   * Below that, you either see the current day’s workout type (editable via a `Picker`) or the list of exercises added to that day.
   * An **Add** button brings up the `ExerciseSelectorView` sheet, where you can search and pick any exercise. Selections are appended to the day’s list, persisted to `UserDefaults`, and (optionally) synced to the backend.

2. **Social**

   * Displays a feed of anonymous `WorkoutPostCard` entries fetched from `/api/posts/`. Each card shows the post’s title, description, and the exercises included.
   * A **Save to My Plan** button on each card invokes an `ActionSheet` that lets you import that shared workout into any weekday of your choice.

When you **share** your own daily plan, the app posts first to `/api/workouts/`, then to `/api/posts/` to create a social entry. On success, a temporary banner animates in to confirm the share.

### Profile & Settings

Finally, the **ProfileView** shows your Google avatar and first name, along with placeholder sections for account and app settings. A **Logout** button ties back to `AuthManager.logout()`, cleaning your session and returning to the animated login page.

---

## Persistence & Animations

* **`UserDefaults`** stores:
  • Session token and Google user info
  • The user’s weekly exercise map (`dayExercises`)
  • The stable ID mapping for exercises
* **Animations**:
  • `matchedGeometryEffect` for the tab bar
  • SwiftUI transitions on banners, filter panels, and sheets
  • WWDC-inspired mesh gradients and text-reveal on the login screen

By combining a robust networking layer, flexible state management in `UserModel`, and a rich set of SwiftUI views with custom animations, CornellGym delivers a polished, user-driven fitness app experience.
Thought for a couple of seconds


## CornellGym iOS App Architecture

This documentation describes the overall structure and key components of the CornellGym SwiftUI application. You’ll find an in-depth look at how authentication, state management, networking, data modeling, and UI composition come together to deliver a seamless fitness experience.

---

## Authentication & Profile Login

The entry point of the app is the **login screen**, which leverages Google Sign-In to authenticate users. I chose Google over Apple Sign-In to avoid the additional annual Apple Developer Program fee, and because our backend runs on Google Cloud, integrating Google’s official SDK was straightforward.

Behind the scenes, an `AuthManager` singleton handles every aspect of session management:

1. **Session Creation**
   When the user successfully logs in, I generate a unique session token and store it alongside the Google-provided user data (ID, email, first name, last name, profile picture URL) in `UserDefaults`. This persistence ensures that on subsequent launches, the app can silently restore the user’s session without re-prompting for credentials.

2. **Session Restoration**
   On startup, `AuthManager.checkSavedCredentials()` checks `UserDefaults` for an existing token. If found, it marks the user as authenticated and populates all published user properties. The UI then bypasses the login screen and proceeds directly to the main tab view.

3. **Logout Flow**
   Signing out calls `GIDSignIn.sharedInstance.signOut()`, clears all saved keys from `UserDefaults` (including the session token), and resets the authentication flag. SwiftUI reacts by sending the user back to the login screen.

Visually, my login page blends several WWDC 2024 inspirations—mesh gradients, dynamic text-reveal animations, and custom shaders—to provide an engaging first impression.

---

## Global State with `UserModel`

Once authenticated, the app relies on a single shared `UserModel` (injected via `.environmentObject`) to drive personalized content:

* **User Identity**: name, email, and ID are exposed throughout the app so that views like the Profile screen and Social feed can display the correct information.
* **Workout Schedule**: a seven-day dictionary maps each weekday to a default workout type (e.g., Monday → “Chest”). This schedule is editable at runtime and saved back to `UserDefaults`, enabling the Weekly Planner to always reflect the user’s preferences.
* **Selected Context**: transient state—such as which muscle group the user is currently viewing—also lives here, ensuring consistency across navigations.

By centralizing all user-specific data in `UserModel`, I avoid passing state manually between dozens of views, simplifying both development and maintenance.

---

## Networking Layer & Exercise Management

At the heart of the app’s data fetching sits the `ExerciseService` singleton. It communicates with our REST API (hosted on Google Cloud) to retrieve exercise metadata and handles a surprising wrinkle: **string-based IDs**.

### Handling String IDs

Our API returns exercise identifiers as arbitrary strings, but the GIF endpoint expects an integer path component. Because reworking the backend was infeasible late in development, I implemented a **stable ID mapping** on the client:

1. **First Encounter**
   When an exercise is fetched, if its string ID has no mapping, `getSequentialId(for:)` assigns the next available integer and records it in a dictionary.
2. **Persistence**
   Both the mapping dictionary and the next-index counter are saved to `UserDefaults`, ensuring identical assignments across app launches.
3. **Usage**
   Whenever I build a GIF URL—e.g. `http://…/api/gifs/3/`—I call `getSequentialId` to guarantee I reference the correct image.

Beyond ID management, `ExerciseService` exposes two primary methods:

* `fetchAllExercises(completion:)` pulls the full list from `/api/exercises/`, decodes it into `[Exercise]`, assigns any new IDs, and returns the results via a completion handler.
* `fetchExercise(byId:completion:)` fetches a single exercise by its string ID.

Error handling is consolidated in a helper that attempts to decode any `{ message, code }` payload into an `APIError` before wrapping it in an `NSError` for the UI to display.

---

## Core Data Models

### `Exercise`

Each exercise is modeled as:

```swift
struct Exercise: Codable, Identifiable {
  var id: String                 // fallback: a name-derived slug
  let bodyPart, equipment, name, target, gifUrl: String
  let secondaryMuscles, instructions: [String]
}
```

* **Custom Decoding**: the initializer gracefully handles missing fields, JSON-encoded strings for arrays, and generates a slug ID when none is provided.
* **Identifiable**: letting SwiftUI uniquely diff lists of exercises by `id`.

### Social & Workout Entities

* **`WorkoutDay`** bundles a workout type (e.g. “Legs”) with an array of `Exercise` objects.
* **`WorkoutPost`** represents an anonymous social post: it contains a `WorkoutDay`, along with metadata like title, description, and likes.

These models power both the Weekly Planner and the Social Feed.

---

## UI Composition

### Custom Tab Bar

I replaced SwiftUI’s default tab bar with a custom `CustomTabBar` overlay. It uses `matchedGeometryEffect` to animate the background behind the selected icon and integrates seamlessly with a `TabView` in page style, allowing horizontal swipes between screens.

### Exercise Library Screen

In `MuscleSelectionWithPreviewView`, I present the full exercise catalog with:

* **Search Field** and **Filter Panels** (Body Part, Equipment, Target Muscle). Toggling filters is done with a smooth animation that shows or hides the filter controls.
* **Real-time Filtering**: the computed property `filteredExercises` applies your search text and any selected filters. SwiftUI re-renders the list automatically whenever those state variables change.
* **Loading, Error, and Empty States**: each has its own dedicated view so the user knows exactly what’s happening.
* **Exercise Cards**: each card displays a looping GIF (via `AnimatedImage` from SDWebImageSwiftUI) plus summary metadata. Tapping a card sets `selectedExercise` and flips a boolean, which activates a completely hidden `NavigationLink` to push the detailed view onto the navigation stack.

### Weekly Workout & Social Feed

The **WeeklyPlanner** is split into two modes:

1. **My Plan**

   * A horizontally scrolling row of **DayButtons** selects Monday through Sunday.
   * Below that, you either see the current day’s workout type (editable via a `Picker`) or the list of exercises added to that day.
   * An **Add** button brings up the `ExerciseSelectorView` sheet, where you can search and pick any exercise. Selections are appended to the day’s list, persisted to `UserDefaults`, and (optionally) synced to the backend.

2. **Social**

   * Displays a feed of anonymous `WorkoutPostCard` entries fetched from `/api/posts/`. Each card shows the post’s title, description, and the exercises included.
   * A **Save to My Plan** button on each card invokes an `ActionSheet` that lets you import that shared workout into any weekday of your choice.

When you **share** your own daily plan, the app posts first to `/api/workouts/`, then to `/api/posts/` to create a social entry. On success, a temporary banner animates in to confirm the share.

### Profile & Settings

Finally, the **ProfileView** shows your Google avatar and first name, along with placeholder sections for account and app settings. A **Logout** button ties back to `AuthManager.logout()`, cleaning your session and returning to the animated login page.

---
