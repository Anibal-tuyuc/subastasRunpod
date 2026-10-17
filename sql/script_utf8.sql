USE [master]
GO
/****** Objeto: Database [subastas_privadas] Fecha de script: 26/09/2026 10:27:03 ******/
CREATE DATABASE [subastas_privadas]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'subastas_privadas', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.SQLEXPRESS\MSSQL\DATA\subastas_privadas.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'subastas_privadas_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL17.SQLEXPRESS\MSSQL\DATA\subastas_privadas_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [subastas_privadas] SET COMPATIBILITY_LEVEL = 170
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [subastas_privadas].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [subastas_privadas] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [subastas_privadas] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [subastas_privadas] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [subastas_privadas] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [subastas_privadas] SET ARITHABORT OFF 
GO
ALTER DATABASE [subastas_privadas] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [subastas_privadas] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [subastas_privadas] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [subastas_privadas] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [subastas_privadas] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [subastas_privadas] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [subastas_privadas] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [subastas_privadas] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [subastas_privadas] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [subastas_privadas] SET  ENABLE_BROKER 
GO
ALTER DATABASE [subastas_privadas] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [subastas_privadas] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [subastas_privadas] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [subastas_privadas] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [subastas_privadas] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [subastas_privadas] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [subastas_privadas] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [subastas_privadas] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [subastas_privadas] SET  MULTI_USER 
GO
ALTER DATABASE [subastas_privadas] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [subastas_privadas] SET DB_CHAINING OFF 
GO
ALTER DATABASE [subastas_privadas] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [subastas_privadas] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [subastas_privadas] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [subastas_privadas] SET OPTIMIZED_LOCKING = OFF 
GO
ALTER DATABASE [subastas_privadas] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [subastas_privadas] SET QUERY_STORE = ON
GO
ALTER DATABASE [subastas_privadas] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [subastas_privadas]
GO
/****** Objeto: Table [dbo].[Adjudicaciones] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Adjudicaciones](
	[id_subasta] [int] NOT NULL,
	[id_puja_ganadora] [int] NOT NULL,
	[id_usuario_ganador] [int] NOT NULL,
	[monto_adjudicado] [decimal](15, 2) NOT NULL,
	[fecha_adjudicacion] [datetime2](3) NOT NULL,
	[supero_reserva] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_subasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_puja_ganadora] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Alertas_Fraude] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Alertas_Fraude](
	[id_alerta] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario_sospechoso] [int] NULL,
	[tipo_alerta] [varchar](30) NOT NULL,
	[severidad] [varchar](15) NOT NULL,
	[descripcion] [text] NOT NULL,
	[evidencia] [nvarchar](max) NULL,
	[fecha_deteccion] [datetime] NOT NULL,
	[id_usuario_revisor] [int] NULL,
	[estado] [varchar](15) NOT NULL,
	[fecha_resolucion] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_alerta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Articulos] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Articulos](
	[id_articulo] [int] IDENTITY(1,1) NOT NULL,
	[id_vendedor] [int] NOT NULL,
	[id_categoria] [int] NOT NULL,
	[id_estado_fisico] [tinyint] NOT NULL,
	[id_estado_articulo] [tinyint] NOT NULL,
	[codigo_moneda] [char](3) NOT NULL,
	[titulo] [varchar](150) NOT NULL,
	[descripcion] [text] NOT NULL,
	[anio_fabricacion] [smallint] NULL,
	[procedencia] [varchar](255) NULL,
	[precio_base_reserva] [decimal](15, 2) NOT NULL,
	[fecha_ingreso] [datetime] NOT NULL,
	[id_usuario_validador] [int] NULL,
	[fecha_validacion] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_articulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Auditoria_Pujas] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Auditoria_Pujas](
	[id_auditoria] [bigint] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_puja] [int] NULL,
	[id_resultado] [tinyint] NOT NULL,
	[monto_intento] [decimal](15, 2) NOT NULL,
	[puja_maxima_al_momento] [decimal](15, 2) NOT NULL,
	[fecha_hora_intento] [datetime2](3) NOT NULL,
	[ip_origen] [varbinary](16) NOT NULL,
	[user_agent] [varchar](255) NULL,
	[id_sesion] [char](36) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_auditoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Categorias] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Categorias](
	[id_categoria] [int] IDENTITY(1,1) NOT NULL,
	[id_categoria_padre] [int] NULL,
	[nombre] [varchar](100) NOT NULL,
	[descripcion] [text] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_categoria] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_categoria_padre] ASC,
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Certificados_Autenticidad] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Certificados_Autenticidad](
	[id_certificado] [int] IDENTITY(1,1) NOT NULL,
	[id_articulo] [int] NOT NULL,
	[id_entidad_emisora] [int] NOT NULL,
	[numero_registro] [varchar](100) NOT NULL,
	[fecha_emision] [date] NOT NULL,
	[fecha_vencimiento] [date] NULL,
	[url_documento] [varchar](255) NOT NULL,
	[hash_documento] [char](64) NULL,
	[verificado_por_plataforma] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_certificado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_entidad_emisora] ASC,
	[numero_registro] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Depositos_Garantia] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Depositos_Garantia](
	[id_deposito] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_metodo_pago] [int] NOT NULL,
	[monto] [decimal](15, 2) NOT NULL,
	[fecha_deposito] [datetime] NOT NULL,
	[estado] [varchar](20) NOT NULL,
	[fecha_liberacion] [datetime] NULL,
	[referencia_externa] [varchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_deposito] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC,
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Direcciones] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Direcciones](
	[id_direccion] [int] IDENTITY(1,1) NOT NULL,
	[id_usuario] [int] NOT NULL,
	[tipo] [varchar](20) NOT NULL,
	[calle] [varchar](150) NOT NULL,
	[ciudad] [varchar](100) NOT NULL,
	[estado_provincia] [varchar](100) NULL,
	[codigo_postal] [varchar](15) NULL,
	[pais] [char](2) NOT NULL,
	[es_principal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_direccion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Documentos_Identidad] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Documentos_Identidad](
	[id_documento] [int] IDENTITY(1,1) NOT NULL,
	[id_usuario] [int] NOT NULL,
	[tipo_documento] [varchar](20) NOT NULL,
	[numero_documento] [varchar](50) NOT NULL,
	[pais_emision] [char](2) NOT NULL,
	[fecha_vencimiento] [date] NULL,
	[url_archivo] [varchar](255) NOT NULL,
	[fecha_carga] [datetime] NOT NULL,
	[id_usuario_revisor] [int] NULL,
	[fecha_revision] [datetime] NULL,
	[aprobado] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_documento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[tipo_documento] ASC,
	[numero_documento] ASC,
	[pais_emision] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Entidades_Certificadoras] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Entidades_Certificadoras](
	[id_entidad_emisora] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [varchar](150) NOT NULL,
	[pais] [char](2) NULL,
	[sitio_web] [varchar](255) NULL,
	[acreditada] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_entidad_emisora] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Envios] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Envios](
	[id_envio] [int] IDENTITY(1,1) NOT NULL,
	[id_orden] [int] NOT NULL,
	[id_direccion] [int] NOT NULL,
	[transportista] [varchar](100) NULL,
	[numero_guia] [varchar](100) NULL,
	[asegurado] [bit] NOT NULL,
	[monto_seguro] [decimal](15, 2) NULL,
	[fecha_despacho] [datetime] NULL,
	[fecha_entrega] [datetime] NULL,
	[estado] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_envio] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Articulo] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Articulo](
	[id_estado_articulo] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_articulo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Fisicos] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Fisicos](
	[id_estado_fisico] [tinyint] NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[descripcion] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_fisico] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Pago] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Pago](
	[id_estado_pago] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_pago] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Puja] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Puja](
	[id_estado_puja] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_puja] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Subasta] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Subasta](
	[id_estado_subasta] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
	[es_terminal] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_subasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Estados_Verificacion] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Estados_Verificacion](
	[id_estado_verificacion] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
	[permite_pujar] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_estado_verificacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Imagenes_Articulo] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Imagenes_Articulo](
	[id_imagen] [int] IDENTITY(1,1) NOT NULL,
	[id_articulo] [int] NOT NULL,
	[url] [varchar](255) NOT NULL,
	[descripcion] [varchar](200) NULL,
	[orden] [tinyint] NOT NULL,
	[es_portada] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_imagen] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_articulo] ASC,
	[orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Invitaciones_Subasta] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Invitaciones_Subasta](
	[id_invitacion] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_usuario_invita] [int] NOT NULL,
	[fecha_invitacion] [datetime] NOT NULL,
	[fecha_aceptacion] [datetime] NULL,
	[estado] [varchar](20) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_invitacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC,
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Metodos_Pago_Usuario] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Metodos_Pago_Usuario](
	[id_metodo_pago] [int] IDENTITY(1,1) NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_tipo_metodo] [tinyint] NOT NULL,
	[token_proveedor] [varchar](255) NOT NULL,
	[ultimos_digitos] [char](4) NULL,
	[alias] [varchar](50) NULL,
	[verificado] [bit] NOT NULL,
	[es_predeterminado] [bit] NOT NULL,
	[fecha_alta] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_metodo_pago] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Monedas] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Monedas](
	[codigo_moneda] [char](3) NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[simbolo] [varchar](5) NOT NULL,
	[decimales] [tinyint] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[codigo_moneda] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Ordenes_Pago] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ordenes_Pago](
	[id_orden] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario_ganador] [int] NOT NULL,
	[id_estado_pago] [tinyint] NOT NULL,
	[codigo_moneda] [char](3) NOT NULL,
	[monto_adjudicado] [decimal](15, 2) NOT NULL,
	[comision_comprador] [decimal](15, 2) NOT NULL,
	[comision_vendedor] [decimal](15, 2) NOT NULL,
	[impuestos] [decimal](15, 2) NOT NULL,
	[deposito_aplicado] [decimal](15, 2) NOT NULL,
	[total_a_pagar]  AS ((([monto_adjudicado]+[comision_comprador])+[impuestos])-[deposito_aplicado]) PERSISTED,
	[neto_vendedor]  AS ([monto_adjudicado]-[comision_vendedor]) PERSISTED,
	[fecha_generacion] [datetime] NOT NULL,
	[fecha_vencimiento] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_orden] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Politicas_Comision] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Politicas_Comision](
	[id_politica] [int] IDENTITY(1,1) NOT NULL,
	[id_categoria] [int] NULL,
	[nombre] [varchar](100) NOT NULL,
	[porcentaje_comprador] [decimal](5, 2) NOT NULL,
	[porcentaje_vendedor] [decimal](5, 2) NOT NULL,
	[comision_minima] [decimal](15, 2) NOT NULL,
	[vigente_desde] [date] NOT NULL,
	[vigente_hasta] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[id_politica] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Pujas] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pujas](
	[id_puja] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario] [int] NOT NULL,
	[id_estado_puja] [tinyint] NOT NULL,
	[monto_oferta] [decimal](15, 2) NOT NULL,
	[fecha_hora_puja] [datetime2](3) NOT NULL,
	[es_automatica] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_puja] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC,
	[monto_oferta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Pujas_Automaticas] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Pujas_Automaticas](
	[id_puja_automatica] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[id_usuario] [int] NOT NULL,
	[monto_maximo] [decimal](15, 2) NOT NULL,
	[activa] [bit] NOT NULL,
	[fecha_configuracion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_puja_automatica] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC,
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Reglas_Incremento] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Reglas_Incremento](
	[id_regla] [int] IDENTITY(1,1) NOT NULL,
	[id_subasta] [int] NOT NULL,
	[monto_desde] [decimal](15, 2) NOT NULL,
	[monto_hasta] [decimal](15, 2) NULL,
	[incremento_minimo] [decimal](10, 2) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_regla] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[id_subasta] ASC,
	[monto_desde] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Resultados_Intento] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Resultados_Intento](
	[id_resultado] [tinyint] NOT NULL,
	[codigo] [varchar](40) NOT NULL,
	[descripcion] [varchar](150) NOT NULL,
	[es_exitoso] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_resultado] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[codigo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Roles] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Roles](
	[id_rol] [tinyint] NOT NULL,
	[nombre] [varchar](30) NOT NULL,
	[descripcion] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_rol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Subastas] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Subastas](
	[id_subasta] [int] IDENTITY(1,1) NOT NULL,
	[id_articulo] [int] NOT NULL,
	[id_estado_subasta] [tinyint] NOT NULL,
	[id_politica] [int] NOT NULL,
	[id_usuario_creador] [int] NOT NULL,
	[fecha_hora_inicio] [datetime2](3) NOT NULL,
	[fecha_hora_fin] [datetime2](3) NOT NULL,
	[extension_anti_sniping_seg] [smallint] NOT NULL,
	[puja_actual_maxima] [decimal](15, 2) NOT NULL,
	[id_puja_lider] [int] NULL,
	[total_pujas] [int] NOT NULL,
	[version] [int] NOT NULL,
	[fecha_creacion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_subasta] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Tasaciones] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tasaciones](
	[id_tasacion] [int] IDENTITY(1,1) NOT NULL,
	[id_articulo] [int] NOT NULL,
	[id_usuario_tasador] [int] NOT NULL,
	[valor_estimado_min] [decimal](15, 2) NOT NULL,
	[valor_estimado_max] [decimal](15, 2) NOT NULL,
	[fecha_tasacion] [date] NOT NULL,
	[observaciones] [text] NULL,
	[url_informe] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_tasacion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Tipos_Metodo_Pago] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tipos_Metodo_Pago](
	[id_tipo_metodo] [tinyint] NOT NULL,
	[nombre] [varchar](50) NOT NULL,
	[requiere_verificacion] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_tipo_metodo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[nombre] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Transacciones_Pago] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Transacciones_Pago](
	[id_transaccion] [int] IDENTITY(1,1) NOT NULL,
	[id_orden] [int] NOT NULL,
	[id_metodo_pago] [int] NOT NULL,
	[monto] [decimal](15, 2) NOT NULL,
	[fecha_transaccion] [datetime] NOT NULL,
	[referencia_pasarela] [varchar](100) NULL,
	[resultado] [varchar](20) NOT NULL,
	[mensaje_pasarela] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[id_transaccion] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[referencia_pasarela] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Usuario_Roles] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Usuario_Roles](
	[id_usuario] [int] NOT NULL,
	[id_rol] [tinyint] NOT NULL,
	[fecha_asignacion] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC,
	[id_rol] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Table [dbo].[Usuarios] Fecha de script: 26/09/2026 10:27:04 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Usuarios](
	[id_usuario] [int] IDENTITY(1,1) NOT NULL,
	[nombre] [varchar](100) NOT NULL,
	[apellido] [varchar](100) NOT NULL,
	[email] [varchar](150) NOT NULL,
	[telefono] [varchar](20) NULL,
	[password_hash] [char](60) NOT NULL,
	[id_estado_verificacion] [tinyint] NOT NULL,
	[fecha_registro] [datetime] NOT NULL,
	[fecha_ultimo_acceso] [datetime] NULL,
	[activo] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id_usuario] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[email] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Objeto: Index [idx_aud_subasta_fecha] Fecha de script: 26/09/2026 10:27:04 ******/
