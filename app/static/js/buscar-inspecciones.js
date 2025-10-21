/**
 * Buscar Inspecciones System - Castillo de Chancay
 * Sistema de búsqueda avanzada de inspecciones con filtros
 */

// ===== VARIABLES GLOBALES =====
let inspecciones = [];

// ===== ELEMENTOS DEL DOM =====
let filtroEstablecimiento, filtroEncargado, filtroFechaDesde, filtroFechaHasta, filtroEstado;
let btnBuscar, btnLimpiar, btnNuevaInspeccion;
let listaInspecciones, contadorResultados, loadingResultados, sinResultados, vistaTabla, tbodyResultados;
let modalVistaPrevia, cerrarModal, contenidoModal;

// ===== INICIALIZACIÓN =====
document.addEventListener('DOMContentLoaded', function() {
    
    // Verificar dependencias
    if (typeof sanitizeText === 'undefined') {
        console.error('Error: sanitizeText function not found');
        return;
    }
    
    // Verificar que sanitizeText funcione correctamente
    const testSanitize = sanitizeText('test');
    if (typeof testSanitize !== 'string') {
        console.error('Error: sanitizeText does not return a string');
        return;
    }
    
    inicializarBuscarInspecciones();
});

// ===== FUNCIÓN PRINCIPAL DE INICIALIZACIÓN =====
function inicializarBuscarInspecciones() {
    try {
        // 1. Obtener elementos del DOM
        obtenerElementosDOM();
        
        // 2. Configurar eventos
        configurarEventos();
        
        // 3. Cargar datos iniciales
        cargarDatosIniciales();
        
    } catch (error) {
    }
}

// ===== OBTENER ELEMENTOS DEL DOM =====
function obtenerElementosDOM() {
    // Filtros
    filtroEstablecimiento = document.getElementById('filtro-establecimiento');
    filtroEncargado = document.getElementById('filtro-encargado');
    filtroFechaDesde = document.getElementById('filtro-fecha-desde');
    filtroFechaHasta = document.getElementById('filtro-fecha-hasta');
    filtroEstado = document.getElementById('filtro-estado');
    
    // Botones
    btnBuscar = document.getElementById('btn-buscar');
    btnLimpiar = document.getElementById('btn-limpiar');
    btnNuevaInspeccion = document.getElementById('btn-nueva-inspeccion');
    
    // Resultados
    listaInspecciones = document.getElementById('lista-inspecciones');
    contadorResultados = document.getElementById('contador-resultados');
    loadingResultados = document.getElementById('loading-resultados');
    sinResultados = document.getElementById('sin-resultados');
    vistaTabla = document.getElementById('vista-tabla');
    tbodyResultados = document.getElementById('tbody-resultados');
    
    // Modal
    modalVistaPrevia = document.getElementById('modal-vista-previa');
    cerrarModal = document.getElementById('cerrar-modal');
    contenidoModal = document.getElementById('contenido-modal');
    
    // Verificar elementos críticos
    if (!filtroEstablecimiento || !listaInspecciones) {
        throw new Error('Elementos críticos del DOM no encontrados');
    }
}

// ===== CONFIGURACIÓN DE EVENTOS =====
function configurarEventos() {
    // Botones principales
    if (btnBuscar) btnBuscar.addEventListener('click', buscarInspecciones);
    if (btnLimpiar) btnLimpiar.addEventListener('click', limpiarFiltros);
    if (btnNuevaInspeccion) btnNuevaInspeccion.addEventListener('click', () => window.location.href = '/');
    if (cerrarModal) cerrarModal.addEventListener('click', cerrarModalPrevia);
    
    // Event listener para cambio de establecimiento - manejar habilitación de encargados
    if (filtroEstablecimiento) {
        filtroEstablecimiento.addEventListener('change', function() {
            const establecimientoId = this.value;
            
            if (establecimientoId && establecimientoId !== '') {
                // Establecimiento seleccionado: habilitar select de encargados y cargar lista
                if (filtroEncargado) {
                    filtroEncargado.disabled = false;
                    filtroEncargado.className = 'w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-white dark:bg-slate-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent';
                    cargarEncargados(establecimientoId);
                }
            } else {
                // No hay establecimiento: deshabilitar select de encargados
                if (filtroEncargado) {
                    filtroEncargado.disabled = true;
                    filtroEncargado.className = 'w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-gray-100 dark:bg-slate-600 text-slate-500 dark:text-slate-400 cursor-not-allowed';
                    filtroEncargado.innerHTML = '<option value="">Seleccione un establecimiento primero</option>';
                    filtroEncargado.value = '';
                }
            }
        });
    }
}

