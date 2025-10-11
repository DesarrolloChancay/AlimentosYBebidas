/**
 * ✅ CONFIGURACIÓN DEL SISTEMA - JavaScript
 * FUNCIONALIDADES:
 * - Gestión de pestañas de configuración
 * - Guardado automático y manual de configuraciones
 * - Validación de formatos de fecha/hora Lima, Perú
 * - Interfaz responsive con modo oscuro/claro
 * - Gestión de permisos por rol de usuario
 */

class ConfiguracionManager {
    constructor() {
        this.configuracionOriginal = {};
        this.configuracionActual = {};
        this.hayChangios = false;
        this.autoSaveInterval = null;
        this.init();
    }

    init() {
        this.verificarBorrador();
        this.setupEventListeners();
        this.cargarConfiguracion();
        this.configurarAutoSave();
        this.configurarValidaciones();
    }

    verificarBorrador() {
        const borrador = localStorage.getItem('configuracion_draft');
        if (borrador) {
            try {
                const config = JSON.parse(borrador);
                this.mostrarConfirmacionBorrador(config);
            } catch (error) {
                localStorage.removeItem('configuracion_draft');
            }
        }
    }

    async mostrarConfirmacionBorrador(config) {
        const confirmacion = await this.mostrarConfirmacion(
            '💾 Borrador encontrado',
            'Se encontró una configuración guardada localmente. ¿Desea restaurarla?',
            'Restaurar',
            'Descartar'
        );

        if (confirmacion) {
            this.aplicarConfiguracion(config);
            this.hayChangios = true;
            this.mostrarIndicadorCambios(true);
            mostrarToast('success', 'Borrador restaurado', 'El borrador ha sido restaurado correctamente');
        }
        
        localStorage.removeItem('configuracion_draft');
    }

