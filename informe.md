
# Informe de laboratorio: Privacidad y Protección de Datos en PostgreSQL

---

## 19. Informe

### 19.1 Clasificación
Los datos personales que requieren protección dentro de la base de datos son:
* **Identificadores directos:** Nombre, correo electrónico, teléfono y RFC. Requieren protección estricta porque revelan directamente la identidad única e inequívoca del titular de la información.
* **Cuasi-identificadores:** Edad, ciudad y código postal. Requieren protección o manipulación (generalización) porque, aunque aislados no identifican a una persona, al combinarse entre sí mediante ataques de vinculación pueden aislar a un individuo dentro de un grupo reducido y reidentificarlo.

### 19.2 Enmascaramiento
* **Qué se ocultó:** Se ocultaron parcialmente los caracteres del correo electrónico, número telefónico y RFC.
* **Para quién:** Para los usuarios pertenecientes al rol operativo de `soporte`.
* **Por qué:** Para aplicar el principio de minimización de datos. El personal de soporte técnico solo requiere confirmar la identidad o verificar datos de contacto parciales, sin necesidad de visualizar la información sensible de forma expuesta.
* **Mecanismo utilizado:** Se creó una vista dinámica (`v_clientes_soporte`) utilizando funciones de manipulación de texto en SQL (`CONCAT`, `LEFT`, `RIGHT`, `SUBSTRING`, `POSITION`) para reemplazar los caracteres intermedios por asteriscos o caracteres de enmascaramiento.

### 19.3 Seudonimización
* **Cómo se generaron los tokens:** Se utilizaron identificadores únicos universales versión 4 (UUID v4) generados dinámicamente mediante la función `gen_random_uuid()` de la extensión `pgcrypto`.
* **Dónde se encuentra el mapa de correspondencia:** En el esquema privado `pii`, dentro de la tabla de mapeo `pii.mapa_cliente`.
* **Quién debería poder acceder a él:** Únicamente los administradores del sistema, el Oficial de Protección de Datos (DPO) o procesos automatizados con privilegios elevados y auditados.
* **Por qué se separaron los permisos:** Para evitar la reidentificación directa por parte del rol de analítica, garantizando que este solo pueda consultar datos desacoplados de la identidad real del usuario.

### 19.4 Anonimización
* **Identificadores eliminados:** Nombre, correo electrónico, teléfono, RFC e ID secuencial original.
* **Atributos generalizados:** La edad (convertida en rangos: `18-30`, `31-45`, `46+`) y la ubicación geográfica (reduciendo el código postal a sus primeros 1 o 2 dígitos para representar regiones amplias).
* **Grupos suprimidos:** Aquellas combinaciones de datos (cuasi-identificadores agrupados) cuya frecuencia de registros fuera inferior al umbral $k$ ($k < 5$), aplicando la cláusula `HAVING COUNT(*) >= 5`.
* **Riesgo de reidentificación permanente:** Existe un riesgo residual si los datos anonimizados se cruzan o vinculan con bases de datos externas públicas o adicionales (*linkage attack*).

### 19.5 Retención
* **Criterio utilizado:** Criterio temporal basado en el ciclo de vida de los datos. Se identifican registros con una antigüedad de alta superior a 5 años (`fecha_alta < CURRENT_DATE - INTERVAL '5 years'`).
* **Información a conservar:** Datos mínimos necesarios para el cumplimiento de obligaciones legales, fiscales o auditorías que por ley exijan un periodo de conservación específico.
* **Información a eliminar:** Datos personales directos y registros de usuarios inactivos o sin obligaciones contractuales vigentes.
* **Controles previos a la eliminación:**
  1. Aprobación formal por parte del área Legal y del Oficial de Protección de Datos (DPO).
  2. Generación de un respaldo inmutable (*backup*) cifrado antes de la purga.
  3. Registro y auditoría formal del proceso de borrado (*audit logs*).

