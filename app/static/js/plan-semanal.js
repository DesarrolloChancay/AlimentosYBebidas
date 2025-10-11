/**
 * ✅ PLAN SEMANAL - Gestión ORM de metas de evaluaciones
 * FUNCIONALIDADES:
 * - Edición de metas por inspector/admin
 * - Actualización automática de contadores
 * - Sincronización con base de datos
 */

class PlanSemanalManager {
    constructor() {
        this.currentWeekOffset = 0;
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.loadPlanSemanal();
    }

    setupEventListeners() {
        // Botones de navegación de semanas
        document.addEventListener('click', (e) => {
            if (e.target.matches('[data-semana-anterior]')) {
                this.currentWeekOffset--;
                this.loadPlanSemanal();
            }
            
            if (e.target.matches('[data-semana-siguiente]')) {
                this.currentWeekOffset++;
                this.loadPlanSemanal();
            }
            
            if (e.target.matches('[data-semana-actual]')) {
                this.currentWeekOffset = 0;
                this.loadPlanSemanal();
            }

            // Editar meta semanal
            if (e.target.matches('[data-editar-meta]')) {
                const establecimientoId = e.target.dataset.establecimientoId;
                const metaActual = e.target.dataset.metaActual;
                this.mostrarModalEditarMeta(establecimientoId, metaActual);
            }
        });

        // Socket para actualizaciones en tiempo real
        if (typeof socket !== 'undefined') {
            socket.on('plan_semanal_actualizado', (data) => {
                this.actualizarContadorTiempoReal(data);
            });
        }
    }

    async loadPlanSemanal() {
        try {
            showLoading();
            
            const response = await fetch(`/inspecciones/api/dashboard/plan-semanal?semana_offset=${this.currentWeekOffset}`);
            const data = await response.json();

            if (response.ok) {
                this.renderPlanSemanal(data);
            } else {
                showNotification('Error cargando plan semanal: ' + data.error, 'error');
            }
        } catch (error) {
            showNotification('Error de conexión', 'error');
        } finally {
            hideLoading();
        }
    }

    renderPlanSemanal(data) {
        const container = document.getElementById('plan-semanal-container');
        if (!container) return;

        // Actualizar header con información de semana
        this.updateWeekHeader(data.semana);

        // Renderizar establecimientos
        const establecimientosHtml = data.establecimientos.map(est => 
            this.renderEstablecimientoCard(est)
        ).join('');

        container.innerHTML = `
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                ${establecimientosHtml}
            </div>
            
            <!-- Resumen General -->
            <div class="mt-8 bg-white dark:bg-slate-800 rounded-lg shadow-lg p-6">
                <h3 class="text-lg font-semibold text-slate-800 dark:text-white mb-4">
                    Resumen General
                </h3>
                <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div class="text-center">
                        <div class="text-2xl font-bold text-blue-600">${data.resumen_general.total_inspecciones}</div>
                        <div class="text-sm text-slate-600 dark:text-slate-400">Realizadas</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-green-600">${data.resumen_general.establecimientos_completos}</div>
                        <div class="text-sm text-slate-600 dark:text-slate-400">Completos</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-orange-600">${data.resumen_general.establecimientos_pendientes}</div>
                        <div class="text-sm text-slate-600 dark:text-slate-400">Pendientes</div>
                    </div>
                    <div class="text-center">
                        <div class="text-2xl font-bold text-purple-600">${data.resumen_general.promedio_cumplimiento}%</div>
                        <div class="text-sm text-slate-600 dark:text-slate-400">Promedio</div>
                    </div>
                </div>
            </div>
        `;
    }

