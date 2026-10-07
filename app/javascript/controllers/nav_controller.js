import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (localStorage.getItem("study-nav") === "closed") {
      document.documentElement.classList.add("nav-collapsed")
    }
  }

  toggle() {
    const closed = document.documentElement.classList.toggle("nav-collapsed")
    localStorage.setItem("study-nav", closed ? "closed" : "open")
  }
}
