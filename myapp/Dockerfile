# Use the official Python image as the base image
FROM python:3.9-slim

# Set environment variables for Flask
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file into the container at /app
COPY requirements.txt requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install -r requirements.txt

# Copy the rest of the application code into the container at /app
COPY . .

# Expose port 8000 for the Flask app to listen on
EXPOSE 8000

# Run the application
CMD ["flask", "run"]

