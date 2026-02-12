import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._observer = new MutationObserver(this.onMutations.bind(this))
    this._observer.observe(this.element, { childList: true, subtree: true })

    this.attachHandlers()
  }

  disconnect() {
    this.detachHandlers()
    this._observer?.disconnect()
  }

  onMutations(mutations) {
    for (const mutation of mutations) {
      if (mutation.type === "childList") {
        this.attachHandlers()
      }
    }
  }

  attachHandlers() {
    const input = this.element.querySelector("input.gsc-input")
    if (!input || input.dataset.urlHandlerBound === "true") return

    const form = input.closest("form")
    this._input = input
    this._form = form

    this._onKeyDown = this.onKeyDown.bind(this)
    this._onSubmit = this.onSubmit.bind(this)

    input.addEventListener("keydown", this._onKeyDown, true)
    form?.addEventListener("submit", this._onSubmit, true)

    input.dataset.urlHandlerBound = "true"
    input.setAttribute(
      "title",
      "Paste a recipe URL and press Enter to import it directly.",
    )
    input.setAttribute("placeholder", "Search or paste a recipe URL")
  }

  detachHandlers() {
    if (this._input && this._onKeyDown) {
      this._input.removeEventListener("keydown", this._onKeyDown, true)
      delete this._input.dataset.urlHandlerBound
    }

    if (this._form && this._onSubmit) {
      this._form.removeEventListener("submit", this._onSubmit, true)
    }

    this._input = null
    this._form = null
    this._onKeyDown = null
    this._onSubmit = null
  }

  onKeyDown(event) {
    if (event.key !== "Enter") return

    this.handleUrlSubmit(event, event.currentTarget.value)
  }

  onSubmit(event) {
    this.handleUrlSubmit(event, this._input?.value)
  }

  handleUrlSubmit(event, value) {
    const url = this.extractUrl(value)
    if (!url) return

    event.preventDefault()
    event.stopImmediatePropagation()
    this.redirectToImport(url)
  }

  extractUrl(value) {
    if (!value) return null

    const trimmed = value.trim()
    if (!/^https?:\/\//i.test(trimmed)) return null

    try {
      return new URL(trimmed).toString()
    } catch {
      return null
    }
  }

  redirectToImport(url) {
    const params = new URLSearchParams({ url })
    window.location.href = `web_result?${params}`
  }
}
