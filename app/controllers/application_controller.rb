class ApplicationController < ActionController::Base
  include HtmxResponses

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :htmx_request, :htmx_request?

  private

  # Parsed htmx request headers. HTMX.request hands back a Data object whose
  # members are named after the headers with the HX- prefix removed:
  #
  #   #<data HTMX::Headers::Request boosted=nil current_url="/" history_restore_request=nil
  #     request="true" request_type=nil source=nil target="#main-content">
  def htmx_request
    @htmx_request ||= HTMX.request(**request.headers.env)
  end

  def htmx_request?
    htmx_request.request?
  end
end
