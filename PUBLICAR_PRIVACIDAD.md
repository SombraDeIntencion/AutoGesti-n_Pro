# Guía para Publicar la Política de Privacidad

## Archivo a Publicar
`privacy_policy.html` - Ubicado en la raíz del proyecto

## Opciones de Hosting

### Opción 1: GitHub Pages (Gratuito, Recomendado)

#### Pasos:
1. **Crear repositorio en GitHub** (puede ser privado)
   - Ve a https://github.com/new
   - Nombre: `autogestion-privacy-policy`
   - Selecciona "Private" si no quieres que sea público

2. **Subir el archivo**
   ```bash
   cd c:\Dev\FlutterProjects\autogestion_pro\autogestion_pro
   
   # Inicializar git
   git init
   git add privacy_policy.html
   git commit -m "Add privacy policy"
   
   # Conectar con GitHub
   git remote add origin https://github.com/TU_USUARIO/autogestion-privacy-policy.git
   git branch -M main
   git push -u origin main
   ```

3. **Activar GitHub Pages**
   - Ve a Settings > Pages
   - Source: Deploy from a branch
   - Branch: main / root
   - Save

4. **Obtener URL**
   - La URL será: `https://TU_USUARIO.github.io/autogestion-privacy-policy/privacy_policy.html`
   - Usa esta URL en Play Console

**Ventajas:**
- ✅ Gratuito
- ✅ Fácil de actualizar
- ✅ Confiable
- ✅ HTTPS incluido

---

### Opción 2: Firebase Hosting (Gratuito)

Si ya tienes Firebase configurado:

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Iniciar sesión
firebase login

# Inicializar hosting
firebase init hosting

# Copiar archivo
mkdir public
copy privacy_policy.html public\

# Desplegar
firebase deploy --only hosting
```

**URL:** `https://TU_PROYECTO.web.app/privacy_policy.html`

---

### Opción 3: Google Sites (Sin código)

1. Ve a https://sites.google.com/new
2. Crea un sitio nuevo
3. Añade una página "Política de Privacidad"
4. Copia el contenido de `privacy_policy.html`
5. Publica el sitio
6. Obtén la URL

---

### Opción 4: Netlify Drop (Más Fácil)

1. Ve a https://app.netlify.com/drop
2. Arrastra `privacy_policy.html` a la página
3. Netlify te dará una URL automáticamente
4. Copia la URL

**URL:** `https://random-name.netlify.app/privacy_policy.html`

---

### Opción 5: Hosting Propio

Si tienes dominio y hosting web:

1. Accede a tu servidor por FTP/cPanel
2. Sube `privacy_policy.html` a la carpeta pública
3. Accede via: `https://tudominio.com/privacy_policy.html`

---

## Recomendación Inmediata

Para publicar **AHORA MISMO**, usa **Netlify Drop**:

### Pasos Rápidos:
1. Abre https://app.netlify.com/drop
2. Arrastra el archivo `privacy_policy.html`
3. Copia la URL que te da
4. ¡Listo! Ya tienes tu política pública

**Tiempo:** 2 minutos

---

## Verificación

Después de publicar:
- [ ] La URL abre correctamente
- [ ] El contenido se ve bien
- [ ] Es accesible desde móvil
- [ ] HTTPS está activo
- [ ] No requiere login para ver

---

## Uso en Play Console

1. Play Console > Tu App
2. Política y programas > Privacidad y seguridad
3. Pega la URL de tu política
4. Guardar

---

## Actualización Futura

Si necesitas actualizar la política:

**GitHub Pages:**
```bash
# Editar archivo
# Luego:
git add privacy_policy.html
git commit -m "Update privacy policy"
git push
```

**Netlify Drop:**
- Sube el archivo actualizado nuevamente

---

## URL de Ejemplo

Después de publicar, tu URL debería verse así:
```
https://usuario.github.io/autogestion-privacy-policy/privacy_policy.html
o
https://app-name-12345.netlify.app/privacy_policy.html
```

Esta URL es la que pondrás en Play Console.

---

## Siguiente Paso

**Elige una opción y publícala AHORA:**

¿Cuál prefieres?
1. GitHub Pages (recomendado para control)
2. Netlify Drop (más rápido, 2 minutos)
3. Otra opción
