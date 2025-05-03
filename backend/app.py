from flask import Flask, send_from_directory, abort, jsonify, request, json
import os
from db import *
import json
from datetime import datetime, timedelta
import uuid
import hashlib
import base64
from google.oauth2 import id_token
from google.auth.transport import requests
import time

from openai import OpenAI
from eatery import *
import requests as http_requests
from functools import wraps

app = Flask(__name__)
db_filename = "cornellgym.db" 
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///%s" % db_filename
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SQLALCHEMY_ECHO"] = True
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-key-for-testing")

# Set your actual Google Client ID - put your actual client ID here
GOOGLE_CLIENT_ID = "567520598057-bv9qpqvcf095rso31u02ubi20j191lu7.apps.googleusercontent.com"

# Dict to track recent auth attempts to prevent duplicates
# Format: {email: last_auth_timestamp}
recent_auth_attempts = {}
AUTH_COOLDOWN_SECONDS = 3  # Minimum seconds between auth attempts for the same user

def rate_limit_auth(func):
    @wraps(func)
    def wrapper(*args, **kwargs):
        try:
            # Get email from request
            if not request.data:
                return failure_response("Empty request body", 400)
            
            body = json.loads(request.data)
            email = body.get("email", "")
            
            # Skip rate limiting if no email available
            if not email:
                return func(*args, **kwargs)
            
            current_time = time.time()
            if email in recent_auth_attempts:
                last_attempt = recent_auth_attempts[email]
                time_diff = current_time - last_attempt
                
                if time_diff < AUTH_COOLDOWN_SECONDS:
                    # This is a duplicate auth attempt, return the existing session
                    print(f"Rate limited auth attempt for {email} - {time_diff:.2f}s since last attempt")
                    user = User.query.filter_by(email=email).first()
                    if user and user.session_token:
                        return success_response({
                            "id": user.id,
                            "username": user.username,
                            "email": user.email,
                            "first_name": user.first_name,
                            "last_name": user.last_name,
                            "session_token": user.session_token,
                            "session_expiration": str(user.session_expiration),
                            "update_token": user.update_token,
                            "note": "Using existing session due to rapid duplicate request"
                        })
            
            # Update the timestamp for this email
            recent_auth_attempts[email] = current_time
            
            # Clean up old entries to prevent memory leaks
            cleanup_old_auth_attempts()
            
            return func(*args, **kwargs)
        except Exception as e:
            print(f"Error in rate limit middleware: {str(e)}")
            # Continue with the regular flow if the rate limiting fails
            return func(*args, **kwargs)
    
    return wrapper

def cleanup_old_auth_attempts():
    """Remove entries older than 1 minute to prevent memory leaks"""
    current_time = time.time()
    cutoff_time = current_time - 60  # 1 minute
    
    keys_to_remove = []
    for email, timestamp in recent_auth_attempts.items():
        if timestamp < cutoff_time:
            keys_to_remove.append(email)
    
    for email in keys_to_remove:
        del recent_auth_attempts[email]

