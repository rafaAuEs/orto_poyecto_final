<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api'

const props = defineProps({
  activity: Object
})

const emit = defineEmits(['close'])

const attendees = ref([])
const loading = ref(true)

onMounted(async () => {
  await fetchAttendees()
})

const fetchAttendees = async () => {
  loading.value = true
  try {
    const response = await api.get(`/reservations/activity/${props.activity._id}`)
    attendees.value = response.data
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}

const toggleAttendance = async (reservation, newStatus) => {
  const originalStatus = reservation.status
  reservation.status = newStatus // Optimistic UI
  
  try {
    await api.put(`/reservations/${reservation._id}/attendance`, { status: newStatus })
  } catch (e) {
    reservation.status = originalStatus // Revert
    alert("Error actualizando asistencia")
  }
}

const formatDate = (isoString) => {
  if (!isoString) return '-'
  return new Date(isoString).toLocaleString('es-ES')
}
</script>

<template>
  <div class="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
    <div class="bg-white rounded-xl shadow-2xl w-full max-w-2xl overflow-hidden h-[80vh] flex flex-col">
      
      <!-- Header -->
      <div class="px-6 py-4 border-b border-gray-100 bg-gray-50 flex justify-between items-center">
        <div>
          <h3 class="text-lg font-bold text-gray-800">Control de Asistencia</h3>
          <p class="text-sm text-gray-500">{{ activity.title }} - {{ formatDate(activity.start_time) }}</p>
        </div>
        <button @click="$emit('close')" class="text-gray-400 hover:text-gray-600">
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
      </div>

      <!-- Body (Scrollable) -->
      <div class="flex-1 overflow-y-auto p-0">
        <table class="w-full text-left border-collapse">
          <thead class="bg-gray-50 sticky top-0">
            <tr>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Alumno</th>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase">Estado</th>
              <th class="px-6 py-3 text-xs font-semibold text-gray-500 uppercase text-right">Acción</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="res in attendees" :key="res._id" class="hover:bg-gray-50">
              <td class="px-6 py-4">
                <p class="font-medium text-gray-900">{{ res.user_name || 'Usuario desconocido' }}</p>
                <p class="text-xs text-gray-500">{{ res.user_email }}</p>
              </td>
              <td class="px-6 py-4">
                <span :class="{
                  'px-2 py-1 rounded-full text-xs font-semibold': true,
                  'bg-green-100 text-green-700': res.status === 'attended',
                  'bg-blue-100 text-blue-700': res.status === 'active',
                  'bg-red-100 text-red-700': res.status === 'absent' || res.status === 'late_cancelled'
                }">
                  {{ res.status === 'active' ? 'Reservado' : res.status }}
                </span>
              </td>
              <td class="px-6 py-4 text-right space-x-2">
                <button 
                  v-if="res.status !== 'attended'"
                  @click="toggleAttendance(res, 'attended')"
                  class="text-xs bg-green-600 hover:bg-green-700 text-white px-3 py-1 rounded transition-colors"
                >
                  Marcar Asistió
                </button>
                <button 
                  v-if="res.status === 'attended'"
                  @click="toggleAttendance(res, 'active')"
                  class="text-xs bg-gray-200 hover:bg-gray-300 text-gray-700 px-3 py-1 rounded transition-colors"
                >
                  Deshacer
                </button>
                 <button 
                  v-if="res.status === 'active'"
                  @click="toggleAttendance(res, 'absent')"
                  class="text-xs text-red-500 hover:text-red-700 px-2"
                >
                  Falta
                </button>
              </td>
            </tr>
            <tr v-if="attendees.length === 0 && !loading">
              <td colspan="3" class="px-6 py-8 text-center text-gray-500">
                Nadie se ha apuntado aún.
              </td>
            </tr>
          </tbody>
        </table>
        
        <div v-if="loading" class="p-8 text-center text-gray-500">
          Cargando lista...
        </div>
      </div>

    </div>
  </div>
</template>
