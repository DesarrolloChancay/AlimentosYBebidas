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

    static setToken(token) {
        if (!token) return;

        let metaToken = document.querySelector(`meta[name="${SECURITY_CONFIG.CSRF_TOKEN_META}"]`);
        if (!metaToken) {
            metaToken = document.createElement('meta');
            metaToken.setAttribute('name', SECURITY_CONFIG.CSRF_TOKEN_META);
            document.head.appendChild(metaToken);
        }

        metaToken.setAttribute('content', token);
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

    static async refreshToken(forceRefresh = true) {
        if (!NATIVE_FETCH) {
            this.lastRefreshStatus = null;
            return null;
        }

        const suffix = forceRefresh ? '?refresh=1' : '';
        const response = await NATIVE_FETCH(`/api/auth/csrf-token${suffix}`, {
            method: 'GET',
            credentials: 'same-origin',
            cache: 'no-store',
            headers: {
                'X-Requested-With': 'XMLHttpRequest'
            }
        });

        this.lastRefreshStatus = response.status;

        if (!response.ok) {
            return null;
        }

        const data = await response.json().catch(() => ({}));
        if (!data || !data.csrf_token) {
            return null;
        }

        this.setToken(data.csrf_token);
        return data.csrf_token;
    }
}

// ===== FETCH SEGURO CENTRALIZADO =====
const NATIVE_FETCH = window.fetch ? window.fetch.bind(window) : null;
const SAFE_HTTP_METHODS = new Set(['GET', 'HEAD', 'OPTIONS', 'TRACE']);
let isRedirectingToLogin = false;
let isRecoveringFromCsrf = false;
CSRFManager.lastRefreshStatus = null;

function isSameOriginRequest(input) {
    try {
        const rawUrl = input instanceof Request ? input.url : String(input);
        const url = new URL(rawUrl, window.location.origin);
        return url.origin === window.location.origin;
    } catch (error) {
        return true;
    }
}

function mergeHeaders(input, options) {
    const headers = new Headers(input instanceof Request ? input.headers : undefined);
    const optionHeaders = new Headers(options.headers || {});
    optionHeaders.forEach((value, key) => headers.set(key, value));
    return headers;
}

function isLoginUrl(url) {
    try {
        const parsed = new URL(url, window.location.origin);
        return parsed.origin === window.location.origin && parsed.pathname === '/login';
    } catch (error) {
        return false;
    }
}

function redirectToLogin(reason = 'session-expired') {
    if (isRedirectingToLogin || isLoginUrl(window.location.href)) {
        return;
    }

    isRedirectingToLogin = true;

    try {
        sessionStorage.setItem('auth_redirect_reason', reason);
    } catch (error) {
    }

    window.location.replace('/login');
}

function notifyUserSecurityRecovery(message, type = 'warning') {
    if (typeof window.mostrarNotificacion === 'function') {
        window.mostrarNotificacion(message, type);
        return;
    }

    if (typeof window.notificarEvidencias === 'function') {
        window.notificarEvidencias(message, type);
        return;
    }

    if (type === 'error' || type === 'warning') {
        alert(message);
    }
}

async function isCsrfFailureResponse(response) {
    if (!response || response.status !== 403) {
        return false;
    }

    const errorData = await response.clone().json().catch(() => null);
    return Boolean(
        errorData &&
        typeof errorData.error === 'string' &&
        errorData.error.toLowerCase().includes('csrf')
    );
}

function recoverFromCsrfFailure(reason = 'csrf-expired') {
    if (isRecoveringFromCsrf || isLoginUrl(window.location.href)) {
        return;
    }

    isRecoveringFromCsrf = true;

    try {
        sessionStorage.setItem('auth_redirect_reason', reason);
    } catch (error) {
    }

    window.dispatchEvent(new CustomEvent('secure-fetch-csrf-error', {
        detail: { reason }
    }));

    notifyUserSecurityRecovery(
        'La validación de seguridad expiró. La página se recargará para continuar.',
        'warning'
    );

    window.setTimeout(() => {
        window.location.reload();
    }, 1200);
}