@app.route("/api/google-login/", methods=["POST"])
@rate_limit_auth  # Apply rate limiting to prevent duplicate logins
def google_login():
    try:
        if not request.data:
            return failure_response("Empty request body", 400)
        body = json.loads(request.data)
        
        if "google_id_token" not in body:
            return failure_response("Missing Google ID token", 400)
        
        token = body.get("google_id_token")
        
        # Debug mode for development
        if app.config["DEBUG"] and body.get("test_mode") == "true":
            print("DEBUG MODE: Bypassing token verification")
            email = body.get("email", "test@example.com")
            first_name = body.get("first_name", "Test")
            last_name = body.get("last_name", "User")
            
            # Add request ID for debugging duplicate requests
            request_id = str(uuid.uuid4())[:8]
            print(f"DEBUG MODE: Processing auth request {request_id} for {email}")
            
            # Check if user exists
            user = User.query.filter_by(email=email).first()
            
            if user is None:
                # Create new user if doesn't exist
                user = User(
                    username=email.split("@")[0],  # Use email prefix as username
                    email=email,
                    first_name=first_name,
                    last_name=last_name
                )
                # Set a random password (user will never use it)
                user.set_password(str(uuid.uuid4()))
                db.session.add(user)
            
            # Generate session tokens
            user.session_token = generate_session_token()
            user.session_expiration = datetime.utcnow() + timedelta(days=1)
            user.update_token = generate_update_token()
            
            user.last_login = datetime.utcnow()
            db.session.commit()
            
            print(f"DEBUG MODE: Completed auth request {request_id} for {email}")
            
            return success_response({
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "session_token": user.session_token,
                "session_expiration": str(user.session_expiration),
                "update_token": user.update_token
            })
        
        try:
            # Log for debugging
            print(f"Verifying token with Google Client ID: {GOOGLE_CLIENT_ID}")
            
            # Verify the token
            idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
            
            # Print token info for debugging
            print(f"Token verified successfully. Token info: {idinfo}")
            
            # Get user info from the token
            email = idinfo.get("email")
            if not email:
                return failure_response("Email not found in token", 400)
            
            # Get additional user info from the token
            given_name = idinfo.get("given_name", "")
            family_name = idinfo.get("family_name", "")
            
            # Use provided values as fallback
            first_name = body.get("first_name", given_name)
            last_name = body.get("last_name", family_name)
            
            # Check if user exists
            user = User.query.filter_by(email=email).first()
            
            if user is None:
                # Create new user if doesn't exist
                user = User(
                    username=email.split("@")[0],  # Use email prefix as username
                    email=email,
                    first_name=first_name,
                    last_name=last_name
                )
                # Set a random password (user will never use it)
                user.set_password(str(uuid.uuid4()))
                db.session.add(user)
            else:
                # Update existing user info
                user.first_name = first_name
                user.last_name = last_name
            
            # Generate session tokens
            user.session_token = generate_session_token()
            user.session_expiration = datetime.utcnow() + timedelta(days=1)
            user.update_token = generate_update_token()
            
            user.last_login = datetime.utcnow()
            db.session.commit()
            
            return success_response({
                "id": user.id,
                "username": user.username,
                "email": user.email,
                "first_name": user.first_name,
                "last_name": user.last_name,
                "session_token": user.session_token,
                "session_expiration": str(user.session_expiration),
                "update_token": user.update_token
            })
            
        except ValueError as e:
            # More detailed error message
            error_detail = str(e)
            print(f"Token verification error: {error_detail}")
            return failure_response(f"Invalid Google ID token: {error_detail}", 401)
            
    except Exception as e:
        # Catch any other errors
        print(f"Unexpected error in google_login: {str(e)}")
        return failure_response("Server error processing login", 500)

db.init_app(app)
with app.app_context():
    db.create_all()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
GIF_DIRECTORY = os.path.join(BASE_DIR, "exercise_gifs")

def generate_session_token():
    return str(uuid.uuid4())

def generate_update_token():
    return str(uuid.uuid4())

def extract_token(request):
    auth_header = request.headers.get("Authorization")
    if auth_header is None:
        return None
        
    bearer_token = auth_header.replace("Bearer ", "").strip()
    if bearer_token is None or not bearer_token:
        return None
        
    return bearer_token

def get_user_by_session_token(session_token):
    return User.query.filter_by(session_token=session_token).first()

def get_user_by_update_token(update_token):
    return User.query.filter_by(update_token=update_token).first()

def renew_session(update_token):
    user = get_user_by_update_token(update_token)
    if user is None:
        return None
        
    user.session_token = generate_session_token()
    user.session_expiration = datetime.utcnow() + timedelta(days=1)
    user.update_token = generate_update_token()
    
    db.session.commit()
    return user

def verify_session_token(session_token):
    user = get_user_by_session_token(session_token)
    if user is None:
        return None
        
    if user.session_expiration < datetime.utcnow():
        return None
        
    return user

def user_authentication_required(func):
    def wrapper(*args, **kwargs):
        session_token = extract_token(request)
        if session_token is None:
            return failure_response("Missing session token", 401)
            
        user = verify_session_token(session_token)
        if user is None:
            return failure_response("Invalid session token", 401)
            
        kwargs["user"] = user
        return func(*args, **kwargs)
    
    wrapper.__name__ = func.__name__
    return wrapper

