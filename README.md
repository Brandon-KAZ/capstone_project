# Capstone: Analisis Exploratorio de Datos con PostgreSQL
# Brandon Zalazar
## 1. Problema de negocio
Una tienda online de tecnologia, hogar y accesorios quiere saber **de dónde vienen sus ingresos** para decidir donde invertir en marketing y stock. Preguntas que responde este análisis:

1. ¿Que clientes generan mas ingresos y que tan concentrado esta el negocio en ellos?
2. ¿Como evolucionan las ventas mes a mes?
3. ¿Que productos casi no se venden?
4. ¿Qué producto lidera dentro de cada categoria?

## 2. Dataset
Dataset **inventado** (generado para el curso) con 3 tablas:

| Tabla | Filas | Contenido |
|---|---|---|
| `clientes` | 10 | nombre, email, ciudad, fecha de registro |
| `productos` | 10 | nombre, categoría, precio de lista |
| `pedidos` | 40 | cliente, producto, cantidad, precio, fecha, estado |

Los datos incluyen **suciedad a proposito**: 4 precios nulos, 2 fechas nulas, 3 pedidos cancelados y 2 clientes sin ciudad.

## 3. Como ejecutar el codigo
1. Abri pgAdmin o `psql` y crea la base: `CREATE DATABASE capstone_project;`
2. Conectate a `capstone_project`.
3. Ejecutá **`estructura.sql`** (crea tablas e inserta los datos; se puede re-ejecutar sin errores).
4. Ejecuta **`analisis.sql`** (limpieza + consultas). Las consultas se pueden correr de a una.

Con `psql`:
```bash
psql -U postgres -d capstone_project -f estructura.sql
psql -U postgres -d capstone_project -f analisis.sql
```

## 4. Limpieza aplicada
| Problema | Decision | Por que |
|---|---|---|
| 4 `precio_unitario` nulos | `COALESCE(precio_unitario, precio de lista)` | Un NULL como 0 "regalaría" el producto y subestimaria ingresos. |
| 3 pedidos cancelados | Se excluyen | No generaron ingreso real. |
| 2 `fecha_pedido` nulas | No se inventa; se muestran como `Sin fecha` | Asignar una fecha falsa distorsionaria la tendencia mensual. |
| 2 clientes sin ciudad | Se mantienen | No afecta las metricas principales. |

Despues de limpiar quedan **37 pedidos validos y 5.557,50 de ingresos**. Los 4 precios imputados pesan 336,50 (≈6 % del total), por lo que el impacto de esa decision es bajo.

## 5. Hallazgos principales

### Clientes: negocio concentrado
| # | Cliente | Pedidos | Gasto |
|---|---|---|---|
| 1 | Sofia Ramirez | 9 | 1.446,50 |
| 2 | Camila Torres | 5 | 902,00 |
| 3 | Diego Sosa | 3 | 880,00 |
| 4 | Valentina Ruiz | 3 | 846,00 |
| 5 | Lucia Fernandez | 7 | 486,50 |

**Interpretacion:** los 5 mejores clientes (la mitad de la base) generan **82 % de los ingresos**, y Sofía sola el 26 %. Perder a uno o dos de ellos afectaria fuerte las ventas. Ademas, Lucia hizo 7 pedidos pero gasto poco: compra productos baratos con frecuencia, mientras que Diego y Valentina gastan casi lo mismo con solo 3 pedidos (compras grandes). Son perfiles distintos y conviene tratarlos con acciones distintas (ej. *upselling* a Lucía, programa de fidelizacion para Sofia).

### Ventas por mes
| Mes | Pedidos | Ventas |
|---|---|---|
| 2025-01 | 7 | 493,00 |
| 2025-02 | 2 | 105,50 |
| 2025-03 | 7 | 1.376,50 |
| 2025-04 | 7 | 1.884,00 |
| 2025-05 | 6 | 860,00 |
| 2025-06 | 6 | 757,50 |
| Sin fecha | 2 | 81,00 |

**Interpretacion:** febrero es el mes mas debil (apenas 2 pedidos) y abril el mas fuerte (34 % de las ventas con fecha conocida), impulsado por compras de alto valor, no por mas pedidos: marzo y abril tienen los mismos 7 pedidos pero abril vendio ~37 % más. Conviene investigar que se hizo distinto en abril y reforzar febrero con promociones.

### Productos menos vendidos
| Producto | Categoria | Unidades |
|---|---|---|
| Lampara LED | Hogar | 0 |
| Notebook 14" | Tecnologia | 0 |
| Silla ergonomica | Hogar | 2 |

**Interpretacion:** dos productos del catálogo **no tuvieron ninguna venta** en el periodo; son candidatos a revisar precio, visibilidad o stock inmovilizado. La Notebook es de alto valor (750), asi que una sola venta moveria mucho los ingresos: vale la pena investigar si el problema es precio o demanda.

### Ranking por categoria (RANK)
- **Accesorios:** Mochila urbana (8 pedidos) > Auriculares (6) > Botella termica (3).
- **Tecnología:** Mouse (7) > Monitor (5) > Teclado (4) > Notebook (0).
- **Hogar:** Silla y Escritorio **empatan en el puesto 1** (2 pedidos cada uno) y la Lampara queda 3.º con 0 (`RANK()` salta el puesto 2 tras un empate).

**Interpretacion:** el Mouse lidera por cantidad de pedidos pero el Monitor genera mucho mas ingreso (2.310 vs 331,50). El producto mas "popular" no siempre es el mas rentable.

### Ingresos por categoria
Tecnologia 3.041,50 (**55 %**) · Accesorios 1.356,00 (24 %) · Hogar 1.160,00 (21 %).
Mas de la mitad de los ingresos depende de una sola categoria.

## 6. Conclusiones y recomendaciones
1. **Reducir la dependencia de pocos clientes:** 82 % de los ingresos viene de 5 personas. Armar un programa de fidelización y captar nuevos clientes.
2. **Aprovechar los meses fuertes y reforzar los debiles:** repetir lo que funciono en abril y lanzar promociones en febrero.
3. **Revisar el catálogo:** Lampara LED y Notebook sin ventas; decidir si se promocionan, se bajan de precio o se retiran.
4. **Mejorar la calidad de datos en origen:** 15 % de los pedidos (6 de 40) llego con precio o fecha faltante; conviene validar al momento de la carga.

> **Limitacion:** el dataset es pequeño (40 pedidos) y los porcentajes son orientativos; con datos reales las conclusiones deberian validarse con mas volumen.

## 7. Estructura del repositorio
```
├── estructura.sql
├── analisis.sql
└── README.md
```

## 8. Herramientas
PostgreSQL · pgAdmin · SQL (JOIN, GROUP BY, CTE, Window Functions, CASE, COALESCE)
