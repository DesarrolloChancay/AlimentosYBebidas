// LIMPIAR INTERVALOS EXISTENTES AL CARGAR
// Deshabilitar cualquier intervalo de verificación de sesión que pueda estar ejecutándose
(function() {
    // Limpiar todos los intervalos que puedan estar ejecutándose
    const maxIntervalId = window.setInterval(function(){}, 0);
    for (let i = 1; i <= maxIntervalId; i++) {
        window.clearInterval(i);
    }
    // *console.log('Intervalos de sesión limpiados');
})();

// Estado global de la inspección
window.inspeccionEstado = {
    establecimiento_id: null,
    items: {},
    evidencias: [],
    firma_inspector: null,
    firma_encargado: null,
    observaciones: '',
    resumen: {
        puntaje_total: 0,
        puntaje_maximo_posible: 0,  // Cambiado de puntaje_maximo a puntaje_maximo_posible
        porcentaje_cumplimiento: 0,
        puntos_criticos_perdidos: 0
    }
};

// Variables globales
let socket = null;
let inspeccionActualId = null;
let userRole = null;
let autoSaveInterval = null;

// Control de cambios para optimización de emisiones en tiempo real
let hayCambiosPendientes = false;
let ultimoEstadoEmitido = null;

// Configuración de autosave cada 30 segundos
const AUTOSAVE_INTERVAL = 30000; // 30 segundos

// Función para marcar que hay cambios pendientes
function marcarCambiosPendientes() {
    hayCambiosPendientes = true;
}

// Función para verificar si el estado actual es diferente al último emitido
function hayDiferenciasEnEstado() {
    if (!ultimoEstadoEmitido) return true;
    
    const estadoActual = {
        items: window.inspeccionEstado.items,
        observaciones: window.inspeccionEstado.observaciones,
        resumen: window.inspeccionEstado.resumen
    };
    
    return JSON.stringify(estadoActual) !== JSON.stringify(ultimoEstadoEmitido);
}

// =======================
// FUNCIONES DE DIÁLOGO REUTILIZABLES
// =======================

function mostrarDialogoConfirmacion(titulo, mensaje, textoBtnConfirmar = 'Confirmar', textoBtnCancelar = 'Cancelar') {
    return new Promise((resolve) => {
        const dialog = document.getElementById('dialog-confirmar');
        const overlay = dialog.querySelector('.fixed.inset-0');
        const panel = dialog.querySelector('[role="dialog"]');
        const tituloEl = dialog.querySelector('#dialog-title');
        const mensajeEl = dialog.querySelector('#dialog-mensaje');
        const btnConfirmar = dialog.querySelector('#btn-confirmar-modal');
        const btnCancelar = dialog.querySelector('#btn-cancelar-modal');
        
        // Configurar contenido
        tituloEl.textContent = titulo;
        mensajeEl.textContent = mensaje;
        btnConfirmar.textContent = textoBtnConfirmar;
        btnCancelar.textContent = textoBtnCancelar;
        
        // Mostrar diálogo
        dialog.showModal();
        dialog.classList.remove('hidden');
        
        // Manejar respuesta
        const manejarRespuesta = (confirmado) => {
            dialog.close();
            dialog.classList.add('hidden');
            btnConfirmar.onclick = null;
            btnCancelar.onclick = null;
            resolve(confirmado);
        };
        
        btnConfirmar.onclick = () => manejarRespuesta(true);
        btnCancelar.onclick = () => manejarRespuesta(false);
        
        // Cerrar con Escape
        dialog.onkeydown = (e) => {
            if (e.key === 'Escape') {
                manejarRespuesta(false);
            }
        };
    });
}

function mostrarDialogoInfo(titulo, mensaje, textoBtnOk = 'Entendido') {
    return new Promise((resolve) => {
        const dialog = document.getElementById('dialog-confirmar');
        const tituloEl = dialog.querySelector('#dialog-title');
        const mensajeEl = dialog.querySelector('#dialog-mensaje');
        const btnConfirmar = dialog.querySelector('#btn-confirmar-modal');
        const btnCancelar = dialog.querySelector('#btn-cancelar-modal');
        
        // Configurar contenido
        tituloEl.textContent = titulo;
        mensajeEl.textContent = mensaje;
        btnConfirmar.textContent = textoBtnOk;
        
        // Ocultar botón cancelar
        btnCancelar.style.display = 'none';
        
        // Mostrar diálogo
        dialog.showModal();
        dialog.classList.remove('hidden');
        
        // Manejar respuesta
        const manejarRespuesta = () => {
            dialog.close();
            dialog.classList.add('hidden');
            btnCancelar.style.display = 'inline-flex'; // Restaurar para futuros usos
            btnConfirmar.onclick = null;
            resolve();
        };
        
        btnConfirmar.onclick = manejarRespuesta;
        
        // Cerrar con Escape
        dialog.onkeydown = (e) => {
            if (e.key === 'Escape') {
                manejarRespuesta();
            }
        };
    });
}

// =======================
// FUNCIONES PRINCIPALES
// =======================

function inicializarSocketIO() {
    socket = io();
    
    socket.on('connected', function(data) {
        // *console.log('Conectado a Socket.IO:', data.mensaje);
    });
    
    socket.on('usuario_unido', function(data) {
        mostrarNotificacion(`${data.usuario} se unió a la inspección`, 'info');
    });
    
    socket.on('usuario_salio', function(data) {
        mostrarNotificacion(`${data.usuario} salió de la inspección`, 'info');
    });
    
    // Evento específico para tiempo real sin inspección activa
    socket.on('item_rating_tiempo_real', function(data) {
        actualizarItemEnTiempoReal(data);
    });
    
    // Nuevo evento para tiempo real completo en establecimiento
    socket.on('inspeccion_tiempo_real', function(data) {
        // *console.log('Datos tiempo real recibidos:', data);
        if (userRole === 'Encargado' && data.establecimiento_id) {
            actualizarDatosTiempoRealCompletos(data);
        }
    });
    
    socket.on('item_actualizado', function(data) {
        // Solo mostrar al encargado cuando el inspector actualiza
        if (userRole === 'Encargado' && data.actualizado_por === 'Inspector') {
            actualizarItemEnTiempoReal(data);
        }
    });
    
    socket.on('observaciones_actualizadas', function(data) {
        // Solo mostrar al encargado cuando el inspector actualiza
        if (userRole === 'Encargado' && data.actualizado_por === 'Inspector') {
            actualizarObservacionesEnTiempoReal(data);
        }
    });
    
    socket.on('estado_inspeccion_cambiado', function(data) {
        actualizarEstadoInspeccionEnTiempoReal(data);
    });
    
    socket.on('solicitud_firma', function(data) {
        if (userRole === 'Encargado') {
            mostrarSolicitudFirma(data);
        }
    });
    
    socket.on('firma_recibida', function(data) {
        mostrarNotificacion(`Firma de ${data.tipo_firma} recibida de ${data.firmado_por}`, 'success');
    });
}

function unirseAInspeccion(inspeccionId) {
    if (socket && inspeccionId) {
        inspeccionActualId = inspeccionId;
        socket.emit('join_inspeccion', {
            inspeccion_id: inspeccionId,
            usuario_id: window.userId || 1,
            role: userRole
        });
        // *console.log(`Unido a inspección ${inspeccionId}`);
    }
}

function salirDeInspeccion() {
    if (socket && inspeccionActualId) {
        socket.emit('leave_inspeccion', {
            inspeccion_id: inspeccionActualId,
            usuario_id: window.userId || 1
        });
        inspeccionActualId = null;
    }
}

