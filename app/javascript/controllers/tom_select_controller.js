import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  static values = { create: Boolean, suppressSuggestions: Boolean }
  connect() {
    const select = new TomSelect(this.element, {
      plugins: ["remove_button", "input_autogrow"],
      create: this.createValue,
      createOnBlur: true,
      persist: false,
      onItemAdd: function () {
        this.setTextboxValue("")
        this.refreshOptions()
      },
    })

    if (this.suppressSuggestionsValue) {
      select.control_input.setAttribute("autocomplete", "off")
      select.control_input.setAttribute("autocorrect", "off")
      select.control_input.setAttribute("spellcheck", "false")
    }
  }
}
