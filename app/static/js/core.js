/**
 * CORE SYSTEM - Funciones esenciales compartidas
 * Castillo de Chancay - Sistema de Alimentos y Bebidas
 * 
 * Este archivo contiene SOLO las funciones más críticas y compartidas
 * para evitar duplicación y asegurar que estén disponibles en todos los templates
 */

// ===== VARIABLES GLOBALES =====
window.AppCore = window.AppCore || {};

// ===== FUNCIONES DE AUTENTICACIÓN Y SESIÓN =====
/**
 * Cierra la sesión del usuario actual
 * NOTA: Esta es una versión simplificada para templates básicos.
 * app.js tiene una versión más completa para index.html
 */
async function cerrarSesionBasico() {
    try {
        // Fallback simple para templates que no tienen mostrarDialogoConfirmacion
        if (!confirm('¿Estás seguro de que deseas cerrar sesión?')) {
            return;
        }

        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            credentials: 'same-origin'
        });
        
        // Limpiar datos locales
        localStorage.clear();
        sessionStorage.clear();
        
        // Redirigir al login
        window.location.href = '/login';
    } catch (error) {
        // Forzar redirect en caso de error
        window.location.href = '/login';
    }
}

// ===== MANEJO DE ARCHIVOS =====
/**
 * Maneja la selección de archivos para firmas (versión mejorada)
 */
function handleFileSelect(event, tipo) {
    const file = event.target.files[0];
    if (!file) return;

    // Validar que sea imagen
    if (!file.type.startsWith('image/')) {
        alert('Por favor seleccione una imagen válida');
        event.target.value = '';
        return;
    }

    // Validar archivo usando función de seguridad
    const validacion = validateImageFile(file);
    if (!validacion.valid) {
        alert(`Error: ${validacion.error}`);
        event.target.value = '';
        return;
    }

    const reader = new FileReader();
    reader.onload = function(e) {
        // Actualizar estado global si existe (para app.js)
        if (window.inspeccionEstado) {
            window.inspeccionEstado[`firma_${tipo}`] = e.target.result;
        }

        // Mostrar preview  
        const preview = document.getElementById(`preview-firma-${tipo}`);
        if (preview) {
            const imgUrl = e.target.result;
            preview.innerHTML = `
                <div class="relative">
                    <img src="${imgUrl}" 
                         class="max-w-full h-20 object-contain border rounded cursor-pointer" 
                         onclick="abrirVistaPrevia ? abrirVistaPrevia('${imgUrl}') : void(0)">
                </div>
                <p class="text-xs text-gray-500 mt-1">Haga clic en la imagen para ampliar</p>
            `;
        }

        // Funciones específicas de app.js si están disponibles
        if (typeof actualizarInterfazFirmas === 'function') {
            actualizarInterfazFirmas();
        }
        
        if (typeof guardarEstadoTemporal === 'function') {
            guardarEstadoTemporal();
        }

    };
    reader.readAsDataURL(file);
}

/**
 * Elimina la firma seleccionada (versión mejorada)
 */
function eliminarFirma(tipo) {
    // Actualizar estado global si existe (para app.js)
    if (window.inspeccionEstado) {
        window.inspeccionEstado[`firma_${tipo}`] = null;
    }

    // Limpiar input y preview
    const input = document.getElementById(`firma-${tipo}`);
    const preview = document.getElementById(`preview-firma-${tipo}`);
    
    if (input) {
        input.value = '';
    }
    
    if (preview) {
        preview.innerHTML = '';
    }

    // Funciones específicas de app.js si están disponibles
    if (typeof actualizarInterfazFirmas === 'function') {
        actualizarInterfazFirmas();
    }
    
    if (typeof guardarEstadoTemporal === 'function') {
        guardarEstadoTemporal();
    }
    
}

// ===== GESTIÓN DE EVIDENCIAS =====
function asegurarEstadoEvidenciasCompartido() {
    const estado = window.inspeccionEstado || {};

    if (!Array.isArray(window.evidenciasAcumuladas)) {
        window.evidenciasAcumuladas = Array.isArray(estado.evidencias) ? estado.evidencias : [];
    }

    if (!Array.isArray(window.evidenciasAcumuladas)) {
        window.evidenciasAcumuladas = [];
    }

    if (!Array.isArray(estado.evidencias) || estado.evidencias !== window.evidenciasAcumuladas) {
        estado.evidencias = window.evidenciasAcumuladas;
    }

    window.inspeccionEstado = estado;
    return window.evidenciasAcumuladas;
}

/**
 * Inicializa el sistema de evidencias fotográficas
 */
