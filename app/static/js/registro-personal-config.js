document.addEventListener('DOMContentLoaded', function () {
    var selectEstablecimiento = document.getElementById('config-establecimiento');
    if (selectEstablecimiento) {
        selectEstablecimiento.addEventListener('change', function () {
            if (this.value) {
                window.location.href = '/registro-personal/configuracion?establecimiento_id=' + this.value;
            }
        });
    }

    var btnGuardar = document.getElementById('btn-guardar-configuracion');
    if (btnGuardar) {
        btnGuardar.addEventListener('click', guardarConfiguracionMinimos);
    }
});

function guardarConfiguracionMinimos() {
    var establecimientoId = document.getElementById('config-establecimiento').value;
    if (!establecimientoId) {
        mostrarNotificacion('Selecciona un establecimiento primero', 'error');
        return;
    }

    var filas = [];
    document.querySelectorAll('.fila-minimo').forEach(function (input) {
        var rol = input.dataset.rol;
        var dia = parseInt(input.dataset.dia, 10);
        var checkboxOpcional = document.querySelector(
            '.check-opcional[data-rol="' + rol + '"][data-dia="' + dia + '"]'
        );
        filas.push({
            rol_nombre: rol,
            dia_semana: dia,
            cantidad_minima: parseInt(input.value, 10) || 0,
            opcional: checkboxOpcional ? checkboxOpcional.checked : false,
        });
    });

    fetch('/registro-personal/configuracion/guardar', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ establecimiento_id: establecimientoId, filas: filas }),
    })
        .then(function (res) { return res.json(); })
        .then(function (data) {
            if (data.success) {
                mostrarNotificacion('Configuración guardada', 'success');
            } else {
                mostrarNotificacion(data.error || 'Error al guardar', 'error');
            }
        })
        .catch(function () {
            mostrarNotificacion('Error de conexión', 'error');
        });
}
