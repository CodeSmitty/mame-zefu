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
      if (previewContainer) previewContainer.classList.remove("hidden")
    }
    reader.readAsDataURL(file)
  }

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
      const clonedInput = uploadInput.cloneNode(true)
      uploadInput.parentNode.replaceChild(clonedInput, uploadInput)
    }

    if (replaceInput?.files.length) {
      const clonedInput = replaceInput.cloneNode(true)
      replaceInput.parentNode.replaceChild(clonedInput, replaceInput)
    }

    if (previewContainer) {
      previewContainer.classList.add("hidden")
    }
    if (previewImage) {
      previewImage.src = ""
    }
  }
}
