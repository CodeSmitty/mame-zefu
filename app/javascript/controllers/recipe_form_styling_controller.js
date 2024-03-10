import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    connect() {

        const tx = document.getElementsByTagName("textarea");

        for (let i = 0; i < tx.length; i++) {
            tx[i].setAttribute('style', `height: ${tx[i]?.id === 'recipe_description' || tx[i]?.id === 'recipe_notes' ? '70px' : '230px'}`);
            tx[i].addEventListener("input", OnInput, false);
        }

        function OnInput() {
            this.style.height = this?.id === 'recipe_description' || this?.id === 'recipe_notes' ? "70px" : "230px";
            this.style.height = (this.scrollHeight) + "px";
        }
    }
}