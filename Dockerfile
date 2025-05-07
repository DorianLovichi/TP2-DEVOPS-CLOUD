FROM python:3.13-slim

WORKDIR /app

COPY backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENV FLASK_APP=backend/app.py
ENV FLASK_ENV=production
ENV DYNAMODB_TABLE=Campaigns

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "backend.app:app"]