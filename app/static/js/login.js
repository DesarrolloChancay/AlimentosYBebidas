/**
 * Login System - Castillo de Chancay
 * Sistema de autenticación con manejo de sesiones duplicadas
 */

document.addEventListener('DOMContentLoaded', function() {
    inicializarLogin();
});

function inicializarLogin() {
    const form = document.getElementById('login-form');
    if (!form) {
        return;
    }

    form.addEventListener('submit', manejarLogin);
}

async function manejarLogin(e) {
    e.preventDefault();

    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    const errorDiv = document.getElementById('error-message');

    errorDiv.classList.add('hidden');

    try {
        const response = await fetch('/api/auth/login', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password })
        });

        const data = await response.json();

        if (data.success) {
            if (data.cambiar_contrasena) {
                window.location.href = '/cambiar-contrasena';
                return;
            }

            if (data.user && data.user.rol === 'Jefe de Establecimiento') {
                window.location.href = '/jefe/dashboard';
            } else {
                window.location.href = '/';
            }
        } else {
            if (data.codigo === 'SESION_DUPLICADA') {
                mostrarDialogoSesionDuplicada(username, password);
            } else if (data.codigo === 'ENCARGADO_DESHABILITADO') {
                mostrarDialogoEncargadoDeshabilitado(data);
            } else {
                mostrarError(data.error || 'Error al iniciar sesión');
            }
        }
    } catch (error) {
        mostrarError('Error de conexión. Verifique su internet e intente nuevamente.');
    }
}

function mostrarDialogoSesionDuplicada(username, password) {
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center';
    modal.innerHTML = `
        <div class="bg-white dark:bg-slate-800 rounded-lg p-6 max-w-md mx-4">
            <h3 class="text-lg font-semibold text-orange-600 mb-4">Sesión Activa Detectada</h3>
            <p class="text-slate-700 dark:text-slate-300 mb-6">
                Ya existe una sesión activa para este usuario. ¿Desea cerrar la sesión anterior e iniciar una nueva?
            </p>
            <div class="flex space-x-3">
                <button id="btn-forzar-login" class="flex-1 px-4 py-2 bg-orange-600 text-white rounded-lg hover:bg-orange-700 transition-colors">
                    Cerrar Sesión Anterior
                </button>
                <button id="btn-cancelar-login" class="flex-1 px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors">
                    Cancelar
                </button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    document.getElementById('btn-forzar-login').onclick = () => forzarLogin(username, password, modal);
    document.getElementById('btn-cancelar-login').onclick = () => cerrarModal(modal);

    document.addEventListener('keydown', function onEscape(e) {
        if (e.key === 'Escape') {
            cerrarModal(modal);
            document.removeEventListener('keydown', onEscape);
        }
    });
}

function mostrarDialogoEncargadoDeshabilitado(data) {
    const modal = document.createElement('div');
    modal.className = 'fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center';
    modal.innerHTML = `
        <div class="bg-white dark:bg-slate-800 rounded-lg p-6 max-w-md mx-4">
            <div class="flex items-center mb-4">
                <div class="flex-shrink-0 w-10 h-10 bg-red-100 dark:bg-red-900 rounded-full flex items-center justify-center">
                    <svg class="w-5 h-5 text-red-600 dark:text-red-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z"></path>
                    </svg>
                </div>
                <h3 class="ml-3 text-lg font-semibold text-red-600 dark:text-red-400">Cuenta Deshabilitada</h3>
            </div>
            <div class="mb-6">
                <p class="text-slate-700 dark:text-slate-300 mb-4">
                    ${data.error}
                </p>
                ${data.jefe_contacto ? `
                <div class="bg-blue-50 dark:bg-blue-900 p-4 rounded-lg">
                    <h4 class="font-semibold text-blue-800 dark:text-blue-200 mb-2">Contacte a su jefe:</h4>
                    <div class="text-sm text-blue-700 dark:text-blue-300">
                        <p><strong>Nombre:</strong> ${data.jefe_contacto.nombre}</p>
                        <p><strong>Teléfono:</strong> ${data.jefe_contacto.telefono}</p>
                        <p><strong>Establecimiento:</strong> ${data.jefe_contacto.establecimiento}</p>
                    </div>
                </div>
                ` : ''}
            </div>
            <div class="flex justify-end">
                <button id="btn-cerrar-deshabilitado" class="px-4 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors">
                    Cerrar
                </button>
            </div>
        </div>
    `;

    document.body.appendChild(modal);

    document.getElementById('btn-cerrar-deshabilitado').onclick = () => cerrarModal(modal);

    document.addEventListener('keydown', function onEscape(e) {
        if (e.key === 'Escape') {
            cerrarModal(modal);
            document.removeEventListener('keydown', onEscape);
        }
    });
}

async function forzarLogin(username, password, modal) {
    try {
        const response = await fetch('/api/auth/login-forzado', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ username, password, force: true })
        });

        const data = await response.json();

        if (data.success) {
            if (data.cambiar_contrasena) {
                window.location.href = '/cambiar-contrasena';
                return;
            }

            if (data.user && data.user.rol === 'Jefe de Establecimiento') {
                window.location.href = '/jefe/dashboard';
            } else {
                window.location.href = '/';
            }
        } else {
            cerrarModal(modal);

            if (data.codigo === 'ENCARGADO_DESHABILITADO') {
                mostrarDialogoEncargadoDeshabilitado(data);
            } else {
                mostrarError(data.error || 'Error al forzar login');
            }
        }
    } catch (error) {
        cerrarModal(modal);
        mostrarError('Error de conexión al forzar login');
    }
}

function mostrarError(mensaje) {
    const errorDiv = document.getElementById('error-message');
    if (errorDiv) {
        errorDiv.textContent = mensaje;
        errorDiv.classList.remove('hidden');
    }
}

function cerrarModal(modal) {
    if (modal && modal.parentNode) {
        modal.parentNode.removeChild(modal);
    }
}

window.LoginSystem = {
    mostrarError,
    cerrarModal
};
