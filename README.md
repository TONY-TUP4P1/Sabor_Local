# 📱 SaborLocal

SaborLocal es una aplicación móvil desarrollada en **Flutter** con backend en **Supabase**, diseñada para digitalizar y agilizar la gestión de un restaurante de comida típica.

El sistema soluciona problemas de lentitud en la toma de pedidos, desorden en inventarios y falta de visibilidad en cocina y gerencia, conectando en tiempo real a **Clientes, Cocina y Administración**.

---

## 🚀 Funcionalidades Principales

- Pedidos digitales desde mesa o domicilio.  
- Cocina digital con actualización instantánea de comandas (KDS).  
- Control automático de inventario basado en recetas.  
- Dashboard de ventas para gerencia.  
- Reservas integradas.  
- Gestión de menú con CRUD completo.  

---

# 📘 Historias de Usuario

---

## 👤 Perfil Cliente (HU-C)

### **HU-C1: Ver Menú y Detalles de Platos**
**Descripción:**  
Como cliente, quiero ver la lista de platos con fotos, precios e ingredientes reales para decidir qué comer.

**Criterios de Aceptación:**
- Debe poder desplazarse por la lista de platos.
- Al tocar un plato, se muestra una pantalla con ingredientes desde la BD (tabla `recetas`).

---

### **HU-C2: Realizar Pedido (Carrito)**
**Descripción:**  
Como cliente, quiero agregar platos a un carrito y confirmar mi pedido.

**Criterios de Aceptación:**
- El total se calcula automáticamente.
- Al confirmar, se crea un registro en `pedidos` y se descuenta stock.
- Solo usuarios logueados pueden pedir.

---

### **HU-C3: Monitoreo de Pedido en Tiempo Real**
**Descripción:**  
Como cliente, quiero ver el progreso: *Pendiente*, *En Cocina*, *Listo*.

**Criterios de Aceptación:**
- La pantalla “Mis Pedidos” se actualiza automáticamente.
- Se muestran indicadores visuales según estado.

---

### **HU-C4: Reservar Mesa**
**Descripción:**  
Como cliente, quiero reservar mesa eligiendo fecha, hora y número de personas.

**Criterios de Aceptación:**
- Calendario para seleccionar fecha y hora.
- No puede modificarse si faltan menos de 24 horas.
- Puede ver sus reservas futuras.

---

## 🧑‍🍳 Perfil Empleado / Admin (HU-E)

### **HU-E1: Gestión de Comandas (KDS)**
**Descripción:**  
Como cocinero, quiero ver pedidos activos y cambiar su estado.

**Criterios de Aceptación:**
- Solo se muestran pedidos no entregados.
- Cambios rápidos a “En Cocina” y “Listo”.
- Actualización en tiempo real.

---

### **HU-E2: Gestión del Menú (CRUD)**
**Descripción:**  
Como administrador, quiero crear, editar o desactivar platos.

**Criterios de Aceptación:**
- Subir URL de imagen y definir precio.
- Definir receta (ingredientes necesarios).

---

### **HU-E3: Control de Inventario Inteligente**
**Descripción:**  
Como administrador, quiero gestionar stock y que se descuente automáticamente al vender.

**Criterios de Aceptación:**
- Trigger descuenta ingredientes según receta.
- Alertas visuales cuando el stock es bajo.

---

### **HU-E4: Dashboard de Ventas y Roles**
**Descripción:**  
Como gerente, quiero ver ventas del día y gestionar roles.

**Criterios de Aceptación:**
- Mostrar dinero recaudado hoy.
- Buscar usuarios y asignar roles: Cliente, Cocina, Admin.

---

# 🛠️ Requisitos Funcionales (RF) del MVP

### **1. Autenticación y Seguridad**
- Registro/inicio de sesión con Email/Password.
- Row Level Security (RLS) en Supabase.
- Cada usuario solo ve su propia información.

---

### **2. Base de Datos en Tiempo Real**
- Uso de Streams/WebSockets (Supabase Realtime).
- Cocina recibe pedidos al instante.
- Clientes ven cambios sin refrescar.

---

### **3. Lógica de Negocio con Triggers**
- Trigger PostgreSQL descuenta stock según receta al confirmar venta.

---

### **4. Gestión de Imágenes y Assets**
- Manejo de imágenes mediante URLs.
- Splash screen, ícono y logo configurados en `pubspec.yaml`.

---

### **5. Validación de Formularios**
- Validación de campos vacíos, tipos numéricos y formato de email.

---

### **6. Navegación por Roles**
- `auth_gate` detecta rol y redirige a:
  - Cliente → Menú  
  - Cocina → Comandas  
  - Admin → Panel de Administración  

---