function actualizarItemEnTiempoReal(data) {
    // Solo procesar si es para el encargado y viene del inspector
    if (userRole !== 'Encargado' || data.actualizado_por !== 'Inspector') {
        return;
    }
    
    // Actualizar el DOM con los datos recibidos - para que el encargado vea en tiempo real
    const itemElement = document.querySelector(`input[data-item-id="${data.item_id}"][value="${data.rating}"]`);
    if (itemElement) {
        itemElement.checked = true;
        // Si es encargado, asegurar que esté deshabilitado
        const allRadios = document.querySelectorAll(`input[data-item-id="${data.item_id}"]`);
        allRadios.forEach(radio => {
            radio.disabled = true;
        });
    }
    
    // Actualizar estado local
    if (!window.inspeccionEstado.items[data.item_id]) {
        window.inspeccionEstado.items[data.item_id] = {};
    }
    window.inspeccionEstado.items[data.item_id] = {
        ...window.inspeccionEstado.items[data.item_id],
        rating: data.rating,
        puntaje_maximo: data.puntaje_maximo || window.inspeccionEstado.items[data.item_id].puntaje_maximo,
        riesgo: data.riesgo || window.inspeccionEstado.items[data.item_id].riesgo
    };
    
    // Actualizar resumen
    actualizarResumen();
    
    mostrarNotificacion(`Item calificado: ${data.rating} puntos`, 'info');
}

function actualizarDatosTiempoRealCompletos(data) {
    // Función para encargados que recibe todos los datos en tiempo real
    if (userRole !== 'Encargado') return;
    
    // *console.log('Encargado - Datos recibidos en tiempo real:', data);
    // *console.log('Encargado - Resumen recibido:', data.resumen);
    
    // Actualizar items individualmente
    if (data.items) {
        Object.keys(data.items).forEach(itemId => {
            const itemData = data.items[itemId];
            if (itemData.rating !== null && itemData.rating !== undefined) {
                // Actualizar radio buttons
                const itemElement = document.querySelector(`input[data-item-id="${itemId}"][value="${itemData.rating}"]`);
                if (itemElement) {
                    // Limpiar selecciones previas del item
                    const allRadios = document.querySelectorAll(`input[data-item-id="${itemId}"]`);
                    allRadios.forEach(radio => {
                        radio.checked = false;
                        radio.disabled = true; // Solo lectura para encargado
                    });
                    
                    // Marcar el nuevo rating
                    itemElement.checked = true;
                    
                    // Agregar clase visual para resaltar el cambio
                    itemElement.parentElement.classList.add('bg-blue-100', 'border-blue-300', 'animate-pulse');
                    setTimeout(() => {
                        itemElement.parentElement.classList.remove('animate-pulse');
                    }, 1000);
                }
                
                // Actualizar estado local
                if (!window.inspeccionEstado.items[itemId]) {
                    window.inspeccionEstado.items[itemId] = {};
                }
                window.inspeccionEstado.items[itemId] = {
                    ...window.inspeccionEstado.items[itemId],
                    rating: itemData.rating,
                    observacion: itemData.observacion || ''
                };
            }
        });
    }
    
    // Actualizar observaciones si hay cambios
    if (data.observaciones !== undefined) {
        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea && observacionesTextarea.value !== data.observaciones) {
            observacionesTextarea.value = data.observaciones;
            observacionesTextarea.disabled = true; // Solo lectura para encargado
            // Resaltar cambio
            observacionesTextarea.classList.add('bg-blue-50', 'border-blue-300');
            setTimeout(() => {
                observacionesTextarea.classList.remove('bg-blue-50', 'border-blue-300');
            }, 2000);
        }
    }
    
    // Actualizar resumen en tiempo real con los datos recibidos
    if (data.resumen && Object.keys(data.resumen).length > 0) {
        // *console.log('Encargado: Usando resumen del backend:', data.resumen);
        actualizarResumenConPuntajes(data.resumen);
    } else {
        console.warn('Encargado: No se recibió resumen del backend. Los datos pueden estar incompletos.');
        // NO calcular resumen local para encargados - esto causaba el problema
        // actualizarResumen();
    }
    
    // Mostrar notificación discreta
    mostrarNotificacion(`Inspector actualizó calificaciones`, 'info');
}

function actualizarObservacionesEnTiempoReal(data) {
    const observacionesTextarea = document.getElementById('observaciones-generales');
    if (observacionesTextarea) {
        observacionesTextarea.value = data.observaciones;
        // Si es encargado, solo puede ver, no editar
        if (userRole === 'Encargado') {
            observacionesTextarea.disabled = true;
        }
    }
    
    mostrarNotificacion(`Observaciones actualizadas`, 'info');
}

function actualizarEstadoInspeccionEnTiempoReal(data) {
    mostrarNotificacion(`Inspección ${data.estado}`, 'success');
    
    if (data.estado === 'completada' && data.puntajes) {
        // Actualizar resumen con puntajes finales
        actualizarResumenConPuntajes(data.puntajes);
        
        // Si es encargado, mostrar opción de firma
        if (userRole === 'Encargado') {
            mostrarOpcionFirma();
        }
    }
}

function mostrarSolicitudFirma(data) {
    mostrarNotificacion(`Se solicita su firma para aprobar la inspección`, 'warning');
    mostrarOpcionFirma();
}

function mostrarOpcionFirma() {
    // Mostrar el área de firma del encargado si está oculta
    const firmaArea = document.getElementById('firma-encargado-area');
    if (firmaArea) {
        firmaArea.style.display = 'block';
        firmaArea.scrollIntoView({ behavior: 'smooth' });
    }
}

function mostrarNotificacion(mensaje, tipo = 'info') {
    // Crear elemento de notificación
    const notificacion = document.createElement('div');
    notificacion.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 transition-all duration-300 ${
        tipo === 'success' ? 'bg-green-500 text-white' :
        tipo === 'error' ? 'bg-red-500 text-white' :
        tipo === 'warning' ? 'bg-yellow-500 text-black' :
        'bg-blue-500 text-white'
    }`;
    notificacion.textContent = mensaje;
    
    document.body.appendChild(notificacion);
    
    // Remover después de 4 segundos
    setTimeout(() => {
        notificacion.style.transform = 'translateX(100%)';
        setTimeout(() => {
            if (notificacion.parentNode) {
                notificacion.parentNode.removeChild(notificacion);
            }
        }, 300);
    }, 4000);
}

// Función para manejar la vista previa de evidencias
function handleEvidenciasSelect(event) {
    const files = event.target.files;
    const previewContainer = document.getElementById('evidencias-preview');
    if (!previewContainer) return;

    // Agregar archivos al estado existente en lugar de reemplazarlo
    Array.from(files).forEach((file, index) => {
        if (file.type.startsWith('image/')) {
            const totalIndex = window.inspeccionEstado.evidencias.length;
            window.inspeccionEstado.evidencias.push(file);
            
            const reader = new FileReader();
            reader.onload = function(e) {
                const container = document.createElement('div');
                container.className = 'relative group';
                container.dataset.evidenciaIndex = totalIndex;
                
                const img = document.createElement('img');
                img.src = e.target.result;
                img.className = 'w-full h-32 object-cover rounded-lg cursor-pointer hover:opacity-75 transition-opacity';
                img.onclick = () => abrirVistaPrevia(e.target.result);
                
                const deleteBtn = document.createElement('button');
                deleteBtn.innerHTML = `
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                `;
                deleteBtn.className = 'absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 text-sm flex items-center justify-center hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity';
                deleteBtn.onclick = (e) => {
                    e.stopPropagation();
                    eliminarEvidencia(totalIndex);
                };
                
                const overlay = document.createElement('div');
                overlay.className = 'absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all duration-200 rounded-lg flex items-center justify-center';
                overlay.innerHTML = `
                    <svg class="w-8 h-8 text-white opacity-0 group-hover:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                `;
                
                container.appendChild(img);
                container.appendChild(deleteBtn);
                container.appendChild(overlay);
                previewContainer.appendChild(container);
            };
            reader.readAsDataURL(file);
        }
    });

    // Limpiar el input para permitir seleccionar más archivos
    event.target.value = '';
    guardarEstadoTemporal();
}

