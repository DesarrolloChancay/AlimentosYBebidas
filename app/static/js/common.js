/**
 * Funciones comunes reutilizables para el sistema de inspecciones
 * Castillo de Chancay - Sistema de Alimentos y Bebidas
 */

// ===== API HELPERS =====
const API = {
    /**
     * Realiza una petición GET con manejo de errores
     */
    async get(url, options = {}) {
        try {
            const response = await fetch(url, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                credentials: 'same-origin',
                ...options
            });
            
            if (!response.ok) {
                throw new Error(`Error HTTP: ${response.status} - ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            throw error;
        }
    },

    /**
     * Realiza una petición POST con manejo de errores
     */
    async post(url, data, options = {}) {
        try {
            const response = await fetch(url, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                credentials: 'same-origin',
                body: JSON.stringify(data),
                ...options
            });
            
            if (!response.ok) {
                throw new Error(`Error HTTP: ${response.status} - ${response.statusText}`);
            }
            
            return await response.json();
        } catch (error) {
            throw error;
        }
    }
};

// ===== ESTABLECIMIENTOS API =====
const EstablecimientosAPI = {
    /**
     * Carga todos los establecimientos disponibles
     */
    async cargar() {
        return await API.get('/api/establecimientos');
    },

    /**
     * Puebla un select con los establecimientos
     */
    async poblarSelect(selectElement, placeholder = 'Todos los establecimientos') {
        if (!selectElement) {
            return false;
        }

        // Verificación adicional para elementos DOM válidos
        if (!selectElement.nodeType || selectElement.nodeType !== 1) {
            return false;
        }

        if (selectElement.tagName.toLowerCase() !== 'select') {
            return false;
        }

        try {

            const establecimientos = await this.cargar();
            
            // Limpiar select
            selectElement.innerHTML = '';
            
            // Agregar opción por defecto
            const defaultOption = document.createElement('option');
            defaultOption.value = '';
            defaultOption.textContent = placeholder;
            selectElement.appendChild(defaultOption);
            
            // Agregar establecimientos
            if (Array.isArray(establecimientos) && establecimientos.length > 0) {
                establecimientos.forEach(establecimiento => {
                    if (establecimiento.id && establecimiento.nombre) {
                        const option = document.createElement('option');
                        option.value = establecimiento.id.toString();
                        option.textContent = sanitizeText(establecimiento.nombre);
                        selectElement.appendChild(option);
                    }
                });
                
                return true;
            } else {
                const noDataOption = document.createElement('option');
                noDataOption.value = '';
                noDataOption.textContent = 'No hay establecimientos disponibles';
                selectElement.appendChild(noDataOption);
                return false;
            }
        } catch (error) {
            
            // Mostrar opción de error
            selectElement.innerHTML = '';
            const errorOption = document.createElement('option');
            errorOption.value = '';
            errorOption.textContent = 'Error cargando establecimientos';
            selectElement.appendChild(errorOption);
            
            return false;
        }
    }
};

// ===== ENCARGADOS API =====
const EncargadosAPI = {
    /**
     * Carga encargados de un establecimiento específico
     */
    async cargar(establecimientoId) {
        if (!establecimientoId) {
            throw new Error('ID de establecimiento requerido');
        }
        
        return await API.get(`/api/usuarios/encargados?establecimiento_id=${establecimientoId}`);
    },

    /**
     * Puebla un select con los encargados de un establecimiento
     */
    async poblarSelect(selectElement, establecimientoId, placeholder = 'Todos los encargados') {
        if (!selectElement) {
            return false;
        }

        try {
            selectElement.innerHTML = '<option value="">Cargando encargados...</option>';
            selectElement.disabled = false;
            
            const encargados = await this.cargar(establecimientoId);
            
            // Limpiar select
            selectElement.innerHTML = '';
            
            // Agregar opción por defecto
            const defaultOption = document.createElement('option');
            defaultOption.value = '';
            defaultOption.textContent = encargados.length > 0 ? placeholder : 'No hay encargados asignados';
            selectElement.appendChild(defaultOption);
            
            // Agregar encargados
            if (Array.isArray(encargados) && encargados.length > 0) {
                encargados.forEach(encargado => {
                    if (encargado.id && encargado.nombre) {
                        const option = document.createElement('option');
                        option.value = encargado.id.toString();
                        
                        const nombreLimpio = sanitizeText(encargado.nombre);
                        const estadoTexto = encargado.activo === false ? ' (Inactivo)' : '';
                        
                        option.textContent = nombreLimpio + estadoTexto;
                        
                        // Marcar inactivos visualmente
                        if (!encargado.activo) {
                            option.style.color = '#6b7280';
                            option.style.fontStyle = 'italic';
                        }
                        
                        selectElement.appendChild(option);
                    }
                });
                
                return true;
            }
            
            return false;
        } catch (error) {
            
            // Mostrar opción de error
            selectElement.innerHTML = '';
            const errorOption = document.createElement('option');
            errorOption.value = '';
            errorOption.textContent = 'Error cargando encargados';
            selectElement.appendChild(errorOption);
            
            return false;
        }
    },

    /**
     * Configura la relación establecimiento-encargado
     */
    configurarRelacion(selectEstablecimiento, selectEncargado) {
        if (!selectEstablecimiento || !selectEncargado) {
            return;
        }

        selectEstablecimiento.addEventListener('change', async () => {
            const establecimientoId = selectEstablecimiento.value;
            
            if (establecimientoId && establecimientoId !== '') {
                // Habilitar y cargar encargados
                selectEncargado.disabled = false;
                selectEncargado.classList.remove('cursor-not-allowed', 'bg-gray-100', 'dark:bg-slate-600');
                selectEncargado.classList.add('bg-white', 'dark:bg-slate-700');
                
                await this.poblarSelect(selectEncargado, establecimientoId);
            } else {
                // Deshabilitar encargados
                selectEncargado.disabled = true;
                selectEncargado.classList.add('cursor-not-allowed', 'bg-gray-100', 'dark:bg-slate-600');
                selectEncargado.classList.remove('bg-white', 'dark:bg-slate-700');
                
                selectEncargado.innerHTML = '<option value="">Seleccione un establecimiento primero</option>';
                selectEncargado.value = '';
            }
        });
    }
};

// ===== UI HELPERS =====
const UI = {
    /**
     * Muestra/oculta elementos de loading
     */
    toggleLoading(element, show) {
        if (element) {
            if (show) {
                element.classList.remove('hidden');
            } else {
                element.classList.add('hidden');
            }
        }
    },

    /**
     * Muestra notificaciones/errores
     */
    showNotification(message, type = 'info') {
        // TODO: Implementar sistema de notificaciones
    },

    /**
     * Formatea fechas para mostrar
     */
    formatDate(dateString, locale = 'es-ES') {
        try {
            return new Date(dateString).toLocaleDateString(locale);
        } catch (error) {
            return dateString;
        }
    },

    /**
     * Sanitiza texto de forma segura
     */
    sanitizeText(text) {
        // Validar entrada
        if (!text || typeof text !== 'string') {
            return '';
        }
        
        // Aplicar sanitización básica
        const sanitized = text.replace(/[<>&"']/g, function(char) {
            const escapeMap = { 
                '<': '&lt;', 
                '>': '&gt;', 
                '&': '&amp;', 
                '"': '&quot;', 
                "'": '&#x27;' 
            };
            return escapeMap[char] || char;
        });
        
        // Asegurar que el resultado sea un string
        return String(sanitized);
    }
};

// ===== PERMISOS/ROLES =====
const Permisos = {
    /**
     * Verifica si el usuario tiene permiso para ver establecimientos
     */
    puedeVerEstablecimientos() {
        // Si existe el elemento select, significa que tiene permisos
        return !!document.getElementById('filtro-establecimiento');
    },

    /**
     * Obtiene el rol del usuario desde el DOM o contexto
     */
    obtenerRolUsuario() {
        // Intentar obtener desde meta tag o elemento oculto
        const metaRole = document.querySelector('meta[name="user-role"]');
        if (metaRole) {
            return metaRole.getAttribute('content');
        }
        
        // Fallback: verificar permisos basado en elementos presentes
        if (this.puedeVerEstablecimientos()) {
            return 'Inspector'; // o 'Administrador'
        }
        
        return 'Usuario';
    }
};

// ===== VALIDACIONES =====
const Validaciones = {
    /**
     * Valida que un elemento DOM existe
     */
    elemento(elemento, nombre) {
        if (!elemento) {
            return false;
        }
        return true;
    },

    /**
     * Valida formato de fecha
     */
    fecha(fechaString) {
        if (!fechaString) return true; // Opcional
        
        const fecha = new Date(fechaString);
        return !isNaN(fecha.getTime());
    },

    /**
     * Valida ID numérico
     */
    id(id) {
        return id && !isNaN(parseInt(id)) && parseInt(id) > 0;
    }
};

// ===== EXPORTAR FUNCIONES GLOBALES =====
window.AppCommon = {
    API,
    EstablecimientosAPI,
    EncargadosAPI,
    UI,
    Permisos,
    Validaciones
};

// Para compatibilidad con código existente - solo para páginas que no tienen implementación específica
window.cargarEncargados = function(selectElement, placeholder) {
    if (!selectElement) {
        return Promise.resolve(false);
    }
    return EncargadosAPI.poblarSelect(selectElement, placeholder);
};
