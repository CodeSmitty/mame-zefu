import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { create: Boolean }
  connect() {
    new TomSelect(this.element, {
      plugins: ["remove_button", "input_autogrow"],
      create: this.createValue,
      createOnBlur: true,
      persist: false,
      onItemAdd: function () {
        this.setTextboxValue("")
        this.refreshOptions()
      },
    })
  }
}
