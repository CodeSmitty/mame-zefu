import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.initializeObserver(this.element);
  }

  initializeObserver(targetNode) {
    const config = { attributes: false, childList: true, subtree: true };
    this.searchResultsObserver = new MutationObserver(this.searchResultsCallback);
    this.searchResultsObserver.observe(targetNode, config);
  }

  searchResultsCallback(mutationList, observer) {
    for (const mutation of mutationList) {
      if (mutation.type === "childList") {
        for (const node of mutation.addedNodes) {
          if (node.nodeType === Node.ELEMENT_NODE && node.matches("div.gsc-result")) {
            const link = node.querySelector("div.gs-result a");
            link.addEventListener("click", function (e) {
              e.preventDefault();
              console.log(this.getAttribute("href"))
            });
          }
        }
      }
    }
  };

  disconnect() {
    this.searchResultsObserver.disconnect();
  }
}