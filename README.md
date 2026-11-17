# Capstone: Análisis Exploratorio de Datos con PostgreSQL
# Brandon Zalazar

## 1. Problema de negocio
Una tienda online de tecnología, hogar y accesorios quiere saber **de dónde vienen sus ingresos** para decidir dónde invertir en marketing y stock. El análisis responde:

1. ¿Qué clientes generan más ingresos y qué tan concentrado está el negocio?
2. ¿Cómo evolucionan las ventas mes a mes?
3. ¿Qué productos casi no se venden?
4. ¿Qué producto lidera dentro de cada categoría?
5. ¿De qué categorías y proveedores depende el negocio?

## 2. Dataset
Dataset **inventado** para el curso, con 6 tablas relacionadas:

| Tabla | Filas | Contenido |
|---|---|---|
| `categorias` | 3 | Tecnología, Hogar, Accesorios |
| `proveedores` | 4 | nombre y país |
| `clientes` | 10 | nombre, email, ciudad, fecha de registro |
| `productos` | 10 | nombre, categoría, proveedor, precio de lista |
| `pedidos` | 30 | cliente, fecha, estado |
| `detalle_pedidos` | 56 | productos de cada pedido: cantidad y precio unitario |

```
categorias ──┐
             ├── productos ──── detalle_pedidos ──── pedidos ──── clientes
proveedores ─┘
```

El dataset incluye **datos sucios a propósito**: 4 precios nulos, 2 fechas nulas, 3 pedidos cancelados y 2 clientes sin ciudad.

## 3. Cómo ejecutar el código
1. En pgAdmin o `psql`, crear la base: `CREATE DATABASE capstone_project;`
2. Conectarse a `capstone_project` (en pgAdmin: clic derecho sobre la base → *Query Tool*).
3. Ejecutar **`estructura.sql`**: crea las tablas e inserta los datos (se puede re-ejecutar sin errores).
4. Ejecutar **`analisis.sql`**: limpieza y consultas. Conviene correrlas de a una (seleccionar y F5).

Con `psql`:
```bash
psql -U postgres -d capstone_project -f estructura.sql
psql -U postgres -d capstone_project -f analisis.sql
```

## 4. Limpieza aplicada
| Problema | Decisión | Por qué |
|---|---|---|
| 4 `precio_unitario` nulos | `COALESCE(precio_unitario, precio de lista)` | Tratar el nulo como 0 regalaría el producto y subestimaría ingresos. |
| 3 pedidos cancelados | Se excluyen | No generaron ingreso real. |
| 2 `fecha_pedido` nulas | No se inventa la fecha; se muestran como `Sin fecha` | Una fecha falsa distorsionaría la tendencia mensual. |
| 2 clientes sin ciudad | Se mantienen | No afecta las métricas principales. |

Tras la limpieza quedan **27 pedidos válidos (48 líneas de detalle) y 11.953,50 de ingresos**, con un ticket promedio de 442,72 por pedido. De los 4 precios nulos, 1 estaba en un pedido cancelado; los otros 3 se completaron y representan 431,00 (3,6 % del total), así que el impacto de esa decisión es bajo. Se verificó que los JOINs no duplican filas (la vista tiene exactamente las 48 líneas esperadas).

## 5. Hallazgos principales

### Clientes: negocio muy concentrado
| # | Cliente | Pedidos | Gasto |
|---|---|---|---|
| 1 | Camila Torres | 5 | 4.007,50 |
| 2 | Agustina Molina | 4 | 2.621,00 |
| 3 | Valentina Ruiz | 5 | 1.734,50 |
| 4 | Federico Castro | 5 | 1.461,50 |
| 5 | Sofía Ramírez | 3 | 932,00 |

**Interpretación:** los 5 mejores clientes (la mitad de la base) generan el **90 % de los ingresos**, y Camila sola el **34 %**. Gran parte de su gasto son 4 Notebooks (3.000 de sus 4.007,50), por lo que una sola persona sostiene la mayor parte de las ventas de ese producto. Perder a uno o dos de ellos tendría un impacto muy fuerte.

