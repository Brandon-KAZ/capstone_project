-- =====================================================================
-- Brandon Zalazar
-- Pregunta de negocio: ¿quiénes y qué nos generan los ingresos, y cuándo
-- vendemos más o menos, para decidir dónde enfocar campañas y stock?
-- =====================================================================


-- =====================================================================
-- 1. LIMPIEZA DE DATOS
-- =====================================================================

-- 1.1 Auditoria: medimos cuanta "suciedad" hay ANTES de analizar.
-- Si no sabemos cuantos nulos hay, no podemos juzgar cuanto sesgan los resultados
SELECT
    COUNT(*)                                          AS total_pedidos,
    COUNT(*) FILTER (WHERE precio_unitario IS NULL)   AS precios_nulos,
    COUNT(*) FILTER (WHERE fecha_pedido IS NULL)      AS fechas_nulas,
    COUNT(*) FILTER (WHERE estado = 'cancelado')      AS cancelados
FROM pedidos;

-- 1.2 Verificamos que los tipos sean los correctos (NUMERIC para dinero, DATE para fechas).
-- Con tipos erroneos (ej. texto) no podriamos sumar ni usar funciones de fecha

SELECT table_name, column_name, data_type
FROM information_schema.columns
WHERE table_name IN ('pedidos', 'productos')
  AND column_name IN ('precio_unitario', 'precio', 'fecha_pedido')
ORDER BY table_name, column_name;

-- 1.3 Vista "pedidos_limpios": todo el analisis posterior parte de aca,
-- asi la limpieza se define una sola vez y todas las consultas son consistentes.
--  * Precio nulo -> usamos el precio de lista del producto (COALESCE). Es el mejor
--    sustituto disponible: un NULL tratado como 0 regalaria el producto en las metricas
--  * Cancelados fuera: un pedido cancelado no genero ingreso real, inflaria las ventas
--  * La fecha nula no se inventa: se deja NULL y se reporta aparte en 2.2

CREATE OR REPLACE VIEW pedidos_limpios AS
SELECT
    p.pedido_id,
    p.cliente_id,
    p.producto_id,
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio)                AS precio_unitario,
    p.fecha_pedido,
    p.cantidad * COALESCE(p.precio_unitario, pr.precio)   AS monto_total
FROM pedidos p
JOIN productos pr ON pr.producto_id = p.producto_id
WHERE p.estado <> 'cancelado';

-- 1.4 Control de calidad de la vista: no debe quedar ningun precio nulo.

SELECT COUNT(*)                                          AS pedidos_validos,
       COUNT(*) FILTER (WHERE precio_unitario IS NULL)   AS precios_nulos_restantes,
       SUM(monto_total)                                  AS ingresos_totales
FROM pedidos_limpios;

-- 1.5 Control del JOIN (trampa de "explosión de filas"): la vista debe tener
-- exactamente tantas filas como pedidos no cancelados (relacion producto 1:N pedidos)

SELECT (SELECT COUNT(*) FROM pedidos WHERE estado <> 'cancelado') AS filas_esperadas,
       (SELECT COUNT(*) FROM pedidos_limpios)                     AS filas_en_vista;


-- =====================================================================
-- 2. ANALISIS
-- =====================================================================

-- 2.1 TOP 5 CLIENTES POR GASTO TOTAL  (JOIN + GROUP BY + SUM)
-- Objetivo: identificar al cliente mas valioso para priorizar atencion y fidelizacion
-- Agrupamos por cliente_id Y nombre porque dos clientes podrian llamarse igual

SELECT
    c.cliente_id,
    c.nombre,
    COUNT(*)            AS cantidad_pedidos,
    SUM(pl.monto_total) AS gasto_total
FROM pedidos_limpios pl
JOIN clientes c ON c.cliente_id = pl.cliente_id
GROUP BY c.cliente_id, c.nombre
ORDER BY gasto_total DESC
LIMIT 5;

-- 2.2 VENTAS TOTALES POR MES  (funciones de fecha + GROUP BY)
-- Objetivo: detectar estacionalidad (meses fuertes/debiles) para planificar campañas
-- TO_CHAR con 'YYYY-MM' ordena cronologicamente como texto
-- COALESCE etiqueta los pedidos sin fecha como 'Sin fecha' en lugar de ocultarlos:
-- así vemos cuanto ingreso no podemos ubicar en el tiempo (calidad de dato)