function eliminarEvidencia(index) {
    window.inspeccionEstado.evidencias.splice(index, 1);
    
    // Recrear el preview
    const previewContainer = document.getElementById('evidencias-preview');
    if (previewContainer) {
        previewContainer.innerHTML = '';
        
        // Recrear todas las previsualizaciones
        window.inspeccionEstado.evidencias.forEach((file, newIndex) => {
            const reader = new FileReader();
            reader.onload = function(e) {
                const container = document.createElement('div');
                container.className = 'relative group';
                container.dataset.evidenciaIndex = newIndex;
                
                const img = document.createElement('img');
                img.src = e.target.result;
                img.className = 'w-full h-32 object-cover rounded-lg cursor-pointer hover:opacity-75 transition-opacity';
                img.onclick = () => abrirVistaPrevia(e.target.result);
                
                const deleteBtn = document.createElement('button');
                deleteBtn.innerHTML = `
                    <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                `;
                deleteBtn.className = 'absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 text-sm flex items-center justify-center hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity';
                deleteBtn.onclick = (e) => {
                    e.stopPropagation();
                    eliminarEvidencia(newIndex);
                };
                
                const overlay = document.createElement('div');
                overlay.className = 'absolute inset-0 bg-black bg-opacity-0 group-hover:bg-opacity-10 transition-all duration-200 rounded-lg flex items-center justify-center';
                overlay.innerHTML = `
                    <svg class="w-8 h-8 text-white opacity-0 group-hover:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                    </svg>
                `;
                
                container.appendChild(img);
                container.appendChild(deleteBtn);
                container.appendChild(overlay);
                previewContainer.appendChild(container);
            };
            reader.readAsDataURL(file);
        });
    }
    
    guardarEstadoTemporal();
}

function abrirVistaPrevia(src, filename = 'Evidencia') {
    // Crear modal para vista previa mejorada
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 p-4';
    modal.onclick = (e) => {
        if (e.target === modal) {
            document.body.removeChild(modal);
        }
    };
    
    const container = document.createElement('div');
    container.className = 'relative max-w-4xl max-h-full bg-white rounded-lg overflow-hidden shadow-2xl';
    container.onclick = (e) => e.stopPropagation();
    
    // Header del modal
    const header = document.createElement('div');
    header.className = 'flex items-center justify-between p-4 bg-gray-50 border-b';
    header.innerHTML = `
        <h3 class="text-lg font-semibold text-gray-900">${filename}</h3>
        <button class="text-gray-400 hover:text-gray-600 transition-colors" onclick="document.body.removeChild(document.querySelector('.fixed.inset-0'))">
            <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
            </svg>
        </button>
    `;
    
    // Imagen
    const img = document.createElement('img');
    img.src = src;
    img.className = 'max-w-full max-h-96 mx-auto block';
    img.style.maxHeight = 'calc(100vh - 200px)';
    
    // Footer con acciones
    const footer = document.createElement('div');
    footer.className = 'flex items-center justify-end p-4 bg-gray-50 border-t space-x-3';
    footer.innerHTML = `
        <button onclick="window.open('${src}', '_blank')" class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"/>
            </svg>
            <span>Abrir en nueva pestaña</span>
        </button>
        <button onclick="document.body.removeChild(document.querySelector('.fixed.inset-0'))" class="px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors">
            Cerrar
        </button>
    `;
    
    container.appendChild(header);
    container.appendChild(img);
    container.appendChild(footer);
    modal.appendChild(container);
    document.body.appendChild(modal);
    
    // Cerrar con tecla Escape
    const handleEscape = (e) => {
        if (e.key === 'Escape') {
            document.body.removeChild(modal);
            document.removeEventListener('keydown', handleEscape);
        }
    };
    document.addEventListener('keydown', handleEscape);
}

// Funciones de manejo de firmas
function handleFileSelect(event, tipo) {
    const file = event.target.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
        mostrarNotificacion('Por favor seleccione una imagen válida', 'error');
        return;
    }

    const reader = new FileReader();
    reader.onload = function(e) {
        window.inspeccionEstado[`firma_${tipo}`] = e.target.result;
        
        // Mostrar preview con imagen
        const preview = document.getElementById(`preview-firma-${tipo}`);
        if (preview) {
            preview.innerHTML = `
                <div class="relative">
                    <img src="${e.target.result}" class="max-w-full h-20 object-contain border rounded cursor-pointer" onclick="abrirVistaPrevia('${e.target.result}')">
                    <div class="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-10 transition-all duration-200 rounded flex items-center justify-center">
                        <svg class="w-6 h-6 text-gray-600 opacity-0 hover:opacity-100 transition-opacity" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"/>
                        </svg>
                    </div>
                </div>
                <p class="text-xs text-gray-500 mt-1">Haga clic en la imagen para ampliar</p>
            `;
        }
        
        guardarEstadoTemporal();
    };
    reader.readAsDataURL(file);
}

function eliminarFirma(tipo) {
    window.inspeccionEstado[`firma_${tipo}`] = null;
    
    // Limpiar input y preview
    const input = document.getElementById(`firma-${tipo}`);
    const preview = document.getElementById(`preview-firma-${tipo}`);
    
    if (input) input.value = '';
    if (preview) preview.innerHTML = '';
    
    guardarEstadoTemporal();
}

