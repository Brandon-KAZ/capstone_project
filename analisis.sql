-- =====================================================================
-- Brandon Zalazar
-- Pregunta de negocio: ¿de donde vienen los ingresos y donde conviene enfocar marketing y stock?
-- =====================================================================

-- =====================================================================
-- 1. LIMPIEZA DE DATOS
-- =====================================================================

-- 1.1 Auditoria previa: medimos cuanta suciedad hay antes de decidir como tratarla.
SELECT
    (SELECT COUNT(*) FROM pedidos)                                       AS pedidos,
    (SELECT COUNT(*) FROM pedidos WHERE fecha_pedido IS NULL)            AS fechas_nulas,
    (SELECT COUNT(*) FROM pedidos WHERE estado = 'cancelado')            AS cancelados,
    (SELECT COUNT(*) FROM detalle_pedidos)                               AS lineas_detalle,
    (SELECT COUNT(*) FROM detalle_pedidos WHERE precio_unitario IS NULL) AS precios_nulos;

-- 1.2 Verificamos tipos: con NUMERIC y DATE se puede sumar y usar funciones de fecha.
SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE (table_name, column_name) IN (('detalle_pedidos','precio_unitario'),
                                    ('productos','precio'),
                                    ('pedidos','fecha_pedido'))
ORDER BY table_name;

-- 1.3 Vista base de todo el análisis: la limpieza se define una sola vez.
--  * Precio nulo -> precio de lista (COALESCE); tratarlo como 0 regalaria el producto.
--  * Pedidos cancelados fuera: no generaron ingreso real.
--  * Fecha nula: no se inventa, se reporta aparte en 2.2.
CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    p.pedido_id,
    p.cliente_id,
    p.fecha_pedido,
    d.producto_id,
    d.cantidad,
    COALESCE(d.precio_unitario, pr.precio)              AS precio_unitario,
    d.cantidad * COALESCE(d.precio_unitario, pr.precio) AS monto_total
FROM detalle_pedidos d
JOIN pedidos   p  ON p.pedido_id    = d.pedido_id
JOIN productos pr ON pr.producto_id = d.producto_id
WHERE p.estado <> 'cancelado';

-- 1.4 Control: sin precios nulos y sin filas duplicadas por los JOINs.
SELECT
    COUNT(*)                                        AS filas_vista,
    (SELECT COUNT(*)
       FROM detalle_pedidos d
       JOIN pedidos p ON p.pedido_id = d.pedido_id
      WHERE p.estado <> 'cancelado')                AS filas_esperadas,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL) AS precios_nulos_restantes,
    SUM(monto_total)                                AS ingresos_totales
FROM pedidos_limpios;


-- =====================================================================
-- 2. ANALISIS
-- =====================================================================

-- 2.1 Top 5 clientes por gasto total.
-- Sirve para saber a quien fidelizar primero. Agrupamos tambien por cliente_id
-- porque dos clientes podrian llamarse igual. COUNT(DISTINCT) evita contar
-- varias veces un pedido con mas de un producto.
SELECT
    c.cliente_id,
    c.nombre,
    COUNT(DISTINCT pl.pedido_id) AS pedidos,
    SUM(pl.monto_total)          AS gasto_total
FROM pedidos_limpios pl
JOIN clientes c ON c.cliente_id = pl.cliente_id
GROUP BY c.cliente_id, c.nombre
ORDER BY gasto_total DESC
LIMIT 5;

-- 2.2 Ventas totales por mes.
-- Sirve para detectar estacionalidad y planificar campañas.
-- COALESCE etiqueta los pedidos sin fecha para ver cuanto ingreso no podemos ubicar en el tiempo.
SELECT
    COALESCE(TO_CHAR(fecha_pedido, 'YYYY-MM'), 'Sin fecha') AS mes,
    COUNT(DISTINCT pedido_id)                               AS pedidos,
    SUM(monto_total)                                        AS ventas
FROM pedidos_limpios
GROUP BY 1
ORDER BY 1;

