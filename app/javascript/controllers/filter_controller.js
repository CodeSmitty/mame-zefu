import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  initialize() {
    this.submit = debounce(this.submit.bind(this), 300)
  }

  submit(event) {
    this.element.requestSubmit()
  }
}