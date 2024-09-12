# Dockerfile
FROM ruby:3.0

# Install dependencies
RUN apt-get update && apt-get install -y build-essential

# Set working directory
WORKDIR /app

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy the application code
COPY . .

# Expose port 4567
EXPOSE 4567

# Start the application
CMD ["ruby", "app.rb"]