### 19.6 Conclusiones
* **Área de soporte:** **Enmascaramiento de datos (Data Masking)** mediante vistas. Permite operar y validar usuarios sin exponer la PII completa.
* **Área de analítica:** **Seudonimización** (reemplazo por tokens UUID). Permite realizar estudios de comportamiento y modelos de datos sin vincular directamente la identidad real del usuario.
* **Publicar estadísticas:** **Anonimización y $k$-anonimato** (generalización y supresión). Garantiza que los conjuntos de datos públicos no permitan reidentificar a ningún individuo.
* **¿Por qué ninguna técnica sustituye al control de acceso?:** Porque el enmascaramiento, seudonimización y anonimización modifican o estructuran la información, pero sin un control de acceso riguroso (roles, permisos `GRANT`/`REVOKE`, autenticación), cualquier usuario no autorizado podría consultar, modificar o eludir las vistas y tablas subyacentes donde reside la información original.

---

## 20. Preguntas de reflexión

1. **¿Cuál es la diferencia entre enmascaramiento y seudonimización?**  
   El enmascaramiento oculta visualmente parte de los caracteres de un dato sensible manteniendo su formato original para un uso operativo parcial, mientras que la seudonimización reemplaza por completo el identificador por un código irreconocible (token/UUID), separando la identidad del resto de la información.

2. **¿Por qué la seudonimización no significa anonimización?**  
   Porque la seudonimización es un proceso **reversible** si se cuenta con la tabla o mapa de correspondencia entre el token y la PII original. La anonimización busca ser **irreversible**.

3. **¿Por qué eliminar nombre y RFC no garantiza que un conjunto de datos sea anónimo?**  
   Porque persisten los cuasi-identificadores (como edad, código postal o género) que, al combinarse, permiten realizar un aislamiento por combinación (*singling out*) y reidentificar individualmente a un usuario.

4. **¿Qué función tienen los cuasi-identificadores?**  
   Sirven para contextualizar la información en análisis demográficos o geográficos, pero requieren especial atención porque son los atributos que facilitan los ataques de reidentificación por vinculación con otras fuentes de datos.

5. **¿Por qué es importante separar el mapa de seudonimización?**  
   Para evitar que un usuario con privilegios analíticos o de consulta general pueda realizar un `JOIN` entre el token seudonimizado y la tabla que contiene las identidades reales.

6. **¿Qué principio de seguridad se aplica al impedir que el analista acceda al mapa?**  
   El principio de **menor privilegio** (*Principle of Least Privilege*) y la **separación de funciones** (*Separation of Duties*).

7. **¿Por qué una vista puede ser preferible a entregar acceso directo a la tabla?**  
   Porque una vista actúa como una capa de abstracción y control centralizado que permite exponer únicamente los campos y formatos estrictamente necesarios para un rol, protegiendo los datos subyacentes de la tabla real.

8. **¿Qué diferencia existe entre proteger un dato para visualización y protegerlo contra acceso no autorizado?**  
   Protegerlo para visualización (como el enmascaramiento) modifica la presentación de la información expuesta a usuarios legítimos, mientras que protegerlo contra acceso no autorizado implica establecer restricciones de seguridad a nivel de motor (permisos SQL, autenticación y cifrado) para evitar que el dato sea leído o extraído por quien no tiene privilegios.

9. **¿Por qué la retención forma parte de la protección de datos?**  
   Porque se fundamenta en el principio de minimización y limitación del plazo de conservación: conservar datos que ya no son necesarios incrementa innecesariamente la superficie de impacto ante incidentes de seguridad o fugas de información.

10. **¿Qué riesgo existe si una organización conserva información indefinidamente?**  
    Aumenta sustancialmente el riesgo de exposición masiva frente a ciberataques, genera posibles sanciones por incumplimiento de normativas de privacidad (como RGPD o LFPDPPP) e incrementa los costos y la complejidad en la gestión y custodia de la infraestructura.
