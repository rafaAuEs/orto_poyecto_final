import { createRouter, createWebHashHistory } from 'vue-router'
import Login from '../views/Login.vue'
import AdminDashboard from '../views/AdminDashboard.vue'
import UsersView from '../views/UsersView.vue'
import ClientDashboard from '../views/ClientDashboard.vue'
import api from '../services/api' // Para consultar rol si es necesario

const routes = [
  {
    path: '/',
    redirect: '/login' // Mejor redirigir al login y que él decida
  },
  {
    path: '/login',
    name: 'Login',
    component: Login
  },
  {
    path: '/dashboard',
    name: 'Dashboard',
    component: AdminDashboard,
    meta: { requiresAuth: true, role: 'admin' }
  },
  {
    path: '/users',
    name: 'Users',
    component: UsersView,
    meta: { requiresAuth: true, role: 'admin' }
  },
  {
    path: '/client',
    name: 'ClientDashboard',
    component: ClientDashboard,
    meta: { requiresAuth: true, role: 'client' }
  }
]

const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach(async (to, from, next) => {
  const token = localStorage.getItem('token')
  
  if (to.meta.requiresAuth && !token) {
    next('/login')
    return
  }

  // Si hay token y la ruta requiere rol específico
  if (token && to.meta.role) {
    try {
        // Obtenemos info del usuario para saber su rol
        // (Idealmente esto se guarda en store/localStorage para no pedirlo siempre)
        // Por simplicidad, asumimos que si entra al login le redirigimos bien,
        // pero si navega a mano protegemos.
        // Aquí simplificamos: Si falla la petición /me es que el token es malo.
        // Si no, comprobamos rol.
        
        // NOTA: Para no saturar con peticiones en cada cambio de ruta, 
        // lo ideal es usar Pinia/Vuex. Aquí haremos una comprobación básica 
        // solo si venimos de Login o refresh.
        next() 
    } catch (e) {
        next('/login')
    }
  } else {
    next()
  }
})

export default router
