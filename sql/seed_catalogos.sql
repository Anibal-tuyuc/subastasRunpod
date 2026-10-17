USE [subastas_privadas]
GO
/* =========================================================================
   SEED DE CATALOGOS - catálogos mínimos que el motor de pujas y la app
   necesitan. Los ids son explícitos (estas tablas no tienen IDENTITY).
   Idempotente: se puede correr varias veces sin duplicar.
   ========================================================================= */

-- Resultados_Intento: ids 1-5 los asume sp_RegistrarPuja (NO cambiar sin ajustar el SP)
IF NOT EXISTS (SELECT 1 FROM Resultados_Intento WHERE id_resultado = 1)
    INSERT INTO Resultados_Intento (id_resultado, codigo, descripcion, es_exitoso)
    VALUES (1, 'ACEPTADA', 'Puja registrada correctamente', 1);
IF NOT EXISTS (SELECT 1 FROM Resultados_Intento WHERE id_resultado = 2)
    INSERT INTO Resultados_Intento (id_resultado, codigo, descripcion, es_exitoso)
    VALUES (2, 'MONTO_BAJO', 'Monto inferior al minimo requerido', 0);
IF NOT EXISTS (SELECT 1 FROM Resultados_Intento WHERE id_resultado = 3)
    INSERT INTO Resultados_Intento (id_resultado, codigo, descripcion, es_exitoso)
    VALUES (3, 'FUERA_DE_TIEMPO', 'Intento fuera del horario de la subasta', 0);
IF NOT EXISTS (SELECT 1 FROM Resultados_Intento WHERE id_resultado = 4)
    INSERT INTO Resultados_Intento (id_resultado, codigo, descripcion, es_exitoso)
    VALUES (4, 'NO_ACTIVA', 'La subasta no esta en estado Activa', 0);
IF NOT EXISTS (SELECT 1 FROM Resultados_Intento WHERE id_resultado = 5)
    INSERT INTO Resultados_Intento (id_resultado, codigo, descripcion, es_exitoso)
    VALUES (5, 'NO_VERIFICADO', 'Usuario no verificado o inactivo', 0);

-- Estados_Subasta: 'Activa' y 'Finalizada' las usan los SPs por nombre
IF NOT EXISTS (SELECT 1 FROM Estados_Subasta WHERE id_estado_subasta = 1)
    INSERT INTO Estados_Subasta (id_estado_subasta, nombre, es_terminal)
    VALUES (1, 'Programada', 0);
IF NOT EXISTS (SELECT 1 FROM Estados_Subasta WHERE id_estado_subasta = 2)
    INSERT INTO Estados_Subasta (id_estado_subasta, nombre, es_terminal)
    VALUES (2, 'Activa', 0);
IF NOT EXISTS (SELECT 1 FROM Estados_Subasta WHERE id_estado_subasta = 3)
    INSERT INTO Estados_Subasta (id_estado_subasta, nombre, es_terminal)
    VALUES (3, 'Finalizada', 1);
IF NOT EXISTS (SELECT 1 FROM Estados_Subasta WHERE id_estado_subasta = 4)
    INSERT INTO Estados_Subasta (id_estado_subasta, nombre, es_terminal)
    VALUES (4, 'Cancelada', 1);

-- Estados_Puja: sp_RegistrarPuja inserta id_estado_puja = 1
IF NOT EXISTS (SELECT 1 FROM Estados_Puja WHERE id_estado_puja = 1)
    INSERT INTO Estados_Puja (id_estado_puja, nombre) VALUES (1, 'Registrada');
IF NOT EXISTS (SELECT 1 FROM Estados_Puja WHERE id_estado_puja = 2)
    INSERT INTO Estados_Puja (id_estado_puja, nombre) VALUES (2, 'Superada');
IF NOT EXISTS (SELECT 1 FROM Estados_Puja WHERE id_estado_puja = 3)
    INSERT INTO Estados_Puja (id_estado_puja, nombre) VALUES (3, 'Ganadora');

-- Estados_Pago: sp_CerrarSubasta inserta id_estado_pago = 1
IF NOT EXISTS (SELECT 1 FROM Estados_Pago WHERE id_estado_pago = 1)
    INSERT INTO Estados_Pago (id_estado_pago, nombre) VALUES (1, 'Pendiente');
IF NOT EXISTS (SELECT 1 FROM Estados_Pago WHERE id_estado_pago = 2)
    INSERT INTO Estados_Pago (id_estado_pago, nombre) VALUES (2, 'Pagado');
IF NOT EXISTS (SELECT 1 FROM Estados_Pago WHERE id_estado_pago = 3)
    INSERT INTO Estados_Pago (id_estado_pago, nombre) VALUES (3, 'Vencido');

-- Politica de comision por defecto (id_politica es IDENTITY)
IF NOT EXISTS (SELECT 1 FROM Politicas_Comision)
    INSERT INTO Politicas_Comision (id_categoria, nombre, porcentaje_comprador,
        porcentaje_vendedor, comision_minima, vigente_desde, vigente_hasta)
    VALUES (NULL, 'Estandar', 10.00, 8.00, 5.00, '2025-01-01', NULL);

-- Estados de verificacion: debe existir al menos uno con permite_pujar = 1
IF NOT EXISTS (SELECT 1 FROM Estados_Verificacion WHERE permite_pujar = 1)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Estados_Verificacion WHERE id_estado_verificacion = 1)
        INSERT INTO Estados_Verificacion (id_estado_verificacion, nombre, permite_pujar)
        VALUES (1, 'Verificado', 1);
    ELSE
        UPDATE Estados_Verificacion SET permite_pujar = 1 WHERE id_estado_verificacion = 1;
END

PRINT 'Catalogos sembrados correctamente.';
GO

SELECT 'Resultados_Intento' AS tabla, COUNT(*) AS filas FROM Resultados_Intento
UNION ALL SELECT 'Estados_Subasta', COUNT(*) FROM Estados_Subasta
UNION ALL SELECT 'Estados_Puja', COUNT(*) FROM Estados_Puja
UNION ALL SELECT 'Estados_Pago', COUNT(*) FROM Estados_Pago
UNION ALL SELECT 'Politicas_Comision', COUNT(*) FROM Politicas_Comision
UNION ALL SELECT 'Estados_Verificacion (permite pujar)', COUNT(*) FROM Estados_Verificacion WHERE permite_pujar = 1;
GO
