import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { recipeId: Number, originalYield: Number }
  static targets = ["input", "value"]
  connect() {
    this.loading = false
    this.baseYieldValue = this.originalYieldValue
    this.baseIngredientsValue = Array.from(
      document.querySelectorAll("[itemprop='recipeIngredient']"),
    )
      .map((item) => item.textContent.trim())
      .join("\n")
  }

  custom(event) {
    const newYield = parseInt(event.target.value, 10)
    if (isNaN(newYield) || newYield < 1 || newYield > this.maxServings) {
      alert(`Please enter a number between 1 and ${this.maxServings}`)
      event.target.value = this.originalYieldValue // revert
      return
    }
    this.updateYield(this.recipeIdValue, newYield)
  }

  async double(event) {
    event.preventDefault()
    if (this.loading) return
    this.loading = true

    const newYield = this.originalYieldValue * 2
    await this.updateYield(this.recipeIdValue, newYield)

    this.loading = false
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
        body: JSON.stringify({
          new_yield: newYield,
          original_yield: this.originalYieldValue,
          base_yield: this.baseYieldValue,
          base_ingredients: this.baseIngredientsValue,
        }),
      })

      if (response.ok) {
        const data = await response.json()
        this.originalYieldValue = newYield
        this.updateYieldDisplay(data?.yield)
        this.updateIngredientsDisplay(data?.ingredients)
      } else {
        console.error("Failed to update yield")
      }
    } catch (error) {
      console.error("Error updating yield:", error)
    }
  }

  updateYieldDisplay(newYield) {
    const valueElement = this.element.querySelector(
      "[data-yield-target-value='yield']",
    )
    if (valueElement) {
      valueElement.textContent = newYield
    }
  }

  updateIngredientsDisplay(ingredients) {
    if (!ingredients) return
    const lines = ingredients.split("\n").filter((line) => line.trim() !== "")
    const items = document.querySelectorAll("[itemprop='recipeIngredient']")
    items.forEach((item, index) => {
      if (lines[index] !== undefined) item.textContent = lines[index]
    })
  }
}