// Función para actualizar el resumen basado en el total de TODOS los items
function actualizarResumen() {
    // Los encargados NO deben calcular su propio resumen
    // Solo deben usar los datos que vienen del backend via socket
    if (userRole === 'Encargado') {
        // *console.log('Encargado: No calcular resumen localmente, esperar datos del backend');
        return;
    }
    
    let puntajeTotal = 0;
    let puntajeMaximoTotal = 0;
    let puntosCriticos = 0;
    let itemsCalificados = 0;
    let totalItems = 0;
    
    // Obtener todos los items disponibles desde el DOM (incluye los no calificados)
    const todosLosRadios = document.querySelectorAll('input[data-item-id]');
    const itemsUnicos = new Set();
    
    todosLosRadios.forEach(radio => {
        const itemId = radio.getAttribute('data-item-id');
        const puntajeMaximo = parseFloat(radio.getAttribute('data-puntaje-maximo')) || 0;
        const riesgo = radio.getAttribute('data-riesgo') || '';
        
        if (itemId && !itemsUnicos.has(itemId)) {
            itemsUnicos.add(itemId);
            totalItems++;
            
            // Sumar al puntaje máximo total siempre
            puntajeMaximoTotal += puntajeMaximo;
            
            // Solo sumar al puntaje obtenido si está calificado
            const itemData = window.inspeccionEstado.items[itemId];
            if (itemData && itemData.rating !== null && itemData.rating !== undefined) {
                const rating = parseFloat(itemData.rating);
                puntajeTotal += rating;
                itemsCalificados++;
                
                // Contar puntos críticos perdidos
                if (riesgo === 'Crítico' && rating < puntajeMaximo) {
                    puntosCriticos += (puntajeMaximo - rating);
                }
            }
        }
    });
    
    // Calcular porcentaje basado en el total de items disponibles
    const porcentaje = puntajeMaximoTotal > 0 ? (puntajeTotal / puntajeMaximoTotal * 100) : 0;
    
    window.inspeccionEstado.resumen = {
        puntaje_total: puntajeTotal,
        puntaje_maximo_posible: puntajeMaximoTotal,  // Cambiado de puntaje_maximo a puntaje_maximo_posible
        porcentaje_cumplimiento: porcentaje,
        puntos_criticos_perdidos: puntosCriticos,
        items_calificados: itemsCalificados,
        total_items: totalItems
    };
    
    // Actualizar UI con formato mejorado
    const puntajeActual = document.getElementById('puntaje-actual');
    const puntajeMaximoEl = document.getElementById('puntaje-maximo');
    const porcentajeEl = document.getElementById('porcentaje-cumplimiento');
    const criticosEl = document.getElementById('puntos-criticos');
    const progresoEl = document.getElementById('progreso-items');
    
    if (puntajeActual) puntajeActual.textContent = puntajeTotal.toFixed(1);
    if (puntajeMaximoEl) puntajeMaximoEl.textContent = puntajeMaximoTotal.toFixed(1);
    if (porcentajeEl) {
        porcentajeEl.textContent = porcentaje.toFixed(1) + '%';
        // Actualizar color según porcentaje
        if (porcentaje >= 90) {
            porcentajeEl.className = 'text-green-600 font-bold';
        } else if (porcentaje >= 70) {
            porcentajeEl.className = 'text-yellow-600 font-bold';
        } else {
            porcentajeEl.className = 'text-red-600 font-bold';
        }
    }
    if (criticosEl) criticosEl.textContent = puntosCriticos.toFixed(1);
    if (progresoEl) progresoEl.textContent = `${itemsCalificados}/${totalItems} items`;
    
    // Actualizar barra de progreso si existe
    const barraProgreso = document.getElementById('barra-progreso');
    if (barraProgreso) {
        const progresoItems = totalItems > 0 ? (itemsCalificados / totalItems * 100) : 0;
        barraProgreso.style.width = progresoItems + '%';
        
        if (progresoItems === 100) {
            barraProgreso.className = 'h-2 bg-green-500 rounded transition-all duration-300';
        } else if (progresoItems >= 50) {
            barraProgreso.className = 'h-2 bg-blue-500 rounded transition-all duration-300';
        } else {
            barraProgreso.className = 'h-2 bg-gray-400 rounded transition-all duration-300';
        }
    }
}

function actualizarResumenConPuntajes(puntajes) {
    window.inspeccionEstado.resumen = puntajes;
    
    // Validar que puntajes existe y tiene las propiedades necesarias
    if (!puntajes) {
        console.warn('Puntajes no definidos');
        return;
    }
    
    // *console.log('Actualizando resumen con puntajes:', puntajes);
    
    // Actualizar UI con los puntajes finales
    const puntajeActual = document.getElementById('puntaje-actual');
    const puntajeMaximoEl = document.getElementById('puntaje-maximo');
    const porcentajeEl = document.getElementById('porcentaje-cumplimiento');
    const criticosEl = document.getElementById('puntos-criticos');
    const progresoEl = document.getElementById('progreso-items');
    
    if (puntajeActual && puntajes.puntaje_total !== undefined && puntajes.puntaje_total !== null) {
        puntajeActual.textContent = Number(puntajes.puntaje_total).toFixed(1);
    }
    
    // Usar puntaje_maximo_posible del backend
    if (puntajeMaximoEl && puntajes.puntaje_maximo_posible !== undefined && puntajes.puntaje_maximo_posible !== null) {
        puntajeMaximoEl.textContent = Number(puntajes.puntaje_maximo_posible).toFixed(1);
    }
    
    if (porcentajeEl && puntajes.porcentaje_cumplimiento !== undefined && puntajes.porcentaje_cumplimiento !== null) {
        const porcentaje = Number(puntajes.porcentaje_cumplimiento);
        porcentajeEl.textContent = porcentaje.toFixed(1) + '%';
        
        // Actualizar color según porcentaje
        if (porcentaje >= 90) {
            porcentajeEl.className = 'text-green-600 font-bold';
        } else if (porcentaje >= 70) {
            porcentajeEl.className = 'text-yellow-600 font-bold';
        } else {
            porcentajeEl.className = 'text-red-600 font-bold';
        }
    }
    
    if (criticosEl && puntajes.puntos_criticos_perdidos !== undefined && puntajes.puntos_criticos_perdidos !== null) {
        criticosEl.textContent = Number(puntajes.puntos_criticos_perdidos).toFixed(1);
    }
    
    // Actualizar progreso de items evaluados
    if (progresoEl && puntajes.items_calificados !== undefined && puntajes.total_items !== undefined) {
        progresoEl.textContent = `${puntajes.items_calificados}/${puntajes.total_items} items`;
    }
    
    // Actualizar barra de progreso - ESTO ES CLAVE PARA EL ENCARGADO
    const barraProgreso = document.getElementById('barra-progreso');
    if (barraProgreso) {
        let progresoItems = 0;
        
        // Calcular progreso basado en items evaluados
        if (puntajes.items_calificados !== undefined && puntajes.total_items !== undefined && puntajes.total_items > 0) {
            progresoItems = (puntajes.items_calificados / puntajes.total_items) * 100;
        }
        
        // *console.log('Actualizando barra de progreso:', progresoItems + '%', 'items_calificados:', puntajes.items_calificados, 'total_items:', puntajes.total_items);
        barraProgreso.style.width = progresoItems + '%';
        
        // Actualizar color de la barra según progreso
        if (progresoItems === 100) {
            barraProgreso.className = 'h-2 bg-green-500 rounded transition-all duration-300';
        } else if (progresoItems >= 50) {
            barraProgreso.className = 'h-2 bg-blue-500 rounded transition-all duration-300';
        } else {
            barraProgreso.className = 'h-2 bg-gray-400 rounded transition-all duration-300';
        }
    } else {
        console.warn('Elemento barra-progreso no encontrado');
    }
}

async function cargarEstablecimientos() {
    try {
        const response = await fetch('/api/establecimientos');
        const establecimientos = await response.json();
        
        const select = document.getElementById('establecimiento');
        if (select) {
            select.innerHTML = '<option value="">Seleccione un establecimiento</option>';
            establecimientos.forEach(est => {
                const option = document.createElement('option');
                option.value = est.id;
                option.textContent = est.nombre;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error cargando establecimientos:', error);
        mostrarNotificacion('Error al cargar establecimientos', 'error');
    }
}

async function cargarItemsEstablecimiento(establecimientoId) {
    try {
        // Solo cargar items cuando se selecciona un establecimiento
        if (!establecimientoId) {
            document.getElementById('categorias-container').innerHTML = '<p class="text-gray-500">Seleccione un establecimiento para ver los items de evaluación</p>';
            return;
        }
        
        const response = await fetch(`/api/establecimientos/${establecimientoId}/items`);
        const data = await response.json();
        
        if (!response.ok) {
            throw new Error(data.error || 'Error al cargar items');
        }
        
        const container = document.getElementById('categorias-container');
        if (container) {
            container.innerHTML = '';
            
            if (data.categorias && data.categorias.length > 0) {
                data.categorias.forEach(categoria => {
                    const categoriaDiv = crearCategoriaHTML(categoria);
                    container.appendChild(categoriaDiv);
                });
                
                // Configurar eventos para actualización en tiempo real
                configurarEventosItems();
            } else {
                container.innerHTML = '<p class="text-gray-500">No hay items configurados para este establecimiento</p>';
            }
        }
        
        // Guardar el establecimiento seleccionado
        window.inspeccionEstado.establecimiento_id = establecimientoId;
        
        // Marcar cambios pendientes para enviar estado inicial
        marcarCambiosPendientes();
        
        // Forzar emisión inicial cuando se selecciona un establecimiento
        guardarEstadoTemporal(true);
        
    } catch (error) {
        console.error('Error cargando items:', error);
        mostrarNotificacion(error.message || 'Error al cargar items', 'error');
    }
}

// Función para verificar sesión única con mejor manejo
async function verificarSesionUnica() {
    try {
        const response = await fetch('/api/auth/verificar-sesion-unica', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                timestamp: Date.now()
            })
        });
        
        if (!response.ok) {
            const data = await response.json();
            if (data.error === 'sesion_duplicada') {
                // Mostrar diálogo de sesión duplicada con mejores estilos
                mostrarDialogoSesionDuplicada();
                return;
            }
        }
    } catch (error) {
        console.error('Error verificando sesión única:', error);
    }
}