async function secureFetch(input, options = {}) {
    if (!NATIVE_FETCH) {
        throw new Error('Fetch no está disponible en este navegador.');
    }

    const method = String(
        options.method || (input instanceof Request ? input.method : 'GET')
    ).toUpperCase();
    const headers = mergeHeaders(input, options);

    if (!SAFE_HTTP_METHODS.has(method) && isSameOriginRequest(input)) {
        const token = CSRFManager.getToken();
        if (token && !headers.has(SECURITY_CONFIG.CSRF_TOKEN_HEADER)) {
            headers.set(SECURITY_CONFIG.CSRF_TOKEN_HEADER, token);
        }
    }

    const requestOptions = {
        ...options,
        credentials: options.credentials || 'same-origin',
        headers
    };
    let response = await NATIVE_FETCH(input, requestOptions);

    if (
        response.status === 403 &&
        !SAFE_HTTP_METHODS.has(method) &&
        isSameOriginRequest(input) &&
        !options._csrfRetried
    ) {
        if (await isCsrfFailureResponse(response)) {
            const newToken = await CSRFManager.refreshToken(true);
            if (newToken) {
                const retryHeaders = mergeHeaders(input, requestOptions);
                retryHeaders.set(SECURITY_CONFIG.CSRF_TOKEN_HEADER, newToken);
                response = await NATIVE_FETCH(input, {
                    ...requestOptions,
                    _csrfRetried: true,
                    headers: retryHeaders
                });
            } else if (CSRFManager.lastRefreshStatus === 401) {
                redirectToLogin('session-expired');
                return response;
            } else {
                recoverFromCsrfFailure('csrf-expired');
                return response;
            }
        }
    }

    if (
        response.status === 403 &&
        !SAFE_HTTP_METHODS.has(method) &&
        isSameOriginRequest(input) &&
        options._csrfRetried &&
        await isCsrfFailureResponse(response)
    ) {
        recoverFromCsrfFailure('csrf-retry-failed');
        return response;
    }

    if (response.redirected && isLoginUrl(response.url)) {
        window.dispatchEvent(new CustomEvent('secure-fetch-auth-error', {
            detail: { status: 401, url: response.url, redirected: true }
        }));
        redirectToLogin('session-expired');
        return response;
    }

    if (response.status === 401 || response.status === 403) {
        window.dispatchEvent(new CustomEvent('secure-fetch-auth-error', {
            detail: { status: response.status, url: response.url }
        }));

        if (response.status === 401) {
            redirectToLogin('session-expired');
        }
    }

    return response;
}

if (NATIVE_FETCH) {
    window.fetch = secureFetch;
    window.addEventListener('pageshow', () => {
        CSRFManager.refreshToken(false).catch(() => null);
    });
}

document.addEventListener('submit', (event) => {
    if (event.target instanceof HTMLFormElement) {
        CSRFManager.addTokenToForm(event.target);
    }
}, true);

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
                const response = await this.secureRequest('/api/auth/verificar-timeout', {
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
        redirectToLogin('session-timeout');
    }
    
    static handleSessionInvalid() {
        redirectToLogin('session-invalid');
    }
    
    static async secureRequest(url, options = {}) {
        const headers = CSRFManager.addTokenToHeaders(options.headers || {});
        headers['Content-Type'] = headers['Content-Type'] || 'application/json';
        headers['X-Session-Fingerprint'] = this.fingerprint;
        
        return secureFetch(url, { ...options, headers });
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
                cleanUrl = `/evidencias/${evidenciasRest}`;
            } else {
                cleanUrl = `/${trimmed}`;
            }
        } else if (trimmed.startsWith('evidencias')) {
            const evidenciasRest = trimmed.slice('evidencias'.length).replace(/^\/+/, '');
            cleanUrl = `/evidencias/${evidenciasRest}`;
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
    const allowedTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/avif'];
    if (!allowedTypes.includes(file.type)) {
        return { valid: false, error: 'Tipo de archivo no permitido' };
    }
    
    // Validar tamaño (máximo 10MB)
    const maxSize = 10 * 1024 * 1024;
    if (file.size > maxSize) {
        return { valid: false, error: 'Archivo demasiado grande (máximo 10MB)' };
    }
    
    // Validar extensión del nombre
    const allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.avif'];
    const fileExtension = file.name.toLowerCase().split('.').pop();
    if (!allowedExtensions.includes('.' + fileExtension)) {
        return { valid: false, error: 'Extensión de archivo no permitida' };
    }
    
    return { valid: true };
}

// Exportar funciones para uso global
if (typeof window !== 'undefined') {
    window.CSRFManager = CSRFManager;
    window.SessionManager = SessionManager;
    window.secureFetch = secureFetch;
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
