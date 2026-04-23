let reglamentoCharts = {};
let reglamentoFechaInicio = null;
let reglamentoFechaFin = null;
let reglamentoPicker = null;

const REGLAMENTO_CHART_IDS = ['chartMovimientoMensual', 'chartRestaurantes', 'chartCategorias'];
const REGLAMENTO_TABLE_IDS = ['tablaItemsMenosCumplidos', 'tablaItemsCumplidos'];
const REGLAMENTO_KPI_CLASSES = {
    kpiPromedioSemanal: 'mt-2 text-3xl font-bold text-slate-900 dark:text-white',
    kpiPromedioMensual: 'mt-2 text-3xl font-bold text-slate-900 dark:text-white',
    kpiComparativoAnual: 'mt-2 text-3xl font-bold text-slate-900 dark:text-white',
    kpiReuniones: 'mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-400',
    kpiInfracciones: 'mt-2 text-3xl font-bold text-rose-600 dark:text-rose-400',
};
const REGLAMENTO_KPI_PLACEHOLDERS = {
    kpiPromedioSemanal: '0',
    kpiPromedioMensual: '0',
    kpiComparativoAnual: '-',
    kpiReuniones: '0',
    kpiInfracciones: '0',
};
const REGLAMENTO_KPI_DETALLE_CLASS = 'mt-1 text-xs text-slate-500 dark:text-slate-400';

document.addEventListener('DOMContentLoaded', () => {
    const root = document.getElementById('reglamentoAnalitica');
    if (!root) return;

    reglamentoFechaInicio = root.dataset.defaultStart;
    reglamentoFechaFin = root.dataset.defaultEnd;

    inicializarFiltrosReglamento();
    cargarAnaliticaReglamento();
    window.addEventListener('resize', redimensionarChartsReglamento);
});

function inicializarFiltrosReglamento() {
    const inputRango = document.getElementById('rangoFechasReglamento');
    const selectEstablecimiento = document.getElementById('establecimientoAnalitica');
    const btnActualizar = document.getElementById('btnActualizarAnalitica');
    const params = new URLSearchParams(window.location.search);
    const fechaInicioParam = params.get('fecha_inicio');
    const fechaFinParam = params.get('fecha_fin');
    const establecimientoId = params.get('establecimiento_id');

    if (esFechaIso(fechaInicioParam)) {
        reglamentoFechaInicio = fechaInicioParam;
    }
    if (esFechaIso(fechaFinParam)) {
        reglamentoFechaFin = fechaFinParam;
    }

    if (establecimientoId && selectEstablecimiento) {
        selectEstablecimiento.value = establecimientoId;
    }

    if (inputRango) {
        if (typeof flatpickr !== 'undefined') {
            if (flatpickr.l10ns && flatpickr.l10ns.es) {
                flatpickr.localize(flatpickr.l10ns.es);
            }

            reglamentoPicker = flatpickr(inputRango, {
                mode: 'range',
                dateFormat: 'Y-m-d',
                altInput: true,
                altFormat: 'd/m/Y',
                disableMobile: true,
                defaultDate: [reglamentoFechaInicio, reglamentoFechaFin],
                onChange: (selectedDates) => {
                    if (selectedDates.length === 1) {
                        reglamentoFechaInicio = formatearFechaIso(selectedDates[0]);
                        reglamentoFechaFin = reglamentoFechaInicio;
                    }
                    if (selectedDates.length >= 2) {
                        reglamentoFechaInicio = formatearFechaIso(selectedDates[0]);
                        reglamentoFechaFin = formatearFechaIso(selectedDates[1]);
                    }
                },
            });
        } else {
            inputRango.value = `${reglamentoFechaInicio} a ${reglamentoFechaFin}`;
        }
    }

    btnActualizar?.addEventListener('click', cargarAnaliticaReglamento);
    selectEstablecimiento?.addEventListener('change', cargarAnaliticaReglamento);
}

