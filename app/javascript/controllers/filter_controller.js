import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  initialize() {
    this.throttledSubmit = debounce(this.submit, 800).bind(this)
  }

  focus() {
    const input = document.querySelector(
      "input[name='query'], input[type='search'], input[type='text']",
    )

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
    if (event) {
      event.preventDefault()
    }

    this.element.requestSubmit()
  }
}
