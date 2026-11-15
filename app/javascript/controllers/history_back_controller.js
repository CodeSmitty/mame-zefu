import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  disconnect() {
    if (this.onPopState) {
      window.removeEventListener("popstate", this.onPopState, true)
    }
  }

  back(event) {
    if (
      event.defaultPrevented ||
      event.button !== 0 ||
      event.metaKey ||
      event.ctrlKey ||
      event.shiftKey ||
      event.altKey ||
      window.history.length <= 1
    )
      return

    event.preventDefault()
    if (this.onPopState) return

    const currentPage = window.location.pathname + window.location.search
    this.onPopState = (popstate) => {
      this.onPopState = null
      const previousPage = window.location.pathname + window.location.search
      if (!popstate.state?.turbo && previousPage !== currentPage) {
        // Turbo treats history entries without its state as same-page changes.
        popstate.stopImmediatePropagation()
        window.location.reload()
      }
    }
    window.addEventListener("popstate", this.onPopState, {
      capture: true,
      once: true,
    })
    window.history.back()
  }
}
