USE [subastas_privadas]
GO

/* =========================================================================
   0. PREPARAR DATOS MAESTROS
   ========================================================================= */

-- A. Insertar Monedas (Ignorar si ya existen)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Monedas] WHERE codigo_moneda = 'USD')
    INSERT INTO [dbo].[Monedas] (codigo_moneda, nombre, simbolo, decimales) VALUES ('USD', 'Dólar Estadounidense', '$', 2);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Monedas] WHERE codigo_moneda = 'EUR')
    INSERT INTO [dbo].[Monedas] (codigo_moneda, nombre, simbolo, decimales) VALUES ('EUR', 'Euro', '€', 2);
GO

-- B. Insertar Estados de Artículo y Físico (Ignorar si ya existen)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Estados_Articulo] WHERE id_estado_articulo = 1)
    INSERT INTO [dbo].[Estados_Articulo] (id_estado_articulo, nombre) VALUES (1, 'Activo/Disponible');

IF NOT EXISTS (SELECT 1 FROM [dbo].[Estados_Fisicos] WHERE id_estado_fisico = 1)
    INSERT INTO [dbo].[Estados_Fisicos] (id_estado_fisico, nombre, descripcion) VALUES (1, 'Excelente', 'Sin detalles');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Estados_Fisicos] WHERE id_estado_fisico = 2)
    INSERT INTO [dbo].[Estados_Fisicos] (id_estado_fisico, nombre, descripcion) VALUES (2, 'Bueno', 'Uso moderado');
GO

-- C. Insertar Estado de Verificación de Usuario
IF NOT EXISTS (SELECT 1 FROM [dbo].[Estados_Verificacion] WHERE id_estado_verificacion = 1)
    INSERT INTO [dbo].[Estados_Verificacion] (id_estado_verificacion, nombre, permite_pujar) VALUES (1, 'Verificado', 1);
GO

-- D. Insertar Categorias (Ignorar si ya existen)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Categorias] WHERE nombre = 'Instrumentos Musicales')
    INSERT INTO [dbo].[Categorias] (nombre, descripcion) VALUES ('Instrumentos Musicales', 'Todo tipo de instrumentos');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Categorias] WHERE nombre = 'Joyería y Relojes')
    INSERT INTO [dbo].[Categorias] (nombre, descripcion) VALUES ('Joyería y Relojes', 'Joyas de alto valor');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Categorias] WHERE nombre = 'Ropa de Colección')
    INSERT INTO [dbo].[Categorias] (nombre, descripcion) VALUES ('Ropa de Colección', 'Prendas históricas');
GO

-- E. Insertar Usuarios/Vendedores mínimos (Ignorar si ya existen)
IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE email = 'juan@test.com')
    INSERT INTO [dbo].[Usuarios] (nombre, apellido, email, password_hash, id_estado_verificacion, fecha_registro, activo)
    VALUES ('Juan', 'Perez', 'juan@test.com', 'hashejemplo', 1, GETDATE(), 1);
IF NOT EXISTS (SELECT 1 FROM [dbo].[Usuarios] WHERE email = 'ana@test.com')
    INSERT INTO [dbo].[Usuarios] (nombre, apellido, email, password_hash, id_estado_verificacion, fecha_registro, activo)
    VALUES ('Ana', 'Gomez', 'ana@test.com', 'hashejemplo', 1, GETDATE(), 1);
GO

/* =========================================================================
   1. INSERTAR DATOS DE PRUEBA: UBICACIONES DE ALMACENAJE
   ========================================================================= */
-- Limpiamos tabla antes por si intentaste correrlo antes
DELETE FROM [dbo].[Ubicaciones_Almacenaje];
DBCC CHECKIDENT ('[dbo].[Ubicaciones_Almacenaje]', RESEED, 0);

INSERT INTO [dbo].[Ubicaciones_Almacenaje]
([nombre_ubicacion], [tipo_ubicacion], [institucion], [direccion], [nivel_seguridad], [contacto_responsable], [notas_acceso])
VALUES
('Bóveda Principal Centro', 'Bóveda Bancaria', 'Banco Nacional', 'Av. Reforma 123, Piso -2', 'Máxima', 'Roberto Carlos', 'Acceso con doble biometría'),
('Caja de Seguridad 445', 'Caja de Seguridad', 'Banco Central', 'Calle 50 10-10, Sucursal Norte', 'Alta', 'Marta Gómez', 'Solo el titular y apoderado'),
('Almacén Climatizado A1', 'Almacén Privado', 'Seguridad Privada S.A.', 'Zona Industrial Bodega 8', 'Media-Alta', 'Carlos Pérez', 'Control de humedad 40%'),
('Bóveda Suiza', 'Bóveda Internacional', 'Swiss Bank Corp', 'Zurich, Suiza', 'Extrema', 'Hans Müller', 'Depósito para arte y joyas');
GO

/* =========================================================================
   2. INSERTAR DATOS DE PRUEBA: ARTÍCULOS
   ========================================================================= */
-- Variables para obtener IDs reales dinámicos
DECLARE @IdCatMusica INT = (SELECT MIN(id_categoria) FROM [dbo].[Categorias] WHERE nombre = 'Instrumentos Musicales');
DECLARE @IdCatJoyas INT = (SELECT MIN(id_categoria) FROM [dbo].[Categorias] WHERE nombre = 'Joyería y Relojes');
DECLARE @IdCatRopa INT = (SELECT MIN(id_categoria) FROM [dbo].[Categorias] WHERE nombre = 'Ropa de Colección');

