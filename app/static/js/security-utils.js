/**
 * Utilidades de seguridad para prevenir XSS, CSRF, Session Hijacking y otras vulnerabilidades
 * Sistema de seguridad robusto para Castillo de Chancay
 */

// ===== CONFIGURACIÓN DE SEGURIDAD =====
const SECURITY_CONFIG = {
    CSRF_TOKEN_HEADER: 'X-CSRF-Token',
    CSRF_TOKEN_META: 'csrf-token',
    SESSION_TIMEOUT: 30 * 60 * 1000, // 30 minutos
    MAX_FILE_SIZE: 10 * 1024 * 1024, // 10MB
    ALLOWED_DOMAINS: [window.location.hostname, 'localhost', '127.0.0.1'],
    API_RATE_LIMIT: 100, // requests per minute
    FINGERPRINT_CHECKS: true,
    CONTENT_SECURITY_POLICY: {
        'script-src': "'self'",
        'style-src': "'self' 'unsafe-inline'",
        'img-src': "'self' data:",
        'connect-src': "'self'",
        'font-src': "'self'",
        'object-src': "'none'",
        'media-src': "'self'",
        'frame-src': "'none'"
    },
    SENSITIVE_ENDPOINTS: ['/api/auth/', '/jefe/', '/admin/', '/api/usuarios/'],
    XSS_PATTERNS: [
        /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi,
        /javascript:/gi,
        /on\w+\s*=/gi,
        /<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)*<\/iframe>/gi,
        /<object\b[^<]*(?:(?!<\/object>)<[^<]*)*<\/object>/gi,
        /<embed\b[^<]*>/gi,
        /<link\b[^<]*>/gi,
        /<meta\b[^<]*>/gi
    ]
};

// ===== GESTIÓN DE TOKENS CSRF =====
class CSRFManager {
    static getToken() {
        // Buscar token en meta tag
        const metaToken = document.querySelector(`meta[name="${SECURITY_CONFIG.CSRF_TOKEN_META}"]`);
        if (metaToken) return metaToken.getAttribute('content');
        
        // Buscar en cookies como fallback
        const cookieToken = this.getCookie('csrf_token');
        return cookieToken;
    }
    
    static getCookie(name) {
        const value = `; ${document.cookie}`;
        const parts = value.split(`; ${name}=`);
        if (parts.length === 2) return parts.pop().split(';').shift();
        return null;
    }
    
    static addTokenToHeaders(headers = {}) {
        const token = this.getToken();
        if (token) {
            headers[SECURITY_CONFIG.CSRF_TOKEN_HEADER] = token;
        }
        return headers;
    }
    
    static addTokenToForm(form) {
        if (!form || !(form instanceof HTMLFormElement)) return;
        
        // Remover token anterior si existe
        const existingToken = form.querySelector('input[name="csrf_token"]');
        if (existingToken) existingToken.remove();
        
        // Agregar nuevo token
        const token = this.getToken();
        if (token) {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'csrf_token';
            input.value = token;
            form.appendChild(input);
        }
    }
}

// ===== GESTIÓN DE SESIONES SEGURAS =====
class SessionManager {
    static lastActivity = Date.now();
    static fingerprint = null;
    
    static init() {
        this.generateFingerprint();
        this.setupActivityTracking();
        this.setupSessionValidation();
    }
    
    static generateFingerprint() {
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        ctx.textBaseline = 'top';
        ctx.font = '14px Arial';
        ctx.fillText('Security fingerprint', 2, 2);
        
        this.fingerprint = btoa(JSON.stringify({
            userAgent: navigator.userAgent.slice(0, 100),
            language: navigator.language,
            platform: navigator.platform,
            screen: `${screen.width}x${screen.height}`,
            timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
            canvas: canvas.toDataURL().slice(0, 50)
        }));
    }
    
    static setupActivityTracking() {
        const events = ['mousedown', 'mousemove', 'keypress', 'scroll', 'touchstart'];
        
        events.forEach(event => {
            document.addEventListener(event, () => {
                this.lastActivity = Date.now();
            }, { passive: true });
        });
        
        // Verificar timeout de sesión cada minuto
        setInterval(() => {
            if (Date.now() - this.lastActivity > SECURITY_CONFIG.SESSION_TIMEOUT) {
                this.handleSessionTimeout();
            }
        }, 60000);
    }
    
