import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  initialize() {
    this.submit = debounce(this.submit, 500).bind(this)
  }

  submit() {
    this.element.requestSubmit()
  }
}
