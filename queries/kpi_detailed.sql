-- ====================================================================
-- CONSULTAS PARA INDICADORES DE NEGOCIO - BIKE Z DATA WAREHOUSE
-- ====================================================================

USE DW_BikeZ;
GO

-- ====================================================================
-- INDICADOR 1: ¿Qué productos generan más ingresos o mayor volumen de ventas?
-- ====================================================================

-- 1.1 TOP 10 Productos por Ingresos Totales
SELECT TOP 10 dp.Producto,
              dp.Color,
              dp.Categoria,
              COUNT(*)               as NumeroTransacciones,
              SUM(fv.Cantidad)       as TotalUnidadesVendidas,
              SUM(fv.ImporteTotal)   as TotalIngresos,
              AVG(fv.PrecioUnitario) as PrecioPromedioUnitario,
              AVG(fv.ImporteTotal)   as TicketPromedioProducto
FROM fact_Ventas fv
         INNER JOIN dim_Productos dp ON fv.ProductoKey = dp.ProductoKey
GROUP BY dp.Producto, dp.Color, dp.Categoria
ORDER BY TotalIngresos DESC;

-- 1.2 TOP 10 Productos por Volumen de Ventas (Cantidad)
SELECT TOP 10 dp.Producto,
              dp.Color,
              dp.Categoria,
              SUM(fv.Cantidad)                                  as TotalUnidadesVendidas,
              SUM(fv.ImporteTotal)                              as TotalIngresos,
              COUNT(*)                                          as NumeroTransacciones,
              ROUND(SUM(fv.ImporteTotal) / SUM(fv.Cantidad), 2) as PrecioPromedioRealizado
FROM fact_Ventas fv
         INNER JOIN dim_Productos dp ON fv.ProductoKey = dp.ProductoKey
GROUP BY dp.Producto, dp.Color, dp.Categoria
ORDER BY TotalUnidadesVendidas DESC;

-- 1.3 Análisis por Categoría de Productos
SELECT dp.Categoria,
       COUNT(DISTINCT dp.Producto)                                                          as NumeroProductosDiferentes,
       COUNT(*)                                                                             as NumeroTransacciones,
       SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
       AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas), 2) as PorcentajeIngresoTotal
FROM fact_Ventas fv
         INNER JOIN dim_Productos dp ON fv.ProductoKey = dp.ProductoKey
GROUP BY dp.Categoria
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 2: ¿En qué periodo se realizaron más ventas?
-- ====================================================================

-- 2.1 Análisis de Ventas por Año
SELECT dt.Anio,
       COUNT(DISTINCT fv.VentaID) as NumeroVentas,
       COUNT(*)                   as NumeroDetalles,
       SUM(fv.Cantidad)           as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)       as TotalIngresos,
       AVG(fv.ImporteTotal)       as TicketPromedio
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Anio
ORDER BY dt.Anio;

-- 2.2 Análisis de Ventas por Mes (Histórico)
SELECT dt.Anio,
       dt.Mes,
       dt.NombreMes,
       COUNT(DISTINCT fv.VentaID)                             as NumeroVentas,
       SUM(fv.Cantidad)                                       as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                   as TotalIngresos,
       AVG(fv.ImporteTotal)                                   as TicketPromedio,
       ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC) as RankingPorIngresos
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Anio, dt.Mes, dt.NombreMes
ORDER BY TotalIngresos DESC;

-- 2.3 Análisis de Estacionalidad por Mes (Promedio Histórico)
SELECT dt.Mes,
       dt.NombreMes,
       COUNT(DISTINCT dt.Anio)                                  as AniosConDatos,
       COUNT(DISTINCT fv.VentaID)                               as TotalVentas,
       SUM(fv.ImporteTotal)                                     as TotalIngresos,
       ROUND(AVG(fv.ImporteTotal), 2)                           as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT dt.Anio), 2) as IngresoPromedioAnual
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Mes, dt.NombreMes
ORDER BY dt.Mes;

-- 2.4 Análisis por Trimestre
SELECT dt.Anio,
       dt.Trimestre,
       CASE dt.Trimestre
           WHEN 1 THEN 'Q1 (Ene-Mar)'
           WHEN 2 THEN 'Q2 (Abr-Jun)'
           WHEN 3 THEN 'Q3 (Jul-Sep)'
           WHEN 4 THEN 'Q4 (Oct-Dic)'
           END                    as NombreTrimestre,
       COUNT(DISTINCT fv.VentaID) as NumeroVentas,
       SUM(fv.ImporteTotal)       as TotalIngresos,
       AVG(fv.ImporteTotal)       as TicketPromedio
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Anio, dt.Trimestre
ORDER BY dt.Anio, dt.Trimestre;

