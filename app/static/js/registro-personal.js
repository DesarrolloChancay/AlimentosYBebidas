// Módulo de Registro de Personal.
// Estructura basada en private/guia_html_registro_personal.md: dos plantillas
// completas (entre semana / fin de semana), se muestra una u otra según el día.
// Ningún campo se deshabilita ni se bloquea nunca.

const DIAS_SEMANA = ['Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado'];

function leerMinimosDia() {
    const data = document.getElementById('minimos-dia-data');
    if (!data) return {};
    try {
        return JSON.parse(data.textContent) || {};
    } catch (err) {
        return {};
    }
}

function contarNombres(texto) {
    if (!texto) return 0;
    return texto
        .split('/')
        .map((s) => s.trim())
        .filter((s) => s.length > 0).length;
}

function actualizarAlertasMinimos(minimosDia) {
    // Las dos plantillas (entre semana / fin de semana) coexisten en el DOM aunque una esté
    // oculta, y ambas reutilizan los mismos data-rol — hay que buscar solo dentro de la
    // plantilla visible, si no el resultado de una pisa al de la otra.
    const tablaFinDeSemana = document.getElementById('tabla-fin-de-semana');
    const esFinDeSemana = tablaFinDeSemana && !tablaFinDeSemana.classList.contains('hidden');
    const contenedor = esFinDeSemana ? tablaFinDeSemana : document.getElementById('tabla-entre-semana');
    if (!contenedor) return;

    contenedor.querySelectorAll('tr[data-rol], tr.puesto-input-row[data-rol]').forEach((fila) => {
        const rol = fila.dataset.rol;
        const minimo = minimosDia[rol];
        const alerta = contenedor.querySelector(`.minimo-alerta[data-rol="${rol}"]`);
        if (!alerta) return;

        if (!minimo || minimo.opcional || !minimo.cantidad_minima) {
            alerta.textContent = '';
            return;
        }

        const textarea = fila.querySelector('textarea');
        const cantidadIngresada = contarNombres(textarea ? textarea.value : '');

        if (cantidadIngresada < minimo.cantidad_minima) {
            const faltan = minimo.cantidad_minima - cantidadIngresada;
            alerta.textContent = `⚠ Faltan ${faltan} (mínimo ${minimo.cantidad_minima})`;
        } else {
            alerta.textContent = '';
        }
    });
}

function actualizarVistaSegunFecha() {
    const fechaInput = document.getElementById('registro-fecha');
    const tablaEntreSemana = document.getElementById('tabla-entre-semana');
    const tablaFinDeSemana = document.getElementById('tabla-fin-de-semana');
    const tituloEntreSemana = document.getElementById('titulo-entre-semana');
    const tituloFinDeSemana = document.getElementById('titulo-fin-de-semana');
    if (!fechaInput) return;

    const dia = fechaInput.value ? new Date(fechaInput.value + 'T00:00:00').getDay() : 1;
    const nombreDia = DIAS_SEMANA[dia];
    const esFinDeSemana = dia === 0 || dia === 6;

    if (tablaEntreSemana) tablaEntreSemana.classList.toggle('hidden', esFinDeSemana);
    if (tablaFinDeSemana) tablaFinDeSemana.classList.toggle('hidden', !esFinDeSemana);
    if (tituloEntreSemana) tituloEntreSemana.textContent = nombreDia;
    if (tituloFinDeSemana) tituloFinDeSemana.textContent = nombreDia;
}

function irAFechaSeleccionada() {
    const estSelect = document.getElementById('registro-establecimiento');
    const fechaInput = document.getElementById('registro-fecha');
    const establecimientoId = estSelect ? estSelect.value : '';
    const fecha = fechaInput ? fechaInput.value : '';

    if (establecimientoId && fecha) {
        // Recarga la página para ese establecimiento/fecha: si ya hay algo guardado
        // se precarga, si no, los campos quedan limpios (nunca arrastra datos de otro día).
        const params = new URLSearchParams({ establecimiento_id: establecimientoId, fecha: fecha });
        window.location.href = `/registro-personal/nuevo?${params.toString()}`;
        return;
    }
    // Sin establecimiento todavía no hay nada que cargar, solo actualizamos qué plantilla se ve.
    actualizarVistaSegunFecha();
}

