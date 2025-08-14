-- Estructura base para el sistema de evaluación sanitaria

CREATE DATABASE IF NOT EXISTS alimentosybebidas;
USE alimentosybebidas;

-- Tabla de roles (control centralizado de permisos)
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion TEXT
);

-- Tabla de usuarios
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100),
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol_id INT NOT NULL,
    FOREIGN KEY (rol_id) REFERENCES roles(id)
);

-- Tabla de empresas
CREATE TABLE empresas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    ruc VARCHAR(11) UNIQUE NOT NULL
);

-- Tabla de áreas
CREATE TABLE areas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    empresa_id INT NOT NULL,
    FOREIGN KEY (empresa_id) REFERENCES empresas(id)
);

-- Tabla de establecimientos
CREATE TABLE establecimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255),
    area_id INT NOT NULL,
    FOREIGN KEY (area_id) REFERENCES areas(id)
);

-- Tabla de encargados (no son usuarios)
CREATE TABLE encargados (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(15)
);

-- Encargados asignados por establecimiento y fecha (pueden variar por día)
CREATE TABLE encargados_establecimientos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    encargado_id INT NOT NULL,
    establecimiento_id INT NOT NULL,
    fecha DATE NOT NULL,
    FOREIGN KEY (encargado_id) REFERENCES encargados(id),
    FOREIGN KEY (establecimiento_id) REFERENCES establecimientos(id)
);