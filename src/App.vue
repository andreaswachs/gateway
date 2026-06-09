<script setup lang="ts">
import Fuse, { type FuseResult } from 'fuse.js'
import jsonData from '@/assets/data.json'
import { onMounted, ref, watch } from 'vue'

interface DataItem {
  name: string
  url: string
}

interface QuickCard {
  title: string
  url: string
  image?: string
}

interface QuickSection {
  title: string
  cards: QuickCard[]
}

interface QuickColumn {
  sections: QuickSection[]
}

interface QuickLinks {
  columns: QuickColumn[]
}

interface JsonData {
  searchItems: DataItem[]
  quickLinks: QuickLinks
}

const quickLinks = (jsonData as unknown as JsonData).quickLinks

const fuse = new Fuse((jsonData as unknown as JsonData).searchItems, {
  keys: ['name'],
  includeScore: true,
  threshold: 0.4,
  ignoreLocation: true,
})

const searchResults = ref<FuseResult<DataItem>[]>([])
const selectedIndex = ref(-1)
const searchInput = ref<HTMLInputElement | null>(null)

const navigateTo = (event: MouseEvent, url: string) => {
  if (event.metaKey || event.ctrlKey) {
    window.open(url, '_blank')
  } else {
    window.location.href = url
  }
}

const handleKeydown = (event: KeyboardEvent) => {
  if (event.key === 'Escape') {
    event.preventDefault()
    if (searchInput.value) {
      searchInput.value.value = ''
    }
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
    const selectedItem = searchResults.value[selectedIndex.value].item
    if (event.metaKey || event.ctrlKey) {
      window.open(selectedItem.url, '_blank')
    } else {
      window.location.href = selectedItem.url
    }
  }
}

const handleInput = (event: Event) => {
  const input = event.target as HTMLInputElement
  if (input.value.length < 2) {
    searchResults.value = []
    return
  }

  searchResults.value = fuse.search(input.value, { limit: 8 })

  selectedIndex.value = 0
}

// Reset selection when results change
watch(searchResults, (newResults) => {
  if (newResults.length === 0) {
    selectedIndex.value = -1
  } else {
    selectedIndex.value = 0
  }
})

onMounted(() => {
  searchInput.value?.focus()
})
</script>

<template>
  <div class="min-h-screen w-full relative">
    <!-- Background layers -->
    <div class="gateway-bg"></div>
    <div class="gateway-grid"></div>
    <div class="gateway-particles"></div>

    <!-- Main content -->
    <div class="relative z-10 min-h-screen px-6">
      <!-- Search container -->
      <div class="fixed top-[10vh] left-1/2 -translate-x-1/2 w-full max-w-2xl px-6 z-20">
        <div class="glass-card rounded-2xl p-2">
          <!-- Search input -->
          <div class="relative">
            <div class="absolute left-4 top-1/2 -translate-y-1/2 pointer-events-none">
              <svg class="w-5 h-5 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
            <input
              ref="searchInput"
              type="text"
              class="search-input w-full rounded-xl bg-white/5 placeholder:text-slate-500 text-white pl-12 pr-4 py-4 text-lg outline-none border border-transparent focus:border-indigo-500/30"
              placeholder="Search repositories, services, tools..."
              @keydown="handleKeydown"
              @input="handleInput"
              autofocus
            />
          </div>

          <!-- Results dropdown -->
          <div v-if="searchResults.length" class="results-container mt-2 rounded-xl">
            <ul class="py-1">
              <li
                v-for="(result, index) in searchResults"
                :key="result.item.name"
                :class="[
                  'result-item mx-1 px-4 py-3 rounded-lg cursor-pointer',
                  index === selectedIndex ? 'selected' : ''
                ]"
                role="option"
                :aria-selected="index === selectedIndex"
                @click="navigateTo($event, result.item.url)"
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
                      <p class="text-white font-medium truncate">{{ result.item.name }}</p>
                      <p class="text-slate-500 text-sm truncate">{{ result.item.url }}</p>
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
        <div class="flex items-center justify-center gap-6 mt-4 text-xs text-slate-500">
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

      <!-- Quick links cards -->
      <div v-if="quickLinks?.columns?.length" class="relative z-10 max-w-6xl mx-auto px-6 pt-[30vh] pb-8">
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <template v-for="(column, colIdx) in quickLinks.columns" :key="colIdx">
            <div class="space-y-6">
              <template v-for="(section, secIdx) in column.sections" :key="secIdx">
                <div v-if="section.title" class="text-xs font-medium text-slate-500 uppercase tracking-wider mb-2 px-1">{{ section.title }}</div>
                <div class="grid grid-cols-1 gap-2">
                  <a
                    v-for="card in section.cards"
                    :key="card.title"
                    :href="card.url"
                    class="quick-card w-full flex items-center gap-3 cursor-pointer group p-2.5 rounded-lg bg-white/[0.02] border border-white/[0.06] hover:border-indigo-500/20 hover:bg-white/[0.04] transition-all"
                  >
                    <img
                      v-if="card.image"
                      :src="card.image"
                      :alt="card.title"
                      class="w-6 h-6 object-contain group-hover:scale-110 transition-transform flex-shrink-0"
                      loading="lazy"
                      @error="(e) => ((e.target as HTMLImageElement).style.display = 'none')"
                    />
                    <svg v-else class="w-6 h-6 text-slate-500 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13.828 10.172a4 4 0 00-5.656 0l-4 4a4 4 0 105.656 5.656l1.102-1.101m-.758-4.899a4 4 0 005.656 0l4-4a4 4 0 00-5.656-5.656l-1.1 1.1" />
                    </svg>
                    <span class="text-sm text-slate-300 font-medium truncate">{{ card.title }}</span>
                  </a>
                </div>
              </template>
            </div>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
</style>