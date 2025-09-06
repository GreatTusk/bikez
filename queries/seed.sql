-- ====================================================================
-- CONSULTAS ETL PARA CARGAR DATA WAREHOUSE - BIKE Z
-- Proceso: Migración desde BD Transaccional a Data Warehouse
-- ====================================================================

-- ====================================================================
-- 1. CARGA DE DIMENSIÓN PRODUCTOS (dim_Productos)
-- ====================================================================
INSERT INTO dim_Productos (ProductoID, Producto, Color, CategoriaID, Categoria)
SELECT p.ProductoID,
       p.Producto,
       p.Color,
       p.CategoriaID,
       c.Categoria
FROM [BikeZ_DB].[dbo].[Productos] p
         LEFT JOIN [BikeZ_DB].[dbo].[Categorias] c ON p.CategoriaID = c.CategoriaID;

-- ====================================================================
-- 2. CARGA DE DIMENSIÓN CLIENTES (dim_Clientes)
-- ====================================================================
INSERT INTO dim_Clientes (ClienteID, Nombre, Apellido)
SELECT c.ClienteID,
       c.Nombre,
       c.Apellido
FROM [BikeZ_DB].[dbo].[Clientes] c;

-- ====================================================================
-- 3. CARGA DE DIMENSIÓN EMPLEADOS (dim_Empleados)
-- ====================================================================
INSERT INTO dim_Empleados (EmpleadoID,
                           Cargo,
                           FechaNacimiento,
                           EstadoCivil,
                           Genero,
                           FechaContratacion,
                           HorasVacaciones)
SELECT e.EmpleadoID,
       e.Cargo,
       e.FechaNacimiento,
       e.EstadoCivil,
       e.Genero,
       e.FechaContratacion,
       e.HorasVacaciones
FROM [BikeZ_DB].[dbo].[Empleados] e;

-- ====================================================================
-- 4. CARGA DE DIMENSIÓN GEOGRAFÍA (dim_Geografia)
-- ====================================================================
INSERT INTO dim_Geografia (PaisID, Pais, TerritorioID, Territorio, Grupo, AlmacenID, Almacen)
SELECT DISTINCT p.PaisID,
                p.Pais,
                t.TerritorioID,
                t.Territorio,
                t.Grupo,
                a.AlmacenID,
                a.Almacen
FROM [BikeZ_DB].[dbo].[Paises] p
         INNER JOIN [BikeZ_DB].[dbo].[Territorios] t ON p.PaisID = t.PaisID
         LEFT JOIN [BikeZ_DB].[dbo].[Almacenes] a ON t.TerritorioID = a.TerritorioID

UNION

SELECT DISTINCT p.PaisID,
                p.Pais,
                t.TerritorioID,
                t.Territorio,
                t.Grupo,
                NULL as AlmacenID,
                NULL as Almacen
FROM [BikeZ_DB].[dbo].[Paises] p
         INNER JOIN [BikeZ_DB].[dbo].[Territorios] t ON p.PaisID = t.PaisID
WHERE t.TerritorioID NOT IN (SELECT DISTINCT a.TerritorioID
                             FROM [BikeZ_DB].[dbo].[Almacenes] a
                             WHERE a.TerritorioID IS NOT NULL);

-- ====================================================================
-- 5. CARGA DE DIMENSIÓN TIEMPO (dim_Tiempo)
-- ====================================================================
DECLARE @FechaInicio DATE, @FechaFin DATE;

SELECT @FechaInicio = MIN(CAST(v.Fecha AS DATE)),
       @FechaFin = MAX(CASE
                           WHEN v.FechaEnvio IS NOT NULL THEN CAST(v.FechaEnvio AS DATE)
                           ELSE CAST(v.Fecha AS DATE)
           END)
FROM [BikeZ_DB].[dbo].[Ventas] v;

SET @FechaInicio = DATEADD(YEAR, -1, @FechaInicio);
SET @FechaFin = DATEADD(YEAR, 2, @FechaFin);

WITH FechasSequencia AS (SELECT @FechaInicio AS Fecha
                         UNION ALL
                         SELECT DATEADD(DAY, 1, Fecha)
                         FROM FechasSequencia
                         WHERE Fecha < @FechaFin)