    static setupSessionValidation() {
        // Validar sesión periódicamente
        setInterval(async () => {
            try {
                const response = await this.secureRequest('/api/auth/validate-session', {
                    method: 'POST',
                    body: JSON.stringify({ fingerprint: this.fingerprint })
                });
                
                if (!response.ok) {
                    this.handleSessionInvalid();
                }
            } catch (error) {
            }
        }, 5 * 60 * 1000); // Cada 5 minutos
    }
    
    static handleSessionTimeout() {
        alert('Su sesión ha expirado por inactividad. Será redirigido al login.');
        window.location.href = '/login';
    }
    
    static handleSessionInvalid() {
        alert('Su sesión ha sido invalidada por motivos de seguridad.');
        window.location.href = '/login';
    }
    
    static async secureRequest(url, options = {}) {
        const headers = CSRFManager.addTokenToHeaders(options.headers || {});
        headers['Content-Type'] = headers['Content-Type'] || 'application/json';
        headers['X-Session-Fingerprint'] = this.fingerprint;
        
        return fetch(url, { ...options, headers });
    }
}

// ===== RATE LIMITING =====
class RateLimiter {
    static requests = new Map();
    
    static isAllowed(endpoint) {
        const now = Date.now();
        const minute = Math.floor(now / 60000);
        const key = `${endpoint}_${minute}`;
        
        const count = this.requests.get(key) || 0;
        if (count >= SECURITY_CONFIG.API_RATE_LIMIT) {
            return false;
        }
        
        this.requests.set(key, count + 1);
        
        // Limpiar entradas antiguas
        for (const [mapKey] of this.requests) {
            const [, mapMinute] = mapKey.split('_');
            if (parseInt(mapMinute) < minute - 1) {
                this.requests.delete(mapKey);
            }
        }
        
        return true;
    }
}

// Función para sanitizar texto y prevenir XSS
function sanitizeText(text) {
    if (!text || typeof text !== 'string') return '';
    
    const escapeMap = {
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;',
        '&': '&amp;',
        '/': '&#x2F;',
        '`': '&#x60;',
        '=': '&#x3D;'
    };
    
    return text.replace(/[<>"'&/`=]/g, function(match) {
        return escapeMap[match];
    });
}

