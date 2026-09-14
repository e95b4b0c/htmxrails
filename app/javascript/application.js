// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
//
// Turbo is deliberately not imported: Turbo Drive would highjack the same link
// clicks and form submissions that htmx is here to handle. htmx itself is loaded
// as a classic script from vendor/javascript in app/views/layouts/application.html.erb.
import "controllers"

// htmx leaves 4xx responses alone by default, which would drop the
// re-rendered form that Rails returns with a 422. Swap it, but leave the
// other client errors and server errors as errors.
htmx.config.responseHandling = [
  { code: "204", swap: false },
  { code: "[23]..", swap: true },
  { code: "422", swap: true },
  { code: "[45]..", swap: false, error: true }
]

// `HX-Trigger: {"contact:message-sent":{"name":"Ada"}}` reaches the browser as a
// DOM event, with the JSON payload in event.detail. Nothing else to wire up.
document.body.addEventListener("contact:message-sent", (event) => {
  const region = document.getElementById("toast-region")
  if (!region) return

  const toast = document.createElement("div")
  toast.className = "toast"
  toast.textContent = `Message from ${event.detail.name} received by the server.`
  region.append(toast)

  setTimeout(() => toast.classList.add("toast-out"), 3200)
  setTimeout(() => toast.remove(), 3700)
})
