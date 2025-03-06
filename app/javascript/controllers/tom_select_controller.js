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
    this.onChange(this.element)
  }

  onChange() {
    const tsSelect = document.getElementsByClassName("ts-control")[0]

    document
      .getElementById("recipe_category_names-ts-control")
      .addEventListener("select", (e) => {
        tsSelect.style.borderColor = "#eeb14a"
      })
    document
      .getElementById("recipe_category_names-ts-control")
      .addEventListener("blur", (e) => {
        tsSelect.style.borderColor = "transparent"
      })
  }
}
