# Laboratorio 01: Privacidad y Protección de Datos en PostgreSQL

## Descripción del Proyecto
Este laboratorio práctico aborda la implementación de técnicas de protección de datos personales y privacidad dentro de una base de datos **PostgreSQL 16** desplegada en Docker. Durante la práctica se aplican controles de seguridad a nivel de motor de base de datos para garantizar el cumplimiento de principios de privacidad como minimización, separación de funciones y ciclo de vida de la información.

---

## Objetivos del Laboratorio
1. **Clasificación de Datos:** Identificar datos personales directos y cuasi-identificadores.
2. **Enmascaramiento de Datos (*Data Masking*):** Crear vistas dinámicas con datos ocultos para roles operativos (`soporte`).
3. **Seudonimización:** Separar datos sensibles mediante esquemas (`pii`, `analitica`) y el uso de tokens UUID v4 (`pgcrypto`).
4. **Separación de Funciones (*Separation of Duties*):** Restringir accesos para evitar la reversión no autorizada de tokens por parte del rol `analista`.
5. **Anonimización y k-Anonimato:** Aplicar técnicas de generalización (rangos de edad y regiones de código postal) y supresión de grupos pequeños ($k = 5$).
6. **Retención de Datos:** Consultar e identificar datos caducos bajo políticas de conservación a 5 años.

---

## Estructura del Repositorio

```text
LAB-01/
├── README.md                 # Descripción general e instrucciones de uso
├── informe.md                # Respuestas teóricas, matriz de clasificación y análisis de riesgos
├── sql/                      # Scripts SQL divididos por actividad
│   ├── 01-clasificacion.sql
│   ├── 02-enmascaramiento.sql
│   ├── 03-seudonimizacion.sql
│   ├── 04-anonimizacion.sql
│   └── 05-retencion.sql
└── evidencias/               # Documentos PDF con capturas de pantalla de la terminal
    ├── 01-clasificacion.pdf
    ├── 02-enmascaramiento.pdf
    ├── 03-seudonimizacion.pdf
    ├── 04-anonimizacion.pdf
    └── 05-retencion.pdf