// Función para mostrar diálogo de sesión duplicada
function mostrarDialogoSesionDuplicada() {
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50';
    modal.innerHTML = `
        <div class="bg-white rounded-lg p-8 max-w-md mx-4 shadow-2xl">
            <div class="flex items-center mb-6">
                <div class="flex-shrink-0 w-12 h-12 bg-red-100 rounded-full flex items-center justify-center mr-4">
                    <svg class="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z"/>
                    </svg>
                </div>
                <div>
                    <h3 class="text-lg font-bold text-gray-900">Sesión Duplicada</h3>
                    <p class="text-sm text-gray-600">El usuario ya está en línea</p>
                </div>
            </div>
            <div class="mb-6">
                <p class="text-gray-700 leading-relaxed">
                    Su sesión ha sido cerrada porque se detectó que el mismo usuario está activo en otro dispositivo o navegador. 
                    Solo se permite una sesión activa por usuario.
                </p>
            </div>
            <div class="flex justify-center">
                <button id="aceptar-cierre-sesion" class="bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 transition-colors font-semibold">
                    Entendido
                </button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    // Manejar clic en el botón
    document.getElementById('aceptar-cierre-sesion').onclick = () => {
        window.location.href = '/api/auth/logout';
    };
    
    // Evitar que se cierre haciendo clic fuera
    modal.onclick = (e) => {
        if (e.target === modal) {
            e.preventDefault();
            e.stopPropagation();
        }
    };
    
    // Bloquear tecla Escape
    const handleEscape = (e) => {
        if (e.key === 'Escape') {
            e.preventDefault();
        }
    };
    document.addEventListener('keydown', handleEscape);
}

// Función para cargar establecimiento del encargado automáticamente
async function cargarEstablecimientoEncargado() {
    try {
        const response = await fetch('/api/establecimientos');
        const establecimientos = await response.json();
        
        if (establecimientos && establecimientos.length > 0) {
            // Seleccionar automáticamente el primer establecimiento del encargado
            const select = document.getElementById('establecimiento');
            if (select && establecimientos[0]) {
                select.value = establecimientos[0].id;
                await cargarItemsEstablecimiento(establecimientos[0].id);
                
                // Unirse automáticamente para tiempo real
                if (socket) {
                    socket.emit('join_establecimiento', {
                        establecimiento_id: establecimientos[0].id,
                        usuario_id: window.userId || 1,
                        role: userRole
                    });
                    
                    // Solicitar datos actuales del establecimiento para tiempo real
                    cargarDatosTiempoRealEstablecimiento(establecimientos[0].id);
                }
            }
        }
    } catch (error) {
        console.error('Error cargando establecimiento del encargado:', error);
    }
}

async function cargarDatosTiempoRealEstablecimiento(establecimientoId) {
    // Cargar datos actuales de tiempo real para un establecimiento (para encargados)
    if (userRole !== 'Encargado') return;
    
    try {
        const response = await fetch(`/api/inspecciones/tiempo-real/establecimiento/${establecimientoId}`);
        if (response.ok) {
            const data = await response.json();
            if (data && Object.keys(data).length > 0) {
                // *console.log('Datos tiempo real cargados:', data);
                actualizarDatosTiempoRealCompletos(data);
                mostrarNotificacion('Datos en tiempo real cargados', 'success');
            } else {
                // *console.log('No hay datos de tiempo real disponibles para este establecimiento');
            }
        }
    } catch (error) {
        console.error('Error cargando datos tiempo real:', error);
    }
}

function crearCategoriaHTML(categoria) {
    const div = document.createElement('div');
    div.className = 'mb-8 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden';
    
    let itemsHTML = '';
    categoria.items.forEach(item => {
        // Definir colores según el riesgo
        const riesgoClasses = {
            'Crítico': 'bg-red-50 dark:bg-red-950 border-red-200 dark:border-red-800',
            'Mayor': 'bg-yellow-50 dark:bg-yellow-950 border-yellow-200 dark:border-yellow-800',
            'Menor': 'bg-blue-50 dark:bg-blue-950 border-blue-200 dark:border-blue-800'
        };
        
        const riesgoBadge = {
            'Crítico': 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200',
            'Mayor': 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200',
            'Menor': 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200'
        };
        
        itemsHTML += `
            <tr class="border-b border-slate-100 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-750 transition-colors ${riesgoClasses[item.riesgo] || ''}">
                <td class="py-4 px-6">
                    <div class="flex flex-col space-y-2">
                        <div class="flex items-center space-x-3">
                            <span class="font-mono text-sm font-semibold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-700 px-2 py-1 rounded">${item.codigo}</span>
                            <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${riesgoBadge[item.riesgo] || ''}">${item.riesgo}</span>
                        </div>
                        <p class="text-sm text-slate-900 dark:text-slate-100 leading-relaxed">${item.descripcion}</p>
                        <div class="text-xs text-slate-500 dark:text-slate-400">
                            Puntaje máximo: <span class="font-semibold">${item.puntaje_maximo}</span> puntos
                        </div>
                    </div>
                </td>
                <td class="py-4 px-6 text-center min-w-[300px]">
                    <div class="flex justify-center space-x-3">
                        ${Array.from({length: item.puntaje_maximo + 1}, (_, i) => `
                            <label class="flex flex-col items-center cursor-pointer group ${userRole === 'Encargado' ? 'opacity-75' : ''}">
                                <input type="radio" name="item_${item.id}" value="${i}" 
                                       class="radio-item w-5 h-5 text-blue-600 bg-gray-100 border-2 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 checked:bg-blue-600 checked:border-blue-600 checked:ring-2 checked:ring-blue-200 transition-all duration-200 hover:border-blue-400" 
                                       data-item-id="${item.id}" 
                                       data-puntaje-maximo="${item.puntaje_maximo}" 
                                       data-riesgo="${item.riesgo}"
                                       ${userRole === 'Encargado' ? 'disabled' : ''}>
                                <span class="text-sm mt-2 font-bold text-slate-700 dark:text-slate-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors ${userRole === 'Encargado' ? 'text-slate-500' : ''}">${i}</span>
                                ${i === 0 ? `<span class="text-xs text-red-600 font-semibold mt-1 ${userRole === 'Encargado' ? 'text-red-400' : ''}">No cumple</span>` : ''}
                                ${i === item.puntaje_maximo ? `<span class="text-xs text-green-600 font-semibold mt-1 ${userRole === 'Encargado' ? 'text-green-400' : ''}">Completo</span>` : ''}
                            </label>
                        `).join('')}
                    </div>
                    ${userRole === 'Encargado' ? '<p class="text-xs text-slate-500 mt-2 italic">Vista en tiempo real</p>' : ''}
                </td>
            </tr>
        `;
    });
    
    div.innerHTML = `
        <div class="bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-700 px-6 py-4 border-b border-slate-200 dark:border-slate-600">
            <div class="flex items-center justify-between">
                <h3 class="text-xl font-bold text-slate-900 dark:text-white">${categoria.nombre}</h3>
                <span class="text-sm text-slate-500 dark:text-slate-400">${categoria.items.length} item(s)</span>
            </div>
            ${categoria.descripcion ? `<p class="text-sm text-slate-600 dark:text-slate-300 mt-1">${categoria.descripcion}</p>` : ''}
        </div>
        <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
                <thead class="bg-slate-50 dark:bg-slate-800">
                    <tr>
                        <th class="px-6 py-4 text-left text-sm font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider">
                            Item de Evaluación
                        </th>
                        <th class="px-6 py-4 text-center text-sm font-bold text-slate-900 dark:text-slate-100 uppercase tracking-wider">
                            Puntuación (0-${Math.max(...categoria.items.map(item => item.puntaje_maximo))})
                        </th>
                    </tr>
                </thead>
                <tbody class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700">
                    ${itemsHTML}
                </tbody>
            </table>
        </div>
    `;
    
    return div;
}

function configurarEventosItems() {
    // Event listeners para radios - optimizado para detectar cambios reales
    document.querySelectorAll('.radio-item').forEach(radio => {
        radio.addEventListener('change', function() {
            const itemId = this.getAttribute('data-item-id');
            const rating = parseInt(this.value);
            const riesgo = this.dataset.riesgo;
            const maxPuntaje = parseInt(this.dataset.puntajeMaximo);
            
            // Verificar si realmente cambió el valor
            const valorAnterior = window.inspeccionEstado.items[itemId]?.rating;
            if (valorAnterior === rating) {
                return; // No hay cambio real, no hacer nada
            }
            
            // Marcar que hay cambios pendientes
            marcarCambiosPendientes();
            
            // Actualizar estado local
            window.inspeccionEstado.items[itemId] = {
                rating: rating,
                puntaje_maximo: maxPuntaje,
                riesgo: riesgo,
                observacion: window.inspeccionEstado.items[itemId]?.observacion || ''
            };
            
            // Para inspectores - emitir actualización en tiempo real solo cuando hay cambios
            if (userRole === 'Inspector' && socket && window.inspeccionEstado.establecimiento_id) {
                // *console.log(`Cambio detectado en item ${itemId}: ${valorAnterior} -> ${rating}`);
                
                // Usar throttling más eficiente - solo guardar el estado al final
                clearTimeout(window.emitTimeout);
                window.emitTimeout = setTimeout(() => {
                    // Solo guardar si realmente hay cambios pendientes
                    if (hayCambiosPendientes) {
                        guardarEstadoTemporal(); // Esto emitirá el cambio automáticamente
                    }
                }, 500); // 500ms delay para agrupar cambios múltiples
            }
            
            actualizarResumen();
        });
    });
    
    // Agregar observador de mutación para detectar cambios dinámicos
    const observer = new MutationObserver(function(mutations) {
        mutations.forEach(function(mutation) {
            if (mutation.type === 'attributes' && mutation.attributeName === 'checked') {
                const radio = mutation.target;
                if (radio.classList.contains('radio-item') && radio.checked) {
                    // Un radio fue marcado programáticamente (tiempo real)
                    actualizarResumen();
                }
            }
        });
    });
    
    // Observar cambios en todos los radio buttons
    document.querySelectorAll('.radio-item').forEach(radio => {
        observer.observe(radio, { attributes: true, attributeFilter: ['checked'] });
    });
}

function restaurarEstado(estado) {
    if (!estado) return;
    
    // Restaurar establecimiento
    if (estado.establecimiento_id) {
        const select = document.getElementById('establecimiento');
        if (select) {
            select.value = estado.establecimiento_id;
            cargarItemsEstablecimiento(estado.establecimiento_id);
        }
    }
    
    // Restaurar observaciones
    if (estado.observaciones) {
        const textarea = document.getElementById('observaciones-generales');
        if (textarea) {
            textarea.value = estado.observaciones;
        }
    }
    
    // Restaurar estado global
    window.inspeccionEstado = { ...window.inspeccionEstado, ...estado };
}

async function guardarEstadoTemporal(forzarEmision = false) {
    try {
        // Solo proceder si hay cambios pendientes o se fuerza la emisión
        if (!hayCambiosPendientes && !forzarEmision) {
            // *console.log('No hay cambios pendientes - omitiendo guardado');
            return;
        }
        
        // Obtener observaciones actuales
        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea) {
            window.inspeccionEstado.observaciones = observacionesTextarea.value;
        }
        
        // Calcular resumen actualizado
        actualizarResumen();
        
        /* *console.log('Inspector - Estado calculado:', {
            items: Object.keys(window.inspeccionEstado.items).length,
            resumen: window.inspeccionEstado.resumen
        }); */
        
        // Guardar en servidor (cookie del formulario) SOLO si hay cambios
        if (hayCambiosPendientes || forzarEmision) {
            await fetch('/api/inspecciones/temporal', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(window.inspeccionEstado)
            });
        }
        
        // Emitir datos de tiempo real solo si es inspector, hay establecimiento seleccionado Y hay cambios pendientes
        if (userRole === 'Inspector' && window.inspeccionEstado.establecimiento_id && socket) {
            // Verificar si hay cambios reales comparado con el último estado emitido
            const hayChanges = hayCambiosPendientes || hayDiferenciasEnEstado() || forzarEmision;
            
            if (hayChanges) {
                const datosEmitir = {
                    establecimiento_id: window.inspeccionEstado.establecimiento_id,
                    items: window.inspeccionEstado.items,
                    observaciones: window.inspeccionEstado.observaciones,
                    resumen: window.inspeccionEstado.resumen,
                    actualizado_por: userRole,
                    timestamp: Date.now()
                };
                
                // *console.log('Inspector - Emitiendo datos en tiempo real (HAY CAMBIOS):', datosEmitir);
                
                socket.emit('item_rating_tiempo_real', datosEmitir);
                
                // También unirse al room del establecimiento si no lo está
                socket.emit('join_establecimiento', {
                    establecimiento_id: window.inspeccionEstado.establecimiento_id,
                    usuario_id: window.userId || 1,
                    role: userRole
                });
                
                // Guardar el estado actual como último emitido
                ultimoEstadoEmitido = {
                    items: JSON.parse(JSON.stringify(window.inspeccionEstado.items)),
                    observaciones: window.inspeccionEstado.observaciones,
                    resumen: JSON.parse(JSON.stringify(window.inspeccionEstado.resumen))
                };
                
                // Resetear flag de cambios pendientes
                hayCambiosPendientes = false;
                
                // *console.log('Estado guardado temporalmente y emitido en tiempo real');
            } else {
                // *console.log('No hay cambios - omitiendo emisión tiempo real');
            }
        }
    } catch (error) {
        console.error('Error guardando estado temporal:', error);
    }
}

async function recuperarEstadoTemporal() {
    try {
        const response = await fetch('/api/inspecciones/temporal');
        const estado = await response.json();
        
        if (estado && Object.keys(estado).length > 0) {
            restaurarEstado(estado);
            // *console.log('Estado temporal recuperado');
        }
    } catch (error) {
        console.error('Error recuperando estado temporal:', error);
    }
}

function iniciarAutosave() {
    // AUTOSAVE INTELIGENTE - Solo se guarda cuando hay cambios del usuario
    // *console.log('Autosave inteligente iniciado - Solo guardado cuando hay cambios');
    
    // Verificación cada 60 segundos para guardado de seguridad SOLO si hay cambios
    autoSaveInterval = setInterval(() => {
        if (hayCambiosPendientes && userRole === 'Inspector') {
            // *console.log('Guardado de seguridad - detectados cambios pendientes');
            guardarEstadoTemporal();
        }
    }, 60000); // 60 segundos para guardado de seguridad
}

function detenerAutosave() {
    if (autoSaveInterval) {
        clearInterval(autoSaveInterval);
        autoSaveInterval = null;
    }
}

// Variables para control de sesión
let sessionTimeoutWarning = null;
let sessionTimeout = null;
let sessionUniqueCheck = null; // Para verificación periódica de sesión única
let lastActivity = Date.now();
const SESSION_TIMEOUT = 10 * 60 * 1000; // 10 minutos
const WARNING_TIME = 2 * 60 * 1000; // 2 minutos antes de cerrar
const SESSION_CHECK_INTERVAL = 30 * 1000; // 30 segundos para verificar sesión única
let isConfirmDialogOpen = false;

// Función para resetear el timeout de sesión - DESHABILITADA
function resetSessionTimeout() {
    // Función deshabilitada - toda la gestión de sesión se hace desde el backend
    return;
}

// Función para mostrar advertencia de sesión
function mostrarAdvertenciaSesion() {
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50';
    modal.innerHTML = `
        <div class="bg-white rounded-lg p-6 max-w-md mx-4">
            <h3 class="text-lg font-semibold mb-4">Sesión por expirar</h3>
            <p class="text-gray-600 mb-6">Su sesión expirará en 2 minutos debido a inactividad. ¿Desea continuar?</p>
            <div class="flex justify-end gap-3">
                <button id="cerrar-sesion-btn" class="px-4 py-2 bg-gray-500 text-white rounded hover:bg-gray-600">Cerrar sesión</button>
                <button id="continuar-sesion-btn" class="px-4 py-2 bg-blue-500 text-white rounded hover:bg-blue-600">Continuar</button>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    
    document.getElementById('cerrar-sesion-btn').onclick = () => {
        window.location.href = '/api/auth/logout';
    };
    
    document.getElementById('continuar-sesion-btn').onclick = () => {
        document.body.removeChild(modal);
        resetSessionTimeout();
    };
}

