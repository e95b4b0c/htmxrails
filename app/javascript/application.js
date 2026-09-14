// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
//
// htmx is pulled in here, through the import map, so the layout needs no separate
// script tag and there is no load-order to reason about. The ESM build exports
// the htmx object and initialises itself; assigning it to window keeps `htmx`
// reachable from hx-on expressions, extensions and the browser console.
//
// No Turbo and no Stimulus, on purpose: Turbo Drive would highjack the same link
// clicks and form submissions that htmx handles, and Stimulus would only be a
// second, unused way of attaching behaviour to the same DOM.
import htmx from "htmx"

window.htmx = htmx

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
