/* =========================================================================
   SINCRONIZACION DE DATOS local -> pod (SQL 2022 compatible)
   Generado 2026-10-16. Inserta los datos que faltan en el pod:
   monedas, articulos, imagenes, subastas, reglas, pujas.
   IDEMPOTENTE: usa NOT EXISTS para no duplicar si se corre 2 veces.
   NO toca usuarios (ya existen en el pod).
   ========================================================================= */
USE [subastas_privadas]
GO
SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ---- 1) MONEDAS faltantes (el pod solo tiene USD y EUR) ----
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='ARS')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('ARS','Peso Argentino','$',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='GBP')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('GBP','Libra Esterlina','£',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='GTQ')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('GTQ','Quetzal Guatemalteco','Q',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='MXN')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('MXN','Peso Mexicano','$',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='PEN')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('PEN','Sol Peruano','S/',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='EUR')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('EUR','Euro','€',2);
IF NOT EXISTS (SELECT 1 FROM Monedas WHERE codigo_moneda='USD')
    INSERT INTO Monedas (codigo_moneda, nombre, simbolo, decimales) VALUES ('USD','Dólar Estadounidense','$',2);
PRINT 'Monedas sincronizadas';
GO

-- ---- 2) ARTICULOS (con IDENTITY_INSERT para conservar los ids originales) ----
-- id_vendedor se resuelve POR EMAIL y la ubicacion POR NOMBRE
-- (los IDs difieren entre local y pod).
DECLARE @vendedor_juan INT = (SELECT TOP 1 id_usuario FROM Usuarios WHERE email='juan@test.com' ORDER BY id_usuario);
DECLARE @vendedor_junior INT = (SELECT TOP 1 id_usuario FROM Usuarios WHERE email='juniortuyuc5@gmail.com' ORDER BY id_usuario);
IF @vendedor_juan IS NULL SET @vendedor_juan = (SELECT TOP 1 id_usuario FROM Usuarios ORDER BY id_usuario);
IF @vendedor_junior IS NULL SET @vendedor_junior = @vendedor_juan;

SET IDENTITY_INSERT Articulos ON;
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=2)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 2,@vendedor_juan,1,1,1,'USD','TEST_Guitarra Eléctrica Fender','Guitarra color rojo, excelentes condiciones',1965,'Estados Unidos',15000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Almacén Climatizado A1');
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=3)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 3,@vendedor_juan,2,1,2,'USD','TEST_Reloj Rolex Daytona','Reloj de oro blanco 18k',1990,'Suiza',25000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Bóveda Principal Centro');
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=4)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 4,@vendedor_juan,3,1,1,'USD','TEST_Chaqueta de Cuero Roja','Chaqueta original usada en videoclip',1983,'Estados Unidos',50000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Caja de Seguridad 445');
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=5)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 5,@vendedor_juan,2,2,1,'EUR','TEST_Collar de Diamantes Azules','Collar de la realeza europea del siglo XIX',1880,'Francia',120000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Bóveda Suiza');
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=6)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 6,@vendedor_junior,3,4,1,'USD','Le Bombe','Máquina Bombe histórica de descifrado',1939,'Colección Privada',1000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Caja de Seguridad 445');
IF NOT EXISTS (SELECT 1 FROM Articulos WHERE id_articulo=8)
    INSERT INTO Articulos (id_articulo,id_vendedor,id_categoria,id_estado_fisico,id_estado_articulo,codigo_moneda,titulo,descripcion,anio_fabricacion,procedencia,precio_base_reserva,fecha_ingreso,id_ubicacion_actual)
    SELECT 8,@vendedor_junior,3,1,1,'GTQ','La Bombe','Máquina Bombe histórica de descifrado',1939,'Colección Privada',100000.00,dbo.fn_AhoraGT(),
           (SELECT id_ubicacion FROM Ubicaciones_Almacenaje WHERE nombre_ubicacion='Almacén Climatizado A1');
SET IDENTITY_INSERT Articulos OFF;
PRINT 'Articulos sincronizados';
GO

-- ---- 3) IMAGENES de los articulos ----
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=2 AND orden=1)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (2,'https://picsum.photos/seed/guitarra/600/400',1,1);
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=2 AND orden=2)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (2,'https://picsum.photos/seed/fender2/600/400',2,0);
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=3 AND orden=1)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (3,'https://picsum.photos/seed/rolex/600/400',1,1);
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=3 AND orden=2)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (3,'https://picsum.photos/seed/reloj2/600/400',2,0);
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=6 AND orden=1)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (6,'https://en.wikipedia.org/wiki/Bombe#/media/File:Wartime_picture_of_a_Bletchley_Park_Bombe.jpg',1,1);
IF NOT EXISTS (SELECT 1 FROM Imagenes_Articulo WHERE id_articulo=8 AND orden=1)
    INSERT INTO Imagenes_Articulo (id_articulo,url,orden,es_portada) VALUES (8,'https://res.cloudinary.com/xbylnxck/image/upload/v1792118719/Wartime_picture_of_a_Bletchley_Park_Bombe.jpg',1,1);
PRINT 'Imagenes sincronizadas';
GO

-- ---- 4) SUBASTAS (con IDENTITY_INSERT; estado 3 = Finalizada) ----
-- id_usuario_creador se resuelve por email (admin). id_puja_lider se enlaza
-- despues de insertar las pujas (paso 6b).
DECLARE @id_admin INT = (SELECT TOP 1 id_usuario FROM Usuarios WHERE email='juniortuyuc5@gmail.com' ORDER BY id_usuario);
IF @id_admin IS NULL SET @id_admin = (SELECT TOP 1 id_usuario FROM Usuarios ORDER BY id_usuario);

