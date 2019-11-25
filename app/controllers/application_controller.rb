class ApplicationController < ActionController::Base
  def render_stream(enumerator)
    headers['Cache-Controller'] = 'no-cache'
    headers['Last-Modified'] = Time.now.utc.httpdate
    self.response_body = enumerator
  end
end
