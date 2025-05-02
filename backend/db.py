from flask_sqlalchemy import SQLAlchemy
import json
from datetime import datetime
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

db = SQLAlchemy()

user_workout = db.Table('user_workout',
    db.Column('user_id', db.Integer, db.ForeignKey('users.id'), primary_key=True),
    db.Column('workout_id', db.Integer, db.ForeignKey('workout.id'), primary_key=True)
)

class User(UserMixin, db.Model):
    __tablename__ = "users"
    
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False, index=True)
    email = db.Column(db.String(120), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(128), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    first_name = db.Column(db.String(80), nullable=False)
    last_name = db.Column(db.String(80), nullable=False)
    last_login = db.Column(db.DateTime, nullable=True)
    
    session_token = db.Column(db.String(128), nullable=True)
    session_expiration = db.Column(db.DateTime, nullable=True)
    update_token = db.Column(db.String(128), nullable=True)
    
    weekly_workout_id = db.Column(db.Integer, db.ForeignKey('weekly_workout.id'), nullable=True)
    
    created_workouts = db.relationship('Workout', backref='creator', lazy='dynamic', 
                                      foreign_keys='Workout.created_by')
    
    saved_workouts = db.relationship('Workout', 
                                    secondary=user_workout,
                                    backref=db.backref('saved_by_users', lazy='dynamic'),
                                    lazy='dynamic')
    
    weekly_workout = db.relationship('WeeklyWorkout', uselist=False, 
                                    backref='user', foreign_keys=[weekly_workout_id])
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(
            password, 
            method='pbkdf2:sha256', 
            salt_length=8
        )
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def get_full_name(self):
        return f"{self.first_name} {self.last_name}"
    
    def __repr__(self):
        return f'<User {self.username}>'


class Post(db.Model):
    __tablename__ = "posts"
    
    id = db.Column(db.Integer, primary_key=True)
    workout_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    weekly_workout_id = db.Column(db.Integer, db.ForeignKey("weekly_workout.id"), nullable=True)
    title = db.Column(db.String(120), nullable=False)
    content = db.Column(db.Text, nullable=True)
    
    workout = db.relationship("Workout", backref="posts")
    author = db.relationship("User", backref="posts", foreign_keys=[created_by])
    weekly_workout = db.relationship("WeeklyWorkout", backref="posts")
    
    def __repr__(self):
        return f'<Post {self.id} by {self.created_by}>'


class Workout(db.Model):
    __tablename__ = "workout"
    
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    duration = db.Column(db.Integer, nullable=False)
    created_by = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    
    exercises = db.Column(db.Text, nullable=True)
    exercise_plan = db.Column(db.Text, nullable=True)
    
    def __init__(self, **kwargs):
        self.name = kwargs.get("name", "")
        self.description = kwargs.get("description", "")
        self.duration = kwargs.get("duration", 0)
        self.created_by = kwargs.get("created_by")
        
        exercises = kwargs.get("exercises")
        if exercises and isinstance(exercises, list):
            self.exercises = json.dumps(exercises)
            
        exercise_plan = kwargs.get("exercise_plan")
        if exercise_plan and isinstance(exercise_plan, dict):
            self.exercise_plan = json.dumps(exercise_plan)
    
    def get_exercises(self):
        if self.exercises:
            return json.loads(self.exercises)
        return []
    
    def get_exercise_plan(self):
        if self.exercise_plan:
            return json.loads(self.exercise_plan)
        return {}
        
    def add_exercise(self, exercise_id, reps=0, sets=1, order=None, **kwargs):
        exercises = self.get_exercises()
        plan = self.get_exercise_plan()
        
        if exercise_id not in exercises:
            exercises.append(exercise_id)
            
        details = {"reps": reps, "sets": sets}
        details.update(kwargs)
        
        plan[str(exercise_id)] = details
        
        self.exercises = json.dumps(exercises)
        self.exercise_plan = json.dumps(plan)
        
    def remove_exercise(self, exercise_id):
        exercises = self.get_exercises()
        plan = self.get_exercise_plan()
        
        if exercise_id in exercises:
            exercises.remove(exercise_id)
            
        str_id = str(exercise_id)
        if str_id in plan:
            del plan[str_id]
            
        self.exercises = json.dumps(exercises)
        self.exercise_plan = json.dumps(plan)
        
    def get_exercises_with_details(self):
        from sqlalchemy import select
        from sqlalchemy.orm import Session
        
        exercises = self.get_exercises()
        plan = self.get_exercise_plan()
        
        if not exercises:
            return []
            
        session = Session.object_session(self)
        exercise_objects = session.execute(
            select(Exercise).where(Exercise.id.in_(exercises))
        ).scalars().all()
        
        exercise_map = {str(ex.id): ex for ex in exercise_objects}
        
        result = []
        for ex_id in exercises:
            str_id = str(ex_id)
            if str_id in exercise_map and str_id in plan:
                exercise_obj = exercise_map[str_id]
                details = plan[str_id]
                
                exercise_data = exercise_obj.serialize()
                exercise_data.update(details)
                result.append(exercise_data)
                
        return result
    
    def __repr__(self):
        return f'<Workout {self.name}>'


class Exercise(db.Model):    
    __tablename__ = "exercise"    
    
    id = db.Column(db.Integer, primary_key=True)    
    bodyPart = db.Column(db.String(50), nullable=False, index=True)
    equipment = db.Column(db.String(50), nullable=False, index=True)
    gifUrl = db.Column(db.String(255), nullable=False)
    name = db.Column(db.String(100), nullable=False, index=True)
    target = db.Column(db.String(50), nullable=False, index=True)
    secondaryMuscles = db.Column(db.Text, nullable=True)
    instructions = db.Column(db.Text, nullable=True)

    def __init__(self, **kwargs):
        self.bodyPart = kwargs.get("bodyPart", "")
        self.equipment = kwargs.get("equipment", "")
        self.gifUrl = kwargs.get("gifUrl", "")
        self.name = kwargs.get("name", "")
        self.target = kwargs.get("target", "")
        
        if isinstance(kwargs.get("secondaryMuscles"), list):
            self.secondaryMuscles = json.dumps(kwargs.get("secondaryMuscles", []))
        else:
            self.secondaryMuscles = kwargs.get("secondaryMuscles", "[]")
            
        if isinstance(kwargs.get("instructions"), list):
            self.instructions = json.dumps(kwargs.get("instructions", []))
        else:
            self.instructions = kwargs.get("instructions", "[]")
   
    def get_secondary_muscles(self):
        try:
            return json.loads(self.secondaryMuscles)
        except:
            return []
            
    def get_instructions(self):
        try:
            return json.loads(self.instructions)
        except:
            return []
   
    def serialize(self):
        return {
            "id": self.id,
            "bodyPart": self.bodyPart,
            "equipment": self.equipment,
            "gifUrl": self.gifUrl,
            "name": self.name,
            "target": self.target,
            "secondaryMuscles": self.get_secondary_muscles(),
            "instructions": self.get_instructions(),
        }
    
    def to_dict(self):
        return self.serialize()
        
    def to_dict_simple(self):
        return self.serialize()
        
    def __repr__(self):
        return f'<Exercise {self.name}>'


class WeeklyWorkout(db.Model):
    __tablename__ = "weekly_workout"
    
    id = db.Column(db.Integer, primary_key=True)
    week_start_date = db.Column(db.Date, nullable=False, default=datetime.utcnow().date)
    
    monday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    tuesday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    wednesday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    thursday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    friday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    saturday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    sunday_id = db.Column(db.Integer, db.ForeignKey("workout.id"), nullable=True)
    
    monday_workout = db.relationship("Workout", foreign_keys=[monday_id])
    tuesday_workout = db.relationship("Workout", foreign_keys=[tuesday_id])
    wednesday_workout = db.relationship("Workout", foreign_keys=[wednesday_id])
    thursday_workout = db.relationship("Workout", foreign_keys=[thursday_id])
    friday_workout = db.relationship("Workout", foreign_keys=[friday_id])
    saturday_workout = db.relationship("Workout", foreign_keys=[saturday_id])
    sunday_workout = db.relationship("Workout", foreign_keys=[sunday_id])
    
    def get_workout_for_day(self, day):
        days = [
            self.monday_workout,
            self.tuesday_workout,
            self.wednesday_workout,
            self.thursday_workout,
            self.friday_workout,
            self.saturday_workout,
            self.sunday_workout
        ]
        if 0 <= day <= 6:
            return days[day]
        return None
        
    def __repr__(self):
        return f'<WeeklyWorkout {self.id}>'