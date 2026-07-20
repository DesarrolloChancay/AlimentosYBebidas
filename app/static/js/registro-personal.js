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

function parsearNombres(texto) {
    if (!texto) return [];
    return String(texto)
        .split(/[/|,]+/)
        .map((s) => s.trim())
        .filter((s) => s.length > 0);
}

function contarNombres(texto) {
    return parsearNombres(texto).length;
}

function obtenerNombresDeCampo(fila) {
    const tagInput = fila.querySelector('.tag-input');
    if (tagInput) {
        return obtenerNombresTagInput(tagInput);
    }
    const textarea = fila.querySelector('textarea');
    return textarea ? textarea.value : '';
}

function obtenerNombresTagInput(tagInput) {
    const chips = Array.from(tagInput.querySelectorAll('.tag-chip'))
        .map((chip) => {
            const edit = chip.querySelector('.tag-chip-edit');
            if (edit) return edit.value.trim();
            const label = chip.querySelector('.tag-chip-label');
            return label ? label.textContent.trim() : (chip.dataset.value || '').trim();
        })
        .filter(Boolean);
    const pendiente = tagInput.querySelector('.tag-input-field');
    const valorPendiente = pendiente ? pendiente.value.trim() : '';
    if (valorPendiente) {
        chips.push(valorPendiente);
    }
    return chips.join(' / ');
}

function crearChip(nombre, readonly) {
    const chip = document.createElement('span');
    chip.className = 'tag-chip';
    chip.dataset.value = nombre;

    const label = document.createElement('span');
    label.className = 'tag-chip-label';
    label.textContent = nombre;
    label.title = readonly ? nombre : 'Clic para editar';
    chip.appendChild(label);

    if (!readonly) {
        label.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            iniciarEdicionChip(chip);
        });

        const removeBtn = document.createElement('button');
        removeBtn.type = 'button';
        removeBtn.className = 'tag-chip-remove';
        removeBtn.setAttribute('aria-label', `Quitar ${nombre}`);
        removeBtn.textContent = '×';
        removeBtn.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            const container = chip.closest('.tag-input');
            chip.remove();
            if (container) {
                container.dispatchEvent(new CustomEvent('tags:change', { bubbles: true }));
            }
        });
        chip.appendChild(removeBtn);
    }

    return chip;
}

function nombresExistentesEnTagInput(tagInput, exceptChip) {
    return Array.from(tagInput.querySelectorAll('.tag-chip'))
        .filter((chip) => chip !== exceptChip)
        .map((chip) => {
            const label = chip.querySelector('.tag-chip-label');
            return (label ? label.textContent : chip.dataset.value || '').trim().toLowerCase();
        })
        .filter(Boolean);
}

function iniciarEdicionChip(chip) {
    if (!chip || chip.classList.contains('is-editing')) return;

    const tagInput = chip.closest('.tag-input');
    if (!tagInput || tagInput.dataset.readonly === 'true') return;

    // Cierra otra edición abierta en el mismo campo
    tagInput.querySelectorAll('.tag-chip.is-editing .tag-chip-edit').forEach((otro) => {
        otro.blur();
    });

    const label = chip.querySelector('.tag-chip-label');
    const removeBtn = chip.querySelector('.tag-chip-remove');
    if (!label) return;

    const valorOriginal = label.textContent.trim();
    chip.classList.add('is-editing');

    // Lleva el chip en edición al frente visual (última fila del wrap)
    const field = tagInput.querySelector('.tag-input-field');
    if (field) {
        tagInput.insertBefore(chip, field);
    }

    const input = document.createElement('input');
    input.type = 'text';
    input.className = 'tag-chip-edit';
    input.value = valorOriginal;
    input.setAttribute('aria-label', 'Editar nombre');
    input.setAttribute('placeholder', 'Editar nombre…');
    label.replaceWith(input);

    const finalizar = (guardar) => {
        if (!chip.classList.contains('is-editing')) return;

        const nuevoValor = input.value.trim();
        chip.classList.remove('is-editing');

        if (!guardar || !nuevoValor) {
            chip.remove();
            tagInput.dispatchEvent(new CustomEvent('tags:change', { bubbles: true }));
            return;
        }

        const duplicado = nombresExistentesEnTagInput(tagInput, chip).includes(nuevoValor.toLowerCase());
        const valorFinal = duplicado ? valorOriginal : nuevoValor;

        const nuevoLabel = document.createElement('span');
        nuevoLabel.className = 'tag-chip-label';
        nuevoLabel.textContent = valorFinal;
        nuevoLabel.title = 'Clic para editar';
        nuevoLabel.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            iniciarEdicionChip(chip);
        });

        input.replaceWith(nuevoLabel);
        chip.dataset.value = valorFinal;
        if (removeBtn) {
            removeBtn.setAttribute('aria-label', `Quitar ${valorFinal}`);
        }
        tagInput.dispatchEvent(new CustomEvent('tags:change', { bubbles: true }));
    };

    input.addEventListener('keydown', (event) => {
        // En edición, espacio forma parte del nombre; solo Enter confirma
        if (event.key === 'Enter') {
            event.preventDefault();
            event.stopPropagation();
            finalizar(true);
            return;
        }
        if (event.key === 'Escape') {
            event.preventDefault();
            event.stopPropagation();
            input.value = valorOriginal;
            finalizar(true);
            return;
        }
        event.stopPropagation();
    });

    input.addEventListener('blur', () => finalizar(true));
    input.addEventListener('click', (event) => event.stopPropagation());
    input.addEventListener('mousedown', (event) => event.stopPropagation());

    requestAnimationFrame(() => {
        chip.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
        input.focus();
        input.select();
    });
}

