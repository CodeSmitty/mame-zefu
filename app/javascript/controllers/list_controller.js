import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.element.classList.add("cursor-pointer")
  }

  strike(event) {
    event.target.classList.toggle("line-through")
  }

  focus(event) {
    this.itemTargets.forEach((item) => {
      if (item !== event.target) {
        item.classList.remove("font-bold")
      }
    })
    event.target.classList.toggle("font-bold")
  }
}