@app.route("/api/register/", methods=["POST"])
def register():
    body = json.loads(request.data)
    
    if not all(k in body for k in ["username", "email", "password", "first_name", "last_name"]):
        return failure_response("Missing required fields", 400)
    
    if User.query.filter_by(username=body.get("username")).first() is not None:
        return failure_response("Username is already taken", 400)
    if User.query.filter_by(email=body.get("email")).first() is not None:
        return failure_response("Email is already registered", 400)
    
    new_user = User(
        username=body.get("username"),
        email=body.get("email"),
        first_name=body.get("first_name"),
        last_name=body.get("last_name")
    )
    new_user.set_password(body.get("password"))
    
    new_user.session_token = generate_session_token()
    new_user.session_expiration = datetime.utcnow() + timedelta(days=1)
    new_user.update_token = generate_update_token()
    
    db.session.add(new_user)
    db.session.commit()
    
    return success_response({
        "id": new_user.id,
        "username": new_user.username,
        "email": new_user.email,
        "first_name": new_user.first_name,
        "last_name": new_user.last_name,
        "session_token": new_user.session_token,
        "session_expiration": str(new_user.session_expiration),
        "update_token": new_user.update_token
    }, 201)

@app.route("/api/login/", methods=["POST"])
@rate_limit_auth  # Also apply rate limiting to regular login
def login():
    body = json.loads(request.data)
    
    if not all(k in body for k in ["username", "password"]):
        return failure_response("Missing username or password", 400)
    
    user = User.query.filter_by(username=body.get("username")).first()
    
    if user is None or not user.check_password(body.get("password")):
        return failure_response("Invalid username or password", 401)
    
    user.session_token = generate_session_token()
    user.session_expiration = datetime.utcnow() + timedelta(days=1)
    user.update_token = generate_update_token()
    
    user.last_login = datetime.utcnow()
    db.session.commit()
    
    return success_response({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "session_token": user.session_token,
        "session_expiration": str(user.session_expiration),
        "update_token": user.update_token
    })

@app.route("/api/session/", methods=["POST"])
def update_session():
    body = json.loads(request.data)
    if "update_token" not in body:
        return failure_response("Missing update token", 400)
        
    user = renew_session(body.get("update_token"))
    if user is None:
        return failure_response("Invalid update token", 401)
        
    return success_response({
        "session_token": user.session_token,
        "session_expiration": str(user.session_expiration),
        "update_token": user.update_token
    })

@app.route("/api/logout/", methods=["POST"])
@user_authentication_required
def logout(user):
    user.session_token = None
    user.session_expiration = None
    user.update_token = None
    db.session.commit()
    
    return success_response({"message": "Successfully logged out"})

@app.route("/api/user/", methods=["GET"])
@user_authentication_required
def get_current_user(user):
    return success_response({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name,
        "created_at": user.created_at.isoformat()
    })

@app.route("/api/weekly-workout/", methods=["POST"])
@user_authentication_required
def create_weekly_workout(user):
    body = json.loads(request.data)
    
    weekly_workout = WeeklyWorkout(
        week_start_date=datetime.strptime(body.get("week_start_date", datetime.utcnow().strftime("%Y-%m-%d")), "%Y-%m-%d").date()
    )
    
    if "monday_id" in body:
        weekly_workout.monday_id = body.get("monday_id")
    if "tuesday_id" in body:
        weekly_workout.tuesday_id = body.get("tuesday_id")
    if "wednesday_id" in body:
        weekly_workout.wednesday_id = body.get("wednesday_id")
    if "thursday_id" in body:
        weekly_workout.thursday_id = body.get("thursday_id")
    if "friday_id" in body:
        weekly_workout.friday_id = body.get("friday_id")
    if "saturday_id" in body:
        weekly_workout.saturday_id = body.get("saturday_id")
    if "sunday_id" in body:
        weekly_workout.sunday_id = body.get("sunday_id")
    
    db.session.add(weekly_workout)
    db.session.flush()
    
    user.weekly_workout_id = weekly_workout.id
    db.session.commit()
    
    return success_response({
        "id": weekly_workout.id,
        "message": "Weekly workout plan created successfully."
    }, 201)

@app.route("/api/exercises/", methods=["POST"])
@user_authentication_required
def create_exercise(user):
    body = json.loads(request.data)
    new_exercise = Exercise(
        bodyPart=body.get("bodyPart"),
        equipment=body.get("equipment"),
        gifUrl=body.get("gifUrl"),
        name=body.get("name"),
        target=body.get("target"),
        secondaryMuscles=body.get("secondaryMuscles"),
        instructions=body.get("instructions")
    )
    db.session.add(new_exercise)
    db.session.commit()
    return success_response(new_exercise.serialize(), 201)

@app.route("/api/exercises/", methods=["GET"])
def get_exercises():
    exercises = Exercise.query.all()
    if exercises is None or len(exercises) == 0:
        return failure_response("No exercises found!")
    serialized_exercises = [exercise.serialize() for exercise in exercises]
    return success_response(serialized_exercises)

