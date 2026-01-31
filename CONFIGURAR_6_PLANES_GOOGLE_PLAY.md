# 🎮 Configurar 6 Planes de Suscripción en Google Play Console
## AutoGestión Pro - Sistema de Flotillas

---

## 📊 ESTRUCTURA DE 6 PLANES (1ER VEHÍCULO GRATIS)

| Plan | Total Vehículos | Veh. Adicionales | Precio/Adicional | Rango Mensual | USD Aprox |
|------|----------------|------------------|------------------|---------------|-----------|
| **Free** | 1 | 0 | - | $0 | $0 |
| **Starter** | 2-5 | 1-4 | $175 MXN | $175-$700 MXN | $10-$40 |
| **Small** | 6-10 | 5-9 | $165 MXN | $825-$1,485 MXN | $46-$83 |
| **Medium** | 11-20 | 10-19 | $155 MXN | $1,550-$2,945 MXN | $86-$164 |
| **Large** | 21-35 | 20-34 | $145 MXN | $2,900-$4,930 MXN | $161-$274 |
| **Enterprise** | 36-50 | 35-49 | $135 MXN | $4,725-$6,615 MXN | $263-$368 |

**⚡ Ventaja Competitiva:** El primer vehículo siempre es gratis, solo pagas por adicionales

---

## 🚀 PASOS EN GOOGLE PLAY CONSOLE

### 1. Acceder a Play Console

