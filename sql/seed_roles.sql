USE [subastas_privadas]
GO
/* =========================================================================
   SEED DE ROLES - roles del sistema y asignacion del primer admin.
   Idempotente.
   ========================================================================= */

IF NOT EXISTS (SELECT 1 FROM Roles WHERE id_rol = 1)
    INSERT INTO Roles (id_rol, nombre, descripcion)
    VALUES (1, 'Admin', 'Administrador: crea y cierra subastas, ve reportes');
IF NOT EXISTS (SELECT 1 FROM Roles WHERE id_rol = 2)
    INSERT INTO Roles (id_rol, nombre, descripcion)
    VALUES (2, 'Postor', 'Usuario regular: puja en subastas activas');

-- Juan (usuario 1, el creador de las subastas de prueba) queda como admin
IF NOT EXISTS (SELECT 1 FROM Usuario_Roles WHERE id_usuario = 1 AND id_rol = 1)
    INSERT INTO Usuario_Roles (id_usuario, id_rol, fecha_asignacion)
    VALUES (1, 1, GETDATE());

SELECT r.id_rol, r.nombre, u.nombre + ' ' + u.apellido AS usuario
FROM Roles r
LEFT JOIN Usuario_Roles ur ON r.id_rol = ur.id_rol
LEFT JOIN Usuarios u ON ur.id_usuario = u.id_usuario;
GO
