import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    // Asegurar que el menú esté cerrado al inicializar
    if (this.hasMenuTarget) {
      const menu = this.menuTarget
      menu.classList.remove('show')
      // Forzar el ancho a 0 para asegurar que esté cerrado
      menu.style.width = '0'
    }
    
    // Guardar referencia al área principal de contenido
    this.findMainContent()
  }
  
  findMainContent() {
    this.mainContent = document.querySelector('.main-content')
    if (!this.mainContent) {
      console.warn('Main content element not found, will retry')
      setTimeout(() => this.findMainContent(), 100)
    } else {
      console.log('Main content found:', this.mainContent)
    }
  }

  toggle(event) {
    if (event) {
      event.preventDefault()
      event.stopPropagation()
    }
    
    if (!this.hasMenuTarget) {
      console.error('Menu target not found')
      return
    }
    
    const menu = this.menuTarget
    const isOpen = menu.classList.contains('show')
    
    if (isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    if (!this.hasMenuTarget) {
      console.error('Cannot open: menu target not found')
      return
    }
    
    const menu = this.menuTarget
    menu.classList.add('show')
    menu.style.width = '320px'
    
    // Compactar el área principal de contenido
    // Buscar el elemento si no está guardado
    if (!this.mainContent) {
      this.findMainContent()
    }
    
    if (this.mainContent) {
      this.mainContent.classList.add('menu-open')
      // También aplicar estilo inline como respaldo
      this.mainContent.style.marginLeft = '390px'
      console.log('Menu opened, main content classes:', this.mainContent.className)
      console.log('Menu opened, main content margin-left:', window.getComputedStyle(this.mainContent).marginLeft)
    } else {
      console.error('Main content element not found when opening menu')
    }
    
    // No agregar overlay - el menú se cierra con el botón hamburguesa
  }

  close() {
    if (!this.hasMenuTarget) return
    
    const menu = this.menuTarget
    menu.classList.remove('show')
    menu.style.width = '0'
    
    // Expandir el área principal de contenido
    // Buscar el elemento si no está guardado
    if (!this.mainContent) {
      this.findMainContent()
    }
    
    if (this.mainContent) {
      this.mainContent.classList.remove('menu-open')
      // Remover estilo inline
      this.mainContent.style.marginLeft = ''
      console.log('Menu closed, main content classes:', this.mainContent.className)
      console.log('Menu closed, main content margin-left:', window.getComputedStyle(this.mainContent).marginLeft)
    }
    
    // No hay overlay que remover
  }
}
