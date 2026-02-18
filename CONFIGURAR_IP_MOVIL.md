# Configurar IP para App Móvil

## Para Dispositivo Físico

### 1. Obtener la IP de tu Mac

Ejecuta en la terminal:
```bash
ipconfig getifaddr en0
```

O:
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### 2. Actualizar NetworkModule.kt

En `handy_promo_mobile/app/src/main/kotlin/com/handy/promomobile/di/NetworkModule.kt`:

```kotlin
private const val BASE_URL = "http://TU_IP_AQUI:3000/"
```

**Ejemplo:**
```kotlin
private const val BASE_URL = "http://192.168.86.26:3000/"
```

### 3. Asegurar que el servidor Rails escuche en todas las interfaces

El servidor debe estar corriendo con:
```bash
rails s
```

O explícitamente:
```bash
rails s -b 0.0.0.0
```

Verifica que esté escuchando en todas las interfaces:
```bash
lsof -i:3000 | grep LISTEN
```

Deberías ver `*:hbci (LISTEN)`.

### 4. Verificar que el dispositivo esté en la misma red WiFi

- Tu Mac y tu celular deben estar conectados a la misma red WiFi
- No funcionará si están en redes diferentes

### 5. Probar la conexión

Desde tu celular, abre un navegador y visita:
```
http://TU_IP:3000/up
```

Deberías ver una respuesta JSON con `{"status":"ok"}`.

## Para Emulador Android

Si vuelves a usar el emulador, cambia la URL a:
```kotlin
private const val BASE_URL = "http://10.0.2.2:3000/" // 10.0.2.2 es localhost en emulador
```

## Solución de Problemas

### Error: "Connection refused"
- Verifica que el servidor Rails esté corriendo
- Verifica que esté escuchando en `0.0.0.0:3000` (no solo `localhost`)
- Verifica que el firewall de macOS no esté bloqueando el puerto 3000

### Error: "Network unreachable"
- Verifica que tu Mac y celular estén en la misma red WiFi
- Verifica que la IP sea correcta

### Error: "Timeout"
- Verifica que el servidor Rails esté respondiendo (prueba con curl desde tu Mac)
- Verifica que no haya un proxy o VPN interfiriendo
