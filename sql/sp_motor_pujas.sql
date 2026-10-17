USE [subastas_privadas]
GO

/* =========================================================================
   MEJORA 2026-10-16
   1) Monto de apertura: 80% del precio_base_reserva del articulo.
      - La subasta NUNCA arranca en 0: la primera puja debe superar
        monto_apertura + incremento minimo.
      - Al cerrar, solo se adjudica si la puja ganadora >= monto_apertura
        (regla del 20% bajo la reserva).
   2) Hora Guatemala (UTC-6) en TODA la logica de negocio.
      fn_AhoraGT() devuelve SYSDATETIME() convertido con AT TIME ZONE,
      asi no importa en que zona horaria corra el servidor (RunPod = UTC).
   ========================================================================= */

-- ---- 1a. Columna nueva en Subastas ----
IF COL_LENGTH('dbo.Subastas', 'monto_apertura') IS NULL
BEGIN
    ALTER TABLE dbo.Subastas ADD monto_apertura DECIMAL(15,2) NULL;
END
GO

-- Rellenar subastas existentes: 80% del precio base/reserva del articulo
UPDATE s
SET s.monto_apertura = ROUND(a.precio_base_reserva * 0.80, 2)
FROM dbo.Subastas s
JOIN dbo.Articulos a ON a.id_articulo = s.id_articulo
WHERE s.monto_apertura IS NULL;
GO

ALTER TABLE dbo.Subastas ALTER COLUMN monto_apertura DECIMAL(15,2) NOT NULL;
GO

-- ---- 1b. Funcion hora Guatemala (UTC-6 fijo, Guatemala no usa DST) ----
CREATE OR ALTER FUNCTION dbo.fn_AhoraGT()
RETURNS DATETIME2(3)
AS
BEGIN
    RETURN CAST(SYSDATETIME() AT TIME ZONE 'UTC'
                AT TIME ZONE 'Central America Standard Time' AS DATETIME2(3));
END
GO

