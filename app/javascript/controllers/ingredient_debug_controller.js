import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  toggle() {
    this.panelTarget.classList.toggle("hidden")
    this.forceColumnReflow()
  }

  // Mobile browsers don't shrink CSS column heights when content collapses mid-column,
  // leaving stale whitespace below. Toggling display forces a synchronous relayout.
  forceColumnReflow() {
    const columns = this.element.closest("ul")
    if (!columns) return

    const previousDisplay = columns.style.display
    columns.style.display = "none"
    void columns.offsetHeight
    columns.style.display = previousDisplay
  }
}
