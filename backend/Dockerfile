FROM python:3.7

WORKDIR /usr/app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY exercise_gifs/ ./exercise_gifs/
COPY temp/ ./temp/

COPY . .

CMD ["python", "app.py"]