-- ====================================================================
-- INDICADOR 3: ¿En qué territorios o países se concentran las ventas?
-- ====================================================================

-- 3.1 Análisis de Ventas por País
SELECT dg.Pais,
       COUNT(DISTINCT dg.Territorio)                                                        as NumeroTerritorios,
       COUNT(DISTINCT fv.VentaID)                                                           as NumeroVentas,
       SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
       AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas), 2) as PorcentajeIngresoTotal
FROM fact_Ventas fv
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Pais
ORDER BY TotalIngresos DESC;

-- 3.2 Análisis de Ventas por Territorio
SELECT dg.Pais,
       dg.Territorio,
       dg.Grupo,
       COUNT(DISTINCT fv.VentaID)                                                           as NumeroVentas,
       SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
       AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas), 2) as PorcentajeIngresoTotal,
       ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC)                               as RankingPorIngresos
FROM fact_Ventas fv
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Pais, dg.Territorio, dg.Grupo
ORDER BY TotalIngresos DESC;

-- 3.3 Análisis por Grupo Geográfico
SELECT dg.Grupo,
       COUNT(DISTINCT dg.Pais)       as NumeroPaises,
       COUNT(DISTINCT dg.Territorio) as NumeroTerritorios,
       COUNT(DISTINCT fv.VentaID)    as NumeroVentas,
       SUM(fv.ImporteTotal)          as TotalIngresos,
       AVG(fv.ImporteTotal)          as TicketPromedio
FROM fact_Ventas fv
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Grupo
ORDER BY TotalIngresos DESC;

-- 3.4 TOP 5 Territorios con Mayor Crecimiento (requiere múltiples períodos)
WITH VentasPorTerritorioPeriodo AS (SELECT dg.Territorio,
                                           dt.Anio,
                                           SUM(fv.ImporteTotal) as IngresoAnual
                                    FROM fact_Ventas fv
                                             INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
                                             INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
                                    GROUP BY dg.Territorio, dt.Anio),
     CrecimientoTerritorios AS (SELECT v1.Territorio,
                                       v1.Anio         as AnioActual,
                                       v1.IngresoAnual as IngresoActual,
                                       v2.IngresoAnual as IngresoAnterior,
                                       CASE
                                           WHEN v2.IngresoAnual > 0
                                               THEN ROUND(((v1.IngresoAnual - v2.IngresoAnual) / v2.IngresoAnual) * 100,
                                                          2)
                                           ELSE NULL
                                           END         as PorcentajeCrecimiento
                                FROM VentasPorTerritorioPeriodo v1
                                         LEFT JOIN VentasPorTerritorioPeriodo v2 ON v1.Territorio = v2.Territorio
                                    AND v1.Anio = v2.Anio + 1)
SELECT TOP 5 Territorio,
             AnioActual,
             IngresoActual,
             IngresoAnterior,
             PorcentajeCrecimiento
FROM CrecimientoTerritorios
WHERE PorcentajeCrecimiento IS NOT NULL
ORDER BY PorcentajeCrecimiento DESC;

-- ====================================================================
-- INDICADOR 4: ¿Qué vendedores generan mayores ventas en la empresa?
-- ====================================================================

-- 4.1 TOP 10 Vendedores por Ingresos Totales
SELECT TOP 10 CASE
                  WHEN de.EmpleadoID IS NOT NULL
                      THEN CAST(de.EmpleadoID AS VARCHAR(10))
                  ELSE 'SIN VENDEDOR'
                  END                                                                              as EmpleadoID,
              de.Cargo,
              de.Genero,
              de.Edad,
              de.AntiguedadAnios,
              COUNT(DISTINCT fv.VentaID)                                                           as NumeroVentas,
              COUNT(*)                                                                             as NumeroDetallesVenta,
              SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
              SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
              AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
              ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas),
                    2)                                                                             as PorcentajeIngresoTotal
FROM fact_Ventas fv
         LEFT JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
