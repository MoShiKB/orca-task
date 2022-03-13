FROM python:3.8-slim as base

# Install Postgres dependency
RUN apt-get update && apt-get install -y --no-install-recommends libpq-dev
RUN pip install pipenv

FROM base AS python-deps

# Install needed packages for psycopg2
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev

# Install python dependencies in /.venv
COPY Pipfile .
COPY Pipfile.lock .
RUN pipenv install psycopg2
RUN PIPENV_VENV_IN_PROJECT=1 pipenv install --deploy

FROM base AS runtime

# Copy virtual env from python-deps stage
COPY --from=python-deps /.venv /.venv
ENV PATH="/.venv/bin:$PATH"

# Activating venv
ENV VIRTUAL_ENV=/.venv
RUN python3 -m venv $VIRTUAL_ENV

# Create and switch to a new user
RUN useradd --create-home flask
WORKDIR /home/flask
USER flask

# Install application into container
COPY . .

# Run the application
ENTRYPOINT ["/bin/sh"]
CMD ["run_app.sh"]
