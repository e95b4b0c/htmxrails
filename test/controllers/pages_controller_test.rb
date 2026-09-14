# frozen_string_literal: true

require "test_helper"

# The demo is an HTTP contract, so the tests assert the wire format: the shell
# for browsers, bare fragments plus out-of-band swaps for htmx.
class PagesControllerTest < ActionDispatch::IntegrationTest
  test "root renders the shell around an empty content region" do
    get root_url, headers: browser_headers

    assert_response :success
    assert_select "body.app[data-hx-headers]" # CSRF token inherited by every htmx request
    assert_select "main#main-content"
    assert_select "nav#site-nav a.nav-link[data-hx-get][data-hx-target=?]", "#main-content", count: 3
    assert_select "nav#site-nav a.nav-link.active", text: "Home"
    assert_select "div#clock[data-hx-trigger=?]", "every 2s"
  end

  test "tabs push their URL so every fragment stays a real route" do
    get root_url, headers: browser_headers

    assert_select "a[data-hx-get=?][data-hx-push-url=?]", about_path, "true"
    assert_select "a[data-hx-get=?]", root_path
    assert_select "a[data-hx-get=?]", contact_path
  end

  test "a browser request for a subpage renders the full shell" do
    get about_url, headers: browser_headers

    assert_response :success
    assert_includes response.body, "<!DOCTYPE html>"
    assert_select "main#main-content"
    assert_select "title#page-title", text: "About · HTMX on Rails"
    assert_select "nav#site-nav a.nav-link.active", text: "About"
    # The layout renders the nav in place; no out-of-band swap needed.
    assert_select "nav#site-nav[data-hx-swap-oob]", count: 0
  end

  test "an htmx request for a subpage renders the fragment and the out of band shell" do
    get about_url, headers: htmx_headers

    assert_response :success
    assert_not_includes response.body, "<!DOCTYPE"
    assert_not_includes response.body, "<body"
    assert_select "main#main-content", count: 0

    # The gem built these attributes: swap_oob: "outerHTML:#site-nav" becomes
    # data-hx-swap-oob, which is how the active tab and the title stay in sync.
    assert_select "nav#site-nav[data-hx-swap-oob=?] a.nav-link.active", "outerHTML:#site-nav", text: "About"
    assert_select "title#page-title[data-hx-swap-oob=?]", "outerHTML:#page-title",
                  text: "About · HTMX on Rails"
  end

  test "the contact page ships an htmx form that replaces its own card" do
    get contact_url, headers: browser_headers

    assert_response :success
    assert_select "div#contact-card form[data-hx-post=?][data-hx-target=?][data-hx-swap=?]",
                  contact_path, "#contact-card", "outerHTML"
    assert_select "form[novalidate]"
  end

  test "an invalid message returns 422 with the errors rendered in the form" do
    post contact_url, headers: htmx_headers,
         params: { contact_message: { name: "", email: "nope", body: "short" } }

    assert_response :unprocessable_content
    assert_select "div#contact-card div.errors li", minimum: 3
    assert_select "div#contact-card form[data-hx-post=?]", contact_path
    assert_nil response.headers["HX-Trigger"]
  end

  test "a valid message swaps in the sent card and triggers a client event" do
    post contact_url, headers: htmx_headers,
         params: { contact_message: { name: "Ada", email: "ada@example.com",
                                      body: "Hello from the test suite." } }

    assert_response :success
    assert_select "div#contact-card.card-success", text: /Thanks, Ada/
    assert_equal({ "contact:message-sent" => { "name" => "Ada" } },
                 JSON.parse(response.headers["HX-Trigger"]))
  end

  # The browser path end to end: the first response sets the encrypted session
  # cookie, the second request sends it back along with the CSRF token that the
  # layout put in data-hx-headers. Forgery protection is off in the test
  # environment, so it is switched on here to keep this honest.
  test "a form post carries the session cookie and the CSRF token" do
    ActionController::Base.allow_forgery_protection = true

    get contact_url, headers: browser_headers
    assert_response :success
    assert_includes response.headers["Set-Cookie"].to_s, "session"

    token = response.body[/name="csrf-token" content="([^"]+)"/, 1]
    assert token, "expected the layout to render the CSRF meta tag"

    post contact_url, headers: htmx_headers("X-CSRF-Token" => token),
         params: { contact_message: { name: "Ada", email: "ada@example.com",
                                      body: "Round trip through the session cookie." } }

    assert_response :success
    assert_select "div#contact-card.card-success", text: /Thanks, Ada/
  ensure
    ActionController::Base.allow_forgery_protection = false
  end

  test "the clock fragment polls itself" do
    get clock_url, headers: htmx_headers

    assert_response :success
    assert_select "div#clock[data-hx-get=?][data-hx-trigger=?][data-hx-swap=?]",
                  clock_path, "every 2s", "outerHTML"
  end
end