    setupEventListeners() {
        
        // Navegación por pestañas
        document.querySelectorAll('.config-tab').forEach(tab => {
            tab.addEventListener('click', (e) => {
                const tabName = e.target.dataset.tab;
                this.cambiarPestana(tabName);
            });
        });

        // Botones principales
        const guardarBtn = document.getElementById('guardar-btn');
        const resetearBtn = document.getElementById('resetear-btn');
        const limpiarBtn = document.getElementById('limpiar-datos-btn');
        
        
        if (guardarBtn) {
            guardarBtn.addEventListener('click', () => {
                this.guardarConfiguracion();
            });
        } else {
        }

        if (resetearBtn) {
            resetearBtn.addEventListener('click', () => {
                this.restaurarDefecto();
            });
        } else {
        }

        if (limpiarBtn) {
            limpiarBtn.addEventListener('click', () => {
                this.limpiarDatosLocales();
            });
        } else {
        }

        // Limpiar datos locales
        const alertClose = document.getElementById('alert-close');
        if (alertClose) {
            alertClose.addEventListener('click', () => {
                cerrarToast();
            });
        }

        // Checkboxes de días de la semana
        document.querySelectorAll('.day-checkbox input').forEach(checkbox => {
            checkbox.addEventListener('change', (e) => {
                this.toggleDaySelection(e.target);
            });
        });

        // Inputs que disparan cambios
        this.setupChangeListeners();

        // Escape para cerrar modales
        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                cerrarToast();
            }
        });
        
    }

    setupChangeListeners() {
        // Todos los inputs, selects y checkboxes de configuración
        const elementos = document.querySelectorAll(
            'input[type="number"], input[type="time"], select, input[type="checkbox"]'
        );

        elementos.forEach(elemento => {
            elemento.addEventListener('change', () => {
                this.detectarCambios();
            });
        });
    }

    cambiarPestana(tabName) {
        // Remover clases activas
        document.querySelectorAll('.config-tab').forEach(tab => {
            tab.classList.remove('active');
        });
        document.querySelectorAll('.config-panel').forEach(panel => {
            panel.classList.remove('active');
        });

        // Activar pestaña y panel correspondiente
        document.querySelector(`[data-tab="${tabName}"]`)?.classList.add('active');
        document.getElementById(`tab-${tabName}`)?.classList.add('active');

        // Guardar en localStorage la pestaña activa
        localStorage.setItem('config_active_tab', tabName);
    }

    async cargarConfiguracion() {
        try {
            this.mostrarLoading(true);
            
            const response = await fetch('/api/dashboard/configuracion-plan', {
                method: 'GET',
                credentials: 'include', // Importante: incluir cookies de sesión
                headers: {
                    'Accept': 'application/json',
                    'Content-Type': 'application/json'
                }
            });
            
            
            if (response.ok) {
                const contentType = response.headers.get('content-type');
                
                if (contentType && contentType.includes('application/json')) {
                    const config = await response.json();
                    this.configuracionOriginal = { ...config };
                    this.aplicarConfiguracion(config);
                } else {
                    // Si no es JSON, probablemente es HTML (página de error/login)
                    throw new Error('AUTHENTICATION_ERROR'); // Error específico para autenticación
                }
            } else if (response.status === 401) {
                throw new Error('PERMISSION_ERROR');
            } else if (response.status === 403) {
                throw new Error('ACCESS_DENIED');
            } else if (response.status === 302) {
                throw new Error('SESSION_EXPIRED');
            } else {
                const errorText = await response.text();
                if (errorText.includes('<!DOCTYPE')) {
                    throw new Error('AUTHENTICATION_ERROR');
                }
                throw new Error(`SERVER_ERROR:${response.status}`);
            }
        } catch (error) {
            
            // Manejo específico de tipos de errores
            switch (error.message) {
                case 'AUTHENTICATION_ERROR':
                    mostrarToast('info', 'Sesión no iniciada', 'Activando modo de demostración');
                    this.cargarConfiguracionPorDefecto();
                    break;
                    
                case 'PERMISSION_ERROR':
                    mostrarToast('warning', 'Sin permisos', 'Activando modo de solo lectura');
                    this.cargarConfiguracionPorDefecto();
                    break;
                    
                case 'ACCESS_DENIED':
                    mostrarToast('info', 'Configuración cargada', 'Modo de solo lectura activado');
                    this.cargarConfiguracionPorDefecto();
                    break;
                    
                case 'SESSION_EXPIRED':
                    mostrarToast('warning', 'Sesión expirada', 'Por favor inicie sesión nuevamente');
                    this.cargarConfiguracionPorDefecto();
                    break;
                    
                default:
                    if (error.message.startsWith('SERVER_ERROR:')) {
                        const status = error.message.split(':')[1];
                        mostrarToast('error', 'Error del servidor', `Activando modo de respaldo (${status})`);
                    } else {
                        mostrarToast('error', 'Error de conexión', 'Activando modo de respaldo');
                    }
                    this.cargarConfiguracionPorDefecto();
                    break;
            }
            
        } finally {
            this.mostrarLoading(false);
        }
    }

    cargarConfiguracionPorDefecto() {
        // Configuración por defecto para que la interfaz funcione
        const configDefecto = {
            meta_semanal_default: 3,
            inicio_semana: 'lunes',
            zona_horaria: 'America/Lima - Lima, Perú',
            dias_recordatorio: [1, 3, 5], // Lunes, Miércoles, Viernes
            hora_recordatorio: '09:00',
            notificaciones_email: true,
            notificaciones_navegador: true,
            alertas_dashboard: true,
            retener_logs: 90,
            backup_automatico: 'semanal',
            tiempo_sesion: 240,
            intentos_login: 5
        };
        
        this.configuracionOriginal = { ...configDefecto };
        this.aplicarConfiguracion(configDefecto);
        
    }

    aplicarConfiguracion(config) {
        // Plan de evaluaciones
        if (config.meta_semanal_default) {
            const metaSemanal = document.getElementById('meta-semanal');
            if (metaSemanal) metaSemanal.value = config.meta_semanal_default;
        }

        // Inicio de semana
        if (config.inicio_semana) {
            const inicioSemana = document.getElementById('inicio-semana');
            if (inicioSemana) inicioSemana.value = config.inicio_semana;
        }

        // Zona horaria
        if (config.zona_horaria) {
            const zonaHoraria = document.getElementById('zona-horaria');
            if (zonaHoraria) zonaHoraria.value = config.zona_horaria;
        }

        // Notificaciones - Días de recordatorio
        if (config.dias_recordatorio && Array.isArray(config.dias_recordatorio)) {
            this.configurarDiasRecordatorio(config.dias_recordatorio);
        }

        // Hora de recordatorio
        if (config.hora_recordatorio) {
            const horaRecordatorio = document.getElementById('hora-recordatorio');
            if (horaRecordatorio) horaRecordatorio.value = config.hora_recordatorio;
        }

        // Canales de notificación
        if (config.notificaciones_email !== undefined) {
            const notificacionesEmail = document.getElementById('notificaciones-email');
            if (notificacionesEmail) notificacionesEmail.checked = config.notificaciones_email;
        }

        if (config.notificaciones_navegador !== undefined) {
            const notificacionesNavegador = document.getElementById('notificaciones-navegador');
            if (notificacionesNavegador) notificacionesNavegador.checked = config.notificaciones_navegador;
        }

        if (config.alertas_dashboard !== undefined) {
            const alertasDashboard = document.getElementById('alertas-dashboard');
            if (alertasDashboard) alertasDashboard.checked = config.alertas_dashboard;
        }

        // Mantenimiento de datos
        if (config.retener_logs) {
            const retenerLogs = document.getElementById('retener-logs');
            if (retenerLogs) retenerLogs.value = config.retener_logs;
        }

        if (config.backup_automatico) {
            const backupAutomatico = document.getElementById('backup-automatico');
            if (backupAutomatico) backupAutomatico.value = config.backup_automatico;
        }

        // Seguridad y sesiones
        if (config.tiempo_sesion) {
            const tiempoSesion = document.getElementById('tiempo-sesion');
            if (tiempoSesion) tiempoSesion.value = config.tiempo_sesion;
        }

        if (config.intentos_login) {
            const intentosLogin = document.getElementById('intentos-login');
            if (intentosLogin) intentosLogin.value = config.intentos_login;
        }

        // Restaurar pestaña activa
        const tabActiva = localStorage.getItem('config_active_tab') || 'establecimientos';
        this.cambiarPestana(tabActiva);
    }

    configurarDiasRecordatorio(diasSeleccionados) {
        // Resetear todos los checkboxes
        document.querySelectorAll('input[name="dias-recordatorio"]').forEach(checkbox => {
            checkbox.checked = false;
        });

        // Activar días seleccionados
        diasSeleccionados.forEach(dia => {
            const checkbox = document.querySelector(`input[name="dias-recordatorio"][value="${dia}"]`);
            if (checkbox) {
                checkbox.checked = true;
            }
        });
    }

    toggleDaySelection(checkbox) {
        const label = checkbox.parentElement.querySelector('.day-label');
        
        if (checkbox.checked) {
            label.classList.add('active');
        } else {
            label.classList.remove('active');
        }
        
        this.detectarCambios();
    }

    detectarCambios() {
        const configActual = this.obtenerConfiguracionActual();
        this.hayChangios = JSON.stringify(configActual) !== JSON.stringify(this.configuracionOriginal);
        
        // Actualizar interfaz si hay cambios
        if (this.hayChangios) {
            this.mostrarIndicadorCambios(true);
        } else {
            this.mostrarIndicadorCambios(false);
        }
    }

    obtenerConfiguracionActual() {
        const config = {};

        // Plan de evaluaciones
        const metaSemanal = document.getElementById('meta-semanal')?.value;
        if (metaSemanal) {
            config.meta_semanal_default = parseInt(metaSemanal);
        }

        // Inicio de semana
        const inicioSemana = document.getElementById('inicio-semana')?.value;
        if (inicioSemana) {
            config.inicio_semana = inicioSemana;
        }

        // Días de recordatorio
        const diasSeleccionados = [];
        document.querySelectorAll('input[name="dias-recordatorio"]:checked').forEach(checkbox => {
            diasSeleccionados.push(parseInt(checkbox.value));
        });
        config.dias_recordatorio = diasSeleccionados;

        // Hora de recordatorio
        const horaRecordatorio = document.getElementById('hora-recordatorio')?.value;
        if (horaRecordatorio) {
            config.hora_recordatorio = horaRecordatorio;
        }

        // Canales de notificación
        config.notificaciones_email = document.getElementById('notificaciones-email')?.checked || false;
        config.notificaciones_navegador = document.getElementById('notificaciones-navegador')?.checked || false;
        config.alertas_dashboard = document.getElementById('alertas-dashboard')?.checked || false;

        // Mantenimiento de datos
        const retenerLogs = document.getElementById('retener-logs')?.value;
        if (retenerLogs) {
            config.retener_logs = parseInt(retenerLogs);
        }

        const backupAutomatico = document.getElementById('backup-automatico')?.value;
        if (backupAutomatico) {
            config.backup_automatico = backupAutomatico;
        }

        // Seguridad y sesiones
        const tiempoSesion = document.getElementById('tiempo-sesion')?.value;
        if (tiempoSesion) {
            config.tiempo_sesion = parseInt(tiempoSesion);
        }

        const intentosLogin = document.getElementById('intentos-login')?.value;
        if (intentosLogin) {
            config.intentos_login = parseInt(intentosLogin);
        }

        return config;
    }

    async guardarConfiguracion() {
        
        let configActual = null; // Declarar fuera del try para acceder en catch
        
        try {
            if (!this.hayChangios) {
                mostrarToast('info', 'Sin cambios', 'No hay cambios que guardar');
                return;
            }

            this.mostrarSaveStatus(true, 'Guardando cambios...');

            configActual = this.obtenerConfiguracionActual();
            
            // Validar configuración antes de enviar
            const validacion = this.validarConfiguracion(configActual);
            
            if (!validacion.valida) {
                mostrarToast('error', 'Validación fallida', validacion.mensaje);
                this.mostrarSaveStatus(false);
                return;
            }

            const response = await fetch('/api/dashboard/configuracion-plan', {
                method: 'PUT',
                credentials: 'include', // Importante: incluir cookies de sesión
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(configActual)
            });
            

            if (response.ok) {
                const contentType = response.headers.get('content-type');
                
                if (contentType && contentType.includes('application/json')) {
                    const resultado = await response.json();
                    
                    this.configuracionOriginal = { ...configActual };
                    this.hayChangios = false;
                    this.mostrarIndicadorCambios(false);
                    mostrarToast('success', 'Configuración guardada', 'Los cambios han sido guardados correctamente');
                    this.mostrarSaveStatus(true, 'Guardado exitoso', 2000);
                } else {
                    throw new Error('Respuesta del servidor no es JSON válido');
                }
            } else if (response.status === 401) {
                throw new Error('Sesión expirada: Por favor inicie sesión nuevamente');
            } else if (response.status === 403) {
                throw new Error('No tiene permisos para modificar la configuración');
            } else if (response.status === 302) {
                throw new Error('Sesión no válida: Redirigiendo a login');
            } else {
                const errorText = await response.text();
                if (errorText.includes('<!DOCTYPE')) {
                    throw new Error('Problema de autenticación detectado');
                }
                
                try {
                    const resultado = JSON.parse(errorText);
                    throw new Error(resultado.error || 'Error al guardar');
                } catch (parseError) {
                    throw new Error(`Error del servidor: ${response.status}`);
                }
            }

        } catch (error) {
            
            if (error.message.includes('autenticación') || 
                error.message.includes('Sesión') || 
                error.message.includes('permisos')) {
                
                mostrarToast('warning', 'Modo de solo lectura', error.message + '. Cambiando a modo de solo lectura.');
                
                // Guardar en localStorage como respaldo
                localStorage.setItem('configuracion_draft', JSON.stringify(configActual));
                mostrarToast('info', 'Borrador guardado', 'Configuración guardada localmente como borrador');
                
            } else {
                mostrarToast('error', 'Error al guardar', 'Error al guardar la configuración: ' + error.message);
            }
            
            this.mostrarSaveStatus(false);
        }
    }

    validarConfiguracion(config) {
        
        // Validar meta semanal
        if (!config.meta_semanal_default || config.meta_semanal_default < 1 || config.meta_semanal_default > 10) {
            return {
                valida: false,
                mensaje: 'La meta semanal debe estar entre 1 y 10 evaluaciones'
            };
        }

        // Solo validar días si el campo existe en el DOM
        const camposDias = document.querySelectorAll('input[name="dias-recordatorio"]');
        if (camposDias.length > 0) {
            if (!config.dias_recordatorio || config.dias_recordatorio.length === 0) {
                return {
                    valida: false,
                    mensaje: 'Debe seleccionar al menos un día para recordatorios'
                };
            }
        }

        // Solo validar hora si el campo existe en el DOM
        const campoHora = document.getElementById('hora-recordatorio');
        if (campoHora) {
            if (!config.hora_recordatorio || !this.validarHora(config.hora_recordatorio)) {
                return {
                    valida: false,
                    mensaje: 'La hora de recordatorio debe tener un formato válido (HH:MM)'
                };
            }
        }

        return { valida: true };
    }

    validarHora(hora) {
        const regex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]$/;
        return regex.test(hora);
    }

    async restaurarDefecto() {
        const confirmado = await this.mostrarConfirmacion(
            '🔄 Restaurar Configuración',
            '¿Está seguro que desea restaurar toda la configuración a los valores por defecto?\n\nEsta acción no se puede deshacer.',
            'Restaurar',
            'Cancelar'
        );

        if (!confirmado) return;

        try {
            this.mostrarLoading(true);

            // Configuración por defecto
            const configDefecto = {
                meta_semanal_default: 3,
                dias_recordatorio: [1, 3, 5], // Lunes, Miércoles, Viernes
                hora_recordatorio: '09:00'
            };

            const response = await fetch('/api/dashboard/configuracion-plan', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(configDefecto)
            });

            if (response.ok) {
                this.aplicarConfiguracion(configDefecto);
                this.configuracionOriginal = { ...configDefecto };
                this.hayChangios = false;
                this.mostrarIndicadorCambios(false);
                mostrarToast('success', 'Configuración restaurada', 'Se han restaurado los valores por defecto');
            } else {
                throw new Error('Error al restaurar configuración');
            }

        } catch (error) {
            mostrarToast('error', 'Error al restaurar', 'Error al restaurar la configuración');
        } finally {
            this.mostrarLoading(false);
        }
    }

    configurarAutoSave() {
        // Auto-guardar cada 30 segundos si hay cambios
        this.autoSaveInterval = setInterval(() => {
            if (this.hayChangios) {
                this.guardarConfiguracion();
            }
        }, 30000);
    }

    configurarValidaciones() {
        // Validación en tiempo real para meta semanal
        const metaSemanal = document.getElementById('meta-semanal');
        metaSemanal?.addEventListener('input', (e) => {
            const valor = parseInt(e.target.value);
            if (valor < 1) e.target.value = 1;
            if (valor > 10) e.target.value = 10;
        });

        // Validación para hora de recordatorio (formato Lima, Perú)
        const horaRecordatorio = document.getElementById('hora-recordatorio');
        horaRecordatorio?.addEventListener('change', (e) => {
            const hora = e.target.value;
            if (!this.validarHora(hora)) {
                mostrarToast('warning', 'Formato inválido', 'Formato de hora inválido. Use HH:MM (ejemplo: 09:30)');
                e.target.focus();
            }
        });
    }

    mostrarIndicadorCambios(mostrar) {
        const botonGuardar = document.getElementById('guardar-btn');
        if (mostrar) {
            botonGuardar?.classList.add('bg-orange-600', 'hover:bg-orange-700');
            botonGuardar?.classList.remove('bg-blue-600', 'hover:bg-blue-700');
            if (botonGuardar) {
                botonGuardar.innerHTML = `
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    Hay Cambios Pendientes
                `;
            }
        } else {
            botonGuardar?.classList.remove('bg-orange-600', 'hover:bg-orange-700');
            botonGuardar?.classList.add('bg-blue-600', 'hover:bg-blue-700');
            if (botonGuardar) {
                botonGuardar.innerHTML = `
                    <svg class="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3-3m0 0l-3 3m3-3v12"/>
                    </svg>
                    Guardar Cambios
                `;
            }
        }
    }

    mostrarSaveStatus(mostrar, texto = 'Guardando...', duracion = null) {
        const statusDiv = document.getElementById('save-status');
        const spinner = document.getElementById('save-spinner');
        const textoSpan = document.getElementById('save-text');

        if (!statusDiv || !spinner || !textoSpan) return;

        if (mostrar) {
            textoSpan.textContent = texto;
            statusDiv.classList.remove('hidden');
            
            if (duracion) {
                setTimeout(() => {
                    this.mostrarSaveStatus(false);
                }, duracion);
            }
        } else {
            statusDiv.classList.add('hidden');
        }
    }

    mostrarLoading(mostrar) {
        // Implementar indicador de carga global si es necesario
        document.body.style.cursor = mostrar ? 'wait' : 'default';
    }

    async mostrarConfirmacion(titulo, mensaje, textoConfirmar = 'Confirmar', textoCancelar = 'Cancelar') {
        return new Promise((resolve) => {
            // Crear modal de confirmación dinámico
            const modal = document.createElement('div');
            modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
            modal.innerHTML = `
                <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-md w-full p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">${titulo}</h3>
                    <p class="text-gray-600 dark:text-gray-400 mb-6 whitespace-pre-line">${mensaje}</p>
                    <div class="flex justify-end space-x-3">
                        <button id="modal-cancelar" class="btn-secondary">${textoCancelar}</button>
                        <button id="modal-confirmar" class="btn-primary">${textoConfirmar}</button>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);

            // Event listeners
            modal.querySelector('#modal-cancelar').onclick = () => {
                document.body.removeChild(modal);
                resolve(false);
            };

            modal.querySelector('#modal-confirmar').onclick = () => {
                document.body.removeChild(modal);
                resolve(true);
            };

            // Cerrar con escape
            const escapeHandler = (e) => {
                if (e.key === 'Escape') {
                    document.body.removeChild(modal);
                    document.removeEventListener('keydown', escapeHandler);
                    resolve(false);
                }
            };
            document.addEventListener('keydown', escapeHandler);
        });
    }

    destroy() {
        // Limpiar intervalos y event listeners
        if (this.autoSaveInterval) {
            clearInterval(this.autoSaveInterval);
        }
    }

    async limpiarDatosLocales() {
        const confirmacion = await this.mostrarConfirmacion(
            '🗑️ Limpiar datos locales',
            'Esta acción eliminará todos los borradores y datos temporales guardados localmente. ¿Está seguro?',
            'Limpiar',
            'Cancelar'
        );

        if (confirmacion) {
            // Limpiar localStorage
            localStorage.removeItem('configuracion_draft');
            localStorage.removeItem('configuracion_temp');
            localStorage.removeItem('configuracion_backup');
            
            // Limpiar sessionStorage si existe
            sessionStorage.removeItem('configuracion_session');
            
            this.mostrarToast('success', 'Datos limpiados', 'Los datos locales han sido eliminados correctamente');
            
            // Recargar configuración desde servidor
            setTimeout(() => {
                this.cargarConfiguracion();
            }, 1000);
        }
    }
}

// ===== FUNCIONES GLOBALES DE TOAST =====

/**
 * Muestra una notificación toast en la esquina superior derecha
 * @param {string} tipo - Tipo de notificación: 'success', 'error', 'warning', 'info'
 * @param {string} titulo - Título de la notificación
 * @param {string} mensaje - Mensaje de la notificación
 */
function mostrarToast(tipo, titulo, mensaje) {
    const toast = document.getElementById('toast');
    const toastIcon = document.getElementById('toastIcon');
    const toastTitle = document.getElementById('toastTitle');
    const toastMessage = document.getElementById('toastMessage');
    
    if (!toast || !toastIcon || !toastTitle || !toastMessage) {
        console.warn('Elementos del toast no encontrados');
        return;
    }
    
    // Configurar icono según el tipo
    let iconoHTML = '';
    switch (tipo) {
        case 'success':
            iconoHTML = '<svg class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>';
            break;
        case 'error':
            iconoHTML = '<svg class="h-6 w-6 text-red-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>';
            break;
        case 'warning':
            iconoHTML = '<svg class="h-6 w-6 text-yellow-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.732-.833-2.5 0L4.732 13.5c-.77.833.192 2.5 1.732 2.5z" /></svg>';
            break;
        case 'info':
        default:
            iconoHTML = '<svg class="h-6 w-6 text-blue-400" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>';
            break;
    }
    
    toastIcon.innerHTML = iconoHTML;
    toastTitle.textContent = titulo;
    toastMessage.textContent = mensaje;
    
    // Mostrar toast
    toast.classList.remove('hidden');
    
    // Auto cerrar después de 5 segundos
    setTimeout(() => {
        cerrarToast();
    }, 5000);
}

/**
 * Cierra el toast notification
 */
function cerrarToast() {
    const toast = document.getElementById('toast');
    if (toast) {
        toast.classList.add('hidden');
    }
}

// Funciones globales de utilidad
function formatearFechaLima(fecha) {
    const fechaLima = new Date(fecha).toLocaleDateString('es-PE', {
        timeZone: 'America/Lima',
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
    return fechaLima;
}

function formatearHoraLima(hora) {
    if (!hora) return '';
    const [horas, minutos] = hora.split(':');
    return `${horas.padStart(2, '0')}:${minutos.padStart(2, '0')}`;
}

function obtenerFechaHoraLima() {
    const ahora = new Date();
    const fechaLima = ahora.toLocaleDateString('es-PE', {
        timeZone: 'America/Lima',
        day: '2-digit',
        month: '2-digit',
        year: 'numeric'
    });
    const horaLima = ahora.toLocaleTimeString('es-PE', {
        timeZone: 'America/Lima',
        hour: '2-digit',
        minute: '2-digit',
        hour12: false
    });
    return { fecha: fechaLima, hora: horaLima };
}

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    window.configuracionManager = new ConfiguracionManager();
    
    // Mostrar fecha/hora actual de Lima en la interfaz
    const { fecha, hora } = obtenerFechaHoraLima();

    // Inicializar gestión de establecimientos
    window.establecimientosManager = new EstablecimientosManager();
    // Inicializar gestión de plantillas
    window.plantillasManager = new PlantillasManager();
});

// Limpiar al cerrar la página
window.addEventListener('beforeunload', function() {
    if (window.configuracionManager) {
        window.configuracionManager.destroy();
    }
    if (window.establecimientosManager) {
        window.establecimientosManager.destroy();
    }
    if (window.plantillasManager) {
        window.plantillasManager.destroy();
    }
});

// Prevenir cierre si hay cambios no guardados
window.addEventListener('beforeunload', function(e) {
    if (window.configuracionManager && window.configuracionManager.hayChangios) {
        e.preventDefault();
        e.returnValue = '¿Está seguro que desea salir? Hay cambios sin guardar.';
    }
});

/**
 * ✅ GESTIÓN DE PLANTILLAS - JavaScript
 * FUNCIONALIDADES:
 * - Crear nuevas plantillas de inspección
 * - Listar plantillas existentes
 * - Editar plantillas (solo administradores)
 * - Validación de formularios
 * - Integración con API backend
 */
class PlantillasManager {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.cargarPlantillas();
    }

    setupEventListeners() {
        // Formulario de creación de plantilla
        const formCrear = document.getElementById('form-crear-plantilla');
        if (formCrear) {
            formCrear.addEventListener('submit', (e) => {
                e.preventDefault();
                this.crearPlantilla();
            });
        }

        // Botón limpiar formulario
        const btnLimpiar = document.getElementById('btn-limpiar-form-plantilla');
        if (btnLimpiar) {
            btnLimpiar.addEventListener('click', () => {
                this.limpiarFormularioPlantilla();
            });
        }

        // Botón refrescar lista
        const btnRefrescar = document.getElementById('btn-refrescar-plantillas');
        if (btnRefrescar) {
            btnRefrescar.addEventListener('click', () => {
                this.cargarPlantillas();
            });
        }
    }

    async crearPlantilla() {
        try {
            // Obtener datos del formulario
            const datos = {
                nombre: document.getElementById('nombre-plantilla').value.trim(),
                descripcion: document.getElementById('descripcion-plantilla').value.trim(),
                tipo: document.getElementById('tipo-plantilla').value,
                categoria: document.getElementById('categoria-plantilla').value
            };

            // Validar datos
            const validacion = this.validarDatosPlantilla(datos);
            if (!validacion.valida) {
                mostrarToast('error', 'Validación fallida', validacion.mensaje);
                return;
            }

            // Mostrar loading
            this.mostrarLoadingPlantilla(true);

            // Enviar a API
            const response = await fetch('/api/plantillas', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(datos)
            });

            if (response.ok) {
                const resultado = await response.json();
                mostrarToast('success', 'Plantilla creada', 'La plantilla ha sido creada exitosamente');
                this.limpiarFormularioPlantilla();
                this.cargarPlantillas(); // Recargar lista
            } else if (response.status === 400) {
                const error = await response.json();
                mostrarToast('error', 'Error de datos', error.error || 'Datos inválidos');
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para crear plantillas');
            } else if (response.status === 409) {
                mostrarToast('warning', 'Plantilla existente', 'Ya existe una plantilla con ese nombre');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error al crear', 'Error al crear la plantilla: ' + error.message);
        } finally {
            this.mostrarLoadingPlantilla(false);
        }
    }

    validarDatosPlantilla(datos) {
        // Validar nombre
        if (!datos.nombre || datos.nombre.length < 3) {
            return {
                valida: false,
                mensaje: 'El nombre de la plantilla debe tener al menos 3 caracteres'
            };
        }

        // Validar tipo
        if (!datos.tipo) {
            return {
                valida: false,
                mensaje: 'Debe seleccionar un tipo de plantilla'
            };
        }

        return { valida: true };
    }

    async cargarPlantillas() {
        try {
            const listaContainer = document.getElementById('lista-plantillas');
            if (!listaContainer) return;

            // Mostrar loading
            listaContainer.innerHTML = `
                <div class="text-center py-8">
                    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600 mx-auto mb-4"></div>
                    <p class="text-slate-500 dark:text-slate-400">Cargando plantillas...</p>
                </div>
            `;

            // Obtener plantillas
            const response = await fetch('/api/plantillas', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const plantillas = await response.json();
                this.renderizarPlantillas(plantillas);
            } else if (response.status === 403) {
                listaContainer.innerHTML = `
                    <div class="text-center py-8">
                        <i class="ph ph-lock text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                        <p class="text-slate-500 dark:text-slate-400">No tiene permisos para ver plantillas</p>
                    </div>
                `;
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            const listaContainer = document.getElementById('lista-plantillas');
            if (listaContainer) {
                listaContainer.innerHTML = `
                    <div class="text-center py-8">
                        <i class="ph ph-wifi-x text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                        <p class="text-slate-500 dark:text-slate-400">Error al cargar plantillas</p>
                        <button onclick="window.plantillasManager.cargarPlantillas()"
                                class="mt-4 px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 transition-colors">
                            Reintentar
                        </button>
                    </div>
                `;
            }
        }
    }

    renderizarPlantillas(plantillas) {
        const listaContainer = document.getElementById('lista-plantillas');
        if (!listaContainer) return;

        if (!plantillas || plantillas.length === 0) {
            listaContainer.innerHTML = `
                <div class="text-center py-8">
                    <i class="ph ph-clipboard text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                    <p class="text-slate-500 dark:text-slate-400">No hay plantillas registradas</p>
                    <p class="text-sm text-slate-400 dark:text-slate-500 mt-2">Crea tu primera plantilla usando el formulario arriba</p>
                </div>
            `;
            return;
        }

        // Renderizar lista de plantillas
        const html = plantillas.map(plantilla => `
            <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-slate-200 dark:border-slate-600 hover:shadow-md transition-shadow">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <div class="flex items-center space-x-3 mb-2">
                            <div class="w-10 h-10 bg-gradient-to-r from-purple-500 to-pink-600 rounded-lg flex items-center justify-center">
                                <i class="ph ph-clipboard-text text-white text-lg"></i>
                            </div>
                            <div>
                                <h4 class="font-semibold text-slate-900 dark:text-white">${plantilla.nombre}</h4>
                                <p class="text-sm text-slate-500 dark:text-slate-400">${plantilla.tipo}</p>
                            </div>
                        </div>

                        ${plantilla.descripcion ? `
                            <p class="text-sm text-slate-600 dark:text-slate-300 mb-3">${plantilla.descripcion}</p>
                        ` : ''}

                        <div class="flex items-center space-x-4 text-xs text-slate-500 dark:text-slate-400">
                            <span class="flex items-center space-x-1">
                                <i class="ph ph-folder"></i>
                                <span>${plantilla.categoria || 'Sin categoría'}</span>
                            </span>
                            <span class="flex items-center space-x-1">
                                <i class="ph ph-check-circle"></i>
                                <span>${plantilla.items_count || 0} items</span>
                            </span>
                        </div>
                    </div>

                    <div class="flex items-center space-x-2 ml-4">
                        <span class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300">
                            Activa
                        </span>
                    </div>
                </div>

                <div class="mt-4 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                    <span>Creado: ${this.formatearFecha(plantilla.fecha_creacion)}</span>
                    <div class="flex items-center space-x-3">
                        <button onclick="window.plantillasManager.verDetalles(${plantilla.id})"
                                class="text-slate-600 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-300">
                            <i class="ph ph-eye mr-1"></i>Ver
                        </button>
                        ${window.userRole === 'Administrador' ? `
                        <button onclick="window.plantillasManager.editarPlantilla(${plantilla.id})"
                                class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
                            <i class="ph ph-pencil mr-1"></i>Editar
                        </button>
                        <button onclick="window.plantillasManager.eliminarPlantilla(${plantilla.id})"
                                class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300">
                            <i class="ph ph-trash mr-1"></i>Eliminar
                        </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `).join('');

        listaContainer.innerHTML = html;
    }

    limpiarFormularioPlantilla() {
        const form = document.getElementById('form-crear-plantilla');
        if (form) {
            form.reset();
        }
    }

    mostrarLoadingPlantilla(mostrar) {
        const btnSubmit = document.querySelector('#form-crear-plantilla button[type="submit"]');
        if (btnSubmit) {
            if (mostrar) {
                btnSubmit.disabled = true;
                btnSubmit.innerHTML = `
                    <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Creando...
                `;
            } else {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = `
                    <i class="ph ph-plus mr-2"></i>
                    Crear Plantilla
                `;
            }
        }
    }

    formatearFecha(fechaString) {
        if (!fechaString) return 'N/A';
        const fecha = new Date(fechaString);
        return fecha.toLocaleDateString('es-PE', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        });
    }

    editarPlantilla(id) {
        // Redirigir a la página de edición de plantilla
        window.location.href = `/admin/editar-plantilla/${id}`;
    }

    async eliminarPlantilla(id) {
        const confirmacion = await this.mostrarConfirmacion(
            '🗑️ Eliminar plantilla',
            '¿Está seguro que desea eliminar esta plantilla?\n\nEsta acción NO se puede deshacer y puede afectar a los establecimientos que la utilizan.',
            'Eliminar',
            'Cancelar'
        );

        if (!confirmacion) return;

        try {
            const response = await fetch(`/api/plantillas/${id}`, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                mostrarToast('success', 'Plantilla eliminada', 'La plantilla ha sido eliminada exitosamente');
                this.cargarPlantillas(); // Recargar lista
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para eliminar plantillas');
            } else if (response.status === 409) {
                mostrarToast('warning', 'No se puede eliminar', 'La plantilla está siendo utilizada por establecimientos');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error', 'Error al eliminar la plantilla');
        }
    }

    verDetalles(id) {
        // Obtener datos de la plantilla y mostrar modal de detalles
        this.mostrarModalDetalles(id);
    }

    async mostrarModalDetalles(id) {
        try {
            // Obtener datos de la plantilla
            const response = await fetch(`/api/plantillas/${id}`, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const plantilla = await response.json();
                this.crearModalDetalles(plantilla);
            } else {
                mostrarToast('error', 'Error', 'No se pudo obtener los datos de la plantilla');
            }
        } catch (error) {
            mostrarToast('error', 'Error', 'Error al cargar datos de la plantilla');
        }
    }

    crearModalDetalles(plantilla) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
        modal.id = 'modal-detalles-plantilla';

        // Formatear fecha de creación
        const fechaCreacion = plantilla.fecha_creacion
            ? new Date(plantilla.fecha_creacion).toLocaleDateString('es-PE', {
                day: '2-digit',
                month: 'long',
                year: 'numeric'
              })
            : 'No disponible';

        modal.innerHTML = `
            <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                <div class="p-6">
                    <!-- Header -->
                    <div class="flex items-center justify-between mb-6">
                        <div class="flex items-center gap-4">
                            <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-600 rounded-xl flex items-center justify-center shadow-lg">
                                <i class="ph ph-clipboard-text text-white text-xl"></i>
                            </div>
                            <div>
                                <h2 class="text-2xl font-bold text-slate-900 dark:text-white">${plantilla.nombre}</h2>
                                <p class="text-sm text-slate-600 dark:text-slate-300">ID: ${plantilla.id}</p>
                            </div>
                        </div>
                        <button onclick="this.closest('#modal-detalles-plantilla').remove()"
                                class="w-8 h-8 bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-lg flex items-center justify-center transition-colors">
                            <i class="ph ph-x text-slate-600 dark:text-slate-300"></i>
                        </button>
                    </div>

                    <!-- Información Principal -->
                    <div class="space-y-6">
                        <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                <i class="ph ph-info text-purple-600"></i>
                                Información General
                            </h3>
                            <div class="space-y-3">
                                <div class="flex items-center gap-3">
                                    <i class="ph ph-tag text-slate-400 w-5"></i>
                                    <div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Tipo</p>
                                        <p class="font-medium text-slate-900 dark:text-white">${plantilla.tipo || 'No especificado'}</p>
                                    </div>
                                </div>
                                <div class="flex items-center gap-3">
                                    <i class="ph ph-folder text-slate-400 w-5"></i>
                                    <div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Categoría</p>
                                        <p class="font-medium text-slate-900 dark:text-white">${plantilla.categoria || 'Sin categoría'}</p>
                                    </div>
                                </div>
                                ${plantilla.descripcion ? `
                                <div class="flex items-start gap-3">
                                    <i class="ph ph-text-align-left text-slate-400 w-5 mt-0.5"></i>
                                    <div class="flex-1">
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Descripción</p>
                                        <p class="font-medium text-slate-900 dark:text-white">${plantilla.descripcion}</p>
                                    </div>
                                </div>
                                ` : ''}
                            </div>
                        </div>

                        <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                <i class="ph ph-chart-bar text-indigo-600"></i>
                                Estadísticas
                            </h3>
                            <div class="grid grid-cols-2 gap-4">
                                <div class="text-center">
                                    <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">${plantilla.items_count || 0}</div>
                                    <p class="text-sm text-slate-500 dark:text-slate-400">Items de inspección</p>
                                </div>
                                <div class="text-center">
                                    <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">${plantilla.establecimientos_count || 0}</div>
                                    <p class="text-sm text-slate-500 dark:text-slate-400">Establecimientos</p>
                                </div>
                            </div>
                        </div>

                        <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                <i class="ph ph-calendar text-green-600"></i>
                                Información del Sistema
                            </h3>
                            <div class="space-y-3">
                                <div class="flex items-center gap-3">
                                    <i class="ph ph-calendar-plus text-slate-400 w-5"></i>
                                    <div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Fecha de creación</p>
                                        <p class="font-medium text-slate-900 dark:text-white">${fechaCreacion}</p>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Acciones -->
                    <div class="flex flex-col sm:flex-row gap-3 pt-6 border-t border-slate-200 dark:border-slate-600">
                        ${window.userRole === 'Administrador' ? `
                        <button onclick="window.plantillasManager.editarPlantilla(${plantilla.id})"
                                class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium rounded-lg shadow-sm text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105">
                            <i class="ph ph-pencil"></i>
                            Editar Plantilla
                        </button>
                        ` : ''}
                        <button onclick="this.closest('#modal-detalles-plantilla').remove()"
                                class="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium rounded-lg text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500 transition-all duration-200 border border-slate-300 dark:border-slate-600">
                            <i class="ph ph-x"></i>
                            Cerrar
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Cerrar con escape
        const escapeHandler = (e) => {
            if (e.key === 'Escape') {
                document.body.removeChild(modal);
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
    }

    async mostrarConfirmacion(titulo, mensaje, textoConfirmar = 'Confirmar', textoCancelar = 'Cancelar') {
        return new Promise((resolve) => {
            // Crear modal de confirmación dinámico
            const modal = document.createElement('div');
            modal.className = 'fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
            modal.innerHTML = `
                <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-md w-full p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">${titulo}</h3>
                    <p class="text-gray-600 dark:text-gray-400 mb-6 whitespace-pre-line">${mensaje}</p>
                    <div class="flex justify-end space-x-3">
                        <button id="modal-cancelar" class="btn-secondary">${textoCancelar}</button>
                        <button id="modal-confirmar" class="btn-primary">${textoConfirmar}</button>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);

            // Event listeners
            modal.querySelector('#modal-cancelar').onclick = () => {
                document.body.removeChild(modal);
                resolve(false);
            };

            modal.querySelector('#modal-confirmar').onclick = () => {
                document.body.removeChild(modal);
                resolve(true);
            };

            // Cerrar con escape
            const escapeHandler = (e) => {
                if (e.key === 'Escape') {
                    document.body.removeChild(modal);
                    document.removeEventListener('keydown', escapeHandler);
                    resolve(false);
                }
            };
            document.addEventListener('keydown', escapeHandler);
        });
    }

    destroy() {
        // Limpiar event listeners si es necesario
    }
}