async function cargarAnaliticaReglamento() {
    const btnActualizar = document.getElementById('btnActualizarAnalitica');
    const establecimientoId = document.getElementById('establecimientoAnalitica')?.value || '';
    const params = new URLSearchParams({
        fecha_inicio: reglamentoFechaInicio,
        fecha_fin: reglamentoFechaFin,
    });

    if (establecimientoId) {
        params.set('establecimiento_id', establecimientoId);
    }

    setLoadingReglamento(true);
    if (btnActualizar) {
        btnActualizar.disabled = true;
        btnActualizar.innerHTML = '<span class="ph ph-circle-notch mr-2 text-lg animate-spin"></span>Cargando';
    }

    try {
        const response = await fetch(`/reglamento/api/analitica?${params.toString()}`);
        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.error || 'No se pudo cargar la analítica.');
        }

        renderAnaliticaReglamento(data);
        actualizarUrlAnalitica(params);
        ocultarAlertaReglamento();
    } catch (error) {
        mostrarAlertaReglamento(error.message || 'Error cargando analítica.', 'error');
    } finally {
        setLoadingReglamento(false);
        if (btnActualizar) {
            btnActualizar.disabled = false;
            btnActualizar.innerHTML = '<span class="ph ph-arrows-clockwise mr-2 text-lg"></span>Actualizar';
        }
    }
}

function renderAnaliticaReglamento(data) {
    renderKpisReglamento(data.kpis || {});
    renderMovimientoMensual(data.series?.movimiento_mensual || {});
    renderRestaurantes(data.series?.restaurantes || []);
    renderCategorias(data.series?.categorias || []);
    renderTablaItems('tablaItemsMenosCumplidos', data.reportes?.menos_cumplidos || [], 'menos');
    renderTablaItems('tablaItemsCumplidos', data.reportes?.cumplidos || [], 'cumplidos');
}

function renderKpisReglamento(kpis) {
    setKpiTexto('kpiPromedioSemanal', formatearNumero(kpis.promedio_semanal));
    setKpiTexto('kpiPromedioMensual', formatearNumero(kpis.promedio_mensual));
    setKpiTexto('kpiReuniones', formatearEntero(kpis.reuniones));
    setKpiTexto('kpiInfracciones', formatearEntero(kpis.total_infracciones));

    const comparativo = document.getElementById('kpiComparativoAnual');
    const detalle = document.getElementById('kpiComparativoDetalle');
    const variacion = kpis.variacion_anual;

    if (variacion === null || variacion === undefined) {
        setKpiTexto('kpiComparativoAnual', '-');
        setKpiDetalle('Sin datos comparables');
        return;
    }

    const mejora = Number(variacion) <= 0;
    if (comparativo) {
        comparativo.textContent = `${mejora ? '↓' : '↑'} ${Math.abs(Number(variacion)).toFixed(1)}%`;
        comparativo.className = mejora
            ? 'mt-2 text-3xl font-bold text-emerald-600 dark:text-emerald-400'
            : 'mt-2 text-3xl font-bold text-rose-600 dark:text-rose-400';
    }
    if (detalle) {
        setKpiDetalle(`Actual ${formatearNumero(kpis.promedio_actual)} pts | Año pasado ${formatearNumero(kpis.promedio_anio_anterior)} pts`);
    }
}

function renderMovimientoMensual(data) {
    const chart = obtenerChartReglamento('chartMovimientoMensual');
    if (!chart) return;

    const labels = data.labels || [];
    chart.setOption({
        tooltip: { trigger: 'axis', valueFormatter: (value) => value === null ? 'Sin datos' : `${formatearNumero(value)} pts` },
        legend: { top: 0, data: ['Periodo actual', 'Año pasado'] },
        grid: { left: 40, right: 18, top: 52, bottom: 42 },
        xAxis: { type: 'category', boundaryGap: false, data: labels },
        yAxis: { type: 'value', name: 'Puntos', minInterval: 1 },
        series: [
            {
                name: 'Periodo actual',
                type: 'line',
                smooth: true,
                connectNulls: false,
                symbolSize: 8,
                data: data.actual || [],
                lineStyle: { width: 3, color: '#059669' },
                itemStyle: { color: '#059669' },
                areaStyle: { color: 'rgba(5, 150, 105, 0.12)' },
            },
            {
                name: 'Año pasado',
                type: 'line',
                smooth: true,
                connectNulls: false,
                symbolSize: 7,
                data: data.anterior || [],
                lineStyle: { width: 2, color: '#64748b', type: 'dashed' },
                itemStyle: { color: '#64748b' },
            },
        ],
    });
}

