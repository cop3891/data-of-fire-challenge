# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory
WORKDIR /app

#install git and other dependencies
RUN apt-get update && apt-get install -y \
    git \
    make 

# Copy the requirements file and install dependencies
COPY ./report/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8501

COPY ./report/ .

# Specify the default command to run your application
CMD ["tail", "-f", "/dev/null"]