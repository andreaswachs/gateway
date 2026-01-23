<script setup lang="ts">
import TrieSearch from 'trie-search'
import jsonData from '@/assets/data.json'
import { onMounted, ref, watch } from 'vue'

interface DataItem {
  name: string
  fullName?: string  // Add optional fullName field
  url: string
}

// Initialize trie with the 'name' field as the key
const trie = new TrieSearch(['name'])
const searchResults = ref<DataItem[]>([])
const selectedIndex = ref(-1)

// Add the JSON data to the trie
const addItemWithVariations = (item: DataItem) => {
  const name = item.name
  const itemWithFullName = { ...item, fullName: name }  // Store original name
  trie.add(itemWithFullName)
  
  // Add variations with characters removed from the left
  for (let i = 1; i < name.length; i++) {
    const variation = { 
      ...item,
      fullName: name,  // Keep original name for reference
      name: name.slice(i) 
    }
    trie.add(variation)
  }
}

jsonData.forEach(addItemWithVariations)

const calculateSimilarity = (input: string, name: string, fullName: string): number => {
  const lowerInput = input.toLowerCase()
  const lowerName = fullName.toLowerCase()  // Use fullName for comparison
  
  // Exact match gets highest priority
  if (lowerName === lowerInput) return 100
  
  // Starts with gets second priority
  if (lowerName.startsWith(lowerInput)) return 75
  
  // Contains gets third priority, with earlier matches ranking higher
  const index = lowerName.indexOf(lowerInput)
  if (index >= 0) return 50 - (index * 0.1)
  
  return 0
}

const navigateTo = (url: string) => {
  window.location.href = url
}

const handleKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    event.preventDefault()
    const input = event.target as HTMLInputElement
    input.value = ''
    searchResults.value = []
    return
  }

  if (searchResults.value.length === 0) return

  if (event.key === 'ArrowDown') {
    event.preventDefault()
    selectedIndex.value = Math.min(selectedIndex.value + 1, searchResults.value.length - 1)
  } else if (event.key === 'ArrowUp') {
    event.preventDefault()
    selectedIndex.value = Math.max(selectedIndex.value - 1, 0)
  } else if (event.key === 'Enter' && selectedIndex.value >= 0) {
    event.preventDefault()
    const selectedItem = searchResults.value[selectedIndex.value]
    navigateTo(selectedItem.url)
  }
}

const handleInput = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.value.length < 2) {
    searchResults.value = []
    return
  }
  
  // Get results and sort them by similarity
  const results = trie.get(input.value) as DataItem[]
  
  // Deduplicate results based on fullName
  const uniqueResults = Array.from(
    results.reduce((map, item) => {
      const fullName = item.fullName || item.name
      if (!map.has(fullName) || 
          calculateSimilarity(input.value, item.name, fullName) > 
          calculateSimilarity(input.value, map.get(fullName)!.name, fullName)) {
        map.set(fullName, item)
      }
      return map
    }, new Map<string, DataItem>())
  ).map(([_, item]) => item)
  
  searchResults.value = uniqueResults.sort((a, b) => {
    const similarityA = calculateSimilarity(input.value, a.name, a.fullName || a.name)
    const similarityB = calculateSimilarity(input.value, b.name, b.fullName || b.name)
    return similarityB - similarityA
  })
}

// Reset selection when results change
watch(searchResults, (newResults) => {
  if (newResults.length === 0) {
    selectedIndex.value = -1
  } else {
    // Select first item by default, or keep selection in bounds
    selectedIndex.value = selectedIndex.value === -1 ? 0 : Math.min(selectedIndex.value, newResults.length - 1)
  }
})

onMounted(() => {
  const inputElement = document.querySelector('input')
  if (inputElement) {
    inputElement.focus()
  }
})
</script>

<template>
  <div class="min-h-screen w-full relative">
    <!-- Background layers -->
    <div class="gateway-bg"></div>
    <div class="gateway-grid"></div>
    <div class="gateway-particles"></div>

    <!-- Main content -->
    <div class="relative z-10 min-h-screen flex flex-col items-center justify-center px-6">
      <!-- Logo and branding -->
      <div class="flex flex-col items-center mb-8">
        <div class="relative mb-4">
          <div class="absolute inset-0 bg-gradient-to-r from-indigo-500 to-purple-500 rounded-2xl blur-xl opacity-30"></div>
          <img src="/src/assets/logo.svg" alt="logo" class="relative h-16 w-16" />
        </div>
        <h1 class="text-3xl font-bold text-white tracking-tight">Gateway</h1>
        <p class="text-slate-400 mt-1 text-sm">Press <span class="kbd">⌘</span> <span class="kbd">K</span> anywhere to search</p>
      </div>

      <!-- Search container -->
      <div class="w-full max-w-2xl">
        <div class="glass-card rounded-2xl p-2">
          <!-- Search input -->
          <div class="relative">
            <div class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none">
              <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <input
              type="text"
              class="search-input w-full rounded-xl bg-white/5 placeholder:text-slate-500 text-white pl-12 pr-4 py-4 text-lg outline-none border border-transparent focus:border-indigo-500/30"
              placeholder="Search repositories, services, tools..."
              @keydown="handleKeydown"
              @input="handleInput"
              autofocus
            />
          </div>

          <!-- Results dropdown -->
          <div v-if="searchResults.length" class="results-container mt-2 max-h-[400px] overflow-auto rounded-xl">
            <ul class="py-1">
              <li
                v-for="(result, index) in searchResults"
                :key="result.fullName || result.name"
                :class="[
                  'result-item mx-1 px-4 py-3 rounded-lg cursor-pointer',
                  index === selectedIndex ? 'selected' : ''
                ]"
                role="option"
                :aria-selected="index === selectedIndex"
                @click="navigateTo(result.url)"
                @mouseenter="selectedIndex = index"
              >
                <div class="flex items-center justify-between gap-4">
                  <div class="flex items-center gap-3 min-w-0 flex-1">
                    <div class="w-8 h-8 rounded-lg bg-gradient-to-br from-indigo-500/20 to-purple-500/20 flex items-center justify-center flex-shrink-0">
                      <svg class="w-4 h-4 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                      </svg>
                    </div>
                    <div class="min-w-0 flex-1">
                      <p class="text-white font-medium truncate">{{ result.fullName || result.name }}</p>
                      <p class="text-slate-500 text-sm truncate">{{ result.url }}</p>
                    </div>
                  </div>
                  <div v-if="index === selectedIndex" class="flex items-center gap-1 flex-shrink-0">
                    <span class="kbd">↵</span>
                  </div>
                </div>
              </li>
            </ul>
          </div>
        </div>

        <!-- Keyboard hints -->
        <div class="flex items-center justify-center gap-6 mt-6 text-xs text-slate-500">
          <span class="flex items-center gap-1.5">
            <span class="kbd">↑</span><span class="kbd">↓</span> Navigate
          </span>
          <span class="flex items-center gap-1.5">
            <span class="kbd">↵</span> Open
          </span>
          <span class="flex items-center gap-1.5">
            <span class="kbd">esc</span> Clear
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>