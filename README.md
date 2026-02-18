# Handy Promo

Aplicación web administrativa desarrollada con Ruby on Rails 8.

## Características

- **Autenticación multiusuario**: Configurado con Devise
- **Base de datos**: SQLite (desarrollo local)
- **Framework CSS**: Bootstrap 5.3
- **JavaScript**: Importmaps con Turbo y Stimulus
- **Layout**: Navbar superior fijo y sidebar lateral izquierdo fijo

## Requisitos

- Ruby 3.2.9
- Bundler
- Node.js (para compilar assets con dartsass-rails)

## Instalación

1. Instalar dependencias:
```bash
bundle install
```

2. Crear y migrar la base de datos:
```bash
rails db:create db:migrate
```

3. Compilar estilos CSS:
```bash
rails dartsass:build
```

4. Iniciar el servidor:
```bash
rails server
```

La aplicación estará disponible en `http://localhost:3000`

## Estructura del Layout

- **Navbar superior**: Logo, campo de búsqueda y perfil de usuario
- **Sidebar lateral**: Botones de acceso rápido (Dashboard, Reportes, Configuración, Usuarios)
- **Área de contenido**: Zona principal donde se muestran las vistas de trabajo

## Próximos pasos

- Personalizar estilos Bootstrap según diseño final
- Implementar funcionalidad de búsqueda
- Agregar funcionalidad a los botones del sidebar
- Configurar subida de imágenes de perfil de usuario
