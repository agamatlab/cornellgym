# RedGym

[Demo Video](https://youtu.be/JQS2jVGyl3s?si=Ub-RGouNtGukeGf_)

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

# BackEnd


## Authentication

The cornerstone of CornellGym’s backend is its **Google‐based authentication** flow, which I prioritized because it provides robust identity verification without forcing users through additional registration screens.

On the **frontend**, I imported Google’s official iOS SDK directly from GitHub. That handles the user interface and OAuth handshake for us, so all I needed to do was pass the resulting **Google ID token** to my backend.

On the **backend**, I copied best practices I learned from an in-depth YouTube lecture on Google Sign In:

1. **Rate-Limiting Duplicate Logins**
   I used a `@rate_limit_auth` decorator that tracks recent auth attempts per email in memory. If the same email hits `/api/google-login/` again within a cooldown window (3 seconds), we simply return the *existing* session token rather than re-verifying with Google. This both protects Google’s token-verification endpoint from bursts of duplicate requests and gives a snappier UX.

2. **Token Verification & User Provisioning**

   * In `/api/google-login/`, we extract the `google_id_token` from the POST body.
   * In production mode, we call Google’s OAuth2 library (`id_token.verify_oauth2_token`) with our **GOOGLE\_CLIENT\_ID** to confirm the token’s validity and pull the user’s email, given\_name, and family\_name.
   * In debug mode, we bypass real verification and accept a `test_mode` flag—this let me iterate quickly during development.

3. **Session & Update Tokens**
   Once a token is verified:

   * We look up the `User` by email (creating a new record if none exists).
   * We generate two UUIDv4 strings:

     * `session_token` (used for all subsequent API calls)
     * `update_token` (used to renew an expired session without forcing a full re-login)
   * We set `session_expiration = now + 1 day`.
   * We save those values in the user’s database row and return them in the JSON response.

4. **Stateless Protection for All Endpoints**
   A `@user_authentication_required` decorator then guards every other protected route. It:

   * Reads the `Authorization: Bearer <session_token>` header.
   * Verifies that token exists in the database and hasn’t expired.
   * Looks up the corresponding `User` and passes it into the route handler.
   * Returns a 401 error if the token is missing, invalid, or expired.

---

## Database Models & Relationships

I designed each SQLAlchemy model to mirror the needs of the SwiftUI frontend:

* **User**

  * Stores `username`, `email`, `password_hash` (for fallback local login), plus `first_name` and `last_name` (populated from Google).
  * Holds `session_token`, `session_expiration`, and `update_token` for stateless auth.
  * Defines relationships:

    * One-to-many to **Workout** (creations)
    * Many-to-many to **Workout** (saved workouts)
    * One-to-one to **WeeklyWorkout** (the user’s calendar plan)

* **Exercise**

  * Captures metadata—`bodyPart`, `equipment`, `gifUrl`, `name`, `target`.
  * Stores `secondaryMuscles` and `instructions` as JSON-encoded text.
  * Provides helper methods `get_secondary_muscles()`, `get_instructions()`, and `serialize()` to return a JSON-ready dict.

* **Workout**

  * Records a session’s `name`, `description`, `duration`, and author (`created_by`).
  * Keeps two JSON columns:

    1. `exercises` → list of exercise IDs
    2. `exercise_plan` → map of exercise ID → details (sets, reps, weight, etc.)
  * Methods like `add_exercise()`, `remove_exercise()`, and `get_exercises_with_details()` let me mutate or fully hydrate the workout on demand.

* **WeeklyWorkout**

  * Bundles seven foreign keys (Monday through Sunday) to link each day of the week to a specific `Workout`.
  * Includes a `week_start_date` to anchor the plan in time.

* **Post**

  * Enables a simple social feed: each post has `title`, `content`, author, and an optional link to a `Workout` or `WeeklyWorkout`.

All models inherit from SQLAlchemy’s `db.Model`, and I call `db.create_all()` on startup to ensure the SQLite schema is in place.

---

## CRUD Endpoints

With authentication and models in place, I exposed a full REST API:

* **User Routes**

  * `/api/register/` (POST): create a new username/password user and issue tokens.
  * `/api/login/` (POST): local login with username + password.
  * `/api/google-login/` (POST): social login with ID token.
  * `/api/session/` (POST): renew session via `update_token`.
  * `/api/logout/` (POST): clear tokens and end session.
  * `/api/user/` (GET): fetch current user profile.

* **Exercise Routes**

  * `/api/exercises/` (GET/POST): list or create exercises.
  * `/api/exercises/<id>` (GET): single exercise by ID.

* **GIF Delivery**

  * `/api/gifs/<gif_id>/` (GET): serves `gif_id.gif` from a local directory.

* **Workout Routes**

  * `/api/workouts/` (GET/POST): list or create workouts.
  * `/api/workouts/<id>/` (GET/PUT/DELETE): retrieve, update, or delete—protected so only the creator may modify.

* **WeeklyWorkout Routes**

  * `/api/weekly-workouts/` (GET/POST): list or create a week plan.
  * `/api/weekly-workouts/<id>/` (GET/PUT/DELETE): manage a specific plan—protected by ownership.

* **Social Post Routes**

  * `/api/posts/` (GET/POST): list or create posts.
  * `/api/posts/<id>/` (GET/PUT/DELETE): manage a specific post—only the author may modify or delete.

Each protected route is decorated with `@user_authentication_required`. Unprotected “GET all” routes are open so the frontend can display public catalogs (exercises, workouts, posts).

---

## Dining Recommendations (OpenAI Integration)

Beyond workouts, I built a **`/api/dining/top-meals/`** endpoint that:

1. Authenticates the user.
2. Fetches campus dining menus via my helper module.
3. Sends a custom prompt—including the user’s goal (“cutting” or “bulking”)—to OpenAI’s GPT model.
4. Returns the top-10 meal recommendations as a Markdown-formatted string.

All API keys (Google and OpenAI) live in environment variables, keeping secrets out of source control.

---

# Full API Specification
> **ℹ️ Information**  
> Most of the endpoints implemented are currently unused by the front-end. They’re included here for completeness but may need further review.

## Authentication Endpoints

1. **Register a new account**

   * **Request**:

     * **Method & URL**: `POST /api/register/`
     * **Body**:

       ```json
       {
         "username":   "myusername",
         "email":      "me@example.com",
         "password":   "s3cret",
         "first_name": "My",
         "last_name":  "Name"
       }
       ```
   * **Response**:

     * **201 Created** with JSON:

       ```json
       {
         "id": 42,
         "username": "myusername",
         "email": "me@example.com",
         "first_name": "My",
         "last_name": "Name",
         "session_token": "550e8400-e29b-41d4-a716-446655440000",
         "session_expiration": "2025-05-04T12:34:56",
         "update_token": "123e4567-e89b-12d3-a456-426614174000"
       }
       ```
     * **400 Bad Request** if I omit any required field or use a taken username/email:

       ```json
       { "error": "Username is already taken" }
       ```

2. **Log in with username & password**

   * **Request**:

     * **Method & URL**: `POST /api/login/`
     * **Body**:

       ```json
       {
         "username": "myusername",
         "password": "s3cret"
       }
       ```
   * **Response**:

     * **200 OK** returns the same JSON shape as registration (new tokens).
     * **401 Unauthorized** if credentials are wrong:

       ```json
       { "error": "Invalid username or password" }
       ```

3. **Log in with Google**

   * **Request**:

     * **Method & URL**: `POST /api/google-login/`
     * **Body**:

       ```json
       {
         "google_id_token": "<ID-TOKEN-FROM-FRONTEND>"
       }
       ```
   * **Response**:

     * **200 OK** returns user data + tokens (same shape as above).
     * **401 Unauthorized** if Google rejects the token:

       ```json
       { "error": "Invalid Google ID token: <detail>" }
       ```

4. **Refresh my session**

   * **Request**:

     * **Method & URL**: `POST /api/session/`
     * **Body**:

       ```json
       { "update_token": "123e4567-e89b-12d3-a456-426614174000" }
       ```
   * **Response**:

     * **200 OK** with fresh `session_token`, `session_expiration`, and new `update_token`.
     * **401 Unauthorized** if my `update_token` is invalid.

5. **Log out**

   * **Request**:

     * **Method & URL**: `POST /api/logout/`
     * **Headers**: `Authorization: Bearer <my session_token>`
   * **Response**:

     * **200 OK**:

       ```json
       { "message": "Successfully logged out" }
       ```
     * **401 Unauthorized** if token is missing/expired.

---

## User Management

6. **Get my profile**

   * **Request**:

     * **Method & URL**: `GET /api/user/`
     * **Headers**: `Authorization: Bearer <session_token>`
   * **Response**:

     * **200 OK**:

       ```json
       {
         "id": 42,
         "username": "myusername",
         "email": "me@example.com",
         "first_name": "My",
         "last_name": "Name",
         "created_at": "2025-05-01T08:00:00"
       }
       ```

7. **List all users**

   * **Request**: `GET /api/users/` with my auth header.
   * **Response**:

     * **200 OK**: array of user objects (same shape as above).

8. **Get any user by ID**

   * **Request**: `GET /api/users/{user_id}/` with auth.
   * **Response**:

     * **200 OK**: that user’s object.
     * **404 Not Found** if no such user.

9. **Update my name**

   * **Request**:

     * **Method & URL**: `PUT /api/users/{my_id}/`
     * **Headers**: auth
     * **Body**: any of:

       ```json
       { "first_name": "NewFirst", "last_name": "NewLast" }
       ```
   * **Response**:

     * **200 OK**: updated user.
     * **403 Forbidden** if I try to update someone else.

10. **Delete my account**

    * **Request**: `DELETE /api/users/{my_id}/` with auth.
    * **Response**:

      * **200 OK**:

        ```json
        { "message": "User deleted successfully" }
        ```
      * **403** if I target another user.

---

## Exercises & GIFs

11. **Create an exercise**

    * **Request**:

      * **Method & URL**: `POST /api/exercises/`
      * **Headers**: auth
      * **Body**:

        ```json
        {
          "bodyPart": "chest",
          "equipment": "barbell",
          "gifUrl": "/api/gifs/12/",
          "name": "bench press",
          "target": "pectorals",
          "secondaryMuscles": ["triceps", "delts"],
          "instructions": [
            "Lie on bench",
            "Grip barbell",
            "Press up"
          ]
        }
        ```
    * **Response**:

      * **201 Created**: the serialized exercise:

        ```json
        {
          "id": 12,
          "bodyPart": "chest",
          "equipment": "barbell",
          "gifUrl": "/api/gifs/12/",
          "name": "bench press",
          "target": "pectorals",
          "secondaryMuscles": ["triceps","delts"],
          "instructions": ["Lie on bench","Grip barbell","Press up"]
        }
        ```

12. **List all exercises**

    * **Request**: `GET /api/exercises/`
    * **Response**:

      * **200 OK**: array of exercises.
      * **404** if none exist.

13. **Get one exercise**

    * **Request**: `GET /api/exercises/{id}`
    * **Response**:

      * **200**: that exercise.
      * **404** if not found.

14. **Serve exercise GIF**

    * **Request**: `GET /api/gifs/{gif_id}/`
    * **Response**:

      * The `.gif` file.
      * **404** JSON error if missing.

---

## Workouts & Weekly Plans

15. **Create a workout**

    * **Request**:

      * **Method & URL**: `POST /api/workouts/`
      * **Headers**: auth
      * **Body**:

        ```json
        {
          "name": "Full Body Blast",
          "description": "A total-body circuit",
          "duration": 45,
          "exercises": [12, 13, 14],
          "exercise_plan": {
            "12": { "sets": 3, "reps": 10 },
            "13": { "sets": 2, "reps": 15 }
          }
        }
        ```
    * **Response**:

      * **201**: the new workout with its ID and my user ID.

16. **List all workouts**

    * **Request**: `GET /api/workouts/`
    * **Response**:

      * **200**: array of workouts, each including `exercises` (array) and `exercise_plan` (object).

17. **Get a workout**

    * **Request**: `GET /api/workouts/{id}/`
    * **Response**:

      * **200**: that workout.
      * **404** if missing.

18. **Update my workout**

    * **Request**:

      * **Method & URL**: `PUT /api/workouts/{id}/`
      * **Headers**: auth
      * **Body**: any fields I want to change.
    * **Response**:

      * **200** updated workout or **403** if I’m not the creator.

19. **Delete my workout**

    * **Request**: `DELETE /api/workouts/{id}/` with auth.
    * **Response**:

      * **200** message or **403** if unauthorized.

20. **Create/replace my weekly plan**

    * **Request**:

      * **Method & URL**: `POST /api/weekly-workout/`
      * **Headers**: auth
      * **Body**:

        ```json
        {
          "week_start_date": "2025-05-05",
          "monday_id": 5,
          "wednesday_id": 7
        }
        ```
      * Omit any day I don’t want to set; defaults to today for `week_start_date` if I leave it out.
    * **Response**:

      * **201 Created**:

        ```json
        { "id": 3, "message": "Weekly workout plan created successfully." }
        ```

21. **List all weekly plans**

    * **Request**: `GET /api/weekly-workouts/`
    * **Response**: **200** list of plans with each day’s workout IDs.

22. **Get a weekly plan**

    * **Request**: `GET /api/weekly-workouts/{id}/`
    * **Response**:

      * **200** plan object or **404** if not found.

23. **Update my weekly plan**

    * **Request**:

      * **Method & URL**: `PUT /api/weekly-workouts/{id}/`
      * **Headers**: auth
      * **Body**: any subset of `monday_id`…`sunday_id`.
    * **Response**:

      * **200** updated plan or **403** if I don’t own it.

24. **Delete my weekly plan**

    * **Request**: `DELETE /api/weekly-workouts/{id}/` with auth.
    * **Response**:

      * **200** message or **403** if unauthorized.

---

## Posts

25. **List all posts**

    * **Request**: `GET /api/posts/`
    * **Response**: **200** array of posts (with `workout_id` and `weekly_workout_id`).

26. **Get a post**

    * **Request**: `GET /api/posts/{id}/`
    * **Response**: **200** the post or **404** if missing.

27. **Create a post**

    * **Request**:

      * **Method & URL**: `POST /api/posts/`
      * **Headers**: auth
      * **Body**:

        ```json
        {
          "title": "My Workout Notes",
          "content": "Felt great today!",
          "workout_id": 5,
          "weekly_workout_id": 3
        }
        ```
    * **Response**:

      * **201** new post or **400** if I omit `title`.

28. **Update my post**

    * **Request**: `PUT /api/posts/{id}/` with auth + any fields to change.
    * **Response**: **200** updated or **403** if I didn’t author it.

29. **Delete my post**

    * **Request**: `DELETE /api/posts/{id}/` with auth.
    * **Response**: **200** message or **403** if unauthorized.

---

## Dining Recommendations

30. **Get top meals**

    * **Request**:

      * **Method & URL**: `POST /api/dining/top-meals/`
      * **Headers**: auth
      * **Body**: optional `{ "goal": "cutting" }` or `"bulking"`.
    * **Response**:

      * **200**:

        ```json
        { "recommendations": [/* up to 10 meal objects */] }
        ```
      * **500** on server errors.

---

## Data Models & Relationships

* **Users**

  * I store `username`, `email`, `password_hash`, `first_name`, `last_name`, timestamps, plus my `session_token` and `update_token`.
  * **One-to-One** → **WeeklyWorkout** via `User.weekly_workout_id`.
  * **One-to-Many** → **Workout.created\_by** (I create workouts).
  * **Many-to-Many** ↔ **Workout** through `user_workout` association (I can save others’ workouts).

* **WeeklyWorkout**

  * Holds a `week_start_date` and seven foreign keys (`monday_id`…`sunday_id`) each pointing to a **Workout**.
  * Backrefs let me do `weekly_workout.monday_workout`, etc., and `user.weekly_workout`.

* **Workout**

  * I record `name`, `description`, `duration`, `created_by` (FK → User).
  * I keep two JSON blobs:

    * `exercises`: an array of exercise IDs
    * `exercise_plan`: a map from exercise ID → `{ reps, sets, … }`
  * Helpers let me load full **Exercise** objects and merge in plan details.

* **Exercise**

  * Independent table of exercises with `bodyPart`, `equipment`, `gifUrl`, `name`, `target`, plus JSON-string fields for `secondaryMuscles` and `instructions`.

* **Post**

  * I store `title`, `content`, `created_by` (FK → User), optional `workout_id` and `weekly_workout_id`.
  * Backrefs let me navigate `post.author`, `post.workout`, and `post.weekly_workout`.

---

