// Event listener principal
document.addEventListener('DOMContentLoaded', function () {
    // NO ejecutar en página de login
    if (window.location.pathname === '/login') {
        return;
    }

    // Inicializar datos de usuario desde el DOM o variables globales
    inicializarDatosUsuario();

    // Asegurar que userRole esté definido con fallback
    if (!userRole) {
        userRole = document.body.dataset.userRole || 'Inspector';
    }

    // Inicializar estado global de inspección
    if (!window.inspeccionEstado) {
        window.inspeccionEstado = {
            inspeccion_id: null,
            firma_encargado: null,
            firma_inspector: null,
            estado: 'borrador',
            encargado_aprobo: false,
            inspector_firmo: false,
            confirmada_por_encargado: false,
            confirmador_nombre: null,
            confirmador_rol: null,
            confirmacionesPorEstablecimiento: {} // Estado de confirmación por establecimiento
        };
    }

    // Cargar estado de confirmaciones desde sessionStorage
    cargarEstadoConfirmaciones();

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

    // Mantener conexión activa en móviles
    mantenerConexionActiva();

    // Cargar establecimientos
    // await cargarEstablecimientos();
    // cargarEstablecimientos();

    inicializarIndexSelect()

    // Limpiar cookies viejas automáticamente al cargar la aplicación
    if (window.FormCookieManager) {
        const cookieManager = new window.FormCookieManager();
        cookieManager.cleanupOldCookies();
    }

    // Recuperar estado temporal
    // await recuperarEstadoTemporal();
    recuperarEstadoTemporal();

    // Verificar si hay datos de cookie para cargar al inicio
    const establecimientoSelectElement = document.getElementById('establecimiento');
    if (establecimientoSelectElement && establecimientoSelectElement.value && window.FormCookieManager) {
        const establecimientoId = establecimientoSelectElement.value;
        const cookieManager = new window.FormCookieManager();
        if (cookieManager.hasFormData(establecimientoId)) {

            mostrarNotificacion('Se ha encontrado datos guardados', 'info')

            // Solo cargar cookies si no hay estado temporal del servidor
            if (!window.inspeccionEstado.inspeccion_id && (!window.inspeccionEstado.items || Object.keys(window.inspeccionEstado.items).length === 0)) {
                const savedData = cookieManager.loadFormData(establecimientoId);
                if (savedData) {
                    mostrarNotificacion('Cargando datos desde cookie...', 'info')

                    // Esperar un poco para que se cargue la interfaz
                    // await new Promise(resolve => setTimeout(resolve, 500));
                    new Promise(resolve => setTimeout(resolve, 500));

                    // Restaurar estado desde cookie
                    restaurarEstado(savedData);

                    // Aplicar calificaciones si existen
                    if (savedData.items && Object.keys(savedData.items).length > 0) {
                        aplicarCalificacionesAInterfaz(savedData.items);
                    }

                    // Aplicar observaciones si existen
                    if (savedData.observaciones) {
                        const observacionesTextarea = document.getElementById('observaciones-generales');
                        if (observacionesTextarea) {
                            observacionesTextarea.value = savedData.observaciones;
                        }
                    }

                    // Actualizar resumen
                    actualizarResumen();
                    actualizarInterfazResumen();

                    mostrarNotificacion('Datos recuperados del último guardado local', 'info');
                }
            }
        }
    }

    // Actualizar contador de evidencias al cargar
    actualizarContadorEvidencias();

    // Iniciar autosave
    iniciarAutosave();

    // Para encargados, cargar establecimiento automáticamente
    if (userRole === 'Encargado') {
        // await cargarEstablecimientoEncargado();
        cargarEstablecimientoEncargado();
    }

    // Actualizar interfaz de firmas
    actualizarInterfazFirmas();

    // Para Inspector/Admin/Jefe: Cargar su firma automáticamente al inicio (no requiere establecimiento)
    if (userRole === 'Inspector' || userRole === 'Administrador' || userRole === 'Jefe de Establecimiento') {
        cargarFirmaUsuarioActual();
    }

    // Para Inspector/Admin: Mostrar opción de inspecciones pendientes
    if (userRole === 'Inspector' || userRole === 'Administrador') {
        cargarInspeccionesPendientes();
    } else {
    }

    // Nota: El event listener para selección de establecimiento se configura automáticamente

    // Evento para botón de sincronización manual (solo Encargados - ahora oculto ya que es automático)
    const btnSincronizar = document.getElementById('btn-sincronizar');
    if (btnSincronizar && userRole === 'Encargado') {
        // Ocultar el botón ya que la sincronización es automática
        btnSincronizar.style.display = 'none';
    }

    // Event listener para observaciones generales con throttling
    const observacionesTextarea = document.getElementById('observaciones-generales');
    if (observacionesTextarea) {
        let observacionesTimeout = null;

        observacionesTextarea.addEventListener('input', function () {
            if (userRole === 'Inspector' || userRole === 'Administrador') {
                reiniciarConfirmacionEncargadoPorCambio();
            }

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
        observacionesTextarea.addEventListener('blur', function () {
            // Marcar que hay cambios pendientes si el valor cambió realmente
            if (window.inspeccionEstado.observaciones !== this.value) {
                if (userRole === 'Inspector' || userRole === 'Administrador') {
                    reiniciarConfirmacionEncargadoPorCambio();
                }

                marcarCambiosPendientes();
                window.inspeccionEstado.observaciones = this.value;

                if (userRole === 'Inspector' && hayCambiosPendientes) {
                    guardarEstadoTemporal();
                }
            }
        });
    }

    if (typeof inicializarEvidencias === 'function') {
        inicializarEvidencias();
    } else {
    }

    // Event listener para envío del formulario
    const form = document.getElementById('form-inspeccion');
    if (form) {
        form.addEventListener('submit', async function (e) {
            e.preventDefault();
            await guardarInspeccionFinal(e.submitter?.value === 'completar');
        });
    }

    // Event listener para salir de la página
    window.addEventListener('beforeunload', function () {
        salirDeInspeccion();
        detenerAutosave();
        detenerVerificacionSesionUnica();
    });
});


// ===== FUNCIÓN PRINCIPAL DE INICIALIZACIÓN =====
async function inicializarIndexSelect() {
    try {

        // Buscar el select específico de index
        const establecimientoSelect = document.getElementById('establecimiento');
        if (!establecimientoSelect) {
            return;
        }

        // Verificar el rol del usuario
        const userRole = establecimientoSelect.closest('#vista-app')?.dataset.userRole || window.userRole;

        // Para encargados, cargar su establecimiento específico
        if (userRole === 'Encargado') {
            await cargarEstablecimientoEncargado();
            return;
        }

        // Para Inspector/Admin, poblar todos los establecimientos usando la API
        if (typeof EstablecimientosAPI !== 'undefined') {

            const exito = await EstablecimientosAPI.poblarSelect(establecimientoSelect, 'Seleccione un establecimiento');
            if (exito) {
                // Configurar evento de cambio para cargar items cuando se seleccione un establecimiento
                configurarEventoEstablecimiento(establecimientoSelect);
            } else {
                mostrarNotificacion('Error al cargar establecimientos', 'error');
            }
        } else {
            mostrarNotificacion('EstablecimientosAPI no disponible', 'error');
        }

    } catch (error) {
    }
}

// Hacer la función disponible globalmente
window.inicializarIndexSelect = inicializarIndexSelect;


// LIMPIAR INTERVALOS EXISTENTES AL CARGAR
// Deshabilitar cualquier intervalo de verificación de sesión que pueda estar ejecutándose
(function () {
    // Limpiar todos los intervalos que puedan estar ejecutándose
    const maxIntervalId = window.setInterval(function () { }, 0);
    for (let i = 1; i <= maxIntervalId; i++) {
        window.clearInterval(i);
    }
})();

// Estado global de la inspección
window.inspeccionEstado = {
    establecimiento_id: null,
    items: {},
    evidencias: [],
    firma_inspector: null,
    firma_encargado: null,
    observaciones: '',
    encargado_aprobo: false,
    inspector_firmo: false,
    confirmacionesPorEstablecimiento: {}, // Nuevo: estado de confirmación por establecimiento
    confirmador_nombre: null,
    confirmador_rol: null,
    resumen: {
        puntaje_total: 0,
        puntaje_maximo_posible: 0,  // Cambiado de puntaje_maximo a puntaje_maximo_posible
        porcentaje_cumplimiento: 0,
        puntos_criticos_perdidos: 0
    }
};

// Funciones para persistir estado de confirmaciones en sessionStorage
/**
 * Carga el estado de confirmaciones desde sessionStorage al inicializar la aplicación.
 * Se ejecuta al cargar la página para restaurar el estado de confirmaciones por establecimiento.
 */
function cargarEstadoConfirmaciones() {
    try {
        const estadoGuardado = sessionStorage.getItem('confirmacionesPorEstablecimiento');
        if (estadoGuardado) {
            const confirmaciones = JSON.parse(estadoGuardado);
            window.inspeccionEstado.confirmacionesPorEstablecimiento = confirmaciones;
        }
    } catch (error) {
        console.warn('Error al cargar estado de confirmaciones desde sessionStorage:', error);
    }
}

/**
 * Guarda el estado actual de confirmaciones en sessionStorage.
 * Se ejecuta cada vez que cambia el estado de confirmación de un establecimiento.
 */
function guardarEstadoConfirmaciones() {
    try {
        const estadoActual = window.inspeccionEstado.confirmacionesPorEstablecimiento;
        sessionStorage.setItem('confirmacionesPorEstablecimiento', JSON.stringify(estadoActual));
    } catch (error) {
        console.warn('Error al guardar estado de confirmaciones en sessionStorage:', error);
    }
}

// Variables globales
let socket = null;
let inspeccionActualId = null;
let userRole = null;
let userId = null;
let autoSaveInterval = null;

// Función para inicializar variables de usuario desde los datos del DOM
function inicializarDatosUsuario() {
    const vistaApp = document.getElementById('vista-app');
    if (vistaApp) {
        userRole = vistaApp.getAttribute('data-user-role');
        const userIdAttr = vistaApp.getAttribute('data-user-id');
        userId = userIdAttr ? parseInt(userIdAttr) : null;
    }

    // Fallback: usar variables globales de window si existen
    if (!userRole && window.userRole) {
        userRole = window.userRole;
    }
    if (!userId && window.userId) {
        userId = window.userId;
    }
}

// Control de cambios para optimización de emisiones en tiempo real
let hayCambiosPendientes = false;
let ultimoEstadoEmitido = null;

// Configuración de autosave - guardado inmediato en cada cambio
const AUTOSAVE_INTERVAL = 5000; // 5 segundos para guardado de seguridad (si falló el inmediato)
const IMMEDIATE_SAVE_DELAY = 500; // 500ms de delay para batch de cambios múltiples

// Control de autosave inmediato
let immediateSaveTimeout = null;

// Función para marcar que hay cambios pendientes
function marcarCambiosPendientes() {
    hayCambiosPendientes = true;

    // Guardado inmediato con debounce para evitar demasiadas llamadas
    if (immediateSaveTimeout) {
        clearTimeout(immediateSaveTimeout);
    }

    immediateSaveTimeout = setTimeout(() => {
        guardarEstadoTemporal(true); // Forzar guardado inmediato
    }, IMMEDIATE_SAVE_DELAY);
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
    // Configuración optimizada para dispositivos móviles
    socket = io({
        // Configuraciones para mantener conexión activa
        forceNew: true,
        reconnection: true,
        timeout: 5000,
        reconnectionDelay: 1000,
        reconnectionDelayMax: 5000,
        maxReconnectionAttempts: 10,
        transports: ['websocket', 'polling'],
        upgrade: true,

        // Configuraciones específicas para móviles
        pingTimeout: 60000,
        pingInterval: 25000,

        // Headers para mantener conexión
        extraHeaders: {
            'Connection': 'keep-alive',
            'Keep-Alive': 'timeout=60, max=1000'
        }
    });

    // Eventos de conexión/desconexión
    socket.on('connect', function () {
        mostrarEstadoConexion('Conectado', 'success');

        // Delay pequeño para asegurar conexión estable, luego recuperar estado
        setTimeout(async () => {
            mostrarEstadoSincronizacion('🔄 Sincronizando datos...', true);

            try {
                // Recuperar estado temporal del servidor
                await recuperarEstadoTemporal();

                // Para encargados, sincronizar inmediatamente si hay establecimiento
                if (userRole === 'Encargado' && window.inspeccionEstado.establecimiento_id) {
                    // Unirse a la sala del establecimiento
                    socket.emit('join_establecimiento', {
                        establecimiento_id: window.inspeccionEstado.establecimiento_id,
                        usuario_id: window.userId || 1,
                        role: userRole
                    });

                    await sincronizarEstablecimientoInmediatamente(window.inspeccionEstado.establecimiento_id);
                }

                // Reenviar estado actual tras conexión si existe
                if (inspeccionActualId && window.inspeccionEstado.establecimiento_id) {
                    emitirEstadoCompleto();
                }

                mostrarEstadoSincronizacion('✅ Datos sincronizados');
            } catch (error) {
                mostrarEstadoSincronizacion('❌ Error en sincronización');
                console.error('Error en conexión inicial:', error);
            }
        }, 500);
    });

    socket.on('disconnect', function (reason) {
        mostrarEstadoConexion('Desconectado', 'error');
    });

    socket.on('reconnect', function (attemptNumber) {
        mostrarEstadoConexion('Reconectado', 'success');

        // Delay para asegurar que la reconexión esté estable
        setTimeout(async () => {
            mostrarEstadoSincronizacion('🔄 Sincronizando datos...', true);

            try {
                // Recuperar estado temporal del servidor
                await recuperarEstadoTemporal();

                // Para encargados, forzar sincronización inmediata del establecimiento
                if (userRole === 'Encargado' && window.inspeccionEstado.establecimiento_id) {
                    // Unirse a la sala del establecimiento
                    socket.emit('join_establecimiento', {
                        establecimiento_id: window.inspeccionEstado.establecimiento_id,
                        usuario_id: window.userId || 1,
                        role: userRole
                    });

                    await sincronizarEstablecimientoInmediatamente(window.inspeccionEstado.establecimiento_id);
                }

                // Reenviar estado actual tras reconexión si existe
                if (inspeccionActualId && window.inspeccionEstado.establecimiento_id) {
                    emitirEstadoCompleto();
                }

                mostrarEstadoSincronizacion('✅ Datos sincronizados');
            } catch (error) {
                mostrarEstadoSincronizacion('❌ Error en sincronización');
                console.error('Error en reconexión:', error);
            }
        }, 1500);
    });

    socket.on('reconnecting', function (attemptNumber) {
        mostrarEstadoConexion(`Reconectando... (${attemptNumber})`, 'warning');
    });

    socket.on('reconnect_error', function (error) {
        mostrarEstadoConexion('Error de conexión', 'error');
    });

    socket.on('connected', function (data) {
    });

    socket.on('usuario_unido', function (data) {
        mostrarNotificacion(`${data.usuario} se unió a la inspección`, 'info');
    });

    socket.on('usuario_salio', function (data) {
        mostrarNotificacion(`${data.usuario} salió de la inspección`, 'info');
    });

    // Evento específico para tiempo real sin inspección activa
    socket.on('item_rating_tiempo_real', function (data) {
        actualizarItemEnTiempoReal(data);
    });

    // Nuevo evento para tiempo real completo en establecimiento
    socket.on('inspeccion_tiempo_real', function (data) {
        if (!data || !data.establecimiento_id) {
            return;
        }

        if (userRole === 'Encargado') {
            const sincronizacionParcial = actualizarDatosTiempoRealCompletos(data);

            if (!sincronizacionParcial) {
                mostrarNotificacion('Sincronizacion completa solicitada al servidor', 'info');

                sincronizarEstablecimientoInmediatamente(data.establecimiento_id).then(exito => {
                    if (exito) {
                        mostrarNotificacion('Datos sincronizados automaticamente', 'success');
                    }
                });
            }
            return;
        }

        if (userRole === 'Inspector' || userRole === 'Administrador') {
            actualizarEstadoTiempoRealInspector(data);
        }
    });

    socket.on('item_actualizado', function (data) {
        // Solo mostrar al encargado cuando el inspector actualiza
        if (userRole === 'Encargado' && data.actualizado_por === 'Inspector') {
            actualizarItemEnTiempoReal(data);
        }
    });

    socket.on('observaciones_actualizadas', function (data) {
        // Solo mostrar al encargado cuando el inspector actualiza
        if (userRole === 'Encargado' && data.actualizado_por === 'Inspector') {
            actualizarObservacionesEnTiempoReal(data);
        }
    });

    socket.on('estado_inspeccion_cambiado', function (data) {
        actualizarEstadoInspeccionEnTiempoReal(data);
    });

    socket.on('solicitud_firma', function (data) {
        if (userRole === 'Encargado') {
            mostrarSolicitudFirma(data);
        }
    });

    // Evento para resetear formulario después de guardar inspección
    socket.on('inspeccion_guardada_resetear', function (data) {

        if (data.establecimiento_id) {
            // Limpiar formulario completo
            resetearFormularioCompleto();

            // Limpiar estado de la aplicación
            limpiarEstadoTemporal();

            // Si hay establecimiento seleccionado actualmente, mantenerlo pero recargar items
            const establecimientoSelect = document.getElementById('establecimiento');
            if (establecimientoSelect && establecimientoSelect.value) {
                setTimeout(() => {
                    cargarItemsEstablecimiento(establecimientoSelect.value);
                }, 500);
            }

            // Actualizar plan semanal si está disponible
            if (data.actualizar_plan_semanal && typeof actualizarPlanSemanal === 'function') {
                setTimeout(() => {
                    actualizarPlanSemanal();
                }, 1000);
            }

            mostrarNotificacion('Formulario reseteado - Inspección guardada exitosamente', 'success');
        }
    });

    socket.on('firma_recibida', function (data) {
        mostrarNotificacion(`Firma de ${data.tipo_firma} recibida de ${data.firmado_por}`, 'success');

        // Actualizar estado local de firmas CON LOS DATOS REALES
        if (data.tipo_firma === 'encargado') {
            // Solo actualizar si tenemos datos reales de firma
            if (data.firma_data) {
                window.inspeccionEstado.firma_encargado = data.firma_data;
            }
            window.inspeccionEstado.encargado_aprobo = true;
        } else if (data.tipo_firma === 'inspector') {
            // Solo actualizar si tenemos datos reales de firma
            if (data.firma_data) {
                window.inspeccionEstado.firma_inspector = data.firma_data;
            }
            window.inspeccionEstado.inspector_firmo = true;
        }

        // Actualizar interfaz
        actualizarInterfazFirmas();
    });

    socket.on('encargado_aprobo', function (data) {
        // Evento encargado_aprobo recibido
        if (userRole === 'Inspector') {
            mostrarNotificacion(data.mensaje, 'success');
            window.inspeccionEstado.encargado_aprobo = true;

            // SIEMPRE actualizar con la firma real cuando llegue del encargado
            if (data.firma_data) {
                window.inspeccionEstado.firma_encargado = data.firma_data;
                // Firma del encargado recibida y guardada
            } else {
                // No se recibieron datos de firma del encargado
                window.inspeccionEstado.firma_encargado = 'FIRMA_APROBADA';
            }

            // Actualizar interfaz inmediatamente
            actualizarInterfazFirmas();

            // Estado actualizado - Encargado aprobó
        }
    });

    socket.on('notificacion_general', function (data) {
        // Evento notificacion_general recibido
        if (data.para_rol === userRole || data.para_rol === 'Todos') {
            if (data.tipo === 'encargado_aprobo' && userRole === 'Inspector') {
                // Procesando notificación de aprobación para Inspector
                window.inspeccionEstado.encargado_aprobo = true;

                // SIEMPRE actualizar con la firma real del encargado
                if (data.firma_data) {
                    window.inspeccionEstado.firma_encargado = data.firma_data;
                    // Firma del encargado recibida via notificacion_general
                } else {
                    // No hay firma_data en notificacion_general
                    window.inspeccionEstado.firma_encargado = 'FIRMA_APROBADA';
                }

                actualizarInterfazFirmas();
                mostrarNotificacion(data.mensaje, 'success');
            }
        }
    });

    socket.on('estado_sincronizado', function (data) {
        if (data.reconectado) {
            mostrarNotificacion('Conexión restaurada', 'success');

            // Recuperar estado actualizado del servidor para asegurar sincronización
            setTimeout(async () => {
                await recuperarEstadoTemporal();
            }, 500);

            // Actualizar estado local si es necesario
            if (userRole === 'Encargado' && data.establecimiento_id) {
                actualizarDatosTiempoRealCompletos(data);
            }
        }
    });

    socket.on('pong_keepalive', function (data) {
        // Respuesta del servidor al ping - conexión activa
    });

    // Evento cuando un encargado confirma la inspección
    socket.on('encargado_aprobo', function (data) {

        // Para todos los encargados y jefes: deshabilitar botón
        if (userRole === 'Encargado' || userRole === 'Jefe de Establecimiento') {
            mostrarNotificacion(
                `Inspección confirmada por ${data.confirmador_nombre || 'Encargado'} (${data.confirmador_rol || 'Encargado'})`,
                'success'
            );
            deshabilitarBotonConfirmar(data.confirmador_nombre || 'Encargado', data.confirmador_rol || 'Encargado');
        }

        // Para inspectores: actualizar estado y habilitar guardado
        if (userRole === 'Inspector' || userRole === 'Administrador') {
            mostrarNotificacion(
                `Encargado confirmó la inspección`,
                'success'
            );

            // Actualizar estado por establecimiento
            if (!window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id]) {
                window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id] = {};
            }
            window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id] = {
                confirmada_por_encargado: true,
                confirmador_nombre: data.confirmador_nombre || 'Encargado',
                confirmador_rol: data.confirmador_rol || 'Encargado'
            };

            // Guardar estado de confirmaciones en sessionStorage
            guardarEstadoConfirmaciones();

            // Habilitar botón de completar inspección
            deshabilitarBotonCompletarInspector();
        }
    });
}