/**
 * ✅ GESTIÓN DE ESTABLECIMIENTOS - JavaScript
 * FUNCIONALIDADES:
 * - Crear nuevos establecimientos
 * - Listar establecimientos existentes
 * - Validación de formularios
 * - Integración con API backend
 */
class EstablecimientosManager {
    constructor() {
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.cargarTiposEstablecimiento();
        this.cargarEstablecimientos();
    }

    setupEventListeners() {
        // Formulario de creación de establecimiento
        const formCrear = document.getElementById('form-crear-establecimiento');
        if (formCrear) {
            formCrear.addEventListener('submit', (e) => {
                e.preventDefault();
                this.crearEstablecimiento();
            });
        }

        // Botón limpiar formulario
        const btnLimpiar = document.getElementById('btn-limpiar-form');
        if (btnLimpiar) {
            btnLimpiar.addEventListener('click', () => {
                this.limpiarFormulario();
            });
        }

        // Botón refrescar lista
        const btnRefrescar = document.getElementById('btn-refrescar-lista');
        if (btnRefrescar) {
            btnRefrescar.addEventListener('click', () => {
                this.cargarEstablecimientos();
            });
        }
    }

    async cargarTiposEstablecimiento() {
        try {
            const response = await fetch('/api/tipos-establecimiento', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const tipos = await response.json();
                this.poblarSelectTipos(tipos);
            } else {
                // Usar tipos por defecto
                this.poblarSelectTipos([
                    { id: 1, nombre: 'Restaurante' },
                    { id: 2, nombre: 'Cafetería' },
                    { id: 3, nombre: 'Bar' },
                    { id: 4, nombre: 'Hotel' },
                    { id: 5, nombre: 'Supermercado' },
                    { id: 6, nombre: 'Tienda' },
                    { id: 7, nombre: 'Otro' }
                ]);
            }
        } catch (error) {
            // Usar tipos por defecto en caso de error
            this.poblarSelectTipos([
                { id: 1, nombre: 'Restaurante' },
                { id: 2, nombre: 'Cafetería' },
                { id: 3, nombre: 'Bar' },
                { id: 4, nombre: 'Hotel' },
                { id: 5, nombre: 'Supermercado' },
                { id: 6, nombre: 'Tienda' },
                { id: 7, nombre: 'Otro' }
            ]);
        }
    }

