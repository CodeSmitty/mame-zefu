import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox"]

  submit() {
    this.checkboxTarget.form.requestSubmit()
  }
}
