import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];
  static values = {
    isFavorite: Boolean,
    url: String,
    heart: String,
    emptyHeart: String
  }

  connect() {
    this.updateHeartIcon();
    this.buttonTarget.addEventListener('click', this.toggleFavorite.bind(this));
  }

  async toggleFavorite(event) {
    event.preventDefault();

    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': token
        }
      })
      if (!response.ok) throw new Error("Failed to toggle favorite");

      const data = await response.json();
      this.isFavoriteValue = data.is_favorite;
      this.updateHeartIcon();
    } catch (error) {
      console.error(error);
    }
  }

  updateHeartIcon() {
    this.buttonTarget.innerHTML = this.isFavoriteValue ? this.heartValue : this.emptyHeartValue
  }
}