// Función para cerrar sesión por inactividad
function cerrarSesionPorInactividad() {
    alert('Su sesión ha expirado por inactividad');
    window.location.href = '/api/auth/logout';
}

// Función para detectar actividad del usuario - DESHABILITADA
function detectarActividad() {
    // Función deshabilitada - toda la gestión de sesión se hace desde el backend
    return;
}

// Función para iniciar verificación periódica de sesión única - DESHABILITADA
function iniciarVerificacionSesionUnica() {
    // Función deshabilitada - toda la gestión de sesión se hace desde el backend
    return;
}

// Función para detener verificación de sesión única
function detenerVerificacionSesionUnica() {
    if (sessionUniqueCheck) {
        clearInterval(sessionUniqueCheck);
        sessionUniqueCheck = null;
    }
}

// Event listener principal
document.addEventListener('DOMContentLoaded', async function() {
    // NO ejecutar en página de login
    if (window.location.pathname === '/login') {
        return;
    }
    
    // Detectar rol del usuario desde el template
    userRole = document.body.dataset.userRole || window.userRole;
    
    // Ya no necesitamos verificación constante de sesión en JS
    // Todo se maneja desde el backend ahora
    // await verificarSesionUnica();
    // iniciarVerificacionSesionUnica(); // Verificación periódica cada 30 segundos
    // detectarActividad();
    // resetSessionTimeout();
    
    // Configurar interfaz según rol
    configurarInterfazPorRol();
    
    // Inicializar Socket.IO
    inicializarSocketIO();
    
    // Cargar establecimientos
    await cargarEstablecimientos();
    
    // Recuperar estado temporal
    await recuperarEstadoTemporal();
    
    // Iniciar autosave
    iniciarAutosave();
    
    // Para encargados, cargar establecimiento automáticamente
    if (userRole === 'Encargado') {
        await cargarEstablecimientoEncargado();
    }
    
    // Event listener para selección de establecimiento
    const establecimientoSelect = document.getElementById('establecimiento');
    if (establecimientoSelect) {
        establecimientoSelect.addEventListener('change', function() {
            const establecimientoId = this.value;
            if (establecimientoId) {
                cargarItemsEstablecimiento(establecimientoId);
            } else {
                // Limpiar items si no hay establecimiento seleccionado
                document.getElementById('categorias-container').innerHTML = '<p class="text-gray-500">Seleccione un establecimiento para ver los items de evaluación</p>';
                window.inspeccionEstado.items = {};
                actualizarResumen();
            }
        });
    }
    
    // Event listener para observaciones generales con throttling
    const observacionesTextarea = document.getElementById('observaciones-generales');
    if (observacionesTextarea) {
        let observacionesTimeout = null;
        
        observacionesTextarea.addEventListener('input', function() {
            // Marcar que hay cambios pendientes
            marcarCambiosPendientes();
            
            // Actualizar estado inmediatamente para UX
            window.inspeccionEstado.observaciones = this.value;
            
            // Throttling más eficiente - solo guardar y emitir si hay cambios reales
            clearTimeout(observacionesTimeout);
            observacionesTimeout = setTimeout(() => {
                if (userRole === 'Inspector' && hayCambiosPendientes) {
                    guardarEstadoTemporal(); // Esto emitirá el cambio automáticamente
                }
            }, 1000); // 1 segundo para observaciones (texto más largo)
        });
        
        // También mantener el evento blur como respaldo
        observacionesTextarea.addEventListener('blur', function() {
            // Marcar que hay cambios pendientes si el valor cambió realmente
            if (window.inspeccionEstado.observaciones !== this.value) {
                marcarCambiosPendientes();
                window.inspeccionEstado.observaciones = this.value;
                
                if (userRole === 'Inspector' && hayCambiosPendientes) {
                    guardarEstadoTemporal();
                }
            }
        });
    }
    
    // Event listener para evidencias
    const evidenciasInput = document.getElementById('evidencias-input');
    if (evidenciasInput) {
        evidenciasInput.addEventListener('change', handleEvidenciasSelect);
    }
    
    // Event listener para envío del formulario
    const form = document.getElementById('form-inspeccion');
    if (form) {
        form.addEventListener('submit', async function(e) {
            e.preventDefault();
            await guardarInspeccionFinal(e.submitter?.value === 'completar');
        });
    }
    
    // Event listener para salir de la página
    window.addEventListener('beforeunload', function() {
        salirDeInspeccion();
        detenerAutosave();
        detenerVerificacionSesionUnica();
    });
});

