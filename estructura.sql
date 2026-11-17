-- =====================================================================
-- Proyecto Capstone: EDA
-- Brandon Zalazar
-- =====================================================================

DROP VIEW  IF EXISTS pedidos_limpios;
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS proveedores;
DROP TABLE IF EXISTS categorias;
DROP TABLE IF EXISTS clientes;

CREATE TABLE categorias (
    categoria_id INTEGER PRIMARY KEY,
    nombre       VARCHAR(50) NOT NULL
);

CREATE TABLE proveedores (
    proveedor_id INTEGER PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    pais         VARCHAR(50)  NOT NULL
);

CREATE TABLE clientes (
    cliente_id     INTEGER PRIMARY KEY,
    nombre         VARCHAR(100) NOT NULL,
    email          VARCHAR(100) NOT NULL,
    ciudad         VARCHAR(50),                -- puede venir vacía
    fecha_registro DATE NOT NULL
);

CREATE TABLE productos (
    producto_id  INTEGER PRIMARY KEY,
    nombre       VARCHAR(100) NOT NULL,
    categoria_id INTEGER NOT NULL REFERENCES categorias(categoria_id),
    proveedor_id INTEGER NOT NULL REFERENCES proveedores(proveedor_id),
    precio       NUMERIC(10,2) NOT NULL
);

CREATE TABLE pedidos (
    pedido_id    INTEGER PRIMARY KEY,
    cliente_id   INTEGER NOT NULL REFERENCES clientes(cliente_id),
    fecha_pedido DATE,
    estado       VARCHAR(20) NOT NULL
);

CREATE TABLE detalle_pedidos (
    detalle_id      INTEGER PRIMARY KEY,
    pedido_id       INTEGER NOT NULL REFERENCES pedidos(pedido_id),
    producto_id     INTEGER NOT NULL REFERENCES productos(producto_id),
    cantidad        INTEGER NOT NULL,
    precio_unitario NUMERIC(10,2)
);

-- Datos
INSERT INTO categorias (categoria_id, nombre) VALUES
  (1, 'Tecnología'),
  (2, 'Hogar'),
  (3, 'Accesorios');

INSERT INTO proveedores (proveedor_id, nombre, pais) VALUES
  (1, 'TecnoMundo S.A.', 'China'),
  (2, 'HogarPlus', 'Argentina'),
  (3, 'AccesoriosSur', 'Argentina'),
  (4, 'Digital Global', 'Estados Unidos');

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

INSERT INTO productos (producto_id, nombre, categoria_id, proveedor_id, precio) VALUES
  (1, 'Notebook 14"', 1, 4, 750.0),
  (2, 'Mouse inalámbrico', 1, 1, 25.5),
  (3, 'Teclado mecánico', 1, 1, 80.0),
  (4, 'Monitor 24"', 1, 4, 210.0),
  (5, 'Silla ergonómica', 2, 2, 190.0),
  (6, 'Escritorio regulable', 2, 2, 260.0),
  (7, 'Lámpara LED', 2, 2, 30.0),
  (8, 'Mochila urbana', 3, 3, 45.0),
  (9, 'Botella térmica', 3, 3, 18.0),
  (10, 'Auriculares Bluetooth', 3, 1, 60.0);

