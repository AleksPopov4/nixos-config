# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY . /app

# Install any necessary dependencies (optional)
# RUN pip install --no-cache-dir -r requirements.txt

# Add a simple Python script
RUN echo "print('Docker container is running properly!')" > script.py

# Run the Python script
CMD ["python", "script.py"]