Segmentación (4 o más pedidos = *Leal*): 4 clientes leales, 3 ocasionales y 3 nuevos o inactivos. Julián y Nicolás **no compraron nunca**, por lo que son un objetivo claro de campañas de reactivación.

### Ventas por mes
| Mes | Pedidos | Ventas |
|---|---|---|
| 2025-01 | 7 | 3.801,00 |
| 2025-02 | 6 | 3.627,50 |
| 2025-03 | 3 | 1.097,00 |
| 2025-04 | 2 | 726,00 |
| 2025-05 | 4 | 644,50 |
| 2025-06 | 3 | 1.765,50 |
| Sin fecha | 2 | 292,00 |

**Interpretación:** enero y febrero concentran el **64 %** de las ventas con fecha conocida; desde marzo la actividad cae y mayo es el mes más bajo. Junio se recupera en ventas con solo 3 pedidos porque una Notebook (1.500) explica el 85 % del mes: no es una mejora sostenida del volumen sino una venta puntual de alto valor. Conviene investigar por qué se frena la demanda después de febrero.

### Productos menos vendidos
| Producto | Categoría | Unidades |
|---|---|---|
| Lámpara LED | Hogar | 0 |
| Botella térmica | Accesorios | 3 |
| Teclado mecánico | Tecnología | 5 |

**Interpretación:** la Lámpara LED no tuvo ninguna venta; es candidata a promoción, rebaja o retiro del catálogo. La Botella térmica vende poco pero además es barata (18), así que aporta casi nada a los ingresos.

### Ranking por categoría (`RANK()`, por cantidad de pedidos)
- **Accesorios:** Mochila urbana (6) > Auriculares (4) > Botella térmica (2).
- **Hogar:** Silla ergonómica (6) > Escritorio (4) > Lámpara LED (0).
- **Tecnología:** Mouse (15) > **Notebook y Monitor empatan en el puesto 2** (4 pedidos cada uno) > Teclado en el puesto 4 (`RANK()` salta el puesto 3 tras un empate).

**Interpretación:** el producto más pedido no es el que más ingresos genera. El Mouse tiene 15 pedidos pero solo 484,50 de ingresos, mientras que la Notebook, con 4 pedidos, genera 5.250.

### Dependencia por categoría y proveedor
| Categoría | Ingresos | % |
|---|---|---|
| Tecnología | 7.814,50 | 65,4 % |
| Hogar | 3.080,00 | 25,8 % |
| Accesorios | 1.059,00 | 8,9 % |

| Proveedor | País | Ingresos | % |
|---|---|---|---|
| Digital Global | Estados Unidos | 6.930,00 | 58,0 % |
| HogarPlus | Argentina | 3.080,00 | 25,8 % |
| TecnoMundo S.A. | China | 1.304,50 | 10,9 % |
| AccesoriosSur | Argentina | 639,00 | 5,3 % |

**Interpretación:** casi dos tercios de las ventas dependen de Tecnología, y **un solo proveedor (Digital Global, que provee Notebook y Monitor) concentra el 58 %**. Un problema de abastecimiento con ese proveedor afectaría de lleno al negocio.

## 6. Conclusiones y recomendaciones
1. **Reducir la dependencia de pocos clientes:** 90 % de los ingresos viene de 5 personas. Armar un programa de fidelización y captar clientes nuevos.
2. **Reactivar clientes inactivos:** 2 clientes registrados nunca compraron.
3. **Entender la caída posterior a febrero** y planificar campañas para marzo-mayo.
4. **Revisar el catálogo:** la Lámpara LED no se vende; la Botella térmica aporta muy poco.
5. **Diversificar proveedores y categorías:** hoy un proveedor y una categoría concentran más de la mitad de las ventas.

> **Limitación:** el dataset es pequeño (27 pedidos válidos), por lo que los porcentajes son orientativos y un solo pedido grande mueve mucho los resultados. Con datos reales habría que validar con más volumen.

## 7. Estructura del repositorio
```
├── estructura.sql   # creación de tablas e inserción de datos
├── analisis.sql     # limpieza y consultas comentadas
└── README.md        # este archivo
```

## 8. Herramientas
PostgreSQL · pgAdmin · SQL (JOIN, GROUP BY, CTE, Window Functions, CASE, COALESCE)
