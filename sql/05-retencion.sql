-- Actividad 7: Retención de datos
SELECT * FROM clientes WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';
