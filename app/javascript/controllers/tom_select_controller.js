import { Controller } from "@hotwired/stimulus"
import TomSelect from 'tom-select'

export default class extends Controller {
  connect () {
    new TomSelect(this.element ,{
        plugins: ['remove_button'],
        create: true,
        createOnBlur: true,
        persist: false
    })
  }
}