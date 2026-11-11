import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  initialize() {
    this.throttledSubmit = debounce(this.submit, 800).bind(this)
  }

  rememberFocus() {
    const target = document.activeElement
    if (!this.element.contains(target)) {
      this.focusedElement = null
      return
    }

    this.focusedElement = {
      target,
      selectionStart:
        typeof target.selectionStart === "number"
          ? target.selectionStart
          : null,
      selectionEnd:
        typeof target.selectionEnd === "number" ? target.selectionEnd : null,
      selectionDirection: target.selectionDirection,
    }
  }

  restoreFocus() {
    const focusedElement = this.focusedElement
    this.focusedElement = null
    if (!focusedElement?.target.isConnected) return

    requestAnimationFrame(() => {
      if (document.activeElement !== document.body) return

      const { target, selectionStart, selectionEnd, selectionDirection } =
        focusedElement
      target.focus()
      if (
        selectionStart !== null &&
        selectionEnd !== null &&
        typeof target.setSelectionRange === "function"
      ) {
        target.setSelectionRange(
          selectionStart,
          selectionEnd,
          selectionDirection,
        )
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
