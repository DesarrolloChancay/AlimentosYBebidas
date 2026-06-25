/**
 * Dashboard Plan Semanal - Castillo de Chancay
 * Sistema de gestión de inspecciones semanales
 */

// ===== VARIABLES GLOBALES =====
let currentPeriodType = 'semanal';
let currentWeekOffset = 0;
let currentMonthOffset = 0;
let currentEstablecimiento = null;
let dashboardData = null;
let charts = {};
let periodoPicker = null;
let sincronizandoPeriodoPicker = false;

const SEMANAS_DISPONIBLES_PICKER = 8;
const MESES_DISPONIBLES_PICKER = 11;

// ===== INICIALIZACIÓN =====
document.addEventListener('DOMContentLoaded', function() {
    
    // Verificar dependencias
    if (typeof Chart === 'undefined') {
        return;
    }
    
    if (typeof AppCommon === 'undefined') {
        return;
    }
    
    // Inicializar dashboard con delay mínimo
    setTimeout(() => {
        inicializarDashboard();
    }, 100);
    
    // Auto-refresh cada 5 minutos
    setInterval(cargarDashboard, 5 * 60 * 1000);
});

// ===== FUNCIÓN PRINCIPAL DE INICIALIZACIÓN =====
async function inicializarDashboard() {
    try {
        // 1. Inicializar eventos
        inicializarEventos();

        // 2. Cargar opciones del período activo
        await cargarOpcionesPeriodo();

        // 3. Cargar establecimientos si el usuario tiene permisos
        await cargarEstablecimientos();

        // 4. Cargar datos del dashboard
        await cargarDashboard();

        // 5. Configurar estado inicial de botones
        actualizarEstadoBotonesPeriodo();

    } catch (error) {
    }
}

// ===== GESTIÓN DE EVENTOS =====
function inicializarEventos() {
    // Navegación del período
    const btnAnterior = document.getElementById('btn-anterior');
    const btnActual = document.getElementById('btn-actual');
    const btnSiguiente = document.getElementById('btn-siguiente');
    const btnRefresh = document.getElementById('btn-refresh');
    const periodoTipoSelect = document.getElementById('periodo-tipo-select');

    if (btnAnterior) btnAnterior.onclick = () => cambiarPeriodoNavegacion(-1);
    if (btnActual) btnActual.onclick = () => cambiarPeriodoNavegacion(0);
    if (btnSiguiente) btnSiguiente.onclick = () => cambiarPeriodoNavegacion(1);
    if (btnRefresh) btnRefresh.onclick = () => cargarDashboard();

    if (periodoTipoSelect) {
        periodoTipoSelect.onchange = async function() {
            currentPeriodType = this.value === 'mensual' ? 'mensual' : 'semanal';
            currentWeekOffset = 0;
            currentMonthOffset = 0;
            actualizarEtiquetasPeriodo();
            await cargarOpcionesPeriodo();
            actualizarEstadoBotonesPeriodo();
            cargarDashboard();
        };
    }

    // Filtro de establecimientos
    const filtroEst = document.getElementById('establecimiento-select');
    if (filtroEst) {
        filtroEst.onchange = function() {
            currentEstablecimiento = this.value || null;
            cargarDashboard();
        };
    }

    // Cambio de vista
    const btnTarjetas = document.getElementById('btn-tarjetas');
    const btnGraficos = document.getElementById('btn-graficos');

    if (btnTarjetas) btnTarjetas.onclick = () => cambiarVista('tarjetas');
    if (btnGraficos) btnGraficos.onclick = () => cambiarVista('graficos');
}