function agregarNombreAlTagInput(tagInput, nombre) {
    const limpio = (nombre || '').trim();
    if (!limpio) return false;

    const existentes = nombresExistentesEnTagInput(tagInput);
    if (existentes.includes(limpio.toLowerCase())) {
        return false;
    }

    const field = tagInput.querySelector('.tag-input-field');
    const readonly = tagInput.dataset.readonly === 'true';
    const chip = crearChip(limpio, readonly);
    if (field) {
        tagInput.insertBefore(chip, field);
    } else {
        tagInput.appendChild(chip);
    }
    tagInput.dispatchEvent(new CustomEvent('tags:change', { bubbles: true }));
    return true;
}

function inicializarTagInput(tagInput, onChange) {
    if (!tagInput || tagInput.dataset.ready === 'true') return;

    const readonly = tagInput.dataset.readonly === 'true';
    const field = tagInput.querySelector('.tag-input-field');
    if (!field) return;

    if (readonly) {
        tagInput.classList.add('is-readonly');
        field.disabled = true;
    }

    parsearNombres(tagInput.dataset.initial || '').forEach((nombre) => {
        agregarNombreAlTagInput(tagInput, nombre);
    });

    if (!readonly) {
        tagInput.addEventListener('click', (event) => {
            if (event.target.closest('.tag-chip')) return;
            field.focus();
        });

        field.addEventListener('keydown', (event) => {
            if (event.key === 'Enter' || event.key === ',') {
                event.preventDefault();
                if (agregarNombreAlTagInput(tagInput, field.value)) {
                    field.value = '';
                }
                return;
            }

            // Confirmación por 2 espacios:
            // - "Jean Pier" + espacio → cajita (1 espacio interno + 1 de cierre)
            // - "Wesly" + espacio + espacio → cajita (nombre simple)
            if (event.key === ' ') {
                const valorActual = field.value;

                if (!valorActual.trim()) {
                    event.preventDefault();
                    return;
                }

                const espaciosInternos = (valorActual.match(/ /g) || []).length;
                const esEspacioDeCierre =
                    valorActual.endsWith(' ') || espaciosInternos >= 1;

                if (esEspacioDeCierre) {
                    event.preventDefault();
                    if (agregarNombreAlTagInput(tagInput, valorActual)) {
                        field.value = '';
                    }
                }
                // Primer espacio sobre una sola palabra: se deja pasar
                return;
            }

            if (event.key === 'Backspace' && !field.value) {
                const chips = tagInput.querySelectorAll('.tag-chip:not(.is-editing)');
                if (chips.length) {
                    chips[chips.length - 1].remove();
                    tagInput.dispatchEvent(new CustomEvent('tags:change', { bubbles: true }));
                }
            }
        });

        field.addEventListener('blur', () => {
            if (agregarNombreAlTagInput(tagInput, field.value)) {
                field.value = '';
            }
        });
    }

    if (typeof onChange === 'function') {
        tagInput.addEventListener('tags:change', onChange);
    }

    tagInput.dataset.ready = 'true';
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

        const cantidadIngresada = contarNombres(obtenerNombresDeCampo(fila));

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

function crearFilaRolLibre(onTagsChange) {
    const tr = document.createElement('tr');
    tr.dataset.rolLibre = 'true';
    tr.innerHTML = `
        <td class="puesto-col">
            <div class="flex items-center gap-2">
                <input type="text" placeholder="Nombre del rol">
                <button type="button" class="text-xs text-red-500 hover:underline btn-quitar-rol flex-shrink-0">Quitar</button>
            </div>
        </td>
        <td>
            <div class="tag-input" data-initial="">
                <input type="text" class="tag-input-field" placeholder="Ej: Jhon Doe">
            </div>
        </td>
    `;
    tr.querySelector('.btn-quitar-rol').addEventListener('click', () => tr.remove());
    inicializarTagInput(tr.querySelector('.tag-input'), onTagsChange);
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
            roles.push({
                rol_nombre: fila.dataset.rol,
                nombres: obtenerNombresDeCampo(fila),
                es_rol_libre: false,
            });
        });
    } else {
        document.querySelectorAll('#registro-roles-container tr').forEach((fila) => {
            if (fila.dataset.rolLibre === 'true') {
                const inputNombreRol = fila.querySelector('.puesto-col input[type="text"]');
                roles.push({
                    rol_nombre: inputNombreRol ? inputNombreRol.value : '',
                    nombres: obtenerNombresDeCampo(fila),
                    es_rol_libre: true,
                });
            } else if (fila.dataset.rol) {
                roles.push({
                    rol_nombre: fila.dataset.rol,
                    nombres: obtenerNombresDeCampo(fila),
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

    const minimosDia = leerMinimosDia();
    const refrescarAlertas = () => actualizarAlertasMinimos(minimosDia);

    document.querySelectorAll('#registro-roles-container .tag-input').forEach((tagInput) => {
        inicializarTagInput(tagInput, refrescarAlertas);
    });

    document.querySelectorAll('.tabla-personal-form textarea').forEach((textarea) => {
        textarea.addEventListener('input', refrescarAlertas);
    });

    const btnAgregarRol = document.getElementById('btn-agregar-rol');
    const container = document.getElementById('registro-roles-container');
    if (btnAgregarRol && container) {
        btnAgregarRol.addEventListener('click', () => {
            container.appendChild(crearFilaRolLibre(refrescarAlertas));
        });
    }
    activarBotonesQuitarRol();

    const btnGuardar = document.getElementById('btn-guardar-registro');
    if (btnGuardar) {
        btnGuardar.addEventListener('click', guardarRegistro);
    }

    actualizarAlertasMinimos(minimosDia);
});
