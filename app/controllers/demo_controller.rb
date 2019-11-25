class DemoController < ApplicationController
  def show
    json_enum = Enumerator.new do |yielder|
      yielder << '['

      first_element = true
      100.times do |n|
        yielder << ',' unless first_element
        yielder << "{\"id\": \"#{n}\", \"value\": \"#{expensive_method_call(n)}\"}"
        first_element = false
      end

      yielder << ']'
    end

    headers['Content-Type'] = 'application/json'
    render_stream json_enum
  end

  private

  # TODO: trace this method in Newrelic
  def expensive_method_call(n)
    sleep 0.1
    "foo#{n}"
  end
  add_method_tracer :expensive_method_call
end