// ===== CARGA DE DATOS INICIALES =====
async function cargarDatosIniciales() {
    // Cargar solo establecimientos al inicio - NO cargar encargados hasta seleccionar establecimiento
    await cargarEstablecimientos();
    
    // Buscar automáticamente al cargar
    await buscarInspecciones();
}

// ===== CARGA DE ESTABLECIMIENTOS =====
async function cargarEstablecimientos() {
    if (!filtroEstablecimiento) return;
    
    try {
        // Usar función consolidada de common.js
        const exito = await EstablecimientosAPI.poblarSelect(filtroEstablecimiento, 'Todos los establecimientos');
        if (exito) {
        } else {
        }
    } catch (error) {
        
        // Fallback manual
        filtroEstablecimiento.innerHTML = '<option value="">Error cargando establecimientos</option>';
    }
}

// ===== CARGA DE ENCARGADOS =====
async function cargarEncargados(establecimientoId) {
    if (!filtroEncargado) return;
    
    try {
        // VALIDACIÓN: Solo cargar si se proporciona un establecimientoId válido
        if (!establecimientoId || establecimientoId === '') {
            return;
        }
        
        // Mostrar indicador de carga
        filtroEncargado.innerHTML = '<option value="">Cargando encargados...</option>';
        
        // Construir URL con parámetro de establecimiento (OBLIGATORIO)
        const url = `/api/usuarios/encargados?establecimiento_id=${establecimientoId}`;
        
        const response = await fetch(url);
        if (response.ok) {
            const encargados = await response.json();
            
            // Configurar opciones según si hay encargados o no
            if (encargados.length > 0) {
                filtroEncargado.innerHTML = '<option value="">Todos los encargados de este establecimiento</option>';
                encargados.forEach(enc => {
                    const option = document.createElement('option');
                    option.value = enc.id;
                    
                    // SEGURIDAD: Sanitizar el nombre antes de mostrarlo
                    const nombreSanitizado = sanitizeText(enc.nombre || '');
                    const estadoTexto = enc.activo === false ? ' (Inactivo)' : '';
                    
                    // Usar textContent en lugar de innerHTML para seguridad adicional
                    option.textContent = nombreSanitizado + estadoTexto;
                    
                    // Deshabilitar visualmente encargados inactivos pero mantenerlos en la lista
                    if (!enc.activo) {
                        option.style.color = '#6b7280';
                        option.style.fontStyle = 'italic';
                    }
                    filtroEncargado.appendChild(option);
                });
            } else {
                // No hay encargados para este establecimiento
                filtroEncargado.innerHTML = '<option value="">No hay encargados asignados a este establecimiento</option>';
            }
            
            // Log para debugging sin mostrar datos sensibles
        } else {
            throw new Error(`Error HTTP: ${response.status}`);
        }
    } catch (error) {
        // En caso de error, mostrar mensaje apropiado de manera segura
        const errorOption = document.createElement('option');
        errorOption.value = '';
        errorOption.textContent = 'Error cargando encargados del establecimiento';
        filtroEncargado.innerHTML = '';
        filtroEncargado.appendChild(errorOption);
    }
}

// ===== BÚSQUEDA DE INSPECCIONES =====
async function buscarInspecciones() {
    mostrarLoading(true);

    try {
        const params = new URLSearchParams();

        if (filtroEstablecimiento && filtroEstablecimiento.value) params.append('establecimiento_id', filtroEstablecimiento.value);
        if (filtroEncargado && filtroEncargado.value) params.append('encargado_id', filtroEncargado.value);
        if (filtroFechaDesde && filtroFechaDesde.value) params.append('fecha_desde', filtroFechaDesde.value);
        if (filtroFechaHasta && filtroFechaHasta.value) params.append('fecha_hasta', filtroFechaHasta.value);
        if (filtroEstado && filtroEstado.value) params.append('estado', filtroEstado.value);

        const response = await fetch(`/api/inspecciones/buscar?${params.toString()}`);
        if (response.ok) {
            inspecciones = await response.json();
            mostrarResultados();
        } else {
            throw new Error('Error en la búsqueda');
        }
    } catch (error) {
        mostrarError('Error al buscar inspecciones');
    } finally {
        mostrarLoading(false);
    }
}

