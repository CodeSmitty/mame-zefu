import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  static targets = ["query"]

  initialize() {
    this.focusQueryAfterSubmit = false
    this.throttledSubmit = debounce(this.submit, 800).bind(this)
  }

  focus() {
    if (!this.focusQueryAfterSubmit) return

    this.focusQueryAfterSubmit = false
    const input = this.queryTarget

    if (!input) return

    requestAnimationFrame(() => {
      input.focus()
      const end = input.value.length
      if (typeof input.setSelectionRange === "function") {
        input.setSelectionRange(end, end)
      }
    })
  }

  submit(event) {
    this.focusQueryAfterSubmit = event?.target?.name === "query"

    if (event) {
      event.preventDefault()
    }

    this.element.requestSubmit()
  }
}
