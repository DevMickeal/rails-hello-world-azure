# syntax=docker/dockerfile:1
# check=error=true

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t rails_app .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name rails_app rails_app

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Use the official Ruby image as the base image
FROM ruby:3.3-alpine

# Install system dependencies
RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    yaml-dev \
    tzdata \
    nodejs \
    yarn

# Set working directory
WORKDIR /app

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install Ruby gems
RUN bundle install --jobs 4 --retry 3

# Copy the rest of the application
COPY . .

# Create a non-root user
RUN addgroup -g 1000 -S rails && \
    adduser -u 1000 -S rails -G rails

# Change ownership of the app directory
RUN chown -R rails:rails /app
USER rails

# Expose port 3000
EXPOSE 3000

# Set environment variables
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# Start the Rails server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]
