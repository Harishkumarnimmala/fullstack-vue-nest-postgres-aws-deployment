<script setup>
import { onMounted, ref } from 'vue'

const loading = ref(true)
const error = ref('')
const data = ref({ name: '', date: '', address: '' })
const showCard = ref(false)

onMounted(async () => {
  // trigger card fade-in after mount
  setTimeout(() => {
    showCard.value = true
  }, 100)

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
  <main class="min-h-screen flex items-center justify-center bg-gradient-to-r from-purple-400 via-pink-500 to-red-500 p-6">
    <div
      class="bg-white/90 backdrop-blur-lg shadow-xl rounded-2xl p-8 max-w-lg w-full text-center transform transition-all duration-700 ease-out"
      :class="showCard ? 'opacity-100 translate-y-0' : 'opacity-0 translate-y-6'"
    >
      <h1 class="text-3xl font-bold text-indigo-600 mb-6">
        Avenit AG Interview Demo
      </h1>

      <div v-if="loading" class="text-gray-600 animate-pulse">
        Loading…
      </div>

      <div v-else-if="error" class="text-red-600 font-semibold">
        {{ error }}
      </div>

      <div v-else class="space-y-4">
        <p class="text-lg text-gray-800">
          Hello <span class="font-semibold text-pink-600">{{ data.name }}</span>,  
          today is <span class="font-semibold text-purple-600">{{ data.date }}</span>.
        </p>
        <p class="text-gray-700">
          Your registered address is:  
          <span class="font-medium text-indigo-700">{{ data.address }}</span>
        </p>
      </div>
    </div>
  </main>
</template>
