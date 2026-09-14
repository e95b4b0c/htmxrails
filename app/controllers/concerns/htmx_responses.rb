# frozen_string_literal: true

# Writes htmx response headers using the htmx gem's header map, so callers can
# use the gem's snake_case names instead of the raw HTTP header names:
#
#   htmx_response trigger: "contact:message-sent", push_url: "/contact"
#   # => HX-Trigger:   contact:message-sent
#   #    HX-Push-Url: /contact
#
# See HTMX::RESPONSE_MAP for every supported key.
module HtmxResponses
  extend ActiveSupport::Concern

  private

  # Builds the headers with HTMX.response! and writes each one to the response.
  def htmx_response(**attributes)
    HTMX.response!({}, **attributes).each { |name, value| response.headers[name] = value }
  end
end
