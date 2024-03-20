import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initialHeight = this.element.offsetHeight
    this.resizeElement(this.element)
  }

  resize(event) {
    this.resizeElement(event.target)
  }

  resizeElement(element) {
    element.style.height = this.initialHeight + "px"
    element.style.height = element.scrollHeight + 3 + "px"
  }
}