    renderEstablecimientoCard(est) {
        const userRole = window.userRole || '';
        const canEditMeta = ['Administrador', 'Inspector'].includes(userRole);
        
        const progressPercent = Math.min(100, (est.inspecciones_realizadas / est.meta_semanal) * 100);
        const statusColor = est.estado === 'completo' ? 'bg-green-500' : 'bg-orange-500';
        const statusIcon = est.estado === 'completo' ? 'check' : 'clock';

        return `
            <div class="bg-white dark:bg-slate-800 rounded-lg shadow-lg p-6 border-l-4 ${est.estado === 'completo' ? 'border-green-500' : 'border-orange-500'}">
                <!-- Header -->
                <div class="flex justify-between items-start mb-4">
                    <h3 class="font-semibold text-slate-800 dark:text-white text-lg">
                        ${est.nombre}
                    </h3>
                    <span class="text-2xl">${est.estado === 'completo' ? '<i class="fas fa-check text-green-600"></i>' : '<i class="fas fa-clock text-orange-600"></i>'}</span>
                </div>

                <!-- Progreso -->
                <div class="mb-4">
                    <div class="flex justify-between items-center mb-2">
                        <span class="text-sm text-slate-600 dark:text-slate-400">Progreso</span>
                        <span class="font-semibold text-slate-800 dark:text-white">
                            ${est.inspecciones_realizadas}/${est.meta_semanal}
                        </span>
                    </div>
                    <div class="w-full bg-slate-200 dark:bg-slate-700 rounded-full h-3">
                        <div class="${statusColor} h-3 rounded-full transition-all duration-300" 
                             style="width: ${progressPercent}%"></div>
                    </div>
                    <div class="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        ${est.porcentaje_cumplimiento_meta}% completado
                    </div>
                </div>

                <!-- Estadísticas -->
                <div class="grid grid-cols-2 gap-4 mb-4">
                    <div class="text-center">
                        <div class="text-lg font-bold text-blue-600">${est.promedio_calificacion}%</div>
                        <div class="text-xs text-slate-600 dark:text-slate-400">Promedio</div>
                    </div>
                    <div class="text-center">
                        <div class="text-lg font-bold text-orange-600">${est.inspecciones_pendientes}</div>
                        <div class="text-xs text-slate-600 dark:text-slate-400">Pendientes</div>
                    </div>
                </div>

                <!-- Acciones -->
                <div class="flex gap-2">
                    ${canEditMeta ? `
                        <button class="btn-secondary text-xs px-3 py-2 flex-1" 
                                data-editar-meta 
                                data-establecimiento-id="${est.establecimiento_id}"
                                data-meta-actual="${est.meta_semanal}">
                            <i class="fas fa-cog mr-1"></i>Editar Meta
                        </button>
                    ` : ''}
                    <button class="btn-primary text-xs px-3 py-2 flex-1" 
                            onclick="verDetalleEstablecimiento(${est.establecimiento_id})">
                        <i class="fas fa-eye mr-1"></i>Ver Detalle
                    </button>
                </div>

                <!-- Estado -->
                <div class="mt-3 text-center">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                        est.estado === 'completo' 
                            ? 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200' 
                            : 'bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200'
                    }">
                        ${est.estado === 'completo' ? 'Completado' : `${est.dias_restantes} días restantes`}
                    </span>
                </div>
            </div>
        `;
    }

    updateWeekHeader(semanaInfo) {
        const header = document.getElementById('semana-header');
        if (!header) return;

        const fechaInicio = new Date(semanaInfo.inicio).toLocaleDateString('es-PE');
        const fechaFin = new Date(semanaInfo.fin).toLocaleDateString('es-PE');
        const esActual = semanaInfo.es_actual;

        header.innerHTML = `
            <div class="flex justify-between items-center">
                <button class="btn-secondary" data-semana-anterior>
                    ← Anterior
                </button>
                
                <div class="text-center">
                    <h2 class="text-2xl font-bold text-slate-800 dark:text-white">
                        ${esActual ? 'Semana Actual' : 'Semana del'} 
                    </h2>
                    <p class="text-slate-600 dark:text-slate-400">
                        ${fechaInicio} - ${fechaFin}
                    </p>
                </div>
                
                <div class="flex gap-2">
                    ${!esActual ? `
                        <button class="btn-primary" data-semana-actual>
                            <i class="fas fa-calendar-day mr-1"></i>Actual
                        </button>
                    ` : ''}
                    <button class="btn-secondary" data-semana-siguiente>
                        Siguiente →
                    </button>
                </div>
            </div>
        `;
    }

