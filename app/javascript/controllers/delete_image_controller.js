import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]
  static values = {
    url: String,
  }

  connect() {
    this.buttonTarget.addEventListener("click", this.deleteImage.bind(this))
  }

  async deleteImage(event) {
    event.preventDefault()

    const token = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute("content")

    try {
      const response = await fetch(this.urlValue, {
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": token,
          accept: "text/html, application/json",
        },
      })

      if (!response.ok) throw new Error("Failed to delete image")

      // Optionally, you can handle UI updates here after successful deletion
      console.log("Image deleted successfully")
      window.location.reload() // Reload the page to reflect changes
    } catch (error) {
      console.error(error)
    }
  }
}
