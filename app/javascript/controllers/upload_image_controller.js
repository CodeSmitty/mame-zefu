import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image-input", "clear-preview-button"]

  connect() {
    document.addEventListener("change", (event) => {
      if (event.target.matches("#upload-image-input, #replace-image-input")) {
        this.previewImage(event)
      }
    })
  }

  replaceFileInput(inputId) {
    const oldInput = document.getElementById(inputId)

    if (!oldInput) return

    const newInput = document.createElement("input")
    newInput.type = "file"
    newInput.id = oldInput.id
    newInput.name = oldInput.name
    newInput.className = oldInput.className
    newInput.accept = oldInput.accept
    newInput.dataset.controller = oldInput.dataset.controller
    newInput.dataset.action = oldInput.dataset.action

    Array.from(oldInput.attributes).forEach((attr) => {
      if (attr.name.startsWith("data-")) {
        newInput.setAttribute(attr.name, attr.value)
      }
    })

    oldInput.parentNode.replaceChild(newInput, oldInput)

    return newInput
  }

  previewImage(event) {
    const file = event.target.files && event.target.files[0]
    if (!file || !file.type.startsWith("image/")) return

    const previewContainer =
      this.element.querySelector("#image-preview-container") ||
      document.getElementById("image-preview-container")
    const previewImage =
      this.element.querySelector("#image-preview") ||
      document.getElementById("image-preview")

    if (!previewImage) return

    const reader = new FileReader()
    reader.onload = (e) => {
      previewImage.src = e.target.result
      if (previewContainer) {
        if (event.target.id === "replace-image-input") {
          document
            .getElementById("display-image-container")
            .classList.add("hidden")
          document.getElementById("delete-image-button").classList.add("hidden")
        }
        previewContainer.classList.remove("hidden")
      }
    }
    reader.readAsDataURL(file)
  }
  // Added Line 56 and Line 84. showing and hiding image preview correctly after clearing the preview.
  clearPreview(event) {
    event.preventDefault()
    const previewContainer =
      this.element.querySelector("#image-preview-container") ||
      document.getElementById("image-preview-container")
    const previewImage =
      this.element.querySelector("#image-preview") ||
      document.getElementById("image-preview")
    const uploadInput = document.getElementById("upload-image-input")
    const replaceInput = document.getElementById("replace-image-input")

    if (uploadInput?.files.length) {
      this.replaceFileInput("upload-image-input")
    }

    if (replaceInput?.files.length) {
      this.replaceFileInput("replace-image-input")
    }

    if (previewContainer) {
      previewContainer.classList.add("hidden")
      document
        .getElementById("display-image-container")
        ?.classList.remove("hidden")
      document.getElementById("delete-image-button").classList.remove("hidden")
    }
    if (previewImage) {
      previewImage.src = ""
    }
  }
}
