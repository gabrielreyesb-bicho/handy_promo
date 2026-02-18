# Flujo de Actualización de Precios

## Resumen
Sistema para gestionar actualizaciones de precios que solo se muestran al promotor cuando hay precios pendientes de actualizar para su visita.

## Modelo de Datos

### PriceUpdate
Almacena las actualizaciones de precios pendientes con los siguientes campos:
- `product_presentation_id`: Presentación del producto a actualizar
- `new_price`: Nuevo precio a aplicar
- `visit_id`: (Opcional) Visita específica donde aplicar
- `store_id`: (Opcional) Tienda donde aplicar
- `company_id`: Compañía propietaria
- `status`: Estado (pending/applied/cancelled)
- `applied_at`: Fecha de aplicación
- `notes`: Notas adicionales

## Flujo de Trabajo

### 1. Creación de Actualizaciones de Precios (Admin)

#### Opción A: Manual
1. Admin accede al módulo "Actualizaciones de Precios"
2. Selecciona productos (presentaciones) y establece nuevos precios
3. Asigna a:
   - **Visita específica**: Los precios solo aparecerán en esa visita
   - **Tienda**: Los precios aparecerán en todas las visitas futuras a esa tienda hasta ser aplicados

#### Opción B: Carga desde Excel
1. Admin prepara un archivo Excel con columnas:
   - Código de producto/presentación
   - Nuevo precio
   - (Opcional) Código de tienda o ID de visita
2. Sube el archivo
3. El sistema crea los registros `PriceUpdate` con status `pending`

### 2. Asignación a Visitas

Las actualizaciones pueden asignarse de dos formas:

**A. Asignación directa a visita:**
- Se crea `PriceUpdate` con `visit_id` específico
- Solo aparecerá en esa visita

**B. Asignación a tienda:**
- Se crea `PriceUpdate` con `store_id` pero sin `visit_id`
- Aparecerá en todas las visitas futuras a esa tienda hasta ser aplicado

### 3. Ejecución por el Promotor

Cuando el promotor ejecuta una visita:

1. **Verificación condicional:**
   - El sistema verifica si hay `PriceUpdate` con status `pending` para esa visita:
     - Directamente asignados a la visita (`visit_id = visita_actual`)
     - O asignados a la tienda (`store_id = tienda_visita` y `visit_id IS NULL`)

2. **Mostrar tarea:**
   - Si hay precios pendientes → La tarea "Actualización de precios" aparece en el plan de trabajo
   - Si NO hay precios pendientes → La tarea NO aparece (aunque esté en el plan)

3. **Ejecución:**
   - El promotor ve la lista de productos con precios a actualizar
   - Para cada producto muestra:
     - Nombre del producto/presentación
     - Precio actual (si existe en el sistema)
     - Nuevo precio a aplicar
   - El promotor confirma la actualización
   - Al confirmar, se actualiza el status a `applied` y se registra `applied_at`

## Ventajas de este Flujo

1. **Flexibilidad**: No es necesario incluir la tarea en cada plan de trabajo
2. **Condicional**: Solo aparece cuando es necesario
3. **Trazabilidad**: Se registra cuándo y dónde se aplicó cada actualización
4. **Escalabilidad**: Permite cargar masivamente desde Excel
5. **Granularidad**: Puede asignarse a visitas específicas o a tiendas completas

## Implementación Técnica

### En el Plan de Trabajo
- La tarea `price_update` puede agregarse al plan normalmente
- No requiere configuración adicional
- El sistema decide dinámicamente si mostrarla según precios pendientes

### En la Vista del Promotor
```ruby
# Pseudocódigo para verificar si mostrar la tarea
def should_show_price_update_task?(visit)
  PriceUpdate.pending_for_visit(visit).any? || 
  PriceUpdate.pending_for_store(visit.store).any?
end
```

### Métodos Útiles en PriceUpdate
- `pending_for_visit(visit)`: Precios pendientes para una visita
- `pending_for_store(store)`: Precios pendientes para una tienda
- `apply!`: Marca como aplicado
- `cancel!`: Cancela la actualización

## Próximos Pasos

1. ✅ Modelo PriceUpdate creado
2. ✅ Tarea price_update creada
3. ⏳ Controlador y vistas para gestionar actualizaciones (crear, editar, cargar Excel)
4. ⏳ Vista del promotor para ejecutar actualizaciones
5. ⏳ Lógica condicional en la vista del promotor para mostrar/ocultar tarea
