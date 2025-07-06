#!/bin/bash

# Stop any existing containers
docker stop rails-test 2>/dev/null || true
docker rm rails-test 2>/dev/null || true

# Generate a secret key base
SECRET_KEY_BASE=$(docker run --rm rails-hello-world bin/rails secret)

# Run the Rails app in Docker
echo "Starting Rails app in Docker..."
docker run -d \
  --name rails-test \
  -p 3000:3000 \
  -e RAILS_ENV=development \
  -e SECRET_KEY_BASE="$SECRET_KEY_BASE" \
  -e DATABASE_URL="postgresql://postgres:password@host.docker.internal:5432/rails_app_development" \
  rails-hello-world

echo "Waiting for Rails app to start..."
sleep 10

echo "Testing endpoints..."
echo "Health check:"
curl -s http://localhost:3000/health | jq .

echo -e "\nHello endpoint:"
curl -s http://localhost:3000/hello | jq .

echo -e "\nRoot endpoint:"
curl -s http://localhost:3000/ | jq .

echo -e "\nRails app is running at http://localhost:3000"
echo "To stop: docker stop rails-test"
echo "To view logs: docker logs rails-test" 