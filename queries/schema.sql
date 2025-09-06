-- ====================================================================
-- MODELO DATA WAREHOUSE - BIKE Z
-- Proceso: VENTAS
-- ====================================================================

USE DW_BikeZ;

-- TABLA DE DIMENSIÓN: PRODUCTOS
-- Consolida información de productos y sus categorías
CREATE TABLE dim_Productos
(
    ProductoKey        INT IDENTITY (1,1) NOT NULL PRIMARY KEY,
    ProductoID         INT                NOT NULL,
    Producto           NVARCHAR(50)       NOT NULL,
    Color              NVARCHAR(15),
    CategoriaID        INT,
    Categoria          NVARCHAR(50),
    FechaCreacion      DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),
    EsActivo           BIT      DEFAULT 1
);

-- TABLA DE DIMENSIÓN: CLIENTES
-- Información de los clientes
CREATE TABLE dim_Clientes
(
    ClienteKey         INT IDENTITY (1,1) NOT NULL PRIMARY KEY,
    ClienteID          INT                NOT NULL,
    Nombre             NVARCHAR(50),
    Apellido           NVARCHAR(50),
    NombreCompleto     AS (RTRIM(LTRIM(ISNULL(Nombre, '') + ' ' + ISNULL(Apellido, '')))),
    FechaCreacion      DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),
    EsActivo           BIT      DEFAULT 1
);

-- TABLA DE DIMENSIÓN: EMPLEADOS/VENDEDORES
-- Información de los vendedores
CREATE TABLE dim_Empleados
(
    EmpleadoKey        INT IDENTITY (1,1) NOT NULL PRIMARY KEY,
    EmpleadoID         INT                NOT NULL,
    Cargo              NVARCHAR(50)       NOT NULL,
    FechaNacimiento    DATE               NOT NULL,
    EstadoCivil        NCHAR(1)           NOT NULL,
    Genero             NCHAR(1)           NOT NULL,
    FechaContratacion  DATE               NOT NULL,
    HorasVacaciones    SMALLINT           NOT NULL,
    Edad               AS (DATEDIFF(YEAR, FechaNacimiento, GETDATE())),
    AntiguedadAnios    AS (DATEDIFF(YEAR, FechaContratacion, GETDATE())),
    FechaCreacion      DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),
    EsActivo           BIT      DEFAULT 1
);

-- TABLA DE DIMENSIÓN: GEOGRAFÍA
-- Consolida información de países, territorios y almacenes
CREATE TABLE dim_Geografia
(
    GeografiaKey       INT IDENTITY (1,1) NOT NULL PRIMARY KEY,
    PaisID             NVARCHAR(3)        NOT NULL,
    Pais               NVARCHAR(50)       NOT NULL,
    TerritorioID       INT                NOT NULL,
    Territorio         NVARCHAR(50)       NOT NULL,
    Grupo              NVARCHAR(50)       NOT NULL,
    AlmacenID          INT,
    Almacen            NVARCHAR(50),
    FechaCreacion      DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),
    EsActivo           BIT      DEFAULT 1
);

-- TABLA DE DIMENSIÓN: TIEMPO
-- Dimensión temporal para análisis por períodos
CREATE TABLE dim_Tiempo
(
    TiempoKey       INT          NOT NULL PRIMARY KEY,
    Fecha           DATE         NOT NULL,
    Anio            INT          NOT NULL,
    Mes             INT          NOT NULL,
    Dia             INT          NOT NULL,
    Trimestre       INT          NOT NULL,
    Semana          INT          NOT NULL,
    DiaSemana       INT          NOT NULL,
    NombreMes       NVARCHAR(20) NOT NULL,
    NombreDiaSemana NVARCHAR(20) NOT NULL,
    EsFinDeSemana   BIT          NOT NULL,
    EsFeriado       BIT DEFAULT 0,
    PeriodoAnioMes  NVARCHAR(7)  NOT NULL -- Formato: YYYY-MM
);