function configurarInterfazPorRol() {
    if (userRole === 'Encargado') {
        // Ocultar campos que el encargado no puede usar
        const camposOcultar = [
            '#evidencias-container',
            '#firma-inspector-area',
            'button[type="submit"]'
        ];
        
        camposOcultar.forEach(selector => {
            const elemento = document.querySelector(selector);
            if (elemento) {
                elemento.style.display = 'none';
            }
        });
        
        // Mostrar solo área de firma para encargado
        const firmaEncargadoArea = document.getElementById('firma-encargado-area');
        if (firmaEncargadoArea) {
            firmaEncargadoArea.style.display = 'block';
        }
        
        // Agregar botón de firma si no existe
        const firmaContainer = document.getElementById('firma-encargado-container');
        if (firmaContainer && !document.getElementById('btn-firmar-encargado')) {
            const btnFirmar = document.createElement('button');
            btnFirmar.id = 'btn-firmar-encargado';
            btnFirmar.className = 'bg-green-600 text-white px-6 py-2 rounded-lg hover:bg-green-700';
            btnFirmar.textContent = 'Firmar y Aprobar Inspección';
            btnFirmar.onclick = firmarComoEncargado;
            firmaContainer.appendChild(btnFirmar);
        }
    }
}

async function guardarInspeccionFinal(completar = false) {
    try {
        // Mostrar diálogo de confirmación
        const titulo = completar ? 'Completar Inspección' : 'Guardar Borrador';
        const mensaje = completar ? 
            '¿Está seguro que desea completar la inspección? Esta acción no se puede deshacer.' :
            '¿Está seguro que desea guardar el borrador de la inspección?';
            
        const confirmado = await mostrarDialogoConfirmacion(
            titulo, 
            mensaje, 
            completar ? 'Completar' : 'Guardar',
            'Cancelar'
        );
        
        if (!confirmado) {
            return; // Usuario canceló
        }
        
        const response = await fetch('/api/inspecciones', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                establecimiento_id: window.inspeccionEstado.establecimiento_id,
                fecha: document.getElementById('fecha').value,
                observaciones: window.inspeccionEstado.observaciones,
                items: window.inspeccionEstado.items,
                accion: completar ? 'completar' : 'guardar'
            })
        });
        
        const result = await response.json();
        
        if (response.ok) {
            mostrarNotificacion(result.mensaje, 'success');
            
            // Limpiar estado temporal - se borrará la cookie al guardar la inspección
            if (completar) {
                // Limpiar cookie temporal
                await fetch('/api/inspecciones/temporal', { 
                    method: 'DELETE',
                    headers: {
                        'Content-Type': 'application/json',
                    }
                });
                
                window.inspeccionEstado = {
                    establecimiento_id: null,
                    items: {},
                    evidencias: [],
                    firma_inspector: null,
                    firma_encargado: null,
                    observaciones: '',
                    resumen: { puntaje_total: 0, puntaje_maximo_posible: 0, porcentaje_cumplimiento: 0, puntos_criticos_perdidos: 0 }  // Cambiado de puntaje_maximo a puntaje_maximo_posible
                };
                
                detenerAutosave();
            }
            
            // Si se completó, unirse a la inspección para tiempo real
            if (completar && result.inspeccion_id) {
                unirseAInspeccion(result.inspeccion_id);
            }
            
        } else {
            throw new Error(result.error || 'Error al guardar inspección');
        }
        
    } catch (error) {
        console.error('Error guardando inspección:', error);
        mostrarNotificacion(error.message || 'Error al guardar inspección', 'error');
    }
}

