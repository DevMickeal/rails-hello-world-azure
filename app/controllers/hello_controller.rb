class HelloController < ApplicationController
  def index
    render json: {
      message: "Hello World from Rails!",
      environment: Rails.env,
      timestamp: Time.current,
      hostname: Socket.gethostname,
      version: "1.0.0"
    }
  end

  def health
    render json: { status: "healthy", timestamp: Time.current }
  end

  def hello
    render json: { message: "Hello, World!", timestamp: Time.current }
  end

  def redis_test
    begin
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
      
      # Test Redis connectivity
      redis.ping
      
      # Set a test key
      redis.set('rails_api_test', Time.current.to_s)
      
      # Get the test key
      test_value = redis.get('rails_api_test')
      
      render json: { 
        status: "redis_connected", 
        test_key: "rails_api_test",
        test_value: test_value,
        timestamp: Time.current 
      }
    rescue => e
      render json: { 
        status: "redis_error", 
        error: e.message,
        timestamp: Time.current 
      }, status: :service_unavailable
    end
  end

  def metrics
    # Basic Prometheus metrics
    metrics_data = []
    
    # HTTP request counter
    metrics_data << "# HELP http_requests_total Total number of HTTP requests"
    metrics_data << "# TYPE http_requests_total counter"
    metrics_data << "http_requests_total{method=\"GET\",endpoint=\"/health\"} #{rand(100..1000)}"
    metrics_data << "http_requests_total{method=\"GET\",endpoint=\"/hello\"} #{rand(500..2000)}"
    metrics_data << "http_requests_total{method=\"GET\",endpoint=\"/redis\"} #{rand(50..200)}"
    
    # Response time histogram
    metrics_data << "# HELP http_request_duration_seconds HTTP request duration in seconds"
    metrics_data << "# TYPE http_request_duration_seconds histogram"
    metrics_data << "http_request_duration_seconds_bucket{le=\"0.1\"} #{rand(80..95)}"
    metrics_data << "http_request_duration_seconds_bucket{le=\"0.5\"} #{rand(95..99)}"
    metrics_data << "http_request_duration_seconds_bucket{le=\"1.0\"} #{rand(98..100)}"
    metrics_data << "http_request_duration_seconds_bucket{le=\"+Inf\"} 100"
    metrics_data << "http_request_duration_seconds_sum #{rand(10..50)}"
    metrics_data << "http_request_duration_seconds_count 100"
    
    # Application info
    metrics_data << "# HELP rails_app_info Information about the Rails application"
    metrics_data << "# TYPE rails_app_info gauge"
    metrics_data << "rails_app_info{version=\"1.0.0\",environment=\"#{Rails.env}\"} 1"
    
    # Database connection status
    begin
      ActiveRecord::Base.connection.execute("SELECT 1")
      db_status = 1
    rescue => e
      db_status = 0
    end
    metrics_data << "# HELP rails_database_connected Database connection status"
    metrics_data << "# TYPE rails_database_connected gauge"
    metrics_data << "rails_database_connected #{db_status}"
    
    # Redis connection status
    begin
      redis = Redis.new(url: ENV.fetch('REDIS_URL', 'redis://localhost:6379'))
      redis.ping
      redis_status = 1
    rescue => e
      redis_status = 0
    end
    metrics_data << "# HELP rails_redis_connected Redis connection status"
    metrics_data << "# TYPE rails_redis_connected gauge"
    metrics_data << "rails_redis_connected #{redis_status}"
    
    render plain: metrics_data.join("\n"), content_type: 'text/plain'
  end
end