// ===== VISUALIZACIÓN DE RESULTADOS =====
function mostrarResultados() {
    if (!listaInspecciones || !contadorResultados) return;
    
    if (inspecciones.length === 0) {
        if (sinResultados) sinResultados.classList.remove('hidden');
        listaInspecciones.innerHTML = '';
        contadorResultados.textContent = '0 inspecciones encontradas';
        if (tbodyResultados) tbodyResultados.innerHTML = '';
        return;
    }
    
    if (sinResultados) sinResultados.classList.add('hidden');
    contadorResultados.textContent = `${inspecciones.length} inspección${inspecciones.length !== 1 ? 'es' : ''} encontrada${inspecciones.length !== 1 ? 's' : ''}`;
    
    // Generar HTML asegurándose de que sea un string válido
    const html = inspecciones.map(inspeccion => {
        const cardHtml = crearCardInspeccion(inspeccion);
        // Verificar que sea un string
        if (typeof cardHtml !== 'string') {
            console.error('Error: crearCardInspeccion no devolvió un string', cardHtml);
            return '';
        }
        return cardHtml;
    }).join('');
    
    // Verificar que el HTML final sea un string
    if (typeof html !== 'string') {
        console.error('Error: HTML generado no es un string', html);
        listaInspecciones.innerHTML = '<p>Error al cargar los resultados</p>';
        return;
    }
    
    listaInspecciones.innerHTML = html;
    
    if (tbodyResultados) {
        const filasHtml = inspecciones.map(inspeccion => crearFilaTabla(inspeccion)).join('');
        tbodyResultados.innerHTML = filasHtml;

        document.querySelectorAll('#tbody-resultados tr[data-inspeccion-id]').forEach(fila => {
            fila.addEventListener('click', (event) => {
                // Evitar que el click en el botón dispare doble navegación
                if (event.target.closest('button')) {
                    return;
                }
                verDetalleInspeccion(fila.dataset.inspeccionId);
            });
        });

        document.querySelectorAll('#tbody-resultados button[data-inspeccion-id]').forEach(boton => {
            boton.addEventListener('click', (event) => {
                event.stopPropagation();
                verDetalleInspeccion(boton.dataset.inspeccionId);
            });
        });
    }

    // Agregar event listeners a las cards
    document.querySelectorAll('#lista-inspecciones [data-inspeccion-id]').forEach(card => {
        card.addEventListener('click', () => verDetalleInspeccion(card.dataset.inspeccionId));
    });
}

// ===== CREACIÓN DE TARJETAS DE INSPECCIÓN =====
function crearCardInspeccion(inspeccion) {
    const fecha = formatearFechaLocal(inspeccion.fecha);
    const estadoClass = `estado-${inspeccion.estado.toLowerCase().replace(' ', '-')}`;

    // SEGURIDAD: Sanitizar todos los datos antes de mostrarlos
    const establecimientoNombre = sanitizeText(inspeccion.establecimiento_nombre || '');
    const inspectorNombre = sanitizeText(inspeccion.inspector_nombre || 'N/A');
    const estado = sanitizeText(inspeccion.estado || '');
    const observaciones = sanitizeText(inspeccion.observaciones || '');

    // Sanitizar valores numéricos (convertir a número y validar)
    const puntajeTotal = parseInt(inspeccion.puntaje_total) || 0;
    const puntajeMaximo = parseInt(inspeccion.puntaje_maximo) || 0;
    const porcentajeCumplimiento = parseInt(inspeccion.porcentaje_cumplimiento) || 0;
    const itemsEvaluados = parseInt(inspeccion.items_evaluados) || 0;
    const inspeccionId = parseInt(inspeccion.id) || 0;

    // Construir HTML de manera explícita para evitar problemas de template literals
    let html = '<div class="inspeccion-card bg-slate-50 dark:bg-slate-700 border border-slate-200 dark:border-slate-600 rounded-lg p-4 cursor-pointer hover:shadow-md hover:border-blue-300 transition-all duration-200 mb-4" data-inspeccion-id="' + inspeccionId + '">';
    html += '<div class="flex justify-between items-start mb-3">';
    html += '<div>';
    html += '<h4 class="font-semibold text-slate-900 dark:text-white">' + establecimientoNombre + '</h4>';
    html += '<p class="text-sm text-slate-600 dark:text-slate-400">' + fecha + '</p>';
    html += '<p class="text-xs text-blue-600 dark:text-blue-400 mt-1">Click para ver detalles completos</p>';
    html += '</div>';
    html += '<span class="estado-badge ' + estadoClass + '">' + estado + '</span>';
    html += '</div>';

    html += '<div class="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">';
    html += '<div>';
    html += '<span class="font-medium text-slate-700 dark:text-slate-300">Inspector:</span>';
    html += '<p class="text-slate-600 dark:text-slate-400">' + inspectorNombre + '</p>';
    html += '</div>';
    html += '<div>';
    html += '<span class="font-medium text-slate-700 dark:text-slate-300">Puntaje:</span>';
    html += '<p class="text-slate-600 dark:text-slate-400">' + puntajeTotal + '/' + puntajeMaximo + '</p>';
    html += '</div>';
    html += '<div>';
    html += '<span class="font-medium text-slate-700 dark:text-slate-300">Cumplimiento:</span>';
    html += '<p class="text-slate-600 dark:text-slate-400">' + porcentajeCumplimiento + '%</p>';
    html += '</div>';
    html += '<div>';
    html += '<span class="font-medium text-slate-700 dark:text-slate-300">Items:</span>';
    html += '<p class="text-slate-600 dark:text-slate-400">' + itemsEvaluados + ' evaluados</p>';
    html += '</div>';
    html += '</div>';

    if (observaciones) {
        html += '<div class="mt-3 pt-3 border-t border-slate-200 dark:border-slate-600">';
        html += '<span class="font-medium text-slate-700 dark:text-slate-300">Observaciones:</span>';
        html += '<p class="text-sm text-slate-600 dark:text-slate-400 line-clamp-2">' + observaciones + '</p>';
        html += '</div>';
    }

    html += '</div>';

    return html;
}

