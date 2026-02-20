<script setup>
import { ref, computed } from 'vue'
import api from '../services/api'

const props = defineProps({
  activity: {
    type: Object,
    default: null // null = modo crear, objeto = modo editar
  }
})

const emit = defineEmits(['close', 'saved'])

// Inicializar estado con props si es edición
const isEdit = computed(() => !!props.activity)

// Auxiliar para formatear fecha UTC de la DB a local para el input datetime-local
const formatToLocalInput = (isoString) => {
  if (!isoString) return ''
  const date = new Date(isoString)
  if (isNaN(date.getTime())) return ''
  
  const pad = (n) => String(n).padStart(2, '0')
  const y = date.getFullYear()
  const m = pad(date.getMonth() + 1)
  const d = pad(date.getDate())
  const h = pad(date.getHours())
  const min = pad(date.getMinutes())
  
  return `${y}-${m}-${d}T${h}:${min}`
}

// Formulario reactivo
const form = ref({
  title: props.activity?.title || '',
  instructor: props.activity?.instructor || '',
  location: props.activity?.location || 'Sala Principal',
  capacity: props.activity?.capacity || 20,
  start_time: formatToLocalInput(props.activity?.start_time),
  end_time: formatToLocalInput(props.activity?.end_time)
})

const loading = ref(false)
const errorMsg = ref('')

const handleSubmit = async () => {
  loading.value = true
  errorMsg.value = ''
  
  try {
    // Validar fechas básicas
    if (new Date(form.value.end_time) <= new Date(form.value.start_time)) {
      throw new Error("La fecha de fin debe ser posterior a la de inicio")
    }

    const payload = { ...form.value }
    // Convertir a ISO string completo para el backend
    payload.start_time = new Date(form.value.start_time).toISOString()
    payload.end_time = new Date(form.value.end_time).toISOString()

    if (isEdit.value) {
      // Usar ruta sin barra final si FastAPI no la requiere, o con barra si sí.
      // FastAPI router prefix includes slash usually.
      await api.put(`/activities/${props.activity._id}`, payload)
    } else {
      // POST a la raíz del router activities
      await api.post('/activities/', payload)
    }
    
    emit('saved') // Notificar al padre para recargar
    emit('close')
  } catch (e) {
    errorMsg.value = e.response?.data?.detail || e.message || "Error al guardar"
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-lg overflow-hidden transform transition-all">
      
      <!-- Header -->
      <div class="px-6 py-4 border-b border-gray-100 bg-gray-50 flex justify-between items-center">
        <h3 class="text-lg font-bold text-gray-800">
          {{ isEdit ? 'Editar Actividad' : 'Nueva Clase' }}
        </h3>
        <button @click="$emit('close')" class="text-gray-400 hover:text-gray-600">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Body -->
      <form @submit.prevent="handleSubmit" class="p-6 space-y-4">
        
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Título</label>
          <input v-model="form.title" type="text" required placeholder="Ej: Yoga Avanzado" class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all" />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Instructor</label>
            <input v-model="form.instructor" type="text" required placeholder="Nombre" class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-blue-500 outline-none" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Ubicación</label>
            <input v-model="form.location" type="text" required class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-blue-500 outline-none" />
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Inicio</label>
            <input v-model="form.start_time" type="datetime-local" required class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-blue-500 outline-none" />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Fin</label>
            <input v-model="form.end_time" type="datetime-local" required class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-blue-500 outline-none" />
          </div>
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Aforo Máximo</label>
          <input v-model="form.capacity" type="number" min="1" required class="w-full rounded-lg border-gray-300 border px-3 py-2 focus:ring-blue-500 outline-none" />
        </div>

        <div v-if="errorMsg" class="p-3 bg-red-50 text-red-700 text-sm rounded-lg border border-red-100">
          {{ errorMsg }}
        </div>

        <div class="pt-4 flex justify-end space-x-3">
          <button type="button" @click="$emit('close')" class="px-4 py-2 text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 font-medium">
            Cancelar
          </button>
          <button type="submit" :disabled="loading" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 font-medium shadow-sm disabled:opacity-50 flex items-center">
            <svg v-if="loading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" fill="none" viewBox="0 0 24 24">
              <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
              <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
            </svg>
            {{ isEdit ? 'Guardar Cambios' : 'Crear Clase' }}
          </button>
        </div>

      </form>
    </div>
  </div>
</template>
