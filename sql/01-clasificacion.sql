-- Actividad 1: Clasificación de datos
CREATE TABLE public.clientes (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    correo VARCHAR(100),
    telefono VARCHAR(20),
    rfc VARCHAR(13),
    edad INT,
    codigo_postal VARCHAR(10),
    ciudad VARCHAR(50),
    fecha_alta DATE DEFAULT CURRENT_DATE
);

INSERT INTO public.clientes (nombre, correo, telefono, rfc, edad, codigo_postal, ciudad) VALUES
('Ana López', 'ana.lopez@example.com', '5551234567', 'LOPA900101XXX', 34, '01000', 'CDMX'),
('Carlos Pérez', 'carlos.perez@example.com', '5559876543', 'PEPC850515YYY', 29, '02000', 'CDMX'),
('María García', 'maria.garcia@example.com', '5555555555', 'GAMM920820ZZZ', 42, '44100', 'Guadalajara'),
('Luis Torres', 'luis.torres@example.com', '5554443322', 'TORL881111AAA', 30, '64000', 'Monterrey'),
('Laura Sánchez', 'laura.sanchez@example.com', '5556667788', 'SALL950330BBB', 25, '01000', 'CDMX');
