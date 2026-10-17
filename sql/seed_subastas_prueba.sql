USE [subastas_privadas]
GO
/* =========================================================================
   SUBASTA DE PRUEBA - crea subastas activas sobre los articulos TEST_*
   para probar el flujo de pujas de punta a punta. Idempotente: no duplica
   si ya existe una subasta sobre ese articulo.

   Actualizado 2026-10-16:
   - monto_apertura = 80% del precio_base_reserva (regla del negocio)
   - fechas con dbo.fn_AhoraGT() (hora Guatemala, no la del servidor)
   ========================================================================= */

DECLARE @id_politica INT = (SELECT TOP 1 id_politica FROM Politicas_Comision);
DECLARE @id_estado_activa TINYINT = (SELECT id_estado_subasta FROM Estados_Subasta WHERE nombre = 'Activa');

IF NOT EXISTS (SELECT 1 FROM Subastas WHERE id_articulo = 2)
BEGIN
    INSERT INTO Subastas (id_articulo, id_estado_subasta, id_politica, id_usuario_creador,
        fecha_hora_inicio, fecha_hora_fin, extension_anti_sniping_seg,
        puja_actual_maxima, total_pujas, version, fecha_creacion, monto_apertura)
    SELECT 2, @id_estado_activa, @id_politica, 1,
        DATEADD(HOUR, -1, dbo.fn_AhoraGT()), DATEADD(DAY, 3, dbo.fn_AhoraGT()),
        120, 0.00, 0, 1, dbo.fn_AhoraGT(), ROUND(a.precio_base_reserva * 0.80, 2)
    FROM Articulos a WHERE a.id_articulo = 2;
    PRINT 'Subasta creada para articulo 2 (Guitarra Fender)';
END

IF NOT EXISTS (SELECT 1 FROM Subastas WHERE id_articulo = 3)
BEGIN
    INSERT INTO Subastas (id_articulo, id_estado_subasta, id_politica, id_usuario_creador,
        fecha_hora_inicio, fecha_hora_fin, extension_anti_sniping_seg,
        puja_actual_maxima, total_pujas, version, fecha_creacion, monto_apertura)
    SELECT 3, @id_estado_activa, @id_politica, 1,
        DATEADD(HOUR, -1, dbo.fn_AhoraGT()), DATEADD(DAY, 5, dbo.fn_AhoraGT()),
        120, 0.00, 0, 1, dbo.fn_AhoraGT(), ROUND(a.precio_base_reserva * 0.80, 2)
    FROM Articulos a WHERE a.id_articulo = 3;
    PRINT 'Subasta creada para articulo 3 (Rolex Daytona)';
END

-- Reglas de incremento para cada subasta creada
DECLARE @id_sub2 INT = (SELECT id_subasta FROM Subastas WHERE id_articulo = 2);
IF @id_sub2 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Reglas_Incremento WHERE id_subasta = @id_sub2)
BEGIN
    INSERT INTO Reglas_Incremento (id_subasta, monto_desde, monto_hasta, incremento_minimo) VALUES
        (@id_sub2, 0,      1000,    50.00),
        (@id_sub2, 1000,   10000,   100.00),
        (@id_sub2, 10000,  NULL,    500.00);
END

DECLARE @id_sub3 INT = (SELECT id_subasta FROM Subastas WHERE id_articulo = 3);
IF @id_sub3 IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Reglas_Incremento WHERE id_subasta = @id_sub3)
BEGIN
    INSERT INTO Reglas_Incremento (id_subasta, monto_desde, monto_hasta, incremento_minimo) VALUES
        (@id_sub3, 0,      1000,    50.00),
        (@id_sub3, 1000,   25000,   250.00),
        (@id_sub3, 25000,  NULL,    1000.00);
END

SELECT s.id_subasta, a.titulo, s.monto_apertura, s.puja_actual_maxima,
       s.fecha_hora_inicio, s.fecha_hora_fin, e.nombre AS estado
FROM Subastas s
JOIN Articulos a ON s.id_articulo = a.id_articulo
JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta;
GO
