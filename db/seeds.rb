# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed para cadenas y formatos de retail
# Datos de la industria de trade marketing mexicana

# Estructura de datos: { cadena => { code: código, formats: [{ name: nombre, code: código }] } }
retail_data = {
  "Walmart" => {
    code: "WAL",
    formats: [
      { name: "Walmart Supercenter", code: "WAL_SUP" },
      { name: "Walmart Express", code: "WAL_EXP" },
      { name: "Bodega Aurrera", code: "WAL_BOD" },
      { name: "Sam's Club", code: "WAL_SAM" }
    ]
  },
  "Soriana" => {
    code: "SOR",
    formats: [
      { name: "Soriana Híper", code: "SOR_HIP" },
      { name: "Soriana Súper", code: "SOR_SUP" },
      { name: "Soriana Mercado", code: "SOR_MER" },
      { name: "City Club", code: "SOR_CIT" }
    ]
  },
  "Chedraui" => {
    code: "CHD",
    formats: [
      { name: "Chedraui", code: "CHD_STD" },
      { name: "Selecto Chedraui", code: "CHD_SEL" },
      { name: "Súper Chedraui", code: "CHD_SUP" },
      { name: "Súper Che / Súpercito", code: "CHD_CHE" }
    ]
  },
  "La Comer" => {
    code: "COM",
    formats: [
      { name: "La Comer", code: "COM_STD" },
      { name: "City Market", code: "COM_CIT" },
      { name: "Fresko", code: "COM_FRE" },
      { name: "Sumesa", code: "COM_SUM" }
    ]
  },
  "H-E-B" => {
    code: "HEB",
    formats: [
      { name: "H-E-B", code: "HEB_STD" },
      { name: "Mi Tienda del Ahorro", code: "HEB_TIA" }
    ]
  },
  "FEMSA" => {
    code: "FEM",
    formats: [
      { name: "OXXO", code: "FEM_OXX" }
    ]
  },
  "Casa Ley" => {
    code: "LEY",
    formats: [
      { name: "Casa Ley", code: "LEY_STD" }
    ]
  },
  "S-Mart" => {
    code: "SMT",
    formats: [
      { name: "S-Mart", code: "SMT_STD" }
    ]
  }
}

# Obtener la primera compañía (compañía de pruebas)
company = Company.first

if company.nil?
  puts "⚠️  No se encontró ninguna compañía. Por favor crea una compañía primero."
  exit
end

puts "📦 Insertando cadenas y formatos para la compañía: #{company.name} (ID: #{company.id})"
puts "=" * 80

retail_data.each do |chain_name, chain_data|
  chain_code = chain_data[:code]
  format_list = chain_data[:formats]
  
  # Crear o encontrar la cadena
  chain = company.chains.find_or_create_by(name: chain_name) do |c|
    c.code = chain_code
    c.active = true
  end
  
  # Actualizar código si ya existía pero no tenía código
  if chain.code.blank? || chain.code != chain_code
    chain.update(code: chain_code)
    puts "🔄 Cadena actualizada con código: #{chain_name} (#{chain_code})"
  elsif chain.persisted? && chain.previously_new_record?
    puts "✅ Cadena creada: #{chain_name} (#{chain_code})"
  else
    puts "ℹ️  Cadena ya existía: #{chain_name} (#{chain_code})"
  end
  
  # Crear los formatos para esta cadena
  format_list.each do |format_data|
    format_name = format_data[:name]
    format_code = format_data[:code]
    
    format = chain.formats.find_or_create_by(name: format_name) do |f|
      f.code = format_code
      f.active = true
    end
    
    # Actualizar código si ya existía pero no tenía código
    if format.code.blank? || format.code != format_code
      format.update(code: format_code)
      puts "   🔄 Formato actualizado con código: #{format_name} (#{format_code})"
    elsif format.persisted? && format.previously_new_record?
      puts "   ✅ Formato creado: #{format_name} (#{format_code})"
    else
      puts "   ℹ️  Formato ya existía: #{format_name} (#{format_code})"
    end
  end
  
  puts ""
end

# Seed para segmentos
segments_data = [
  "Nivel A",
  "Nivel B",
  "Nivel C"
]

puts ""
puts "📊 Insertando segmentos para la compañía: #{company.name}"
puts "=" * 80

segments_data.each do |segment_name|
  segment = company.segments.find_or_create_by(name: segment_name) do |s|
    s.active = true
  end
  
  if segment.persisted? && segment.previously_new_record?
    puts "✅ Segmento creado: #{segment_name}"
  else
    puts "ℹ️  Segmento ya existía: #{segment_name}"
  end
