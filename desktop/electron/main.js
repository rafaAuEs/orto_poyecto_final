const { app, BrowserWindow } = require('electron')
const path = require('path')

// Detección robusta de entorno de desarrollo
const isDev = !app.isPackaged

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
      webSecurity: false // Desactivar temporalmente para evitar problemas de CORS en dev
    }
  })

  if (isDev) {
    console.log('Running in development mode')
    // Esperar un poco para asegurar que Vite está listo si wait-on falla
    setTimeout(() => {
        win.loadURL('http://localhost:3000')
    }, 1000)
    win.webContents.openDevTools()
  } else {
    win.loadFile(path.join(__dirname, '../dist/index.html'))
  }
}

app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
