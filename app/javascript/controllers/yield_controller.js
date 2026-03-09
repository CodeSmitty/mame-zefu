import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Hello controller connected")
  }

  async decrement(event) {
    event.preventDefault()
    const recipeId = this.data.get("recipe-id-value")
    const originalYield = parseFloat(this.data.get("original-value"))
    await this.updateYield(recipeId, originalYield - 1)
  }

  async increment(event) {
    event.preventDefault()
    const recipeId = this.data.get("recipe-id-value")
    const originalYield = parseFloat(this.data.get("original-value"))
    await this.updateYield(recipeId, originalYield + 1)
  }

  async updateYield(recipeId, newYield) {
    try {
      const response = await fetch(`/recipes/${recipeId}/update_yield`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ yield: newYield }),
      })

      if (response.ok) {
        const data = await response.json()
        this.updateYieldDisplay(data.new_yield)
      } else {
        console.error("Failed to update yield")
      }
    } catch (error) {
      console.error("Error updating yield:", error)
    }
  }

  updateYieldDisplay(newYield) {
    const valueElement = this.element.querySelector(
      "[data-yield-target='value']",
    )
    if (valueElement) {
      valueElement.textContent = newYield
    }
  }
}
