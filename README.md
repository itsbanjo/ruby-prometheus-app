# Ruby Prometheus Metrics with Elastic Stack

This project demonstrates how to set up a Ruby application that exposes Prometheus metrics, scrape those metrics using Prometheus, and send them to Elastic Cloud using Elastic Agent.

## Prerequisites

- Docker and Docker Compose
- An Elastic Cloud account
- Access to Kibana and Fleet

## Setup

1. Clone this repository:
   ```
   git clone https://github.com/itsbanjo/ruby-prometheus-app.git
   cd ruby-prometheus-app
   ```

2. Update the `docker-compose.yml` file with your Elastic Fleet information:
   - Replace `FLEET_URL` with your actual Fleet URL
   - Replace `FLEET_ENROLLMENT_TOKEN` with your actual Fleet enrollment token

   ```yaml
   elastic-agent:
     environment:
       - FLEET_ENROLL=1
       - FLEET_INSECURE=false
       - FLEET_URL=https://your-fleet-url.cloud.es.io:443
       - FLEET_ENROLLMENT_TOKEN=YourActualEnrollmentTokenHere
   ```

3. Build and start the Docker containers:
   ```
   docker-compose up --build
   ```

## Components

### Ruby Application

- Located in `app.rb`
- Exposes a `/metrics` endpoint for Prometheus
- Simulates sales with the `/make_sale` endpoint

### Prometheus

- Scrapes metrics from the Ruby application
- Configuration in `prometheus.yml`
- Accessible at `http://localhost:9090`

### Elastic Agent

- Managed by Fleet
- Collects metrics from the Ruby application
- Sends data to Elastic Cloud

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

## Verifying the Setup

1. Generate some metrics:
   ```
   curl http://localhost:4567/make_sale
   ```

2. Check Prometheus:
   - Open `http://localhost:9090`
   - Query for `total_sales`

3. Check Elastic Cloud:
   - In Kibana, go to Metrics > Inventory
   - Look for metrics from your Ruby application

## Visualizing Data in Kibana

1. In Kibana, go to Analytics > Discover
2. Create a new data view:
   - Click "Create data view"
   - Index pattern: `metrics-*`
   - Timestamp field: `@timestamp`
   - Name: "Ruby App Metrics"
   - Click "Save data view to Kibana"
3. You should now see your metric data
4. To create a visualization:
   - Go to Analytics > Dashboard
   - Click "Create visualization"
   - Choose "Line" (or another appropriate type)
   - In the data panel:
     - Select "Ruby App Metrics" as your data view
     - Y-axis: Aggregation "Max" of field "prometheus.ruby_app.total_sales"
     - X-axis: Aggregation "Date Histogram" of field "@timestamp"
   - Click "Save and return"
5. Add the visualization to a dashboard:
   - Click "Add to dashboard"
   - Create a new dashboard or add to an existing one

## Troubleshooting

- Check Docker logs: `docker-compose logs`
- Verify Elastic Agent enrollment: Check the Fleet UI in Kibana
- Ensure the Ruby app is exposing metrics: `curl http://localhost:4567/metrics`
- Check Elastic Agent logs in Kibana: Fleet > Agents > [Your Agent] > Logs

## Contributing

[Include information about how to contribute to the project]

## License

[Include your license information here]
