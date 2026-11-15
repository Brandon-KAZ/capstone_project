-- =====================================================================
-- Proyecto Capstone: EDA
-- Brandon Zalazar
-- =====================================================================

DROP VIEW  IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
    cliente_id     INTEGER PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    ciudad         VARCHAR(50),
    fecha_registro DATE NOT NULL
);

CREATE TABLE productos (
    producto_id INTEGER PRIMARY KEY,
    nombre      VARCHAR(100) NOT NULL,
    categoria   VARCHAR(50)  NOT NULL,
    precio      NUMERIC(10,2) NOT NULL
);

CREATE TABLE pedidos (
    pedido_id       INTEGER PRIMARY KEY,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(cliente_id),
    producto_id     INTEGER NOT NULL REFERENCES productos(producto_id),
    cantidad        INTEGER NOT NULL,
    precio_unitario NUMERIC(10,2),
    fecha_pedido    DATE,
    estado          VARCHAR(20) NOT NULL
);

-- Datos: clientes
INSERT INTO clientes (cliente_id, nombre, email, ciudad, fecha_registro) VALUES
  (1, 'Lucía Fernández', 'lucia.fernandez@mail.com', 'Buenos Aires', '2024-11-03'),
  (2, 'Martín Gómez', 'martin.gomez@mail.com', 'Córdoba', '2024-11-15'),
  (3, 'Sofía Ramírez', 'sofia.ramirez@mail.com', 'Rosario', '2024-12-01'),
  (4, 'Julián Pérez', 'julian.perez@mail.com', 'Buenos Aires', '2024-12-10'),
  (5, 'Camila Torres', 'camila.torres@mail.com', NULL, '2024-12-20'),
  (6, 'Diego Sosa', 'diego.sosa@mail.com', 'Mendoza', '2025-01-05'),
  (7, 'Valentina Ruiz', 'valentina.ruiz@mail.com', 'Córdoba', '2025-01-18'),
  (8, 'Nicolás Díaz', 'nicolas.diaz@mail.com', 'Buenos Aires', '2025-02-02'),
  (9, 'Agustina Molina', 'agustina.molina@mail.com', NULL, '2025-02-14'),
  (10, 'Federico Castro', 'federico.castro@mail.com', 'Rosario', '2025-03-01');

-- Datos: productos
INSERT INTO productos (producto_id, nombre, categoria, precio) VALUES
  (1, 'Notebook 14"', 'Tecnología', 750.0),
  (2, 'Mouse inalámbrico', 'Tecnología', 25.5),
  (3, 'Teclado mecánico', 'Tecnología', 80.0),
  (4, 'Monitor 24"', 'Tecnología', 210.0),
  (5, 'Silla ergonómica', 'Hogar', 190.0),
  (6, 'Escritorio regulable', 'Hogar', 260.0),
  (7, 'Lámpara LED', 'Hogar', 30.0),
  (8, 'Mochila urbana', 'Accesorios', 45.0),
  (9, 'Botella térmica', 'Accesorios', 18.0),
  (10, 'Auriculares Bluetooth', 'Accesorios', 60.0);

-- Datos: pedidos
INSERT INTO pedidos (pedido_id, cliente_id, producto_id, cantidad, precio_unitario, fecha_pedido, estado) VALUES
  (1, 5, 2, 2, 25.5, '2025-06-02', 'entregado'),
  (2, 1, 8, 1, 45.0, '2025-03-19', 'entregado'),
  (3, 1, 8, 1, 45.0, '2025-01-03', 'entregado'),
  (4, 7, 6, 1, 260.0, '2025-02-03', 'cancelado'),
  (5, 8, 6, 1, 260.0, '2025-05-04', 'entregado'),
  (6, 3, 10, 3, NULL, '2025-05-02', 'entregado'),
  (7, 9, 9, 2, 18.0, '2025-01-08', 'entregado'),
  (8, 1, 8, 1, 45.0, '2025-03-14', 'entregado'),
  (9, 3, 8, 1, 45.0, NULL, 'entregado'),
  (10, 8, 10, 1, 60.0, '2025-01-19', 'entregado'),
  (11, 9, 10, 1, 60.0, '2025-03-04', 'entregado'),
  (12, 8, 2, 2, 25.5, '2025-01-20', 'entregado'),
  (13, 3, 8, 3, 45.0, '2025-05-14', 'entregado'),
  (14, 5, 8, 2, 45.0, '2025-04-12', 'entregado'),
  (15, 5, 3, 1, NULL, '2025-06-25', 'entregado'),
  (16, 3, 2, 2, 25.5, '2025-03-17', 'entregado'),
  (17, 7, 4, 3, 210.0, '2025-04-10', 'entregado'),
  (18, 9, 2, 1, 25.5, '2025-05-14', 'cancelado'),
  (19, 3, 4, 1, 210.0, '2025-04-14', 'entregado'),
  (20, 1, 10, 1, 60.0, '2025-05-19', 'entregado'),
  (21, 5, 4, 3, 210.0, '2025-03-20', 'entregado'),
  (22, 7, 9, 2, 18.0, NULL, 'entregado'),
  (23, 2, 3, 2, 80.0, '2025-06-22', 'entregado'),
  (24, 1, 2, 3, 25.5, '2025-06-10', 'entregado'),
  (25, 10, 9, 3, 18.0, '2025-04-10', 'entregado'),
  (26, 6, 10, 1, 60.0, '2025-01-15', 'entregado'),
  (27, 5, 2, 2, NULL, '2025-01-16', 'entregado'),
  (28, 1, 3, 1, 80.0, '2025-02-24', 'entregado'),
  (29, 3, 5, 1, 190.0, '2025-04-03', 'entregado'),
  (30, 3, 8, 2, 45.0, '2025-05-09', 'entregado'),
  (31, 3, 6, 2, 260.0, '2025-03-23', 'entregado'),
  (32, 6, 4, 3, 210.0, '2025-04-08', 'entregado'),
  (33, 3, 2, 1, NULL, '2025-02-08', 'entregado'),
  (34, 10, 3, 1, 80.0, '2025-04-27', 'entregado'),
  (35, 9, 2, 1, 25.5, '2025-03-01', 'entregado'),
  (36, 3, 6, 2, 260.0, '2025-03-20', 'cancelado'),
  (37, 9, 4, 1, 210.0, '2025-06-28', 'entregado'),
  (38, 7, 10, 3, 60.0, '2025-06-24', 'entregado'),
  (39, 1, 8, 3, 45.0, '2025-05-13', 'entregado'),
  (40, 6, 5, 1, 190.0, '2025-01-16', 'entregado');