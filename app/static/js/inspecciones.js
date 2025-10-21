/**
 * Inspecciones History System - Castillo de Chancay
 * Sistema de historial y búsqueda de inspecciones
 */

// ===== VARIABLES GLOBALES =====
let inspecciones = [];
let userRole = '';

// ===== INICIALIZACIÓN =====
document.addEventListener('DOMContentLoaded', function() {
    
    // Verificar dependencias
    if (typeof AppCommon === 'undefined') {
        return;
    }
    
    inicializarInspecciones();
});

// ===== FUNCIÓN PRINCIPAL DE INICIALIZACIÓN =====
async function inicializarInspecciones() {
    try {
        // 1. Obtener rol del usuario desde template
        obtenerRolUsuario();
        
        // 2. Cargar establecimientos en filtro
        await cargarEstablecimientosFiltro();
        
        // 3. Cargar todas las inspecciones inicialmente
        await buscarInspecciones();
        
        // 4. Configurar eventos
        configurarEventos();
        
    } catch (error) {
    }
}

// ===== CONFIGURACIÓN DE EVENTOS =====
function configurarEventos() {
    // Formulario de filtros
    const formFiltros = document.getElementById('filtros-form');
    if (formFiltros) {
        formFiltros.addEventListener('submit', function(e) {
            e.preventDefault();
            buscarInspecciones();
        });
    }
    
    // Botón limpiar filtros
    const btnLimpiar = document.getElementById('limpiar-filtros');
    if (btnLimpiar) {
        btnLimpiar.addEventListener('click', limpiarFiltros);
    }
}

// ===== GESTIÓN DE USUARIO =====
function obtenerRolUsuario() {
    // Intentar obtener rol desde elemento template
    const roleElement = document.querySelector('[data-user-role]');
    if (roleElement) {
        userRole = roleElement.dataset.userRole;
    } else {
        // Fallback: intentar desde variable global si existe
        if (typeof window.USER_ROLE !== 'undefined') {
            userRole = window.USER_ROLE;
        }
    }
}

// ===== CARGA DE ESTABLECIMIENTOS =====
async function cargarEstablecimientosFiltro() {
    const select = document.getElementById('filtro-establecimiento');
    if (!select) {
        return;
    }
    
    try {
        const success = await AppCommon.EstablecimientosAPI.poblarSelect(select, 'Todos los establecimientos');
        if (success) {
        }
    } catch (error) {
    }
}

// ===== BÚSQUEDA DE INSPECCIONES =====
async function buscarInspecciones() {
    const formData = new FormData(document.getElementById('filtros-form'));
    const params = new URLSearchParams();
    
    // Construir parámetros de búsqueda
    for (let [key, value] of formData.entries()) {
        if (value) {
            params.append(key, value);
        }
    }
    
    // Mostrar loading
    AppCommon.UI.mostrarLoading('loading');
    const contenedorResultados = document.getElementById('resultados-container');
    if (contenedorResultados && !contenedorResultados.dataset.locked) {
        contenedorResultados.dataset.locked = '1';
    }
    document.getElementById('sin-resultados').classList.add('hidden');
    
    try {
        const response = await fetch(`/api/inspecciones?${params.toString()}`);
        const data = await response.json();
        
        if (response.ok) {
            inspecciones = data;
            mostrarResultados(data);
        } else {
            throw new Error(data.error || 'Error al buscar inspecciones');
        }
    } catch (error) {
        AppCommon.UI.mostrarNotificacion(
            'Error al buscar inspecciones: ' + error.message,
            'error'
        );
    } finally {
        AppCommon.UI.ocultarLoading('loading');
    }
}

// ===== VISUALIZACIÓN DE RESULTADOS =====
function mostrarResultados(inspecciones) {
    const container = document.getElementById('resultados-container');
    const totalElement = document.getElementById('total-resultados');
    const sinResultados = document.getElementById('sin-resultados');

    if (!container || !totalElement) {
        return;
    }

    totalElement.textContent = inspecciones.length;

    if (sinResultados) {
        if (inspecciones.length === 0) {
            sinResultados.classList.remove('hidden');
        } else {
            sinResultados.classList.add('hidden');
        }
    }

    delete container.dataset.locked;

    if (inspecciones.length === 0) {
        while (container.firstChild) {
            container.removeChild(container.firstChild);
        }
        return;
    }

    const fragment = document.createDocumentFragment();
    const existingItems = new Map();

    Array.from(container.children).forEach(item => {
        const inspeccionId = Number(item.dataset ? item.dataset.id : NaN);
        if (Number.isFinite(inspeccionId)) {
            existingItems.set(inspeccionId, item);
        }
    });

    inspecciones.forEach(inspeccion => {
        const inspeccionId = inspeccion.id;
        const estadoClass = obtenerClaseEstado(inspeccion.estado);
        const nuevoHTML = crearHTMLInspeccion(inspeccion, estadoClass);

        if (existingItems.has(inspeccionId)) {
            const existingItem = existingItems.get(inspeccionId);
            if (existingItem.innerHTML !== nuevoHTML) {
                existingItem.innerHTML = nuevoHTML;
            }
            existingItems.delete(inspeccionId);
        } else {
            const div = document.createElement('div');
            div.className = 'p-6 hover:bg-gray-50 transition-colors';
            div.dataset.id = inspeccionId;
            div.innerHTML = nuevoHTML;
            fragment.appendChild(div);
        }
    });

    existingItems.forEach(item => {
        container.removeChild(item);
    });

    container.appendChild(fragment);
}