function renderRestaurantes(restaurantes) {
    const chart = obtenerChartReglamento('chartRestaurantes');
    if (!chart) return;

    const top = restaurantes.slice(0, 12);
    chart.setOption({
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            formatter: (params) => {
                const index = params[0].dataIndex;
                const item = top[index] || {};
                return [
                    `<strong>${escapeHtml(item.establecimiento || '')}</strong>`,
                    `Promedio: ${formatearNumero(item.promedio_puntos)} pts`,
                    `Reuniones: ${formatearEntero(item.reuniones)}`,
                    `Infracciones: ${formatearEntero(item.total_infracciones)}`,
                ].join('<br>');
            },
        },
        grid: { left: 130, right: 18, top: 18, bottom: 36 },
        xAxis: { type: 'value', name: 'Promedio pts', minInterval: 1 },
        yAxis: {
            type: 'category',
            inverse: true,
            data: top.map((item) => item.establecimiento),
            axisLabel: { width: 112, overflow: 'truncate' },
        },
        series: [
            {
                type: 'bar',
                data: top.map((item) => item.promedio_puntos),
                barMaxWidth: 24,
                itemStyle: { color: '#0f766e', borderRadius: [0, 6, 6, 0] },
            },
        ],
    });
}

function renderCategorias(categorias) {
    const chart = obtenerChartReglamento('chartCategorias');
    if (!chart) return;

    const top = categorias.slice(0, 10);
    chart.setOption({
        tooltip: {
            trigger: 'axis',
            axisPointer: { type: 'shadow' },
            formatter: (params) => {
                const index = params[0].dataIndex;
                const item = top[index] || {};
                return [
                    `<strong>${escapeHtml(item.categoria || '')}</strong>`,
                    `Promedio: ${formatearNumero(item.promedio_puntos)} pts`,
                    `Cumplimiento: ${formatearNumero(item.cumplimiento)}%`,
                    `No cumple: ${formatearEntero(item.no_cumple)}`,
                ].join('<br>');
            },
        },
        grid: { left: 220, right: 28, top: 18, bottom: 36 },
        xAxis: { type: 'value', name: 'Promedio pts', minInterval: 1 },
        yAxis: {
            type: 'category',
            inverse: true,
            data: top.map((item) => item.categoria),
            axisLabel: { width: 200, overflow: 'truncate' },
        },
        series: [
            {
                type: 'bar',
                data: top.map((item) => item.promedio_puntos),
                barMaxWidth: 26,
                itemStyle: { color: '#b45309', borderRadius: [0, 6, 6, 0] },
            },
        ],
    });
}

function renderTablaItems(tbodyId, items, modo) {
    const tbody = document.getElementById(tbodyId);
    if (!tbody) return;
    delete tbody.dataset.skeleton;

    if (!items.length) {
        tbody.innerHTML = `
            <tr>
                <td colspan="3" class="px-4 py-8 text-center text-slate-500 dark:text-slate-400">Sin datos en el rango seleccionado.</td>
            </tr>
        `;
        return;
    }

    tbody.innerHTML = items.map((item) => {
        const terceraColumna = modo === 'menos'
            ? `<span class="font-semibold text-rose-600 dark:text-rose-400">${formatearNumero(item.cumplimiento)}%</span>`
            : `<span class="font-semibold text-emerald-600 dark:text-emerald-400">${formatearNumero(item.cumplimiento)}%</span>`;
        const segundaColumna = modo === 'menos'
            ? formatearEntero(item.no_cumple)
            : formatearEntero(item.total);

        return `
            <tr class="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                <td class="px-4 py-4 align-top">
                    <div class="font-semibold text-slate-900 dark:text-white">${escapeHtml(item.codigo || '')}</div>
                    <div class="mt-1 max-w-md text-xs text-slate-500 dark:text-slate-400">${escapeHtml(item.descripcion || '')}</div>
                    <div class="mt-2 text-xs text-slate-400 dark:text-slate-500">${escapeHtml(item.categoria || '')}</div>
                </td>
                <td class="px-4 py-4 text-center align-top font-semibold text-slate-800 dark:text-slate-100">${segundaColumna}</td>
                <td class="px-4 py-4 text-center align-top">${terceraColumna}</td>
            </tr>
        `;
    }).join('');
}

