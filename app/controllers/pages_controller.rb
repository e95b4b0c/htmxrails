# frozen_string_literal: true

# Serves the demo pages. Each action can answer twice: with the full page shell
# for a normal browser request, or with the bare fragment htmx wants to swap in.
class PagesController < ApplicationController
  layout :page_layout

  CURRENT_PAGE = { "home" => :home, "about" => :about, "contact" => :contact,
                   "create_message" => :contact, "clock" => :home }.freeze

  before_action :set_current_page

  def home
    @message = ContactMessage.new
  end

  def about
  end

  def contact
    @message = ContactMessage.new
  end

  # POST /contact — the only non-GET action, driven by the htmx form.
  def create_message
    @message = ContactMessage.new(message_params)

    if @message.valid?
      # HX-Trigger becomes a `contact:message-sent` DOM event on the client,
      # with the JSON payload available as event.detail.
      htmx_response trigger: { "contact:message-sent" => { name: @message.name } }.to_json
      render partial: "pages/message_sent", locals: { message: @message }
    else
      # 422 so the response is honest about the failure. The client-side htmx
      # config in app/javascript/application.js keeps swapping on 422.
      render partial: "pages/contact_card", locals: { message: @message },
             status: :unprocessable_content
    end
  end

  # Polled fragment for the clock widget: answers with the clock itself.
  def clock
    render partial: "pages/clock"
  end

  private

  # The htmx gem parses the request headers for us: HTMX.request returns a Data
  # object and `request?` is true only when htmx issued the request. Fragments
  # skip the layout so the shell (header, nav, footer) is never re-sent.
  def page_layout
    htmx_request? ? false : "application"
  end

  def set_current_page
    @current_page = CURRENT_PAGE.fetch(action_name, :home)
  end

  def message_params
    params.require(:contact_message).permit(:name, :email, :body)
  end
end
