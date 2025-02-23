import { Controller } from "@hotwired/stimulus"
import debounce from "lodash/debounce"

export default class extends Controller {
  static targets = ["query", "category"];

  initialize() {
    this.submit = debounce(this.submit.bind(this), 300);
  }

  connect() {
    this.queryTarget.addEventListener("input", this.submit);
    this.categoryTarget.addEventListener("input", this.submit);
  }

  submit() {
    console.log('form=submit')
    this.element.requestSubmit();
  }
}