1. Ve a [Google Play Console](https://play.google.com/console)
2. Inicia sesión con tu cuenta de desarrollador
3. Selecciona o crea la app "AutoGestión Pro"

---

### 2. Crear Suscripción 1: STARTER

**Ubicación:** Monetización > Productos > Suscripciones

**Clic en:** "Crear suscripción"

#### Datos básicos:
```
ID del producto: starter_monthly
Nombre: Plan Starter Mensual
Descripción: 1 vehículo gratis + hasta 4 adicionales con sincronización en la nube
```

#### Configuración de precio:
```
Precio base: 
  - México: $700 MXN (máximo: 1 gratis + 4 adicionales × $175)
  - Estados Unidos: $40 USD
  - España: €35 EUR

Período de renovación: 1 mes
Período de prueba: 7 días gratis (opcional)
```

**Guardar y Activar**

---

### 3. Crear Suscripción 2: SMALL

**Clic en:** "Crear suscripción"

#### Datos básicos:
```
ID del producto: small_monthly
Nombre: Plan Small Mensual
Descripción: 1 vehículo gratis + hasta 9 adicionales para pequeñas empresas
```

#### Configuración de precio:
```
Precio base:
  - México: $1,485 MXN (máximo: 1 gratis + 9 adicionales × $165)
  - Estados Unidos: $83 USD
  - España: €75 EUR

Período de renovación: 1 mes
Período de prueba: 7 días gratis (opcional)
```

**Guardar y Activar**

---

### 4. Crear Suscripción 3: MEDIUM

**Clic en:** "Crear suscripción"

#### Datos básicos:
```
ID del producto: medium_monthly
Nombre: Plan Medium Mensual
Descripción: 1 vehículo gratis + hasta 19 adicionales con reportes avanzados
```

#### Configuración de precio:
```
Precio base:
  - México: $2,945 MXN (máximo: 1 gratis + 19 adicionales × $155)
  - Estados Unidos: $164 USD
  - España: €145 EUR

Período de renovación: 1 mes
Período de prueba: 7 días gratis (opcional)
```

**Guardar y Activar**

---

### 5. Crear Suscripción 4: LARGE

**Clic en:** "Crear suscripción"

#### Datos básicos:
```
ID del producto: large_monthly
Nombre: Plan Large Mensual
Descripción: 1 vehículo gratis + hasta 34 adicionales con descuentos por volumen
```

#### Configuración de precio:
```
Precio base:
  - México: $4,930 MXN (máximo: 1 gratis + 34 adicionales × $145)
  - Estados Unidos: $274 USD
  - España: €245 EUR

Período de renovación: 1 mes
Período de prueba: 14 días gratis (recomendado para planes grandes)
```

**Guardar y Activar**

---

### 6. Crear Suscripción 5: ENTERPRISE

**Clic en:** "Crear suscripción"

#### Datos básicos:
```
ID del producto: enterprise_monthly
Nombre: Plan Enterprise Mensual
Descripción: 1 vehículo gratis + hasta 49 adicionales con soporte dedicado 24/7
```

#### Configuración de precio:
```
Precio base:
  - México: $6,615 MXN (máximo: 1 gratis + 49 adicionales × $135)
  - Estados Unidos: $368 USD
  - España: €330 EUR

Período de renovación: 1 mes
Período de prueba: 14 días gratis
```

**Guardar y Activar**

---

## 🧪 7. Configurar Testing

1. Ve a **Configuración** > **Licencia**
2. En "Cuentas de prueba de licencia", agrega emails:
   ```
   mtr123202@gmail.com
   (otros emails de prueba)
   ```
3. Guarda los cambios

**Los testers podrán comprar sin cargos reales**

---

## ✅ 8. Verificar Todo

Asegúrate que:

- [ ] Las 5 suscripciones están creadas
- [ ] Los IDs son exactamente:
  - `starter_monthly`
  - `small_monthly`
  - `medium_monthly`
  - `large_monthly`
  - `enterprise_monthly`
- [ ] Todas tienen estado **Activo**
- [ ] Los precios están configurados para México, USA, España
- [ ] Los emails de prueba están agregados

---

## 💰 PROYECCIÓN DE INGRESOS

### Escenario Conservador (100 clientes):

| Plan | Clientes | Ingreso Mensual | Ingreso Anual |
|------|----------|-----------------|---------------|
| Free | 40 | $0 | $0 |
| Starter | 30 | $1,050 | $12,600 |
| Small | 15 | $1,282.50 | $15,390 |
| Medium | 10 | $1,575 | $18,900 |
| Large | 4 | $1,026 | $12,312 |
| Enterprise | 1 | $323 | $3,876 |
| **TOTAL** | **100** | **$5,256.50** | **$63,078** |

*Después del 15% de comisión de Google Play

### Escenario Optimista (500 clientes):

| Plan | Clientes | Ingreso Anual |
|------|----------|---------------|
| Free | 150 | $0 |
| Starter | 200 | $84,000 |
| Small | 80 | $81,960 |
| Medium | 50 | $94,500 |
| Large | 15 | $46,170 |
| Enterprise | 5 | $19,380 |
| **TOTAL** | **500** | **$326,010/año** |

---

## 🎯 VENTAJAS DE 6 NIVELES

### Vs. 3 Niveles:

✅ **Mejor segmentación de mercado**
- Microempresas (2-5): Plan accesible de entrada
- Pequeñas (6-10): Paso intermedio natural
- Medianas (11-20): Opción sólida con features
- Grandes (21-35): Descuento por volumen atractivo
- Muy grandes (36-50): Premium con todo incluido

✅ **Mayor conversión**
- Los clientes encuentran el plan "perfecto" para su tamaño
- Menor fricción entre free y paid
- Upgrade path claro y gradual

✅ **Maximización de ingresos**
- Capturas más valor de clientes grandes (no saltan de $25 a $100)
- Incentivo claro para upgrade (más vehículos = mejor precio/unidad)

✅ **Psicología de precios**
- Efecto ancla: Enterprise hace que Large parezca razonable
- Precio por vehículo descendente = incentivo para crecer
- Rangos flexibles por si no usan el máximo

---

## 📈 ESTRATEGIA DE PRECIOS

### Por Qué Este Modelo Funciona:

1. **Descuento por Volumen Real**
   - $175 → $135 MXN por vehículo (-23%)
   - Incentiva a agregar más vehículos
   - Recompensa la lealtad

2. **Punto de Entrada Bajo**
   - $350 MXN/mes ($20 USD) es accesible
   - Barrera de entrada mínima
   - Fácil justificar vs. papel/Excel

3. **Escalabilidad Atractiva**
   - Cada nivel tiene "espacio para crecer"
   - No fuerza a saltar de golpe
   - Cliente puede planear su crecimiento

4. **Enterprise Premium**
   - $6,750 MXN para 50 vehículos = $135/veh
   - Incluye todo + soporte dedicado
   - ROI claro para flotillas grandes

---

## 🔄 PRÓXIMOS PASOS DESPUÉS DE CONFIGURAR

1. **Compilar APK de prueba**
   ```powershell
   flutter build apk --release
   ```

2. **Probar compras** con email de tester

3. **Verificar en Firestore** que los datos se actualicen

4. **Ajustar precios** basado en conversión real

5. **Marketing**: Destacar el precio/vehículo descendente

---

## 📞 SOPORTE

Si hay problemas:

1. Verifica que los IDs coincidan exactamente
2. Espera 2-4 horas después de crear productos (propagación)
3. Confirma que la app esté en modo prueba cerrada/abierta
4. Revisa que el email esté en lista de testers

---

## ✨ RESUMEN

**¡Sistema de 6 niveles configurado!**

- ✅ Mejor que 3 niveles para flotillas
- ✅ Precio por volumen descendente
- ✅ Escalabilidad clara
- ✅ Potencial de $63K-$326K/año

**Tiempo estimado de configuración: 20-25 minutos**

---

**¡Listo para generar ingresos recurrentes!** 🚀💰
