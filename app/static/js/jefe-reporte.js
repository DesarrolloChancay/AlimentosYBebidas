/**
 * Reporte de Establecimiento - JavaScript
 * Sistema de gestión de reportes para jefes de establecimiento
 */

// Variables globales
let chartTendencias = null;
let periodoActual = 'mes';

// ===== INICIALIZACIÓN =====
document.addEventListener('DOMContentLoaded', function() {
    
    // Verificar que Chart.js está disponible
    if (typeof Chart === 'undefined') {
        return;
    }
    
    // Inicializar con datos reales si están disponibles
    const reporte = window.reporte_data || {};
    
    // Verificar elementos DOM importantes
    const elementos = {
        chartTendencias: document.getElementById('chartTendencias'),
        tabs: document.querySelectorAll('.periodo-tab'),
        contenidos: document.querySelectorAll('.periodo-content')
    };
    
    
    inicializarGraficos();
    
});

// ===== FUNCIÓN DE CAMBIO DE PERÍODO =====
function cambiarPeriodo(periodo) {
    
    try {
        // Actualizar tabs con las nuevas clases de Tailwind
        document.querySelectorAll('.periodo-tab').forEach(tab => {
            // Remover clases activas
            tab.classList.remove('bg-gradient-to-r', 'from-indigo-500', 'to-purple-600', 'text-white', 'shadow-md');
            // Agregar clases inactivas
            tab.classList.add('text-slate-600', 'dark:text-slate-300', 'hover:bg-slate-100', 'dark:hover:bg-slate-700');
        });
        
        const activeTab = document.getElementById(`tab-${periodo}`);
        if (activeTab) {
            // Remover clases inactivas
            activeTab.classList.remove('text-slate-600', 'dark:text-slate-300', 'hover:bg-slate-100', 'dark:hover:bg-slate-700');
            // Agregar clases activas
            activeTab.classList.add('bg-gradient-to-r', 'from-indigo-500', 'to-purple-600', 'text-white', 'shadow-md');
        }
        
        // Mostrar contenido correspondiente
        document.querySelectorAll('.periodo-content').forEach(content => {
            content.classList.add('hidden');
        });
        
        const targetContent = document.getElementById(`metricas-${periodo}`);
        if (targetContent) {
            targetContent.classList.remove('hidden');
        } else {
        }
    } catch (error) {
    }
}

// ===== INICIALIZACIÓN DE GRÁFICOS =====
function inicializarGraficos() {
    try {
        const ctx = document.getElementById('chartTendencias');
        
        if (!ctx) {
            return;
        }

        const context = ctx.getContext('2d');
        if (!context) {
            return;
        }

        chartTendencias = new Chart(context, {
            type: 'line',
            data: {
                labels: ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'],
                datasets: [{
                    label: 'Inspecciones Completadas',
                    data: [12, 19, 15, 25, 22, 18],
                    borderColor: '#10b981',
                    backgroundColor: 'rgba(16, 185, 129, 0.1)',
                    tension: 0.4,
                    fill: true
                }, {
                    label: 'Inspecciones Iniciadas',
                    data: [15, 25, 18, 30, 28, 22],
                    borderColor: '#3b82f6',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top',
                    },
                    tooltip: {
                        mode: 'index',
                        intersect: false,
                    }
                },
                scales: {
                    x: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Mes'
                        }
                    },
                    y: {
                        display: true,
                        title: {
                            display: true,
                            text: 'Cantidad'
                        },
                        beginAtZero: true
                    }
                },
                interaction: {
                    mode: 'nearest',
                    axis: 'x',
                    intersect: false
                }
            }
        });
        
    } catch (error) {
    }
}

// ===== FUNCIÓN VER INSPECCIÓN =====
function verInspeccion(inspeccionId) {
    window.open(`/inspecciones/${inspeccionId}/detalle`, '_blank');
}

// ===== FUNCIÓN EXPORTAR PDF =====
function exportarPDF() {
    
    try {
        // Ocultar elementos que no queremos en el PDF
        const elementosOcultar = document.querySelectorAll('button, .no-print');
        elementosOcultar.forEach(elemento => {
            elemento.style.visibility = 'hidden';
        });
        
        // Configurar estilo para impresión
        const estiloImpresion = document.createElement('style');
        estiloImpresion.textContent = `
            @media print {
                body { margin: 0; padding: 20px; }
                .no-print { display: none !important; }
                .print-only { display: block !important; }
                button { display: none !important; }
                .bg-gradient-to-r { background: linear-gradient(to right, #6366f1, #8b5cf6) !important; }
                * { color-adjust: exact !important; -webkit-print-color-adjust: exact !important; }
            }
        `;
        document.head.appendChild(estiloImpresion);
        
        // Imprimir
        window.print();
        
        // Restaurar elementos después de un delay
        setTimeout(() => {
            elementosOcultar.forEach(elemento => {
                elemento.style.visibility = 'visible';
            });
            document.head.removeChild(estiloImpresion);
        }, 1000);
        
    } catch (error) {
    }
}

// ===== UTILIDADES =====
function formatearFecha(fecha) {
    const opciones = { 
        year: 'numeric', 
        month: '2-digit', 
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    };
    return new Date(fecha).toLocaleDateString('es-ES', opciones);
}

// Hacer las funciones disponibles globalmente
window.cambiarPeriodo = cambiarPeriodo;
window.exportarPDF = exportarPDF;
window.verInspeccion = verInspeccion;