// Función para mostrar estado de conexión
function mostrarEstadoConexion(estado, tipo) {
    const estadoElement = document.getElementById('estado-conexion');
    if (estadoElement) {
        estadoElement.textContent = estado;
        estadoElement.className = `estado-conexion ${tipo}`;

        // Auto ocultar después de 3 segundos si es éxito
        if (tipo === 'success') {
            setTimeout(() => {
                estadoElement.textContent = '';
                estadoElement.className = 'estado-conexion';
            }, 3000);
        }
    }
}

// Función para emitir estado completo tras reconexión
function emitirEstadoCompleto() {
    if (!socket || !socket.connected) return;

    const estadoCompleto = {
        establecimiento_id: window.inspeccionEstado.establecimiento_id,
        inspeccion_id: inspeccionActualId,
        items: window.inspeccionEstado.items,
        observaciones: window.inspeccionEstado.observaciones,
        resumen: window.inspeccionEstado.resumen,
        evidencias_count: window.inspeccionEstado.evidencias ? window.inspeccionEstado.evidencias.length : 0,
        timestamp: Date.now()
    };

    socket.emit('estado_completo_reconexion', estadoCompleto);

    // También solicitar sincronización desde el servidor
    setTimeout(async () => {
        await recuperarEstadoTemporal();
    }, 1000);
}

// Funciones para mantener conexión activa en móviles
function mantenerConexionActiva() {
    // Enviar ping cada 20 segundos para mantener conexión
    setInterval(() => {
        if (socket && socket.connected) {
            socket.emit('ping_keepalive', { timestamp: Date.now() });
        }
    }, 20000);

    // Detectar cambios de visibilidad de página
    document.addEventListener('visibilitychange', function () {
        if (document.visibilityState === 'visible' && socket && !socket.connected) {
            socket.connect();
        }
    });

    // Detectar cambios de conexión de red
    window.addEventListener('online', function () {
        if (socket && !socket.connected) {
            socket.connect();
        }
    });

    window.addEventListener('offline', function () {
        mostrarEstadoConexion('Sin conexión', 'error');
    });

    // Detectar cuando la página vuelve desde el background (mobile)
    let isHidden = false;
    document.addEventListener('visibilitychange', function () {
        if (document.hidden) {
            isHidden = true;
            // Guardar inmediatamente antes de ir al background
            if (hayCambiosPendientes) {
                guardarEstadoTemporal(true);
            }
        } else if (isHidden) {
            isHidden = false;

            // Verificar estado de Socket después de 1 segundo
            setTimeout(() => {
                if (socket && !socket.connected) {
                    mostrarEstadoConexion('Reconectando...', 'warning');
                    socket.connect();
                } else if (socket && socket.connected) {
                    // Verificar que la conexión esté realmente activa
                    socket.emit('ping_keepalive', { timestamp: Date.now() });
                }

                // Recuperar estado actualizado del servidor
                setTimeout(async () => {
                    await recuperarEstadoTemporal();
                }, 1000);
            }, 1000);
        }
    });

    // Detectar cambios de estado de la aplicación en iOS
    window.addEventListener('pagehide', function () {
        // Guardar síncronamente antes de que la página se oculte
        if (hayCambiosPendientes) {
            navigator.sendBeacon('/api/inspecciones/temporal',
                JSON.stringify(window.inspeccionEstado));
        }
    });

    window.addEventListener('pageshow', function (e) {
        if (e.persisted) {
            // Forzar reconexión en iOS
            setTimeout(() => {
                if (socket && !socket.connected) {
                    socket.connect();
                }
                // Recuperar estado actualizado
                setTimeout(async () => {
                    await recuperarEstadoTemporal();
                }, 500);
            }, 500);
        }
    });

    // Guardar antes de cerrar ventana o navegar fuera
    window.addEventListener('beforeunload', function (e) {
        if (hayCambiosPendientes) {
            // Usar sendBeacon para envío confiable al cerrar
            navigator.sendBeacon('/api/inspecciones/temporal',
                JSON.stringify(window.inspeccionEstado));
        }
    });

    // Guardar al navegar fuera (SPA)
    window.addEventListener('unload', function () {
        if (hayCambiosPendientes) {
            navigator.sendBeacon('/api/inspecciones/temporal',
                JSON.stringify(window.inspeccionEstado));
        }
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
    } else {
        console.log('DEBUG - No se puede unir a inspección - Socket:', !!socket, 'InspeccionId:', inspeccionId);
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

    if (!window.inspeccionEstado.items[data.item_id]) {
        window.inspeccionEstado.items[data.item_id] = {};
    }
    window.inspeccionEstado.items[data.item_id] = {
        ...window.inspeccionEstado.items[data.item_id],
        rating: data.rating,
        puntaje_maximo: data.puntaje_maximo || window.inspeccionEstado.items[data.item_id].puntaje_maximo,
        riesgo: data.riesgo || window.inspeccionEstado.items[data.item_id].riesgo
    };

    // Actualizar resumen y barra de progreso usando datos del backend si existen
    if (data.resumen && Object.keys(data.resumen).length > 0) {
        actualizarResumenConPuntajes(data.resumen);
    } else {
        if (!window.inspeccionEstado.resumen) {
            window.inspeccionEstado.resumen = {};
        }

        window.inspeccionEstado.resumen.total_items = window.inspeccionEstado.resumen.total_items ?? data.total_items ?? data.totalItems ?? obtenerTotalItemsDisponibles();
        recalcularResumenEncargado();
    }

    mostrarNotificacion(`Item calificado: ${data.rating} puntos`, 'info');
}

function actualizarDatosTiempoRealCompletos(data) {
    if (userRole !== 'Encargado') {
        return false;
    }

    if (!data) {
        return false;
    }

    let huboCambios = false;

    if (data.items) {
        Object.keys(data.items).forEach(itemId => {
            const itemData = data.items[itemId];
            if (itemData && itemData.rating !== null && itemData.rating !== undefined) {
                const itemElement = document.querySelector(`input[data-item-id="${itemId}"][value="${itemData.rating}"]`);

                if (itemElement) {
                    const allRadios = document.querySelectorAll(`input[data-item-id="${itemId}"]`);
                    allRadios.forEach(radio => {
                        const estabaMarcado = radio.checked;
                        radio.checked = radio === itemElement;
                        radio.disabled = true;
                        if (radio === itemElement && !estabaMarcado) {
                            huboCambios = true;
                        }
                    });

                    const itemContainer = itemElement.closest('.item-container') || itemElement.parentElement;
                    if (itemContainer) {
                        itemContainer.classList.add('bg-blue-50');
                        setTimeout(() => {
                            itemContainer.classList.remove('bg-blue-50');
                        }, 1000);
                    }
                }

                if (!window.inspeccionEstado.items[itemId]) {
                    window.inspeccionEstado.items[itemId] = {};
                }

                const estadoPrevio = window.inspeccionEstado.items[itemId];
                const ratingPrevio = estadoPrevio.rating;

                window.inspeccionEstado.items[itemId] = {
                    ...estadoPrevio,
                    rating: itemData.rating,
                    observacion: itemData.observacion || estadoPrevio.observacion || '',
                    puntaje_maximo: itemData.puntaje_maximo || estadoPrevio.puntaje_maximo,
                    riesgo: itemData.riesgo || estadoPrevio.riesgo
                };

                if (ratingPrevio !== itemData.rating) {
                    huboCambios = true;
                }
            }
        });
    }

    if (data.observaciones !== undefined) {
        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea) {
            if (observacionesTextarea.value !== data.observaciones) {
                observacionesTextarea.value = data.observaciones;
                huboCambios = true;
            }
            observacionesTextarea.disabled = true;
        }
    }

    if (data.resumen && Object.keys(data.resumen).length > 0) {
        actualizarResumenConPuntajes(data.resumen);
        huboCambios = true;
    } else if (huboCambios) {
        recalcularResumenEncargado();
    }

    if (typeof data.confirmada_por_encargado !== 'undefined') {
        const estadoPrevioConfirmacion = Boolean(window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id]?.confirmada_por_encargado);
        const estadoNuevoConfirmacion = Boolean(data.confirmada_por_encargado);

        if (!window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id]) {
            window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id] = {};
        }
        window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id] = {
            ...window.inspeccionEstado.confirmacionesPorEstablecimiento[data.establecimiento_id],
            confirmada_por_encargado: estadoNuevoConfirmacion,
            confirmador_nombre: data.confirmador_nombre || null,
            confirmador_rol: data.confirmador_rol || null
        };

        // Guardar estado de confirmaciones en sessionStorage
        guardarEstadoConfirmaciones();

        if (estadoNuevoConfirmacion) {
            deshabilitarBotonConfirmar(data.confirmador_nombre || 'Encargado', data.confirmador_rol || 'Encargado');
        } else {
            restaurarBotonConfirmarEncargado();
        }

        if (estadoPrevioConfirmacion !== estadoNuevoConfirmacion) {
            huboCambios = true;
        }
    }

    if (huboCambios) {
        mostrarNotificacion('Inspector actualizo calificaciones', 'info');
    }

    return huboCambios;
}