// ===== UTILIDADES DE VISUALIZACIÓN =====
function obtenerClaseEstado(estado) {
    const clases = {
        borrador: 'bg-yellow-100 text-yellow-800',
        en_proceso: 'bg-blue-100 text-blue-800',
        completada: 'bg-green-100 text-green-800'
    };
    return clases[estado] || 'bg-gray-100 text-gray-800';
}

function crearHTMLInspeccion(inspeccion, estadoClass) {
    return `
        <div class="flex justify-between items-start mb-3">
            <div>
                <h3 class="font-semibold text-lg">${inspeccion.establecimiento}</h3>
                <p class="text-sm text-gray-600">ID: ${inspeccion.id}</p>
            </div>
            <span class="px-3 py-1 rounded-full text-sm font-medium ${estadoClass}">
                ${inspeccion.estado_label || inspeccion.estado}
            </span>
        </div>
        
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 text-sm">
            <div>
                <span class="font-medium text-gray-700">Fecha:</span>
                <span>${new Date(inspeccion.fecha).toLocaleDateString('es-ES')}</span>
            </div>
            <div>
                <span class="font-medium text-gray-700">Inspector:</span>
                <span>${inspeccion.inspector || 'N/A'}</span>
            </div>
            <div>
                <span class="font-medium text-gray-700">Puntaje:</span>
                <span>${inspeccion.puntaje_total || 0} / ${inspeccion.puntaje_maximo || 0}</span>
            </div>
            <div>
                <span class="font-medium text-gray-700">Cumplimiento:</span>
                <span class="font-semibold ${obtenerColorCumplimiento(inspeccion.porcentaje_cumplimiento)}">
                    ${inspeccion.porcentaje_cumplimiento || 0}%
                </span>
            </div>
        </div>
        
        ${inspeccion.observaciones ? `
            <div class="mt-3">
                <span class="font-medium text-gray-700">Observaciones:</span>
                <p class="text-sm text-gray-600 mt-1">${inspeccion.observaciones}</p>
            </div>
        ` : ''}
        
        <div class="flex justify-end gap-2 mt-4">
            <button onclick="InspeccionesHistory.verDetalle(${inspeccion.id})" 
                    class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm">
                Ver Detalle
            </button>
            ${inspeccion.estado === 'borrador' ? `
                <button onclick="InspeccionesHistory.editarInspeccion(${inspeccion.id})" 
                        class="px-4 py-2 bg-yellow-600 text-white rounded-lg hover:bg-yellow-700 transition-colors text-sm">
                    Continuar Editando
                </button>
            ` : ''}
        </div>
    `;
}

function obtenerColorCumplimiento(porcentaje) {
    if (porcentaje >= 80) return 'text-green-600';
    if (porcentaje >= 60) return 'text-yellow-600';
    return 'text-red-600';
}

// ===== ACCIONES DE INSPECCIÓN =====
function verDetalle(inspeccionId) {
    const url = `/inspecciones/${inspeccionId}/detalle`;
    window.open(url, '_blank');
}

function editarInspeccion(inspeccionId) {
    const url = `/?editar=${inspeccionId}`;
    window.location.href = url;
}

// ===== GESTIÓN DE FILTROS =====
function limpiarFiltros() {
    const form = document.getElementById('filtros-form');
    if (form) {
        form.reset();
        document.getElementById('resultados-container').innerHTML = '';
        document.getElementById('sin-resultados').classList.add('hidden');
        document.getElementById('total-resultados').textContent = '0';
    }
}

// ===== SESIÓN =====
async function cerrarSesion() {
    const confirmar = await AppCommon.UI.mostrarConfirmacion(
        '¿Estás seguro de que deseas cerrar sesión?'
    );
    
    if (confirmar) {
        try {
            const response = await fetch('/api/auth/logout', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
            });
            
            window.location.href = '/login';
        } catch (error) {
            // Redirigir al login aunque haya error
            window.location.href = '/login';
        }
    }
}

// ===== UTILIDADES GLOBALES =====
window.InspeccionesHistory = {
    verDetalle,
    editarInspeccion,
    limpiarFiltros,
    cerrarSesion,
    buscarInspecciones
};
