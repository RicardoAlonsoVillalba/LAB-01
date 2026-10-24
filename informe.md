# Informe de laboratorio: Privacidad de datos en PostgreSQL

## 1. Clasificación de datos
### Matriz de clasificación de atributos
| Campo | ¿Identifica directamente? | ¿Puede contribuir a identificar? | ¿Requiere protección? | Justificación |
| :--- | :---: | :---: | :---: | :--- |
| **id** | No | Sí | No | Identificador interno secuencial; no revela identidad por sí solo. |
| **nombre** | Sí | Sí | Sí | Dato de identificación directa e explícita. |
| **correo** | Sí | Sí | Sí | Identificador directo de contacto personal y digital. |
| **telefono** | Sí | Sí | Sí | Dato de contacto directo del titular. |
| **rfc** | Sí | Sí | Sí | Clave única de identificación oficial en México. |
| **edad** | No | Sí | Sí | Cuasi-identificador demográfico. |
| **ciudad** | No | Sí | Sí | Cuasi-identificador geográfico. |
| **codigo_postal** | No | Sí | Sí | Cuasi-identificador de ubicación que ayuda a acotar grupos. |
| **fecha_alta** | No | Sí | No | Dato transaccional y administrativo del sistema. |

### Respuestas teóricas
* **¿Qué datos permiten identificar directamente a una persona?** Nombre, correo electrónico, teléfono y RFC.
* **¿Qué datos son cuasi-identificadores?** Edad, ciudad y código postal.
* **¿Por qué un dato que no identifica directamente puede representar un riesgo de privacidad?** Porque al combinar varios cuasi-identificadores (por ejemplo: edad + código postal) mediante ataques de vinculación, es posible aislar a un individuo dentro de un grupo reducido y reidentificarlo.

---

## 2. Enmascaramiento de datos (Masking)
* **Objetivo:** Permitir al rol de `soporte` visualizar información parcial necesaria para la operación sin exponer la PII completa.
* **Implementación:** Se construyó la vista `v_clientes_soporte` utilizando funciones de texto (`CONCAT`, `LEFT`, `RIGHT`, `SUBSTRING`, `POSITION`) para ocultar caracteres sensibles de correo, teléfono y RFC.
* **Acceso restringido:** Se otorgó `SELECT` sobre la vista al rol `soporte` y se denegó el acceso directo a la tabla `public.clientes`.

---

## 3. Seudonimización
* **Estrategia:** Separación del conjunto de datos en dos esquemas independientes: `pii` (contiene la tabla de correspondencia `mapa_cliente` con tokens UUID) y `analitica` (contiene la tabla `clientes` vinculada únicamente por token).
* **Mecanismo:** Generación de UUIDs v4 mediante la extensión `pgcrypto`.

---

## 4. Separación de funciones (Separation of Duties)
* **Control:** El rol `analista` únicamente tiene permiso de lectura en `analitica.clientes`. Se le denegó explícitamente el acceso a `pii.mapa_cliente` y a `public.clientes`.
* **Respuestas de evaluación:**
  1. **¿Qué ocurriría si analista pudiera consultar también `pii.mapa_cliente`?** Podría realizar un `JOIN` entre el token y el ID original, revirtiendo la seudonimización y reidentificando a los clientes.
  2. **¿Qué principio de seguridad se está aplicando al separar ambos accesos?** Principio de menor privilegio y separación de funciones (*Separation of Duties*).
  3. **¿Por qué la seudonimización no equivale a anonimización?** Porque la seudonimización es un proceso reversible si se cuenta con la información adicional (el mapa de llaves o tokens), mientras que la anonimización busca ser irreversible.
  4. **¿Qué información permite volver a relacionar el token con una persona?** La tabla de correspondencia `pii.mapa_cliente`, que vincula el `token` UUID con el `cliente_id`.

---

## 5. Anonimización y k-anonimato
* **Técnicas aplicadas:**
  * **Generalización de edad:** Agrupación por rangos (`18-30`, `31-45`, `46+`).
  * **Generalización de región:** Extracción de los primeros dígitos del código postal (`LEFT(codigo_postal, 2)`).
  * **Supresión por k-anonimato:** Filtrado mediante `HAVING COUNT(*) >= 5` para eliminar grupos pequeños expuestos a reidentificación.

### Análisis de riesgo de reidentificación
1. **Identificadores eliminados:** Nombre, correo, teléfono y RFC.
2. **Cuasi-identificadores remanentes:** Rango de edad y región (código postal parcial).
3. **Combinaciones de riesgo:** La intersección de un rango de edad específico con una región geográfica pequeña.
4. **Grupos con pocos registros:** Aumentan drásticamente el riesgo de reidentificación por aislamiento.
5. **Atributos a generalizar:** Edades exactas, códigos postales detallados y fechas completas.
6. **Información a suprimir:** Grupos de registros que no alcancen el umbral $k$ establecido.
7. **¿Es "100% anónimo"?:** No. No existe el anonimato absoluto; siempre persiste un riesgo residual si los datos se cruzan con fuentes de datos externas o públicas.

---

## 6. Reto de mayor generalización
* **Cambio realizado:** Se modificó la extracción geográfica de `LEFT(codigo_postal, 2)` a `LEFT(codigo_postal, 1)`.
* **Motivo:** Aumentar la densidad de registros por grupo al abarcar macro-regiones o estados enteros.
* **Resultado obtenido:** Se reduce la granularidad geográfica y se incrementa el tamaño de los grupos.
* **Riesgo reducido:** Mitigación del ataque por aislamiento espacial en zonas poco pobladas.

---

## 7. Retención y ciclo de vida de los datos
* **Consulta de identificación:** `SELECT * FROM clientes WHERE fecha_alta < CURRENT_DATE - INTERVAL '5 years';`
* **Política y procedimiento:**
  * **Registros afectados:** Clientes con antigüedad mayor a 5 años sin actividad contractual.
  * **Justificación:** Cumplimiento de obligaciones fiscales/legales y principio de minimización de almacenamiento.
  * **Aprobaciones necesarias:** Autorización formal del DPO (Oficial de Protección de Datos) y el área Legal.
  * **Respaldo previo:** Generación de copia de seguridad inmutable (*cold storage*) cifrada antes de cualquier purga.
  * **Evidencia de purga:** Registro en bitácoras (*audit logs*) del sistema con firma digital.
  * **Recuperación accidental:** Restauración desde *snapshot* incremental en un entorno aislado de recuperación.
