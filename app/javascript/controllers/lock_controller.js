import { Controller } from "@hotwired/stimulus"

// Freezes the sidebar while a practice session is running. Link clicks and
// back/forward history are cancelled server pages can't be reached; closing
// the tab warns. Submitting sets `submitting` so Turbo may navigate to the
// result page, then disconnect restores navigation.
export default class extends Controller {
  connect() {
    this.submitting = false

    this.links = Array.from(document.querySelectorAll(
      ".sidebar a[href], .sidebar button:not(.nav-toggle)"
    ))
    this.links.forEach((el) => {
      el.dataset.lockedTabIndex = String(el.tabIndex)
      el.tabIndex = -1
      el.setAttribute("aria-disabled", "true")
      el.style.pointerEvents = "none"
      el.style.opacity = "0.45"
      el.style.cursor = "not-allowed"
    })
    document.documentElement.classList.add("nav-locked")

    this.onBeforeVisit = (event) => {
      if (!this.submitting) event.preventDefault()
    }
    document.addEventListener("turbo:before-visit", this.onBeforeVisit)

    this.onBeforeUnload = (event) => {
      event.preventDefault()
      event.returnValue = ""
      return ""
    }
    window.addEventListener("beforeunload", this.onBeforeUnload)
  }

  disconnect() {
    this.links.forEach((el) => {
      el.tabIndex = Number(el.dataset.lockedTabIndex)
      el.removeAttribute("aria-disabled")
      el.style.pointerEvents = ""
      el.style.opacity = ""
      el.style.cursor = ""
      delete el.dataset.lockedTabIndex
    })
    document.documentElement.classList.remove("nav-locked")

    document.removeEventListener("turbo:before-visit", this.onBeforeVisit)
    window.removeEventListener("beforeunload", this.onBeforeUnload)
  }

  markSubmit() {
    this.submitting = true
  }
}
