<script setup>
import { onMounted, ref } from 'vue'

const loading = ref(true)
const error = ref('')
const data = ref({ name: '', date: '', address: '' })
const showCard = ref(false)

onMounted(async () => {
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

<style>
/* Full-page animated multicolor gradient */
.bg-digital {
  background: linear-gradient(270deg, #ff0080, #7928ca, #2afadf, #f6d365, #fda085);
  background-size: 1000% 1000%;
  animation: digitalFlow 20s ease infinite;
}

@keyframes digitalFlow {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* Neon glow effect for card */
.glow {
  box-shadow:
    0 0 15px rgba(255, 0, 128, 0.6),
    0 0 30px rgba(121, 40, 202, 0.6),
    0 0 45px rgba(42, 250, 223, 0.6);
  transition: box-shadow 0.5s ease-in-out;
}

.glow:hover {
  box-shadow:
    0 0 25px rgba(255, 0, 128, 0.9),
    0 0 50px rgba(121, 40, 202, 0.9),
    0 0 70px rgba(42, 250, 223, 0.9);
}
</style>

<template>
  <main class="min-h-screen flex items-center justify-center bg-digital p-6">
    <div
      class="bg-white/90 backdrop-blur-lg rounded-2xl p-8 max-w-lg w-full text-center transform transition-all duration-700 ease-out glow"
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