function crearFilaRolLibre() {
    const tr = document.createElement('tr');
    tr.dataset.rolLibre = 'true';
    tr.innerHTML = `
        <td class="puesto-col">
            <div class="flex items-center gap-2">
                <input type="text" placeholder="Nombre del rol">
                <button type="button" class="text-xs text-red-500 hover:underline btn-quitar-rol flex-shrink-0">Quitar</button>
            </div>
        </td>
        <td><textarea rows="1" placeholder="Nombres. Ej: Wesly / Joselyn / Stiv (?)"></textarea></td>
    `;
    tr.querySelector('.btn-quitar-rol').addEventListener('click', () => tr.remove());
    return tr;
}

function activarBotonesQuitarRol() {
    document.querySelectorAll('#registro-roles-container tr[data-rol-libre="true"] .btn-quitar-rol').forEach((btn) => {
        btn.addEventListener('click', () => btn.closest('tr').remove());
    });
}

function recolectarRolesVisibles() {
    const roles = [];
    const tablaFinDeSemana = document.getElementById('tabla-fin-de-semana');
    const esFinDeSemana = tablaFinDeSemana && !tablaFinDeSemana.classList.contains('hidden');

    if (esFinDeSemana) {
        document.querySelectorAll('#tabla-fin-de-semana tr.puesto-input-row[data-rol]').forEach((fila) => {
            const textarea = fila.querySelector('textarea');
            roles.push({
                rol_nombre: fila.dataset.rol,
                nombres: textarea ? textarea.value : '',
                es_rol_libre: false,
            });
        });
    } else {
        document.querySelectorAll('#registro-roles-container tr').forEach((fila) => {
            const textarea = fila.querySelector('textarea');
            if (fila.dataset.rolLibre === 'true') {
                const inputNombreRol = fila.querySelector('input[type="text"]');
                roles.push({
                    rol_nombre: inputNombreRol ? inputNombreRol.value : '',
                    nombres: textarea ? textarea.value : '',
                    es_rol_libre: true,
                });
            } else if (fila.dataset.rol) {
                roles.push({
                    rol_nombre: fila.dataset.rol,
                    nombres: textarea ? textarea.value : '',
                    es_rol_libre: false,
                });
            }
        });
    }
    return roles;
}

async function guardarRegistro() {
    const establecimientoSelect = document.getElementById('registro-establecimiento');
    const fechaInput = document.getElementById('registro-fecha');
    const btnGuardar = document.getElementById('btn-guardar-registro');

    const establecimientoId = establecimientoSelect ? establecimientoSelect.value : '';
    const fecha = fechaInput ? fechaInput.value : '';

    if (!establecimientoId || !fecha) {
        mostrarNotificacion('Elige establecimiento y fecha antes de guardar.', 'warning');
        return;
    }

    const payload = {
        establecimiento_id: establecimientoId,
        fecha: fecha,
        roles: recolectarRolesVisibles(),
    };

    if (btnGuardar) {
        btnGuardar.disabled = true;
        btnGuardar.textContent = 'Guardando...';
    }

    try {
        const response = await fetch('/registro-personal/guardar', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        const data = await response.json();
        if (response.ok && data.success) {
            mostrarNotificacion('Registro guardado correctamente.', 'success');
        } else {
            mostrarNotificacion(data.error || 'No se pudo guardar el registro.', 'error');
        }
    } catch (err) {
        mostrarNotificacion('Error de conexión al guardar.', 'error');
    } finally {
        if (btnGuardar) {
            btnGuardar.disabled = false;
            btnGuardar.textContent = 'Guardar registro';
        }
    }
}

document.addEventListener('DOMContentLoaded', () => {
    const fechaInput = document.getElementById('registro-fecha');
    const estSelect = document.getElementById('registro-establecimiento');
    if (fechaInput) {
        if (!fechaInput.value) {
            fechaInput.value = new Date().toISOString().slice(0, 10);
        }
        fechaInput.addEventListener('change', irAFechaSeleccionada);
        actualizarVistaSegunFecha();
    }
    if (estSelect) {
        estSelect.addEventListener('change', irAFechaSeleccionada);
    }

    const btnAgregarRol = document.getElementById('btn-agregar-rol');
    const container = document.getElementById('registro-roles-container');
    if (btnAgregarRol && container) {
        btnAgregarRol.addEventListener('click', () => {
            container.appendChild(crearFilaRolLibre());
        });
    }
    activarBotonesQuitarRol();

    const btnGuardar = document.getElementById('btn-guardar-registro');
    if (btnGuardar) {
        btnGuardar.addEventListener('click', guardarRegistro);
    }

    const minimosDia = leerMinimosDia();
    document.querySelectorAll('.tabla-personal-form textarea').forEach((textarea) => {
        textarea.addEventListener('input', () => actualizarAlertasMinimos(minimosDia));
    });
    actualizarAlertasMinimos(minimosDia);
});