GROUP BY de.EmpleadoID, de.Cargo, de.Genero, de.Edad, de.AntiguedadAnios
ORDER BY TotalIngresos DESC;

-- 4.2 Análisis de Performance por Cargo
SELECT ISNULL(de.Cargo, 'SIN VENDEDOR ASIGNADO')                                  as Cargo,
       COUNT(DISTINCT CASE WHEN de.EmpleadoID IS NOT NULL THEN de.EmpleadoID END) as NumeroVendedores,
       COUNT(DISTINCT fv.VentaID)                                                 as NumeroVentas,
       SUM(fv.ImporteTotal)                                                       as TotalIngresos,
       AVG(fv.ImporteTotal)                                                       as TicketPromedio,
       CASE
           WHEN COUNT(DISTINCT CASE WHEN de.EmpleadoID IS NOT NULL THEN de.EmpleadoID END) > 0
               THEN ROUND(
                   SUM(fv.ImporteTotal) / COUNT(DISTINCT CASE WHEN de.EmpleadoID IS NOT NULL THEN de.EmpleadoID END), 2)
           ELSE 0
           END                                                                    as IngresoPromedioPorVendedor
FROM fact_Ventas fv
         LEFT JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
GROUP BY de.Cargo
ORDER BY TotalIngresos DESC;

-- 4.3 Análisis de Performance por Género
SELECT CASE
           WHEN de.Genero = 'M' THEN 'Masculino'
           WHEN de.Genero = 'F' THEN 'Femenino'
           ELSE 'No Especificado'
           END                                                        as Genero,
       COUNT(DISTINCT de.EmpleadoID)                                  as NumeroVendedores,
       COUNT(DISTINCT fv.VentaID)                                     as NumeroVentas,
       SUM(fv.ImporteTotal)                                           as TotalIngresos,
       AVG(fv.ImporteTotal)                                           as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT de.EmpleadoID), 2) as IngresoPromedioPorVendedor
FROM fact_Ventas fv
         INNER JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
WHERE de.EmpleadoID IS NOT NULL
GROUP BY de.Genero
ORDER BY TotalIngresos DESC;

-- 4.4 Vendedores con Mejor Performance por Territorio
WITH VentasPorVendedorTerritorio AS (SELECT de.EmpleadoID,
                                            de.Cargo,
                                            dg.Territorio,
                                            dg.Pais,
                                            SUM(fv.ImporteTotal)                                                              as TotalIngresos,
                                            COUNT(DISTINCT fv.VentaID)                                                        as NumeroVentas,
                                            ROW_NUMBER() OVER (PARTITION BY dg.Territorio ORDER BY SUM(fv.ImporteTotal) DESC) as RankEnTerritorio
                                     FROM fact_Ventas fv
                                              INNER JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
                                              INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
                                     WHERE de.EmpleadoID IS NOT NULL
                                     GROUP BY de.EmpleadoID, de.Cargo, dg.Territorio, dg.Pais)
SELECT Territorio,
       Pais,
       EmpleadoID,
       Cargo,
       TotalIngresos,
       NumeroVentas
FROM VentasPorVendedorTerritorio
WHERE RankEnTerritorio = 1
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 5: ¿Quiénes son los clientes que más compran y en qué ubicaciones están?
-- ====================================================================

-- 5.1 TOP 20 Clientes por Ingresos Totales
SELECT TOP 20 dc.ClienteID,
              dc.NombreCompleto,
              dg.Pais,
              dg.Territorio,
              COUNT(DISTINCT fv.VentaID)                                                           as NumeroCompras,
              COUNT(*)                                                                             as NumeroDetallesCompra,
              SUM(fv.Cantidad)                                                                     as TotalProductosComprados,
              SUM(fv.ImporteTotal)                                                                 as TotalGastado,
              AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
              ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas),
                    2)                                                                             as PorcentajeIngresoTotal,
              -- Frecuencia de compra
              DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) + 1                                      as DiasEntrePrimeraYUltimaCompra,
              CASE
                  WHEN DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) > 0
                      THEN ROUND(CAST(COUNT(DISTINCT fv.VentaID) AS FLOAT) /
                                 (DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) + 1) * 30, 2)
                  ELSE COUNT(DISTINCT fv.VentaID)
                  END                                                                              as ComprasPromedioPorMes
FROM fact_Ventas fv
         INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dc.ClienteID, dc.NombreCompleto, dg.Pais, dg.Territorio