@app.route("/api/exercises/<int:exercise_id>", methods=["GET"])
def get_exercise_by_id(exercise_id):
    exercise = Exercise.query.filter_by(id=exercise_id).first()
    if exercise is None:
        return failure_response("Exercise not found!")
    return success_response(exercise.serialize())

@app.route("/api/gifs/<int:gif_id>/", methods=["GET"])
def get_gif(gif_id):
    try:
        filename = f"{gif_id}.gif"
        return send_from_directory(GIF_DIRECTORY, filename)
    except FileNotFoundError:
        return failure_response(f"GIF with ID {gif_id} not found", 404)


@app.route("/api/dining/top-meals/", methods=["POST"])
@user_authentication_required  # Only allow authenticated users
def get_top_meals(user):
    try:
        body = json.loads(request.data)
        goal = body.get("goal", "cutting")
        menus = get_dining_menus()
        
        # Get top meal recommendations
        recommendations = ask_top_meals(menus, goal=goal, top_n=10)
        
        # Return recommendations
        return success_response({
            "recommendations": recommendations
        })
    except Exception as e:
        print(f"Error getting top meals: {str(e)}")
        return failure_response(f"Error getting top meals: {str(e)}", 500)

# User Endpoints
@app.route("/api/users/", methods=["GET"])
@user_authentication_required
def get_all_users(user):
    users = User.query.all()
    return success_response([{
        "id": u.id,
        "username": u.username,
        "email": u.email,
        "first_name": u.first_name,
        "last_name": u.last_name,
        "created_at": u.created_at.isoformat()
    } for u in users])

@app.route("/api/users/<int:user_id>/", methods=["GET"])
@user_authentication_required
def get_user_by_id(user, user_id):
    target_user = User.query.filter_by(id=user_id).first()
    if target_user is None:
        return failure_response("User not found")
    return success_response({
        "id": target_user.id,
        "username": target_user.username,
        "email": target_user.email,
        "first_name": target_user.first_name,
        "last_name": target_user.last_name,
        "created_at": target_user.created_at.isoformat()
    })

@app.route("/api/users/<int:user_id>/", methods=["PUT"])
@user_authentication_required
def update_user(user, user_id):
    if user.id != user_id:
        return failure_response("Unauthorized to update this user", 403)
    
    body = json.loads(request.data)
    if "first_name" in body:
        user.first_name = body.get("first_name")
    if "last_name" in body:
        user.last_name = body.get("last_name")
    
    db.session.commit()
    return success_response({
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "first_name": user.first_name,
        "last_name": user.last_name
    })

@app.route("/api/users/<int:user_id>/", methods=["DELETE"])
@user_authentication_required
def delete_user(user, user_id):
    if user.id != user_id:
        return failure_response("Unauthorized to delete this user", 403)
    
    db.session.delete(user)
    db.session.commit()
    return success_response({"message": "User deleted successfully"})

# Post Endpoints
@app.route("/api/posts/", methods=["GET"])
def get_all_posts():
    posts = Post.query.all()
    return success_response([{
        "id": p.id,
        "title": p.title,
        "content": p.content,
        "created_by": p.created_by,
        "created_at": p.created_at.isoformat(),
        "workout_id": p.workout_id,
        "weekly_workout_id": p.weekly_workout_id
    } for p in posts])

@app.route("/api/posts/<int:post_id>/", methods=["GET"])
def get_post_by_id(post_id):
    post = Post.query.filter_by(id=post_id).first()
    if post is None:
        return failure_response("Post not found")
    return success_response({
        "id": post.id,
        "title": post.title,
        "content": post.content,
        "created_by": post.created_by,
        "created_at": post.created_at.isoformat(),
        "workout_id": post.workout_id,
        "weekly_workout_id": post.weekly_workout_id
    })

@app.route("/api/posts/", methods=["POST"])
@user_authentication_required
def create_post(user):
    body = json.loads(request.data)
    if not all(k in body for k in ["title"]):
        return failure_response("Missing required fields", 400)
    
    new_post = Post(
        title=body.get("title"),
        content=body.get("content"),
        created_by=user.id,
        workout_id=body.get("workout_id"),
        weekly_workout_id=body.get("weekly_workout_id")
    )
    
    db.session.add(new_post)
    db.session.commit()
    return success_response({
        "id": new_post.id,
        "title": new_post.title,
        "content": new_post.content,
        "created_by": new_post.created_by,
        "created_at": new_post.created_at.isoformat(),
        "workout_id": new_post.workout_id,
        "weekly_workout_id": new_post.weekly_workout_id
    }, 201)

