<script setup>
import { ref, onMounted } from 'vue'

const data = ref(null)
const error = ref(null)

onMounted(async () => {
  try {
    // Backend base URL: use env var if provided, else localhost for dev
    const base = import.meta.env.VITE_API_URL || 'http://localhost:3000'
    const res = await fetch(`${base}/greeting`)
    if (!res.ok) throw new Error(await res.text())
    data.value = await res.json()
  } catch (e) {
    error.value = e.message || 'Request failed'
  }
})
</script>

<template>
  <main style="font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial, sans-serif; padding: 2rem; line-height: 1.5;">
    <h1 style="margin: 0 0 1rem;">Interview Demo</h1>

    <p v-if="!data && !error">Loading…</p>
    <p v-if="error" style="color:crimson">{{ error }}</p>

    <h2 v-if="data" style="font-weight:600;">
      Hello {{ data.name }}, today is {{ data.date }}.<br />
      Your registered address is: {{ data.address }}
    </h2>
  </main>
</template>