-- ---- 1c. SPs con SET correctos (columnas calculadas en Ordenes_Pago) ----
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_RegistrarPuja]
    @id_subasta INT,
    @id_usuario INT,
    @monto DECIMAL(15,2),
    @ip_origen VARBINARY(16) = 0x00000000000000000000000000000000,
    @user_agent VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @puja_max DECIMAL(15,2), @apertura DECIMAL(15,2),
            @incremento DECIMAL(10,2), @minimo DECIMAL(15,2),
            @fecha_inicio DATETIME2(3), @fecha_fin DATETIME2(3),
            @id_estado TINYINT, @extension SMALLINT, @version INT,
            @permite_pujar BIT, @id_resultado TINYINT, @id_puja_nueva INT,
            @ahora DATETIME2(3) = dbo.fn_AhoraGT();

    -- Resultados_Intento: 1=Aceptada, 2=Rechazada monto bajo, 3=Fuera de tiempo,
    --                     4=Subasta no activa, 5=Usuario no verificado

    BEGIN TRANSACTION;

    SELECT @puja_max = s.puja_actual_maxima,
           @apertura = s.monto_apertura,
           @fecha_inicio = s.fecha_hora_inicio,
           @fecha_fin = s.fecha_hora_fin,
           @id_estado = s.id_estado_subasta,
           @extension = s.extension_anti_sniping_seg,
           @version = s.version
    FROM [dbo].[Subastas] s WITH (UPDLOCK, HOLDLOCK)
    WHERE s.id_subasta = @id_subasta;

    IF @apertura IS NULL
    BEGIN
        ROLLBACK; THROW 50001, 'La subasta no existe.', 1;
    END

    -- Incremento minimo segun el rango donde cae la puja actual.
    -- Si nadie ha pujado, el rango se calcula sobre el monto de apertura.
    DECLARE @base_rango DECIMAL(15,2) =
        CASE WHEN ISNULL(@puja_max, 0) > 0 THEN @puja_max ELSE @apertura END;

    SELECT TOP 1 @incremento = incremento_minimo
    FROM [dbo].[Reglas_Incremento]
    WHERE id_subasta = @id_subasta
      AND @base_rango >= monto_desde
      AND (monto_hasta IS NULL OR @base_rango < monto_hasta)
    ORDER BY monto_desde DESC;
    SET @incremento = ISNULL(@incremento, 1.00);

    -- Minimo exigible: nunca por debajo de la apertura, nunca en 0
    SET @minimo = CASE WHEN ISNULL(@puja_max, 0) > 0
                       THEN @puja_max + @incremento
                       ELSE @apertura + @incremento END;

    -- ===== VALIDACIONES (cada rechazo queda auditado) =====

    IF NOT EXISTS (SELECT 1 FROM Estados_Subasta
                   WHERE id_estado_subasta = @id_estado AND nombre = 'Activa')
    BEGIN
        INSERT INTO Auditoria_Pujas (id_subasta, id_usuario, id_resultado, monto_intento,
            puja_maxima_al_momento, fecha_hora_intento, ip_origen, user_agent)
        VALUES (@id_subasta, @id_usuario, 4, @monto, @puja_max, @ahora, @ip_origen, @user_agent);
        COMMIT; THROW 50004, 'La subasta no esta activa.', 1;
    END

    IF @ahora NOT BETWEEN @fecha_inicio AND @fecha_fin
    BEGIN
        INSERT INTO Auditoria_Pujas (id_subasta, id_usuario, id_resultado, monto_intento,
            puja_maxima_al_momento, fecha_hora_intento, ip_origen, user_agent)
        VALUES (@id_subasta, @id_usuario, 3, @monto, @puja_max, @ahora, @ip_origen, @user_agent);
        COMMIT; THROW 50003, 'Fuera del horario de la subasta.', 1;
    END

    SELECT @permite_pujar = ev.permite_pujar
    FROM Usuarios u JOIN Estados_Verificacion ev
        ON u.id_estado_verificacion = ev.id_estado_verificacion
    WHERE u.id_usuario = @id_usuario AND u.activo = 1;

    IF ISNULL(@permite_pujar, 0) = 0
    BEGIN
        INSERT INTO Auditoria_Pujas (id_subasta, id_usuario, id_resultado, monto_intento,
            puja_maxima_al_momento, fecha_hora_intento, ip_origen, user_agent)
        VALUES (@id_subasta, @id_usuario, 5, @monto, @puja_max, @ahora, @ip_origen, @user_agent);
        COMMIT; THROW 50005, 'Usuario no verificado o inactivo.', 1;
    END

    IF @monto < @minimo
    BEGIN
        INSERT INTO Auditoria_Pujas (id_subasta, id_usuario, id_resultado, monto_intento,
            puja_maxima_al_momento, fecha_hora_intento, ip_origen, user_agent)
        VALUES (@id_subasta, @id_usuario, 2, @monto, @puja_max, @ahora, @ip_origen, @user_agent);
        COMMIT;
        DECLARE @msg VARCHAR(200) = 'Puja minima: ' + CAST(@minimo AS VARCHAR(20));
        THROW 50002, @msg, 1;
    END

    -- ===== PUJA ACEPTADA =====
    INSERT INTO [dbo].[Pujas] (id_subasta, id_usuario, id_estado_puja, monto_oferta,
                               fecha_hora_puja, es_automatica)
    VALUES (@id_subasta, @id_usuario, 1, @monto, @ahora, 0);
    SET @id_puja_nueva = SCOPE_IDENTITY();

    -- Anti-sniping: si quedan menos segundos que la extension configurada, extender
    DECLARE @nueva_fin DATETIME2(3) = @fecha_fin;
    IF DATEDIFF(SECOND, @ahora, @fecha_fin) < @extension
        SET @nueva_fin = DATEADD(SECOND, @extension, @ahora);

    UPDATE [dbo].[Subastas]
    SET puja_actual_maxima = @monto,
        id_puja_lider = @id_puja_nueva,
        total_pujas = total_pujas + 1,
        version = version + 1,
        fecha_hora_fin = @nueva_fin
    WHERE id_subasta = @id_subasta AND version = @version;  -- doble seguro concurrencia

    INSERT INTO Auditoria_Pujas (id_subasta, id_usuario, id_puja, id_resultado, monto_intento,
        puja_maxima_al_momento, fecha_hora_intento, ip_origen, user_agent)
    VALUES (@id_subasta, @id_usuario, @id_puja_nueva, 1, @monto, @puja_max,
            @ahora, @ip_origen, @user_agent);

    COMMIT TRANSACTION;
