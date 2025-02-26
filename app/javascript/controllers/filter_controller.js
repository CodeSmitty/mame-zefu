import { Controller } from "@hotwired/stimulus"
import debounce from "lodash"

export default class extends Controller {
  connect() {
    this.autoSubmit = debounce(this.submit.bind(this), 500)
  }

  submit() {
    this.element.requestSubmit()
  }
}
