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

function limpiarInputsEvidencias() {
    ['evidencias-input', 'evidencias-camera-input'].forEach((inputId) => {
        const input = document.getElementById(inputId);
        if (input) {
            input.value = '';
        }
    });
}

function manejarSeleccionEvidencias(event) {
    const files = Array.from(event.target.files || []);
    if (files.length === 0) {
        return;
    }

    procesarEvidencias(files);

    // Permite volver a seleccionar o volver a tomar la misma foto si el usuario lo necesita.
    event.target.value = '';
}

function registrarInputEvidencias(input) {
    if (!input || input.dataset.evidenciasInicializado === 'true') {
        return;
    }

    input.addEventListener('change', manejarSeleccionEvidencias);
    input.dataset.evidenciasInicializado = 'true';
}

/**
 * Inicializa el sistema de evidencias fotográficas
 */
function inicializarEvidencias() {
    const evidenciasInput = document.getElementById('evidencias-input');
    const camaraInput = document.getElementById('evidencias-camera-input');
    const abrirArchivosBtn = document.getElementById('abrir-archivos-evidencia');
    const abrirCamaraBtn = document.getElementById('abrir-camara-evidencia');

    if (!evidenciasInput && !camaraInput) return;
    
    asegurarEstadoEvidenciasCompartido();
    sincronizarEvidenciasExistentes();

    registrarInputEvidencias(evidenciasInput);
    registrarInputEvidencias(camaraInput);

    if (abrirArchivosBtn && abrirArchivosBtn.dataset.evidenciasInicializado !== 'true') {
        abrirArchivosBtn.addEventListener('click', function() {
            evidenciasInput?.click();
        });
        abrirArchivosBtn.dataset.evidenciasInicializado = 'true';
    }

    if (abrirCamaraBtn && abrirCamaraBtn.dataset.evidenciasInicializado !== 'true') {
        abrirCamaraBtn.addEventListener('click', function() {
            abrirModalCamaraEvidencia();
        });
        abrirCamaraBtn.dataset.evidenciasInicializado = 'true';
    }
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
        const total = window.evidenciasAcumuladas.length;
        contador.textContent = `${total} ${total === 1 ? 'evidencia' : 'evidencias'}`;
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

function notificarEvidencias(mensaje, tipo = 'info') {
    if (typeof mostrarNotificacion === 'function') {
        mostrarNotificacion(mensaje, tipo);
        return;
    }

    if (tipo === 'error' || tipo === 'warning') {
        alert(mensaje);
    }
}

function generarNombreArchivoEvidencia(extension = 'jpg') {
    const ahora = new Date();
    const sello = [
        ahora.getFullYear(),
        String(ahora.getMonth() + 1).padStart(2, '0'),
        String(ahora.getDate()).padStart(2, '0'),
        '_',
        String(ahora.getHours()).padStart(2, '0'),
        String(ahora.getMinutes()).padStart(2, '0'),
        String(ahora.getSeconds()).padStart(2, '0')
    ].join('');

    const sufijo = Math.random().toString(36).slice(2, 8);
    return `evidencia_${sello}_${sufijo}.${extension}`;
}

function detenerStreamCamaraEvidencia() {
    const estado = window.modalCamaraEvidenciaEstado;
    if (!estado || !estado.stream) {
        return;
    }

    estado.stream.getTracks().forEach((track) => {
        try {
            track.stop();
        } catch (error) {
        }
    });

    estado.stream = null;
}

async function capturarBlobCamaraEvidencia(video, canvas) {
    const width = video.videoWidth || 1280;
    const height = video.videoHeight || 720;

    if (!width || !height) {
        throw new Error('La camara aun no esta lista para capturar.');
    }

    canvas.width = width;
    canvas.height = height;

    const context = canvas.getContext('2d', { alpha: false });
    context.drawImage(video, 0, 0, width, height);

    return new Promise((resolve, reject) => {
        canvas.toBlob((blob) => {
            if (blob) {
                resolve(blob);
                return;
            }
            reject(new Error('No se pudo generar la imagen capturada.'));
        }, 'image/jpeg', 0.92);
    });
}

async function iniciarStreamCamaraEvidencia(video, mensajeError, facingMode = 'environment') {
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('Este navegador no soporta camara embebida.');
    }

    if (!window.isSecureContext && !['localhost', '127.0.0.1'].includes(window.location.hostname)) {
        throw new Error('La camara embebida requiere HTTPS o localhost.');
    }

    detenerStreamCamaraEvidencia();

    if (mensajeError) {
        mensajeError.textContent = '';
        mensajeError.classList.add('hidden');
    }

    const videoBase = {
        width: { ideal: 1280 },
        height: { ideal: 720 }
    };

    const constraintsPreferidos = {
        audio: false,
        video: {
            ...videoBase,
            facingMode: { ideal: facingMode }
        }
    };

    const constraintsBasicos = {
        audio: false,
        video: videoBase
    };

    let stream;
    try {
        stream = await navigator.mediaDevices.getUserMedia(constraintsPreferidos);
    } catch (error) {
        stream = await navigator.mediaDevices.getUserMedia(constraintsBasicos);
    }

    const estado = window.modalCamaraEvidenciaEstado || {};
    estado.stream = stream;
    estado.facingMode = facingMode;
    window.modalCamaraEvidenciaEstado = estado;

    video.srcObject = stream;
    video.muted = true;
    video.autoplay = true;
    video.playsInline = true;
    video.setAttribute('playsinline', 'true');
    await video.play();
}

