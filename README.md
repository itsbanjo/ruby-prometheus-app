# Ruby Prometheus Metrics with Elastic Stack, APM, and Redis Sampling

This project demonstrates a Ruby application that exposes Prometheus metrics, integrates with Elastic APM for application performance monitoring, uses Redis for tail-based sampling, and includes error simulation. It's designed to showcase a modern observability setup for a web application.

## Features

- Ruby Sinatra application simulating an online store
- Prometheus metrics exposure
- Elastic APM integration for performance monitoring
- Redis-based tail sampling for efficient APM data collection
- Error simulation endpoint for testing error tracking
- Docker Compose setup for easy deployment

## Prerequisites

- Docker and Docker Compose
- An Elastic Cloud account (or a self-hosted Elastic Stack)
- Basic knowledge of Ruby, Docker, and Elastic Stack

## Setup

1. Clone the repository:
   ```
   git clone [your-repository-url]
   cd [your-project-directory]
   ```

2. Create a `.env` file in the project root and add your Elastic Cloud credentials:
   ```
   ELASTIC_APM_SERVER_URL=https://your-apm-server-url:443
   ELASTIC_APM_SECRET_TOKEN=your_apm_secret_token
   FLEET_URL=https://your-fleet-url.cloud.es.io:443
   FLEET_ENROLLMENT_TOKEN=YourActualEnrollmentTokenHere
   ```

3. Build and start the Docker containers:
   ```
   docker-compose up --build
   ```

## Components

### Ruby Application (app.rb)

- Simulates an online store with a `/make_sale` endpoint
- Exposes Prometheus metrics at `/metrics`
- Integrates with Elastic APM for performance monitoring
- Uses Redis for tail-based sampling of APM transactions
- Includes a `/test_error` endpoint to simulate application errors

### Prometheus

- Scrapes metrics from the Ruby application
- Configured in `prometheus.yml`
- Accessible at `http://localhost:9090`

### Elastic APM

- Monitors application performance
- Sends data to Elastic Cloud
- Custom instrumentation for Redis operations

### Redis

- Used for tail-based sampling of APM transactions
- Stores transaction metadata for sampling decisions

## Elastic Cloud Setup

### Creating a Fleet Policy for Prometheus

1. Log into your Kibana instance in Elastic Cloud
2. Navigate to Management > Fleet
3. Click on "Agent policies" in the left sidebar
4. Click "Create agent policy"
5. Name your policy (e.g., "Ruby App Prometheus Policy")
6. Click "Create agent policy"
7. In the new policy, click "Add integration"
8. Search for and select "Prometheus"
9. Configure the Prometheus integration:
   - Name: "Ruby App Prometheus"
   - Hosts: `http://ruby_app:4567`
   - Metrics path: `/metrics`
   - Scrape interval: 10s (or as needed)
10. Under "Advanced options", add a processor:
    ```yaml
    - add_fields:
        target: ""
        fields:
          service.name: ruby_app
          service.type: prometheus
    ```
11. Click "Save and deploy changes"

### Generating an API Key

1. In Kibana, go to Management > Fleet > Enrollment tokens
2. Click "Create enrollment token"
3. Select the policy you created
4. Click "Create enrollment token"
5. Copy the generated token and update your `docker-compose.yml` file with this token

### Configuring Elastic Agent in Fleet

1. In Fleet, go to the "Agents" tab
2. You should see your agent appear after starting the Docker containers
3. Click on the agent to view its details and ensure it's properly connected

## Usage

1. Access the application:
   - Homepage: `http://localhost:4567`
   - Simulate a sale: `http://localhost:4567/make_sale`
   - View Prometheus metrics: `http://localhost:4567/metrics`
   - Simulate an error: `http://localhost:4567/test_error`

2. Generate some traffic:
   ```
   for i in {1..100}; do curl http://localhost:4567/make_sale; done
   ```

3. Simulate errors:
   ```
   for i in {1..10}; do curl http://localhost:4567/test_error; done
   ```

4. View metrics and traces:
   - Prometheus UI: `http://localhost:9090`
   - Elastic APM (in Kibana): Navigate to APM > Services
     - Check the "Errors" tab to view simulated errors

## Tail-Based Sampling

This project implements tail-based sampling using Redis:

- All transactions are initially captured by APM
- Slow transactions (>200ms) are always sampled
- Other transactions are randomly sampled at a 10% rate
- Redis stores transaction metadata for sampling decisions

To adjust sampling, modify the `SAMPLING_RATE` constant in `app.rb`.

## Redis and APM

While Redis is used for tail-based sampling in this project, it may not appear as a separate service in the APM UI. The Redis operations are instrumented within the Ruby application, but their visibility in APM depends on various factors:

- The volume of Redis operations
- APM agent configuration
- Elastic Stack version

To observe Redis-related data:

1. In Kibana, go to APM > Services and select your Ruby application
2. Look for Redis operations in the transaction traces
3. Check the "Dependencies" section for any Redis-related information

Note: If you don't see explicit Redis entries, the operations are still being traced within your Ruby application's transactions.

## Troubleshooting

- Check Docker logs: `docker-compose logs`
- Verify Elastic Agent enrollment in Kibana's Fleet UI
- Ensure the Ruby app is exposing metrics: `curl http://localhost:4567/metrics`
- Check Redis connection: `docker-compose exec redis redis-cli ping`
- Verify error simulation: `curl http://localhost:4567/test_error` and check APM Errors tab

## Customization

- Adjust the sampling rate in `app.rb`
- Modify the `make_sale` function to simulate different transaction patterns
- Add new endpoints or metrics to the Ruby application as needed
- Customize the `/test_error` endpoint to simulate different types of errors