SELECT
    COALESCE(TO_CHAR(fecha_pedido, 'YYYY-MM'), 'Sin fecha') AS mes,
    COUNT(*)                                                AS pedidos,
    SUM(monto_total)                                        AS ventas
FROM pedidos_limpios
GROUP BY 1
ORDER BY 1;

-- 2.3 LOS 3 PRODUCTOS MENOS VENDIDOS  (LEFT JOIN + COALESCE)
-- Objetivo: decidir que productos liquidar, promocionar o dejar de stockear
-- Usamos LEFT JOIN desde productos: con un JOIN comun los productos SIN ventas
-- desaparecerian justo cuando son los mas importantes de detectar
-- COALESCE convierte el NULL de "sin ventas" en 0 unidades
-- El desempate por nombre hace que el resultado sea siempre el mismo

SELECT
    pr.nombre,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas
FROM productos pr
LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
GROUP BY pr.producto_id, pr.nombre, pr.categoria
ORDER BY unidades_vendidas ASC, pr.nombre
LIMIT 3;

-- 2.4 RANKING DE PRODUCTOS POR CATEGORIA CON RANK()  (CTE + Window Function)
-- Objetivo: ver que producto lidera dentro de su categoria, sin perder el detalle de fila
-- La CTE calcula primero las metricas por producto (mas legible que anidar subconsultas)
-- PARTITION BY categoria reinicia el ranking en cada categoria
-- Usamos RANK() y no ROW_NUMBER() porque queremos que los empates compartan puesto
-- (ej. dos productos con los mismos pedidos no deben "desempatarse" arbitrariamente)

WITH ventas_producto AS (
    SELECT
        pr.categoria,
        pr.nombre,
        COUNT(pl.pedido_id)                AS pedidos,
        COALESCE(SUM(pl.monto_total), 0)   AS ingresos
    FROM productos pr
    LEFT JOIN pedidos_limpios pl ON pl.producto_id = pr.producto_id
    GROUP BY pr.producto_id, pr.categoria, pr.nombre
)
SELECT
    categoria,
    nombre,
    pedidos,
    ingresos,
    RANK() OVER (PARTITION BY categoria ORDER BY pedidos DESC) AS ranking_en_categoria
FROM ventas_producto
ORDER BY categoria, ranking_en_categoria, ingresos DESC;

-- 2.5 SEGMENTACION DE CLIENTES CON CASE  (CTE + CASE + LEFT JOIN)
-- Objetivo: separar clientes leales de ocasionales para dirigir campañas distintas
-- Definimos "Leal" = 5 o mas pedidos: es el umbral que deja afuera a quien compro
-- una o dos veces por promocion. LEFT JOIN para no perder clientes sin compras

WITH resumen AS (
    SELECT cliente_id, COUNT(*) AS pedidos, SUM(monto_total) AS gasto
    FROM pedidos_limpios
    GROUP BY cliente_id
)
SELECT
    c.nombre,
    COALESCE(r.pedidos, 0) AS pedidos,
    COALESCE(r.gasto, 0)   AS gasto_total,
    CASE
        WHEN COALESCE(r.pedidos, 0) >= 5 THEN 'Leal'
        WHEN COALESCE(r.pedidos, 0) >= 2 THEN 'Ocasional'
        ELSE 'Nuevo / Inactivo'
    END AS segmento
FROM clientes c
LEFT JOIN resumen r ON r.cliente_id = c.cliente_id
ORDER BY gasto_total DESC;

-- 2.6 INGRESOS POR CATEGORIA  (JOIN + GROUP BY)
-- Objetivo: saber de que linea de negocio depende mas la empresa (riesgo de concentracion)

SELECT
    pr.categoria,
    COUNT(*)            AS pedidos,
    SUM(pl.monto_total) AS ingresos,
    ROUND(100.0 * SUM(pl.monto_total) / SUM(SUM(pl.monto_total)) OVER (), 1) AS pct_del_total
FROM pedidos_limpios pl
JOIN productos pr ON pr.producto_id = pl.producto_id
GROUP BY pr.categoria
ORDER BY ingresos DESC;