-- 2.3 Los 3 productos menos vendidos.
-- LEFT JOIN desde productos: con un JOIN comun, los productos sin ventas
-- desaparecerian justo cuando mas interesa detectarlos. COALESCE los cuenta como 0.
-- El desempate por nombre hace que el resultado sea siempre el mismo.
SELECT
    pr.nombre,
    ca.nombre                     AS categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
FROM productos pr
JOIN categorias ca ON ca.categoria_id = pr.categoria_id
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre, ca.nombre
ORDER BY unidades_vendidas ASC, pr.nombre
LIMIT 3;

-- 2.4 Ranking de productos por categoría con RANK().
-- Sirve para ver qué producto lidera dentro de cada categoria sin perder el detalle por fila.
-- RANK() y no ROW_NUMBER(): si dos productos empatan en pedidos, comparten puesto.
WITH ventas_producto AS (
    SELECT
        ca.nombre                          AS categoria,
        pr.nombre                          AS producto,
        COUNT(DISTINCT pl.pedido_id)       AS pedidos,
        COALESCE(SUM(pl.monto_total), 0)   AS ingresos
    FROM productos pr
    JOIN categorias ca ON ca.categoria_id = pr.categoria_id
    LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
    GROUP BY pr.producto_id, ca.nombre, pr.nombre
)
SELECT
    categoria,
    producto,
    pedidos,
    ingresos,
    RANK() OVER (PARTITION BY categoria ORDER BY pedidos DESC) AS ranking_en_categoria
FROM ventas_producto
ORDER BY categoria, ranking_en_categoria, ingresos DESC;

-- 2.5 Segmentacion de clientes con CASE.
-- Separa clientes leales de ocasionales para dirigir campañas distintas.
-- "Leal" = 4 o más pedidos: deja afuera a quien compró solo por una promocion.
-- LEFT JOIN para no perder a los clientes que nunca compraron.
WITH resumen AS (
    SELECT cliente_id, COUNT(DISTINCT pedido_id) AS pedidos, SUM(monto_total) AS gasto
    FROM pedidos_limpios
    GROUP BY cliente_id
)
SELECT
    c.nombre,
    COALESCE(r.pedidos, 0) AS pedidos,
    COALESCE(r.gasto, 0)   AS gasto_total,
    CASE
        WHEN COALESCE(r.pedidos, 0) >= 4 THEN 'Leal'
        WHEN COALESCE(r.pedidos, 0) >= 2 THEN 'Ocasional'
        ELSE 'Nuevo / Inactivo'
    END AS segmento
FROM clientes c
LEFT JOIN resumen r ON r.cliente_id = c.cliente_id
ORDER BY gasto_total DESC;

-- 2.6 Ingresos por categoria y por proveedor.
-- Mide la dependencia del negocio: si una categoria o un proveedor concentra
-- demasiado, un problema ahi afecta a todo. La ventana SUM() OVER () calcula el
-- total general sin colapsar las filas.
SELECT
    ca.nombre            AS categoria,
    COUNT(DISTINCT pl.pedido_id) AS pedidos,
    SUM(pl.monto_total)  AS ingresos,
    ROUND(100.0 * SUM(pl.monto_total) / SUM(SUM(pl.monto_total)) OVER (), 1) AS pct_del_total
FROM pedidos_limpios pl
JOIN productos   pr ON pr.producto_id  = pl.producto_id
JOIN categorias  ca ON ca.categoria_id = pr.categoria_id
GROUP BY ca.nombre
ORDER BY ingresos DESC;

SELECT
    pv.nombre            AS proveedor,
    pv.pais,
    SUM(pl.monto_total)  AS ingresos,
    ROUND(100.0 * SUM(pl.monto_total) / SUM(SUM(pl.monto_total)) OVER (), 1) AS pct_del_total
FROM pedidos_limpios pl
JOIN productos    pr ON pr.producto_id  = pl.producto_id
JOIN proveedores  pv ON pv.proveedor_id = pr.proveedor_id
GROUP BY pv.proveedor_id, pv.nombre, pv.pais
ORDER BY ingresos DESC;