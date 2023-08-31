FROM python:3.11-slim AS base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

# Install pipenv and compilation dependencies
RUN pip install pipenv
RUN apt-get update && apt-get install -y --no-install-recommends gcc

# Install python dependencies in /home/build/.venv
WORKDIR /home/build
COPY Pipfile .
COPY Pipfile.lock .
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy


# Copy artifacts and run!
FROM python:3.11-slim AS runtime
# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1

# Create and switch to a new user
WORKDIR /home/aws-prometheus-exporter
RUN useradd --create-home aws-prometheus-exporter
USER aws-prometheus-exporter

# Install application into container
COPY --from=base /home/build/.venv /home/aws-prometheus-exporter/.venv
ENV PATH="/home/aws-prometheus-exporter/.venv/bin:$PATH"
COPY . .

# Run the application
ENTRYPOINT ["python", "main.py"]