function actualizarResumenConPuntajes(puntajes) {
    if (!puntajes) {
        return;
    }

    const puntajeTotal = Number(puntajes.puntaje_total ?? puntajes.puntajeTotal ?? 0);
    const puntajeMaximo = Number(puntajes.puntaje_maximo_posible ?? puntajes.puntaje_maximo ?? 0);
    const porcentaje = Number(puntajes.porcentaje_cumplimiento ?? puntajes.porcentaje ?? 0);
    const puntosCriticos = Number(puntajes.puntos_criticos_perdidos ?? puntajes.puntosCriticosPerdidos ?? 0);
    const totalItemsBackend = Number(puntajes.total_items ?? puntajes.totalItems ?? puntajes.items_totales ?? 0);
    const itemsCalificadosBackend = Number(puntajes.items_calificados ?? puntajes.itemsCalificados ?? puntajes.items ?? 0);

    const totalItems = totalItemsBackend > 0 ? totalItemsBackend : obtenerTotalItemsDisponibles();
    const itemsCalificados = itemsCalificadosBackend >= 0 ? itemsCalificadosBackend : contarItemsCalificadosLocales();

    window.inspeccionEstado.resumen = {
        ...window.inspeccionEstado.resumen,
        ...puntajes,
        puntaje_total: puntajeTotal,
        puntaje_maximo_posible: puntajeMaximo,
        porcentaje_cumplimiento: porcentaje,
        puntos_criticos_perdidos: puntosCriticos,
        total_items: totalItems,
        items_calificados: itemsCalificados
    };

    actualizarInterfazResumen();
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
    notificacion.className = `fixed top-4 right-4 p-4 rounded-lg shadow-lg z-50 transition-all duration-300 ${tipo === 'success' ? 'bg-green-500 text-white' :
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

// Funciones de seguridad reutilizables
function sanitizeText(text) {
    if (!text || typeof text !== 'string') return '';
    return text.replace(/[<>"'&]/g, function (match) {
        const escape = {
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#39;',
            '&': '&amp;'
        };
        return escape[match];
    });
}

function validateImageUrl(url) {
    if (!url || typeof url !== 'string') return null;

    // Whitelist de extensiones permitidas
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.avif'];
    const lowercaseUrl = url.toLowerCase();

    const hasValidExtension = allowedExtensions.some(ext => lowercaseUrl.includes(ext));
    if (!hasValidExtension) {
        return null;
    }

    // Limpiar caracteres peligrosos
    let cleanUrl = url.replace(/[<>"']/g, '').replace(/\\/g, "/");

    // Prevenir path traversal
    if (cleanUrl.includes('..') || cleanUrl.includes('~')) {
        return null;
    }

    return cleanUrl;
}

function createSvgIcon(pathData, className = "w-6 h-6") {
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("class", className);
    svg.setAttribute("fill", "none");
    svg.setAttribute("stroke", "currentColor");
    svg.setAttribute("viewBox", "0 0 24 24");

    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("stroke-linecap", "round");
    path.setAttribute("stroke-linejoin", "round");
    path.setAttribute("stroke-width", "2");
    path.setAttribute("d", pathData);

    svg.appendChild(path);
    return svg;
}

/**
 * Abre un modal para previsualizar una imagen, compatible con URLs y strings Base64.
 * @param {string} src La fuente de la imagen (URL o string Base64).
 * @param {string} [filename='Evidencia'] El nombre del archivo para mostrar en el título.
 */
function abrirVistaPrevia(src, filename = 'Evidencia') {
    // Determinar si el src es una cadena Base64.
    const isBase64 = src.startsWith('data:image');
    let validatedSrc = src;

    // Solo validar si NO es Base64, asumiendo que el Base64 ya es seguro.
    if (!isBase64) {
        // Asumimos que tienes funciones para validar y sanitizar.
        // Si no las tienes, puedes quitar estas líneas.
        // validatedSrc = validateImageUrl(src);
        if (!validatedSrc) {
            return;
        }
    }

    // const safeFilename = sanitizeText(filename); // Asumiendo que tienes esta función
    const safeFilename = filename;


    // Crear modal para vista previa mejorada
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-90 flex items-center justify-center z-50 p-4';
    modal.onclick = (e) => {
        if (e.target === modal) {
            cerrarModal();
        }
    };

    const container = document.createElement('div');
    container.className = 'relative max-w-4xl max-h-full bg-white rounded-lg overflow-hidden shadow-2xl flex flex-col';
    container.onclick = (e) => e.stopPropagation();

    // Función para cerrar modal
    function cerrarModal() {
        if (modal.parentNode) {
            modal.parentNode.removeChild(modal);
        }
        document.removeEventListener('keydown', handleEscape);
    }

    // Header del modal
    const header = document.createElement('div');
    header.className = 'flex items-center justify-between p-4 bg-gray-50 border-b';

    const title = document.createElement('h3');
    title.className = 'text-lg font-semibold text-gray-900';
    title.textContent = safeFilename;

    const closeButton = document.createElement('button');
    closeButton.className = 'text-gray-400 hover:text-gray-600 transition-colors';
    closeButton.onclick = cerrarModal;
    closeButton.innerHTML = `<svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg>`;

    header.appendChild(title);
    header.appendChild(closeButton);

    // Contenedor de la imagen para centrado y scroll si es necesario
    const imageContainer = document.createElement('div');
    imageContainer.className = 'p-4 flex-grow overflow-auto flex items-center justify-center';

    // Imagen
    const img = document.createElement('img');
    img.src = validatedSrc;
    img.className = 'max-w-full max-h-full object-contain'; // object-contain es mejor para previsualización
    img.style.maxHeight = 'calc(100vh - 150px)'; // Un poco más de espacio
    img.alt = 'Vista previa de ' + safeFilename;

    imageContainer.appendChild(img);

    // Footer con acciones
    const footer = document.createElement('div');
    footer.className = 'flex items-center justify-end p-4 bg-gray-50 border-t space-x-3';

    const openNewTabButton = document.createElement('a'); // Usamos 'a' para que se comporte como un link
    openNewTabButton.className = 'px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors flex items-center space-x-2';
    openNewTabButton.target = '_blank'; // Abrir en nueva pestaña
    openNewTabButton.rel = 'noopener noreferrer';

    // *** LÓGICA CLAVE PARA ABRIR EN NUEVA PESTAÑA ***
    if (isBase64) {
        // Para Base64, el href es el propio dato. El navegador lo manejará.
        openNewTabButton.href = validatedSrc;
        openNewTabButton.download = safeFilename; // Sugerir un nombre de archivo para descargar
    } else {
        // Para URLs, el href es la URL validada.
        openNewTabButton.href = validatedSrc;
    }

    openNewTabButton.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg><span>Abrir</span>`;

    const closeFooterButton = document.createElement('button');
    closeFooterButton.className = 'px-4 py-2 bg-gray-600 text-white rounded-lg hover:bg-gray-700 transition-colors';
    closeFooterButton.onclick = cerrarModal;
    closeFooterButton.textContent = 'Cerrar';

    footer.appendChild(openNewTabButton);
    footer.appendChild(closeFooterButton);

    container.appendChild(header);
    container.appendChild(imageContainer); // Usamos el contenedor de imagen
    container.appendChild(footer);
    modal.appendChild(container);
    document.body.appendChild(modal);

    // Cerrar con tecla Escape
    const handleEscape = (e) => {
        if (e.key === 'Escape') {
            e.preventDefault();
            cerrarModal();
        }
    };
    document.addEventListener('keydown', handleEscape);
}

function actualizarContadorEvidencias() {
    let totalEvidencias = 0;

    if (typeof asegurarEstadoEvidenciasCompartido === 'function') {
        totalEvidencias = asegurarEstadoEvidenciasCompartido().length;
    } else if (Array.isArray(window.evidenciasAcumuladas)) {
        totalEvidencias = window.evidenciasAcumuladas.length;
    } else if (window.inspeccionEstado && Array.isArray(window.inspeccionEstado.evidencias)) {
        totalEvidencias = window.inspeccionEstado.evidencias.length;
    }

    const etiqueta = totalEvidencias === 1 ? 'evidencia' : 'evidencias';
    const contadorChip = document.getElementById('evidencias-contador');
    if (contadorChip) {
        contadorChip.textContent = `${totalEvidencias} ${etiqueta}`;
    }

    const contadorBtn = document.getElementById('evidenciasSeleccionadas');
    if (contadorBtn) {
        if (totalEvidencias > 0) {
            contadorBtn.textContent = `Evidencias (${totalEvidencias})`;
            contadorBtn.style.backgroundColor = '#10b981';
        } else {
            contadorBtn.textContent = 'Evidencias';
            contadorBtn.style.backgroundColor = '#6b7280';
        }
    }
}

// Función para subir evidencias al servidor
async function subirEvidencias(inspeccionId, establecimientoId, fecha) {
    try {
        let evidenciasActuales = [];

        if (typeof asegurarEstadoEvidenciasCompartido === 'function') {
            evidenciasActuales = asegurarEstadoEvidenciasCompartido();
        } else if (Array.isArray(window.evidenciasAcumuladas)) {
            evidenciasActuales = window.evidenciasAcumuladas;
        } else if (window.inspeccionEstado && Array.isArray(window.inspeccionEstado.evidencias)) {
            evidenciasActuales = window.inspeccionEstado.evidencias;
        }

        if (!evidenciasActuales || evidenciasActuales.length === 0) {
            return { success: true, mensaje: 'No hay evidencias para subir' };
        }

        const formData = new FormData();
        formData.append('inspeccion_id', inspeccionId);
        formData.append('establecimiento_id', establecimientoId);
        formData.append('fecha', fecha);

        evidenciasActuales.forEach((file) => {
            formData.append('evidencias', file);
        });

        const response = await fetch('/api/inspecciones/evidencias', {
            method: 'POST',
            body: formData
        });

        const result = await response.json();

        if (!response.ok) {
            return {
                success: false,
                error: result.error || 'Error al subir evidencias'
            };
        }

        if (typeof asegurarEstadoEvidenciasCompartido === 'function') {
            window.evidenciasAcumuladas.length = 0;
            if (window.inspeccionEstado) {
                window.inspeccionEstado.evidencias = window.evidenciasAcumuladas;
            }
        } else {
            evidenciasActuales.length = 0;
        }

        if (typeof actualizarVistaEvidencias === 'function') {
            actualizarVistaEvidencias();
        } else {
            const previewContainer = document.getElementById('evidencias-preview');
            if (previewContainer) {
                previewContainer.innerHTML = '';
            }
        }

        const evidenciasInput = document.getElementById('evidencias-input');
        if (evidenciasInput) {
            evidenciasInput.value = '';
        }

        actualizarContadorEvidencias();

        return {
            success: true,
            mensaje: `${result.total} evidencias guardadas exitosamente`,
            evidencias: result.evidencias
        };

    } catch (error) {
        return {
            success: false,
            error: `Error de conexión: ${error.message}`
        };
    }
}

// Función para actualizar el resumen basado en el total de TODOS los items
function actualizarResumen() {
    // Los encargados NO deben calcular su propio resumen
    // Solo deben usar los datos que vienen del backend via socket
    if (userRole === 'Encargado') {
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

function obtenerTotalItemsDisponibles() {
    const radios = document.querySelectorAll('input[data-item-id]');
    if (!radios || radios.length === 0) {
        return window.inspeccionEstado?.resumen?.total_items || 0;
    }

    const itemsUnicos = new Set();
    radios.forEach(radio => {
        const itemId = radio.getAttribute('data-item-id');
        if (itemId) {
            itemsUnicos.add(itemId);
        }
    });

    return itemsUnicos.size;
}

function contarItemsCalificadosLocales() {
    const itemsEstado = window.inspeccionEstado?.items || {};
    return Object.values(itemsEstado).filter(item => item && item.rating !== undefined && item.rating !== null).length;
}

function recalcularResumenEncargado() {
    if (userRole !== 'Encargado') {
        actualizarResumen();
        return;
    }

    const totalItemsDisponibles = obtenerTotalItemsDisponibles();
    const itemsCalificados = contarItemsCalificadosLocales();

    window.inspeccionEstado.resumen = {
        ...window.inspeccionEstado.resumen,
        total_items: totalItemsDisponibles || window.inspeccionEstado?.resumen?.total_items || 0,
        items_calificados: itemsCalificados
    };

    actualizarInterfazResumen();
}

function actualizarResumenConPuntajes(puntajes) {
    window.inspeccionEstado.resumen = puntajes;

    // Validar que puntajes existe y tiene las propiedades necesarias
    if (!puntajes) {
        return;
    }


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
    }
}

async function cargarEstablecimientos() {
    try {

        // Buscar el select específico de index
        const establecimientoSelect = document.getElementById('establecimiento');
        if (!establecimientoSelect) {
            return true;
        }


        // Verificar el rol del usuario
        const userRole = establecimientoSelect.closest('#vista-app')?.dataset.userRole || window.userRole;

        // Para encargados, cargar su establecimiento específico
        if (userRole === 'Encargado') {
            await cargarEstablecimientoEncargado();
            return true;
        }

        // Para Inspector/Admin, poblar todos los establecimientos
        if (typeof EstablecimientosAPI !== 'undefined') {

            const exito = await EstablecimientosAPI.poblarSelect(establecimientoSelect, 'Seleccione un establecimiento');
            if (exito) {

                // Configurar evento de cambio para cargar items cuando se seleccione un establecimiento
                configurarEventoEstablecimiento(establecimientoSelect);

                return true;
            } else {
            }
        } else {
        }

        // Método alternativo directo
        const response = await fetch('/api/establecimientos');
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Limpiar y poblar el select
        establecimientoSelect.innerHTML = '<option value="">Seleccione un establecimiento</option>';

        if (data.success && Array.isArray(data.establecimientos)) {
            data.establecimientos.forEach(establecimiento => {
                const option = document.createElement('option');
                option.value = establecimiento.id;
                option.textContent = establecimiento.nombre;
                establecimientoSelect.appendChild(option);
            });

            // Configurar evento de cambio para cargar items cuando se seleccione un establecimiento
            configurarEventoEstablecimiento(establecimientoSelect);

            return true;
        } else {
            return false;
        }

    } catch (error) {

        // Buscar select para mostrar mensaje de error
        const select = document.getElementById('establecimiento');
        if (select) {
            select.innerHTML = '<option value="">Error al cargar establecimientos</option>';
        }
        return false;
    }
}

// Función auxiliar para configurar el evento de cambio del establecimiento
function configurarEventoEstablecimiento(selectElement) {
    // Remover listener anterior si existe
    const nuevoSelect = selectElement.cloneNode(true);
    selectElement.parentNode.replaceChild(nuevoSelect, selectElement);

    // Agregar el nuevo listener
    nuevoSelect.addEventListener('change', async function () {
        const establecimientoId = this.value;

        if (establecimientoId) {
            // Inicializar estado de confirmación para el nuevo establecimiento
            if (!window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId]) {
                window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId] = {
                    confirmada_por_encargado: false,
                    confirmador_nombre: null,
                    confirmador_rol: null
                };
            }

            // Deshabilitar el botón de completar inspección para el inspector
            deshabilitarBotonCompletarInspector();

            // Esperar un poco para asegurar que el DOM esté listo
            await new Promise(resolve => setTimeout(resolve, 50));

            // Cargar firmas disponibles para el establecimiento
            if (typeof cargarFirmasEstablecimiento === 'function') {
                await cargarFirmasEstablecimiento(establecimientoId);
            }

            // Esta es la lógica original para cargar items del establecimiento
            if (typeof cargarItemsEstablecimiento === 'function') {
                await cargarItemsEstablecimiento(establecimientoId);
            }

            // Unirse a la sala del establecimiento para tiempo real (IMPORTANTE para recibir eventos del encargado)
            if (socket && userRole === 'Inspector') {
                socket.emit('join_establecimiento', {
                    establecimiento_id: establecimientoId,
                    usuario_id: window.userId || 1,
                    role: userRole
                });
            }            // Cargar datos guardados en cookies si existen
            if (window.FormCookieManager) {
                const cookieManager = new window.FormCookieManager();
                if (cookieManager.hasFormData(establecimientoId)) {
                    const savedData = cookieManager.loadFormData(establecimientoId);
                    if (savedData) {
                        // Esperar un poco para que se cargue la interfaz
                        await new Promise(resolve => setTimeout(resolve, 300));

                        // Restaurar estado desde cookie
                        if (typeof restaurarEstado === 'function') {
                            restaurarEstado(savedData);
                        }

                        // Aplicar calificaciones si existen
                        if (savedData.items && Object.keys(savedData.items).length > 0) {
                            if (typeof aplicarCalificacionesAInterfaz === 'function') {
                                aplicarCalificacionesAInterfaz(savedData.items);
                            }
                        }

                        // Aplicar observaciones si existen
                        if (savedData.observaciones) {
                            const observacionesTextarea = document.getElementById('observaciones-generales');
                            if (observacionesTextarea) {
                                observacionesTextarea.value = savedData.observaciones;
                            }
                        }

                        // Actualizar resumen
                        if (typeof actualizarResumen === 'function') {
                            actualizarResumen();
                        }
                        if (typeof actualizarInterfazResumen === 'function') {
                            actualizarInterfazResumen();
                        }

                    }
                }
            }

            // IMPORTANTE: Resetear el estado de confirmación para nueva inspección
            // Independientemente de las cookies anteriores, una nueva selección de establecimiento
            // debe comenzar con confirmación pendiente
            window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId] = {
                confirmada_por_encargado: false,
                confirmador_nombre: null,
                confirmador_rol: null
            };

            // Asegurar que el botón esté deshabilitado para nueva inspección
            deshabilitarBotonCompletarInspector();
        } else {
            // Limpiar interfaz cuando no hay establecimiento seleccionado

            // Limpiar select de firmas
            const selectFirma = document.getElementById('firma-encargado-select');
            if (selectFirma) {
                selectFirma.innerHTML = '<option value="">-- Seleccione una firma --</option>';
            }
            if (typeof limpiarPreviewFirmaEncargado === 'function') {
                limpiarPreviewFirmaEncargado();
            }

            const itemsContainer = document.getElementById('items-container');
            if (itemsContainer) {
                itemsContainer.innerHTML = '';
            }

            const resumenContainer = document.getElementById('resumen-container');
            if (resumenContainer) {
                resumenContainer.innerHTML = '';
            }
        }
    });
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
    }
}

