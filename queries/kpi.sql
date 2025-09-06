-- ====================================================================
-- CONSULTAS ESPECÍFICAS PARA INDICADORES DE NEGOCIO - BIKE Z
-- Una consulta por indicador
-- ====================================================================

USE DW_BikeZ;
GO

-- ====================================================================
-- INDICADOR 1: ¿Qué productos generan más ingresos o mayor volumen de ventas?
-- ====================================================================

SELECT TOP 15 dp.Categoria,
              dp.Producto,
              dp.Color,
              -- Métricas de Volumen
              SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
              COUNT(*)                                                                             as NumeroTransacciones,
              -- Métricas de Ingresos
              SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
              AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
              -- Participación en el negocio
              ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas),
                    2)                                                                             as PorcentajeIngresoTotal,
              ROUND(SUM(fv.Cantidad) * 100.0 / (SELECT SUM(Cantidad) FROM fact_Ventas),
                    2)                                                                             as PorcentajeVolumenTotal,
              -- Ranking
              ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC)                               as RankingPorIngresos,
              ROW_NUMBER() OVER (ORDER BY SUM(fv.Cantidad) DESC)                                   as RankingPorVolumen
FROM fact_Ventas fv
         INNER JOIN dim_Productos dp ON fv.ProductoKey = dp.ProductoKey
GROUP BY dp.Categoria, dp.Producto, dp.Color
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 2: ¿En qué periodo se realizaron más ventas?
-- ====================================================================

SELECT dt.Anio,
       dt.Mes,
       dt.NombreMes,
       dt.Trimestre,
       -- Métricas de Ventas
       COUNT(DISTINCT fv.VentaID)                                                           as NumeroVentas,
       SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
       AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
       -- Participación y Rankings
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas), 2) as PorcentajeIngresoTotal,
       ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC)                               as RankingPorIngresos,
       ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT fv.VentaID) DESC)                         as RankingPorNumeroVentas,
       -- Análisis comparativo
       LAG(SUM(fv.ImporteTotal), 1) OVER (ORDER BY dt.Anio, dt.Mes)                         as IngresoMesAnterior,
       CASE
           WHEN LAG(SUM(fv.ImporteTotal), 1) OVER (ORDER BY dt.Anio, dt.Mes) > 0
               THEN ROUND(((SUM(fv.ImporteTotal) - LAG(SUM(fv.ImporteTotal), 1) OVER (ORDER BY dt.Anio, dt.Mes))
               / LAG(SUM(fv.ImporteTotal), 1) OVER (ORDER BY dt.Anio, dt.Mes)) * 100, 2)
           END                                                                              as PorcentajeCrecimientoMensual
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Anio, dt.Mes, dt.NombreMes, dt.Trimestre
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 3: ¿En qué territorios o países se concentran las ventas de la empresa?
-- ====================================================================

SELECT dg.Pais,
       dg.Territorio,
       dg.Grupo,
       -- Métricas de Ventas
       COUNT(DISTINCT fv.VentaID)                                                  as NumeroVentas,
       COUNT(DISTINCT fv.ClienteKey)                                               as NumeroClientesUnicos,
       SUM(fv.Cantidad)                                                            as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                        as TotalIngresos,
       AVG(fv.ImporteTotal)                                                        as TicketPromedio,
       -- Métricas de concentración
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas),
             2)                                                                    as PorcentajeIngresoTotal,
       ROUND(COUNT(DISTINCT fv.VentaID) * 100.0 / (SELECT COUNT(DISTINCT VentaID) FROM fact_Ventas),
             2)                                                                    as PorcentajeVentasTotal,
       -- Métricas por cliente
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT fv.ClienteKey), 2)              as IngresoPromedioPorCliente,
       ROUND(COUNT(DISTINCT fv.VentaID) * 1.0 / COUNT(DISTINCT fv.ClienteKey),
             2)                                                                    as VentasPromedioPorCliente,
       -- Rankings
       ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC)                      as RankingPorIngresos,
       ROW_NUMBER() OVER (PARTITION BY dg.Pais ORDER BY SUM(fv.ImporteTotal) DESC) as RankingEnPais
FROM fact_Ventas fv
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Pais, dg.Territorio, dg.Grupo
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 4: ¿Qué vendedores generan mayores ventas en la empresa?
-- ====================================================================