// ===== CARGA DE ESTABLECIMIENTOS =====
async function cargarEstablecimientos() {
    const select = document.getElementById('establecimiento-select');
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

// ===== NAVEGACIÓN DE PERÍODOS =====
function cambiarPeriodoNavegacion(offset) {
    if (currentPeriodType === 'mensual') {
        currentMonthOffset = offset === 0 ? 0 : currentMonthOffset + offset;
    } else {
        currentWeekOffset = offset === 0 ? 0 : currentWeekOffset + offset;
    }

    actualizarEstadoBotonesPeriodo();
    actualizarPickerPeriodo();
    cargarDashboard();
}

function actualizarEstadoBotonesPeriodo() {
    const btnAnterior = document.getElementById('btn-anterior');
    const btnActual = document.getElementById('btn-actual');
    const btnSiguiente = document.getElementById('btn-siguiente');
    const offsetActual = currentPeriodType === 'mensual' ? currentMonthOffset : currentWeekOffset;

    if (btnSiguiente) {
        if (offsetActual >= 0) {
            btnSiguiente.disabled = true;
            btnSiguiente.classList.add('opacity-50', 'cursor-not-allowed');
        } else {
            btnSiguiente.disabled = false;
            btnSiguiente.classList.remove('opacity-50', 'cursor-not-allowed');
        }
    }

    if (btnActual) {
        if (offsetActual === 0) {
            btnActual.classList.add('bg-green-600', 'shadow-lg');
            btnActual.classList.remove('bg-green-500', 'hover:bg-green-600');
        } else {
            btnActual.classList.add('bg-green-500', 'hover:bg-green-600');
            btnActual.classList.remove('bg-green-600', 'shadow-lg');
        }
    }
}

function actualizarEtiquetasPeriodo() {
    const subtitle = document.getElementById('dashboard-subtitle');
    const rangoLabel = document.getElementById('periodo-rango-label');
    const selectPeriodo = document.getElementById('periodo-tipo-select');

    if (selectPeriodo) {
        selectPeriodo.value = currentPeriodType;
    }

    if (subtitle) {
        subtitle.textContent = currentPeriodType === 'mensual' ? 'Consolidado Mensual' : 'Plan Semanal';
    }

    if (rangoLabel) {
        rangoLabel.textContent = currentPeriodType === 'mensual' ? 'Mes' : 'Semana';
    }
}

function sumarMeses(fechaBase, offset) {
    return new Date(fechaBase.getFullYear(), fechaBase.getMonth() + offset, 1);
}

function normalizarFecha(fecha) {
    return new Date(fecha.getFullYear(), fecha.getMonth(), fecha.getDate());
}

function sumarDias(fechaBase, dias) {
    const fecha = new Date(fechaBase);
    fecha.setDate(fecha.getDate() + dias);
    return normalizarFecha(fecha);
}

function obtenerInicioSemana(fecha) {
    const base = normalizarFecha(fecha);
    const diaSemana = base.getDay();
    const diff = diaSemana === 0 ? -6 : 1 - diaSemana;
    base.setDate(base.getDate() + diff);
    return normalizarFecha(base);
}

function obtenerFinSemana(fecha) {
    const fin = obtenerInicioSemana(fecha);
    fin.setDate(fin.getDate() + 6);
    return normalizarFecha(fin);
}

function obtenerInicioMes(fecha) {
    return new Date(fecha.getFullYear(), fecha.getMonth(), 1);
}

function obtenerFinMes(fecha) {
    return new Date(fecha.getFullYear(), fecha.getMonth() + 1, 0);
}

function calcularDiferenciaSemanas(fechaBase, fechaObjetivo) {
    const inicioBase = obtenerInicioSemana(fechaBase);
    const inicioObjetivo = obtenerInicioSemana(fechaObjetivo);
    const milisegundosSemana = 7 * 24 * 60 * 60 * 1000;
    return Math.round((inicioObjetivo - inicioBase) / milisegundosSemana);
}

function calcularDiferenciaMeses(fechaBase, fechaObjetivo) {
    const inicioBase = obtenerInicioMes(fechaBase);
    const inicioObjetivo = obtenerInicioMes(fechaObjetivo);
    return ((inicioObjetivo.getFullYear() - inicioBase.getFullYear()) * 12)
        + (inicioObjetivo.getMonth() - inicioBase.getMonth());
}

function capitalizar(texto) {
    if (!texto) return '';
    return texto.charAt(0).toUpperCase() + texto.slice(1);
}

function formatearMes(fecha) {
    return capitalizar(new Intl.DateTimeFormat('es-PE', {
        month: 'long',
        year: 'numeric'
    }).format(fecha));
}

function formatearFechaCorta(fecha) {
    const dia = fecha.getDate().toString().padStart(2, '0');
    const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
    return `${dia}/${mes}`;
}

async function cargarOpcionesPeriodo() {
    actualizarEtiquetasPeriodo();
    inicializarPickerPeriodo();
}

function obtenerFechaPeriodoActual() {
    const hoy = normalizarFecha(new Date());

    if (currentPeriodType === 'mensual') {
        return obtenerInicioMes(sumarMeses(obtenerInicioMes(hoy), currentMonthOffset));
    }

    return obtenerInicioSemana(sumarDias(hoy, currentWeekOffset * 7));
}

function obtenerLimitesPickerPeriodo() {
    const hoy = normalizarFecha(new Date());

    if (currentPeriodType === 'mensual') {
        return {
            minDate: sumarMeses(obtenerInicioMes(hoy), -MESES_DISPONIBLES_PICKER),
            maxDate: obtenerFinMes(hoy)
        };
    }

    return {
        minDate: sumarDias(obtenerInicioSemana(hoy), -(SEMANAS_DISPONIBLES_PICKER * 7)),
        maxDate: obtenerFinSemana(hoy)
    };
}

function obtenerTextoPeriodoPicker(fecha) {
    if (!fecha) {
        return '';
    }

    if (currentPeriodType === 'mensual') {
        return formatearMes(obtenerInicioMes(fecha));
    }

    const inicioSemana = obtenerInicioSemana(fecha);
    const finSemana = obtenerFinSemana(fecha);
    return `Semana ${formatearFechaCorta(inicioSemana)} - ${formatearFechaCorta(finSemana)}`;
}

function actualizarTextoPickerPeriodo(instancia = periodoPicker) {
    if (!instancia) {
        return;
    }

    const campoVisible = instancia.altInput || instancia.input;
    if (!campoVisible) {
        return;
    }

    campoVisible.readOnly = true;
    campoVisible.placeholder = currentPeriodType === 'mensual' ? 'Selecciona un mes' : 'Selecciona una semana';

    if (instancia.selectedDates && instancia.selectedDates.length > 0) {
        campoVisible.value = obtenerTextoPeriodoPicker(instancia.selectedDates[0]);
    }
}

function destruirPickerPeriodo() {
    if (periodoPicker) {
        periodoPicker.destroy();
        periodoPicker = null;
    }
}

function manejarCambioPickerPeriodo(fechasSeleccionadas, instancia = periodoPicker) {
    if (sincronizandoPeriodoPicker || !fechasSeleccionadas || fechasSeleccionadas.length === 0) {
        return;
    }

    const fechaSeleccionada = normalizarFecha(fechasSeleccionadas[0]);

    if (currentPeriodType === 'mensual') {
        currentMonthOffset = calcularDiferenciaMeses(new Date(), fechaSeleccionada);
    } else {
        currentWeekOffset = calcularDiferenciaSemanas(new Date(), fechaSeleccionada);
    }

    actualizarEstadoBotonesPeriodo();
    actualizarTextoPickerPeriodo(instancia);
    cargarDashboard();
}

function inicializarPickerPeriodo() {
    const input = document.getElementById('periodo-rango-picker');
    if (!input) {
        return;
    }

    if (typeof flatpickr === 'undefined') {
        input.value = obtenerTextoPeriodoPicker(obtenerFechaPeriodoActual());
        return;
    }

    destruirPickerPeriodo();

    if (flatpickr.l10ns && flatpickr.l10ns.es) {
        flatpickr.localize(flatpickr.l10ns.es);
    }

    const limites = obtenerLimitesPickerPeriodo();
    const esMensual = currentPeriodType === 'mensual';
    const plugins = [];

    if (esMensual && typeof monthSelectPlugin === 'function') {
        plugins.push(new monthSelectPlugin({
            shorthand: false,
            dateFormat: 'Y-m-d',
            altFormat: 'F Y'
        }));
    }

    periodoPicker = flatpickr(input, {
        locale: flatpickr.l10ns?.es,
        disableMobile: true,
        allowInput: false,
        clickOpens: true,
        dateFormat: 'Y-m-d',
        altInput: true,
        altInputClass: 'w-full px-4 py-3 pr-11 bg-slate-50 dark:bg-slate-700 border border-slate-300 dark:border-slate-600 rounded-xl focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 text-slate-900 dark:text-white',
        defaultDate: obtenerFechaPeriodoActual(),
        minDate: limites.minDate,
        maxDate: limites.maxDate,
        plugins,
        onReady: function(_selectedDates, _dateStr, instance) {
            actualizarTextoPickerPeriodo(instance);
        },
        onChange: function(selectedDates, _dateStr, instance) {
            manejarCambioPickerPeriodo(selectedDates, instance);
        }
    });

    actualizarPickerPeriodo();
}

function actualizarPickerPeriodo() {
    if (!periodoPicker) {
        return;
    }

    sincronizandoPeriodoPicker = true;

    const limites = obtenerLimitesPickerPeriodo();
    periodoPicker.set('minDate', limites.minDate);
    periodoPicker.set('maxDate', limites.maxDate);
    periodoPicker.setDate(obtenerFechaPeriodoActual(), false);
    actualizarTextoPickerPeriodo(periodoPicker);

    sincronizandoPeriodoPicker = false;
}

// ===== CAMBIO DE VISTA =====
function cambiarVista(vista) {
    const vistaCards = document.getElementById('vista-tarjetas');
    const vistaGraficos = document.getElementById('vista-graficos');
    const btnCards = document.getElementById('btn-tarjetas');
    const btnGraficos = document.getElementById('btn-graficos');

    if (vista === 'tarjetas') {
        vistaCards?.classList.remove('hidden');
        vistaGraficos?.classList.add('hidden');
        btnCards?.classList.add('bg-blue-500');
        btnCards?.classList.remove('bg-slate-100', 'dark:bg-slate-700', 'hover:bg-slate-200', 'dark:hover:bg-slate-600');
        btnGraficos?.classList.add('bg-slate-100', 'dark:bg-slate-700', 'hover:bg-slate-200', 'dark:hover:bg-slate-600');
        btnGraficos?.classList.remove('bg-blue-500');
    } else {
        vistaCards?.classList.add('hidden');
        vistaGraficos?.classList.remove('hidden');
        btnGraficos?.classList.add('bg-blue-500');
        btnGraficos?.classList.remove('bg-slate-100', 'dark:bg-slate-700', 'hover:bg-slate-200', 'dark:hover:bg-slate-600');
        btnCards?.classList.add('bg-slate-100', 'dark:bg-slate-700', 'hover:bg-slate-200', 'dark:hover:bg-slate-600');
        btnCards?.classList.remove('bg-blue-500');

        // Crear gráficos si hay datos
        if (dashboardData) {
            crearGraficos();
        }
    }
}

// ===== FUNCIONES DE UI =====
function mostrarLoading(mostrar) {
    const loading = document.getElementById('loading-container');
    if (loading) {
        loading.style.display = mostrar ? 'block' : 'none';
    }
}

function mostrarError(mostrar, mensaje = 'Ha ocurrido un error inesperado') {
    const error = document.getElementById('error-container');
    const errorMessage = document.getElementById('error-message');
    if (error) {
        error.style.display = mostrar ? 'block' : 'none';
        if (errorMessage) {
            errorMessage.textContent = mensaje;
        }
    }
}

// ===== CARGA DE DATOS PRINCIPAL =====
async function cargarDashboard() {
    try {
        mostrarLoading(true);
        mostrarError(false);
        
        // Construir URL con parámetros
        let url = '/api/dashboard/plan-semanal';
        const params = new URLSearchParams();
        params.append('periodo', currentPeriodType);
        
        if (currentPeriodType === 'mensual' && currentMonthOffset !== 0) {
            params.append('mes_offset', currentMonthOffset);
        }

        if (currentPeriodType === 'semanal' && currentWeekOffset !== 0) {
            params.append('semana_offset', currentWeekOffset);
        }
        
        if (currentEstablecimiento) {
            params.append('establecimiento_id', currentEstablecimiento);
        }
        
        if (params.toString()) {
            url += '?' + params.toString();
        }
        
        const response = await fetch(url);
        
        if (!response.ok) {
            throw new Error(`Error HTTP: ${response.status}`);
        }
        
        dashboardData = await response.json();
        
        // Actualizar interfaz
        actualizarInfoPeriodo(dashboardData.periodo || dashboardData.semana);
        actualizarResumenGeneral(dashboardData.resumen_general);
        actualizarVistaEstablecimientos(dashboardData.establecimientos);
        
        mostrarLoading(false);
        
    } catch (error) {
        mostrarError(true, error.message);
        mostrarLoading(false);
    }
}

// ===== ACTUALIZACIÓN DE INTERFAZ =====
function actualizarInfoPeriodo(periodo) {
    const descripcion = document.getElementById('periodo-descripcion');
    const rango = document.getElementById('periodo-rango-texto');

    if (!periodo) return;

    const inicio = periodo.inicio ? periodo.inicio.split('T')[0] : null;
    const fin = periodo.fin ? periodo.fin.split('T')[0] : null;
    const formatearFecha = (fechaStr) => {
        if (!fechaStr) return '';
        const [year, month, day] = fechaStr.split('-');
        return `${day}/${month}/${year}`;
    };

    if (descripcion) {
        descripcion.textContent = periodo.titulo || (periodo.tipo === 'mensual' ? 'Consolidado mensual' : 'Semana seleccionada');
    }

    if (rango) {
        rango.textContent = inicio && fin
            ? `${formatearFecha(inicio)} al ${formatearFecha(fin)}`
            : 'Sin rango disponible';
    }
}

function actualizarResumenGeneral(resumen) {
    const container = document.getElementById('resumen-cards');
    if (!container || !resumen) return;
    
    container.innerHTML = `
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 stats-card">
            <div class="flex items-center">
                <div class="p-3 rounded-full bg-blue-100 dark:bg-blue-900">
                    <svg class="w-6 h-6 text-blue-600 dark:text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path>
                    </svg>
                </div>
                <div class="ml-4">
                    <h3 class="text-lg font-semibold text-slate-800 dark:text-white">Total Inspecciones</h3>
                    <p class="text-3xl font-bold text-blue-600 dark:text-blue-400">${resumen.total_inspecciones}</p>
                </div>
            </div>
        </div>
        
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 stats-card">
            <div class="flex items-center">
                <div class="p-3 rounded-full bg-green-100 dark:bg-green-900">
                    <svg class="w-6 h-6 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path>
                    </svg>
                </div>
                <div class="ml-4">
                    <h3 class="text-lg font-semibold text-slate-800 dark:text-white">Establecimientos Completos</h3>
                    <p class="text-3xl font-bold text-green-600 dark:text-green-400">${resumen.establecimientos_completos}</p>
                </div>
            </div>
        </div>
        
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 stats-card">
            <div class="flex items-center">
                <div class="p-3 rounded-full bg-yellow-100 dark:bg-yellow-900">
                    <svg class="w-6 h-6 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                </div>
                <div class="ml-4">
                    <h3 class="text-lg font-semibold text-slate-800 dark:text-white">Pendientes</h3>
                    <p class="text-3xl font-bold text-yellow-600 dark:text-yellow-400">${resumen.establecimientos_pendientes}</p>
                </div>
            </div>
        </div>
        
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 stats-card">
            <div class="flex items-center">
                <div class="p-3 rounded-full bg-purple-100 dark:bg-purple-900">
                    <svg class="w-6 h-6 text-purple-600 dark:text-purple-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
                    </svg>
                </div>
                <div class="ml-4">
                    <h3 class="text-lg font-semibold text-slate-800 dark:text-white">Cumplimiento General</h3>
                    <p class="text-3xl font-bold text-purple-600 dark:text-purple-400">${resumen.promedio_cumplimiento}%</p>
                </div>
            </div>
        </div>
    `;
}

function actualizarVistaEstablecimientos(establecimientos) {
    const container = document.getElementById('vista-tarjetas');
    if (!container || !establecimientos) return;
    const esMensual = dashboardData?.periodo?.tipo === 'mensual';
    const etiquetaPendiente = esMensual ? 'días restantes en el mes' : 'días restantes en la semana';
    
    const sanitizeTextSafe = (text) => {
        if (typeof sanitizeText === 'function') {
            return sanitizeText(text);
        }
        // Fallback básico
        if (!text || typeof text !== 'string') return '';
        return text.replace(/[<>&"']/g, function(char) {
            const escapeMap = { '<': '&lt;', '>': '&gt;', '&': '&amp;', '"': '&quot;', "'": '&#x27;' };
            return escapeMap[char] || char;
        });
    };
    
    container.innerHTML = establecimientos.map(est => `
        <div class="bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 stats-card">
            <div class="flex items-center justify-between mb-4">
                <h3 class="text-lg font-semibold text-slate-800 dark:text-white">${sanitizeTextSafe(est.nombre)}</h3>
                <span class="px-3 py-1 rounded-full text-xs font-medium ${est.estado === 'completo' ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-400' : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-400'}">
                    ${est.estado === 'completo' ? '✅ Completo' : '<i class="fa-solid fa-hourglass-half"></i> Pendiente'}
                </span>
            </div>
            
            <div class="space-y-3">
                <div class="flex justify-between">
                    <span class="text-slate-600 dark:text-slate-400">Inspecciones realizadas:</span>
                    <span class="font-semibold text-slate-800 dark:text-white">${est.inspecciones_realizadas}/${est.meta_periodo ?? est.meta_semanal}</span>
                </div>
                
                <div class="flex justify-between">
                    <span class="text-slate-600 dark:text-slate-400">Cumplimiento de meta:</span>
                    <span class="font-semibold text-slate-800 dark:text-white">${est.porcentaje_cumplimiento_meta}%</span>
                </div>
                
                <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
                    <div class="progress-bar bg-blue-500 h-2 rounded-full" style="width: ${est.porcentaje_cumplimiento_meta}%"></div>
                </div>
                
                <div class="flex justify-between items-center">
                    <span class="text-slate-600 dark:text-slate-400">Calificación:</span>
                    ${est.calificacion_reciente
                        ? `<span class="px-2 py-0.5 rounded text-xs font-bold ${
                            est.calificacion_reciente === 'EXCELENTE' ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300' :
                            est.calificacion_reciente === 'MUY BIEN'  ? 'bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-300' :
                            est.calificacion_reciente === 'REGULAR'   ? 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300' :
                                                                        'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
                          }">${est.calificacion_reciente}</span>`
                        : `<span class="text-slate-400 dark:text-slate-500 text-sm">Sin datos</span>`
                    }
                </div>
                
                ${est.dias_restantes > 0 ? `
                <div class="text-sm text-slate-500 dark:text-slate-400">
                    ${est.dias_restantes} ${etiquetaPendiente}
                </div>
                ` : ''}
            </div>
        </div>
    `).join('');
}

// ===== GRÁFICOS =====
function crearGraficos() {
    if (!dashboardData || !dashboardData.chart_data) return;
    
    const data = dashboardData.chart_data;
    
    // Destruir gráficos existentes
    Object.values(charts).forEach(chart => chart.destroy());
    charts = {};
    
    // Gráfico de inspecciones
    const ctxInspecciones = document.getElementById('chart-inspecciones');
    if (ctxInspecciones) {
        charts.inspecciones = new Chart(ctxInspecciones, {
            type: 'bar',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Realizadas',
                    data: data.realizadas,
                    backgroundColor: 'rgba(59, 130, 246, 0.6)',
                    borderColor: 'rgb(59, 130, 246)',
                    borderWidth: 1
                }, {
                    label: 'Pendientes',
                    data: data.pendientes,
                    backgroundColor: 'rgba(245, 158, 11, 0.6)',
                    borderColor: 'rgb(245, 158, 11)',
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true }
                }
            }
        });
    }
    
    // Gráfico de cumplimiento
    const ctxCumplimiento = document.getElementById('chart-cumplimiento');
    if (ctxCumplimiento) {
        charts.cumplimiento = new Chart(ctxCumplimiento, {
            type: 'doughnut',
            data: {
                labels: data.labels,
                datasets: [{
                    data: data.cumplimiento,
                    backgroundColor: [
                        'rgba(34, 197, 94, 0.6)',
                        'rgba(59, 130, 246, 0.6)',
                        'rgba(245, 158, 11, 0.6)',
                        'rgba(239, 68, 68, 0.6)'
                    ],
                    borderWidth: 2
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false
            }
        });
    }
    
    // Gráfico de promedios
    const ctxPromedios = document.getElementById('chart-promedios');
    if (ctxPromedios) {
        charts.promedios = new Chart(ctxPromedios, {
            type: 'line',
            data: {
                labels: data.labels,
                datasets: [{
                    label: 'Promedio Calificación (%)',
                    data: data.promedios,
                    borderColor: 'rgb(147, 51, 234)',
                    backgroundColor: 'rgba(147, 51, 234, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { 
                        beginAtZero: true,
                        max: 100
                    }
                }
            }
        });
    }
}

// ===== FUNCIONES GLOBALES PARA DEBUGGING (DESARROLLO) =====
if (typeof window !== 'undefined') {
    window.debugDashboard = function() {

        const select = document.getElementById('establecimiento-select');
        if (select) {
            for (let i = 0; i < select.children.length; i++) {
                const option = select.children[i];
            }
        }

        if (periodoPicker && periodoPicker.selectedDates && periodoPicker.selectedDates.length > 0) {
        }
    };
    
    window.recargarDashboard = function() {
        cargarDashboard();
    };
}
