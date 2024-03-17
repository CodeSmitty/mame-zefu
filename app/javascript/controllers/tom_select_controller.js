import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {
    new TomSelect(this.element, {
      plugins: ["remove_button", "input_autogrow"],
      create: true,
      createOnBlur: true,
      persist: false,
      itemClass: "category-items",
      optionClass: "category-dropdown",
      onItemAdd: function () {
        this.setTextboxValue("")
        this.refreshOptions()
      },
    })
  }
}