// Función específica para firma del encargado
async function firmarComoEncargado() {
    if (userRole !== 'Encargado') {
        mostrarNotificacion('Solo el encargado puede firmar', 'error');
        return;
    }
    
    const firmaData = window.inspeccionEstado.firma_encargado;
    if (!firmaData) {
        mostrarNotificacion('Debe cargar su firma primero', 'error');
        return;
    }
    
    try {
        const response = await fetch('/api/encargado/firmar', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                inspeccion_id: inspeccionActualId,
                firma_data: firmaData
            })
        });
        
        const result = await response.json();
        
        if (response.ok) {
            mostrarNotificacion('Firma registrada exitosamente', 'success');
            // Deshabilitar el área de firma
            const firmaArea = document.getElementById('firma-encargado-area');
            if (firmaArea) {
                firmaArea.innerHTML = '<p class="text-green-600 font-semibold">✓ Inspección firmada y aprobada</p>';
            }
        } else {
            throw new Error(result.error);
        }
        
    } catch (error) {
        console.error('Error al firmar:', error);
        mostrarNotificacion(error.message || 'Error al registrar firma', 'error');
    }
}

// Funciones adicionales para informes (para encargados)
async function cargarInformesEstablecimiento() {
    if (userRole !== 'Encargado') return;
    
    try {
        const response = await fetch('/api/informes');
        const informes = await response.json();
        
        // Mostrar informes en formato amigable
        const container = document.getElementById('informes-container');
        if (container && informes.length > 0) {
            container.innerHTML = '';
            
            informes.forEach(informe => {
                const informeDiv = document.createElement('div');
                informeDiv.className = 'bg-white p-4 rounded-lg shadow mb-4';
                informeDiv.innerHTML = `
                    <div class="flex justify-between items-start mb-2">
                        <h3 class="font-semibold text-lg">${informe.establecimiento}</h3>
                        <span class="px-3 py-1 rounded-full text-sm ${
                            informe.estado === 'completada' ? 'bg-green-100 text-green-800' :
                            informe.estado === 'en_proceso' ? 'bg-yellow-100 text-yellow-800' :
                            'bg-gray-100 text-gray-800'
                        }">${informe.estado}</span>
                    </div>
                    <div class="grid grid-cols-2 gap-4 text-sm">
                        <div>
                            <strong>Fecha:</strong> ${new Date(informe.fecha).toLocaleDateString()}
                        </div>
                        <div>
                            <strong>Inspector:</strong> ${informe.inspector}
                        </div>
                        <div>
                            <strong>Puntaje:</strong> ${informe.puntaje_total || 'N/A'} / ${informe.puntaje_maximo_posible || informe.puntaje_maximo || 'N/A'}
                        </div>
                        <div>
                            <strong>Cumplimiento:</strong> ${informe.porcentaje_cumplimiento || 0}%
                        </div>
                    </div>
                `;
                container.appendChild(informeDiv);
            });
        }
        
    } catch (error) {
        console.error('Error cargando informes:', error);
        mostrarNotificacion('Error al cargar informes', 'error');
    }
}

// Función para cerrar sesión correctamente
async function cerrarSesion() {
    try {
        const confirmado = await mostrarDialogoConfirmacion(
            'Cerrar Sesión',
            '¿Estás seguro de que deseas cerrar sesión?',
            'Cerrar Sesión',
            'Cancelar'
        );
        
        if (!confirmado) {
            return; // Usuario canceló
        }
        
        // Limpiar todos los intervalos
        detenerAutosave();
        detenerVerificacionSesionUnica();
        
        // Desconectar socket antes de cerrar sesión
        if (socket) {
            socket.disconnect();
        }
        
        // Limpiar datos temporales
        if ('inspeccion_temporal' in sessionStorage) {
            sessionStorage.removeItem('inspeccion_temporal');
        }
        
        // Realizar logout
        const response = await fetch('/api/auth/logout', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            }
        });
        
        // Redirigir al login independientemente de la respuesta
        window.location.href = '/login';
        
    } catch (error) {
        console.error('Error cerrando sesión:', error);
        // Redirigir al login aunque haya error
        window.location.href = '/login';
    }
}

// Función para verificar la sesión cuando el usuario navega de vuelta
function verificarSesionAlRetroceder() {
    // NO verificar sesión en la página de login
    if (window.location.pathname === '/login') {
        return;
    }
    
    // Verificar si hay sesión activa
    fetch('/api/auth/check')
        .then(response => {
            if (!response.ok) {
                // No hay sesión válida, redirigir al login
                window.location.href = '/login';
            }
        })
        .catch(error => {
            console.error('Error verificando sesión:', error);
            window.location.href = '/login';
        });
}

// Detectar cuando el usuario navega de vuelta a la página
window.addEventListener('pageshow', function(event) {
    // NO ejecutar en página de login
    if (window.location.pathname === '/login') {
        return;
    }
    
    if (event.persisted) {
        // La página fue cargada desde caché (usuario usó botón atrás)
        verificarSesionAlRetroceder();
    }
});

// Verificar sesión al cargar la página
window.addEventListener('load', function() {
    // NO ejecutar en página de login
    if (window.location.pathname === '/login') {
        return;
    }
    
    verificarSesionAlRetroceder();
});