ORDER BY TotalGastado DESC;

-- 5.2 Análisis de Clientes por País y Territorio
SELECT dg.Pais,
       dg.Territorio,
       COUNT(DISTINCT dc.ClienteID)                                              as NumeroClientes,
       COUNT(DISTINCT fv.VentaID)                                                as NumeroVentas,
       SUM(fv.ImporteTotal)                                                      as TotalIngresos,
       AVG(fv.ImporteTotal)                                                      as TicketPromedio,
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT dc.ClienteID), 2)             as IngresoPromedioPorCliente,
       ROUND(COUNT(DISTINCT fv.VentaID) * 1.0 / COUNT(DISTINCT dc.ClienteID), 2) as VentasPromedioPorCliente
FROM fact_Ventas fv
         INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Pais, dg.Territorio
ORDER BY TotalIngresos DESC;

-- 5.3 Segmentación de Clientes por Valor (RFM simplificado)
WITH ClientesRFM AS (SELECT dc.ClienteID,
                            dc.NombreCompleto,
                            dg.Pais,
                            dg.Territorio,
                            -- Recency: Días desde la última compra
                            DATEDIFF(DAY, MAX(dt.Fecha), GETDATE()) as DiasDesdeUltimaCompra,
                            -- Frequency: Número de compras
                            COUNT(DISTINCT fv.VentaID)              as NumeroCompras,
                            -- Monetary: Total gastado
                            SUM(fv.ImporteTotal)                    as TotalGastado
                     FROM fact_Ventas fv
                              INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
                              INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
                              INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
                     GROUP BY dc.ClienteID, dc.NombreCompleto, dg.Pais, dg.Territorio),
     ClientesSegmentados AS (SELECT *,
                                    CASE
                                        WHEN TotalGastado >=
                                             (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY TotalGastado)
                                              FROM ClientesRFM)
                                            AND NumeroCompras >=
                                                (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY NumeroCompras)
                                                 FROM ClientesRFM)
                                            THEN 'VIP (Alto Valor + Alta Frecuencia)'
                                        WHEN TotalGastado >=
                                             (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY TotalGastado)
                                              FROM ClientesRFM)
                                            THEN 'Premium (Alto Valor)'
                                        WHEN NumeroCompras >=
                                             (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP (ORDER BY NumeroCompras)
                                              FROM ClientesRFM)
                                            THEN 'Frecuente (Alta Frecuencia)'
                                        ELSE 'Regular'
                                        END as SegmentoCliente
                             FROM ClientesRFM)
SELECT SegmentoCliente,
       COUNT(*)                                                                                  as NumeroClientes,
       AVG(TotalGastado)                                                                         as PromedioGastado,
       AVG(NumeroCompras)                                                                        as PromedioCompras,
       AVG(DiasDesdeUltimaCompra)                                                                as PromedioRecency,
       SUM(TotalGastado)                                                                         as TotalSegmento,
       ROUND(SUM(TotalGastado) * 100.0 / (SELECT SUM(TotalGastado) FROM ClientesSegmentados), 2) as PorcentajeIngresos
FROM ClientesSegmentados
GROUP BY SegmentoCliente
ORDER BY TotalSegmento DESC;

-- 5.4 Clientes Top por País/Territorio
WITH ClientesRankingPorTerritorio AS (SELECT dc.ClienteID,
                                             dc.NombreCompleto,
                                             dg.Pais,
                                             dg.Territorio,
                                             SUM(fv.ImporteTotal)                                                                       as TotalGastado,
                                             COUNT(DISTINCT fv.VentaID)                                                                 as NumeroCompras,
                                             ROW_NUMBER() OVER (PARTITION BY dg.Pais, dg.Territorio ORDER BY SUM(fv.ImporteTotal) DESC) as RankEnTerritorio
                                      FROM fact_Ventas fv
                                               INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
                                               INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
                                      GROUP BY dc.ClienteID, dc.NombreCompleto, dg.Pais, dg.Territorio)
SELECT Pais,
       Territorio,
       ClienteID,
       NombreCompleto,
       TotalGastado,
       NumeroCompras
FROM ClientesRankingPorTerritorio
WHERE RankEnTerritorio <= 3 -- Top 3 clientes por territorio
ORDER BY Pais, Territorio, RankEnTerritorio;