function crearFilaTabla(inspeccion) {
    const fecha = formatearFechaLocal(inspeccion.fecha);
    const establecimientoNombre = sanitizeText(inspeccion.establecimiento_nombre || '');
    const encargadoNombre = sanitizeText(inspeccion.encargado_nombre || 'N/A');
    const estadoTexto = sanitizeText(inspeccion.estado || '');
    const porcentajeCumplimiento = parseInt(inspeccion.porcentaje_cumplimiento) || 0;
    const inspeccionId = parseInt(inspeccion.id) || 0;

    const estadoSlug = estadoTexto
        ? estadoTexto
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/(^-|-$)/g, '')
        : 'sin-estado';

    return `
        <tr class="hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer transition-colors" data-inspeccion-id="${inspeccionId}">
            <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">#${inspeccionId}</td>
            <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">${fecha}</td>
            <td class="px-4 sm:px-6 py-4 text-sm text-gray-900 dark:text-gray-100">${establecimientoNombre}</td>
            <td class="px-4 sm:px-6 py-4 text-sm text-gray-600 dark:text-gray-300">${encargadoNombre}</td>
            <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm">
                <span class="estado-badge estado-${estadoSlug}">${estadoTexto || 'N/A'}</span>
            </td>
            <td class="px-4 sm:px-6 py-4 whitespace-nowrap text-sm text-gray-600 dark:text-gray-300">${porcentajeCumplimiento}%</td>
            <td class="px-4 sm:px-6 py-4 whitespace-nowrap">
                <button type="button" data-inspeccion-id="${inspeccionId}" class="inline-flex items-center px-3 py-1.5 text-xs font-medium rounded-lg bg-blue-600 text-white hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500">
                    <i class="fas fa-eye mr-1"></i> Ver detalle
                </button>
            </td>
        </tr>
    `;
}

// ===== DETALLE DE INSPECCIÓN =====
async function verDetalleInspeccion(inspeccionId) {
    // Redirigir a la vista de detalle completa
    window.location.href = `/inspecciones/${inspeccionId}/detalle`;
}

