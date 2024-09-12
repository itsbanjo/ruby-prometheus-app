require 'sinatra/base'
require 'prometheus/client'
require 'prometheus/client/formats/text'
require 'elastic-apm'
require 'redis'
require 'securerandom'
require 'logger'
require 'json'

class App < Sinatra::Base
  # Set up logging
  configure do
    set :logger, Logger.new(STDOUT)
    logger.level = Logger::INFO
  end

  # Redis client
  configure do
    set :redis, Redis.new(url: ENV['REDIS_URL'])
  end

  # Sampling rate (e.g., 10%)
  SAMPLING_RATE = 0.1

  # Configure Elastic APM with custom sampling
  configure do
    begin
      ElasticAPM.start(
        service_name: 'ruby-prometheus-app',
        server_url: ENV['ELASTIC_APM_SERVER_URL'],
        secret_token: ENV['ELASTIC_APM_SECRET_TOKEN'],
        transaction_sample_rate: SAMPLING_RATE,
        span_frames_min_duration: '0ms',
        log_level: Logger::INFO,
        disable_send: ENV['DISABLE_APM_SEND'] == 'true'
      )
      logger.info("Elastic APM started successfully with URL: #{ENV['ELASTIC_APM_SERVER_URL']}")
    rescue => e
      logger.error("Failed to start Elastic APM: #{e.message}")
    end
  end

  use ElasticAPM::Middleware

  # Sinatra configuration
  configure do
    set :port, 4567
    set :bind, '0.0.0.0'
    logger.info("Configuring Sinatra application...")
  end

  # Create a metrics registry
  configure do
    set :prometheus, Prometheus::Client.registry
  end

  # Create a counter for total sales
  configure do
    set :sales_counter, Prometheus::Client::Counter.new(
      :total_sales,
      docstring: 'Total sales in dollars'
    )
    settings.prometheus.register(settings.sales_counter)
  end

  # Simulate a sale
  def make_sale
    amount = rand(10..100)
    settings.sales_counter.increment(by: amount)
    
    # Simulate some processing time
    sleep(rand * 0.5)
    
    # Mark as slow transaction if it takes more than 200ms
    if rand < 0.1  # 10% chance of being a slow transaction
      sleep(0.3)
      transaction_id = ElasticAPM.current_transaction&.id
      settings.redis.setex("slow_transaction:#{transaction_id}", 300, "1") if transaction_id
    end
    
    # Store transaction data in Redis
    transaction_id = ElasticAPM.current_transaction&.id
    if transaction_id
      ElasticAPM.with_span("Redis: Store Transaction") do
        settings.redis.hmset(
          "transaction:#{transaction_id}",
          "amount", amount,
          "timestamp", Time.now.to_i
        )
        settings.redis.expire("transaction:#{transaction_id}", 3600)  # Expire after 1 hour
      end
    end
    
    amount
  end

  # Endpoint for homepage
  get '/' do
    'Welcome to our online store!'
  end

  # Endpoint to simulate a sale
  get '/make_sale' do
    ElasticAPM.with_span("Make Sale") do
      amount = make_sale()
      ElasticAPM.set_label(:sale_amount, amount)
      logger.info("Sale processed successfully for $#{amount}")
      "Sale made for $#{amount}"
    end
  rescue => e
    logger.error("Error processing sale: #{e.message}")
    ElasticAPM.report_message("Error processing sale: #{e.message}")
    status 500
    "Error processing sale"
  end

  # Endpoint for Prometheus metrics
  get '/metrics' do
    content_type 'text/plain; version=0.0.4'
    Prometheus::Client::Formats::Text.marshal(settings.prometheus)
  end

  # New endpoint to test error reporting
  get '/test_error' do
    raise "This is a test error"
  rescue => e
    logger.error("Test error raised: #{e.message}")
    ElasticAPM.report_message("Test error: #{e.message}")
    status 500
    "Test error occurred"
  end

  # Endpoint to check APM status
  get '/apm_status' do
    if ElasticAPM.running?
      logger.info("APM is running")
      "APM is running"
    else
      logger.warn("APM is not running")
      "APM is not running"
    end
  end

  configure do
    at_exit do 
      logger.info("Stopping Elastic APM")
      ElasticAPM.stop
    end
  end
end

# Start the Sinatra application server
if __FILE__ == $0
  App.run!
end