@app.route("/api/posts/<int:post_id>/", methods=["PUT"])
@user_authentication_required
def update_post(user, post_id):
    post = Post.query.filter_by(id=post_id).first()
    if post is None:
        return failure_response("Post not found")
    
    if post.created_by != user.id:
        return failure_response("Unauthorized to update this post", 403)
    
    body = json.loads(request.data)
    if "title" in body:
        post.title = body.get("title")
    if "content" in body:
        post.content = body.get("content")
    if "workout_id" in body:
        post.workout_id = body.get("workout_id")
    if "weekly_workout_id" in body:
        post.weekly_workout_id = body.get("weekly_workout_id")
    
    db.session.commit()
    return success_response({
        "id": post.id,
        "title": post.title,
        "content": post.content,
        "created_by": post.created_by,
        "created_at": post.created_at.isoformat(),
        "workout_id": post.workout_id,
        "weekly_workout_id": post.weekly_workout_id
    })

@app.route("/api/posts/<int:post_id>/", methods=["DELETE"])
@user_authentication_required
def delete_post(user, post_id):
    post = Post.query.filter_by(id=post_id).first()
    if post is None:
        return failure_response("Post not found")
    
    if post.created_by != user.id:
        return failure_response("Unauthorized to delete this post", 403)
    
    db.session.delete(post)
    db.session.commit()
    return success_response({"message": "Post deleted successfully"})

# Workout Endpoints
@app.route("/api/workouts/", methods=["GET"])
def get_all_workouts():
    workouts = Workout.query.all()
    return success_response([{
        "id": w.id,
        "name": w.name,
        "description": w.description,
        "duration": w.duration,
        "created_by": w.created_by,
        "exercises": w.get_exercises(),
        "exercise_plan": w.get_exercise_plan()
    } for w in workouts])

@app.route("/api/workouts/<int:workout_id>/", methods=["GET"])
def get_workout_by_id(workout_id):
    workout = Workout.query.filter_by(id=workout_id).first()
    if workout is None:
        return failure_response("Workout not found")
    return success_response({
        "id": workout.id,
        "name": workout.name,
        "description": workout.description,
        "duration": workout.duration,
        "created_by": workout.created_by,
        "exercises": workout.get_exercises(),
        "exercise_plan": workout.get_exercise_plan()
    })

@app.route("/api/workouts/", methods=["POST"])
@user_authentication_required
def create_workout(user):
    body = json.loads(request.data)
    if not all(k in body for k in ["name", "description", "duration"]):
        return failure_response("Missing required fields", 400)
    
    new_workout = Workout(
        name=body.get("name"),
        description=body.get("description"),
        duration=body.get("duration"),
        created_by=user.id,
        exercises=body.get("exercises", []),
        exercise_plan=body.get("exercise_plan", {})
    )
    
    db.session.add(new_workout)
    db.session.commit()
    return success_response({
        "id": new_workout.id,
        "name": new_workout.name,
        "description": new_workout.description,
        "duration": new_workout.duration,
        "created_by": new_workout.created_by,
        "exercises": new_workout.get_exercises(),
        "exercise_plan": new_workout.get_exercise_plan()
    }, 201)

@app.route("/api/workouts/<int:workout_id>/", methods=["PUT"])
@user_authentication_required
def update_workout(user, workout_id):
    workout = Workout.query.filter_by(id=workout_id).first()
    if workout is None:
        return failure_response("Workout not found")
    
    if workout.created_by != user.id:
        return failure_response("Unauthorized to update this workout", 403)
    
    body = json.loads(request.data)
    if "name" in body:
        workout.name = body.get("name")
    if "description" in body:
        workout.description = body.get("description")
    if "duration" in body:
        workout.duration = body.get("duration")
    if "exercises" in body:
        workout.exercises = json.dumps(body.get("exercises"))
    if "exercise_plan" in body:
        workout.exercise_plan = json.dumps(body.get("exercise_plan"))
    
    db.session.commit()
    return success_response({
        "id": workout.id,
        "name": workout.name,
        "description": workout.description,
        "duration": workout.duration,
        "created_by": workout.created_by,
        "exercises": workout.get_exercises(),
        "exercise_plan": workout.get_exercise_plan()
    })

