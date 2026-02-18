# Formato Excel para Importar Actualizaciones de Precios

## Estructura del Archivo

El archivo Excel debe tener las siguientes columnas en la primera fila (encabezados):

| Codigo_Cadena | Codigo_Formato | Codigo_Producto | Codigo_Presentacion | Nuevo_Precio | Notas (opcional) |
|---------------|----------------|-----------------|---------------------|--------------|------------------|
| WAL | WAL_SUP | PROD001 | PRES001 | 25.50 | Actualización promoción |
| SOR | SOR_HIP | PROD002 | PRES002 | 30.00 | |

## Descripción de Columnas

### 1. Codigo_Cadena (Requerido)
- **Tipo**: Texto
- **Descripción**: Código único de la cadena de retail
- **Ejemplos**: "WAL", "SOR", "CHD"
- **Nota**: Debe coincidir exactamente con el código registrado en el sistema

### 2. Codigo_Formato (Requerido)
- **Tipo**: Texto
- **Descripción**: Código único del formato de la cadena
- **Ejemplos**: "WAL_SUP", "SOR_HIP", "CHD_STD"
- **Nota**: Debe coincidir exactamente con el código registrado en el sistema y pertenecer a la cadena especificada

### 3. Codigo_Producto (Requerido)
- **Tipo**: Texto
- **Descripción**: Código único del producto en tu compañía
- **Ejemplos**: "PROD001", "ABC123"
- **Nota**: Debe existir en el sistema y pertenecer a tu compañía

### 4. Codigo_Presentacion (Requerido)
- **Tipo**: Texto
- **Descripción**: Código de la presentación del producto
- **Ejemplos**: "PRES001", "500ML"
- **Nota**: Debe existir y pertenecer al producto especificado
- **Alternativa**: Puedes usar el `barcode` de la presentación si lo prefieres

### 5. Nuevo_Precio (Requerido)
- **Tipo**: Número decimal
- **Descripción**: Nuevo precio a aplicar
- **Formato**: Número con hasta 2 decimales
- **Ejemplos**: 25.50, 100.00, 15.75
- **Validación**: Debe ser mayor a 0

### 6. Notas (Opcional)
- **Tipo**: Texto
- **Descripción**: Notas adicionales sobre la actualización
- **Ejemplos**: "Actualización promoción", "Precio especial temporada"

## Ejemplo Completo

```
Codigo_Cadena | Codigo_Formato | Codigo_Producto | Codigo_Presentacion | Nuevo_Precio | Notas
--------------|----------------|-----------------|---------------------|--------------|------------------
WAL           | WAL_SUP        | PROD001         | PRES001             | 25.50        | Promoción verano
WAL           | WAL_EXP        | PROD001         | PRES002             | 30.00        | 
SOR           | SOR_HIP        | PROD002         | PRES001             | 28.75        | Actualización
CHD           | CHD_STD        | PROD003         | PRES001             | 22.00        |
```

## Códigos de Cadenas Disponibles

- **WAL** - Walmart
- **SOR** - Soriana
- **CHD** - Chedraui
- **COM** - La Comer
- **HEB** - H-E-B
- **FEM** - FEMSA
- **LEY** - Casa Ley
- **SMT** - S-Mart

## Códigos de Formatos Disponibles

### Walmart (WAL)
- **WAL_SUP** - Walmart Supercenter
- **WAL_EXP** - Walmart Express
- **WAL_BOD** - Bodega Aurrera
- **WAL_SAM** - Sam's Club

### Soriana (SOR)
- **SOR_HIP** - Soriana Híper
- **SOR_SUP** - Soriana Súper
- **SOR_MER** - Soriana Mercado
- **SOR_CIT** - City Club

### Chedraui (CHD)
- **CHD_STD** - Chedraui
- **CHD_SEL** - Selecto Chedraui
- **CHD_SUP** - Súper Chedraui
- **CHD_CHE** - Súper Che / Súpercito

### La Comer (COM)
- **COM_STD** - La Comer
- **COM_CIT** - City Market
- **COM_FRE** - Fresko
- **COM_SUM** - Sumesa

### H-E-B (HEB)
- **HEB_STD** - H-E-B
- **HEB_TIA** - Mi Tienda del Ahorro

### FEMSA (FEM)
- **FEM_OXX** - OXXO

### Casa Ley (LEY)
- **LEY_STD** - Casa Ley

### S-Mart (SMT)
- **SMT_STD** - S-Mart

## Reglas de Validación

1. **Codigo_Cadena y Codigo_Formato**: Deben existir en el sistema y el formato debe pertenecer a la cadena especificada
2. **Producto**: Debe existir y pertenecer a tu compañía
3. **Presentación**: Debe existir y pertenecer al producto especificado
4. **Precio**: Debe ser un número positivo mayor a 0
5. **Duplicados**: Si hay múltiples filas con la misma combinación Codigo_Cadena+Codigo_Formato+Producto+Presentación, se tomará la última

## Asignación de Actualizaciones

Las actualizaciones se asignarán automáticamente a:
- **Todas las tiendas** que pertenezcan a la combinación Codigo_Cadena+Codigo_Formato especificada
- Estado inicial: **Pendiente** (pending)

Esto significa que la actualización aparecerá en todas las visitas futuras a esas tiendas hasta ser aplicada.

## Proceso de Importación

1. El sistema lee el archivo Excel
2. Valida cada fila según las reglas anteriores
3. Busca la tienda(s) que coincidan con Codigo_Cadena+Codigo_Formato
4. Busca el producto por código
5. Busca la presentación por código (o barcode)
6. Crea registros `PriceUpdate` con status `pending` para cada tienda encontrada
7. Muestra un reporte con:
   - Filas procesadas exitosamente
   - Filas con errores y sus razones
   - Total de actualizaciones creadas

## Errores Comunes

- **Cadena no encontrada**: Verifica que el código coincida exactamente
- **Formato no encontrado**: Verifica que el código del formato pertenezca a la cadena
- **Producto no encontrado**: Verifica el código del producto
- **Presentación no encontrada**: Verifica el código de la presentación
- **Precio inválido**: Debe ser un número positivo
