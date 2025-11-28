# bd.sql
CREATE DATABASE IF NOT EXISTS db_paquexpress;
USE db_paquexpress;

-- TABLAS
CREATE TABLE usuarios (
    id_usuario INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    correo VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(200) NOT NULL,
    rol ENUM('admin', 'repartidor') DEFAULT 'repartidor'
);

CREATE TABLE paquetes (
    id_paquete INT AUTO_INCREMENT PRIMARY KEY,
    descripcion VARCHAR(200) NOT NULL,
    direccion_destino VARCHAR(255) NOT NULL,
    id_repartidor INT,
    estado ENUM('pendiente', 'entregado') DEFAULT 'pendiente',
    foto_evidencia LONGTEXT,
    ubicacion VARCHAR(100),
    fecha DATETIME,
    
    FOREIGN KEY (id_repartidor) REFERENCES usuarios(id_usuario)
);


-- DATOS DE PRUEBA
-- Usuario de prueba con contraseña encriptada con md5 (Password:12345)
INSERT INTO usuarios (nombre, correo, password, rol) 
VALUES ('Pedro Perez', 'pedrop@gmail.com', '827ccb0eea8a706c4c34a16891f84e7b', 'repartidor');

-- Paquetes de prueba asignados a Juan
INSERT INTO paquetes (descripcion, direccion_destino, id_repartidor, estado) 
VALUES 
('Zapatos Nike Low Dunk Rojos', 'Av. 5 de Febrero #123, Qro', 1, 'pendiente'),
('Laptop Dell Latitude', 'Blvd. Bernardo Quintana #400, Qro', 1, 'pendiente'),
('Libro Larousse', 'Calle Madero #10, Centro', 1, 'pendiente');