INSERT
INTO dim_Tiempo (TiempoKey,
                 Fecha,
                 Anio,
                 Mes,
                 Dia,
                 Trimestre,
                 Semana,
                 DiaSemana,
                 NombreMes,
                 NombreDiaSemana,
                 EsFinDeSemana,
                 PeriodoAnioMes)
SELECT CONVERT(INT, FORMAT(Fecha, 'yyyyMMdd'))                        as TiempoKey,
       Fecha,
       YEAR(Fecha)                                                    as Anio,
       MONTH(Fecha)                                                   as Mes,
       DAY(Fecha)                                                     as Dia,
       DATEPART(QUARTER, Fecha)                                       as Trimestre,
       DATEPART(WEEK, Fecha)                                          as Semana,
       DATEPART(WEEKDAY, Fecha)                                       as DiaSemana,
       CASE MONTH(Fecha)
           WHEN 1 THEN 'Enero'
           WHEN 7 THEN 'Julio'
           WHEN 2 THEN 'Febrero'
           WHEN 8 THEN 'Agosto'
           WHEN 3 THEN 'Marzo'
           WHEN 9 THEN 'Septiembre'
           WHEN 4 THEN 'Abril'
           WHEN 10 THEN 'Octubre'
           WHEN 5 THEN 'Mayo'
           WHEN 11 THEN 'Noviembre'
           WHEN 6 THEN 'Junio'
           WHEN 12 THEN 'Diciembre'
           END                                                        as NombreMes,
       CASE DATEPART(WEEKDAY, Fecha)
           WHEN 1 THEN 'Domingo'
           WHEN 5 THEN 'Jueves'
           WHEN 2 THEN 'Lunes'
           WHEN 6 THEN 'Viernes'
           WHEN 3 THEN 'Martes'
           WHEN 7 THEN 'Sábado'
           WHEN 4 THEN 'Miércoles'
           END                                                        as NombreDiaSemana,
       CASE WHEN DATEPART(WEEKDAY, Fecha) IN (1, 7) THEN 1 ELSE 0 END as EsFinDeSemana,
       FORMAT(Fecha, 'yyyy-MM')                                       as PeriodoAnioMes
FROM FechasSequencia
OPTION (MAXRECURSION 0);

-- ====================================================================
-- 6. CARGA DE TABLA DE HECHOS (fact_Ventas)
-- ====================================================================
INSERT INTO fact_Ventas (ProductoKey,
                         ClienteKey,
                         EmpleadoKey,
                         GeografiaKey,
                         FechaVentaKey,
                         FechaEnvioKey,
                         VentaID,
                         DetalleVentaID,
                         Cantidad,
                         PrecioUnitario)
SELECT dp.ProductoKey,
       dc.ClienteKey,
       de.EmpleadoKey,
       dg.GeografiaKey,
       dt_venta.TiempoKey as FechaVentaKey,
       dt_envio.TiempoKey as FechaEnvioKey,
       dv.VentaID,
       dv.DetalleVentaID,
       dv.Cantidad,
       dv.PrecioUnitario
FROM [BikeZ_DB].[dbo].[DetalleVentas] dv
         INNER JOIN [BikeZ_DB].[dbo].[Ventas] v ON dv.VentaID = v.VentaID
         INNER JOIN dim_Productos dp ON dv.ProductoID = dp.ProductoID
         INNER JOIN dim_Clientes dc ON v.ClienteID = dc.ClienteID
         LEFT JOIN dim_Empleados de ON v.VendedorID = de.EmpleadoID
         INNER JOIN dim_Geografia dg ON v.TerritorioID = dg.TerritorioID
         INNER JOIN dim_Tiempo dt_venta ON dt_venta.TiempoKey = CONVERT(INT, FORMAT(CAST(v.Fecha AS DATE), 'yyyyMMdd'))
         LEFT JOIN dim_Tiempo dt_envio
                   ON dt_envio.TiempoKey = CONVERT(INT, FORMAT(CAST(v.FechaEnvio AS DATE), 'yyyyMMdd'));
