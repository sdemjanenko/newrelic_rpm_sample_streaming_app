if ENV["NEWRELIC_PATCH"] == "true"
  module NewRelic
    module Agent
      module Instrumentation
        module MiddlewareTracing
          def call(env)
            first_middleware = note_transaction_started(env)

            state = NewRelic::Agent::Tracer.state

            begin
              options = build_transaction_options(env, first_middleware)

              finishable = Tracer.start_transaction_or_segment(
                name: options[:transaction_name],
                category: category,
                options: options
              )

              events.notify(:before_call, env) if first_middleware

              result = (target == self) ? traced_call(env) : target.call(env)

              if first_middleware
                capture_response_attributes(state, result)
                events.notify(:after_call, env, result)
              end

              if first_middleware
                status, headers, response = *result
                lazy_response = response.respond_to?(:close)

                if lazy_response
                  wrapped_response = StreamBodyProxy.new(response) do
                    finishable.finish if finishable
                  end

                  [status, headers, wrapped_response]
                else
                  result
                end
              else
                result
              end
            rescue Exception => e
              NewRelic::Agent.notice_error(e)
              raise e
            ensure
              if finishable
                if first_middleware && lazy_response
                  # NOOP: StreamBodyProxy handles this
                else
                  finishable.finish
                end
              end
            end
          end

          class StreamBodyProxy # ideally this would inherit from < Rack::BodyProxy
            def initialize(body, &block)
              @body = body
              @block = block
              @closed = false
            end

            def respond_to?(method_name, include_all = false)
              case method_name
              when :to_ary, 'to_ary'
                return false
              end
              super or @body.respond_to?(method_name, include_all)
            end

            def close
              return if @closed

              close_segment = NewRelic::Agent::Tracer.start_segment(name: 'Middleware/Rack/StreamBodyProxy/close')
              @closed = true
              begin
                @body.close if @body.respond_to? :close
              rescue => e
                NewRelic::Agent.notice_error(e)
                raise
              ensure
                begin
                  close_segment.finish
                ensure
                  @block.call
                end
              end
            end

            def closed?
              @closed
            end

            def each
              segment = NewRelic::Agent::Tracer.start_segment(name: 'Middleware/Rack/StreamBodyProxy/body_each')

              @body.each { |body| yield body }
            rescue => e
              NewRelic::Agent.notice_error(e)
              raise
            ensure
              segment.finish
            end

            def method_missing(method_name, *args, &block)
              super if :to_ary == method_name
              @body.__send__(method_name, *args, &block)
            end
          end
        end
      end
    end
  end
end
