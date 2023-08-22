FROM python:3.11-slim AS base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

# Install pipenv and compilation dependencies
RUN pip install pipenv
RUN apt-get update && apt-get install -y --no-install-recommends gcc

# Install python dependencies in /.venv
COPY Pipfile .
COPY Pipfile.lock .
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

ENV PATH="/.venv/bin:$PATH"

# Create and switch to a new user
RUN useradd --create-home aws-prometheus-exporter
WORKDIR /home/aws-prometheus-exporter
USER aws-prometheus-exporter

# Install application into container
COPY . .

# Run the application
ENTRYPOINT ["python", "main.py"]