END
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_CerrarSubasta]
    @id_subasta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @id_puja_gan INT, @id_ganador INT, @monto DECIMAL(15,2),
            @id_politica INT, @pct_comprador DECIMAL(5,2), @pct_vendedor DECIMAL(5,2),
            @com_min DECIMAL(15,2), @apertura DECIMAL(15,2), @moneda CHAR(3),
            @id_est_finalizada TINYINT, @id_est_adjudicado TINYINT,
            @ahora DATETIME2(3) = dbo.fn_AhoraGT();

    SELECT @id_est_finalizada = id_estado_subasta FROM Estados_Subasta WHERE nombre = 'Finalizada';
    SELECT @id_est_adjudicado = id_estado_articulo FROM Estados_Articulo WHERE nombre LIKE '%Adjudicado%';

    BEGIN TRANSACTION;

    SELECT TOP 1 @id_puja_gan = p.id_puja, @id_ganador = p.id_usuario, @monto = p.monto_oferta
    FROM Pujas p WITH (UPDLOCK, HOLDLOCK)
    WHERE p.id_subasta = @id_subasta
    ORDER BY p.monto_oferta DESC, p.fecha_hora_puja ASC;  -- empate: gana quien pujo primero

    SELECT @id_politica = s.id_politica,
           @apertura = s.monto_apertura,
           @moneda = a.codigo_moneda
    FROM Subastas s WITH (UPDLOCK, HOLDLOCK)
    JOIN Articulos a ON s.id_articulo = a.id_articulo
    WHERE s.id_subasta = @id_subasta;

    IF @id_politica IS NULL
    BEGIN
        ROLLBACK; THROW 50010, 'La subasta no existe.', 1;
    END

    UPDATE Subastas SET id_estado_subasta = @id_est_finalizada, version = version + 1
    WHERE id_subasta = @id_subasta;

    /* Adjudicacion: la puja ganadora debe alcanzar al menos el monto de
       apertura (80% del precio base/reserva). Si no llega, la subasta se
       cierra SIN ganador y sin orden de pago. */
    IF @id_ganador IS NOT NULL AND @monto >= @apertura
    BEGIN
        -- Comisiones segun politica vigente
        SELECT @pct_comprador = porcentaje_comprador,
               @pct_vendedor = porcentaje_vendedor,
               @com_min = comision_minima
        FROM Politicas_Comision WHERE id_politica = @id_politica;

        DECLARE @com_comprador DECIMAL(15,2) =
            CASE WHEN ROUND(@monto * @pct_comprador/100, 2) < @com_min THEN @com_min
                 ELSE ROUND(@monto * @pct_comprador/100, 2) END;
        DECLARE @com_vendedor DECIMAL(15,2) = ROUND(@monto * @pct_vendedor/100, 2);

        INSERT INTO Adjudicaciones (id_subasta, id_puja_ganadora, id_usuario_ganador,
                                    monto_adjudicado, fecha_adjudicacion, supero_reserva)
        VALUES (@id_subasta, @id_puja_gan, @id_ganador, @monto, @ahora, 1);

        UPDATE Articulos SET id_estado_articulo = @id_est_adjudicado
        WHERE id_articulo = (SELECT id_articulo FROM Subastas WHERE id_subasta = @id_subasta);

        INSERT INTO Ordenes_Pago (id_subasta, id_usuario_ganador, id_estado_pago, codigo_moneda,
            monto_adjudicado, comision_comprador, comision_vendedor, impuestos,
            deposito_aplicado, fecha_generacion, fecha_vencimiento)
        VALUES (@id_subasta, @id_ganador, 1, @moneda, @monto,
                @com_comprador, @com_vendedor, 0, 0,
                CAST(@ahora AS DATETIME), DATEADD(DAY, 7, CAST(@ahora AS DATETIME)));
    END

    COMMIT TRANSACTION;

    SELECT @id_ganador AS id_ganador, @monto AS monto_adjudicado, @apertura AS monto_apertura,
           CASE
               WHEN @id_ganador IS NULL THEN 'SIN PUJAS'
               WHEN @monto >= @apertura THEN 'ADJUDICADO'
               ELSE 'NO ALCANZO APERTURA'
           END AS resultado;
END
GO

SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_CerrarSubastasVencidas]
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @id INT;
    DECLARE cur CURSOR LOCAL FAST_FORWARD FOR
        SELECT s.id_subasta FROM Subastas s
        JOIN Estados_Subasta e ON s.id_estado_subasta = e.id_estado_subasta
        WHERE e.nombre = 'Activa' AND s.fecha_hora_fin < dbo.fn_AhoraGT();
    OPEN cur;
    FETCH NEXT FROM cur INTO @id;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sp_CerrarSubasta @id;
        FETCH NEXT FROM cur INTO @id;
    END
    CLOSE cur; DEALLOCATE cur;
END
GO
