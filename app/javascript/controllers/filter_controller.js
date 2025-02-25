import { Controller } from "@hotwired/stimulus"
import  debounce  from "lodash"

export default class extends Controller {
  initialize() {
    this.autoSubmit = debounce(this.autoSubmit, 300).bind(this)
  }

 autoSubmit() {
    this.element.requestSubmit()
  }
}
