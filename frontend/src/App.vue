<script setup>
import { onMounted, ref } from 'vue'

const loading = ref(true)
const error = ref('')
const data = ref({ name: '', date: '', address: '' })

onMounted(async () => {
  try {
    const base = import.meta.env.VITE_API_BASE || '';
    const res  = await fetch(`${base}/api/greeting`, { credentials: 'omit' });
    if (!res.ok) throw new Error(`HTTP ${res.status}`)
    data.value = await res.json()
  } catch (e) {
    error.value = 'Could not load greeting.'
    console.error(e)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <main style="font-family: ui-sans-serif, system-ui; padding: 2rem; max-width: 720px;">
    <h1 style="margin: 0 0 1rem;">Avenit AG Interview Demo</h1>

    <p v-if="loading">Loading…</p>
    <p v-else-if="error">{{ error }}</p>
    <p v-else>
      Hello {{ data.name }}, today is {{ data.date }}.
      Your registered address is: {{ data.address }}
    </p>
  </main>
</template>
