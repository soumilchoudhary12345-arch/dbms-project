import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option", "switch", "knob"]

  connect() {
    if (localStorage.getItem("study-theme") === "system") {
      localStorage.setItem("study-sync", "1")
      localStorage.removeItem("study-theme")
    }
    this.sync = localStorage.getItem("study-sync") !== "0"
    this.current = localStorage.getItem("study-theme") || "light"
    this.apply()
    this.render()
  }

  select(event) {
    event.preventDefault()
    this.current = event.currentTarget.dataset.preset
    localStorage.setItem("study-theme", this.current)
    if (this.sync) this.setSync(false)
    this.apply()
    this.render()
  }

  toggleSync(event) {
    event.preventDefault()
    this.setSync(!this.sync)
    this.apply()
    this.render()
  }

  setSync(on) {
    this.sync = on
    localStorage.setItem("study-sync", on ? "1" : "0")
  }

  resolved() {
    if (!this.sync) return this.current
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light"
  }

  apply() {
    const root = document.documentElement
    root.classList.add("theming")
    clearTimeout(this.fadeTimer)
    this.fadeTimer = setTimeout(() => root.classList.remove("theming"), 500)
    root.dataset.theme = this.resolved()
  }

  render() {
    const active = this.resolved()
    this.optionTargets.forEach((option) => {
      const on = option.dataset.preset === active
      option.classList.toggle("ring-2", on)
      option.classList.toggle("ring-indigo-500", on)
      const check = option.querySelector("[data-check]")
      if (check) check.classList.toggle("hidden", !on)
    })
    if (this.hasSwitchTarget) {
      this.switchTarget.setAttribute("aria-checked", String(this.sync))
      this.switchTarget.classList.toggle("bg-indigo-600", this.sync)
      this.switchTarget.classList.toggle("bg-slate-200", !this.sync)
      this.knobTarget.classList.toggle("translate-x-5", this.sync)
    }
  }
}
