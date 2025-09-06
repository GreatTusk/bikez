use DW_BikeZ;
-- ====================================================================
-- CONSULTAS DE VERIFICACIÓN
-- ====================================================================

-- Verificar conteos de registros
SELECT 'dim_Productos' as Tabla, COUNT(*) as Registros FROM dim_Productos
UNION ALL
SELECT 'dim_Clientes', COUNT(*) FROM dim_Clientes
UNION ALL
SELECT 'dim_Empleados', COUNT(*) FROM dim_Empleados
UNION ALL
SELECT 'dim_Geografia', COUNT(*) FROM dim_Geografia
UNION ALL
SELECT 'dim_Tiempo', COUNT(*) FROM dim_Tiempo
UNION ALL
SELECT 'fact_Ventas', COUNT(*) FROM fact_Ventas;

-- Verificar integridad referencial
SELECT
    'Productos sin categoría' as Verificacion,
    COUNT(*) as Cantidad
FROM dim_Productos
WHERE CategoriaID IS NULL OR Categoria IS NULL

UNION ALL

SELECT
    'Ventas sin vendedor asignado',
    COUNT(*)
FROM fact_Ventas
WHERE EmpleadoKey IS NULL

UNION ALL

SELECT
    'Ventas sin fecha de envío',
    COUNT(*)
FROM fact_Ventas
WHERE FechaEnvioKey IS NULL;

-- Verificar rangos de fechas cargadas
SELECT
    'Rango fechas en dim_Tiempo' as Info,
    CAST(MIN(Fecha) AS VARCHAR(10)) + ' a ' + CAST(MAX(Fecha) AS VARCHAR(10)) as Valor
FROM dim_Tiempo

UNION ALL

SELECT
    'Total días en dim_Tiempo',
    CAST(COUNT(*) AS VARCHAR(10))
FROM dim_Tiempo;

-- ====================================================================
-- CONSULTAS DE PRUEBA PARA VALIDAR EL MODELO
-- ====================================================================

-- Ejemplo 1: Ventas por producto y categoría
SELECT
    dp.Categoria,
    dp.Producto,
    SUM(fv.Cantidad) as TotalCantidad,
    SUM(fv.ImporteTotal) as TotalIngresos,
    COUNT(*) as NumeroTransacciones
FROM fact_Ventas fv
         INNER JOIN dim_Productos dp ON fv.ProductoKey = dp.ProductoKey
GROUP BY dp.Categoria, dp.Producto
ORDER BY TotalIngresos DESC;

-- Ejemplo 2: Ventas por período temporal
SELECT
    dt.Anio,
    dt.NombreMes,
    SUM(fv.ImporteTotal) as TotalVentas,
    COUNT(DISTINCT fv.VentaID) as NumeroVentas
FROM fact_Ventas fv
         INNER JOIN dim_Tiempo dt ON fv.FechaVentaKey = dt.TiempoKey
GROUP BY dt.Anio, dt.Mes, dt.NombreMes
ORDER BY dt.Anio, dt.Mes;

-- Ejemplo 3: Ventas por territorio y país
SELECT
    dg.Pais,
    dg.Territorio,
    SUM(fv.ImporteTotal) as TotalVentas,
    AVG(fv.ImporteTotal) as VentaPromedio
FROM fact_Ventas fv
         INNER JOIN dim_Geografia dg ON fv.GeografiaKey = dg.GeografiaKey
GROUP BY dg.Pais, dg.Territorio
ORDER BY TotalVentas DESC;

-- Ejemplo 4: Performance de vendedores
SELECT
    de.Cargo,
    ISNULL(de.Genero, 'N/D') as Genero,
    COUNT(*) as NumeroVentas,
    SUM(fv.ImporteTotal) as TotalVentas,
    AVG(fv.ImporteTotal) as VentaPromedio
FROM fact_Ventas fv
         LEFT JOIN dim_Empleados de ON fv.EmpleadoKey = de.EmpleadoKey
GROUP BY de.Cargo, de.Genero
ORDER BY TotalVentas DESC;

-- Ejemplo 5: Análisis de clientes top
SELECT TOP 10
    dc.NombreCompleto,
    COUNT(DISTINCT fv.VentaID) as NumeroCompras,
       SUM(fv.Cantidad) as TotalProductosComprados,
       SUM(fv.ImporteTotal) as TotalGastado,
       AVG(fv.ImporteTotal) as TicketPromedio
FROM fact_Ventas fv
         INNER JOIN dim_Clientes dc ON fv.ClienteKey = dc.ClienteKey
GROUP BY dc.ClienteKey, dc.NombreCompleto
ORDER BY TotalGastado DESC;