function inicializarEvidencias() {
    const evidenciasInput = document.getElementById('evidencias-input');
    if (!evidenciasInput) return;
    
    // Array para almacenar todas las evidencias
    asegurarEstadoEvidenciasCompartido();

    sincronizarEvidenciasExistentes();
    
    evidenciasInput.addEventListener('change', function(event) {
        const files = Array.from(event.target.files);
        if (files.length === 0) return;
        
        procesarEvidencias(files);
        
        // Limpiar el input para permitir seleccionar los mismos archivos otra vez
        event.target.value = '';
    });
}

/**
 * Procesa las evidencias seleccionadas (acumulativas)
 */
function procesarEvidencias(files) {
    asegurarEstadoEvidenciasCompartido();
    const preview = document.getElementById('evidencias-preview');
    const contador = document.getElementById('evidencias-contador');
    
    if (!preview) return;
    
    // Validar archivos nuevos
    const archivosValidos = [];
    for (const file of files) {
        const validacion = validateImageFile(file);
        if (validacion.valid) {
            archivosValidos.push(file);
        } else {
            alert(`Archivo inválido: ${file.name} - ${validacion.error}`);
        }
    }
    
    // Agregar a la lista acumulada con IDs únicos
    asegurarEstadoEvidenciasCompartido();
    
    // Generar IDs únicos para cada archivo
    archivosValidos.forEach(file => {
        file._uniqueId = 'evidencia_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9);
        window.evidenciasAcumuladas.push(file);
    });
    
    actualizarVistaEvidencias();
}

/**
 * Actualiza la vista completa de evidencias
 */
function actualizarVistaEvidencias() {
    asegurarEstadoEvidenciasCompartido();
    const preview = document.getElementById('evidencias-preview');
    const contador = document.getElementById('evidencias-contador');
    
    if (!preview) return;
    
    // Actualizar contador
    if (contador) {
        contador.textContent = `${window.evidenciasAcumuladas.length} evidencia(s) seleccionada(s)`;
    }
    
    // Limpiar y recrear previews
    preview.innerHTML = '';
    window.evidenciasAcumuladas.forEach((file) => {
        crearPreviewEvidencia(file, preview);
    });
}

function sincronizarEvidenciasExistentes() {
    try {
        asegurarEstadoEvidenciasCompartido();
        const preview = document.getElementById('evidencias-preview');
        if (!preview) return;

        const previewsExistentes = preview.querySelectorAll('[data-evidencia-id]');
        if (previewsExistentes.length === 0) {
            actualizarVistaEvidencias();
            return;
        }

        previewsExistentes.forEach((element) => {
            const evidenciaId = element.getAttribute('data-evidencia-id');
            const archivoEncontrado = window.evidenciasAcumuladas.find(
                (file) => file._uniqueId === evidenciaId
            );

            if (!archivoEncontrado) {
                const nombreArchivo = (element.querySelector('div.text-xs') || {}).textContent || 'evidencia';
                const imagen = element.querySelector('img');

                if (imagen && imagen.src) {
                    try {
                        const file = crearArchivoDesdeDataUrl(imagen.src, nombreArchivo.trim());
                        if (file) {
                            file._uniqueId = evidenciaId || 'evidencia_' + Date.now() + Math.random().toString(36).substring(2, 8);
                            window.evidenciasAcumuladas.push(file);
                        }
                    } catch (error) {
                    }
                }
            }
        });

        actualizarVistaEvidencias();
    } catch (error) {
        actualizarVistaEvidencias();
    }
}

function crearArchivoDesdeDataUrl(dataUrl, nombreArchivo) {
    try {
        const partes = dataUrl.split(',');
        if (partes.length < 2) return null;

        const metadata = partes[0];
        const base64Data = partes[1];
        const mimeMatch = metadata.match(/data:([^;]+)/);
        const mimeType = mimeMatch ? mimeMatch[1] : 'image/png';
        const extension = mimeType.split('/')[1] || 'png';
        const nombreLimpio = nombreArchivo && nombreArchivo.includes('.')
            ? nombreArchivo
            : `${nombreArchivo || 'evidencia'}.${extension}`;

        const binary = atob(base64Data);
        const length = binary.length;
        const buffer = new Uint8Array(length);
        for (let i = 0; i < length; i++) {
            buffer[i] = binary.charCodeAt(i);
        }

        const file = new File([buffer], nombreLimpio, { type: mimeType });
        return file;
    } catch (error) {
        return null;
    }
}

/**
 * Crea preview individual de evidencia con modal
 */
