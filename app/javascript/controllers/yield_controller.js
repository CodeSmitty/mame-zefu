import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["decrement", "increment", "yield"]

  connect() {
    console.log("yield file connected")
    const currentValue = this.yieldTarget.value
  }

  decrement(e) {
    e.preventDefault()
    let current = this.getCurrentValue()

    let newValue = current / 2

    let min = this.getOriginalValue()
    if (newValue >= 4) {
      let minValue
      this.yieldTarget.value = Math.floor(newValue)
      minValue = this.yieldTarget.value
      console.log(minValue)
    }
  }

  increment(e) {
    e.preventDefault()
    let current = this.getCurrentValue()

    if (current) {
      let newValue = current * 2

      let min = this.getOriginalValue()

      if ((newValue <= 100) & (newValue >= min)) {
        this.yieldTarget.value = newValue
        console.log(this.yieldTarget.value)
      }
    }
  }

  getCurrentValue() {
    return this.extractNumber(this.yieldTarget.value)
  }

  getOriginalValue() {
    if (!this.yieldTarget.dataset.originalValue) {
      this.yieldTarget.dataset.originalValue = this.getCurrentValue()
    }
    return this.extractNumber(this.yieldTarget.dataset.originalValue)
  }

  extractNumber(str) {
    const numericString = (str || "").replace(/[^\d.-]/g, "")
    const match = numericString.match(/-?\d+(?:\.\d+)?/)
    return match ? parseFloat(match[0]) : 0
  }
}
