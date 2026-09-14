# frozen_string_literal: true

# Source snippets shown on the demo pages. Keeping them in Ruby (instead of
# inside ERB heredocs) keeps the templates readable, and every snippet is
# escaped by the tag builder when it is rendered.
module CodeSampleHelper
  SAMPLES = {
    nav: <<~RUBY,
      # app/views/shared/_nav.html.erb
      HTMX[get: path,
           target: "#main-content",
           swap: "innerHTML",
           push_url: true]
      # => {"data-hx-get"      => path,
      #     "data-hx-target"   => "#main-content",
      #     "data-hx-swap"     => "innerHTML",
      #     "data-hx-push-url" => true}
    RUBY
    layout: <<~RUBY,
      # app/controllers/pages_controller.rb
      layout :page_layout

      def page_layout
        htmx_request? ? false : "application"
      end
    RUBY
    request: <<~RUBY,
      # app/controllers/application_controller.rb
      def htmx_request
        @htmx_request ||= HTMX.request(**request.headers.env)
      end

      def htmx_request?
        htmx_request.request?
      end

      htmx_request.source        # "button"
      htmx_request.target        # "#main-content"
      htmx_request.current_url   # "/about"
    RUBY
    oob: <<~ERB,
      <%# app/views/shared/_nav.html.erb %>
      <% nav_attributes = { id: "site-nav", class: "nav" } %>
      <% nav_attributes.merge! HTMX[swap_oob: "outerHTML:#site-nav"] if oob %>
      <%= tag.nav(**nav_attributes) do %>
        ...
      <% end %>
    ERB
    clock: <<~ERB,
      <%# app/views/pages/_clock.html.erb — the fragment replaces itself %>
      <%= tag.div(id: "clock",
                  **HTMX[get: clock_path, trigger: "every 2s", swap: "outerHTML"]) do %>
        ...
      <% end %>
    ERB
    form: <<~ERB,
      <%# app/views/pages/_contact_card.html.erb — form_with only forwards
          id/class/multipart/method/data/authenticity_token, so htmx attributes
          ride in through html: %>
      <%= form_with model: message, url: contact_path,
                    html: { novalidate: true }.merge(
                      HTMX[post: contact_path,
                           target: "#contact-card",
                           swap: "outerHTML",
                           indicator: "#contact-indicator",
                           disabled_elt: "find button"] ) do |form| %>
        ...
      <% end %>
    ERB
    response: <<~RUBY,
      # app/controllers/pages_controller.rb
      if @message.valid?
        htmx_response trigger: { "contact:message-sent" => { name: @message.name } }.to_json
        render partial: "pages/message_sent", locals: { message: @message }
      else
        render partial: "pages/contact_card", locals: { message: @message },
               status: :unprocessable_content
      end
    RUBY
    csrf: <<~ERB
      <%# app/views/layouts/application.html.erb — inherited by every element %>
      <%= tag.body(**HTMX[headers: { "X-CSRF-Token" => form_authenticity_token }.to_json]) do %>
        ...
      <% end %>
    ERB
  }.freeze

  def code_sample(key) = tag.pre(tag.code(SAMPLES.fetch(key)), class: "code")
end