function obtenerChartReglamento(id) {
    if (typeof echarts === 'undefined') {
        mostrarAlertaReglamento('No se cargó ECharts. Revisa la conexión a los assets CDN.', 'error');
        return null;
    }

    const elemento = document.getElementById(id);
    if (!elemento) return null;

    if (!reglamentoCharts[id]) {
        limpiarSkeletonChart(elemento);
        reglamentoCharts[id] = echarts.init(elemento, document.documentElement.classList.contains('dark') ? 'dark' : null);
    }

    return reglamentoCharts[id];
}

function setLoadingReglamento(loading) {
    document.getElementById('reglamentoAnalitica')?.setAttribute('aria-busy', String(loading));
    setSkeletonKpisReglamento(loading);
    setSkeletonChartsReglamento(loading);
    setSkeletonTablasReglamento(loading);
}

function setSkeletonKpisReglamento(loading) {
    Object.keys(REGLAMENTO_KPI_CLASSES).forEach((id) => {
        const elemento = document.getElementById(id);
        if (!elemento) return;

        if (loading) {
            elemento.textContent = '';
            elemento.className = 'reglamento-skeleton reglamento-skeleton-kpi';
            return;
        }

        if (elemento.classList.contains('reglamento-skeleton')) {
            elemento.className = REGLAMENTO_KPI_CLASSES[id];
            elemento.textContent = REGLAMENTO_KPI_PLACEHOLDERS[id] || '0';
        }
    });

    const detalle = document.getElementById('kpiComparativoDetalle');
    if (!detalle) return;

    if (loading) {
        detalle.textContent = '';
        detalle.className = 'reglamento-skeleton reglamento-skeleton-detail';
        return;
    }

    if (detalle.classList.contains('reglamento-skeleton')) {
        detalle.className = REGLAMENTO_KPI_DETALLE_CLASS;
        detalle.textContent = 'Sin datos comparables';
    }
}

function setSkeletonChartsReglamento(loading) {
    REGLAMENTO_CHART_IDS.forEach((id) => {
        const elemento = document.getElementById(id);
        if (!elemento) return;

        const chart = reglamentoCharts[id];
        if (loading) {
            if (chart) {
                mostrarSkeletonChartOverlay(elemento);
                return;
            }

            elemento.dataset.skeleton = 'true';
            elemento.innerHTML = crearSkeletonChartReglamento();
            return;
        }

        if (chart) {
            quitarSkeletonChartOverlay(elemento);
            return;
        }

        if (elemento.dataset.skeleton === 'true') {
            limpiarSkeletonChart(elemento);
        }
    });
}

function setSkeletonTablasReglamento(loading) {
    REGLAMENTO_TABLE_IDS.forEach((id) => {
        const tbody = document.getElementById(id);
        if (!tbody) return;

        if (loading) {
            tbody.dataset.skeleton = 'true';
            tbody.innerHTML = crearSkeletonFilasTablaReglamento();
            return;
        }

        if (tbody.dataset.skeleton === 'true') {
            delete tbody.dataset.skeleton;
            tbody.innerHTML = `
                <tr>
                    <td colspan="3" class="px-4 py-8 text-center text-slate-500 dark:text-slate-400">Sin datos en el rango seleccionado.</td>
                </tr>
            `;
        }
    });
}

function crearSkeletonChartReglamento() {
    const alturas = [48, 72, 56, 84, 44, 68, 60, 78];
    const barras = alturas.map((altura) => (
        `<span class="reglamento-skeleton reglamento-chart-skeleton-bar" style="height: ${altura}%;"></span>`
    )).join('');

    return `
        <div class="reglamento-chart-skeleton" aria-hidden="true">
            <span class="reglamento-skeleton" style="height: 1rem; width: 42%; border-radius: 9999px;"></span>
            <div class="reglamento-chart-skeleton-bars">${barras}</div>
            <span class="reglamento-skeleton" style="height: 0.875rem; width: 68%; border-radius: 9999px;"></span>
        </div>
    `;
}

