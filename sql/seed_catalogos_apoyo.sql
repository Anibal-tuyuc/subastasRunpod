USE [subastas_privadas]
GO
/* =========================================================================
   SEED CATALOGOS DE APOYO - entidades certificadoras, estados fisicos
   ampliados y estados de articulo. Idempotente.
   ========================================================================= */

-- Entidades certificadoras (para Certificados_Autenticidad)
-- id_entidad_emisora es IDENTITY: se siembra por nombre.
IF NOT EXISTS (SELECT 1 FROM Entidades_Certificadoras WHERE nombre LIKE 'GIA%')
    INSERT INTO Entidades_Certificadoras (nombre, pais, sitio_web, acreditada)
    VALUES ('GIA - Gemological Institute of America', 'US', 'https://www.gia.edu', 1);
IF NOT EXISTS (SELECT 1 FROM Entidades_Certificadoras WHERE nombre LIKE 'PSA%')
    INSERT INTO Entidades_Certificadoras (nombre, pais, sitio_web, acreditada)
    VALUES ('PSA - Professional Sports Authenticator', 'US', 'https://www.psacard.com', 1);
IF NOT EXISTS (SELECT 1 FROM Entidades_Certificadoras WHERE nombre LIKE 'Casa de Tasaciones UMG%')
    INSERT INTO Entidades_Certificadoras (nombre, pais, sitio_web, acreditada)
    VALUES ('Casa de Tasaciones UMG (interna)', 'GT', NULL, 1);
IF NOT EXISTS (SELECT 1 FROM Entidades_Certificadoras WHERE nombre = 'Otra / No listada')
    INSERT INTO Entidades_Certificadoras (nombre, pais, sitio_web, acreditada)
    VALUES ('Otra / No listada', NULL, NULL, 0);

-- Estados fisicos ampliados (la tabla tenia 1=Excelente, 2=Bueno)
IF NOT EXISTS (SELECT 1 FROM Estados_Fisicos WHERE id_estado_fisico = 3)
    INSERT INTO Estados_Fisicos (id_estado_fisico, nombre, descripcion)
    VALUES (3, 'Regular', 'Signos visibles de uso, funcional');
IF NOT EXISTS (SELECT 1 FROM Estados_Fisicos WHERE id_estado_fisico = 4)
    INSERT INTO Estados_Fisicos (id_estado_fisico, nombre, descripcion)
    VALUES (4, 'Para restaurar', 'Requiere restauracion o reparacion');
IF NOT EXISTS (SELECT 1 FROM Estados_Fisicos WHERE id_estado_fisico = 5)
    INSERT INTO Estados_Fisicos (id_estado_fisico, nombre, descripcion)
    VALUES (5, 'Nuevo / Sin uso', 'Sellado o nunca utilizado');

-- Estados de articulo (el DDL trae solo 1=Activo/Disponible; el SP de cierre
-- busca '%Adjudicado%')
IF NOT EXISTS (SELECT 1 FROM Estados_Articulo WHERE nombre LIKE '%Adjudicado%')
    INSERT INTO Estados_Articulo (id_estado_articulo, nombre) VALUES (2, 'Adjudicado');
IF NOT EXISTS (SELECT 1 FROM Estados_Articulo WHERE id_estado_articulo = 3)
    INSERT INTO Estados_Articulo (id_estado_articulo, nombre) VALUES (3, 'Retirado');

PRINT 'Catalogos de apoyo sembrados.';
GO

SELECT 'Entidades' AS t, COUNT(*) AS n FROM Entidades_Certificadoras
UNION ALL SELECT 'Estados_Fisicos', COUNT(*) FROM Estados_Fisicos
UNION ALL SELECT 'Estados_Articulo', COUNT(*) FROM Estados_Articulo;
GO
