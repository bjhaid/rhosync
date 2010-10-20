module Rhosync
  module Stats
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        start = Time.now.to_f
        status, headers, body = @app.call(env)
        finish = Time.now.to_f
        metric = "http:#{env['REQUEST_METHOD']}:#{env['REQUEST_PATH']}"
        source_id = env['rack.request.query_hash']["source_id"] if env['rack.request.query_hash']
        metric << ":#{source_id}" if source_id
        Record.save_average(metric,finish - start)
        [status, headers, body]
      end
    end
  end
end