// Función para mostrar diálogo de sesión duplicada de forma segura
function mostrarDialogoSesionDuplicada() {
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50';

    // Crear container principal
    const container = document.createElement('div');
    container.className = 'bg-white dark:bg-gray-800 rounded-lg p-8 max-w-md mx-4 shadow-2xl';

    // Header con icono
    const header = document.createElement('div');
    header.className = 'flex items-center mb-6';

    const iconContainer = document.createElement('div');
    iconContainer.className = 'flex-shrink-0 w-12 h-12 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center mr-4';

    const warningIcon = createSvgIcon("M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z", "w-6 h-6 text-red-600 dark:text-red-400");
    iconContainer.appendChild(warningIcon);

    const textContainer = document.createElement('div');

    const title = document.createElement('h3');
    title.className = 'text-lg font-bold text-gray-900 dark:text-gray-100';
    title.textContent = 'Sesión Duplicada';

    const subtitle = document.createElement('p');
    subtitle.className = 'text-sm text-gray-600 dark:text-gray-300';
    subtitle.textContent = 'El usuario ya está en línea';

    textContainer.appendChild(title);
    textContainer.appendChild(subtitle);

    header.appendChild(iconContainer);
    header.appendChild(textContainer);

    // Mensaje principal
    const messageContainer = document.createElement('div');
    messageContainer.className = 'mb-6';

    const message = document.createElement('p');
    message.className = 'text-gray-700 dark:text-gray-200 leading-relaxed';
    message.textContent = 'Su sesión ha sido cerrada porque se detectó que el mismo usuario está activo en otro dispositivo o navegador. Solo se permite una sesión activa por usuario.';

    messageContainer.appendChild(message);

    // Botón de acción
    const buttonContainer = document.createElement('div');
    buttonContainer.className = 'flex justify-center';

    const acceptButton = document.createElement('button');
    acceptButton.className = 'bg-red-600 text-white px-6 py-3 rounded-lg hover:bg-red-700 transition-colors font-semibold';
    acceptButton.textContent = 'Entendido';
    acceptButton.onclick = () => {
        window.location.href = '/api/auth/logout';
    };

    buttonContainer.appendChild(acceptButton);

    // Ensamblar todo
    container.appendChild(header);
    container.appendChild(messageContainer);
    container.appendChild(buttonContainer);
    modal.appendChild(container);

    document.body.appendChild(modal);

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
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const data = await response.json();

        // Verificar estructura de respuesta
        let establecimientos = [];
        if (data.success && Array.isArray(data.establecimientos)) {
            establecimientos = data.establecimientos;
        } else if (Array.isArray(data)) {
            // Fallback para formato directo de array
            establecimientos = data;
        }

        if (establecimientos && establecimientos.length > 0) {
            // Seleccionar automáticamente el primer establecimiento del encargado
            const select = document.getElementById('establecimiento');
            if (select && establecimientos[0]) {

                // Limpiar y agregar solo el establecimiento del encargado
                select.innerHTML = '';
                const option = document.createElement('option');
                option.value = establecimientos[0].id;
                option.textContent = establecimientos[0].nombre;
                option.selected = true;
                select.appendChild(option);

                // Cargar items del establecimiento
                await cargarItemsEstablecimiento(establecimientos[0].id);

                // Cargar firma del encargado para este establecimiento
                if (typeof cargarFirmasEstablecimiento === 'function') {
                    await cargarFirmasEstablecimiento(establecimientos[0].id);
                }

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
        } else {
            const select = document.getElementById('establecimiento');
            if (select) {
                select.innerHTML = '<option value="">No tiene establecimientos asignados</option>';
            }
        }
    } catch (error) {
        const select = document.getElementById('establecimiento');
        if (select) {
            select.innerHTML = '<option value="">Error al cargar establecimiento</option>';
        }
    }
}

async function cargarDatosTiempoRealEstablecimiento(establecimientoId) {
    // Cargar datos actuales de tiempo real para un establecimiento (para encargados)
    if (userRole !== 'Encargado' && userRole !== 'Jefe de Establecimiento') return;

    try {
        const response = await fetch(`/api/inspecciones/tiempo-real/establecimiento/${establecimientoId}`);
        if (response.ok) {
            const data = await response.json();
            if (data && Object.keys(data).length > 0) {
                actualizarDatosTiempoRealCompletos(data);
                mostrarNotificacion('Datos en tiempo real cargados', 'success');

                // Verificar si ya fue confirmada
                if (data.confirmada_por_encargado) {
                    setTimeout(() => {
                        deshabilitarBotonConfirmar(data.confirmador_nombre, data.confirmador_rol);
                    }, 500);
                }
            } else {
            }
        }
    } catch (error) {
    }
}

function crearCategoriaHTML(categoria) {
    const div = document.createElement('div');
    div.className = 'mb-8 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl shadow-sm overflow-hidden';

    // Verificar que categoria.items existe y es un array
    if (!categoria.items || !Array.isArray(categoria.items)) {
        categoria.items = [];
    }

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

        // Crear HTML para los radio buttons (mobile-friendly)
        const radioButtonsHTML = Array.from({ length: item.puntaje_maximo + 1 }, (_, i) => `
            <label class="flex flex-col items-center p-3 rounded-lg transition-all duration-200 cursor-pointer group ${userRole === 'Encargado' ? 'opacity-75' : ''} ${riesgoClasses[item.riesgo] || ''}">
                <input type="radio" name="item_${item.id}" value="${i}"
                       class="radio-item w-6 h-6 text-blue-600 bg-gray-100 border-2 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600 checked:bg-blue-600 checked:border-blue-600 checked:ring-2 checked:ring-blue-200 transition-all duration-200 mb-2"
                       data-item-id="${item.id}"
                       data-puntaje-maximo="${item.puntaje_maximo}"
                       data-riesgo="${item.riesgo}"
                       ${userRole === 'Encargado' ? 'disabled' : ''}>
                <span class="text-lg font-bold text-slate-700 dark:text-slate-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">${i}</span>
            </label>
        `).join('');

        itemsHTML += `
            <div class="p-6 border-b border-slate-100 dark:border-slate-700 last:border-b-0 ${riesgoClasses[item.riesgo] || ''}">
                <!-- Header del item -->
                <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between mb-4">
                    <div class="flex items-center space-x-3 mb-2 sm:mb-0">
                        <span class="font-mono text-sm font-semibold text-slate-700 dark:text-slate-300 bg-slate-100 dark:bg-slate-700 px-2 py-1 rounded">${item.codigo}</span>
                        <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${riesgoBadge[item.riesgo] || ''}">${item.riesgo}</span>
                    </div>
                    <div class="text-xs text-slate-500 dark:text-slate-400">
                        Puntaje máximo: <span class="font-semibold">${item.puntaje_maximo}</span> puntos
                    </div>
                </div>

                <!-- Descripción del item -->
                <p class="text-sm text-slate-900 dark:text-slate-100 leading-relaxed mb-4">${item.descripcion_personalizada || item.descripcion_base}</p>

                <!-- Puntuación - Mobile First Grid -->
                <div class="space-y-3">
                    <h4 class="text-sm font-medium text-slate-700 dark:text-slate-300">Seleccione puntuación:</h4>
                    <div class="grid grid-cols-5 sm:grid-cols-5 md:grid-cols-7 gap-0 sm:gap-2">
                        ${radioButtonsHTML}
                    </div>
                    ${userRole === 'Encargado' ? '<p class="text-xs text-slate-500 mt-3 italic text-center">Vista en tiempo real</p>' : ''}
                </div>
            </div>
        `;
    });

    div.innerHTML = `
        <!-- Header de la categoría -->
        <div class="bg-gradient-to-r from-slate-50 to-slate-100 dark:from-slate-800 dark:to-slate-700 px-6 py-4 border-b border-slate-200 dark:border-slate-600">
            <div class="flex items-center justify-between">
                <h3 class="text-xl font-bold text-slate-900 dark:text-white">${categoria.nombre}</h3>
                <span class="text-sm text-slate-500 dark:text-slate-400">${categoria.items.length} item(s)</span>
            </div>
            ${categoria.descripcion ? `<p class="text-sm text-slate-600 dark:text-slate-300 mt-1">${categoria.descripcion}</p>` : ''}
        </div>

        <!-- Items en formato de cards -->
        <div class="divide-y divide-slate-200 dark:divide-slate-700">
            ${itemsHTML}
        </div>
    `;

    return div;
}

