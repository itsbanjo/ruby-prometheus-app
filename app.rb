# app.rb
require 'sinatra'
require 'prometheus/client'
require 'prometheus/client/formats/text'

set :bind, '0.0.0.0'

# Create a metrics registry
$prometheus = Prometheus::Client.registry

# Create a counter for total sales
$sales_counter = Prometheus::Client::Counter.new(
  :total_sales,
  docstring: 'Total sales in dollars'
)
$prometheus.register($sales_counter)

# Simulate a sale
def make_sale
  amount = rand(10..100)
  $sales_counter.increment(by: amount)
  amount
end

# Endpoint for homepage
get '/' do
  'Welcome to our online store!'
end

# Endpoint to simulate a sale
get '/make_sale' do
  amount = make_sale
  "Sale made for $#{amount}"
end

# Endpoint for Prometheus metrics
get '/metrics' do
  content_type 'text/plain; version=0.0.4'
  Prometheus::Client::Formats::Text.marshal($prometheus)
end