    poblarSelectTipos(tipos) {
        const select = document.getElementById('tipo-establecimiento');
        if (!select) return;

        // Limpiar opciones existentes excepto la primera
        while (select.options.length > 1) {
            select.remove(1);
        }

        // Agregar tipos desde la API
        tipos.forEach(tipo => {
            const option = document.createElement('option');
            option.value = tipo.id;
            option.textContent = tipo.nombre;
            select.appendChild(option);
        });
    }

    async crearEstablecimiento() {
        try {
            // Obtener datos del formulario
            const tipoSelect = document.getElementById('tipo-establecimiento');
            const camposAdicionales = document.getElementById('campos-adicionales');
            const camposVisibles = camposAdicionales && !camposAdicionales.classList.contains('hidden');

            const datos = {
                nombre: document.getElementById('nombre-establecimiento').value.trim(),
                tipo_establecimiento_id: tipoSelect.value,
                correo: '' // El backend maneja este campo opcionalmente
            };

            // Agregar campos adicionales solo si están visibles
            if (camposVisibles) {
                const direccion = document.getElementById('direccion-establecimiento').value.trim();
                const distrito = document.getElementById('distrito-establecimiento').value.trim();
                const telefono = document.getElementById('telefono-establecimiento').value.trim();

                if (direccion) datos.direccion = direccion;
                if (distrito) datos.distrito = distrito;
                if (telefono) datos.telefono = telefono;
            }

            // Validar datos
            const validacion = this.validarDatosEstablecimiento(datos);
            if (!validacion.valida) {
                mostrarToast('error', 'Validación fallida', validacion.mensaje);
                return;
            }

            // Mostrar loading
            this.mostrarLoadingEstablecimiento(true);

            // Enviar a API
            const response = await fetch('/api/inspector/establecimientos', {
                method: 'POST',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(datos)
            });

            if (response.ok) {
                const resultado = await response.json();
                mostrarToast('success', 'Establecimiento creado', 'El establecimiento ha sido creado exitosamente');
                this.limpiarFormulario();
                this.cargarEstablecimientos(); // Recargar lista
            } else if (response.status === 400) {
                const error = await response.json();
                mostrarToast('error', 'Error de datos', error.error || 'Datos inválidos');
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para crear establecimientos');
            } else if (response.status === 409) {
                mostrarToast('warning', 'Establecimiento existente', 'Ya existe un establecimiento con ese nombre');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error al crear', 'Error al crear el establecimiento: ' + error.message);
        } finally {
            this.mostrarLoadingEstablecimiento(false);
        }
    }

    validarDatosEstablecimiento(datos) {
        // Validar nombre
        if (!datos.nombre || datos.nombre.length < 3) {
            return {
                valida: false,
                mensaje: 'El nombre del establecimiento debe tener al menos 3 caracteres'
            };
        }

        // Validar tipo
        if (!datos.tipo_establecimiento_id) {
            return {
                valida: false,
                mensaje: 'Debe seleccionar un tipo de establecimiento'
            };
        }

        // Verificar si los campos adicionales están visibles
        const camposAdicionales = document.getElementById('campos-adicionales');
        const camposVisibles = camposAdicionales && !camposAdicionales.classList.contains('hidden');

        // Validar dirección solo si los campos adicionales están visibles
        if (camposVisibles && (!datos.direccion || datos.direccion.length < 10)) {
            return {
                valida: false,
                mensaje: 'La dirección debe tener al menos 10 caracteres'
            };
        }

        // Validar teléfono (opcional pero con formato)
        if (datos.telefono && !this.validarTelefono(datos.telefono)) {
            return {
                valida: false,
                mensaje: 'El formato del teléfono no es válido'
            };
        }

        return { valida: true };
    }

    validarTelefono(telefono) {
        // Formato peruano: (01) 123-4567 o 912345678
        const regex = /^(\(\d{2}\)\s?)?\d{3}-?\d{4}$|^\d{9}$/;
        return regex.test(telefono.replace(/\s/g, ''));
    }

    async cargarEstablecimientos() {
        try {
            const listaContainer = document.getElementById('lista-establecimientos');
            if (!listaContainer) return;

            // Mostrar loading
            listaContainer.innerHTML = `
                <div class="text-center py-8">
                    <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4"></div>
                    <p class="text-slate-500 dark:text-slate-400">Cargando establecimientos...</p>
                </div>
            `;

            // Obtener establecimientos (usando endpoint existente o crear uno nuevo)
            const response = await fetch('/api/dashboard/establecimientos', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const establecimientos = await response.json();
                this.renderizarEstablecimientos(establecimientos);
            } else if (response.status === 403) {
                listaContainer.innerHTML = `
                    <div class="text-center py-8">
                        <i class="ph ph-lock text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                        <p class="text-slate-500 dark:text-slate-400">No tiene permisos para ver establecimientos</p>
                    </div>
                `;
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            const listaContainer = document.getElementById('lista-establecimientos');
            if (listaContainer) {
                listaContainer.innerHTML = `
                    <div class="text-center py-8">
                        <i class="ph ph-wifi-x text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                        <p class="text-slate-500 dark:text-slate-400">Error al cargar establecimientos</p>
                        <button onclick="window.establecimientosManager.cargarEstablecimientos()"
                                class="mt-4 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors">
                            Reintentar
                        </button>
                    </div>
                `;
            }
        }
    }

    renderizarEstablecimientos(establecimientos) {
        const listaContainer = document.getElementById('lista-establecimientos');
        if (!listaContainer) return;

        if (!establecimientos || establecimientos.length === 0) {
            listaContainer.innerHTML = `
                <div class="text-center py-8">
                    <i class="ph ph-buildings text-4xl text-slate-400 dark:text-slate-500 mb-4"></i>
                    <p class="text-slate-500 dark:text-slate-400">No hay establecimientos registrados</p>
                    <p class="text-sm text-slate-400 dark:text-slate-500 mt-2">Crea tu primer establecimiento usando el formulario arriba</p>
                </div>
            `;
            return;
        }

        // Renderizar lista de establecimientos
        const html = establecimientos.map(establecimiento => `
            <div class="bg-white dark:bg-slate-700 rounded-lg p-4 border border-slate-200 dark:border-slate-600 hover:shadow-md transition-shadow">
                <div class="flex items-start justify-between">
                    <div class="flex-1">
                        <div class="flex items-center space-x-3 mb-2">
                            <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-purple-600 rounded-lg flex items-center justify-center">
                                <i class="ph ph-building text-white text-lg"></i>
                            </div>
                            <div>
                                <h4 class="font-semibold text-slate-900 dark:text-white">${establecimiento.nombre}</h4>
                                <p class="text-sm text-slate-500 dark:text-slate-400">${establecimiento.tipo}</p>
                            </div>
                        </div>

                        <div class="space-y-1 text-sm text-slate-600 dark:text-slate-300">
                            <div class="flex items-center space-x-2">
                                <i class="ph ph-map-pin text-slate-400"></i>
                                <span>${establecimiento.direccion}</span>
                            </div>
                            ${establecimiento.distrito ? `
                                <div class="flex items-center space-x-2">
                                    <i class="ph ph-city text-slate-400"></i>
                                    <span>${establecimiento.distrito}</span>
                                </div>
                            ` : ''}
                            ${establecimiento.telefono ? `
                                <div class="flex items-center space-x-2">
                                    <i class="ph ph-phone text-slate-400"></i>
                                    <span>${establecimiento.telefono}</span>
                                </div>
                            ` : ''}
                        </div>
                    </div>

                    <div class="flex items-center space-x-2 ml-4">
                        <span class="px-2 py-1 text-xs font-medium rounded-full ${
                            establecimiento.activo
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300'
                                : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-300'
                        }">
                            ${establecimiento.activo ? 'Activo' : 'Inactivo'}
                        </span>
                    </div>
                </div>

                <div class="mt-4 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
                    <span>Creado: ${this.formatearFecha(establecimiento.fecha_creacion)}</span>
                    <div class="flex items-center space-x-3">
                        <button onclick="window.establecimientosManager.editarEstablecimiento(${establecimiento.id})"
                                class="text-blue-600 hover:text-blue-800 dark:text-blue-400 dark:hover:text-blue-300">
                            <i class="ph ph-pencil mr-1"></i>Editar
                        </button>
                        <button onclick="window.establecimientosManager.verDetalles(${establecimiento.id})"
                                class="text-slate-600 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-300">
                            <i class="ph ph-eye mr-1"></i>Ver
                        </button>
                        <button onclick="window.establecimientosManager.gestionarItems(${establecimiento.id})"
                                class="text-purple-600 hover:text-purple-800 dark:text-purple-400 dark:hover:text-purple-300">
                            <i class="ph ph-list-checks mr-1"></i>Gestionar Items
                        </button>
                        <button onclick="window.establecimientosManager.toggleEstado(${establecimiento.id}, ${establecimiento.activo})"
                                class="text-${establecimiento.activo ? 'orange' : 'green'}-600 hover:text-${establecimiento.activo ? 'orange' : 'green'}-800 dark:text-${establecimiento.activo ? 'orange' : 'green'}-400 dark:hover:text-${establecimiento.activo ? 'orange' : 'green'}-300">
                            <i class="ph ph-${establecimiento.activo ? 'eye-slash' : 'eye'} mr-1"></i>${establecimiento.activo ? 'Deshabilitar' : 'Habilitar'}
                        </button>
                        ${window.userRole === 'Administrador' ? `
                        <button onclick="window.establecimientosManager.eliminarEstablecimiento(${establecimiento.id})"
                                class="text-red-600 hover:text-red-800 dark:text-red-400 dark:hover:text-red-300">
                            <i class="ph ph-trash mr-1"></i>Eliminar
                        </button>
                        ` : ''}
                    </div>
                </div>
            </div>
        `).join('');

        listaContainer.innerHTML = html;
    }

    limpiarFormulario() {
        const form = document.getElementById('form-crear-establecimiento');
        if (form) {
            form.reset();
        }

        // Ocultar campos adicionales si están visibles
        const camposAdicionales = document.getElementById('campos-adicionales');
        const btnToggle = document.getElementById('btn-toggle-campos-adicionales');
        const textoToggle = document.getElementById('texto-toggle');
        const iconoToggle = document.getElementById('icono-toggle');

        if (camposAdicionales && !camposAdicionales.classList.contains('hidden')) {
            camposAdicionales.classList.add('hidden');
            if (textoToggle) textoToggle.textContent = 'Agregar datos adicionales';
            if (iconoToggle) {
                iconoToggle.classList.remove('ph-caret-up');
                iconoToggle.classList.add('ph-caret-down');
            }
            if (btnToggle) {
                btnToggle.classList.remove('text-orange-700', 'dark:text-orange-300', 'bg-orange-50', 'dark:bg-orange-900/20', 'hover:bg-orange-100', 'dark:hover:bg-orange-900/30');
                btnToggle.classList.add('text-blue-700', 'dark:text-blue-300', 'bg-blue-50', 'dark:bg-blue-900/20', 'hover:bg-blue-100', 'dark:hover:bg-blue-900/30');
            }
        }
    }

    mostrarLoadingEstablecimiento(mostrar) {
        const btnSubmit = document.querySelector('#form-crear-establecimiento button[type="submit"]');
        if (btnSubmit) {
            if (mostrar) {
                btnSubmit.disabled = true;
                btnSubmit.innerHTML = `
                    <div class="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                    Creando...
                `;
            } else {
                btnSubmit.disabled = false;
                btnSubmit.innerHTML = `
                    <i class="ph ph-plus mr-2"></i>
                    Crear Establecimiento
                `;
            }
        }
    }

    formatearFecha(fechaString) {
        if (!fechaString) return 'N/A';
        const fecha = new Date(fechaString);
        return fecha.toLocaleDateString('es-PE', {
            day: '2-digit',
            month: 'short',
            year: 'numeric'
        });
    }

    editarEstablecimiento(id) {
        // Obtener datos del establecimiento y mostrar modal de edición
        this.mostrarModalEdicion(id);
    }

    gestionarItems(id) {
        // Redirigir a la página de gestión de items del establecimiento
        window.location.href = `/establecimientos/${id}/items/gestionar`;
    }

    async mostrarModalEdicion(id) {
        try {
            // Obtener datos del establecimiento
            const response = await fetch(`/api/establecimientos/${id}`, {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const establecimiento = await response.json();
                this.crearModalEdicion(establecimiento);
            } else {
                mostrarToast('error', 'Error', 'No se pudo obtener los datos del establecimiento');
            }
        } catch (error) {
            mostrarToast('error', 'Error', 'Error al cargar datos del establecimiento');
        }
    }

    crearModalEdicion(establecimiento) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
        modal.id = 'modal-editar-establecimiento';

        modal.innerHTML = `
            <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
                <div class="p-6">
                    <div class="flex items-center gap-3 mb-6">
                        <div class="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center shadow-md">
                            <i class="ph ph-pencil text-white text-lg"></i>
                        </div>
                        <div>
                            <h3 class="text-lg font-semibold text-slate-900 dark:text-white">Editar Establecimiento</h3>
                            <p class="text-sm text-slate-600 dark:text-slate-300">Modifica los datos del establecimiento</p>
                        </div>
                    </div>

                    <form id="form-editar-establecimiento" class="space-y-4">
                        <input type="hidden" id="edit-establecimiento-id" value="${establecimiento.id}">

                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                            <!-- Nombre -->
                            <div class="sm:col-span-2">
                                <label for="edit-nombre-establecimiento" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    <i class="ph ph-building mr-1"></i>
                                    Nombre del Establecimiento *
                                </label>
                                <input type="text" id="edit-nombre-establecimiento" required
                                       value="${establecimiento.nombre || ''}"
                                       class="w-full px-3 sm:px-4 py-2 sm:py-3 border border-slate-300 dark:border-slate-600 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-white transition-all duration-200 min-h-[44px]">
                            </div>

                            <!-- Tipo -->
                            <div class="sm:col-span-2">
                                <label for="edit-tipo-establecimiento" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    <i class="ph ph-tag mr-1"></i>
                                    Tipo *
                                </label>
                                <select id="edit-tipo-establecimiento" required
                                        class="w-full px-3 sm:px-4 py-2 sm:py-3 border border-slate-300 dark:border-slate-600 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-white transition-all duration-200 min-h-[44px]">
                                    <option value="">Selecciona un tipo</option>
                                </select>
                            </div>

                            <!-- Distrito -->
                            <div>
                                <label for="edit-distrito-establecimiento" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    <i class="ph ph-city mr-1"></i>
                                    Distrito
                                </label>
                                <input type="text" id="edit-distrito-establecimiento"
                                       value="${establecimiento.distrito || ''}"
                                       class="w-full px-3 sm:px-4 py-2 sm:py-3 border border-slate-300 dark:border-slate-600 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-white transition-all duration-200 min-h-[44px]">
                            </div>

                            <!-- Dirección -->
                            <div class="sm:col-span-2">
                                <label for="edit-direccion-establecimiento" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    <i class="ph ph-map-pin mr-1"></i>
                                    Dirección
                                </label>
                                <input type="text" id="edit-direccion-establecimiento"
                                       value="${establecimiento.direccion || ''}"
                                       class="w-full px-3 sm:px-4 py-2 sm:py-3 border border-slate-300 dark:border-slate-600 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-white transition-all duration-200 min-h-[44px]">
                            </div>

                            <!-- Teléfono -->
                            <div>
                                <label for="edit-telefono-establecimiento" class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    <i class="ph ph-phone mr-1"></i>
                                    Teléfono
                                </label>
                                <input type="tel" id="edit-telefono-establecimiento"
                                       value="${establecimiento.telefono || ''}"
                                       class="w-full px-3 sm:px-4 py-2 sm:py-3 border border-slate-300 dark:border-slate-600 rounded-lg shadow-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-slate-700 dark:text-white transition-all duration-200 min-h-[44px]">
                            </div>
                        </div>

                        <!-- Botones -->
                        <div class="flex flex-col sm:flex-row gap-3 sm:gap-4 pt-6 border-t border-slate-200 dark:border-slate-600">
                            <button type="button" onclick="this.closest('#modal-editar-establecimiento').remove()"
                                    class="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2 sm:py-2.5 text-sm font-medium rounded-lg text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500 transition-all duration-200 border border-slate-300 dark:border-slate-600 min-h-[44px]">
                                <i class="ph ph-x"></i>
                                Cancelar
                            </button>
                            <button type="submit"
                                    class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 sm:py-2.5 text-sm font-medium rounded-lg shadow-sm text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105 min-h-[44px]">
                                <i class="ph ph-floppy-disk"></i>
                                Guardar Cambios
                            </button>
                        </div>
                    </form>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Cargar tipos de establecimiento
        this.cargarTiposEnModal(establecimiento.tipo_establecimiento_id);

        // Event listener para el formulario
        const form = modal.querySelector('#form-editar-establecimiento');
        form.addEventListener('submit', (e) => {
            e.preventDefault();
            this.guardarEdicionEstablecimiento();
        });
    }

    async cargarTiposEnModal(tipoSeleccionado = null) {
        try {
            const response = await fetch('/api/tipos-establecimiento', {
                method: 'GET',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const tipos = await response.json();
                const select = document.getElementById('edit-tipo-establecimiento');

                tipos.forEach(tipo => {
                    const option = document.createElement('option');
                    option.value = tipo.id;
                    option.textContent = tipo.nombre;
                    if (tipoSeleccionado && tipo.id == tipoSeleccionado) {
                        option.selected = true;
                    }
                    select.appendChild(option);
                });
            }
        } catch (error) {
            console.error('Error cargando tipos:', error);
        }
    }

    async guardarEdicionEstablecimiento() {
        try {
            const id = document.getElementById('edit-establecimiento-id').value;
            const tipoSelect = document.getElementById('edit-tipo-establecimiento');

            const datos = {
                nombre: document.getElementById('edit-nombre-establecimiento').value.trim(),
                tipo_establecimiento_id: tipoSelect.value,
                direccion: document.getElementById('edit-direccion-establecimiento').value.trim(),
                distrito: document.getElementById('edit-distrito-establecimiento').value.trim(),
                telefono: document.getElementById('edit-telefono-establecimiento').value.trim(),
                correo: '' // El backend maneja este campo opcionalmente
            };

            // Validar datos
            const validacion = this.validarDatosEstablecimiento(datos);
            if (!validacion.valida) {
                mostrarToast('error', 'Validación fallida', validacion.mensaje);
                return;
            }

            // Enviar a API
            const response = await fetch(`/api/establecimientos/${id}`, {
                method: 'PUT',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify(datos)
            });

            if (response.ok) {
                mostrarToast('success', 'Establecimiento actualizado', 'Los cambios han sido guardados exitosamente');
                document.getElementById('modal-editar-establecimiento').remove();
                this.cargarEstablecimientos(); // Recargar lista
            } else if (response.status === 400) {
                const error = await response.json();
                mostrarToast('error', 'Error de datos', error.error || 'Datos inválidos');
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para editar establecimientos');
            } else if (response.status === 409) {
                mostrarToast('warning', 'Nombre existente', 'Ya existe un establecimiento con ese nombre');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error al guardar', 'Error al guardar los cambios: ' + error.message);
        }
    }

    async toggleEstado(id, estadoActual) {
        const accion = estadoActual ? 'deshabilitar' : 'habilitar';
        const confirmacion = await this.mostrarConfirmacion(
            `¿${accion.charAt(0).toUpperCase() + accion.slice(1)} establecimiento?`,
            `¿Está seguro que desea ${accion} este establecimiento? ${estadoActual ? 'Los inspectores no podrán seleccionar este establecimiento para inspecciones.' : 'El establecimiento volverá a estar disponible para inspecciones.'}`,
            accion.charAt(0).toUpperCase() + accion.slice(1),
            'Cancelar'
        );

        if (!confirmacion) return;

        try {
            const response = await fetch(`/api/establecimientos/${id}/estado`, {
                method: 'PUT',
                credentials: 'include',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json'
                },
                body: JSON.stringify({ activo: !estadoActual })
            });

            if (response.ok) {
                mostrarToast('success', 'Estado actualizado',
                    `Establecimiento ${!estadoActual ? 'habilitado' : 'deshabilitado'} exitosamente`);
                this.cargarEstablecimientos(); // Recargar lista
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para cambiar el estado del establecimiento');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error', 'Error al cambiar el estado del establecimiento');
        }
    }

    async eliminarEstablecimiento(id) {
        const confirmacion = await this.mostrarConfirmacion(
            '🗑️ Eliminar establecimiento',
            '¿Está seguro que desea eliminar este establecimiento?\n\nEsta acción NO se puede deshacer y eliminará permanentemente el establecimiento y todas sus inspecciones asociadas.',
            'Eliminar',
            'Cancelar'
        );

        if (!confirmacion) return;

        try {
            const response = await fetch(`/api/establecimientos/${id}`, {
                method: 'DELETE',
                credentials: 'include',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                mostrarToast('success', 'Establecimiento eliminado', 'El establecimiento ha sido eliminado permanentemente');
                this.cargarEstablecimientos(); // Recargar lista
            } else if (response.status === 403) {
                mostrarToast('error', 'Sin permisos', 'No tiene permisos para eliminar establecimientos');
            } else if (response.status === 409) {
                mostrarToast('warning', 'No se puede eliminar', 'El establecimiento tiene inspecciones asociadas y no puede ser eliminado');
            } else {
                throw new Error(`Error del servidor: ${response.status}`);
            }

        } catch (error) {
            mostrarToast('error', 'Error', 'Error al eliminar el establecimiento');
        }
    }

    verDetalles(id) {
        // Obtener datos del establecimiento y mostrar modal de detalles
        this.mostrarModalDetalles(id);
    }

    async mostrarModalDetalles(id) {
        try {
            // Obtener datos del establecimiento y estadísticas en paralelo
            const [establecimientoResponse, estadisticasResponse] = await Promise.all([
                fetch(`/api/establecimientos/${id}`, {
                    method: 'GET',
                    credentials: 'include',
                    headers: {
                        'Accept': 'application/json'
                    }
                }),
                fetch(`/api/establecimientos/${id}/estadisticas`, {
                    method: 'GET',
                    credentials: 'include',
                    headers: {
                        'Accept': 'application/json'
                    }
                })
            ]);

            if (establecimientoResponse.ok && estadisticasResponse.ok) {
                const establecimiento = await establecimientoResponse.json();
                const estadisticas = await estadisticasResponse.json();
                this.crearModalDetalles(establecimiento, estadisticas);
            } else {
                // Si falla estadísticas, mostrar solo datos básicos
                if (establecimientoResponse.ok) {
                    const establecimiento = await establecimientoResponse.json();
                    this.crearModalDetalles(establecimiento, null);
                } else {
                    mostrarToast('error', 'Error', 'No se pudo obtener los datos del establecimiento');
                }
            }
        } catch (error) {
            mostrarToast('error', 'Error', 'Error al cargar datos del establecimiento');
        }
    }

    crearModalDetalles(establecimiento, estadisticas = null) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
        modal.id = 'modal-detalles-establecimiento';

        // Formatear fecha de creación
        const fechaCreacion = establecimiento.fecha_creacion
            ? new Date(establecimiento.fecha_creacion).toLocaleDateString('es-PE', {
                day: '2-digit',
                month: 'long',
                year: 'numeric'
              })
            : 'No disponible';

        // Preparar estadísticas
        const stats = estadisticas || {
            totales: { inspecciones: 0, encargados: 0, jefes: 0, evaluaciones: 0 },
            inspecciones_por_estado: { pendientes: 0, en_proceso: 0, completadas: 0 },
            inspecciones_recientes: 0
        };

        modal.innerHTML = `
            <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
                <div class="p-6">
                    <!-- Header -->
                    <div class="flex items-center justify-between mb-6">
                        <div class="flex items-center gap-4">
                            <div class="w-12 h-12 bg-gradient-to-r from-blue-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
                                <i class="ph ph-building text-white text-xl"></i>
                            </div>
                            <div>
                                <h2 class="text-2xl font-bold text-slate-900 dark:text-white">${establecimiento.nombre}</h2>
                                <p class="text-sm text-slate-600 dark:text-slate-300">ID: ${establecimiento.id}</p>
                            </div>
                        </div>
                        <button onclick="this.closest('#modal-detalles-establecimiento').remove()"
                                class="w-8 h-8 bg-slate-100 dark:bg-slate-700 hover:bg-slate-200 dark:hover:bg-slate-600 rounded-lg flex items-center justify-center transition-colors">
                            <i class="ph ph-x text-slate-600 dark:text-slate-300"></i>
                        </button>
                    </div>

                    <!-- Estado -->
                    <div class="mb-6">
                        <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full text-sm font-medium ${
                            establecimiento.activo
                                ? 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-300'
                                : 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-300'
                        }">
                            <i class="ph ph-${establecimiento.activo ? 'check-circle' : 'x-circle'}"></i>
                            ${establecimiento.activo ? 'Activo' : 'Inactivo'}
                        </span>
                    </div>

                    <!-- Información Principal -->
                    <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
                        <!-- Columna Izquierda -->
                        <div class="space-y-6">
                            <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                                <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                    <i class="ph ph-info text-blue-600"></i>
                                    Información General
                                </h3>
                                <div class="space-y-3">
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-tag text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Tipo</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${establecimiento.tipo || 'No especificado'}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-start gap-3">
                                        <i class="ph ph-map-pin text-slate-400 w-5 mt-0.5"></i>
                                        <div class="flex-1">
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Dirección</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${establecimiento.direccion || 'No especificada'}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-city text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Distrito</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${establecimiento.distrito || 'No especificado'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                                <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                    <i class="ph ph-phone text-green-600"></i>
                                    Contacto
                                </h3>
                                <div class="space-y-3">
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-phone text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Teléfono</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${establecimiento.telefono || 'No especificado'}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-envelope text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Correo</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${establecimiento.correo || 'No especificado'}</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <!-- Columna Derecha -->
                        <div class="space-y-6">
                            <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                                <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                    <i class="ph ph-chart-bar text-purple-600"></i>
                                    Estadísticas
                                </h3>
                                <div class="grid grid-cols-2 gap-4">
                                    <div class="text-center">
                                        <div class="text-2xl font-bold text-blue-600 dark:text-blue-400">${stats.totales.inspecciones}</div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Inspecciones</p>
                                    </div>
                                    <div class="text-center">
                                        <div class="text-2xl font-bold text-green-600 dark:text-green-400">${stats.totales.encargados}</div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Encargados</p>
                                    </div>
                                    <div class="text-center">
                                        <div class="text-2xl font-bold text-orange-600 dark:text-orange-400">${stats.totales.jefes}</div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Jefes</p>
                                    </div>
                                    <div class="text-center">
                                        <div class="text-2xl font-bold text-purple-600 dark:text-purple-400">${stats.totales.evaluaciones}</div>
                                        <p class="text-sm text-slate-500 dark:text-slate-400">Evaluaciones</p>
                                    </div>
                                </div>
                                ${estadisticas ? `
                                <div class="mt-4 pt-4 border-t border-slate-200 dark:border-slate-600">
                                    <p class="text-sm text-slate-600 dark:text-slate-300 mb-2">Inspecciones por estado:</p>
                                    <div class="flex justify-between text-xs">
                                        <span class="text-yellow-600 dark:text-yellow-400">Pendientes: ${stats.inspecciones_por_estado.pendientes}</span>
                                        <span class="text-blue-600 dark:text-blue-400">En proceso: ${stats.inspecciones_por_estado.en_proceso}</span>
                                        <span class="text-green-600 dark:text-green-400">Completadas: ${stats.inspecciones_por_estado.completadas}</span>
                                    </div>
                                    <p class="text-xs text-slate-500 dark:text-slate-400 mt-2">
                                        Inspecciones recientes (30 días): ${stats.inspecciones_recientes}
                                    </p>
                                </div>
                                ` : `
                                <p class="text-xs text-slate-400 dark:text-slate-500 mt-3 text-center">
                                    Estadísticas próximamente disponibles
                                </p>
                                `}
                            </div>

                            <div class="bg-slate-50 dark:bg-slate-700/50 rounded-lg p-4">
                                <h3 class="text-lg font-semibold text-slate-900 dark:text-white mb-4 flex items-center gap-2">
                                    <i class="ph ph-calendar text-indigo-600"></i>
                                    Información del Sistema
                                </h3>
                                <div class="space-y-3">
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-calendar-plus text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Fecha de creación</p>
                                            <p class="font-medium text-slate-900 dark:text-white">${fechaCreacion}</p>
                                        </div>
                                    </div>
                                    <div class="flex items-center gap-3">
                                        <i class="ph ph-clock text-slate-400 w-5"></i>
                                        <div>
                                            <p class="text-sm text-slate-500 dark:text-slate-400">Última actualización</p>
                                            <p class="font-medium text-slate-900 dark:text-white">No disponible</p>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- Acciones -->
                    <div class="flex flex-col sm:flex-row gap-3 pt-6 border-t border-slate-200 dark:border-slate-600">
                        <button onclick="window.establecimientosManager.editarEstablecimiento(${establecimiento.id})"
                                class="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium rounded-lg shadow-sm text-white bg-gradient-to-r from-blue-600 to-blue-700 hover:from-blue-700 hover:to-blue-800 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-all duration-200 transform hover:scale-105">
                            <i class="ph ph-pencil"></i>
                            Editar Establecimiento
                        </button>
                        <button onclick="this.closest('#modal-detalles-establecimiento').remove()"
                                class="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2.5 text-sm font-medium rounded-lg text-slate-700 dark:text-slate-300 bg-white dark:bg-slate-700 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-slate-500 transition-all duration-200 border border-slate-300 dark:border-slate-600">
                            <i class="ph ph-x"></i>
                            Cerrar
                        </button>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Cerrar con escape
        const escapeHandler = (e) => {
            if (e.key === 'Escape') {
                document.body.removeChild(modal);
                document.removeEventListener('keydown', escapeHandler);
            }
        };
        document.addEventListener('keydown', escapeHandler);
    }

    async mostrarConfirmacion(titulo, mensaje, textoConfirmar = 'Confirmar', textoCancelar = 'Cancelar') {
        return new Promise((resolve) => {
            // Crear modal de confirmación dinámico
            const modal = document.createElement('div');
            modal.className = 'fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4';
            modal.innerHTML = `
                <div class="bg-white dark:bg-slate-800 rounded-xl shadow-2xl max-w-md w-full p-6">
                    <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-4">${titulo}</h3>
                    <p class="text-gray-600 dark:text-gray-400 mb-6 whitespace-pre-line">${mensaje}</p>
                    <div class="flex justify-end space-x-3">
                        <button id="modal-cancelar" class="btn-secondary">${textoCancelar}</button>
                        <button id="modal-confirmar" class="btn-primary">${textoConfirmar}</button>
                    </div>
                </div>
            `;

            document.body.appendChild(modal);

            // Event listeners
            modal.querySelector('#modal-cancelar').onclick = () => {
                document.body.removeChild(modal);
                resolve(false);
            };

            modal.querySelector('#modal-confirmar').onclick = () => {
                document.body.removeChild(modal);
                resolve(true);
            };

            // Cerrar con escape
            const escapeHandler = (e) => {
                if (e.key === 'Escape') {
                    document.body.removeChild(modal);
                    document.removeEventListener('keydown', escapeHandler);
                    resolve(false);
                }
            };
            document.addEventListener('keydown', escapeHandler);
        });
    }
}