function crearSkeletonFilasTablaReglamento() {
    return Array.from({ length: 5 }).map((_, index) => {
        const anchoPrincipal = 58 + (index % 3) * 12;
        return `
            <tr>
                <td class="px-4 py-4 align-top">
                    <span class="reglamento-skeleton" style="height: 1rem; width: 4.5rem; border-radius: 9999px;"></span>
                    <span class="reglamento-skeleton" style="height: 0.75rem; width: ${anchoPrincipal}%; margin-top: 0.75rem; border-radius: 9999px;"></span>
                    <span class="reglamento-skeleton" style="height: 0.75rem; width: 38%; margin-top: 0.5rem; border-radius: 9999px;"></span>
                </td>
                <td class="px-4 py-4 align-top">
                    <span class="reglamento-skeleton" style="height: 1rem; width: 3rem; margin: 0 auto; border-radius: 9999px;"></span>
                </td>
                <td class="px-4 py-4 align-top">
                    <span class="reglamento-skeleton" style="height: 1rem; width: 3.5rem; margin: 0 auto; border-radius: 9999px;"></span>
                </td>
            </tr>
        `;
    }).join('');
}

function limpiarSkeletonChart(elemento) {
    quitarSkeletonChartOverlay(elemento);
    if (elemento.dataset.skeleton !== 'true') return;
    elemento.innerHTML = '';
    delete elemento.dataset.skeleton;
}

function mostrarSkeletonChartOverlay(elemento) {
    if (elemento.querySelector('.reglamento-chart-skeleton-overlay')) return;

    const overlay = document.createElement('div');
    overlay.className = 'reglamento-chart-skeleton-overlay';
    overlay.innerHTML = crearSkeletonChartReglamento();
    elemento.appendChild(overlay);
}

function quitarSkeletonChartOverlay(elemento) {
    elemento.querySelector('.reglamento-chart-skeleton-overlay')?.remove();
}

function redimensionarChartsReglamento() {
    Object.values(reglamentoCharts).forEach((chart) => chart.resize());
}

function actualizarUrlAnalitica(params) {
    const nuevaUrl = `${window.location.pathname}?${params.toString()}`;
    window.history.replaceState({}, '', nuevaUrl);
}

function mostrarAlertaReglamento(texto, tipo = 'info') {
    const alerta = document.getElementById('analiticaAlert');
    if (!alerta) return;

    const estilos = {
        error: 'border-red-200 bg-red-50 text-red-800 dark:border-red-800 dark:bg-red-900/20 dark:text-red-300',
        info: 'border-blue-200 bg-blue-50 text-blue-800 dark:border-blue-800 dark:bg-blue-900/20 dark:text-blue-300',
    };
    alerta.className = `mt-4 rounded-xl border px-4 py-3 text-sm font-medium ${estilos[tipo] || estilos.info}`;
    alerta.textContent = texto;
    alerta.classList.remove('hidden');
}

function ocultarAlertaReglamento() {
    document.getElementById('analiticaAlert')?.classList.add('hidden');
}

function setKpiTexto(id, texto, clases = null) {
    const elemento = document.getElementById(id);
    if (!elemento) return;

    elemento.className = clases || REGLAMENTO_KPI_CLASSES[id] || '';
    elemento.textContent = texto;
}

function setKpiDetalle(texto) {
    const detalle = document.getElementById('kpiComparativoDetalle');
    if (!detalle) return;

    detalle.className = REGLAMENTO_KPI_DETALLE_CLASS;
    detalle.textContent = texto;
}

function formatearFechaIso(fecha) {
    const year = fecha.getFullYear();
    const month = String(fecha.getMonth() + 1).padStart(2, '0');
    const day = String(fecha.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
}

function esFechaIso(valor) {
    return /^\d{4}-\d{2}-\d{2}$/.test(String(valor || ''));
}

function formatearNumero(valor) {
    const numero = Number(valor || 0);
    return numero.toLocaleString('es-PE', {
        minimumFractionDigits: Number.isInteger(numero) ? 0 : 1,
        maximumFractionDigits: 2,
    });
}

function formatearEntero(valor) {
    return Number(valor || 0).toLocaleString('es-PE', { maximumFractionDigits: 0 });
}

function escapeHtml(valor) {
    return String(valor ?? '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}
