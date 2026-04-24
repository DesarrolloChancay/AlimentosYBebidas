/**
 * Persistencia temporal de formularios de inspeccion.
 *
 * Se conserva el nombre FormCookieManager por compatibilidad con el resto del
 * sistema, pero ya no guarda estado grande en cookies. Las cookies viajan en
 * cada request y pueden romper Nginx/Gunicorn con "Request Header Fields Too
 * Large"; por eso el estado temporal queda en sessionStorage.
 */

class FormCookieManager {
    constructor() {
        this.cookieName = 'inspeccion_form_data';
        this.storagePrefix = 'inspeccion_form_data_';
        this.expirationDays = 7;
    }

    saveFormData(establecimientoId, data) {
        try {
            const formData = {
                establecimiento_id: establecimientoId,
                items: data.items || {},
                evidencias: data.evidencias || [],
                observaciones: data.observaciones || '',
                resumen: data.resumen || {},
                timestamp: Date.now()
            };

            sessionStorage.setItem(
                this.getStorageKey(establecimientoId),
                JSON.stringify(formData)
            );
            this.clearLegacyCookie(establecimientoId);
            return true;
        } catch (error) {
            return false;
        }
    }

    loadFormData(establecimientoId) {
        try {
            const key = this.getStorageKey(establecimientoId);
            const storedData = sessionStorage.getItem(key);
            if (storedData) {
                const parsedData = JSON.parse(storedData);
                if (this.isExpired(parsedData)) {
                    this.clearFormData(establecimientoId);
                    return null;
                }
                return parsedData;
            }

            const legacyData = this.loadLegacyCookie(establecimientoId);
            if (legacyData && !this.isExpired(legacyData)) {
                sessionStorage.setItem(key, JSON.stringify(legacyData));
                this.clearLegacyCookie(establecimientoId);
                return legacyData;
            }

            this.clearLegacyCookie(establecimientoId);
            return null;
        } catch (error) {
            this.clearFormData(establecimientoId);
            return null;
        }
    }

    clearFormData(establecimientoId) {
        try {
            sessionStorage.removeItem(this.getStorageKey(establecimientoId));
            this.clearLegacyCookie(establecimientoId);
            return true;
        } catch (error) {
            return false;
        }
    }

    hasFormData(establecimientoId) {
        const data = this.loadFormData(establecimientoId);
        return data !== null && Object.keys(data.items || {}).length > 0;
    }

    getSavedEstablecimientos() {
        try {
            const ids = new Set();

            for (let index = 0; index < sessionStorage.length; index += 1) {
                const key = sessionStorage.key(index);
                if (key && key.startsWith(this.storagePrefix)) {
                    const id = Number(key.replace(this.storagePrefix, ''));
                    if (Number.isInteger(id)) ids.add(id);
                }
            }

            document.cookie.split(';').forEach(cookie => {
                const [rawName] = cookie.trim().split('=');
                if (rawName && rawName.startsWith(this.cookieName + '_')) {
                    const id = Number(rawName.replace(this.cookieName + '_', ''));
                    if (Number.isInteger(id)) ids.add(id);
                }
            });

            return Array.from(ids);
        } catch (error) {
            return [];
        }
    }

    clearAllFormData() {
        try {
            this.getSavedEstablecimientos().forEach(id => this.clearFormData(id));
            return true;
        } catch (error) {
            return false;
        }
    }

    cleanupOldCookies() {
        try {
            let cleaned = 0;

            this.getSavedEstablecimientos().forEach(id => {
                const data = this.loadFormData(id);
                if (!data || this.isExpired(data)) {
                    this.clearFormData(id);
                    cleaned += 1;
                } else {
                    this.clearLegacyCookie(id);
                }
            });

            return cleaned;
        } catch (error) {
            return 0;
        }
    }

    getCookieSize(establecimientoId) {
        try {
            const data = this.loadFormData(establecimientoId);
            return data ? JSON.stringify(data).length : 0;
        } catch (error) {
            return 0;
        }
    }

    getStorageKey(establecimientoId) {
        return `${this.storagePrefix}${establecimientoId}`;
    }

    isExpired(data) {
        if (!data || !data.timestamp) return true;
        const maxAge = this.expirationDays * 24 * 60 * 60 * 1000;
        return Date.now() - Number(data.timestamp) > maxAge;
    }

    loadLegacyCookie(establecimientoId) {
        const legacyName = `${this.cookieName}_${establecimientoId}`;
        const cookies = document.cookie.split(';');

        for (const cookie of cookies) {
            const [name, value] = cookie.trim().split('=');
            if (name === legacyName && value) {
                try {
                    const decodedData = decodeURIComponent(escape(atob(value)));
                    return JSON.parse(decodedData);
                } catch (error) {
                    return null;
                }
            }
        }

        return null;
    }

    clearLegacyCookie(establecimientoId) {
        const legacyName = `${this.cookieName}_${establecimientoId}`;
        document.cookie = `${legacyName}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/`;
        document.cookie = `${legacyName}=; max-age=0; path=/; samesite=strict`;
    }
}

window.formCookieManager = new FormCookieManager();

function createToastIcon() {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('class', 'w-5 h-5');
    svg.setAttribute('fill', 'none');
    svg.setAttribute('stroke', 'currentColor');
    svg.setAttribute('viewBox', '0 0 24 24');

    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('stroke-linecap', 'round');
    path.setAttribute('stroke-linejoin', 'round');
    path.setAttribute('stroke-width', '2');
    path.setAttribute('d', 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z');
    svg.appendChild(path);
    return svg;
}

function mostrarMensajeRecuperacion() {
    const mensaje = document.createElement('div');
    mensaje.className = 'fixed top-4 right-4 bg-blue-600 text-white px-6 py-3 rounded-lg shadow-lg z-50 flex items-center space-x-3';

    const texto = document.createElement('span');
    texto.textContent = 'Datos del formulario recuperados desde la sesion anterior';

    const botonCerrar = document.createElement('button');
    botonCerrar.type = 'button';
    botonCerrar.className = 'ml-2 text-white hover:text-gray-200';
    botonCerrar.setAttribute('aria-label', 'Cerrar mensaje');
    botonCerrar.textContent = 'x';
    botonCerrar.addEventListener('click', () => mensaje.remove());

    mensaje.appendChild(createToastIcon());
    mensaje.appendChild(texto);
    mensaje.appendChild(botonCerrar);
    document.body.appendChild(mensaje);

    setTimeout(() => {
        if (mensaje.parentNode) mensaje.remove();
    }, 5000);
}

if (typeof window !== 'undefined') {
    window.FormCookieManager = FormCookieManager;
    window.mostrarMensajeRecuperacion = mostrarMensajeRecuperacion;
}
