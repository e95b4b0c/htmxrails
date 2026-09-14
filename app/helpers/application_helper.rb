# frozen_string_literal: true

module ApplicationHelper
  # The swap target every navigation link points at.
  MAIN_CONTENT = "#main-content"

  # The gem turns snake_case keys into dashed, prefixed attributes:
  #
  #   HTMX[get: "/about", target: "#main-content", push_url: true]
  #   # => {"data-hx-get" => "/about",
  #   #     "data-hx-target" => "#main-content",
  #   #     "data-hx-push-url" => true}
  #
  # htmx accepts both the hx- and data-hx- prefixes; the gem defaults to the
  # latter because it is valid HTML5 for any element.
  def htmx_nav_attributes(path)
    HTMX[get: path, target: MAIN_CONTENT, swap: "innerHTML", push_url: true,
         indicator: "#nav-indicator"]
  end

  # A link that asks htmx to swap the main content region in place instead of
  # navigating the whole page.
  def htmx_link(label, path, **options)
    link_to label, path, **htmx_nav_attributes(path), **options
  end

  # A nav tab, highlighted for the page currently being displayed.
  def nav_link(label, path, current:, page:)
    active = current == page

    htmx_link label, path,
              class: class_names("nav-link", active: active),
              role: "tab",
              "aria-current": (active ? "page" : nil)
  end

  # Emitted by every page: sets the document title and, when htmx asked for a
  # fragment, ships the nav and the title along as out-of-band swaps so the
  # active tab and the browser tab title stay in sync. Full page requests get
  # the nav from the layout instead, so nothing is rendered here.
  def page_nav(current, title)
    content_for :title, title

    return unless htmx_request?

    render "shared/nav", current: current, title: title, oob: true
  end

  # Body level htmx configuration. hx-headers is inherited by every element, so
  # one CSRF token here covers every htmx request on the page. The gem builds
  # the attribute; the value has to be JSON by hand.
  def htmx_body_attributes
    HTMX[headers: { "X-CSRF-Token" => form_authenticity_token }.to_json]
  end

  def htmx_gem_version
    Gem.loaded_specs["htmx"]&.version
  end
end
