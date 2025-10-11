/**
 * Detalle Inspección System - Castillo de Chancay
 * Sistema de visualización de detalles de inspección con vista previa de imágenes
 */

// ===== INICIALIZACIÓN =====
document.addEventListener('DOMContentLoaded', function() {
    inicializarDetalleInspeccion();
});

// ===== FUNCIÓN PRINCIPAL DE INICIALIZACIÓN =====
function inicializarDetalleInspeccion() {
    try {
        // Agregar estilos para impresión
        agregarEstilosImpresion();
        
    } catch (error) {
    }
}

// ===== VISTA PREVIA DE IMÁGENES =====
function abrirVistaPrevia(src) {
    // Cerrar cualquier modal previo que pueda existir
    const existingModal = document.getElementById("modal-vista-previa");
    if (existingModal) {
        existingModal.remove();
    }
    
    // Usar función de seguridad global para validar URL
    const imageSrc = validateImageUrl(src);
    if (!imageSrc) {
        return;
    }
    

    // Variable para el event listener de escape
    let escapeHandler = null;

    // Función para cerrar modal
    function cerrarModal() {
        const modalElement = document.getElementById("modal-vista-previa");
        if (modalElement) {
            modalElement.remove();
        }
        if (escapeHandler) {
            document.removeEventListener("keydown", escapeHandler);
            escapeHandler = null;
        }
    }

    // Crear modal principal
    const modal = document.createElement("div");
    modal.id = "modal-vista-previa";
    modal.className = "fixed inset-0 bg-black bg-opacity-75 flex items-center justify-center z-50 p-4";

    // Container del modal
    const container = document.createElement("div");
    container.className = "bg-white dark:bg-gray-800 rounded-lg max-w-4xl max-h-full overflow-hidden flex flex-col";

    // Header del modal
    const header = document.createElement("div");
    header.className = "px-6 py-4 border-b border-gray-200 dark:border-gray-700 flex justify-between items-center";
    
    // Título
    const title = document.createElement("h3");
    title.className = "text-lg font-semibold text-gray-900 dark:text-gray-100";
    title.textContent = "Vista Previa";
    
    // Botón X para cerrar - crear de forma segura
    const closeXButton = document.createElement("button");
    closeXButton.className = "text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors";
    closeXButton.onclick = cerrarModal;
    closeXButton.setAttribute("aria-label", "Cerrar modal");
    
    // Crear SVG de forma segura
    const closeIcon = createSvgIcon("M6 18L18 6M6 6l12 12");
    closeXButton.appendChild(closeIcon);
    
    header.appendChild(title);
    header.appendChild(closeXButton);

    // Imagen
    const img = document.createElement("img");
    img.src = imageSrc;
    img.className = "max-w-full max-h-96 object-contain mx-auto my-4";
    img.alt = "Vista previa de imagen";
    img.onerror = function() {
        this.src = '/static/img/cropped-CASTILLO-DE-CHANCAY-32x32.png';
    };

    // Footer
    const footer = document.createElement("div");
    footer.className = "px-6 py-4 border-t border-gray-200 dark:border-gray-700 flex justify-end space-x-3";
    
    // Botón abrir en nueva pestaña
    const openButton = document.createElement("button");
    openButton.className = "px-4 py-2 bg-blue-600 dark:bg-blue-700 text-white rounded-lg hover:bg-blue-700 dark:hover:bg-blue-800 transition-colors flex items-center space-x-2";
    openButton.onclick = function() { 
        const fullUrl = new URL(imageSrc, window.location.origin);
        
        // Validar URL antes de abrir
        try {
            if (fullUrl.origin === window.location.origin) {
                window.open(fullUrl.href, '_blank', 'noopener,noreferrer');
            } else {
            }
        } catch (e) {
        }
    };
    
    // Crear icono de forma segura
    const openIcon = createSvgIcon("M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14", "w-4 h-4");
    
    const openText = document.createElement("span");
    openText.textContent = "Abrir en nueva pestaña";
    
    openButton.appendChild(openIcon);
    openButton.appendChild(openText);
    
    // Botón cerrar
    const closeButton = document.createElement("button");
    closeButton.className = "px-4 py-2 bg-gray-600 dark:bg-gray-700 text-white rounded-lg hover:bg-gray-700 dark:hover:bg-gray-800 transition-colors";
    closeButton.onclick = cerrarModal;
    closeButton.textContent = "Cerrar";
    
    footer.appendChild(openButton);
    footer.appendChild(closeButton);

    // Ensamblar modal
    container.appendChild(header);
    container.appendChild(img);
    container.appendChild(footer);
    modal.appendChild(container);
    document.body.appendChild(modal);

    // Event listeners seguros
    escapeHandler = (e) => {
        if (e.key === "Escape") {
            e.preventDefault();
            cerrarModal();
        }
    };
    document.addEventListener("keydown", escapeHandler);
    
    // Cerrar al hacer clic fuera del modal
    modal.addEventListener('click', function(e) {
        if (e.target === modal) {
            cerrarModal();
        }
    });

}

// ===== ESTILOS PARA IMPRESIÓN =====
function agregarEstilosImpresion() {
    const printStyles = document.createElement("style");
    printStyles.textContent = `
    @media print {
        body { font-size: 12px; }
        .no-print { display: none !important; }
        .bg-gray-50 { background: white !important; }
        .shadow-md { box-shadow: none !important; border: 1px solid #ccc; }
        .badge { border: 1px solid #ccc; padding: 2px 4px; }
        .break-inside-avoid { break-inside: avoid; }
        .items-container > div { break-inside: avoid; margin-bottom: 20px; }
    }
    `;
    document.head.appendChild(printStyles);
}

// ===== UTILIDADES GLOBALES =====
window.DetalleInspeccion = {
    abrirVistaPrevia,
    sanitizeUrl,
    createSvgIcon
};
