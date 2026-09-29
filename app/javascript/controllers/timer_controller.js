import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["clock", "form", "submit"]
  static values = { seconds: Number }

  connect() {
    this.remaining = this.secondsValue
    this.render()
    this.interval = setInterval(() => {
      this.remaining -= 1
      this.render()
      if (this.remaining <= 0) {
        clearInterval(this.interval)
        this.autoSubmit()
      }
    }, 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  render() {
    const m = Math.floor(Math.max(this.remaining, 0) / 60)
    const s = Math.max(this.remaining, 0) % 60
    this.clockTarget.textContent = `${m}:${String(s).padStart(2, "0")}`
    this.clockTarget.classList.toggle("text-rose-600", this.remaining <= 60)
  }

  autoSubmit() {
    if (this.submitTarget.disabled) return
    this.submitTarget.disabled = true
    this.submitTarget.value = "Time up — submitting..."
    this.formTarget.requestSubmit()
  }
}