    mostrarModalEditarMeta(establecimientoId, metaActual) {
        const modal = document.createElement('div');
        modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4';
        modal.innerHTML = `
            <div class="bg-white dark:bg-slate-800 rounded-lg p-6 max-w-md w-full">
                <h3 class="text-lg font-semibold text-slate-800 dark:text-white mb-4">
                    <i class="fas fa-cog mr-2"></i>Editar Meta Semanal
                </h3>
                
                <div class="mb-4">
                    <label class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                        Nueva Meta (1-10 evaluaciones)
                    </label>
                    <input type="number" 
                           id="nueva-meta" 
                           min="1" 
                           max="10" 
                           value="${metaActual}"
                           class="w-full px-3 py-2 border border-slate-300 dark:border-slate-600 rounded-lg focus:ring-2 focus:ring-blue-500 dark:bg-slate-700 dark:text-white">
                </div>
                
                <div class="flex gap-3">
                    <button class="btn-secondary flex-1" onclick="this.closest('.fixed').remove()">
                        Cancelar
                    </button>
                    <button class="btn-primary flex-1" onclick="planSemanalManager.guardarNuevaMeta(${establecimientoId}, this)">
                        <i class="fas fa-save mr-1"></i>Guardar
                    </button>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
        document.getElementById('nueva-meta').focus();
    }

    async guardarNuevaMeta(establecimientoId, button) {
        const modal = button.closest('.fixed');
        const nuevaMeta = parseInt(document.getElementById('nueva-meta').value);
        
        if (!nuevaMeta || nuevaMeta < 1 || nuevaMeta > 10) {
            showNotification('Meta debe ser entre 1 y 10', 'error');
            return;
        }

        try {
            button.disabled = true;
            button.textContent = 'Guardando...';

            const response = await fetch('/inspecciones/api/dashboard/actualizar-meta', {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    establecimiento_id: establecimientoId,
                    nueva_meta: nuevaMeta,
                    semana: new Date().getWeekNumber(),
                    ano: new Date().getFullYear()
                })
            });

            const data = await response.json();

            if (response.ok) {
                showNotification('✅ Meta actualizada correctamente', 'success');
                modal.remove();
                this.loadPlanSemanal(); // Recargar datos
            } else {
                showNotification('Error: ' + data.error, 'error');
            }
        } catch (error) {
            showNotification('Error de conexión', 'error');
        } finally {
            button.disabled = false;
            button.textContent = 'Guardar';
        }
    }

    actualizarContadorTiempoReal(data) {
        // Actualizar contador cuando se complete una inspección
        if (data.tipo === 'inspeccion_completada') {
            this.loadPlanSemanal();
            showNotification(`✅ Nueva inspección completada en ${data.establecimiento}`, 'success');
        }
    }
}

// Helper para obtener número de semana
Date.prototype.getWeekNumber = function() {
    const d = new Date(Date.UTC(this.getFullYear(), this.getMonth(), this.getDate()));
    const dayNum = d.getUTCDay() || 7;
    d.setUTCDate(d.getUTCDate() + 4 - dayNum);
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
    return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
};

// Inicializar cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    if (document.getElementById('plan-semanal-container')) {
        window.planSemanalManager = new PlanSemanalManager();
    }
});

// Función global para ver detalle de establecimiento
function verDetalleEstablecimiento(establecimientoId) {
    // Redirigir o abrir modal con detalle del establecimiento
    window.location.href = `/inspecciones/?establecimiento=${establecimientoId}`;
}
