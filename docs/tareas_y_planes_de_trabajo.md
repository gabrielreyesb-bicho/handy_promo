# Tareas y Planes de Trabajo - Análisis y Especificación

## Fecha
16 de febrero de 2025

## Contexto
Sistema para que promotores realicen visitas a tiendas. Cada promotor debe ver su Plan de Trabajo que contiene una lista de tareas a realizar. Cada tarea contiene instrucciones y elementos para ser ejecutados y recibir resultados.

## Estructura de Modelos Propuesta

### 1. Elementos (Task Elements)
Modelo base reutilizable que define tipos de actividades que puede realizar un promotor.

**Campos:**
- Código
- Nombre (ej: "Toma de fotografía", "Mostrar imagen", "Captura de comentarios")
- Tipo/Clase (para diferenciar comportamientos - opcional)
- Texto/Instrucciones (lo que ve el promotor al ejecutar)
- Posiblemente configuración adicional según el tipo

**Ejemplos:**
- Toma de fotografía
- Mostrar una imagen
- Captura de comentarios

**Relaciones:**
- Puede ser usado en múltiples tareas (many-to-many)

---

### 2. Tareas (Tasks)
Define qué debe hacer el promotor en un momento específico.

**Campos:**
- Código
- Nombre/Descripción (ej: "Foto de éxito", "Tomar foto de anaquel al llegar", "Notas")
- Instrucciones generales

**Relaciones:**
- `has_many :task_task_elements` (tabla intermedia para incluir orden/configuración)
- `has_many :task_elements, through: :task_task_elements`
- Puede estar en múltiples planes de trabajo

**Ejemplos:**
- **Tarea A:** "Foto de éxito" → Elemento: "Mostrar imagen"
- **Tarea B:** "Tomar foto de anaquel al llegar" → Elemento: "Tomar foto"
- **Tarea R:** "Notas" → Elemento: "Captura de comentarios"

---

### 3. Planes de Trabajo (Work Plans)
Contiene una lista de tareas que el promotor debe ejecutar durante una visita.

**Campos:**
- Código
- Nombre
- Descripción

**Relaciones:**
- `has_many :work_plan_tasks` (tabla intermedia para orden y configuración)
- `has_many :tasks, through: :work_plan_tasks`
- Futuro: asignación a Cadenas/Formatos de cadena

---

## Diagrama de Relaciones

```
TaskElement (Elemento)
  └─ puede ser usado en múltiples tareas

Task (Tarea)
  └─ has_many :task_task_elements
  └─ has_many :task_elements, through: :task_task_elements

WorkPlan (Plan de Trabajo)
  └─ has_many :work_plan_tasks
  └─ has_many :tasks, through: :work_plan_tasks
```

---

## Flujo del Promotor

1. **Lista de Visitas** → Selecciona cliente
2. **Inicia Visita** → Ve Plan de Trabajo asignado
3. **Ve Lista de Tareas** del plan
4. **Ejecuta Tareas** secuencialmente:
   - Ve instrucciones de la tarea
   - Ejecuta cada elemento (mostrar imagen, tomar foto, capturar comentarios, etc.)
   - Guarda resultados
5. **Termina todas las tareas** → Termina plan → Termina visita

---

## Preguntas Pendientes para Aclarar

1. **Tipos de Elementos:**
   - ¿Los elementos tienen tipos específicos (foto, imagen, comentario) o solo texto?
   - ¿Necesitamos un campo `element_type` o `element_class`?

2. **Múltiples Elementos:**
   - ¿Una tarea puede tener múltiples elementos del mismo tipo?
   - Ejemplo: ¿Una tarea puede tener 2 "Toma de fotografía"?

3. **Orden de Tareas:**
   - ¿El orden de las tareas en el plan es importante?
   - ¿Necesitamos un campo `position` en la tabla intermedia `work_plan_tasks`?

4. **Orden de Elementos:**
   - ¿El orden de los elementos dentro de una tarea es importante?
   - ¿Necesitamos un campo `position` en la tabla intermedia `task_task_elements`?

5. **Configuración de Elementos:**
   - ¿Los elementos tienen configuración adicional?
   - Ejemplos:
     - Tamaño de foto requerido
     - Formato de comentario (texto corto, texto largo, múltiple línea)
     - URL de imagen a mostrar
     - Validaciones específicas

6. **Multi-tenancy:**
   - ¿Los elementos, tareas y planes de trabajo son por compañía?
   - ¿O son compartidos entre compañías?

7. **Estados:**
   - ¿Las tareas tienen estados? (pendiente, en progreso, completada)
   - ¿Los planes de trabajo tienen estados?

8. **Resultados:**
   - ¿Dónde se guardan los resultados de la ejecución de elementos?
   - ¿Necesitamos un modelo `TaskExecution` o `VisitTaskResult`?

---

## Próximos Pasos

1. Aclarar las preguntas pendientes
2. Crear migraciones para los modelos:
   - `task_elements`
   - `tasks`
   - `task_task_elements` (tabla intermedia)
   - `work_plans`
   - `work_plan_tasks` (tabla intermedia)
3. Crear modelos con validaciones y asociaciones
4. Crear CRUDs para cada modelo
5. Implementar la lógica de asignación de planes a cadenas/formatos

---

## Notas Adicionales

- Cada elemento debe permitir escribirle el texto a mostrar al Promotor
- Los planes de trabajo se asignarán posteriormente a Cadena/Formato de cadena
- La vista del Promotor en la app móvil mostrará las visitas, permitirá iniciar visita, mostrar el plan de trabajo, y ejecutar tareas una por una
