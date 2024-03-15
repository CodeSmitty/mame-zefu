import { Controller } from "@hotwired/stimulus"
import TomSelect from "tom-select"

export default class extends Controller {
  connect() {

    new TomSelect(this.element, {
      plugins: ['remove_button', 'input_autogrow', 'change_listener'],
      create: true,
      createOnBlur: true,
      persist: false,
      itemClass: "category-items",
      optionClass: "category-dropdown",
      onItemAdd: function () {
        this.setTextboxValue('');
        this.refreshOptions();
      }
    })

    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
      // true for mobile device
      const ts = document.getElementsByClassName("ts-control")
      ts[0].setAttribute("style", "height: 70px !important")
    } else {
      const ts = document.getElementsByClassName("ts-control")
      ts[0].setAttribute("style", "height: 40px !important")
    }
  }
}