// ===== MODAL DE VISTA PREVIA =====
function mostrarModalDetalle(detalle) {
    if (!contenidoModal || !modalVistaPrevia) return;
    
    // SEGURIDAD: Sanitizar todos los datos antes de mostrarlos
    const establecimientoNombre = sanitizeText(detalle.establecimiento_nombre || '');
    const observaciones = sanitizeText(detalle.observaciones || '');
    const fecha = formatearFechaLocal(detalle.fecha);
    
    // Sanitizar valores numéricos
    const puntajeTotal = parseInt(detalle.puntaje_total) || 0;
    const porcentajeCumplimiento = parseInt(detalle.porcentaje_cumplimiento) || 0;
    const itemsEvaluados = parseInt(detalle.items_evaluados) || 0;
    const detalleId = parseInt(detalle.id) || 0;
    
    // Implementación más segura del contenido del modal
    contenidoModal.innerHTML = `
        <div class="space-y-6">
            <div class="grid grid-cols-2 gap-4">
                <div>
                    <h4 class="font-semibold text-slate-900 dark:text-white">Establecimiento</h4>
                    <p class="text-slate-600 dark:text-slate-400">${establecimientoNombre}</p>
                </div>
                <div>
                    <h4 class="font-semibold text-slate-900 dark:text-white">Fecha</h4>
                    <p class="text-slate-600 dark:text-slate-400">${fecha}</p>
                </div>
            </div>
            
            <div class="grid grid-cols-3 gap-4 p-4 bg-slate-50 dark:bg-slate-700 rounded-lg">
                <div class="text-center">
                    <div class="text-2xl font-bold text-blue-600">${puntajeTotal}</div>
                    <div class="text-sm text-slate-600 dark:text-slate-400">Puntaje Total</div>
                </div>
                <div class="text-center">
                    <div class="text-2xl font-bold text-green-600">${porcentajeCumplimiento}%</div>
                    <div class="text-sm text-slate-600 dark:text-slate-400">Cumplimiento</div>
                </div>
                <div class="text-center">
                    <div class="text-2xl font-bold text-purple-600">${itemsEvaluados}</div>
                    <div class="text-sm text-slate-600 dark:text-slate-400">Items Evaluados</div>
                </div>
            </div>
            
            ${observaciones ? `
                <div>
                    <h4 class="font-semibold text-slate-900 dark:text-white mb-2">Observaciones</h4>
                    <p class="text-slate-600 dark:text-slate-400 bg-slate-50 dark:bg-slate-700 p-3 rounded-lg">${observaciones}</p>
                </div>
            ` : ''}
            
            <div class="flex justify-end space-x-3">
                <button onclick="window.location.href='/inspecciones/${detalleId}/detalle'" class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors duration-200">
                    Ver Detalle Completo
                </button>
            </div>
        </div>
    `;
    
    modalVistaPrevia.classList.remove('hidden');
}

function cerrarModalPrevia() {
    if (modalVistaPrevia) {
        modalVistaPrevia.classList.add('hidden');
    }
}

// ===== LIMPIAR FILTROS =====
function limpiarFiltros() {
    if (filtroEstablecimiento) filtroEstablecimiento.value = '';
    if (filtroEncargado) filtroEncargado.value = '';
    if (filtroFechaDesde) filtroFechaDesde.value = '';
    if (filtroFechaHasta) filtroFechaHasta.value = '';
    if (filtroEstado) filtroEstado.value = '';
    
    // IMPORTANTE: Deshabilitar select de encargados cuando se limpian filtros
    if (filtroEncargado) {
        filtroEncargado.disabled = true;
        filtroEncargado.className = 'w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg bg-gray-100 dark:bg-slate-600 text-slate-500 dark:text-slate-400 cursor-not-allowed';
        filtroEncargado.innerHTML = '<option value="">Seleccione un establecimiento primero</option>';
    }
    
    buscarInspecciones();
}

// ===== UTILIDADES =====
function mostrarLoading(mostrar) {
    if (!loadingResultados || !sinResultados) return;
    
    if (mostrar) {
        loadingResultados.classList.remove('hidden');
        sinResultados.classList.add('hidden');
    } else {
        loadingResultados.classList.add('hidden');
    }
}

function mostrarError(mensaje) {
    // TODO: Implementar notificación visual de error
}

function formatearFechaLocal(fechaValor) {
    if (!fechaValor) return 'N/A';

    try {
        const fechaObjeto = new Date(fechaValor);
        if (!isNaN(fechaObjeto.getTime())) {
            return new Intl.DateTimeFormat('es-PE', {
                year: 'numeric',
                month: '2-digit',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit',
                hour12: true
            }).format(fechaObjeto);
        }
    } catch (error) {
    }

    return 'N/A';
}

// ===== FUNCIONES GLOBALES =====
window.editarInspeccion = function(inspeccionId) {
    window.location.href = `/?editar=${inspeccionId}`;
};

// ===== UTILIDADES GLOBALES =====
window.BuscarInspecciones = {
    verDetalleInspeccion,
    mostrarModalDetalle,
    cerrarModalPrevia,
    limpiarFiltros,
    buscarInspecciones
};