-- TABLA DE HECHOS: VENTAS
-- Tabla principal de hechos con métricas de ventas
CREATE TABLE fact_Ventas
(
    VentaKey           BIGINT IDENTITY (1,1) NOT NULL PRIMARY KEY,
    -- Claves foráneas a dimensiones
    ProductoKey        INT                   NOT NULL,
    ClienteKey         INT                   NOT NULL,
    EmpleadoKey        INT                   NULL, -- Puede ser NULL si no hay vendedor asignado
    GeografiaKey       INT                   NOT NULL,
    FechaVentaKey      INT                   NOT NULL,
    FechaEnvioKey      INT                   NULL, -- Puede ser NULL si no se ha enviado

    -- Identificadores del sistema transaccional
    VentaID            INT                   NOT NULL,
    DetalleVentaID     INT                   NOT NULL,

    -- Métricas de ventas
    Cantidad           SMALLINT              NOT NULL,
    PrecioUnitario     MONEY                 NOT NULL,
    ImporteTotal       AS (Cantidad * PrecioUnitario) PERSISTED,

    -- Metadatos de ETL
    FechaCreacion      DATETIME DEFAULT GETDATE(),
    FechaActualizacion DATETIME DEFAULT GETDATE(),

    -- Claves foráneas
    CONSTRAINT FK_fact_Ventas_Producto
        FOREIGN KEY (ProductoKey) REFERENCES dim_Productos (ProductoKey),
    CONSTRAINT FK_fact_Ventas_Cliente
        FOREIGN KEY (ClienteKey) REFERENCES dim_Clientes (ClienteKey),
    CONSTRAINT FK_fact_Ventas_Empleado
        FOREIGN KEY (EmpleadoKey) REFERENCES dim_Empleados (EmpleadoKey),
    CONSTRAINT FK_fact_Ventas_Geografia
        FOREIGN KEY (GeografiaKey) REFERENCES dim_Geografia (GeografiaKey),
    CONSTRAINT FK_fact_Ventas_FechaVenta
        FOREIGN KEY (FechaVentaKey) REFERENCES dim_Tiempo (TiempoKey),
    CONSTRAINT FK_fact_Ventas_FechaEnvio
        FOREIGN KEY (FechaEnvioKey) REFERENCES dim_Tiempo (TiempoKey)
);

-- ====================================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ====================================================================

-- Índices en dimensiones
CREATE UNIQUE INDEX IX_dim_Productos_ProductoID ON dim_Productos (ProductoID);
CREATE UNIQUE INDEX IX_dim_Clientes_ClienteID ON dim_Clientes (ClienteID);
CREATE UNIQUE INDEX IX_dim_Empleados_EmpleadoID ON dim_Empleados (EmpleadoID);
CREATE INDEX IX_dim_Geografia_PaisID ON dim_Geografia (PaisID);
CREATE INDEX IX_dim_Geografia_TerritorioID ON dim_Geografia (TerritorioID);
CREATE UNIQUE INDEX IX_dim_Tiempo_Fecha ON dim_Tiempo (Fecha);

-- Índices en tabla de hechos
CREATE INDEX IX_fact_Ventas_ProductoKey ON fact_Ventas (ProductoKey);
CREATE INDEX IX_fact_Ventas_ClienteKey ON fact_Ventas (ClienteKey);
CREATE INDEX IX_fact_Ventas_EmpleadoKey ON fact_Ventas (EmpleadoKey);
CREATE INDEX IX_fact_Ventas_GeografiaKey ON fact_Ventas (GeografiaKey);
CREATE INDEX IX_fact_Ventas_FechaVentaKey ON fact_Ventas (FechaVentaKey);
CREATE INDEX IX_fact_Ventas_VentaID_DetalleVentaID ON fact_Ventas (VentaID, DetalleVentaID);