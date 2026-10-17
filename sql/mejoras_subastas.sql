USE [subastas_privadas]
GO

/* =========================================================================
   1. MEJORAS DE UBICACIÓN Y ALMACENAJE
   ========================================================================= */

-- Crear tabla para registrar las ubicaciones físicas (Bóvedas, Bancos, etc.)
CREATE TABLE [dbo].[Ubicaciones_Almacenaje](
    [id_ubicacion] [int] IDENTITY(1,1) NOT NULL,
    [nombre_ubicacion] [varchar](150) NOT NULL,
    [tipo_ubicacion] [varchar](50) NOT NULL, -- Ej: 'Bóveda Bancaria', 'Almacén Privado'
    [institucion] [varchar](100) NULL,       -- Ej: 'Banco Nacional'
    [direccion] [varchar](255) NULL,
    [nivel_seguridad] [varchar](50) NULL,    -- Ej: 'Alta', 'Máxima'
    [contacto_responsable] [varchar](100) NULL,
    [notas_acceso] [text] NULL,
    CONSTRAINT [PK_Ubicaciones_Almacenaje] PRIMARY KEY CLUSTERED ([id_ubicacion] ASC)
) ON [PRIMARY]
GO

-- Agregar el campo a la tabla Articulos para saber en qué bóveda está
ALTER TABLE [dbo].[Articulos]
ADD [id_ubicacion_actual] [int] NULL;
GO

-- Crear la relación
ALTER TABLE [dbo].[Articulos] WITH CHECK ADD CONSTRAINT [FK_Articulos_Ubicacion]
FOREIGN KEY([id_ubicacion_actual]) REFERENCES [dbo].[Ubicaciones_Almacenaje] ([id_ubicacion])
GO


/* =========================================================================
   2. HISTORIAL / PEDIGREE DE LOS ARTÍCULOS
   ========================================================================= */

-- Tabla para guardar el valor especial, procedencia famosa o hechos clave
CREATE TABLE [dbo].[Historial_Pedigree_Articulos](
    [id_historial] [int] IDENTITY(1,1) NOT NULL,
    [id_articulo] [int] NOT NULL,
    [propietario_anterior_famoso] [varchar](150) NULL, -- Ej: 'Michael Jackson'
    [evento_destacado] [varchar](200) NULL,            -- Ej: 'Usado en el concierto de 1995'
    [fecha_evento] [date] NULL,
    [descripcion_historica] [text] NOT NULL,
    [valor_historico_estimado] [decimal](15,2) NULL,   -- Plusvalía por el pedigree
    [evidencia_url] [varchar](255) NULL,               -- Link a fotos o videos que lo comprueben
    CONSTRAINT [PK_Historial_Pedigree] PRIMARY KEY CLUSTERED ([id_historial] ASC)
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[Historial_Pedigree_Articulos] WITH CHECK ADD CONSTRAINT [FK_Historial_Articulo]
FOREIGN KEY([id_articulo]) REFERENCES [dbo].[Articulos] ([id_articulo])
GO


/* =========================================================================
   3. OPTIMIZACIÓN DE BÚSQUEDAS (TABLA CACHÉ / INDEXADA)
   ========================================================================= */

-- Esta tabla sirve como un catálogo "plano". Cuando alguien busca una subasta,
-- lee de aquí en lugar de unir 4 o 5 tablas principales, ahorrando mucha RAM y CPU.
CREATE TABLE [dbo].[Catalogo_Busquedas_Caché](
    [id_busqueda] [int] IDENTITY(1,1) NOT NULL,
    [id_subasta] [int] NOT NULL,
    [id_articulo] [int] NOT NULL,
    [titulo_articulo] [varchar](150) NOT NULL,
    [categoria_nombre] [varchar](100) NOT NULL,
    [fecha_inicio] [datetime] NOT NULL,
    [fecha_fin] [datetime] NOT NULL,
    [precio_actual] [decimal](15, 2) NOT NULL,
    [estado_subasta] [varchar](20) NOT NULL,
    [palabras_clave] [varchar](500) NULL, -- Ej: "reloj oro rolex diamante 1990"
    [tiene_pedigree] [bit] DEFAULT 0 NOT NULL,
    CONSTRAINT [PK_Catalogo_Busquedas] PRIMARY KEY CLUSTERED ([id_busqueda] ASC)
) ON [PRIMARY]
GO

-- Índice optimizado para búsquedas por palabras y categoría
CREATE NONCLUSTERED INDEX [IX_Busquedas_Filtros] ON [dbo].[Catalogo_Busquedas_Caché]
(
    [estado_subasta] ASC,
    [categoria_nombre] ASC
)
INCLUDE([titulo_articulo], [precio_actual], [fecha_fin], [tiene_pedigree])
ON [PRIMARY]
GO

-- Índice optimizado para ordenar por fechas o subastas por terminar
CREATE NONCLUSTERED INDEX [IX_Busquedas_Fechas] ON [dbo].[Catalogo_Busquedas_Caché]
(
    [fecha_fin] ASC,
    [estado_subasta] ASC
)
INCLUDE([titulo_articulo], [precio_actual])
ON [PRIMARY]
GO