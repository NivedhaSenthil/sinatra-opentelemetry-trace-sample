require "sinatra"
require "opentelemetry-sdk"
require "opentelemetry/instrumentation/all"
require "opentelemetry/exporter/google_cloud_trace"
require "google/cloud/pubsub"

OpenTelemetry::SDK.configure do |c|
  c.service_name = "test_app"
  c.add_span_processor(
    OpenTelemetry::SDK::Trace::Export::BatchSpanProcessor.new(
      OpenTelemetry::Exporter::GoogleCloudTrace::SpanExporter.new
    )
  )
  c.use_all
end

set :port, 9495

get "/publish" do  
  tracer = OpenTelemetry.tracer_provider.tracer("pull_tracer")
  tracer.in_span "Publish" do 
    pubsub = Google::Cloud::Pubsub.new
    topic = pubsub.topic "test"
    topic.publish_async "from trace"
    topic.async_publisher.stop.wait!
  end
  "Success!"
end