function crearPreviewEvidencia(file, container) {
    const reader = new FileReader();
    reader.onload = function(e) {
        const div = document.createElement('div');
        div.className = 'relative inline-block m-2';
        div.dataset.evidenciaId = file._uniqueId;
        
        const imageContainer = document.createElement('div');
        imageContainer.className = 'relative';
        
        const img = document.createElement('img');
        img.src = e.target.result;
        img.alt = `Evidencia: ${file.name}`;
        img.className = 'w-24 h-24 object-cover border rounded shadow cursor-pointer hover:opacity-80 transition-opacity';
        
        // Agregar evento de click para abrir modal
        img.addEventListener('click', function() {
            abrirModalEvidencia(e.target.result, file.name);
        });
        
        const deleteBtn = document.createElement('button');
        deleteBtn.type = 'button';
        deleteBtn.className = 'absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm hover:bg-red-600 transition-colors';
        deleteBtn.innerHTML = '×';
        
        // Agregar evento de click para eliminar usando el ID único
        deleteBtn.addEventListener('click', function() {
            eliminarEvidenciaPorId(file._uniqueId);
        });
        
        const nameDiv = document.createElement('div');
        nameDiv.className = 'text-xs text-center mt-1 max-w-24 truncate';
        nameDiv.title = file.name;
        nameDiv.textContent = file.name;
        
        imageContainer.appendChild(img);
        imageContainer.appendChild(deleteBtn);
        div.appendChild(imageContainer);
        div.appendChild(nameDiv);
        
        container.appendChild(div);
    };
    reader.readAsDataURL(file);
}

/**
 * Elimina una evidencia específica por ID único
 */
function eliminarEvidenciaPorId(uniqueId) {
    asegurarEstadoEvidenciasCompartido();
    if (!window.evidenciasAcumuladas) {
        return;
    }
    
    
    // Buscar y remover por ID único
    const index = window.evidenciasAcumuladas.findIndex(file => file._uniqueId === uniqueId);
    if (index !== -1) {
        window.evidenciasAcumuladas.splice(index, 1);
        
        // Actualizar vista
        actualizarVistaEvidencias();
    } else {
    }
}

/**
 * Función de compatibilidad para el sistema anterior
 */
function eliminarEvidencia(indexOrId) {
    asegurarEstadoEvidenciasCompartido();
    // Si es un número, usar el sistema anterior (compatibilidad)
    if (typeof indexOrId === 'number') {
        if (!window.evidenciasAcumuladas || indexOrId < 0 || indexOrId >= window.evidenciasAcumuladas.length) {
            return;
        }
        window.evidenciasAcumuladas.splice(indexOrId, 1);
        actualizarVistaEvidencias();
    } else {
        // Si es string, es un ID único
        eliminarEvidenciaPorId(indexOrId);
    }
}

/**
 * Abre modal para ver evidencia en grande
 */
function abrirModalEvidencia(src, nombre) {
    // Crear modal específico para evidencias (no usar abrirVistaPrevia de app.js)
    // ya que esa función valida URLs de archivo y no funciona con datos base64
    
    // Crear modal simple para evidencias
    const modal = document.createElement('div');
    modal.id = 'modal-evidencia';
    modal.className = 'fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50';
    
    const modalContent = document.createElement('div');
    modalContent.className = 'relative max-w-4xl max-h-4xl p-4';
    
    const img = document.createElement('img');
    img.src = src;
    img.alt = `Evidencia: ${nombre}`;
    img.className = 'max-w-full max-h-full object-contain';
    
    const closeBtn = document.createElement('button');
    closeBtn.className = 'absolute top-2 right-2 bg-red-500 text-white rounded-full w-8 h-8 flex items-center justify-center hover:bg-red-600';
    closeBtn.innerHTML = '×';
    closeBtn.addEventListener('click', cerrarModalEvidencia);
    
    const nameLabel = document.createElement('div');
    nameLabel.className = 'absolute bottom-2 left-2 bg-black bg-opacity-50 text-white px-2 py-1 rounded text-sm';
    nameLabel.textContent = nombre;
    
    modalContent.appendChild(img);
    modalContent.appendChild(closeBtn);
    modalContent.appendChild(nameLabel);
    modal.appendChild(modalContent);
    
    // Cerrar con ESC o click fuera
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            cerrarModalEvidencia();
        }
    });
    
    // Listener para ESC (se agrega temporalmente)
    const escListener = function(e) {
        if (e.key === 'Escape') {
            cerrarModalEvidencia();
            document.removeEventListener('keydown', escListener);
        }
    };
    document.addEventListener('keydown', escListener);
    
    document.body.appendChild(modal);
}