function cerrarModalCamaraEvidencia() {
    const estado = window.modalCamaraEvidenciaEstado;
    if (!estado) {
        return;
    }

    detenerStreamCamaraEvidencia();

    if (estado.previewUrl) {
        URL.revokeObjectURL(estado.previewUrl);
    }

    if (estado.keydownHandler) {
        document.removeEventListener('keydown', estado.keydownHandler);
    }

    if (estado.modal && estado.modal.parentNode) {
        estado.modal.parentNode.removeChild(estado.modal);
    }

    window.modalCamaraEvidenciaEstado = null;
}

async function abrirModalCamaraEvidencia() {
    if (document.getElementById('modal-camara-evidencia')) {
        return;
    }

    const modal = document.createElement('div');
    modal.id = 'modal-camara-evidencia';
    modal.className = 'fixed inset-0 bg-black bg-opacity-80 flex items-center justify-center overflow-y-auto p-3 sm:p-6';
    modal.style.zIndex = '10050';
    modal.innerHTML = `
        <div class="my-auto flex w-full max-w-5xl flex-col overflow-hidden rounded-2xl bg-white dark:bg-slate-900 shadow-2xl" style="max-height: calc(100vh - 2rem);">
            <div class="flex items-center justify-between border-b border-slate-200 dark:border-slate-700 px-4 py-3 sm:px-6">
                <div>
                    <h3 class="text-base sm:text-lg font-semibold text-slate-900 dark:text-slate-100">Tomar evidencia fotografica</h3>
                    <p class="text-xs sm:text-sm text-slate-500 dark:text-slate-400">Capture la foto sin salir del sistema.</p>
                </div>
                <button type="button" id="cerrar-modal-camara-evidencia" class="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 hover:text-slate-700 dark:hover:text-slate-200" aria-label="Cerrar camara">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
            <div class="flex-1 overflow-y-auto p-4 sm:p-6">
                <div class="mx-auto flex w-full items-center justify-center rounded-2xl bg-slate-950 p-2 sm:p-3">
                    <video id="video-camara-evidencia" class="block w-full rounded-xl bg-black object-contain" style="min-height: 280px; max-height: calc(100vh - 18rem);" autoplay muted playsinline></video>
                    <img id="preview-camara-evidencia" class="hidden w-full rounded-xl bg-black object-contain" style="min-height: 280px; max-height: calc(100vh - 18rem);" alt="Vista previa de la captura">
                    <canvas id="canvas-camara-evidencia" class="hidden"></canvas>
                </div>
                <p id="mensaje-error-camara-evidencia" class="hidden mt-4 rounded-xl bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/40 dark:text-red-300"></p>
                <p id="mensaje-ayuda-camara-evidencia" class="mt-3 text-xs sm:text-sm text-slate-500 dark:text-slate-400">Apunte la camara y presione "Tomar foto".</p>
            </div>
            <div class="flex flex-col gap-3 border-t border-slate-200 dark:border-slate-700 px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-6">
                <button type="button" id="cambiar-camara-evidencia" class="inline-flex items-center justify-center rounded-xl border border-slate-300 dark:border-slate-600 px-4 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-200 hover:border-rose-400 hover:text-rose-600 dark:hover:text-rose-400 transition-colors">
                    Cambiar camara
                </button>
                <div class="flex flex-col-reverse gap-3 sm:flex-row">
                    <button type="button" id="cancelar-camara-evidencia" class="inline-flex items-center justify-center rounded-xl border border-slate-300 dark:border-slate-600 px-4 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
                        Cancelar
                    </button>
                    <button type="button" id="repetir-camara-evidencia" class="hidden inline-flex items-center justify-center rounded-xl border border-slate-300 dark:border-slate-600 px-4 py-2.5 text-sm font-medium text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-800 transition-colors">
                        Repetir
                    </button>
                    <button type="button" id="capturar-camara-evidencia" class="inline-flex items-center justify-center rounded-xl bg-rose-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-rose-700 transition-colors">
                        Tomar foto
                    </button>
                    <button type="button" id="guardar-camara-evidencia" class="hidden inline-flex items-center justify-center rounded-xl bg-emerald-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-emerald-700 transition-colors">
                        Usar foto
                    </button>
                </div>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    const video = modal.querySelector('#video-camara-evidencia');
    const preview = modal.querySelector('#preview-camara-evidencia');
    const canvas = modal.querySelector('#canvas-camara-evidencia');
    const mensajeError = modal.querySelector('#mensaje-error-camara-evidencia');
    const mensajeAyuda = modal.querySelector('#mensaje-ayuda-camara-evidencia');
    const btnCerrar = modal.querySelector('#cerrar-modal-camara-evidencia');
    const btnCancelar = modal.querySelector('#cancelar-camara-evidencia');
    const btnCambiarCamara = modal.querySelector('#cambiar-camara-evidencia');
    const btnCapturar = modal.querySelector('#capturar-camara-evidencia');
    const btnRepetir = modal.querySelector('#repetir-camara-evidencia');
    const btnGuardar = modal.querySelector('#guardar-camara-evidencia');

    const estado = {
        modal,
        video,
        canvas,
        preview,
        mensajeError,
        mensajeAyuda,
        btnCambiarCamara,
        btnCapturar,
        btnRepetir,
        btnGuardar,
        stream: null,
        previewUrl: null,
        capturedBlob: null,
        facingMode: 'environment'
    };

    estado.keydownHandler = (event) => {
        if (event.key === 'Escape') {
            cerrarModalCamaraEvidencia();
        }
    };

    window.modalCamaraEvidenciaEstado = estado;
    document.addEventListener('keydown', estado.keydownHandler);

    const mostrarError = (mensaje) => {
        mensajeError.textContent = mensaje;
        mensajeError.classList.remove('hidden');
        mensajeAyuda.textContent = 'Si la camara no abre, verifique permisos del navegador.';
    };

    const resetVistaCaptura = () => {
        if (estado.previewUrl) {
            URL.revokeObjectURL(estado.previewUrl);
            estado.previewUrl = null;
        }

        estado.capturedBlob = null;
        preview.src = '';
        preview.classList.add('hidden');
        video.classList.remove('hidden');
        btnCapturar.classList.remove('hidden');
        btnGuardar.classList.add('hidden');
        btnRepetir.classList.add('hidden');
        btnCambiarCamara.classList.remove('hidden');
        mensajeAyuda.textContent = 'Apunte la camara y presione "Tomar foto".';
    };

    const iniciarCamara = async (facingMode = estado.facingMode) => {
        btnCapturar.disabled = true;
        btnCambiarCamara.disabled = true;
        btnGuardar.disabled = true;
        btnRepetir.disabled = true;

        resetVistaCaptura();

        try {
            await iniciarStreamCamaraEvidencia(video, mensajeError, facingMode);
            estado.facingMode = facingMode;
            btnCapturar.disabled = false;
            btnCambiarCamara.disabled = false;
            mensajeAyuda.textContent = 'Apunte la camara y presione "Tomar foto".';
        } catch (error) {
            mostrarError(error.message || 'No se pudo iniciar la camara.');
        }
    };

    modal.addEventListener('click', (event) => {
        if (event.target === modal) {
            cerrarModalCamaraEvidencia();
        }
    });

    btnCerrar.addEventListener('click', cerrarModalCamaraEvidencia);
    btnCancelar.addEventListener('click', cerrarModalCamaraEvidencia);

    btnCambiarCamara.addEventListener('click', async () => {
        const siguiente = estado.facingMode === 'environment' ? 'user' : 'environment';
        await iniciarCamara(siguiente);
    });

    btnCapturar.addEventListener('click', async () => {
        try {
            const blob = await capturarBlobCamaraEvidencia(video, canvas);
            detenerStreamCamaraEvidencia();

            estado.capturedBlob = blob;
            estado.previewUrl = URL.createObjectURL(blob);
            preview.src = estado.previewUrl;
            preview.classList.remove('hidden');
            video.classList.add('hidden');

            btnCapturar.classList.add('hidden');
            btnGuardar.classList.remove('hidden');
            btnRepetir.classList.remove('hidden');
            btnCambiarCamara.classList.add('hidden');
            btnGuardar.disabled = false;
            btnRepetir.disabled = false;
            mensajeAyuda.textContent = 'Revise la foto. Puede repetirla o usarla como evidencia.';
        } catch (error) {
            mostrarError(error.message || 'No se pudo capturar la imagen.');
        }
    });

    btnRepetir.addEventListener('click', async () => {
        await iniciarCamara(estado.facingMode);
    });

    btnGuardar.addEventListener('click', () => {
        if (!estado.capturedBlob) {
            mostrarError('Primero debe tomar una foto.');
            return;
        }

        const file = new File(
            [estado.capturedBlob],
            generarNombreArchivoEvidencia('jpg'),
            { type: 'image/jpeg', lastModified: Date.now() }
        );

        procesarEvidencias([file]);
        cerrarModalCamaraEvidencia();
        notificarEvidencias('Foto agregada como evidencia', 'success');
    });

    await iniciarCamara(estado.facingMode);
}

window.limpiarInputsEvidencias = limpiarInputsEvidencias;
window.abrirModalCamaraEvidencia = abrirModalCamaraEvidencia;

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
