-- ================================================
-- PROYECTO 11: Hotel Analytics
-- Autor: Martin Lauro
-- Base de datos: SQL Server
-- ================================================

-- 1. CREAR BASE DE DATOS
CREATE DATABASE hotel_analytics;
GO
USE hotel_analytics;
GO

-- ================================================
-- 2. CREAR TABLAS
-- ================================================

CREATE TABLE habitaciones (
    id_habitacion   INT PRIMARY KEY IDENTITY(1,1),
    numero          VARCHAR(10) NOT NULL UNIQUE,
    tipo            VARCHAR(30) CHECK (tipo IN ('Individual','Doble','Suite','Suite Premium')),
    piso            INT,
    precio_noche    DECIMAL(10,2) NOT NULL
);

CREATE TABLE huespedes (
    id_huesped      INT PRIMARY KEY IDENTITY(1,1),
    nombre          VARCHAR(50) NOT NULL,
    apellido        VARCHAR(50) NOT NULL,
    pais_origen     VARCHAR(50) NOT NULL,
    email           VARCHAR(100)
);

CREATE TABLE reservas (
    id_reserva       INT PRIMARY KEY IDENTITY(1,1),
    id_huesped       INT NOT NULL,
    id_habitacion    INT NOT NULL,
    fecha_checkin    DATE NOT NULL,
    fecha_checkout   DATE NOT NULL,
    noches           AS (DATEDIFF(DAY, fecha_checkin, fecha_checkout)),
    canal            VARCHAR(30) CHECK (canal IN ('Directo','Booking','Expedia','Airbnb','Agencia')),
    estado           VARCHAR(20) CHECK (estado IN ('Completada','Cancelada','En curso')),
    total_habitacion DECIMAL(10,2),
    FOREIGN KEY (id_huesped)    REFERENCES huespedes(id_huesped),
    FOREIGN KEY (id_habitacion) REFERENCES habitaciones(id_habitacion)
);

CREATE TABLE servicios_adicionales (
    id_servicio    INT PRIMARY KEY IDENTITY(1,1),
    id_reserva     INT NOT NULL,
    fecha          DATE NOT NULL,
    tipo_servicio  VARCHAR(30) CHECK (tipo_servicio IN ('Room Service','Spa','Restaurante','Bar','Estacionamiento','Lavandería')),
    monto          DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva)
);

CREATE TABLE pagos (
    id_pago          INT PRIMARY KEY IDENTITY(1,1),
    id_reserva       INT NOT NULL UNIQUE,
    total_habitacion DECIMAL(10,2) NOT NULL,
    total_servicios  DECIMAL(10,2) DEFAULT 0,
    total            DECIMAL(10,2) NOT NULL,
    medio_pago       VARCHAR(20) CHECK (medio_pago IN ('Tarjeta','Efectivo','Transferencia','OTA')),
    fecha_pago       DATE NOT NULL,
    FOREIGN KEY (id_reserva) REFERENCES reservas(id_reserva)
);

-- ================================================
-- 3. INSERTAR DATOS
-- ================================================

INSERT INTO habitaciones (numero, tipo, piso, precio_noche) VALUES
('101', 'Individual',     1,  8500),
('102', 'Individual',     1,  8500),
('201', 'Doble',          2, 12000),
('202', 'Doble',          2, 12000),
('203', 'Doble',          2, 12000),
('301', 'Suite',          3, 22000),
('302', 'Suite',          3, 22000),
('401', 'Suite Premium',  4, 38000),
('402', 'Suite Premium',  4, 38000),
('103', 'Individual',     1,  8500),
('204', 'Doble',          2, 12000),
('303', 'Suite',          3, 22000);