CREATE NONCLUSTERED INDEX [idx_aud_subasta_fecha] ON [dbo].[Auditoria_Pujas]
(
	[id_subasta] ASC,
	[fecha_hora_intento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [idx_aud_usuario_fecha] Fecha de script: 26/09/2026 10:27:04 ******/
CREATE NONCLUSTERED INDEX [idx_aud_usuario_fecha] ON [dbo].[Auditoria_Pujas]
(
	[id_usuario] ASC,
	[fecha_hora_intento] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [idx_puja_subasta_monto] Fecha de script: 26/09/2026 10:27:04 ******/
CREATE NONCLUSTERED INDEX [idx_puja_subasta_monto] ON [dbo].[Pujas]
(
	[id_subasta] ASC,
	[monto_oferta] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
/****** Objeto: Index [idx_subasta_estado_fin] Fecha de script: 26/09/2026 10:27:04 ******/
CREATE NONCLUSTERED INDEX [idx_subasta_estado_fin] ON [dbo].[Subastas]
(
	[id_estado_subasta] ASC,
	[fecha_hora_fin] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Adjudicaciones] ADD  DEFAULT (sysdatetime()) FOR [fecha_adjudicacion]
GO
ALTER TABLE [dbo].[Alertas_Fraude] ADD  DEFAULT (getdate()) FOR [fecha_deteccion]
GO
ALTER TABLE [dbo].[Alertas_Fraude] ADD  DEFAULT ('Abierta') FOR [estado]
GO
ALTER TABLE [dbo].[Articulos] ADD  DEFAULT (getdate()) FOR [fecha_ingreso]
GO
ALTER TABLE [dbo].[Auditoria_Pujas] ADD  DEFAULT (sysdatetime()) FOR [fecha_hora_intento]
GO
ALTER TABLE [dbo].[Certificados_Autenticidad] ADD  DEFAULT ((0)) FOR [verificado_por_plataforma]
GO
ALTER TABLE [dbo].[Depositos_Garantia] ADD  DEFAULT (getdate()) FOR [fecha_deposito]
GO
ALTER TABLE [dbo].[Depositos_Garantia] ADD  DEFAULT ('Retenido') FOR [estado]
GO
ALTER TABLE [dbo].[Direcciones] ADD  DEFAULT ((0)) FOR [es_principal]
GO
ALTER TABLE [dbo].[Documentos_Identidad] ADD  DEFAULT (getdate()) FOR [fecha_carga]
GO
ALTER TABLE [dbo].[Entidades_Certificadoras] ADD  DEFAULT ((1)) FOR [acreditada]
GO
ALTER TABLE [dbo].[Envios] ADD  DEFAULT ((1)) FOR [asegurado]
GO
ALTER TABLE [dbo].[Envios] ADD  DEFAULT ('Preparando') FOR [estado]
GO
ALTER TABLE [dbo].[Estados_Subasta] ADD  DEFAULT ((0)) FOR [es_terminal]
GO
ALTER TABLE [dbo].[Estados_Verificacion] ADD  DEFAULT ((0)) FOR [permite_pujar]
GO
ALTER TABLE [dbo].[Imagenes_Articulo] ADD  DEFAULT ((1)) FOR [orden]
GO
ALTER TABLE [dbo].[Imagenes_Articulo] ADD  DEFAULT ((0)) FOR [es_portada]
GO
ALTER TABLE [dbo].[Invitaciones_Subasta] ADD  DEFAULT (getdate()) FOR [fecha_invitacion]
GO
ALTER TABLE [dbo].[Invitaciones_Subasta] ADD  DEFAULT ('Pendiente') FOR [estado]
GO
ALTER TABLE [dbo].[Metodos_Pago_Usuario] ADD  DEFAULT ((0)) FOR [verificado]
GO
ALTER TABLE [dbo].[Metodos_Pago_Usuario] ADD  DEFAULT ((0)) FOR [es_predeterminado]
GO
ALTER TABLE [dbo].[Metodos_Pago_Usuario] ADD  DEFAULT (getdate()) FOR [fecha_alta]
GO
ALTER TABLE [dbo].[Monedas] ADD  DEFAULT ((2)) FOR [decimales]
GO
ALTER TABLE [dbo].[Ordenes_Pago] ADD  DEFAULT ((0)) FOR [impuestos]
GO
ALTER TABLE [dbo].[Ordenes_Pago] ADD  DEFAULT ((0)) FOR [deposito_aplicado]
GO
ALTER TABLE [dbo].[Ordenes_Pago] ADD  DEFAULT (getdate()) FOR [fecha_generacion]
GO
ALTER TABLE [dbo].[Politicas_Comision] ADD  DEFAULT ((0)) FOR [comision_minima]
GO
ALTER TABLE [dbo].[Pujas] ADD  DEFAULT (sysdatetime()) FOR [fecha_hora_puja]
GO
ALTER TABLE [dbo].[Pujas] ADD  DEFAULT ((0)) FOR [es_automatica]
GO
ALTER TABLE [dbo].[Pujas_Automaticas] ADD  DEFAULT ((1)) FOR [activa]
GO
ALTER TABLE [dbo].[Pujas_Automaticas] ADD  DEFAULT (getdate()) FOR [fecha_configuracion]
GO
ALTER TABLE [dbo].[Subastas] ADD  DEFAULT ((0)) FOR [extension_anti_sniping_seg]
GO
ALTER TABLE [dbo].[Subastas] ADD  DEFAULT ((0.00)) FOR [puja_actual_maxima]
GO
ALTER TABLE [dbo].[Subastas] ADD  DEFAULT ((0)) FOR [total_pujas]
GO
ALTER TABLE [dbo].[Subastas] ADD  DEFAULT ((0)) FOR [version]
GO
ALTER TABLE [dbo].[Subastas] ADD  DEFAULT (getdate()) FOR [fecha_creacion]
GO
ALTER TABLE [dbo].[Tipos_Metodo_Pago] ADD  DEFAULT ((1)) FOR [requiere_verificacion]
GO
ALTER TABLE [dbo].[Transacciones_Pago] ADD  DEFAULT (getdate()) FOR [fecha_transaccion]
GO
ALTER TABLE [dbo].[Usuario_Roles] ADD  DEFAULT (getdate()) FOR [fecha_asignacion]
GO
ALTER TABLE [dbo].[Usuarios] ADD  DEFAULT (getdate()) FOR [fecha_registro]
GO
ALTER TABLE [dbo].[Usuarios] ADD  DEFAULT ((1)) FOR [activo]
GO
ALTER TABLE [dbo].[Adjudicaciones]  WITH CHECK ADD FOREIGN KEY([id_puja_ganadora])
REFERENCES [dbo].[Pujas] ([id_puja])
GO
ALTER TABLE [dbo].[Adjudicaciones]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Adjudicaciones]  WITH CHECK ADD FOREIGN KEY([id_usuario_ganador])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD FOREIGN KEY([id_usuario_sospechoso])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD FOREIGN KEY([id_usuario_revisor])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([codigo_moneda])
REFERENCES [dbo].[Monedas] ([codigo_moneda])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([id_categoria])
REFERENCES [dbo].[Categorias] ([id_categoria])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([id_estado_fisico])
REFERENCES [dbo].[Estados_Fisicos] ([id_estado_fisico])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([id_estado_articulo])
REFERENCES [dbo].[Estados_Articulo] ([id_estado_articulo])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([id_usuario_validador])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD FOREIGN KEY([id_vendedor])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Auditoria_Pujas]  WITH CHECK ADD FOREIGN KEY([id_puja])
REFERENCES [dbo].[Pujas] ([id_puja])
GO
ALTER TABLE [dbo].[Auditoria_Pujas]  WITH CHECK ADD FOREIGN KEY([id_resultado])
REFERENCES [dbo].[Resultados_Intento] ([id_resultado])
GO
ALTER TABLE [dbo].[Auditoria_Pujas]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Auditoria_Pujas]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Categorias]  WITH CHECK ADD FOREIGN KEY([id_categoria_padre])
REFERENCES [dbo].[Categorias] ([id_categoria])
GO
ALTER TABLE [dbo].[Certificados_Autenticidad]  WITH CHECK ADD FOREIGN KEY([id_articulo])
REFERENCES [dbo].[Articulos] ([id_articulo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Certificados_Autenticidad]  WITH CHECK ADD FOREIGN KEY([id_entidad_emisora])
REFERENCES [dbo].[Entidades_Certificadoras] ([id_entidad_emisora])
GO
ALTER TABLE [dbo].[Depositos_Garantia]  WITH CHECK ADD FOREIGN KEY([id_metodo_pago])
REFERENCES [dbo].[Metodos_Pago_Usuario] ([id_metodo_pago])
GO
ALTER TABLE [dbo].[Depositos_Garantia]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Depositos_Garantia]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Direcciones]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Documentos_Identidad]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Documentos_Identidad]  WITH CHECK ADD FOREIGN KEY([id_usuario_revisor])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Envios]  WITH CHECK ADD FOREIGN KEY([id_direccion])
REFERENCES [dbo].[Direcciones] ([id_direccion])
GO
ALTER TABLE [dbo].[Envios]  WITH CHECK ADD FOREIGN KEY([id_orden])
REFERENCES [dbo].[Ordenes_Pago] ([id_orden])
GO
ALTER TABLE [dbo].[Imagenes_Articulo]  WITH CHECK ADD FOREIGN KEY([id_articulo])
REFERENCES [dbo].[Articulos] ([id_articulo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Invitaciones_Subasta]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Invitaciones_Subasta]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Invitaciones_Subasta]  WITH CHECK ADD FOREIGN KEY([id_usuario_invita])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Metodos_Pago_Usuario]  WITH CHECK ADD FOREIGN KEY([id_tipo_metodo])
REFERENCES [dbo].[Tipos_Metodo_Pago] ([id_tipo_metodo])
GO
ALTER TABLE [dbo].[Metodos_Pago_Usuario]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Ordenes_Pago]  WITH CHECK ADD FOREIGN KEY([codigo_moneda])
REFERENCES [dbo].[Monedas] ([codigo_moneda])
GO
ALTER TABLE [dbo].[Ordenes_Pago]  WITH CHECK ADD FOREIGN KEY([id_estado_pago])
REFERENCES [dbo].[Estados_Pago] ([id_estado_pago])
GO
ALTER TABLE [dbo].[Ordenes_Pago]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Adjudicaciones] ([id_subasta])
GO
ALTER TABLE [dbo].[Ordenes_Pago]  WITH CHECK ADD FOREIGN KEY([id_usuario_ganador])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Politicas_Comision]  WITH CHECK ADD FOREIGN KEY([id_categoria])
REFERENCES [dbo].[Categorias] ([id_categoria])
GO
ALTER TABLE [dbo].[Pujas]  WITH CHECK ADD FOREIGN KEY([id_estado_puja])
REFERENCES [dbo].[Estados_Puja] ([id_estado_puja])
GO
ALTER TABLE [dbo].[Pujas]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Pujas]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Pujas_Automaticas]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
GO
ALTER TABLE [dbo].[Pujas_Automaticas]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Reglas_Incremento]  WITH CHECK ADD FOREIGN KEY([id_subasta])
REFERENCES [dbo].[Subastas] ([id_subasta])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD FOREIGN KEY([id_articulo])
REFERENCES [dbo].[Articulos] ([id_articulo])
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD FOREIGN KEY([id_estado_subasta])
REFERENCES [dbo].[Estados_Subasta] ([id_estado_subasta])
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD FOREIGN KEY([id_politica])
REFERENCES [dbo].[Politicas_Comision] ([id_politica])
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD FOREIGN KEY([id_puja_lider])
REFERENCES [dbo].[Pujas] ([id_puja])
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD FOREIGN KEY([id_usuario_creador])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Tasaciones]  WITH CHECK ADD FOREIGN KEY([id_articulo])
REFERENCES [dbo].[Articulos] ([id_articulo])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Tasaciones]  WITH CHECK ADD FOREIGN KEY([id_usuario_tasador])
REFERENCES [dbo].[Usuarios] ([id_usuario])
GO
ALTER TABLE [dbo].[Transacciones_Pago]  WITH CHECK ADD FOREIGN KEY([id_metodo_pago])
REFERENCES [dbo].[Metodos_Pago_Usuario] ([id_metodo_pago])
GO
ALTER TABLE [dbo].[Transacciones_Pago]  WITH CHECK ADD FOREIGN KEY([id_orden])
REFERENCES [dbo].[Ordenes_Pago] ([id_orden])
GO
ALTER TABLE [dbo].[Usuario_Roles]  WITH CHECK ADD FOREIGN KEY([id_rol])
REFERENCES [dbo].[Roles] ([id_rol])
GO
ALTER TABLE [dbo].[Usuario_Roles]  WITH CHECK ADD FOREIGN KEY([id_usuario])
REFERENCES [dbo].[Usuarios] ([id_usuario])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Usuarios]  WITH CHECK ADD FOREIGN KEY([id_estado_verificacion])
REFERENCES [dbo].[Estados_Verificacion] ([id_estado_verificacion])
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD CHECK  (([estado]='Descartada' OR [estado]='Confirmada' OR [estado]='En revisión' OR [estado]='Abierta'))
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD CHECK  (([severidad]='Crítica' OR [severidad]='Alta' OR [severidad]='Media' OR [severidad]='Baja'))
GO
ALTER TABLE [dbo].[Alertas_Fraude]  WITH CHECK ADD CHECK  (([tipo_alerta]='Otro' OR [tipo_alerta]='Colusión' OR [tipo_alerta]='Retracción reiterada' OR [tipo_alerta]='IP compartida' OR [tipo_alerta]='Ráfaga de pujas' OR [tipo_alerta]='Shill bidding'))
GO
ALTER TABLE [dbo].[Articulos]  WITH CHECK ADD CHECK  (([precio_base_reserva]>(0)))
GO
ALTER TABLE [dbo].[Depositos_Garantia]  WITH CHECK ADD CHECK  (([estado]='Ejecutado' OR [estado]='Devuelto' OR [estado]='Aplicado' OR [estado]='Retenido'))
GO
ALTER TABLE [dbo].[Depositos_Garantia]  WITH CHECK ADD CHECK  (([monto]>(0)))
GO
ALTER TABLE [dbo].[Direcciones]  WITH CHECK ADD CHECK  (([tipo]='Envio' OR [tipo]='Facturacion'))
GO
ALTER TABLE [dbo].[Documentos_Identidad]  WITH CHECK ADD CHECK  (([tipo_documento]='Otro' OR [tipo_documento]='RFC' OR [tipo_documento]='Licencia' OR [tipo_documento]='DNI' OR [tipo_documento]='Pasaporte'))
GO
ALTER TABLE [dbo].[Envios]  WITH CHECK ADD CHECK  (([estado]='Incidencia' OR [estado]='Entregado' OR [estado]='En tránsito' OR [estado]='Preparando'))
GO
ALTER TABLE [dbo].[Invitaciones_Subasta]  WITH CHECK ADD CHECK  (([estado]='Revocada' OR [estado]='Rechazada' OR [estado]='Aceptada' OR [estado]='Pendiente'))
GO
ALTER TABLE [dbo].[Politicas_Comision]  WITH CHECK ADD CHECK  (([porcentaje_comprador]>=(0) AND [porcentaje_comprador]<=(100)))
GO
ALTER TABLE [dbo].[Politicas_Comision]  WITH CHECK ADD CHECK  (([porcentaje_vendedor]>=(0) AND [porcentaje_vendedor]<=(100)))
GO
ALTER TABLE [dbo].[Pujas]  WITH CHECK ADD CHECK  (([monto_oferta]>(0)))
GO
ALTER TABLE [dbo].[Pujas_Automaticas]  WITH CHECK ADD CHECK  (([monto_maximo]>(0)))
GO
ALTER TABLE [dbo].[Reglas_Incremento]  WITH CHECK ADD CHECK  (([incremento_minimo]>(0)))
GO
ALTER TABLE [dbo].[Reglas_Incremento]  WITH CHECK ADD CHECK  (([monto_hasta] IS NULL OR [monto_hasta]>[monto_desde]))
GO
ALTER TABLE [dbo].[Subastas]  WITH CHECK ADD CHECK  (([fecha_hora_fin]>[fecha_hora_inicio]))
GO
ALTER TABLE [dbo].[Tasaciones]  WITH CHECK ADD CHECK  (([valor_estimado_max]>=[valor_estimado_min]))
GO
ALTER TABLE [dbo].[Transacciones_Pago]  WITH CHECK ADD CHECK  (([monto]>(0)))
GO
ALTER TABLE [dbo].[Transacciones_Pago]  WITH CHECK ADD CHECK  (([resultado]='Reversada' OR [resultado]='Pendiente' OR [resultado]='Rechazada' OR [resultado]='Aprobada'))
GO
USE [master]
GO
ALTER DATABASE [subastas_privadas] SET  READ_WRITE 
GO