INSERT INTO pedidos (pedido_id, cliente_id, fecha_pedido, estado) VALUES
  (1, 7, '2025-05-28', 'entregado'),
  (2, 7, '2025-04-21', 'entregado'),
  (3, 10, '2025-01-20', 'entregado'),
  (4, 9, '2025-01-27', 'entregado'),
  (5, 7, '2025-03-15', 'cancelado'),
  (6, 10, '2025-01-15', 'entregado'),
  (7, 5, '2025-02-17', 'entregado'),
  (8, 6, NULL, 'entregado'),
  (9, 3, '2025-02-02', 'entregado'),
  (10, 10, '2025-02-25', 'entregado'),
  (11, 1, '2025-04-25', 'entregado'),
  (12, 2, '2025-01-02', 'entregado'),
  (13, 7, '2025-05-07', 'entregado'),
  (14, 6, '2025-01-13', 'cancelado'),
  (15, 5, '2025-01-07', 'entregado'),
  (16, 10, '2025-05-04', 'entregado'),
  (17, 7, '2025-03-01', 'entregado'),
  (18, 9, '2025-06-08', 'entregado'),
  (19, 5, '2025-05-15', 'entregado'),
  (20, 9, '2025-02-28', 'entregado'),
  (21, 3, NULL, 'entregado'),
  (22, 3, '2025-06-13', 'entregado'),
  (23, 2, '2025-01-02', 'entregado'),
  (24, 7, '2025-02-24', 'entregado'),
  (25, 7, '2025-05-21', 'cancelado'),
  (26, 1, '2025-03-14', 'entregado'),
  (27, 5, '2025-03-17', 'entregado'),
  (28, 9, '2025-02-19', 'entregado'),
  (29, 5, '2025-06-10', 'entregado'),
  (30, 10, '2025-01-16', 'entregado');

INSERT INTO detalle_pedidos (detalle_id, pedido_id, producto_id, cantidad, precio_unitario) VALUES
  (1, 1, 8, 1, 45.0),
  (2, 1, 9, 1, 18.0),
  (3, 2, 2, 1, NULL),
  (4, 2, 8, 1, 45.0),
  (5, 2, 4, 3, 210.0),
  (6, 3, 8, 3, 45.0),
  (7, 3, 10, 1, 60.0),
  (8, 4, 2, 1, 25.5),
  (9, 4, 1, 2, 750.0),
  (10, 4, 3, 1, 80.0),
  (11, 5, 3, 2, NULL),
  (12, 5, 8, 2, 45.0),
  (13, 5, 10, 1, 60.0),
  (14, 6, 6, 1, 260.0),
  (15, 6, 8, 2, 45.0),
  (16, 7, 1, 2, 750.0),
  (17, 7, 2, 1, 25.5),
  (18, 8, 5, 1, 190.0),
  (19, 8, 2, 1, NULL),
  (20, 9, 5, 1, 190.0),
  (21, 9, 6, 2, 260.0),
  (22, 10, 4, 2, 210.0),
  (23, 10, 2, 2, 25.5),
  (24, 11, 2, 1, 25.5),
  (25, 12, 8, 3, 45.0),
  (26, 12, 2, 1, 25.5),
  (27, 13, 6, 2, 260.0),
  (28, 14, 3, 2, 80.0),
  (29, 14, 1, 2, 750.0),
  (30, 15, 5, 2, NULL),
  (31, 16, 2, 1, 25.5),
  (32, 17, 4, 1, 210.0),
  (33, 17, 5, 1, 190.0),
  (34, 17, 2, 1, 25.5),
  (35, 18, 10, 2, 60.0),
  (36, 19, 9, 2, 18.0),
  (37, 20, 2, 1, 25.5),
  (38, 20, 10, 2, 60.0),
  (39, 21, 2, 3, 25.5),
  (40, 22, 10, 2, 60.0),
  (41, 22, 2, 1, 25.5),
  (42, 23, 3, 3, 80.0),
  (43, 23, 5, 1, 190.0),
  (44, 23, 6, 1, 260.0),
  (45, 24, 2, 1, 25.5),
  (46, 25, 10, 1, 60.0),
  (47, 25, 2, 1, 25.5),
  (48, 25, 3, 1, 80.0),
  (49, 26, 3, 1, 80.0),
  (50, 26, 2, 1, 25.5),
  (51, 27, 2, 2, 25.5),
  (52, 27, 5, 2, 190.0),
  (53, 27, 8, 3, 45.0),
  (54, 28, 1, 1, 750.0),
  (55, 29, 1, 2, 750.0),
  (56, 30, 4, 2, 210.0);
