# Reiniciar Servidor Rails para App Móvil

## Problema
El servidor Rails estaba escuchando solo en `localhost`, lo que impedía que el emulador Android (que usa `10.0.2.2` para acceder al host) se conectara.

## Solución Aplicada
1. ✅ Actualizado `config/puma.rb` para escuchar en `0.0.0.0:3000` (todas las interfaces)
2. ✅ Actualizado `ApplicationController` para no bloquear peticiones API
3. ✅ El servidor anterior fue detenido

## Pasos para Reiniciar

### Opción 1: Usando el comando con bind explícito
```bash
cd /Users/gabriel/dev/handy/handy_promo
rails s -b 0.0.0.0
```

### Opción 2: Usando la configuración de Puma (recomendado)
```bash
cd /Users/gabriel/dev/handy/handy_promo
rails s
```
(La configuración en `puma.rb` ahora escucha en `0.0.0.0` por defecto)

## Verificar que está escuchando correctamente

Después de iniciar el servidor, verifica que esté escuchando en todas las interfaces:

```bash
lsof -i:3000 | grep LISTEN
```

Deberías ver algo como:
```
ruby  <PID>  ...  TCP *:hbci (LISTEN)
```

Si ves `localhost:hbci` en lugar de `*:hbci`, el servidor no está usando la nueva configuración.

## Probar la conexión desde el emulador

1. Asegúrate de que el servidor Rails esté corriendo
2. En la app Android, intenta hacer login
3. Deberías ver en los logs del servidor Rails la petición entrante

## Nota de Seguridad

⚠️ **IMPORTANTE**: Esta configuración permite conexiones desde cualquier IP en la red local. 
- ✅ Está bien para desarrollo
- ❌ NO uses esto en producción sin un firewall adecuado

En producción, usa un servidor web (nginx/Apache) como proxy reverso y configura SSL/TLS.