function configurarEventosItems() {
    // Event listeners para radios - optimizado para detectar cambios reales
    document.querySelectorAll('.radio-item').forEach(radio => {
        radio.addEventListener('change', function () {
            const itemId = this.getAttribute('data-item-id');
            const rating = parseInt(this.value);
            const riesgo = this.dataset.riesgo;
            const maxPuntaje = parseInt(this.dataset.puntajeMaximo);

            // Verificar si realmente cambió el valor
            const valorAnterior = window.inspeccionEstado.items[itemId]?.rating;
            if (valorAnterior === rating) {
                return; // No hay cambio real, no hacer nada
            }

            if (userRole === 'Inspector' || userRole === 'Administrador') {
                reiniciarConfirmacionEncargadoPorCambio();
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
    const observer = new MutationObserver(function (mutations) {
        mutations.forEach(function (mutation) {
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

    // Restaurar estado global (preservando evidencias existentes)
    const evidenciasExistentes = window.inspeccionEstado.evidencias || [];
    window.inspeccionEstado = { ...window.inspeccionEstado, ...estado };
    // Preservar evidencias locales si no hay evidencias válidas en el estado restaurado
    if (!estado.evidencias || estado.evidencias.length === 0) {
        window.inspeccionEstado.evidencias = evidenciasExistentes;
    }
}

// Función para aplicar calificaciones guardadas a la interfaz
function aplicarCalificacionesAInterfaz(items, intento = 0) {
    const MAX_INTENTOS = 8;

    if (!items || Object.keys(items).length === 0) {
        return {};
    }

    const pendientes = {};

    Object.keys(items).forEach(itemId => {
        const itemData = items[itemId];

        // Aplicar rating
        if (itemData.rating !== undefined && itemData.rating !== null) {
            const ratingInputs = document.querySelectorAll(`input[name="item_${itemId}"]`);

            if (!ratingInputs || ratingInputs.length === 0) {
                pendientes[itemId] = itemData;
                return;
            }

            ratingInputs.forEach(input => {
                if (parseInt(input.value) === itemData.rating) {
                    input.checked = true;

                    // Actualizar visualmente el contenedor del item
                    const itemContainer = input.closest('.item-container');
                    if (itemContainer) {
                        // Remover clases existentes
                        itemContainer.classList.remove('rating-0', 'rating-1', 'rating-2', 'rating-3');
                        // Agregar nueva clase
                        itemContainer.classList.add(`rating-${itemData.rating}`);
                    }
                } else {
                    // Asegurar que otros inputs estén desmarcados
                    input.checked = false;
                }
            });
        }

        // Aplicar observación específica del item
        if (itemData.observacion) {
            const observacionInput = document.getElementById(`observacion_${itemId}`);
            if (observacionInput) {
                observacionInput.value = itemData.observacion;
            }
        }
    });

    // Devolver los elementos que no se pudieron aplicar (para reintentos externos)
    return pendientes;
}

// Función para actualizar la interfaz del resumen
function actualizarInterfazResumen() {
    const resumen = window.inspeccionEstado.resumen;
    if (!resumen) return;

    const puntajeActual = document.getElementById('puntaje-actual');
    const puntajeMaximoEl = document.getElementById('puntaje-maximo');
    const porcentajeEl = document.getElementById('porcentaje-cumplimiento');
    const criticosEl = document.getElementById('puntos-criticos');
    const progresoEl = document.getElementById('progreso-items');
    const barraProgreso = document.getElementById('barra-progreso');

    const puntajeTotal = Number(resumen.puntaje_total ?? resumen.puntajeTotal ?? 0) || 0;
    const puntajeMaximo = Number(resumen.puntaje_maximo_posible ?? resumen.puntaje_maximo ?? 0) || 0;
    const porcentaje = Number(resumen.porcentaje_cumplimiento ?? resumen.porcentaje ?? 0) || 0;
    const puntosCriticos = Number(resumen.puntos_criticos_perdidos ?? resumen.puntosCriticosPerdidos ?? 0) || 0;

    if (puntajeActual) puntajeActual.textContent = puntajeTotal.toFixed(1);
    if (puntajeMaximoEl) puntajeMaximoEl.textContent = puntajeMaximo.toFixed(1);
    if (porcentajeEl) {
        porcentajeEl.textContent = porcentaje.toFixed(1) + '%';
        if (porcentaje >= 90) {
            porcentajeEl.className = 'text-green-600 font-bold';
        } else if (porcentaje >= 70) {
            porcentajeEl.className = 'text-yellow-600 font-bold';
        } else {
            porcentajeEl.className = 'text-red-600 font-bold';
        }
    }
    if (criticosEl) criticosEl.textContent = puntosCriticos.toFixed(1);

    let totalItemsRegistrados = Number(resumen.total_items ?? resumen.items_totales ?? resumen.totalItems ?? 0) || 0;
    let totalItems = totalItemsRegistrados > 0 ? totalItemsRegistrados : obtenerTotalItemsDisponibles();
    let itemsCalificados = Number(resumen.items_calificados ?? resumen.itemsCalificados ?? 0);
    if (Number.isNaN(itemsCalificados)) {
        itemsCalificados = 0;
    }
    if (!itemsCalificados) {
        itemsCalificados = contarItemsCalificadosLocales();
    }

    if (totalItems === 0 && itemsCalificados > 0) {
        totalItems = itemsCalificados;
    }

    window.inspeccionEstado.resumen.total_items = totalItems;
    window.inspeccionEstado.resumen.items_calificados = itemsCalificados;

    if (progresoEl) {
        progresoEl.textContent = `${itemsCalificados}/${totalItems} items`;
    }

    if (barraProgreso) {
        const progresoPorcentaje = totalItems > 0 ? Math.min(100, (itemsCalificados / totalItems) * 100) : 0;
        barraProgreso.style.width = `${progresoPorcentaje}%`;
    }

}

// Función para cargar establecimiento y sus items si no están cargados
async function cargarEstablecimientoYItems(establecimientoId) {
    const select = document.getElementById('establecimiento');
    if (select && select.value !== establecimientoId.toString()) {
        select.value = establecimientoId;
        await cargarItemsEstablecimiento(establecimientoId);
    }
}

async function guardarEstadoTemporal(forzarEmision = false) {
    try {
        // Solo proceder si hay cambios pendientes o se fuerza la emisión
        if (!hayCambiosPendientes && !forzarEmision) {
            return;
        }

        // Obtener observaciones actuales
        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea) {
            window.inspeccionEstado.observaciones = observacionesTextarea.value;
        }

        // Calcular resumen actualizado
        actualizarResumen();

        // Guardar en cookie del formulario (según pedido.txt)
        if (window.inspeccionEstado.establecimiento_id && window.FormCookieManager) {
            if (!window.formCookieManager) {
                window.formCookieManager = new window.FormCookieManager();
            }
            window.formCookieManager.saveFormData(
                window.inspeccionEstado.establecimiento_id,
                window.inspeccionEstado
            );
        }

        // Guardar en servidor (cookie del formulario) SOLO si hay cambios
        if (hayCambiosPendientes || forzarEmision) {
            // Crear una copia del estado SIN evidencias para enviar al servidor
            // Las evidencias son objetos File que no son serializables
            const estadoParaServidor = {
                ...window.inspeccionEstado,
                evidencias: [] // No enviar evidencias al servidor, solo metadata
            };

            await fetch('/api/inspecciones/temporal', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(estadoParaServidor)
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

                const confirmaciones = window.inspeccionEstado.confirmacionesPorEstablecimiento || {};
                const estadoConfirmacionActual = confirmaciones[window.inspeccionEstado.establecimiento_id] || {};
                datosEmitir.confirmada_por_encargado = Boolean(estadoConfirmacionActual.confirmada_por_encargado);
                datosEmitir.confirmador_nombre = estadoConfirmacionActual.confirmador_nombre || null;
                datosEmitir.confirmador_rol = estadoConfirmacionActual.confirmador_rol || null;


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

            } else {
            }
        }
    } catch (error) {
    }
}

// Función para sincronizar establecimiento inmediatamente (sin restricciones de tiempo)
async function sincronizarEstablecimientoInmediatamente(establecimientoId) {
    try {
        // Primero intentar obtener datos sincronizados del servidor
        const syncResponse = await fetch(`/api/inspecciones/sincronizado/establecimiento/${establecimientoId}`);
        if (syncResponse.ok) {
            const estadoSincronizado = await syncResponse.json();
            if (estadoSincronizado && Object.keys(estadoSincronizado).length > 0) {
                // Aplicar el estado sincronizado inmediatamente
                await aplicarEstadoSincronizado(estadoSincronizado);
                return true;
            }
        }

        // Si no hay datos sincronizados, intentar recuperar datos temporales del establecimiento
        try {
            const tempResponse = await fetch('/api/inspecciones/temporal/establecimiento/' + establecimientoId);
            if (tempResponse.ok) {
                const estadoTemporal = await tempResponse.json();
                if (estadoTemporal && Object.keys(estadoTemporal).length > 0) {
                    // Aplicar el estado temporal
                    await aplicarEstadoSincronizado(estadoTemporal);
                    mostrarNotificacion('Datos temporales cargados desde otro inspector', 'info');
                    return true;
                }
            }
        } catch (tempError) {
            console.error('Error cargando datos temporales:', tempError);
        }

        return false;
    } catch (syncError) {
        console.error('Error en sincronización inmediata:', syncError);
        return false;
    }
}

// Función para aplicar estado sincronizado de manera robusta
async function aplicarEstadoSincronizado(estado) {
    try {
        // Restaurar estado completo
        restaurarEstado(estado);

        // Si hay un establecimiento seleccionado, cargar su interfaz
        if (estado.establecimiento_id) {
            await cargarEstablecimientoYItems(estado.establecimiento_id);

            // Esperar un poco más para que se cargue completamente la interfaz
            await new Promise(resolve => setTimeout(resolve, 500));

            // Aplicar todas las calificaciones guardadas a la interfaz con más intentos
            if (estado.items && Object.keys(estado.items).length > 0) {
                await aplicarCalificacionesConReintentos(estado.items, 15); // Más intentos
            }

            // Aplicar observaciones
            if (estado.observaciones) {
                const observacionesTextarea = document.getElementById('observaciones-generales');
                if (observacionesTextarea) {
                    observacionesTextarea.value = estado.observaciones;
                }
            }

            // Aplicar evidencias si existen
            if (estado.evidencias && estado.evidencias.length > 0) {
                mostrarEvidenciasSeleccionadas();
                actualizarContadorEvidencias();
            }

            // Actualizar resumen y barra de progreso
            actualizarResumen();
            actualizarInterfazResumen();

            // Forzar actualización visual de la barra de progreso
            setTimeout(() => {
                actualizarInterfazResumen();
            }, 200);
        }

        // Verificar estado de confirmación para encargados/jefes
        if (userRole === 'Encargado' || userRole === 'Jefe de Establecimiento') {
            if (estado.confirmada_por_encargado) {
                setTimeout(() => {
                    deshabilitarBotonConfirmar(estado.confirmador_nombre, estado.confirmador_rol);
                }, 500);
            } else {
                setTimeout(() => {
                    restaurarBotonConfirmarEncargado();
                }, 500);
            }
        }

        // Verificar estado de confirmación para inspectores
        if ((userRole === 'Inspector' || userRole === 'Administrador') && estado.confirmada_por_encargado) {
            const btnCompletar = document.querySelector('button[value="completar"]');
            if (btnCompletar) {
                btnCompletar.disabled = false;
                btnCompletar.classList.remove('opacity-50', 'cursor-not-allowed');
            }
        }

    } catch (error) {
        console.error('Error aplicando estado sincronizado:', error);
    }
}

// Función mejorada para aplicar calificaciones con más reintentos y mejor lógica
async function aplicarCalificacionesConReintentos(items, maxIntentos = 15, delay = 200) {
    for (let intento = 0; intento < maxIntentos; intento++) {
        try {
            const pendientes = aplicarCalificacionesAInterfaz(items, 0); // Sin reintentos internos

            if (!pendientes || Object.keys(pendientes).length === 0) {
                // Todas las calificaciones aplicadas exitosamente
                return true;
            }

            // Si quedan pendientes, esperar y reintentar
            if (intento < maxIntentos - 1) {
                await new Promise(resolve => setTimeout(resolve, delay));
            }
        } catch (error) {
            console.error(`Error en intento ${intento + 1}:`, error);
        }
    }

    console.warn('No se pudieron aplicar todas las calificaciones después de', maxIntentos, 'intentos');
    return false;
}

// Función para mostrar estado de sincronización de forma segura
function mostrarEstadoSincronizacion(mensaje, progreso = false) {
    const statusElement = document.getElementById('sync-status');
    if (statusElement) {
        // Limpiar contenido anterior
        statusElement.innerHTML = '';

        // Crear span de forma segura
        const span = document.createElement('span');
        if (progreso) {
            span.className = 'text-blue-600';
            span.textContent = '[SYNC] ' + sanitizeText(mensaje);
        } else {
            span.className = 'text-green-600';
            span.textContent = '✅ ' + sanitizeText(mensaje);
            setTimeout(() => {
                statusElement.innerHTML = '';
            }, 5000);
        }

        statusElement.appendChild(span);
    }
}

// Función para limpiar datos temporales completamente
async function limpiarDatosTemporalesCompleto() {
    try {
        // Limpiar datos del servidor
        await fetch('/api/inspecciones/temporal', {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json',
            }
        });

        // Limpiar estado local
        window.inspeccionEstado = {
            establecimiento_id: null,
            items: {},
            evidencias: [],
            firma_inspector: null,
            firma_encargado: null,
            observaciones: '',
            encargado_aprobo: false,
            inspector_firmo: false,
            confirmacionesPorEstablecimiento: {}, // Nuevo: estado de confirmación por establecimiento
            confirmador_nombre: null,
            confirmador_rol: null,
            resumen: { puntaje_total: 0, puntaje_maximo_posible: 0, porcentaje_cumplimiento: 0, puntos_criticos_perdidos: 0 }
        };

        // Limpiar interfaz
        const selectEstablecimiento = document.getElementById('establecimiento');
        if (selectEstablecimiento) {
            selectEstablecimiento.value = '';
        }

        const categoriasContainer = document.getElementById('categorias-container');
        if (categoriasContainer) {
            categoriasContainer.innerHTML = '<p class="text-gray-500">Seleccione un establecimiento para ver los items de evaluación</p>';
        }

        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea) {
            observacionesTextarea.value = '';
        }

        // Limpiar evidencias
        const evidenciasContainer = document.getElementById('evidencias-seleccionadas');
        if (evidenciasContainer) {
            evidenciasContainer.innerHTML = '';
        }

        // Limpiar firmas
        const firmaInspectorPreview = document.getElementById('preview-firma-inspector');
        const firmaEncargadoPreview = document.getElementById('preview-firma-encargado');

        if (firmaInspectorPreview) {
            firmaInspectorPreview.innerHTML = '<p class="text-gray-500">No hay firma del inspector</p>';
        }
        if (firmaEncargadoPreview) {
            firmaEncargadoPreview.innerHTML = '<p class="text-gray-500">No hay firma del encargado</p>';
        }

        // Actualizar resumen
        actualizarInterfazResumen();

        // Limpiar cookies del formulario para el establecimiento actual
        if (window.FormCookieManager && window.inspeccionEstado.establecimiento_id) {
            const cookieManager = new window.FormCookieManager();
            cookieManager.clearFormData(window.inspeccionEstado.establecimiento_id);
        }

        // Detener autosave
        detenerAutosave();

        // Restaurar botón de confirmación para futuros flujos
        restaurarBotonConfirmarEncargado();


    } catch (error) {
    }
}

// Función para recuperar estado temporal con sincronización mejorada
async function recuperarEstadoTemporal() {
    try {
        // Primero intentar recuperar estado del usuario actual
        let response = await fetch('/api/inspecciones/temporal');
        let estado = null;

        if (response.ok) {
            const result = await response.json();
            estado = result.data || result; // Manejar tanto formato {data: ...} como directo
        }

        // Si no hay estado personal Y es Encargado con establecimiento seleccionado,
        // intentar obtener estado sincronizado del establecimiento (SIN restricciones de tiempo)
        if ((!estado || Object.keys(estado).length === 0) && userRole === 'Encargado') {
            const establecimientoId = window.inspeccionEstado?.establecimiento_id;

            if (establecimientoId) {
                // Para reconexión, sincronizar inmediatamente sin restricciones de tiempo
                try {
                    const syncResponse = await fetch(`/api/inspecciones/sincronizado/establecimiento/${establecimientoId}`);
                    if (syncResponse.ok) {
                        const estadoSincronizado = await syncResponse.json();
                        if (estadoSincronizado && Object.keys(estadoSincronizado).length > 0) {
                            estado = estadoSincronizado;
                            mostrarNotificacion('Estado sincronizado automáticamente', 'success');
                        }
                    }
                } catch (syncError) {
                    console.error('Error en sincronización automática:', syncError);
                }
            }
        }

        if (estado && Object.keys(estado).length > 0) {
            // Usar la nueva función robusta para aplicar el estado
            await aplicarEstadoSincronizado(estado);
        } else {
            // No hay estado que recuperar
        }
    } catch (error) {
        console.error('Error recuperando estado temporal:', error);
    }
}

function iniciarAutosave() {

    // Autosave de respaldo cada 5 segundos SOLO si hay cambios pendientes
    // El guardado principal es inmediato en cada cambio
    // Para Encargados, reducir frecuencia ya que solo leen datos
    const interval = userRole === 'Encargado' ? 15000 : AUTOSAVE_INTERVAL; // 15s para Encargados, 5s para Inspectores

    autoSaveInterval = setInterval(() => {
        if (hayCambiosPendientes && userRole === 'Inspector') {
            guardarEstadoTemporal();
        }
    }, interval);
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
        <div class="bg-white dark:bg-gray-800 rounded-lg p-6 max-w-md mx-4 shadow-xl">
            <h3 class="text-lg font-semibold mb-4 text-gray-900 dark:text-gray-100">Sesión por expirar</h3>
            <p class="text-gray-600 dark:text-gray-300 mb-6">Su sesión expirará en 2 minutos debido a inactividad. ¿Desea continuar?</p>
            <div class="flex justify-end gap-3">
                <button id="cerrar-sesion-btn" class="px-4 py-2 bg-gray-500 hover:bg-gray-600 text-white rounded transition-colors">Cerrar sesión</button>
                <button id="continuar-sesion-btn" class="px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded transition-colors">Continuar</button>
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



function configurarInterfazPorRol() {
    if (userRole === 'Encargado' || userRole === 'Jefe de Establecimiento') {
        // Ocultar campos que el encargado/jefe no puede usar
        const camposOcultar = [
            '#evidencias-container',
            '#firma-inspector-area'
        ];

        camposOcultar.forEach(selector => {
            const elemento = document.querySelector(selector);
            if (elemento) {
                elemento.style.display = 'none';
            }
        });

        // Ocultar botones que NO sean el de confirmar
        const botonesSubmit = document.querySelectorAll('button[type="submit"]');
        botonesSubmit.forEach(boton => {
            // Solo ocultar botones que NO sean el de confirmar
            if (boton.value !== 'confirmar') {
                boton.style.display = 'none';
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

        // NUEVO FLUJO DE FIRMAS:
        // Solo se puede "completar" cuando ambas firmas están confirmadas Y todos los checklist están marcados

        // VALIDACIÓN: Verificar que todos los items del checklist estén marcados
        const itemIds = new Set();
        document.querySelectorAll('input[type="radio"][data-item-id]').forEach(radio => {
            itemIds.add(radio.getAttribute('data-item-id'));
        });
        const totalItemsChecklist = itemIds.size;
        const itemsMarcados = Object.keys(window.inspeccionEstado.items || {}).length;

        const todosChecklistMarcados = itemsMarcados >= totalItemsChecklist;

        if (completar && !todosChecklistMarcados) {
            mostrarNotificacion(`Debe marcar todos los elementos del checklist antes de completar la inspección. Faltan ${totalItemsChecklist - itemsMarcados} elementos.`, 'warning');
            return; // No continuar con el guardado
        }

        // Determinar la acción real basada en el estado de las firmas
        let accionReal = 'guardar'; // Por defecto siempre guardar

        if (completar && userRole === 'Inspector') {
            // Solo marcar como "completar" si ambas firmas están realmente confirmadas
            if (window.inspeccionEstado.encargado_aprobo && window.inspeccionEstado.inspector_firmo) {
                accionReal = 'completar';
            } else {
                // Si no tiene ambas firmas, guardar como borrador aunque haya clickeado "completar"
                accionReal = 'guardar';

                if (!window.inspeccionEstado.encargado_aprobo) {
                    mostrarNotificacion('El encargado debe aprobar la inspección primero', 'warning');
                }

                if (!window.inspeccionEstado.inspector_firmo) {
                    mostrarNotificacion('Debe confirmar su firma antes de guardar la inspección', 'warning');
                }
            }
        }


        // Mostrar diálogo de confirmación
        const titulo = accionReal === 'completar' ? 'Guardar Inspección Completa' : 'Guardar Borrador';
        let mensaje;

        if (accionReal === 'completar') {
            mensaje = 'La inspección será guardada con ambas firmas de aprobación. ¿Continuar?';
        } else {
            mensaje = '¿Está seguro que desea guardar el borrador de la inspección?';
        }

        const confirmado = await mostrarDialogoConfirmacion(
            titulo,
            mensaje,
            accionReal === 'completar' ? 'Guardar Completa' : 'Guardar Borrador',
            'Cancelar'
        );

        if (!confirmado) {
            return; // Usuario canceló
        }

        // Preparar datos para enviar
        const datosEnvio = {
            establecimiento_id: window.inspeccionEstado.establecimiento_id,
            fecha: document.getElementById('fecha').value,
            observaciones: window.inspeccionEstado.observaciones,
            items: window.inspeccionEstado.items,
            accion: accionReal  // Usar la acción determinada, no la solicitada
        };

        // SIEMPRE enviar las firmas disponibles (el backend validará si son necesarias)
        if (window.inspeccionEstado.firma_encargado && window.inspeccionEstado.firma_encargado !== null) {
            datosEnvio.firma_encargado = window.inspeccionEstado.firma_encargado;
        }

        if (window.inspeccionEstado.firma_inspector && window.inspeccionEstado.firma_inspector !== null) {
            datosEnvio.firma_inspector = window.inspeccionEstado.firma_inspector;
        }

        // Preparar evidencias para el envío

        // Agregar evidencias si existen
        if (window.inspeccionEstado.evidencias && window.inspeccionEstado.evidencias.length > 0) {
            datosEnvio.evidencias = await Promise.all(
                window.inspeccionEstado.evidencias.map(async (evidencia, index) => {
                    try {
                        // Convertir archivo a base64
                        const base64Data = await convertirArchivoABase64(evidencia);
                        return {
                            name: evidencia.name,
                            type: evidencia.type,
                            data: base64Data
                        };
                    } catch (error) {
                        return null;
                    }
                })
            );

            // Filtrar evidencias nulas (errores)
            datosEnvio.evidencias = datosEnvio.evidencias.filter(ev => ev !== null);
        }

        // Agregar inspeccion_id si existe (para actualizar inspección existente)
        if (window.inspeccionEstado.inspeccion_id) {
            datosEnvio.inspeccion_id = window.inspeccionEstado.inspeccion_id;
        }


        const response = await fetch('/api/inspecciones', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(datosEnvio)
        });

        const result = await response.json();

        if (response.ok) {
            // Guardar ID de inspección para futuras operaciones
            if (result.inspeccion_id) {
                window.inspeccionEstado.inspeccion_id = result.inspeccion_id;
            }

            // Subir evidencias si las hay
            let evidenciasResultado = { success: true, mensaje: "No hay evidencias para subir" };
            if (window.inspeccionEstado.evidencias && window.inspeccionEstado.evidencias.length > 0) {
                evidenciasResultado = await subirEvidencias(
                    result.inspeccion_id,
                    datosEnvio.establecimiento_id,
                    datosEnvio.fecha
                );
            }

            // Mostrar notificación principal
            mostrarNotificacion(result.mensaje, 'success');

            // Mostrar notificación de evidencias si corresponde
            if (evidenciasResultado.success && evidenciasResultado.mensaje !== "No hay evidencias para subir") {
                setTimeout(() => {
                    mostrarNotificacion(evidenciasResultado.mensaje, 'success');
                }, 1000);
            } else if (!evidenciasResultado.success) {
                setTimeout(() => {
                    mostrarNotificacion(`Error con evidencias: ${evidenciasResultado.error}`, 'warning');
                }, 1000);
            }

            // Limpiar datos temporales si el backend lo indica o si se completó
            if (result.limpiar_temporal || accionReal === 'completar') {
                // Guardar el estado de las firmas antes de limpiar
                const estadoFirmasAntesLimpieza = {
                    encargado_aprobo: window.inspeccionEstado.encargado_aprobo,
                    inspector_firmo: window.inspeccionEstado.inspector_firmo,
                    firma_encargado: window.inspeccionEstado.firma_encargado,
                    firma_inspector: window.inspeccionEstado.firma_inspector
                };

                await limpiarDatosTemporalesCompleto();

                // Restaurar el estado de las firmas para evitar problemas en la interfaz
                // Esto es temporal hasta que se confirme que todo funciona correctamente
                setTimeout(() => {
                    if (window.inspeccionEstado) {
                        window.inspeccionEstado.encargado_aprobo = estadoFirmasAntesLimpieza.encargado_aprobo;
                        window.inspeccionEstado.inspector_firmo = estadoFirmasAntesLimpieza.inspector_firmo;
                        window.inspeccionEstado.firma_encargado = estadoFirmasAntesLimpieza.firma_encargado;
                        window.inspeccionEstado.firma_inspector = estadoFirmasAntesLimpieza.firma_inspector;
                    }
                }, 100);

                // Mostrar notificación adicional
                setTimeout(() => {
                    mostrarNotificacion('✅ Datos temporales limpiados - Ya puede crear una nueva inspección', 'info');
                }, 2000);
            } else {
                // Para borradores, actualizar la interfaz
                actualizarInterfazFirmas();
            }

            // Si se completó, unirse a la inspección para tiempo real
            if (accionReal === 'completar' && result.inspeccion_id) {
                unirseAInspeccion(result.inspeccion_id);
            }

        } else {
            // Error del backend
            throw new Error(result.error || 'Error al guardar inspección');
        }

    } catch (error) {
        mostrarNotificacion(error.message || 'Error al guardar inspección', 'error');
    }
}

// Función específica para firma del inspector (después de que el encargado aprobó)
async function firmarComoInspector() {
    if (userRole !== 'Inspector') {
        mostrarNotificacion('Solo el inspector puede usar esta función', 'error');
        return;
    }

    const firmaData = window.inspeccionEstado.firma_inspector;
    if (!firmaData) {
        mostrarNotificacion('Debe cargar su firma primero', 'error');
        return;
    }

    if (!window.inspeccionEstado.encargado_aprobo) {
        mostrarNotificacion('El encargado debe aprobar la inspección primero', 'error');
        return;
    }

    try {
        // Marcar que el inspector ya firmó
        window.inspeccionEstado.firma_inspector = firmaData;
        window.inspeccionEstado.inspector_firmo = true;

        mostrarNotificacion('Firma del inspector registrada exitosamente', 'success');

        // Actualizar interfaz para mostrar que ya se puede guardar
        actualizarInterfazFirmas();

        // Actualizar área de firma del inspector
        const firmaInspectorArea = document.getElementById('firma-inspector-area');
        if (firmaInspectorArea) {
            const inputFirma = document.getElementById('firma-inspector');
            if (inputFirma) inputFirma.style.display = 'none';

            const h3 = firmaInspectorArea.querySelector('h3');
            if (h3) h3.innerHTML = '<span class="text-green-600">✓ Inspector ha firmado</span>';
        }

        // Habilitar botón de guardar inspección
        const btnGuardar = document.querySelector('button[value="completar"], button[value="guardar"]');
        if (btnGuardar) {
            btnGuardar.disabled = false;
            btnGuardar.classList.remove('opacity-50', 'cursor-not-allowed');
            btnGuardar.textContent = 'Guardar Inspección';
        }

    } catch (error) {
        mostrarNotificacion(error.message || 'Error al registrar firma', 'error');
    }
}

// Función para actualizar la interfaz según el estado de las firmas
function actualizarInterfazFirmas() {

    const firmaEncargadoArea = document.getElementById('firma-encargado-area');
    const firmaInspectorArea = document.getElementById('firma-inspector-area');
    const btnCompletar = document.querySelector('button[value="completar"]');
    const btnGuardar = document.querySelector('button[value="guardar"]');
    const firmaEncargadoContainer = document.getElementById('firma-encargado-container');

    // Para inspectores
    if (userRole === 'Inspector') {

        // Actualizar área de firma del inspector
        if (firmaInspectorArea) {
            const inputFirma = document.getElementById('firma-inspector');
            const previewFirma = document.getElementById('preview-firma-inspector');

            if (window.inspeccionEstado.inspector_firmo) {
                if (inputFirma) inputFirma.style.display = 'none';
                const h3 = firmaInspectorArea.querySelector('h3');
                if (h3) h3.innerHTML = '<span class="text-green-600">✓ Inspector ha firmado</span>';
            } else if (window.inspeccionEstado.encargado_aprobo) {
                // Mostrar mensaje que ahora puede firmar, pero solo si ya cargó su firma
                let mensaje = firmaInspectorArea.querySelector('.mensaje-puede-firmar');
                if (mensaje) {
                    mensaje.remove(); // Remover mensaje anterior
                }

                const mensajeDiv = document.createElement('div');
                mensajeDiv.className = 'mensaje-puede-firmar mb-3';

                if (window.inspeccionEstado.firma_inspector) {
                    mensajeDiv.innerHTML = `
                        <p class="text-green-600 font-medium">El encargado aprobó la inspección y usted ya cargó su firma. Puede proceder a guardar.</p>
                    `;
                    // Marcar automáticamente como firmado
                    window.inspeccionEstado.inspector_firmo = true;
                } else {
                    mensajeDiv.innerHTML = `
                        <p class="text-blue-600 font-medium">El encargado aprobó la inspección. Cargue su firma para continuar.</p>
                    `;
                }

                firmaInspectorArea.insertBefore(mensajeDiv, firmaInspectorArea.firstChild.nextSibling);
            }
        }

        // Mostrar información sobre el estado del encargado
        if (firmaEncargadoArea) {
            if (window.inspeccionEstado.encargado_aprobo) {
                const h3 = firmaEncargadoArea.querySelector('h3');
                if (h3) h3.innerHTML = '<span class="text-green-600">✓ Encargado ha aprobado la inspección</span>';

                // Ocultar input del encargado
                const inputEncargado = document.getElementById('firma-encargado');
                if (inputEncargado) inputEncargado.style.display = 'none';
            } else {
                const h3 = firmaEncargadoArea.querySelector('h3');
                if (h3) h3.innerHTML = '<span class="text-orange-600">⏳ Esperando aprobación del encargado</span>';
            }
        }

        // Controlar botones de guardar
        const botonPrincipal = btnCompletar || btnGuardar;
        if (botonPrincipal) {
            if (window.inspeccionEstado.encargado_aprobo && window.inspeccionEstado.inspector_firmo) {
                botonPrincipal.disabled = false;
                botonPrincipal.classList.remove('opacity-50', 'cursor-not-allowed');
                botonPrincipal.textContent = 'Guardar Inspección';
            } else {
                botonPrincipal.disabled = true;
                botonPrincipal.classList.add('opacity-50', 'cursor-not-allowed');
                if (!window.inspeccionEstado.encargado_aprobo) {
                    botonPrincipal.textContent = 'Esperando aprobación del encargado';
                } else {
                    botonPrincipal.textContent = 'Agregue su firma para guardar';
                }
            }
        }
    }

    // Para encargados
    else if (userRole === 'Encargado') {
        if (firmaEncargadoContainer && window.inspeccionEstado.encargado_aprobo) {
            firmaEncargadoContainer.innerHTML = '<p class="text-green-600 font-semibold">✓ Ha aprobado la inspección</p>';

            // Ocultar input de firma
            const inputEncargado = document.getElementById('firma-encargado');
            if (inputEncargado) inputEncargado.style.display = 'none';
        } else if (firmaEncargadoContainer && !window.inspeccionEstado.encargado_aprobo) {
            // Solo mostrar botón de aprobar si ya tiene firma cargada
            if (window.inspeccionEstado.firma_encargado) {
                firmaEncargadoContainer.innerHTML = `
                    <button id="btn-aprobar-inspeccion" onclick="firmarComoEncargado()" 
                            class="bg-green-600 text-white px-4 py-2 rounded-lg hover:bg-green-700 transition-colors">
                        Aprobar Inspección
                    </button>
                    <p class="text-sm text-gray-600 mt-2">Al aprobar, confirma que está de acuerdo con las puntuaciones.</p>
                    
                    <!-- Botón de prueba temporal -->
                    <button onclick="socket.emit('test_evento', {test: true})" 
                            class="bg-yellow-600 text-white px-2 py-1 rounded text-xs mt-2">
                        Test Estado
                    </button>
                `;
            } else {
                firmaEncargadoContainer.innerHTML = `
                    <p class="text-sm text-gray-600">Primero cargue su firma, luego podrá aprobar la inspección.</p>
                `;
            }
        }
    }
}

// Función específica para firma del encargado (aprobación directa)
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
        // Marcar que el encargado ya firmó (localmente)
        window.inspeccionEstado.firma_encargado = firmaData;
        window.inspeccionEstado.encargado_aprobo = true;


        mostrarNotificacion('Inspección aprobada por el encargado', 'success');

        // Actualizar interfaz
        actualizarInterfazFirmas();

        // Actualizar área de firma del encargado
        const firmaArea = document.getElementById('firma-encargado-area');
        if (firmaArea) {
            const h3 = firmaArea.querySelector('h3');
            if (h3) h3.innerHTML = '<span class="text-green-600">✓ Inspección Aprobada</span>';

            // Ocultar input de firma
            const inputEncargado = document.getElementById('firma-encargado');
            if (inputEncargado) inputEncargado.style.display = 'none';
        }

        // Emitir evento para notificar al inspector (broadcast general)
        if (socket) {

            // Obtener ID de usuario de manera segura
            const encargadoId = window.userId || window.userRole || 'encargado';

            // Emitir a todos los usuarios conectados
            socket.emit('encargado_aprobo', {
                mensaje: 'El encargado ha aprobado la inspección',
                encargado_id: encargadoId,
                establecimiento_id: window.inspeccionEstado.establecimiento_id,
                firma_data: firmaData, // Incluir los datos reales de la firma
                confirmador_nombre: window.userName || 'Encargado', // Nombre del confirmador
                confirmador_rol: userRole || 'Encargado', // Rol del confirmador
                timestamp: new Date().toISOString()
            });

            // También emitir evento de notificación general
            socket.emit('notificacion_general', {
                tipo: 'encargado_aprobo',
                mensaje: 'El encargado ha aprobado la inspección',
                para_rol: 'Inspector',
                firma_data: firmaData // Incluir los datos reales de la firma
            });
        } else {
        }

        // También forzar actualización con un pequeño delay para asegurar que se procese
        setTimeout(() => {
            window.inspeccionEstado.encargado_aprobo = true;
            actualizarInterfazFirmas();
        }, 100);

    } catch (error) {
        mostrarNotificacion(error.message || 'Error al aprobar inspección', 'error');
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
                        <span class="px-3 py-1 rounded-full text-sm ${informe.estado === 'completada' ? 'bg-green-100 text-green-800' :
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
        // Redirigir al login aunque haya error
        window.location.href = '/login';
    }
}

// ===== FUNCIONES DE RESETEO Y LIMPIEZA =====

/**
 * Resetea completamente el formulario después de guardar una inspección
 */
function resetearFormularioCompleto() {
    try {

        // 1. Limpiar todos los radio buttons
        const radioButtons = document.querySelectorAll('input[type="radio"][data-item-id]');
        radioButtons.forEach(radio => {
            radio.checked = false;
            radio.disabled = false; // Habilitar para nueva inspección
        });

        // 2. Limpiar observaciones generales
        const observacionesTextarea = document.getElementById('observaciones-generales');
        if (observacionesTextarea) {
            observacionesTextarea.value = '';
            observacionesTextarea.disabled = false;
        }

        // 3. Limpiar evidencias
        const evidenciasInput = document.getElementById('evidencias-input');
        const evidenciasPreview = document.getElementById('evidencias-preview');
        if (evidenciasInput) {
            evidenciasInput.value = '';
        }
        if (evidenciasPreview) {
            evidenciasPreview.innerHTML = '';
        }

        // Limpiar evidencias del estado
        window.inspeccionEstado.evidencias = [];

        // 4. Actualizar contador de evidencias
        actualizarContadorEvidencias();

        // 5. Resetear resumen a valores iniciales
        const resumenElements = {
            'total-items': document.getElementById('total-items'),
            'items-completados': document.getElementById('items-completados'),
            'puntaje-obtenido': document.getElementById('puntaje-obtenido'),
            'puntaje-maximo': document.getElementById('puntaje-maximo'),
            'porcentaje': document.getElementById('porcentaje'),
            'estado-cumplimiento': document.getElementById('estado-cumplimiento')
        };

        Object.entries(resumenElements).forEach(([key, element]) => {
            if (element) {
                if (key === 'porcentaje') {
                    element.textContent = '0%';
                } else {
                    element.textContent = '0';
                }
            }
        });

        if (resumenElements['estado-cumplimiento']) {
            resumenElements['estado-cumplimiento'].textContent = 'Pendiente';
            resumenElements['estado-cumplimiento'].className = 'px-2 py-1 text-xs rounded bg-gray-100 text-gray-800';
        }

        // Resetear la barra de progreso visual si existe
        const progressBar = document.querySelector('.progress-bar');
        if (progressBar) {
            progressBar.style.width = '0%';
        }

        // 6. NO limpiar interfaz de firmas - mantener las firmas del inspector y encargado
        // Las firmas deben persistir después del reseteo del formulario

        // 7. Habilitar formulario para nueva inspección
        const form = document.getElementById('form-inspeccion');
        if (form) {
            const inputs = form.querySelectorAll('input, textarea, button');
            inputs.forEach(input => {
                if (input.type !== 'submit') {
                    input.disabled = false;
                }
            });
        }

        // 8. Limpiar cookies del formulario
        const establecimientoId = document.getElementById('establecimiento')?.value;
        if (establecimientoId && window.FormCookieManager) {
            const cookieManager = new window.FormCookieManager();
            cookieManager.clearFormData(establecimientoId);
        }

        // 9. NO restaurar el botón de confirmación - mantener estado "Ya confirmada"
        // El botón debe mantenerse como "Ya confirmada por [Nombre]" después del reseteo

        // 10. Deshabilitar el botón de completar inspección para el inspector
        deshabilitarBotonCompletarInspector();

    } catch (error) {
    }
}

/**
 * Limpia completamente el estado temporal de la aplicación
 */
function limpiarEstadoTemporal() {
    try {
        // Guardar el estado de confirmaciones por establecimiento antes de limpiar
        const confirmacionesPrevias = window.inspeccionEstado?.confirmacionesPorEstablecimiento || {};

        // Guardar las firmas actuales antes de limpiar
        const firmaInspectorActual = window.inspeccionEstado?.firma_inspector;
        const firmaEncargadoActual = window.inspeccionEstado?.firma_encargado;
        const firmaInspectorIdActual = window.inspeccionEstado?.firma_inspector_id;
        const firmaEncargadoIdActual = window.inspeccionEstado?.firma_encargado_id;
        const inspectorFirmoActual = window.inspeccionEstado?.inspector_firmo;
        const encargadoAproboActual = window.inspeccionEstado?.encargado_aprobo;

        // 1. Resetear estado global de inspección
        window.inspeccionEstado = {
            inspeccion_id: null,
            establecimiento_id: null,
            encargado_id: null,
            inspector_id: null,
            fecha: null,
            items: {},
            observaciones: '',
            firma_encargado: firmaEncargadoActual, // Preservar firma del encargado
            firma_inspector: firmaInspectorActual, // Preservar firma del inspector
            firma_encargado_id: firmaEncargadoIdActual, // Preservar ID de firma del encargado
            firma_inspector_id: firmaInspectorIdActual, // Preservar ID de firma del inspector
            estado: 'borrador',
            encargado_aprobo: encargadoAproboActual, // Preservar estado de aprobación
            inspector_firmo: inspectorFirmoActual, // Preservar estado de firma del inspector
            evidencias: [],
            confirmada_por_encargado: false,
            confirmador_nombre: null,
            confirmador_rol: null,
            confirmacionesPorEstablecimiento: confirmacionesPrevias // Mantener estado de confirmaciones por establecimiento
        };

        // 2. Limpiar datos temporales del sessionStorage
        if (sessionStorage.getItem('inspeccion_temporal')) {
            sessionStorage.removeItem('inspeccion_temporal');
        }

        // 3. Resetear variables de control
        window.hayCambiosPendientes = false;
        window.ultimaSincronizacion = null;
        window.inspeccionActualId = null;

        // 4. Limpiar datos de autosave si existen
        if (typeof limpiarAutosave === 'function') {
            limpiarAutosave();
        }

        // 5. Deshabilitar el botón de completar inspección para el inspector
        deshabilitarBotonCompletarInspector();

    } catch (error) {
    }
}

/**
 * Actualiza el plan semanal después de guardar una inspección
 */
function actualizarPlanSemanal() {
    try {

        // 1. Si hay un widget de plan semanal en el dashboard, recargarlo
        const planSemanalContainer = document.getElementById('plan-semanal-container');
        if (planSemanalContainer) {
            fetch('/api/dashboard/plan-semanal')
                .then(response => response.json())
                .then(data => {
                    if (data && typeof renderPlanSemanal === 'function') {
                        renderPlanSemanal(data);
                    }
                })
                .catch(error => {
                });
        }

        // 2. Si hay un dashboard con estadísticas, actualizarlo
        const estadisticasContainer = document.getElementById('estadisticas-dashboard');
        if (estadisticasContainer && typeof actualizarEstadisticasDashboard === 'function') {
            actualizarEstadisticasDashboard();
        }

        // 3. Si hay gráficos o métricas que actualizar
        if (typeof actualizarMetricasInspecciones === 'function') {
            actualizarMetricasInspecciones();
        }

        // 4. Forzar recarga de cualquier widget de progreso semanal
        const progressWidgets = document.querySelectorAll('[data-widget="plan-semanal"]');
        progressWidgets.forEach(widget => {
            if (widget.dataset.establecimientoId) {
                cargarProgresoSemanal(widget.dataset.establecimientoId, widget);
            }
        });


    } catch (error) {
    }
}

// Hacer funciones disponibles globalmente
window.resetearFormularioCompleto = resetearFormularioCompleto;
window.limpiarEstadoTemporal = limpiarEstadoTemporal;
window.actualizarPlanSemanal = actualizarPlanSemanal;

// ===== UTILIDADES PARA EVIDENCIAS =====

/**
 * Función utilitaria para convertir un archivo a base64
 */
function convertirArchivoABase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result);
        reader.onerror = error => reject(error);
        reader.readAsDataURL(file);
    });
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
            window.location.href = '/login';
        });
}

// Detectar cuando el usuario navega de vuelta a la página
window.addEventListener('pageshow', function (event) {
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
window.addEventListener('load', function () {
    // NO ejecutar en página de login
    if (window.location.pathname === '/login') {
        return;
    }

    verificarSesionAlRetroceder();
});


/**
 * Cargar firmas disponibles del establecimiento seleccionado
 * - Para encargados: carga automáticamente SU firma
 * - Para inspectores/admin: muestra selector con todas las firmas
 */
async function cargarFirmasEstablecimiento(establecimientoId) {

    if (!establecimientoId) {
        return;
    }

    // Verificar si el usuario está autenticado
    if (!window.userId && !userId) {
        return;
    }

    // Asegurar que tenemos el rol del usuario
    let currentUserRole = userRole || window.userRole;
    if (!currentUserRole) {
        // Intentar obtener el rol del DOM
        const vistaApp = document.getElementById('vista-app');
        if (vistaApp) {
            currentUserRole = vistaApp.getAttribute('data-user-role');
        }
    }


    if (!currentUserRole) {
        return;
    }

    // Referencias a elementos del DOM
    const previewInspector = document.getElementById('preview-firma-inspector');
    const hiddenInputInspector = document.getElementById('firma-inspector-hidden');
    const infoInspector = document.getElementById('firma-inspector-info');

    try {
        const response = await fetch(`/jefe/firmas/obtener/${establecimientoId}`);

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();

        // === PARA INSPECTORES/ADMIN/JEFE: Cargar SU PROPIA firma Y verificar firma del encargado ===
        if (currentUserRole === 'Inspector' || currentUserRole === 'Administrador' || currentUserRole === 'Jefe de Establecimiento') {

            if (data.success) {
                // Procesar firma del inspector
                if (data.firma_inspector && data.firma_inspector.ruta) {

                    // Verificar que el elemento esté en el DOM antes de intentar actualizarlo
                    if (!previewInspector) {
                    } else {

                        // Mostrar firma en preview usando función helper
                        mostrarPreviewFirmaInspector(data.firma_inspector.ruta);

                        // Verificar que se actualizó el DOM inmediatamente
                        setTimeout(() => {
                            const updatedContent = previewInspector ? previewInspector.innerHTML : 'ELEMENTO NO ENCONTRADO';
                        }, 10);

                        // Verificar después de 500ms
                        setTimeout(() => {
                            const updatedContent = previewInspector ? previewInspector.innerHTML : 'ELEMENTO NO ENCONTRADO';
                        }, 500);
                    }

                    // Guardar en estado global
                    if (window.inspeccionEstado) {
                        window.inspeccionEstado.firma_inspector = data.firma_inspector.ruta;
                        window.inspeccionEstado.firma_inspector_id = data.firma_inspector.id;
                        // Marcar como confirmada automáticamente
                        window.inspeccionEstado.inspector_firmo = true;
                    }

                    // Actualizar campo oculto
                    if (hiddenInputInspector) {
                        hiddenInputInspector.value = data.firma_inspector.ruta;
                    }

                    // Mostrar mensaje informativo
                    if (infoInspector) {
                        infoInspector.classList.remove('hidden');
                    }

                } else {

                    if (previewInspector) {
                        previewInspector.innerHTML = `
                            <div class="text-center">
                                <svg class="w-12 h-12 text-red-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                                </svg>
                                <p class="text-red-500 text-sm font-medium">No tiene firma registrada</p>
                                <p class="text-gray-500 text-xs mt-1">Por favor, suba su firma desde su perfil.</p>
                                <a href="/inspector/perfil" class="inline-flex items-center mt-2 px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
                                    <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                                    </svg>
                                    Ir a mi perfil
                                </a>
                            </div>
                        `;
                    }

                    // Limpiar estado global
                    if (window.inspeccionEstado) {
                        window.inspeccionEstado.firma_inspector = null;
                        window.inspeccionEstado.firma_inspector_id = null;
                    }

                    // Limpiar campo oculto
                    if (hiddenInputInspector) {
                        hiddenInputInspector.value = '';
                    }

                    // Ocultar mensaje informativo
                    if (infoInspector) {
                        infoInspector.classList.add('hidden');
                    }
                }

                // Procesar firma del encargado (si existe)
                if (data.firma_encargado && data.firma_encargado.ruta) {

                    // Mostrar firma del encargado
                    mostrarPreviewFirmaEncargado(data.firma_encargado.ruta);

                    // Guardar en estado global
                    if (window.inspeccionEstado) {
                        window.inspeccionEstado.firma_encargado = data.firma_encargado.ruta;
                        window.inspeccionEstado.firma_encargado_id = data.firma_encargado.id;
                        // Marcar como aprobado automáticamente
                        window.inspeccionEstado.encargado_aprobo = true;
                    }

                    // Actualizar campo oculto
                    const hiddenInput = document.getElementById('firma-encargado-hidden');
                    if (hiddenInput) {
                        hiddenInput.value = data.firma_encargado.id;
                    }

                } else {
                    // No hay firma del encargado
                    limpiarPreviewFirmaEncargado();

                    // Asegurar que no esté marcado como aprobado
                    if (window.inspeccionEstado) {
                        window.inspeccionEstado.encargado_aprobo = false;
                    }
                }

                // Actualizar interfaz después de cargar las firmas
                actualizarInterfazFirmas();
            } else {
                // Error en la respuesta
                if (previewInspector) {
                    previewInspector.innerHTML = `
                        <div class="text-center">
                            <svg class="w-12 h-12 text-yellow-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                            </svg>
                            <p class="text-yellow-600 text-sm font-medium">Error al cargar firma</p>
                            <p class="text-gray-500 text-xs mt-1">Intente recargar la página.</p>
                        </div>
                    `;
                }
            }
        }

        // === PARA ENCARGADOS: Cargar su firma desde FirmaEncargadoPorJefe ===
        if (currentUserRole === 'Encargado') {
            const selectContainer = document.getElementById('firma-selector-container');
            const selectFirma = document.getElementById('firma-encargado-select');
            const infoPropiaDiv = document.getElementById('firma-info-propia');
            const mensajeInfo = document.getElementById('firma-mensaje-info');
            const mensajeTexto = document.getElementById('firma-mensaje-texto');

            if (data.success) {
                // Si es la firma propia del encargado (usuario logueado)
                if (data.firma_encargado && data.firma_encargado.ruta) {

                    // Ocultar selector, mostrar info
                    if (selectContainer) selectContainer.classList.add('hidden');
                    if (infoPropiaDiv) infoPropiaDiv.classList.remove('hidden');

                    // Cargar automáticamente la firma
                    mostrarPreviewFirmaEncargado(data.firma_encargado.ruta);

                    // Guardar en estado global
                    window.inspeccionEstado.firma_encargado = data.firma_encargado.ruta;
                    window.inspeccionEstado.firma_encargado_id = data.firma_encargado.id;
                    // Marcar como aprobada automáticamente
                    window.inspeccionEstado.encargado_aprobo = true;

                    // Actualizar campo oculto
                    const hiddenInput = document.getElementById('firma-encargado-hidden');
                    if (hiddenInput) {
                        hiddenInput.value = data.firma_encargado.id;
                    }


                } else {
                    // Encargado sin firma registrada

                    if (selectContainer) selectContainer.classList.add('hidden');
                    if (infoPropiaDiv) infoPropiaDiv.classList.add('hidden');
                    if (mensajeInfo) {
                        mensajeInfo.classList.remove('hidden');
                        mensajeTexto.textContent = data.message || 'No tiene firma registrada. Contacte al jefe del establecimiento.';
                    }

                    limpiarPreviewFirmaEncargado();
                }
            } else {
                // Error para encargados
                if (mensajeInfo) {
                    mensajeInfo.classList.remove('hidden');
                    mensajeTexto.textContent = data.message || 'Error al cargar firma del encargado.';
                }
                limpiarPreviewFirmaEncargado();
            }
        }
    } catch (error) {

        // Manejar errores de red/conexión
        if (currentUserRole === 'Inspector' || currentUserRole === 'Administrador' || currentUserRole === 'Jefe de Establecimiento') {
            if (previewInspector) {
                previewInspector.innerHTML = `
                    <div class="text-center">
                        <svg class="w-12 h-12 text-yellow-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
                        </svg>
                        <p class="text-yellow-600 text-sm font-medium">Error al cargar firma</p>
                        <p class="text-gray-500 text-xs mt-1">Intente recargar la página.</p>
                    </div>
                `;
            }
        }
    }
}

/**
 * Cargar inspecciones pendientes y mostrar interfaz de selección
 */
async function cargarInspeccionesPendientes() {
    try {
        const response = await fetch('/api/inspecciones/pendientes');


        if (!response.ok) {
            return;
        }

        const data = await response.json();

        if (data.success && data.inspecciones && data.inspecciones.length > 0) {
            mostrarInterfazInspeccionesPendientes(data.inspecciones);
        } else {
        }
    } catch (error) {
    }
}

/**
 * Mostrar interfaz para seleccionar entre nueva inspección o continuar pendiente
 */
function mostrarInterfazInspeccionesPendientes(inspecciones) {

    const contenedorEstablecimiento = document.querySelector('.establecimiento-container') ||
        document.querySelector('[data-establecimiento-container]') ||
        document.getElementById('establecimiento-select-container');


    if (!contenedorEstablecimiento) {
        return;
    }    // Crear interfaz de selección
    const interfazSeleccion = document.createElement('div');
    interfazSeleccion.id = 'inspecciones-pendientes-interfaz';
    interfazSeleccion.className = 'mb-4 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-700 rounded-lg';

    interfazSeleccion.innerHTML = `
        <div class="flex items-center justify-between mb-3">
            <h3 class="text-lg font-semibold text-blue-800 dark:text-blue-200">
                <i class="fa-solid fa-clipboard-clock"></i> Inspecciones Disponibles
            </h3>
            <button id="btn-nueva-inspeccion" class="px-3 py-1 text-sm bg-green-600 text-white rounded hover:bg-green-700 transition-colors">
                <i class="fa-solid fa-plus"></i> Nueva Inspección
            </button>
        </div>
        
        <p class="text-sm text-blue-600 dark:text-blue-300 mb-3">
            Se encontraron ${inspecciones.length} inspección(es) pendiente(s). Puede continuar una existente o crear una nueva.
        </p>
        
        <div class="space-y-2 max-h-60 overflow-y-auto">
            ${inspecciones.map(inspeccion => `
                <div class="inspection-card p-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                     data-inspeccion-id="${inspeccion.id}">
                    <div class="flex justify-between items-start">
                        <div class="flex-1">
                            <h4 class="font-medium text-gray-900 dark:text-gray-100">
                                <i class="fa-solid fa-building"></i> ${inspeccion.establecimiento.nombre}
                            </h4>
                            <p class="text-sm text-gray-600 dark:text-gray-400">
                                <i class="fa-solid fa-calendar-lines-pen"></i> ${inspeccion.fecha}
                            </p>
                            <p class="text-sm text-gray-600 dark:text-gray-400">
                                <i class="fa-solid fa-user"></i> ${inspeccion.inspector_original.nombre}
                                ${inspeccion.inspector_original.es_actual ? ' (Suya)' : ''}
                            </p>
                        </div>
                        <div class="text-right">
                            <div class="text-sm font-medium ${inspeccion.progreso.porcentaje > 50 ? 'text-green-600' : 'text-yellow-600'}">
                                ${inspeccion.progreso.porcentaje}% completo
                            </div>
                            <div class="text-xs text-gray-500">
                                ${inspeccion.progreso.completados}/${inspeccion.progreso.total} items
                            </div>
                            ${inspeccion.tiene_firmas ? '<span class="text-xs text-blue-600">✓ Con firmas</span>' : ''}
                        </div>
                    </div>
                    ${inspeccion.observaciones ? `
                        <div class="mt-2 p-2 bg-gray-50 dark:bg-gray-700 rounded text-xs text-gray-600 dark:text-gray-300">
                            📝 ${inspeccion.observaciones.substring(0, 100)}${inspeccion.observaciones.length > 100 ? '...' : ''}
                        </div>
                    ` : ''}
                </div>
            `).join('')}
        </div>
    `;

    // Insertar antes del contenedor de establecimiento
    contenedorEstablecimiento.parentNode.insertBefore(interfazSeleccion, contenedorEstablecimiento);

    // Configurar event listeners
    configurarEventosInspeccionesPendientes(inspecciones);
}

/**
 * Configurar eventos para la interfaz de inspecciones pendientes
 */
function configurarEventosInspeccionesPendientes(inspecciones) {
    console.log('Configurando eventos para inspecciones pendientes:', inspecciones);
    
    // Botón para nueva inspección
    const btnNueva = document.getElementById('btn-nueva-inspeccion');
    if (btnNueva) {
        console.log('Botón Nueva Inspección encontrado');
        btnNueva.addEventListener('click', () => {
            ocultarInterfazInspeccionesPendientes();
            mostrarNotificacion('Iniciando nueva inspección', 'info');
            limpiarEstadoTemporal();
            resetearFormularioCompleto();
        });
    }

    // Cards de inspecciones - CORREGIR: usar getAttribute en lugar de dataset
    const cards = document.querySelectorAll('.inspection-card');
    console.log(`Cards de inspecciones encontradas: ${cards.length}`);
    
    cards.forEach((card, index) => {
        // IMPORTANTE: HTML usa data-inspeccion-id (con guiones), no data-inspeccion-id (camelCase)
        // dataset.inspeccionId busca data-inspeccion-id, pero el HTML tiene data-inspeccion-id
        const inspeccionIdAttr = card.getAttribute('data-inspeccion-id');
        console.log(`Card ${index}: data-inspeccion-id = ${inspeccionIdAttr}`);
        
        card.addEventListener('click', async (e) => {
            console.log('Click en card de inspección');
            e.preventDefault();
            e.stopPropagation();
            
            const inspeccionId = inspeccionIdAttr; // Puede ser string o número
            console.log('ID de inspección a retomar:', inspeccionId);
            
            const inspeccion = inspecciones.find(i => String(i.id) === String(inspeccionId));
            console.log('Inspección encontrada:', inspeccion);

            if (inspeccion) {
                await retomarInspeccion(inspeccionId, inspeccion);
            } else {
                console.error('No se encontró la inspección con ID:', inspeccionId);
                mostrarNotificacion('Error: No se encontró la inspección', 'error');
            }
        });
    });
}

/**
 * Retomar una inspección pendiente
 */
async function retomarInspeccion(inspeccionId, inspeccionData) {
    try {
        console.log('=== Retomando inspección ===');
        console.log('ID:', inspeccionId);
        console.log('Datos:', inspeccionData);

        mostrarNotificacion('Cargando inspección...', 'info');

        const response = await fetch(`/api/inspecciones/retomar/${inspeccionId}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            }
        });

        console.log('Response status:', response.status);

        if (!response.ok) {
            const error = await response.json();
            console.error('Error del servidor:', error);
            throw new Error(error.error || 'Error al retomar inspección');
        }

        const data = await response.json();
        console.log('Datos recibidos del servidor:', data);

        if (!data.success || !data.inspeccion) {
            console.error('Respuesta inválida del servidor:', data);
            throw new Error('Respuesta inválida del servidor');
        }

        // Ocultar interfaz de selección
        ocultarInterfazInspeccionesPendientes();

        // Cargar datos de la inspección en la interfaz
        console.log('Cargando inspección en interfaz...');
        await cargarInspeccionEnInterfaz(data.inspeccion);

        const nombreEstablecimiento = inspeccionData.establecimiento?.nombre || 'Establecimiento';
        mostrarNotificacion(`Inspección retomada: ${nombreEstablecimiento}`, 'success');

    } catch (error) {
        console.error('Error en retomarInspeccion:', error);
        mostrarNotificacion(`Error: ${error.message}`, 'error');
    }
}

/**
 * Cargar datos de inspección existente en la interfaz
 */
async function cargarInspeccionEnInterfaz(inspeccionData) {
    try {
        console.log('=== Iniciando carga de inspección ===');
        console.log('Datos recibidos:', inspeccionData);

        // Establecer el establecimiento
        const selectEstablecimiento = document.getElementById('establecimiento');
        if (!selectEstablecimiento) {
            console.error('No se encontró el select de establecimiento');
            mostrarNotificacion('Error: No se encontró el formulario', 'error');
            return;
        }

        console.log('Estableciendo establecimiento_id:', inspeccionData.establecimiento_id);
        selectEstablecimiento.value = inspeccionData.establecimiento_id;

        // Disparar evento de cambio para cargar items (esto es asíncrono)
        const event = new Event('change', { bubbles: true });
        selectEstablecimiento.dispatchEvent(event);

        // Cargar firmas disponibles del establecimiento (incluyendo firma del encargado si existe)
        if (typeof cargarFirmasEstablecimiento === 'function') {
            console.log('Cargando firmas del establecimiento...');
            await cargarFirmasEstablecimiento(inspeccionData.establecimiento_id);
        }

        // Establecer fecha
        const inputFecha = document.getElementById('fecha');
        if (inputFecha) {
            inputFecha.value = inspeccionData.fecha;
            console.log('Fecha establecida:', inspeccionData.fecha);
        }

        // Actualizar estado global
        // IMPORTANTE: Para inspecciones en_proceso (borradores), NO deben estar confirmadas
        const esInspeccionBorrador = inspeccionData.estado === 'en_proceso' || inspeccionData.estado === 'temporal';
        
        window.inspeccionEstado = {
            ...window.inspeccionEstado,
            inspeccion_id: inspeccionData.id,
            establecimiento_id: inspeccionData.establecimiento_id,
            items: inspeccionData.items || {},
            observaciones: inspeccionData.observaciones || '',
            firma_inspector: inspeccionData.firma_inspector,
            firma_encargado: inspeccionData.firma_encargado,
            estado: inspeccionData.estado,
            // Determinar si el encargado ya aprobó basado en si hay firma del encargado
            encargado_aprobo: inspeccionData.firma_encargado ? true : false,
            // Determinar si el inspector ya firmó basado en si hay firma del inspector
            inspector_firmo: inspeccionData.firma_inspector ? true : false,
            // Si es borrador, NO debe estar confirmada (aunque tenga firma del encargado)
            confirmada_por_encargado: esInspeccionBorrador ? false : Boolean(inspeccionData.confirmada_por_encargado),
            confirmador_nombre: esInspeccionBorrador ? null : (inspeccionData.confirmador_nombre || null),
            confirmador_rol: esInspeccionBorrador ? null : (inspeccionData.confirmador_rol || null)
        };

        console.log('Estado global actualizado:', window.inspeccionEstado);
        console.log('Es borrador?', esInspeccionBorrador);
        console.log('Confirmada por encargado?', window.inspeccionEstado.confirmada_por_encargado);

        // Si es borrador, asegurarse de que el botón del encargado esté habilitado
        if (esInspeccionBorrador) {
            console.log('Restaurando botón de confirmación (es borrador)...');
            
            // Limpiar confirmación del sessionStorage para este establecimiento
            if (window.inspeccionEstado.confirmacionesPorEstablecimiento[inspeccionData.establecimiento_id]) {
                window.inspeccionEstado.confirmacionesPorEstablecimiento[inspeccionData.establecimiento_id] = {
                    confirmada_por_encargado: false,
                    confirmador_nombre: null,
                    confirmador_rol: null
                };
                // Guardar estado limpio en sessionStorage
                guardarEstadoConfirmaciones();
                console.log('Estado de confirmación limpiado en sessionStorage');
            }
            
            // Restaurar botón de confirmación del encargado a su estado activo
            if (typeof restaurarBotonConfirmarEncargado === 'function') {
                // Usar timeout para asegurar que se ejecute después de que el DOM esté listo
                setTimeout(() => {
                    restaurarBotonConfirmarEncargado();
                    console.log('Botón de confirmación restaurado');
                }, 100);
            }
        }

        // Unirse a la sala del establecimiento para tiempo real
        if (socket && userRole === 'Inspector') {
            socket.emit('join_establecimiento', {
                establecimiento_id: inspeccionData.establecimiento_id,
                usuario_id: window.userId || 1,
                role: userRole
            });
            console.log('Unido a sala de establecimiento');
        }

        // Esperar con reintentos a que los items se carguen
        let intentos = 0;
        const maxIntentos = 20;
        const intervalo = setInterval(() => {
            intentos++;
            console.log(`Intento ${intentos}/${maxIntentos} - Verificando si los items están cargados...`);

            // Verificar si hay radio buttons en el DOM (señal de que los items se cargaron)
            const radioButtons = document.querySelectorAll('input[type="radio"][data-item-id]');
            console.log(`Radio buttons encontrados: ${radioButtons.length}`);

            if (radioButtons.length > 0 || intentos >= maxIntentos) {
                clearInterval(intervalo);

                if (radioButtons.length > 0) {
                    console.log('Items cargados correctamente. Aplicando calificaciones...');

                    // Aplicar calificaciones guardadas
                    if (inspeccionData.items && Object.keys(inspeccionData.items).length > 0) {
                        console.log('Aplicando calificaciones:', inspeccionData.items);
                        aplicarCalificacionesAInterfaz(inspeccionData.items);
                    }

                    // Cargar observaciones
                    const observacionesTextarea = document.getElementById('observaciones-generales');
                    if (observacionesTextarea && inspeccionData.observaciones) {
                        observacionesTextarea.value = inspeccionData.observaciones;
                        console.log('Observaciones cargadas');
                    }

                    // Actualizar interfaz
                    if (typeof actualizarResumen === 'function') {
                        actualizarResumen();
                    }
                    if (typeof actualizarInterfazResumen === 'function') {
                        actualizarInterfazResumen();
                    }

                    console.log('=== Carga de inspección completada ===');
                    mostrarNotificacion('Inspección cargada correctamente', 'success');
                } else {
                    console.error('Timeout: Los items no se cargaron después de múltiples intentos');
                    mostrarNotificacion('Advertencia: Los items del formulario no se cargaron completamente', 'warning');
                }
            }
        }, 250); // Verificar cada 250ms

    } catch (error) {
        console.error('Error en cargarInspeccionEnInterfaz:', error);
        mostrarNotificacion('Error cargando datos de la inspección', 'error');
    }
}

/**
 * Ocultar interfaz de inspecciones pendientes
 */
function ocultarInterfazInspeccionesPendientes() {
    const interfaz = document.getElementById('inspecciones-pendientes-interfaz');
    if (interfaz) {
        interfaz.style.display = 'none';
    }
}

/**
 * Cargar firma del usuario actual (Inspector/Admin/Jefe) al inicio de la página
 * No requiere selección de establecimiento
 */
async function cargarFirmaUsuarioActual() {

    // Verificar autenticación
    if (!userId) {
        return;
    }

    // Solo aplica para Inspector, Admin y Jefe
    const rolesPermitidos = ['Inspector', 'Administrador', 'Jefe de Establecimiento'];
    if (!rolesPermitidos.includes(userRole)) {
        return;
    }

    // Referencias a elementos del DOM
    const previewInspector = document.getElementById('preview-firma-inspector');
    const hiddenInputInspector = document.getElementById('firma-inspector-hidden');
    const infoInspector = document.getElementById('firma-inspector-info');

    if (!previewInspector) {
        return;
    }

    try {
        const response = await fetch('/jefe/firmas/obtener-propia');

        if (!response.ok) {
            throw new Error(`HTTP ${response.status}: ${response.statusText}`);
        }

        const data = await response.json();

        if (data.success && data.firma && data.firma.ruta) {

            // Mostrar firma en preview
            mostrarPreviewFirmaInspector(data.firma.ruta);

            // Guardar en estado global
            if (window.inspeccionEstado) {
                window.inspeccionEstado.firma_inspector = data.firma.ruta;
                window.inspeccionEstado.firma_inspector_id = data.firma.id;
                window.inspeccionEstado.inspector_firmo = true;
            }

            // Actualizar campo oculto
            if (hiddenInputInspector) {
                hiddenInputInspector.value = data.firma.ruta;
            }

            // Mostrar mensaje informativo
            if (infoInspector) {
                infoInspector.classList.remove('hidden');
            }

        } else {
            mostrarMensajeSinFirma(previewInspector);
        }
    } catch (error) {
        mostrarMensajeSinFirma(previewInspector);
    }
}

/**
 * Mostrar mensaje cuando el usuario no tiene firma
 */
function mostrarMensajeSinFirma(previewElement) {
    if (!previewElement) return;

    previewElement.innerHTML = `
        <div class="text-center">
            <svg class="w-12 h-12 text-red-400 mx-auto mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path>
            </svg>
            <p class="text-red-500 text-sm font-medium">No tiene firma registrada</p>
            <p class="text-gray-500 text-xs mt-1">Por favor, suba su firma desde su perfil.</p>
            <a href="/inspector/perfil" class="inline-flex items-center mt-2 px-3 py-1 text-xs bg-blue-600 text-white rounded hover:bg-blue-700 transition-colors">
                <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z"></path>
                </svg>
                Ir a mi perfil
            </a>
        </div>
    `;
}

/**
 * Mostrar preview de firma del inspector
 */
function mostrarPreviewFirmaInspector(pathFirma) {

    // Validar parámetros
    if (!pathFirma) {
        return;
    }

    const preview = document.getElementById('preview-firma-inspector');

    if (!preview) {
        return;
    }

    // Verificar que el elemento esté visible
    const computedStyle = window.getComputedStyle(preview);

    const imageUrl = `/static/${pathFirma}`;

    // Crear el HTML de la imagen
    const imageHtml = `
        <img src="${imageUrl}"
             alt="Firma del inspector"
             class="max-w-full max-h-[200px] object-contain rounded-lg border border-gray-300"

>
    `;


    // Asignar el HTML
    preview.innerHTML = imageHtml;


    // Verificar inmediatamente después
    setTimeout(() => {
        const currentContent = preview.innerHTML;

        const img = preview.querySelector('img');
        if (img) {

            // Verificar si la imagen ya cargó
            if (img.complete) {
                if (img.naturalWidth > 0) {
                } else {
                }
            } else {
            }
        } else {
        }
    }, 100);

    // Verificar después de 1 segundo
    setTimeout(() => {
        const finalContent = preview.innerHTML;
    }, 1000);
}

/**
 * Mostrar preview de firma del encargado
 */
function mostrarPreviewFirmaEncargado(pathFirma) {
    const preview = document.getElementById('preview-firma-encargado');
    if (!preview) return;

    preview.innerHTML = `
        <img src="/static/${pathFirma}" 
             alt="Firma del encargado" 
             class="max-w-full max-h-[200px] object-contain rounded-lg"
             onerror="this.src='/static/img/placeholder-firma.png'">
    `;
}

/**
 * Limpiar preview de firma del encargado
 */
function limpiarPreviewFirmaEncargado() {
    const preview = document.getElementById('preview-firma-encargado');
    if (!preview) return;

    preview.innerHTML = '<p class="text-slate-400 text-sm">Vista previa de la firma</p>';

    // Limpiar estado global
    if (window.inspeccionEstado) {
        window.inspeccionEstado.firma_encargado = null;
        window.inspeccionEstado.firma_encargado_id = null;
    }

    // Limpiar campo oculto
    const hiddenInput = document.getElementById('firma-encargado-hidden');
    if (hiddenInput) {
        hiddenInput.value = '';
    }
}

/**
 * Confirmar inspección por encargado (solo el primero puede hacerlo)
 */
async function confirmarInspeccionEncargado() {
    try {
        const establecimientoId = window.inspeccionEstado?.establecimiento_id;
        const firmaId = window.inspeccionEstado?.firma_encargado_id;

        if (!establecimientoId) {
            mostrarNotificacion('Error: No hay establecimiento seleccionado', 'error');
            return;
        }

        const response = await fetch('/api/inspecciones/confirmar', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                establecimiento_id: establecimientoId,
                firma_id: firmaId
            })
        });

        const data = await response.json();

        if (response.ok) {
            mostrarNotificacion(`Inspección confirmada exitosamente por ${data.confirmador}`, 'success');
            deshabilitarBotonConfirmar(data.confirmador, userRole);
        } else if (response.status === 409) {
            // Ya fue confirmada por otro
            mostrarNotificacion(data.error, 'warning');
            deshabilitarBotonConfirmar(data.confirmador, 'otro encargado');
        } else {
            mostrarNotificacion(data.error || 'Error al confirmar inspección', 'error');
        }
    } catch (error) {
        mostrarNotificacion('Error de conexión al confirmar inspección', 'error');
    }
}

/**
 * Deshabilitar botón de confirmar cuando ya fue confirmada
 */
function deshabilitarBotonConfirmar(confirmador, rol) {
    const boton = document.querySelector('button[onclick="confirmarInspeccionEncargado()"]') || document.querySelector('button[value="confirmar"]');
    if (!boton) return;

    const nombreConfirmador = confirmador || 'Encargado';
    const rolConfirmador = rol ? ` (${rol})` : '';

    boton.disabled = true;
    boton.classList.remove('bg-gradient-to-r', 'from-green-500', 'to-emerald-600', 'hover:from-green-600', 'hover:to-emerald-700');
    boton.classList.add('bg-slate-400', 'cursor-not-allowed', 'opacity-60');
    boton.innerHTML = `
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        Ya confirmada por ${nombreConfirmador}${rolConfirmador}
    `;
}

/**
 * Descripcion: Restaura el boton de confirmacion del encargado a su estado activo original.
 * Logica: Busca el boton asociado a confirmar inspecciones, elimina estilos de deshabilitado y aplica
 * nuevamente las clases base con el icono por defecto para permitir nuevas confirmaciones.
 * @example
 * restaurarBotonConfirmarEncargado();
 */
function restaurarBotonConfirmarEncargado() {
    const boton = document.querySelector('button[onclick="confirmarInspeccionEncargado()"]') || document.querySelector('button[value="confirmar"]');
    if (!boton) {
        return;
    }

    boton.disabled = false;
    boton.className = 'px-8 py-4 bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-semibold rounded-xl transition-all duration-200 shadow-lg hover:shadow-xl flex items-center justify-center';
    boton.innerHTML = `
        <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
        </svg>
        Confirmar Inspecci&oacute;n
    `;
}

/**
 * Descripcion: Deshabilita el boton de completar inspeccion para el inspector hasta que el encargado confirme.
 * Logica: Busca el boton de completar inspeccion, lo deshabilita y cambia su apariencia para indicar que espera confirmacion.
 * Verifica el estado de confirmacion por establecimiento actual.
 * @example
 * deshabilitarBotonCompletarInspector();
 */
function deshabilitarBotonCompletarInspector() {
    const btnCompletar = document.querySelector('button[value="completar"]');
    if (!btnCompletar) {
        return;
    }

    // Verificar si el establecimiento actual está confirmado
    const establecimientoActual = window.inspeccionEstado.establecimiento_id;
    const estaConfirmado = window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoActual]?.confirmada_por_encargado;

    if (estaConfirmado) {
        // Si está confirmado, habilitar el botón
        btnCompletar.disabled = false;
        btnCompletar.classList.remove('opacity-50', 'cursor-not-allowed');
        btnCompletar.innerHTML = `
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            Guardar Inspección
        `;
    } else {
        // Si no está confirmado, deshabilitar el botón
        btnCompletar.disabled = true;
        btnCompletar.classList.add('opacity-50', 'cursor-not-allowed');
        btnCompletar.innerHTML = `
            <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            Esperando Confirmación del Encargado
        `;
    }
}

/**
 * Descripcion: Reinicia el estado de confirmacion cuando el inspector modifica la inspeccion.
 * Logica: Marca la confirmacion como pendiente en memoria, limpia los datos del confirmador y actualiza los botones de inspector y encargado segun corresponda.
 * @example
 * reiniciarConfirmacionEncargadoPorCambio();
 */
function reiniciarConfirmacionEncargadoPorCambio() {
    const establecimientoId = window.inspeccionEstado?.establecimiento_id;
    if (!establecimientoId) {
        return;
    }

    if (!window.inspeccionEstado.confirmacionesPorEstablecimiento) {
        window.inspeccionEstado.confirmacionesPorEstablecimiento = {};
    }

    const estadoPrevio = window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId];

    window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId] = {
        confirmada_por_encargado: false,
        confirmador_nombre: null,
        confirmador_rol: null
    };

    window.inspeccionEstado.confirmada_por_encargado = false;
    window.inspeccionEstado.confirmador_nombre = null;
    window.inspeccionEstado.confirmador_rol = null;

    const yaPendiente = estadoPrevio
        && estadoPrevio.confirmada_por_encargado === false
        && estadoPrevio.confirmador_nombre === null
        && estadoPrevio.confirmador_rol === null;

    if (!yaPendiente) {
        guardarEstadoConfirmaciones();
    }

    if (userRole === 'Inspector' || userRole === 'Administrador') {
        deshabilitarBotonCompletarInspector();
    }

    if (userRole === 'Encargado' || userRole === 'Jefe de Establecimiento') {
        restaurarBotonConfirmarEncargado();
    }
}

/**
 * Descripcion: Sincroniza en el cliente inspector el estado de confirmacion recibido en tiempo real.
 * Logica: Actualiza la tabla de confirmaciones por establecimiento, refresca el boton de completar y conserva los datos del confirmador si la aprobacion sigue vigente.
 * @param {Object} data - Datos recibidos desde el servidor.
 * @example
 * actualizarEstadoTiempoRealInspector({ establecimiento_id: 7, confirmada_por_encargado: false });
 */
function actualizarEstadoTiempoRealInspector(data) {
    if (!data || !data.establecimiento_id) {
        return;
    }

    if (!window.inspeccionEstado.confirmacionesPorEstablecimiento) {
        window.inspeccionEstado.confirmacionesPorEstablecimiento = {};
    }

    const establecimientoId = data.establecimiento_id;

    window.inspeccionEstado.confirmacionesPorEstablecimiento[establecimientoId] = {
        confirmada_por_encargado: Boolean(data.confirmada_por_encargado),
        confirmador_nombre: data.confirmador_nombre || null,
        confirmador_rol: data.confirmador_rol || null
    };

    if (window.inspeccionEstado.establecimiento_id === establecimientoId) {
        window.inspeccionEstado.confirmada_por_encargado = Boolean(data.confirmada_por_encargado);
        window.inspeccionEstado.confirmador_nombre = data.confirmador_nombre || null;
        window.inspeccionEstado.confirmador_rol = data.confirmador_rol || null;
        deshabilitarBotonCompletarInspector();
    }

    guardarEstadoConfirmaciones();
}