SELECT CASE
           WHEN de.EmpleadoID IS NOT NULL THEN CAST(de.EmpleadoID AS VARCHAR(10))
           ELSE 'SIN VENDEDOR'
           END                                                                              as EmpleadoID,
       de.Cargo,
       CASE
           WHEN de.Genero = 'M' THEN 'Masculino'
           WHEN de.Genero = 'F' THEN 'Femenino'
           ELSE 'No Especificado'
           END                                                                              as Genero,
       de.Edad,
       de.AntiguedadAnios,
       -- Métricas de Performance
       COUNT(DISTINCT fv.VentaID)                                                           as NumeroVentas,
       COUNT(DISTINCT fv.ClienteKey)                                                        as NumeroClientesAtendidos,
       COUNT(DISTINCT dg.Territorio)                                                        as NumeroTerritoriosAtendidos,
       SUM(fv.Cantidad)                                                                     as TotalUnidadesVendidas,
       SUM(fv.ImporteTotal)                                                                 as TotalIngresos,
       AVG(fv.ImporteTotal)                                                                 as TicketPromedio,
       -- Participación y eficiencia
       ROUND(SUM(fv.ImporteTotal) * 100.0 / (SELECT SUM(ImporteTotal) FROM fact_Ventas), 2) as PorcentajeIngresoTotal,
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT fv.VentaID), 2)                          as IngresoPromedioPorVenta,
       ROUND(SUM(fv.ImporteTotal) / COUNT(DISTINCT fv.ClienteKey), 2)                       as IngresoPromedioPorCliente,
       -- Rankings
       ROW_NUMBER() OVER (ORDER BY SUM(fv.ImporteTotal) DESC)                               as RankingPorIngresos,
       ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT fv.VentaID) DESC)                         as RankingPorNumeroVentas,
       -- Comparación con promedio de la empresa
       ROUND((SUM(fv.ImporteTotal) - (SELECT AVG(TotalVendedor)
                                      FROM (SELECT SUM(ImporteTotal) as TotalVendedor
                                            FROM fact_Ventas
                                            WHERE EmpleadoKey IS NOT NULL
                                            GROUP BY EmpleadoKey) as PromedioVendedores)) / (SELECT AVG(TotalVendedor)
                                                                                             FROM (SELECT SUM(ImporteTotal) as TotalVendedor
                                                                                                   FROM fact_Ventas
                                                                                                   WHERE EmpleadoKey IS NOT NULL
                                                                                                   GROUP BY EmpleadoKey) as PromedioVendedores) *
             100,
             2)                                                                             as DiferenciaConPromedioEmpresa
FROM fact_Ventas fv
         LEFT JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
         LEFT JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY de.EmpleadoID, de.Cargo, de.Genero, de.Edad, de.AntiguedadAnios
ORDER BY TotalIngresos DESC;

-- ====================================================================
-- INDICADOR 5: ¿Quiénes son los clientes que más compran y en qué ubicaciones están?
-- ====================================================================

WITH ClientesCompletos AS (SELECT dc.ClienteID,
                                  dc.NombreCompleto,
                                  dg.Pais,
                                  dg.Territorio,
                                  -- Métricas básicas
                                  COUNT(DISTINCT fv.VentaID)                      as NumeroCompras,
                                  SUM(fv.Cantidad)                                as TotalProductosComprados,
                                  SUM(fv.ImporteTotal)                            as TotalGastado,
                                  AVG(fv.ImporteTotal)                            as TicketPromedio,
                                  -- Análisis temporal
                                  MIN(dt.Fecha)                                   as PrimeraCompra,
                                  MAX(dt.Fecha)                                   as UltimaCompra,
                                  DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) + 1 as DiasComoCliente,
                                  -- Frecuencia de compra
                                  CASE
                                      WHEN DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) > 0
                                          THEN ROUND(CAST(COUNT(DISTINCT fv.VentaID) AS FLOAT) /
                                                     (DATEDIFF(DAY, MIN(dt.Fecha), MAX(dt.Fecha)) + 1) * 30, 2)
                                      ELSE COUNT(DISTINCT fv.VentaID)
                                      END                                         as ComprasPromedioPorMes,
                                  -- Recency (días desde última compra)
                                  DATEDIFF(DAY, MAX(dt.Fecha), GETDATE())         as DiasDesdeUltimaCompra
                           FROM fact_Ventas fv
                                    INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
                                    INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
                                    INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
                           GROUP BY dc.ClienteID, dc.NombreCompleto, dg.Pais, dg.Territorio)
SELECT ClienteID,
       NombreCompleto,
       Pais,
       Territorio,
       NumeroCompras,
       TotalProductosComprados,
       TotalGastado,
       TicketPromedio,
       PrimeraCompra,
       UltimaCompra,
       DiasComoCliente,
       ComprasPromedioPorMes,
       DiasDesdeUltimaCompra,
       -- Participación en el negocio
       ROUND(TotalGastado * 100.0 / (SELECT SUM(TotalGastado) FROM ClientesCompletos), 2) as PorcentajeIngresoTotal,
       -- Rankings
       ROW_NUMBER() OVER (ORDER BY TotalGastado DESC)                                     as RankingPorGastoTotal,
       ROW_NUMBER() OVER (ORDER BY NumeroCompras DESC)                                    as RankingPorFrecuencia,
       ROW_NUMBER() OVER (PARTITION BY Pais, Territorio ORDER BY TotalGastado DESC)       as RankingEnTerritorio,
       -- Segmentación RFM simplificada usando NTILE
       CASE
           WHEN NTILE(5) OVER (ORDER BY TotalGastado) = 5
               AND NTILE(5) OVER (ORDER BY NumeroCompras) = 5
               THEN 'VIP (Alto Valor + Alta Frecuencia)'
           WHEN NTILE(5) OVER (ORDER BY TotalGastado) IN (4, 5)
               THEN 'Premium (Alto Valor)'
           WHEN NTILE(5) OVER (ORDER BY NumeroCompras) IN (4, 5)
               THEN 'Frecuente (Alta Frecuencia)'
           WHEN DiasDesdeUltimaCompra <= 90
               THEN 'Regular Activo'
           ELSE 'Regular Inactivo'
           END                                                                            as SegmentoCliente,
       -- Estado del cliente
       CASE
           WHEN DiasDesdeUltimaCompra <= 30 THEN 'Muy Activo'
           WHEN DiasDesdeUltimaCompra <= 90 THEN 'Activo'
           WHEN DiasDesdeUltimaCompra <= 180 THEN 'En Riesgo'
           ELSE 'Inactivo'
           END                                                                            as EstadoActividad
FROM ClientesCompletos
ORDER BY TotalGastado DESC;