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

const handleKeydown = (event: KeyboardEvent) => {
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
    window.location.href = selectedItem.url
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
  <div class="min-h-screen bg-[rgba(15,23,42,0.6)] flex items-start justify-center pt-20">
    <!-- Backdrop container to mimic Spotlight -->
    <div class="w-full max-w-3xl px-6">
      <div class="backdrop-blur-md bg-white/6 rounded-2xl shadow-2xl border border-white/10 p-6">
        <div class="flex items-center gap-4">
          <img src="/src/assets/logo.svg" alt="logo" class="h-10 w-10 opacity-95" />
          <div>
            <h1 class="text-xl text-white font-semibold">Gateway</h1>
            <p class="text-sm text-slate-300">Quickly find projects, docs, and tools</p>
          </div>
        </div>

        <!-- Keep the input static by using a positioned container; results are absolutely positioned inside -->
        <div class="mt-6 relative">
          <input
            type="text"
            class="w-full rounded-xl bg-white/5 placeholder:text-slate-400 text-white px-5 py-4 text-lg outline-none ring-1 ring-white/6 focus:ring-2 focus:ring-white/20"
            placeholder="Search for repositories, services, or tools..."
            @keydown="handleKeydown"
            @input="handleInput"
            autofocus
          />

          <div v-if="searchResults.length" class="absolute left-0 right-0 mt-2 max-h-[480px] overflow-auto rounded-xl bg-white/2 border border-white/6 z-20 shadow-lg">
            <ul>
              <li
                v-for="(result, index) in searchResults"
                :key="result.name"
                :class="[
                  'px-4 py-3 cursor-pointer flex items-center justify-between',
                  index === selectedIndex
                    ? 'bg-white/12 text-white ring-1 ring-white/20 border-l-4 border-white/30'
                    : 'hover:bg-white/5'
                ]"
                role="option"
                :aria-selected="index === selectedIndex"
              >
                <!-- Use flex with gap and allow the left text to truncate while the right URL shrinks -->
                <div class="flex items-center gap-4 w-full">
                  <a :href="result.url" class="truncate flex-1" :class="index === selectedIndex ? 'text-white font-semibold' : 'text-white'">
                    {{ result.fullName || result.name }}
                  </a>
                  <span class="ml-4 shrink-0 w-48 text-ellipsis overflow-hidden whitespace-nowrap" :class="index === selectedIndex ? 'text-slate-100 text-sm' : 'text-slate-400 text-sm'">{{ result.url }}</span>
                </div>
              </li>
            </ul>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>