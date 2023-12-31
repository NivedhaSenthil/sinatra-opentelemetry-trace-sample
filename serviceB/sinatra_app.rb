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

set :port, 9496

get "/pull" do
  tracer = OpenTelemetry.tracer_provider.tracer("pull_tracer")
  tracer.in_span "Pull" do |span, context|
    pubsub = Google::Cloud::Pubsub.new
    subscription = pubsub.subscription "test-sub"
    messages = subscription.pull 
    messages.each do |received_message|
      puts "Received message: "
      puts received_message.inspect
      received_message.acknowledge!
    end
  end

  "Success !!"
end