INSERT INTO huespedes (nombre, apellido, pais_origen, email) VALUES
('Carlos',    'García',     'Argentina',      'cgarcia@gmail.com'),
('María',     'López',      'Argentina',      'mlopez@gmail.com'),
('John',      'Smith',      'Estados Unidos', 'jsmith@gmail.com'),
('Sophie',    'Dubois',     'Francia',        'sdubois@gmail.com'),
('Lucas',     'Martínez',   'Argentina',      'lmartinez@gmail.com'),
('Emma',      'Wilson',     'Reino Unido',    'ewilson@gmail.com'),
('Diego',     'Fernández',  'Uruguay',        'dfernandez@gmail.com'),
('Valentina', 'Torres',     'Argentina',      'vtorres@gmail.com'),
('Marco',     'Rossi',      'Italia',         'mrossi@gmail.com'),
('Ana',       'Silva',      'Brasil',         'asilva@gmail.com'),
('Pablo',     'Rodríguez',  'Argentina',      'prodriguez@gmail.com'),
('Claire',    'Martin',     'Francia',        'cmartin@gmail.com'),
('James',     'Brown',      'Estados Unidos', 'jbrown@gmail.com'),
('Sofía',     'Pérez',      'Argentina',      'sperez@gmail.com'),
('Luca',      'Ferrari',    'Italia',         'lferrari@gmail.com'),
('Isabella',  'Santos',     'Brasil',         'isantos@gmail.com'),
('Mateo',     'González',   'Argentina',      'mgonzalez@gmail.com'),
('Olivia',    'Johnson',    'Estados Unidos', 'ojohnson@gmail.com'),
('Nicolás',   'Herrera',    'Colombia',       'nherrera@gmail.com'),
('Laura',     'Müller',     'Alemania',       'lmuller@gmail.com');

-- [Los INSERT de reservas, servicios_adicionales y pagos
--  son los mismos que ejecutaste durante el proyecto]

-- ================================================
-- 4. VIEWS
-- ================================================

GO
CREATE VIEW vw_reservas AS
SELECT
    r.id_reserva,
    r.fecha_checkin,
    r.fecha_checkout,
    r.noches,
    MONTH(r.fecha_checkin)           AS mes,
    DATENAME(MONTH, r.fecha_checkin) AS nombre_mes,
    r.canal,
    r.estado,
    h.numero                         AS habitacion,
    h.tipo                           AS tipo_habitacion,
    h.precio_noche,
    hu.nombre + ' ' + hu.apellido    AS huesped,
    hu.pais_origen,
    p.total_habitacion,
    p.total_servicios,
    p.total,
    p.medio_pago
FROM reservas r
JOIN habitaciones h  ON r.id_habitacion = h.id_habitacion
JOIN huespedes hu    ON r.id_huesped    = hu.id_huesped
JOIN pagos p         ON r.id_reserva    = p.id_reserva;

GO
CREATE VIEW vw_servicios AS
SELECT
    sa.id_servicio,
    sa.fecha,
    MONTH(sa.fecha)                  AS mes,
    DATENAME(MONTH, sa.fecha)        AS nombre_mes,
    sa.tipo_servicio,
    sa.monto,
    h.tipo                           AS tipo_habitacion,
    hu.pais_origen
FROM servicios_adicionales sa
JOIN reservas r     ON sa.id_reserva    = r.id_reserva
JOIN habitaciones h ON r.id_habitacion  = h.id_habitacion
JOIN huespedes hu   ON r.id_huesped     = hu.id_huesped;

-- ================================================
-- 5. CONSULTAS DE ANÁLISIS
-- ================================================

-- Ocupación e ingresos por mes
SELECT
    nombre_mes, mes,
    COUNT(CASE WHEN estado = 'Completada' THEN 1 END) AS reservas_completadas,
    COUNT(CASE WHEN estado = 'Cancelada'  THEN 1 END) AS cancelaciones,
    SUM(CASE WHEN estado = 'Completada' THEN total       ELSE 0 END) AS ingresos_totales,
    SUM(CASE WHEN estado = 'Completada' THEN total_servicios ELSE 0 END) AS ingresos_servicios,
    AVG(CASE WHEN estado = 'Completada' THEN total       ELSE NULL END) AS ticket_promedio
FROM vw_reservas
GROUP BY nombre_mes, mes
ORDER BY mes;

-- Ingresos por tipo de habitación
SELECT
    tipo_habitacion,
    COUNT(*)          AS reservas,
    SUM(total)        AS ingresos_totales,
    AVG(precio_noche) AS precio_promedio,
    AVG(noches)       AS estadia_promedio
FROM vw_reservas
WHERE estado = 'Completada'
GROUP BY tipo_habitacion
ORDER BY ingresos_totales DESC;

-- Top servicios adicionales
SELECT
    tipo_servicio,
    COUNT(*)      AS cantidad,
    SUM(monto)    AS ingresos_totales,
    AVG(monto)    AS ticket_promedio
FROM vw_servicios
GROUP BY tipo_servicio
ORDER BY ingresos_totales DESC;

-- Huéspedes por país
SELECT
    pais_origen,
    COUNT(DISTINCT id_reserva) AS reservas,
    SUM(total)                 AS ingresos_totales
FROM vw_reservas
WHERE estado = 'Completada'
GROUP BY pais_origen
ORDER BY ingresos_totales DESC;