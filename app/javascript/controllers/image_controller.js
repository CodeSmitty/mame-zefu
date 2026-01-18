import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewImage", "deleteButton", "fileField"]
  static values = {
    deleteUrl: String,
    defaultSrc: String,
    persistedSrc: String,
    previewSrc: String,
  }

  previewSrcValueChanged() {
    this.updatePreviewImage()
  }

  persistedSrcValueChanged() {
    this.updatePreviewImage()
  }

  updatePreviewImage() {
    this.previewImageTarget.src =
      this.previewSrcValue || this.persistedSrcValue || this.defaultSrcValue
  }

  fileFieldChange(event) {
    const file = event.target.files[0]

    if (file) {
      const reader = new FileReader()
      reader.onload = (e) => {
        this.previewSrcValue = e.target.result
      }
      reader.readAsDataURL(file)
    } else {
      this.previewSrcValue = undefined
    }
  }

  deleteButtonClick() {
    if (this.previewSrcValue) {
      this.previewSrcValue = undefined
      const newInput = this.fileFieldTarget.cloneNode(false)
      this.fileFieldTarget.replaceWith(newInput)
      this.fileFieldTarget = newInput
    } else if (this.persistedSrcValue) {
      this.deletePersistedImage()
      document.getElementById("upload-image-button").textContent =
        "Upload Image"
    }
  }

  async deletePersistedImage() {
    const token = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content")

    try {
      const response = await fetch(this.deleteUrlValue, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          accept: "text/html, application/json",
        },
      })
      if (!response.ok) throw new Error("Failed to delete image")

      this.persistedSrcValue = undefined
    } catch (error) {
      console.error(error)
    }
  }
}
