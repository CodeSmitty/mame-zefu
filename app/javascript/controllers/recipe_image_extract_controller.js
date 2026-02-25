import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "fileField"]
  static values = {
    url: String,
    sparklesIcon: String,
  }

  // TODO: This could probably re-use some of the logic in the RecipeFormController for setting field values and dispatching events

  connect() {
    this.loading = false
    this.updateButtonState(this.hasImageFile())
  }

  imageFileChange(event) {
    this.updateButtonState(event.detail?.hasFile === true)
  }

  async extract(event) {
    event.preventDefault()
    if (this.loading || !this.hasImageFile()) return

    this.loading = true
    this.renderButton({ disabled: true, label: "Extracting..." })

    try {
      const token = document
        .querySelector('meta[name="csrf-token"]')
        .getAttribute("content")

      const formData = new FormData()
      formData.append("image", this.fileFieldTarget.files[0])

      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "X-CSRF-Token": token,
          Accept: "application/json",
        },
        body: formData,
      })

      const payload = await response.json().catch(() => ({}))
      if (!response.ok) {
        throw new Error(payload.error || "Unable to extract recipe from image.")
      }

      this.populateFields(payload.recipe || {})
    } catch (error) {
      console.error(error)
      alert(error.message)
    } finally {
      this.loading = false
      this.updateButtonState(this.hasImageFile())
    }
  }

  hasImageFile() {
    return this.hasFileFieldTarget && this.fileFieldTarget.files.length > 0
  }

  updateButtonState(enabled) {
    this.renderButton({ disabled: !enabled, label: "Extract Recipe" })
  }

  renderButton({ disabled, label }) {
    this.buttonTarget.disabled = disabled
    this.buttonTarget.classList.toggle("opacity-60", disabled)
    this.buttonTarget.classList.toggle("cursor-not-allowed", disabled)
    this.buttonTarget.classList.toggle("hover:bg-secondary", !disabled)
    this.buttonTarget.classList.toggle("hover:text-white", !disabled)
    this.buttonTarget.innerHTML = `${this.sparklesIconValue}${label}`
  }

  populateFields(recipe) {
    this.setValue("name", recipe.name || "")
    this.setValue("yield", recipe.yield || "")
    this.setValue("prep_time", recipe.prep_time || "")
    this.setValue("cook_time", recipe.cook_time || "")
    this.setValue("total_time", recipe.total_time || "")
    this.setValue("description", recipe.description || "")
    this.setListValue("ingredients", recipe.ingredients || [])
    this.setListValue("directions", recipe.directions || [])
    this.setCategoryNames(recipe.category_names || [])
  }

  setValue(fieldName, value) {
    const field = this.formElement.querySelector(
      `[name="recipe[${fieldName}]"]`,
    )
    if (!field) return

    field.value = value
    this.dispatchInput(field)
  }

  setListValue(fieldName, values) {
    const field = this.formElement.querySelector(
      `[name="recipe[${fieldName}]"]`,
    )
    if (!field) return

    const normalized = Array.isArray(values)
      ? values.join("\n")
      : String(values || "")
    field.value = normalized
    this.dispatchInput(field)
  }

  setCategoryNames(categoryNames) {
    const select = this.formElement.querySelector(
      'select[name="recipe[category_names][]"]',
    )
    if (!(select instanceof HTMLSelectElement)) return

    const normalized = Array.isArray(categoryNames)
      ? categoryNames
          .map((name) => String(name).trim())
          .filter((name) => name.length > 0)
      : []

    if (select.tomselect) {
      select.tomselect.clear(true)
      normalized.forEach((name) => {
        select.tomselect.addOption({ value: name, text: name })
      })
      select.tomselect.setValue(normalized, true)
    } else {
      const options = Array.from(select.options || [])
      options.forEach((option) => {
        option.selected = normalized.includes(option.value)
      })

      normalized.forEach((name) => {
        if (options.some((option) => option.value === name)) return

        const option = document.createElement("option")
        option.value = name
        option.text = name
        option.selected = true
        select.appendChild(option)
      })
    }

    this.dispatchInput(select)
  }

  dispatchInput(element) {
    element.dispatchEvent(new Event("input", { bubbles: true }))
    element.dispatchEvent(new Event("change", { bubbles: true }))
  }

  get formElement() {
    return this.element.closest("form")
  }
}