end

puts "=" * 80
puts "✨ Seed completado exitosamente!"
puts ""
puts "Resumen:"
puts "  - Cadenas: #{company.chains.count}"
puts "  - Formatos: #{company.chains.joins(:formats).count('formats.id')}"
puts "  - Segmentos: #{company.segments.count}"

# Seed para Tareas (globales, no por compañía)
puts ""
puts "📋 Insertando Tareas predefinidas"
puts "=" * 80

tasks_data = [
  {
    code: 'PHOTO_CAPTURE',
    name: 'Captura de fotografía',
    description: 'Permite al promotor tomar una fotografía con la cámara del dispositivo móvil',
    task_type: 'photo_capture',
    instructions_template: 'Toma una fotografía según las instrucciones específicas del plan de trabajo',
    config: {
      required: true,
      max_photos: 1
    }
  },
  {
    code: 'IMAGE_DISPLAY',
    name: 'Muestra de fotografía',
    description: 'Muestra una imagen previamente cargada al promotor',
    task_type: 'image_display',
    instructions_template: 'Revisa la imagen mostrada y sigue las indicaciones',
    config: {
      image_required: true
    }
  },
  {
    code: 'COMMENT_CAPTURE',
    name: 'Captura de comentarios',
    description: 'Permite al promotor capturar comentarios o notas de texto',
    task_type: 'comment_capture',
    instructions_template: 'Ingresa los comentarios o notas solicitadas',
    config: {
      max_length: 1000,
      required: true
    }
  },
  {
    code: 'INCIDENT_REPORT',
    name: 'Registro de incidentes',
    description: 'Permite al promotor registrar un incidente con instrucciones, texto descriptivo y una fotografía',
    task_type: 'incident_report',
    instructions_template: 'Registra el incidente siguiendo las instrucciones específicas. Captura un texto descriptivo y toma una fotografía relacionada al incidente',
    config: {
      text_required: true,
      photo_required: true,
      max_text_length: 2000
    }
  },
  {
    code: 'INVENTORY_CAPTURE',
    name: 'Captura de inventario',
    description: 'Permite al promotor registrar la cantidad de inventario disponible en la tienda para cada producto',
    task_type: 'inventory_capture',
    instructions_template: 'Revisa el inventario disponible en la tienda y registra la cantidad para cada producto según las instrucciones específicas',
    config: {
      show_all_products: true,
      allow_zero: true,
      require_all: false
    }
  },
  {
    code: 'PRICE_UPDATE',
    name: 'Actualización de precios',
    description: 'Permite al promotor actualizar los precios de productos en la tienda según una lista de precios pendientes',
    task_type: 'price_update',
    instructions_template: 'Actualiza los precios de los productos según la lista proporcionada. Esta tarea solo aparecerá si hay precios pendientes de actualizar',
    config: {
      conditional: true,
      requires_pending_updates: true
    }
  }
]

tasks_data.each do |task_data|
  task = Task.find_or_create_by(code: task_data[:code]) do |t|
    t.name = task_data[:name]
    t.description = task_data[:description]
    t.task_type = task_data[:task_type]
    t.instructions_template = task_data[:instructions_template]
    t.config = task_data[:config]
    t.active = true
  end
  
  if task.persisted? && task.previously_new_record?
    puts "✅ Tarea creada: #{task.name} (#{task.code})"
  else
    # Actualizar si ya existía pero cambió algo
    updated = false
    if task.name != task_data[:name]
      task.update(name: task_data[:name])
      updated = true
    end
    if task.description != task_data[:description]
      task.update(description: task_data[:description])
      updated = true
    end
    if task.task_type != task_data[:task_type]
      task.update(task_type: task_data[:task_type])
      updated = true
    end
    if task.instructions_template != task_data[:instructions_template]
      task.update(instructions_template: task_data[:instructions_template])
      updated = true
    end
    if task.config != task_data[:config]
      task.update(config: task_data[:config])
      updated = true
    end
    
    if updated
      puts "🔄 Tarea actualizada: #{task.name} (#{task.code})"
    else
      puts "ℹ️  Tarea ya existía: #{task.name} (#{task.code})"
    end
  end
end

puts ""
puts "=" * 80
puts "✨ Seed de Tareas completado!"
puts "  - Tareas creadas: #{Task.count}"
