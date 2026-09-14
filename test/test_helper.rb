ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# Request helpers for the htmx controller tests: `allow_browser versions:
# :modern` needs a real user agent, and htmx requests are identified by the
# HX-Request header.
module HtmxTestHelpers
  USER_AGENT = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36"

  def browser_headers(**extra)
    { "User-Agent" => USER_AGENT }.merge(extra)
  end

  # Roughly what htmx 2 sends when a tab is clicked.
  def htmx_headers(**extra)
    browser_headers(
      "HX-Request" => "true",
      "HX-Trigger" => "site-nav",
      "HX-Target" => "main-content",
      "HX-Current-URL" => root_url,
      **extra
    )
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    include HtmxTestHelpers
  end
end