DECLARE @IdEstFisico1 TINYINT = (SELECT MIN(id_estado_fisico) FROM [dbo].[Estados_Fisicos]);
DECLARE @IdEstFisico2 TINYINT = (SELECT MAX(id_estado_fisico) FROM [dbo].[Estados_Fisicos]);
DECLARE @IdEstArt TINYINT = (SELECT MIN(id_estado_articulo) FROM [dbo].[Estados_Articulo]);
DECLARE @IdUsuario INT = (SELECT MIN(id_usuario) FROM [dbo].[Usuarios]);

-- Limpiamos tablas dependientes primero
DELETE FROM [dbo].[Catalogo_Busquedas_Caché];
DELETE FROM [dbo].[Historial_Pedigree_Articulos];
-- Eliminamos solo los de prueba de articulos
DELETE FROM [dbo].[Articulos] WHERE titulo LIKE 'TEST_%';

-- Insertamos con un prefijo 'TEST_' para identificarlos
INSERT INTO [dbo].[Articulos]
([id_vendedor], [id_categoria], [id_estado_fisico], [id_estado_articulo], [codigo_moneda], [titulo], [descripcion], [anio_fabricacion], [procedencia], [precio_base_reserva], [fecha_ingreso], [id_ubicacion_actual])
VALUES
(@IdUsuario, @IdCatMusica, @IdEstFisico1, @IdEstArt, 'USD', 'TEST_Guitarra Eléctrica Fender', 'Guitarra color rojo, excelentes condiciones', 1965, 'Estados Unidos', 15000.00, GETDATE(), 3),
(@IdUsuario, @IdCatJoyas, @IdEstFisico1, @IdEstArt, 'USD', 'TEST_Reloj Rolex Daytona', 'Reloj de oro blanco 18k', 1990, 'Suiza', 25000.00, GETDATE(), 1),
(@IdUsuario, @IdCatRopa, @IdEstFisico1, @IdEstArt, 'USD', 'TEST_Chaqueta de Cuero Roja', 'Chaqueta original usada en videoclip', 1983, 'Estados Unidos', 50000.00, GETDATE(), 2),
(@IdUsuario, @IdCatJoyas, @IdEstFisico2, @IdEstArt, 'EUR', 'TEST_Collar de Diamantes Azules', 'Collar de la realeza europea del siglo XIX', 1880, 'Francia', 120000.00, GETDATE(), 4);
GO

/* =========================================================================
   3. INSERTAR DATOS DE PRUEBA: HISTORIAL / PEDIGREE Y CACHÉ
   ========================================================================= */
DECLARE @IdArt1 INT = (SELECT id_articulo FROM [dbo].[Articulos] WHERE titulo = 'TEST_Guitarra Eléctrica Fender');
DECLARE @IdArt2 INT = (SELECT id_articulo FROM [dbo].[Articulos] WHERE titulo = 'TEST_Reloj Rolex Daytona');
DECLARE @IdArt3 INT = (SELECT id_articulo FROM [dbo].[Articulos] WHERE titulo = 'TEST_Chaqueta de Cuero Roja');
DECLARE @IdArt4 INT = (SELECT id_articulo FROM [dbo].[Articulos] WHERE titulo = 'TEST_Collar de Diamantes Azules');

-- Insertamos Pedigree usando los IDs reales de la base de datos
INSERT INTO [dbo].[Historial_Pedigree_Articulos]
([id_articulo], [propietario_anterior_famoso], [evento_destacado], [fecha_evento], [descripcion_historica], [valor_historico_estimado], [evidencia_url])
VALUES
(@IdArt1, 'Jimi Hendrix', 'Concierto en Londres', '1967-05-12', 'Usada y firmada por el artista en el backstage.', 100000.00, 'https://ejemplo.com/hendrix_guitar.jpg'),
(@IdArt3, 'Michael Jackson', 'Grabación del videoclip Thriller', '1983-10-15', 'Una de las dos chaquetas originales utilizadas en el video.', 800000.00, 'https://ejemplo.com/mj_jacket_cert.pdf'),
(@IdArt4, 'Reina María Antonieta', 'Fiesta de la Corte', '1785-06-20', 'Joya perteneciente a la familia real francesa antes de la revolución.', 500000.00, 'https://ejemplo.com/collar_historia.pdf');

-- Insertamos Caché usando los IDs reales
INSERT INTO [dbo].[Catalogo_Busquedas_Caché]
([id_subasta], [id_articulo], [titulo_articulo], [categoria_nombre], [fecha_inicio], [fecha_fin], [precio_actual], [estado_subasta], [palabras_clave], [tiene_pedigree])
VALUES
(100, @IdArt1, 'TEST_Guitarra Eléctrica Fender', 'Instrumentos Musicales', DATEADD(DAY, -1, GETDATE()), DATEADD(DAY, 5, GETDATE()), 15500.00, 'Activa', 'guitarra fender hendrix 1965 electrica', 1),
(101, @IdArt2, 'TEST_Reloj Rolex Daytona', 'Joyería y Relojes', DATEADD(DAY, -2, GETDATE()), DATEADD(DAY, 2, GETDATE()), 28000.00, 'Activa', 'reloj rolex oro daytona 1990 suiza', 0),
(102, @IdArt3, 'TEST_Chaqueta de Cuero Roja', 'Ropa de Colección', DATEADD(DAY, -5, GETDATE()), DATEADD(HOUR, 2, GETDATE()), 125000.00, 'Activa', 'chaqueta michael jackson thriller cuero', 1),
(103, @IdArt4, 'TEST_Collar de Diamantes Azules', 'Joyería y Relojes', DATEADD(DAY, 1, GETDATE()), DATEADD(DAY, 10, GETDATE()), 120000.00, 'Programada', 'collar diamantes azul realeza francesa 1880', 1);
GO