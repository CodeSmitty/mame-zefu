import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["previewImage", "deleteButton", "uploadButton", "fileField"]
  static values = {
    deleteUrl: String,
    defaultSrc: String,
    persistedSrc: String,
    previewSrc: String,
    deleteIcon: String,
    cancelIcon: String,
    uploadIcon: String,
  }

  connect() {
    this.updateUi()
    this.notifyImageFileState()
  }

  previewSrcValueChanged() {
    this.updateUi()
  }

  persistedSrcValueChanged() {
    this.updateUi()
  }

  updateUi() {
    // preview image
    this.previewImageTarget.src =
      this.previewSrcValue || this.persistedSrcValue || this.defaultSrcValue

    // delete button
    if (this.previewSrcValue) {
      this.deleteButtonTarget.classList.toggle("hidden", false)
      this.deleteButtonTarget.innerHTML = this.cancelIconValue
    } else if (this.persistedSrcValue) {
      this.deleteButtonTarget.classList.toggle("hidden", false)
      this.deleteButtonTarget.innerHTML = this.deleteIconValue
    } else {
      this.deleteButtonTarget.classList.toggle("hidden", true)
    }

    // upload button
    const uploadButtonText = this.persistedSrcValue
      ? "Replace Image"
      : "Upload Image"
    this.uploadButtonTarget.innerHTML = this.uploadIconValue + uploadButtonText
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

    this.notifyImageFileState()
  }

  deleteButtonClick() {
    if (this.previewSrcValue) {
      this.fileFieldTarget.value = null
      this.previewSrcValue = undefined

      const newInput = this.fileFieldTarget.cloneNode(false)
      this.fileFieldTarget.replaceWith(newInput)
      this.notifyImageFileState()
    } else if (this.persistedSrcValue) {
      this.deletePersistedImage()
    }
  }

  uploadButtonClick() {
    this.fileFieldTarget.click()
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

  notifyImageFileState() {
    const hasFile = this.fileFieldTarget.files.length > 0
    this.dispatch("file-change", { detail: { hasFile } })
  }
}
