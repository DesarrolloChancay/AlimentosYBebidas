/**
 * Base System - Castillo de Chancay
 * Sistema base con manejo de temas, sesiones y navegación
 */

// ===== CONFIGURACIÓN DE TEMAS =====
const THEME_KEY = 'tema';
const THEMES = {
    light: 'light',
    dark: 'dark',
    system: 'sistema'
};

// ===== GESTIÓN DE TEMAS =====
function getSystemTheme() {
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? THEMES.dark : THEMES.light;
}

function changeTheme(theme) {
    const html = document.documentElement;
    const actualTheme = theme === THEMES.system ? getSystemTheme() : theme;
    
    // Limpiar clases existentes y aplicar el nuevo tema
    html.classList.remove(THEMES.light, THEMES.dark);
    html.classList.add(actualTheme);
    
    // Guardar preferencia
    localStorage.setItem(THEME_KEY, theme);
    
    // Ocultar menú
    const menu = document.getElementById('theme-menu');
    if (menu) menu.classList.add('hidden');
    
}

// ===== INICIALIZACIÓN DE TEMAS =====
function inicializarTemas() {
    // Aplicar tema guardado o sistema por defecto
    const savedTheme = localStorage.getItem(THEME_KEY) || THEMES.system;
    changeTheme(savedTheme);
    
    // Configuración cuando el DOM esté listo
    document.addEventListener('DOMContentLoaded', function() {
        configurarControladorTemas();
        observarCambiosSistema();
    });
}

function configurarControladorTemas() {
    const toggle = document.getElementById('theme-toggle');
    const menu = document.getElementById('theme-menu');

    // Manejar clic en el botón de toggle
    if (toggle) {
        toggle.onclick = function(e) {
            e.preventDefault();
            e.stopPropagation();
            if (menu) {
                menu.classList.toggle('hidden');
            }
        };
    }

    // Cerrar menú al hacer clic fuera
    document.onclick = function(e) {
        if (menu && toggle && !menu.contains(e.target) && !toggle.contains(e.target)) {
            menu.classList.add('hidden');
        }
    };
}

function observarCambiosSistema() {
    // Observar cambios en el tema del sistema
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.onchange = function() {
        if (localStorage.getItem(THEME_KEY) === THEMES.system) {
            changeTheme(THEMES.system);
        }
    };
}

// ===== GESTIÓN DE SESIONES =====
function verificarSesionAlRetroceder() {
    // NO verificar sesión en la página de login
    if (window.location.pathname === '/login') {
        return;
    }
    
    // Verificación simple cuando se navega de vuelta
    fetch('/api/auth/verificar-sesion-unica', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        }
    }).then(response => {
        if (response.status === 401) {
            window.location.href = '/login';
        }
    }).catch(() => {
        window.location.href = '/login';
    });
}

function inicializarSesiones() {
    // Solo verificar cuando el usuario navega de vuelta a la página
    window.addEventListener('pageshow', function(event) {
        if (event.persisted && window.location.pathname !== '/login') {
            verificarSesionAlRetroceder();
        }
    });
}

// ===== GESTIÓN DE ALERTAS =====
function inicializarAlertas() {
    // Auto-cerrar alertas flash después de 5 segundos
    document.addEventListener('DOMContentLoaded', function() {
        const alerts = document.querySelectorAll('.alert-flash');
        alerts.forEach(function(alert) {
            setTimeout(function() {
                alert.style.opacity = '0';
                setTimeout(function() {
                    alert.remove();
                }, 300);
            }, 5000);
        });
        
        if (alerts.length > 0) {
        }
    });
}

// ===== CONFIGURACIÓN TAILWIND =====
function configurarTailwind() {
    if (typeof tailwind !== 'undefined') {
        tailwind.config = {
            darkMode: 'class',
            theme: {
                extend: {}
            }
        };
    }
}

// ===== INICIALIZACIÓN PRINCIPAL =====
function inicializarBase() {
    
    try {
        configurarTailwind();
        inicializarTemas();
        inicializarSesiones();
        inicializarAlertas();
        
    } catch (error) {
    }
}

// ===== EJECUTAR INICIALIZACIÓN =====
// Ejecutar inmediatamente la configuración de temas (crítico para evitar parpadeo)
inicializarTemas();

// Ejecutar el resto cuando sea seguro
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', inicializarBase);
} else {
    inicializarBase();
}

// ===== UTILIDADES GLOBALES =====
window.BaseSystem = {
    changeTheme,
    verificarSesionAlRetroceder,
    THEMES,
    THEME_KEY
};
