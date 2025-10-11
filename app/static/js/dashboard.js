/**
 * Dashboard Plan Semanal - Castillo de Chancay
 * Sistema de gestión de inspecciones semanales
 */

// ===== VARIABLES GLOBALES =====
let currentWeekOffset = 0;
let currentEstablecimiento = null;
let dashboardData = null;
let charts = {};

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

        // 2. Cargar semanas disponibles
        await cargarSemanasDisponibles();

        // 3. Cargar establecimientos si el usuario tiene permisos
        await cargarEstablecimientos();

        // 4. Cargar datos del dashboard
        await cargarDashboard();

        // 5. Configurar estado inicial de botones
        actualizarEstadoBotonesSemana();

    } catch (error) {
    }
}

// ===== GESTIÓN DE EVENTOS =====
function inicializarEventos() {
    // Navegación de semanas
    const btnAnterior = document.getElementById('btn-anterior');
    const btnActual = document.getElementById('btn-actual');
    const btnSiguiente = document.getElementById('btn-siguiente');
    const btnRefresh = document.getElementById('btn-refresh');

    if (btnAnterior) btnAnterior.onclick = () => cambiarSemana(-1);
    if (btnActual) btnActual.onclick = () => cambiarSemana(0);
    if (btnSiguiente) btnSiguiente.onclick = () => cambiarSemana(1);
    if (btnRefresh) btnRefresh.onclick = () => cargarDashboard();

    // Selector de semana
    const semanaSelect = document.getElementById('semana-select');
    if (semanaSelect) {
        semanaSelect.onchange = function() {
            const selectedValue = parseInt(this.value);
            if (!isNaN(selectedValue)) {
                currentWeekOffset = selectedValue;
                actualizarEstadoBotonesSemana();
                cargarDashboard();
            }
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

// ===== NAVEGACIÓN DE SEMANAS =====
function cambiarSemana(offset) {
    if (offset === 0) {
        // Ir a la semana actual
        currentWeekOffset = 0;
    } else {
        // Navegar a semanas anteriores o siguientes
        currentWeekOffset += offset;
    }

    actualizarEstadoBotonesSemana();
    cargarDashboard();
}

function actualizarEstadoBotonesSemana() {
    const btnAnterior = document.getElementById('btn-anterior');
    const btnActual = document.getElementById('btn-actual');
    const btnSiguiente = document.getElementById('btn-siguiente');
    const semanaSelect = document.getElementById('semana-select');

    if (btnSiguiente) {
        if (currentWeekOffset >= 0) {
            // Semana actual o futuras - deshabilitar siguiente
            btnSiguiente.disabled = true;
            btnSiguiente.classList.add('opacity-50', 'cursor-not-allowed');
        } else {
            // Semanas pasadas - habilitar siguiente
            btnSiguiente.disabled = false;
            btnSiguiente.classList.remove('opacity-50', 'cursor-not-allowed');
        }
    }

    if (btnActual) {
        if (currentWeekOffset === 0) {
            // Estamos en la semana actual - destacar el botón
            btnActual.classList.add('bg-green-600', 'shadow-lg');
            btnActual.classList.remove('bg-green-500', 'hover:bg-green-600');
        } else {
            // No estamos en la semana actual - estado normal
            btnActual.classList.add('bg-green-500', 'hover:bg-green-600');
            btnActual.classList.remove('bg-green-600', 'shadow-lg');
        }
    }

    // Actualizar selector de semana
    if (semanaSelect) {
        semanaSelect.value = currentWeekOffset;
    }
}// ===== CARGA DE SEMANAS DISPONIBLES =====
async function cargarSemanasDisponibles() {
    const select = document.getElementById('semana-select');
    if (!select) return;

    try {
        // Cargar semanas disponibles (últimas 12 semanas)
        const semanas = [];
        const hoy = new Date();

        for (let i = -8; i <= 0; i++) {
            const fecha = new Date(hoy);
            fecha.setDate(fecha.getDate() + (i * 7));

            // Obtener el lunes de esa semana
            const diaSemana = fecha.getDay();
            const diff = fecha.getDate() - diaSemana + (diaSemana === 0 ? -6 : 1);
            const lunes = new Date(fecha.setDate(diff));

            // Obtener el domingo de esa semana
            const domingo = new Date(lunes);
            domingo.setDate(domingo.getDate() + 6);

            const formatoFecha = (fecha) => {
                const dia = fecha.getDate().toString().padStart(2, '0');
                const mes = (fecha.getMonth() + 1).toString().padStart(2, '0');
                return `${dia}/${mes}`;
            };

            const etiqueta = `Semana ${formatoFecha(lunes)} - ${formatoFecha(domingo)}`;
            semanas.push({
                offset: i,
                label: etiqueta,
                value: i
            });
        }

        // Limpiar y poblar el select
        select.innerHTML = '<option value="">Cargando semanas...</option>';

        semanas.forEach(semana => {
            const option = document.createElement('option');
            option.value = semana.value;
            option.textContent = semana.label;
            if (semana.value === currentWeekOffset) {
                option.selected = true;
            }
            select.appendChild(option);
        });

    } catch (error) {
    }
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
        
        if (currentWeekOffset !== 0) {
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
        actualizarInfoSemana(dashboardData.semana);
        actualizarResumenGeneral(dashboardData.resumen_general);
        actualizarVistaEstablecimientos(dashboardData.establecimientos);
        
        mostrarLoading(false);
        
    } catch (error) {
        mostrarError(true, error.message);
        mostrarLoading(false);
    }
}

// ===== ACTUALIZACIÓN DE INTERFAZ =====
function actualizarInfoSemana(semana) {
    const fechaInicio = document.getElementById('fecha-inicio');
    const fechaFin = document.getElementById('fecha-fin');
    
    if (fechaInicio && fechaFin && semana) {
        const inicio = semana.inicio.split('T')[0];
        const fin = semana.fin.split('T')[0];
        
        const formatearFecha = (fechaStr) => {
            const [year, month, day] = fechaStr.split('-');
            return `${day}/${month}/${year}`;
        };
        
        fechaInicio.textContent = formatearFecha(inicio);
        fechaFin.textContent = formatearFecha(fin);
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
                    <span class="font-semibold text-slate-800 dark:text-white">${est.inspecciones_realizadas}/${est.meta_semanal}</span>
                </div>
                
                <div class="flex justify-between">
                    <span class="text-slate-600 dark:text-slate-400">Cumplimiento de meta:</span>
                    <span class="font-semibold text-slate-800 dark:text-white">${est.porcentaje_cumplimiento_meta}%</span>
                </div>
                
                <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-2">
                    <div class="progress-bar bg-blue-500 h-2 rounded-full" style="width: ${est.porcentaje_cumplimiento_meta}%"></div>
                </div>
                
                <div class="flex justify-between">
                    <span class="text-slate-600 dark:text-slate-400">Promedio calificación:</span>
                    <span class="font-semibold text-slate-800 dark:text-white">${est.promedio_calificacion}%</span>
                </div>
                
                ${est.dias_restantes > 0 ? `
                <div class="text-sm text-slate-500 dark:text-slate-400">
                    ${est.dias_restantes} días restantes en la semana
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

        const semanaSelect = document.getElementById('semana-select');
        if (semanaSelect) {
            for (let i = 0; i < semanaSelect.children.length; i++) {
                const option = semanaSelect.children[i];
            }
        }
    };
    
    window.recargarDashboard = function() {
        cargarDashboard();
    };
}
