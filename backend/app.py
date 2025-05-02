from flask import Flask, send_from_directory, abort, jsonify, request, json
import os
from db import db, User, Exercise, Workout, WeeklyWorkout
import json
from datetime import datetime, timedelta
import uuid
import hashlib
import base64

app = Flask(__name__)
db_filename = "cornellgym.db" 
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///%s" % db_filename
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
app.config["SQLALCHEMY_ECHO"] = True
app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-key-for-testing")

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

def failure_response(message, code=404):
    return json.dumps({"error": message}), code

def success_response(data, code=200):
    return json.dumps(data), code

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5001, debug=True)