// Función para validar URLs de imágenes
function validateImageUrl(url) {
    if (!url || typeof url !== 'string') return null;
    
    // Whitelist de extensiones permitidas
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.avif'];
    const lowercaseUrl = url.toLowerCase();
    
    // Verificar extensión válida
    const hasValidExtension = allowedExtensions.some(ext => lowercaseUrl.includes(ext));
    if (!hasValidExtension) {
        return null;
    }
    
    // Limpiar caracteres peligrosos
    let cleanUrl = url.replace(/[<>"'`]/g, '').replace(/\\/g, "/");

    // Normalizar prefijo para rutas locales
    if (!cleanUrl.startsWith('http') && !cleanUrl.startsWith('/')) {
        cleanUrl = `/${cleanUrl.replace(/^\/+/, '')}`;
    }

    if (cleanUrl.startsWith('//')) {
        cleanUrl = `/${cleanUrl.replace(/^\/+/, '')}`;
    }

    if (!cleanUrl.startsWith('http')) {
        const trimmed = cleanUrl.replace(/^\/+/, '');

        if (trimmed.startsWith('static/')) {
            const rest = trimmed.slice('static/'.length);
            if (rest.startsWith('evidencias') && !rest.startsWith('evidencias/')) {
                const evidenciasRest = rest.slice('evidencias'.length).replace(/^\/+/, '');
                cleanUrl = `/static/evidencias/${evidenciasRest}`;
            } else {
                cleanUrl = `/${trimmed}`;
            }
        } else if (trimmed.startsWith('evidencias')) {
            const evidenciasRest = trimmed.slice('evidencias'.length).replace(/^\/+/, '');
            cleanUrl = `/static/evidencias/${evidenciasRest}`;
        }

    cleanUrl = cleanUrl.replace(/\/{2,}/g, '/');
    }
    
    // Prevenir path traversal
    if (cleanUrl.includes('..') || cleanUrl.includes('~')) {
        return null;
    }
    
    // Validar que no contenga JavaScript
    if (cleanUrl.toLowerCase().includes('javascript:') || 
        cleanUrl.toLowerCase().includes('data:text/html') ||
        cleanUrl.toLowerCase().includes('vbscript:')) {
        return null;
    }
    
    return cleanUrl;
}

// Función para crear elementos SVG de forma segura
function createSvgIcon(pathData, className = "w-6 h-6") {
    // Validar pathData para prevenir inyección de código
    if (!pathData || typeof pathData !== 'string') {
        return document.createElement('span'); // Retorna elemento vacío como fallback
    }
    
    // Lista blanca de caracteres permitidos en path SVG
    const allowedChars = /^[MmLlHhVvCcSsQqTtAaZz0-9\s\-\.,]+$/;
    if (!allowedChars.test(pathData)) {
        return document.createElement('span');
    }
    
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("class", sanitizeText(className));
    svg.setAttribute("fill", "none");
    svg.setAttribute("stroke", "currentColor");
    svg.setAttribute("viewBox", "0 0 24 24");
    
    const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
    path.setAttribute("stroke-linecap", "round");
    path.setAttribute("stroke-linejoin", "round");
    path.setAttribute("stroke-width", "2");
    path.setAttribute("d", pathData);
    
    svg.appendChild(path);
    return svg;
}

// Función para validar URLs antes de abrirlas
function validateAndOpenUrl(url, target = '_blank') {
    if (!url || typeof url !== 'string') {
        return false;
    }
    
    try {
        const fullUrl = url.startsWith('http') ? url : window.location.origin + '/' + url.replace(/^\/+/, '');
        const urlObj = new URL(fullUrl);
        
        // Solo permitir URLs del mismo origen para recursos locales
        if (!url.startsWith('http') && urlObj.origin !== window.location.origin) {
            return false;
        }
        
        // Prevenir URLs con JavaScript
        if (urlObj.protocol === 'javascript:' || urlObj.protocol === 'data:') {
            return false;
        }
        
        window.open(fullUrl, target, 'noopener,noreferrer');
        return true;
    } catch (e) {
        return false;
    }
}

// Función para crear elementos de forma segura con validación de atributos
function createSecureElement(tagName, attributes = {}, textContent = '') {
    if (!tagName || typeof tagName !== 'string') {
        return document.createElement('span');
    }
    
    // Lista blanca de tags permitidos
    const allowedTags = ['div', 'span', 'p', 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 
                        'button', 'img', 'svg', 'path', 'a', 'ul', 'li', 'ol'];
    
    if (!allowedTags.includes(tagName.toLowerCase())) {
        return document.createElement('span');
    }
    
    const element = document.createElement(tagName);
    
    // Agregar atributos de forma segura
    for (const [key, value] of Object.entries(attributes)) {
        if (typeof key === 'string' && value !== null && value !== undefined) {
            // Lista blanca de atributos permitidos
            const allowedAttributes = ['class', 'id', 'src', 'alt', 'title', 'role', 
                                     'aria-label', 'aria-hidden', 'data-*'];
            
            const isAllowed = allowedAttributes.some(attr => 
                attr === key || (attr.endsWith('*') && key.startsWith(attr.slice(0, -1))));
            
            if (isAllowed) {
                element.setAttribute(key, sanitizeText(String(value)));
            }
        }
    }
    
    // Agregar contenido de texto de forma segura
    if (textContent) {
        element.textContent = String(textContent);
    }
    
    return element;
}

// Función para limpiar contenedores de forma segura
function clearContainer(container) {
    if (!container) return;
    
    // Remover event listeners antes de limpiar
    const elements = container.querySelectorAll('*');
    elements.forEach(el => {
        el.onclick = null;
        el.onchange = null;
        el.oninput = null;
    });
    
    container.innerHTML = '';
}

// Función para validar archivos de imagen
function validateImageFile(file) {
    if (!file || !(file instanceof File)) {
        return { valid: false, error: 'Archivo inválido' };
    }
    
    // Validar tipo MIME
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
        return { valid: false, error: 'Tipo de archivo no permitido' };
    }
    
    // Validar tamaño (máximo 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
        return { valid: false, error: 'Archivo demasiado grande (máximo 10MB)' };
    }
    
    // Validar extensión del nombre
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    const fileExtension = file.name.toLowerCase().split('.').pop();
    if (!allowedExtensions.includes('.' + fileExtension)) {
        return { valid: false, error: 'Extensión de archivo no permitida' };
    }
    
    return { valid: true };
}

// Exportar funciones para uso global
if (typeof window !== 'undefined') {
    window.SecurityUtils = {
        sanitizeText,
        validateImageUrl,
        createSvgIcon,
        validateAndOpenUrl,
        createSecureElement,
        clearContainer,
        validateImageFile
    };
}