/**
 * Cierra el modal de evidencia
 */
function cerrarModalEvidencia() {
    const modal = document.getElementById('modal-evidencia');
    if (modal) {
        modal.remove();
    }
}

// ===== API HELPERS COMUNES =====
/**
 * GET request con manejo de errores
 */
async function fetchAPI(url, options = {}) {
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
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        throw error;
    }
}

/**
 * POST request con manejo de errores
 */
async function postAPI(url, data, options = {}) {
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
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        return await response.json();
    } catch (error) {
        throw error;
    }
}

// ===== PLAN SEMANAL =====
/**
 * Carga el plan semanal para el dashboard con conteos de inspecciones
 */
async function cargarPlanSemanal() {
    const container = document.getElementById('plan-semanal-container');
    
    if (!container) {
        return;
    }
    
    
    try {
        const response = await fetch('/api/dashboard/plan-semanal');
        const data = await response.json();
        
        
        container.innerHTML = '';
        
        // Los datos están en data.establecimientos (no data.data)
        if (data.establecimientos && Array.isArray(data.establecimientos) && data.establecimientos.length > 0) {
            data.establecimientos.forEach((establecimiento, index) => {
                
                const div = document.createElement('div');
                div.className = 'flex justify-between items-center p-3 hover:bg-gray-50 dark:hover:bg-gray-700 rounded-lg border border-gray-200 dark:border-gray-600 mb-2 transition-colors duration-200';
                
                // Usar los campos correctos del backend
                const realizadas = parseInt(establecimiento.inspecciones_realizadas) || 0;
                const meta = parseInt(establecimiento.meta_semanal) || 3; // El backend usa meta_semanal
                const progreso = `${realizadas}/${meta}`;
                
                
                // Determinar color según progreso - mejorado para tema oscuro/claro
                let colorProgreso, colorBarra;
                if (realizadas === 0) {
                    colorProgreso = 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200';
                    colorBarra = 'bg-red-500';
                } else if (realizadas < meta) {
                    colorProgreso = 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200';
                    colorBarra = 'bg-yellow-500';
                } else {
                    colorProgreso = 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200';
                    colorBarra = 'bg-green-500';
                }
                
                div.innerHTML = `
                    <span class="text-sm font-medium text-slate-700 dark:text-slate-300 flex-1">
                        ${sanitizeText(establecimiento.nombre)}
                    </span>
                    <div class="flex items-center space-x-3">
                        <span class="text-xs ${colorProgreso} px-2 py-1 rounded-full font-medium border">
                            ${progreso}
                        </span>
                        <div class="w-20 bg-gray-200 dark:bg-gray-600 rounded-full h-2.5">
                            <div class="${colorBarra} h-2.5 rounded-full transition-all duration-300" 
                                 style="width: ${meta > 0 ? (realizadas / meta) * 100 : 0}%"></div>
                        </div>
                    </div>
                `;
                container.appendChild(div);
            });
        } else {
            container.innerHTML = '<p class="text-sm text-gray-500">No hay establecimientos registrados</p>';
        }
    } catch (error) {
        container.innerHTML = '<p class="text-sm text-red-500">Error cargando plan semanal</p>';
    }
}

// ===== INICIALIZACIÓN =====
/**
 * Inicializa funciones comunes cuando el DOM esté listo
 */
document.addEventListener('DOMContentLoaded', function() {
    // Solo ejecutar en páginas que no sean login
    if (window.location.pathname === '/login') {
        return;
    }
    
    
    // Inicializar evidencias si existe el elemento
    inicializarEvidencias();
    
    // Cargar plan semanal si existe el contenedor
    if (document.getElementById('plan-semanal-container')) {
        cargarPlanSemanal();
    }
});

// ===== EXPORTAR FUNCIONES GLOBALES =====
// Solo exportar si no existen versiones más específicas
window.AppCore = {
    cerrarSesion: cerrarSesionBasico,
    handleFileSelect,
    eliminarFirma,
    eliminarEvidencia,
    fetchAPI,
    postAPI,
    cargarPlanSemanal
};

// Asegurar que las funciones globales estén disponibles
// pero no sobrescribir si ya existen versiones más específicas
if (!window.cerrarSesion) {
    window.cerrarSesion = cerrarSesionBasico;
}

if (!window.handleFileSelect) {
    window.handleFileSelect = handleFileSelect;
}

if (!window.eliminarFirma) {
    window.eliminarFirma = eliminarFirma;
}

if (!window.eliminarEvidencia) {
    window.eliminarEvidencia = eliminarEvidencia;
}
