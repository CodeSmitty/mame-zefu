import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  async toggleFavorite() {
    const recipeId = this.element.dataset.recipeId;
    const toggleFavoriteUrl = this.element.dataset.toggleFavoriteUrl;
    
    try {
      const response = await fetch(toggleFavoriteUrl, { method: "POST" });
      if (!response.ok) throw new Error("Failed to toggle favorite");
      
      const data = await response.json();
      this.element.innerHTML = data.is_favorite ? "<%= escape_javascript(render('icons/mini/heart')) %>" : "<%= escape_javascript(render('icons/mini/empty_heart')) %>";
    } catch (error) {
      console.error(error);
    }
  }
}
