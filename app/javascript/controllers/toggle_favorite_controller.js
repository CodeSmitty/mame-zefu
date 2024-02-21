import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button"];
  
  connect() {
    this.buttonTarget.addEventListener('click', this.toggleFavorite.bind(this));
  }

  async toggleFavorite(event) {
    const token = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
    event.preventDefault();
    const isFavorite = this.element.getAttribute("data-is-favorite")
    const toggleFavoriteUrl = this.element.dataset.toggleFavoriteUrl;
    try {

      const response = await fetch(toggleFavoriteUrl, { method: "POST", 
      headers:{
        'Content-Type': 'application/json'
      , 'X-CSRF-Token': token
      }})
      if (!response.ok) throw new Error("Failed to toggle favorite");

      const data = await response.json();
      this.updateHeartIcon(data.is_favorite);
    } catch (error) {
      console.error(error);
    }
  }
  
  updateHeartIcon(isFavorite) {
    const heart = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5 <%= style if defined?(style) %> text-rose-600">
  <path d="m9.653 16.915-.005-.003-.019-.01a20.759 20.759 0 0 1-1.162-.682 22.045 22.045 0 0 1-2.582-1.9C4.045 12.733 2 10.352 2 7.5a4.5 4.5 0 0 1 8-2.828A4.5 4.5 0 0 1 18 7.5c0 2.852-2.044 5.233-3.885 6.82a22.049 22.049 0 0 1-3.744 2.582l-.019.01-.005.003h-.002a.739.739 0 0 1-.69.001l-.002-.001Z" />
</svg>`;

    const heart_outline = `<svg class="h-5 w-5 text-red-500"  fill="none" viewBox="0 0 24 24" stroke="currentColor">
  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"/>
</svg>`
    this.buttonTarget.innerHTML = isFavorite ? heart : heart_outline;
  }
}