SET IDENTITY_INSERT Subastas ON;
IF NOT EXISTS (SELECT 1 FROM Subastas WHERE id_subasta=1)
    INSERT INTO Subastas (id_subasta,id_articulo,id_estado_subasta,id_politica,id_usuario_creador,fecha_hora_inicio,fecha_hora_fin,extension_anti_sniping_seg,puja_actual_maxima,id_puja_lider,total_pujas,version,fecha_creacion,monto_apertura)
    VALUES (1,2,3,1,@id_admin,'2026-10-15 17:58:10.873','2026-10-18 18:58:10.873',120,350.00,NULL,6,8,dbo.fn_AhoraGT(),12000.00);
IF NOT EXISTS (SELECT 1 FROM Subastas WHERE id_subasta=2)
    INSERT INTO Subastas (id_subasta,id_articulo,id_estado_subasta,id_politica,id_usuario_creador,fecha_hora_inicio,fecha_hora_fin,extension_anti_sniping_seg,puja_actual_maxima,id_puja_lider,total_pujas,version,fecha_creacion,monto_apertura)
    VALUES (2,3,3,1,@id_admin,'2026-10-15 17:58:10.880','2026-10-20 18:58:10.880',120,20500.00,NULL,1,3,dbo.fn_AhoraGT(),20000.00);
SET IDENTITY_INSERT Subastas OFF;
PRINT 'Subastas sincronizadas';
GO

-- ---- 5) REGLAS DE INCREMENTO ----
IF NOT EXISTS (SELECT 1 FROM Reglas_Incremento WHERE id_subasta=1)
BEGIN
    INSERT INTO Reglas_Incremento (id_subasta,monto_desde,monto_hasta,incremento_minimo) VALUES
        (1,0.00,1000.00,50.00),(1,1000.00,10000.00,100.00),(1,10000.00,NULL,500.00);
END
IF NOT EXISTS (SELECT 1 FROM Reglas_Incremento WHERE id_subasta=2)
BEGIN
    INSERT INTO Reglas_Incremento (id_subasta,monto_desde,monto_hasta,incremento_minimo) VALUES
        (2,0.00,1000.00,50.00),(2,1000.00,25000.00,250.00),(2,25000.00,NULL,1000.00);
END
PRINT 'Reglas sincronizadas';
GO

-- ---- 6) PUJAS (con IDENTITY_INSERT; id_usuario por email) ----
DECLARE @id_juan INT = (SELECT TOP 1 id_usuario FROM Usuarios WHERE email='juan@test.com' ORDER BY id_usuario);
DECLARE @id_ana  INT = (SELECT TOP 1 id_usuario FROM Usuarios WHERE email='ana@test.com' ORDER BY id_usuario);
-- fallback: si no existen, usa cualquier usuario no-admin para que la FK no truene
IF @id_juan IS NULL SET @id_juan = (SELECT TOP 1 id_usuario FROM Usuarios ORDER BY id_usuario);
IF @id_ana  IS NULL SET @id_ana  = @id_juan;

SET IDENTITY_INSERT Pujas ON;
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=1)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (1,1,@id_ana,1,100.00,'2026-10-15 18:59:54.334',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=2)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (2,1,@id_juan,1,150.00,'2026-10-15 19:22:20.037',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=3)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (3,1,@id_juan,1,200.00,'2026-10-15 19:22:33.725',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=4)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (4,1,@id_juan,1,250.00,'2026-10-15 19:22:34.638',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=5)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (5,1,@id_juan,1,300.00,'2026-10-15 19:22:36.540',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=6)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (6,1,@id_juan,1,350.00,'2026-10-15 19:22:37.527',0);
IF NOT EXISTS (SELECT 1 FROM Pujas WHERE id_puja=7)
    INSERT INTO Pujas (id_puja,id_subasta,id_usuario,id_estado_puja,monto_oferta,fecha_hora_puja,es_automatica) VALUES (7,2,@id_ana,1,20500.00,'2026-10-16 12:08:11.000',0);
SET IDENTITY_INSERT Pujas OFF;
PRINT 'Pujas sincronizadas';

-- 6b) Enlazar id_puja_lider de cada subasta con su puja ganadora
UPDATE s SET id_puja_lider = 6 FROM Subastas s WHERE s.id_subasta=1 AND EXISTS (SELECT 1 FROM Pujas WHERE id_puja=6);
UPDATE s SET id_puja_lider = 7 FROM Subastas s WHERE s.id_subasta=2 AND EXISTS (SELECT 1 FROM Pujas WHERE id_puja=7);
PRINT 'Pujas lider enlazadas';
GO

-- ---- VERIFICACION ----
SELECT 'MONEDAS' AS obj, COUNT(*) AS n FROM Monedas
UNION ALL SELECT 'Articulos', COUNT(*) FROM Articulos
UNION ALL SELECT 'Imagenes', COUNT(*) FROM Imagenes_Articulo
UNION ALL SELECT 'Subastas', COUNT(*) FROM Subastas
UNION ALL SELECT 'Reglas', COUNT(*) FROM Reglas_Incremento
UNION ALL SELECT 'Pujas', COUNT(*) FROM Pujas;
GO
