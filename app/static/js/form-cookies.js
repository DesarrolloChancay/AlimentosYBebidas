/**
 * Sistema de persistencia de cookies para formularios de inspección
 * Según pedido.txt: "Se guardará cookie del formulario para que los datos no se pierdan 
 * por si el inspector se sale de la página (se borrará esa cookie al guardar la inspección)."
 */

// Clase para manejar cookies de formulario
class FormCookieManager {
    constructor() {
        this.cookieName = 'inspeccion_form_data';
        this.expirationDays = 7; // Las cookies expirarán en 7 días
    }

    // Guardar datos del formulario en cookie
    saveFormData(establecimientoId, data) {
        try {
            const cookieData = {
                establecimiento_id: establecimientoId,
                items: data.items || {},
                evidencias: data.evidencias || [],
                observaciones: data.observaciones || '',
                resumen: data.resumen || {},
                timestamp: Date.now()
            };

            // Convertir a JSON y guardar en cookie
            const jsonData = JSON.stringify(cookieData);
            const encodedData = btoa(unescape(encodeURIComponent(jsonData))); // Base64 encode
            
            // Calcular fecha de expiración
            const expirationDate = new Date();
            expirationDate.setDate(expirationDate.getDate() + this.expirationDays);
            
            // Crear cookie
            document.cookie = `${this.cookieName}_${establecimientoId}=${encodedData}; expires=${expirationDate.toUTCString()}; path=/; secure; samesite=strict`;
            
            return true;
        } catch (error) {
            return false;
        }
    }

    // Cargar datos del formulario desde cookie
    loadFormData(establecimientoId) {
        try {
            const cookieName = `${this.cookieName}_${establecimientoId}`;
            const cookies = document.cookie.split(';');
            
            for (let cookie of cookies) {
                const [name, value] = cookie.trim().split('=');
                if (name === cookieName) {
                    // Decodificar Base64 y parsear JSON
                    const decodedData = decodeURIComponent(escape(atob(value)));
                    const formData = JSON.parse(decodedData);
                    
                    // Verificar que la cookie no sea muy antigua (más de 7 días)
                    const now = Date.now();
                    const cookieAge = now - formData.timestamp;
                    const maxAge = this.expirationDays * 24 * 60 * 60 * 1000; // 7 días en ms
                    
                    if (cookieAge > maxAge) {
                        this.clearFormData(establecimientoId);
                        return null;
                    }
                    
                    return formData;
                }
            }
            
            return null;
        } catch (error) {
            // Si hay error, limpiar la cookie corrupta
            this.clearFormData(establecimientoId);
            return null;
        }
    }

    // Limpiar datos del formulario (se llama al guardar la inspección)
    clearFormData(establecimientoId) {
        try {
            const cookieName = `${this.cookieName}_${establecimientoId}`;
            // Establecer cookie con fecha pasada para eliminarla
            document.cookie = `${cookieName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/`;
            return true;
        } catch (error) {
            return false;
        }
    }

    // Verificar si hay datos guardados para un establecimiento
    hasFormData(establecimientoId) {
        const data = this.loadFormData(establecimientoId);
        return data !== null && Object.keys(data.items || {}).length > 0;
    }

    // Obtener lista de establecimientos con datos guardados
    getSavedEstablecimientos() {
        try {
            const savedIds = [];
            const cookies = document.cookie.split(';');
            
            for (let cookie of cookies) {
                const [name] = cookie.trim().split('=');
                if (name.startsWith(this.cookieName + '_')) {
                    const establecimientoId = name.replace(this.cookieName + '_', '');
                    savedIds.push(parseInt(establecimientoId));
                }
            }
            
            return savedIds;
        } catch (error) {
            return [];
        }
    }

    // Limpiar todas las cookies de formulario (para casos de emergencia)
    clearAllFormData() {
        try {
            const savedIds = this.getSavedEstablecimientos();
            for (let id of savedIds) {
                this.clearFormData(id);
            }
            return true;
        } catch (error) {
            return false;
        }
    }

    // Limpiar cookies viejas automáticamente (más de 7 días)
    cleanupOldCookies() {
        try {
            const cookies = document.cookie.split(';');
            const now = Date.now();
            const maxAge = this.expirationDays * 24 * 60 * 60 * 1000; // Usar el mismo límite de expiración
            let cleaned = 0;
            
            for (let cookie of cookies) {
                const [name, value] = cookie.trim().split('=');
                if (name && name.startsWith(this.cookieName + '_')) {
                    try {
                        if (value) {
                            const data = JSON.parse(atob(decodeURIComponent(value)));
                            if (data.timestamp && (now - data.timestamp) > maxAge) {
                                // Cookie vieja, eliminarla
                                document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/`;
                                cleaned++;
                            }
                        }
                    } catch (e) {
                        // Cookie corrupta, eliminarla
                        document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/`;
                        cleaned++;
                    }
                }
            }
            
            if (cleaned > 0) {
            }
            
            return cleaned;
        } catch (error) {
            return 0;
        }
    }

    // Obtener el tamaño aproximado de la cookie para verificar límites
    getCookieSize(establecimientoId) {
        try {
            const data = this.loadFormData(establecimientoId);
            if (data) {
                return JSON.stringify(data).length;
            }
            return 0;
        } catch (error) {
            return 0;
        }
    }
}

// Crear instancia global
window.formCookieManager = new FormCookieManager();

// Función para mostrar mensaje de recuperación de datos
function mostrarMensajeRecuperacion() {
    const mensaje = document.createElement('div');
    mensaje.className = 'fixed top-4 right-4 bg-blue-600 text-white px-6 py-3 rounded-lg shadow-lg z-50 flex items-center space-x-3';
    mensaje.innerHTML = `
        <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        <span>Datos del formulario recuperados desde la sesión anterior</span>
        <button onclick="this.parentNode.remove()" class="ml-2 text-white hover:text-gray-200">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
        </button>
    `;
    
    document.body.appendChild(mensaje);
    
    // Auto-remover después de 5 segundos
    setTimeout(() => {
        if (mensaje.parentNode) {
            mensaje.parentNode.removeChild(mensaje);
        }
    }, 5000);
}

// Exportar funciones para uso global
if (typeof window !== 'undefined') {
    window.FormCookieManager = FormCookieManager;
    window.mostrarMensajeRecuperacion = mostrarMensajeRecuperacion;
}
