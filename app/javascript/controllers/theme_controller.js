import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  connect() {
    this.current = localStorage.getItem("study-theme") || "system"
    this.apply()
    this.render()
  }

  select(event) {
    event.preventDefault()
    this.current = event.currentTarget.dataset.preset
    localStorage.setItem("study-theme", this.current)
    this.apply()
    this.render()
  }

  apply() {
    const resolved = this.current === "system"
      ? (window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light")
      : this.current
    document.documentElement.dataset.theme = resolved
  }

  render() {
    this.optionTargets.forEach((option) => {
      const active = option.dataset.preset === this.current
      option.classList.toggle("ring-2", active)
      option.classList.toggle("ring-indigo-500", active)
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("hidden", !active)
    })
  }
}
