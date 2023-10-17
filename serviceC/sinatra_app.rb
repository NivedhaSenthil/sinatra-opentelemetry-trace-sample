require "sinatra"
require "opentelemetry-sdk"
require "opentelemetry/instrumentation/sinatra"
require "opentelemetry/instrumentation/rack"
require "opentelemetry/exporter/google_cloud_trace"
require 'net/http'

OpenTelemetry::SDK.configure do |c|
  c.service_name = "test_app"
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
    )
  )
  c.use_all
end

set :port, 9494

get "/message" do
  tracer = OpenTelemetry.tracer_provider.tracer("index_tracer")
  tracer.in_span "test_span" do |span|
    span.add_event "Publishing!!"
    url = URI.parse('http://localhost:9495/publish')
    req = Net::HTTP::Get.new(url.to_s)
    OpenTelemetry.propagation.inject(req)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    puts res.body
    span.add_event "Published!!"
    span.add_event "Pulling!!"
    url = URI.parse('http://localhost:9496/pull')
    req = Net::HTTP::Get.new(url.to_s)
    OpenTelemetry.propagation.inject(req)
    res = Net::HTTP.start(url.host, url.port) {|http|
     http.request(req)
    }
    puts res.body
    span.add_event "Pulled!!"
  end
  sleep 20
  "Hello !"
end