@app.route("/api/workouts/<int:workout_id>/", methods=["DELETE"])
@user_authentication_required
def delete_workout(user, workout_id):
    workout = Workout.query.filter_by(id=workout_id).first()
    if workout is None:
        return failure_response("Workout not found")
    
    if workout.created_by != user.id:
        return failure_response("Unauthorized to delete this workout", 403)
    
    db.session.delete(workout)
    db.session.commit()
    return success_response({"message": "Workout deleted successfully"})

# WeeklyWorkout Endpoints
@app.route("/api/weekly-workouts/", methods=["GET"])
def get_all_weekly_workouts():
    weekly_workouts = WeeklyWorkout.query.all()
    return success_response([{
        "id": w.id,
        "week_start_date": w.week_start_date.isoformat(),
        "monday_id": w.monday_id,
        "tuesday_id": w.tuesday_id,
        "wednesday_id": w.wednesday_id,
        "thursday_id": w.thursday_id,
        "friday_id": w.friday_id,
        "saturday_id": w.saturday_id,
        "sunday_id": w.sunday_id
    } for w in weekly_workouts])

@app.route("/api/weekly-workouts/<int:weekly_workout_id>/", methods=["GET"])
def get_weekly_workout_by_id(weekly_workout_id):
    weekly_workout = WeeklyWorkout.query.filter_by(id=weekly_workout_id).first()
    if weekly_workout is None:
        return failure_response("Weekly workout not found")
    return success_response({
        "id": weekly_workout.id,
        "week_start_date": weekly_workout.week_start_date.isoformat(),
        "monday_id": weekly_workout.monday_id,
        "tuesday_id": weekly_workout.tuesday_id,
        "wednesday_id": weekly_workout.wednesday_id,
        "thursday_id": weekly_workout.thursday_id,
        "friday_id": weekly_workout.friday_id,
        "saturday_id": weekly_workout.saturday_id,
        "sunday_id": weekly_workout.sunday_id
    })

@app.route("/api/weekly-workouts/<int:weekly_workout_id>/", methods=["PUT"])
@user_authentication_required
def update_weekly_workout(user, weekly_workout_id):
    weekly_workout = WeeklyWorkout.query.filter_by(id=weekly_workout_id).first()
    if weekly_workout is None:
        return failure_response("Weekly workout not found")
    
    if weekly_workout.user.id != user.id:
        return failure_response("Unauthorized to update this weekly workout", 403)
    
    body = json.loads(request.data)
    if "monday_id" in body:
        weekly_workout.monday_id = body.get("monday_id")
    if "tuesday_id" in body:
        weekly_workout.tuesday_id = body.get("tuesday_id")
    if "wednesday_id" in body:
        weekly_workout.wednesday_id = body.get("wednesday_id")
    if "thursday_id" in body:
        weekly_workout.thursday_id = body.get("thursday_id")
    if "friday_id" in body:
        weekly_workout.friday_id = body.get("friday_id")
    if "saturday_id" in body:
        weekly_workout.saturday_id = body.get("saturday_id")
    if "sunday_id" in body:
        weekly_workout.sunday_id = body.get("sunday_id")
    
    db.session.commit()
    return success_response({
        "id": weekly_workout.id,
        "week_start_date": weekly_workout.week_start_date.isoformat(),
        "monday_id": weekly_workout.monday_id,
        "tuesday_id": weekly_workout.tuesday_id,
        "wednesday_id": weekly_workout.wednesday_id,
        "thursday_id": weekly_workout.thursday_id,
        "friday_id": weekly_workout.friday_id,
        "saturday_id": weekly_workout.saturday_id,
        "sunday_id": weekly_workout.sunday_id
    })

@app.route("/api/weekly-workouts/<int:weekly_workout_id>/", methods=["DELETE"])
@user_authentication_required
def delete_weekly_workout(user, weekly_workout_id):
    weekly_workout = WeeklyWorkout.query.filter_by(id=weekly_workout_id).first()
    if weekly_workout is None:
        return failure_response("Weekly workout not found")
    
    if weekly_workout.user.id != user.id:
        return failure_response("Unauthorized to delete this weekly workout", 403)
    
    db.session.delete(weekly_workout)
    db.session.commit()
    return success_response({"message": "Weekly workout deleted successfully"})

def failure_response(message, code=404):
    return json.dumps({"error": message}), code

def success_response(data, code=200):
    return json.dumps(data), code

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5001, debug=True)