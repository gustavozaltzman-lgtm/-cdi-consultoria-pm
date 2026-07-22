-- CDI Consultoría — seed_cheeky.sql
-- Dataset realista: "Proyecto ACAI-Cheeky" — Auditoría Cíclica Preventiva y
-- Diagnóstico de Causa Raíz de Inventario para Cheeky S.A. (retail indumentaria infantil).
-- Crea la empresa "Cheeky S.A." (multi-tenant) y carga su proyecto completo.
-- Ejecutar después de schema.sql, sobre una base que ya tenga las tablas creadas.

BEGIN;

INSERT INTO companies (name, slug) VALUES ('Cheeky S.A.', 'cheeky')
ON CONFLICT (slug) DO NOTHING;

INSERT INTO config (company_id, project_name, client_name, start_date, end_date, status)
SELECT id, 'Implementación Servicio Auditoría Cíclica de Inventarios - Cheeky', 'Cheeky S.A.', '2026-08-01', '2026-09-25', 'En proceso'
FROM companies WHERE slug = 'cheeky'
ON CONFLICT (company_id) DO UPDATE SET
  project_name = EXCLUDED.project_name, client_name = EXCLUDED.client_name,
  start_date = EXCLUDED.start_date, end_date = EXCLUDED.end_date, status = EXCLUDED.status;

-- ---------------------------------------------------------
-- TEAM MEMBERS (4)
-- ---------------------------------------------------------
INSERT INTO team_members (company_id, name, role, email, color)
SELECT c.id, v.name, v.role, v.email, v.color
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Martina Ibáñez','Líder de Proyecto CDI','martina.ibanez@cdiconsultoria.com','#1e3a5f'),
('Federico Suárez','Auditor Senior de Campo CDI','federico.suarez@cdiconsultoria.com','#38a169'),
('Lucía Fernández','Gerente de Operaciones Cheeky','lucia.fernandez@cheeky.com.ar','#d69e2e'),
('Bruno Castellano','Jefe de Inventarios Cheeky','bruno.castellano@cheeky.com.ar','#2c5282')
) AS v(name, role, email, color)
ON CONFLICT (company_id, email) WHERE email IS NOT NULL DO NOTHING;

-- ---------------------------------------------------------
-- TASKS (28 tareas, 5 etapas, ~08/2026-09/2026, avance ~45-50%)
-- ---------------------------------------------------------
INSERT INTO tasks (company_id, stage, activity, description, responsible, priority, start_date, end_date, status, progress, observations)
SELECT c.id, v.stage, v.activity, v.description, v.responsible, v.priority, v.start_date::date, v.end_date::date, v.status, v.progress::decimal, v.observations
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
-- Etapa 1: Diagnóstico Inicial y Matriz ABC
('Diagnóstico Inicial y Matriz ABC','Kickoff del proyecto ACAI-Cheeky','Reunión de arranque, alcance y equipo','Martina Ibáñez','Alta','2026-08-01','2026-08-02','Finalizado','100','Acta de inicio firmada'),
('Diagnóstico Inicial y Matriz ABC','Extracción de catálogo maestro SKU (talle/color) del ERP','Exportación de maestro de artículos y variantes desde el ERP de Cheeky','Bruno Castellano','Alta','2026-08-02','2026-08-03','Finalizado','100',NULL),
('Diagnóstico Inicial y Matriz ABC','Definición de matriz ABC por costo y rotación','Segmentación de SKUs críticos por valor e impacto en ventas','Federico Suárez','Alta','2026-08-03','2026-08-05','Finalizado','100',NULL),
('Diagnóstico Inicial y Matriz ABC','Selección de muestra de sucursales y SKUs críticos','Definición de las 3 tiendas piloto por tráfico y complejidad de mix','Martina Ibáñez','Media','2026-08-04','2026-08-05','Finalizado','100','Alto Palermo, Unicenter, DOT Baires'),
('Diagnóstico Inicial y Matriz ABC','Cruce de catálogo de variantes talle/color vs. codificación de góndola','Detección de inconsistencias de codificación entre ERP y piso de venta','Federico Suárez','Alta','2026-08-05','2026-08-07','Finalizado','100',NULL),
('Diagnóstico Inicial y Matriz ABC','Informe de diagnóstico inicial y línea base','Documento consolidado con hallazgos y línea base de KPIs','Martina Ibáñez','Crítica','2026-08-07','2026-08-09','Finalizado','100','Aprobado por Gerencia de Operaciones'),
-- Etapa 2: Diseño de Protocolo SOP y Calibración
('Diseño de Protocolo SOP y Calibración','Diseño de SOP de auditoría cíclica de 2 horas en tienda','Procedimiento estándar de conteo con foco en variantes talle/color','Federico Suárez','Crítica','2026-08-10','2026-08-12','Finalizado','100',NULL),
('Diseño de Protocolo SOP y Calibración','Diseño de hoja de conteo ciego (doble conteo)','Formato de conteo ciego como control cruzado de auditor','Federico Suárez','Media','2026-08-12','2026-08-13','Finalizado','100',NULL),
('Diseño de Protocolo SOP y Calibración','Configuración y prueba de colectores/scanners RF','Puesta a punto de dispositivos de lectura para el piloto','Bruno Castellano','Alta','2026-08-13','2026-08-15','Finalizado','100',NULL),
('Diseño de Protocolo SOP y Calibración','Capacitación a auditores de campo en protocolo SOP','Entrenamiento del equipo de auditoría en el nuevo SOP','Federico Suárez','Alta','2026-08-15','2026-08-17','Finalizado','100',NULL),
('Diseño de Protocolo SOP y Calibración','Validación del protocolo con Gerencia de Operaciones','Revisión conjunta y aprobación final del SOP','Lucía Fernández','Media','2026-08-17','2026-08-19','Finalizado','100',NULL),
-- Etapa 3: Piloto en Tiendas Críticas
('Piloto en Tiendas Críticas','Auditoría piloto Tienda Alto Palermo (2hs)','Ejecución de auditoría cíclica en sucursal de alto tráfico','Federico Suárez','Crítica','2026-08-20','2026-08-20','Finalizado','100',NULL),
('Piloto en Tiendas Críticas','Análisis de descalces Tienda Alto Palermo','Procesamiento de resultados y primer diagnóstico de causas','Federico Suárez','Alta','2026-08-21','2026-08-22','Finalizado','100','8% de descalce monetario neto detectado'),
('Piloto en Tiendas Críticas','Auditoría piloto Tienda Unicenter (2hs)','Ejecución de auditoría cíclica en sucursal de alto tráfico','Federico Suárez','Crítica','2026-08-24','2026-08-24','Finalizado','100',NULL),
('Piloto en Tiendas Críticas','Análisis de descalces Tienda Unicenter','Procesamiento de resultados con hoja de conteo ajustada por variante','Federico Suárez','Alta','2026-08-25','2026-08-26','En proceso','50',NULL),
('Piloto en Tiendas Críticas','Auditoría piloto Tienda DOT Baires (2hs)','Ejecución de auditoría cíclica en sucursal de alto tráfico','Federico Suárez','Crítica','2026-08-28','2026-08-28','No iniciado','0',NULL),
('Piloto en Tiendas Críticas','Análisis de descalces Tienda DOT Baires','Procesamiento de resultados de la tercera tienda piloto','Federico Suárez','Alta','2026-08-29','2026-08-31','No iniciado','0',NULL),
('Piloto en Tiendas Críticas','Consolidado de resultados del piloto (3 tiendas)','Informe comparativo de las 3 auditorías piloto','Martina Ibáñez','Alta','2026-09-01','2026-09-02','No iniciado','0',NULL),
-- Etapa 4: Análisis de Causa Raíz y Matriz de Descalce
('Análisis de Causa Raíz y Matriz de Descalce','Construcción de matriz de descalce por tipo de falla','Clasificación cuantitativa de descalces por categoría de causa','Federico Suárez','Alta','2026-09-03','2026-09-05','No iniciado','0',NULL),
('Análisis de Causa Raíz y Matriz de Descalce','Clasificación de causas: error de recepción en muelle','Análisis de discrepancias originadas en el ingreso de mercadería','Bruno Castellano','Media','2026-09-05','2026-09-07','No iniciado','0',NULL),
('Análisis de Causa Raíz y Matriz de Descalce','Clasificación de causas: cruce de variantes en POS','Análisis de errores de venteo por confusión de talle/color en caja','Federico Suárez','Alta','2026-09-05','2026-09-07','No iniciado','0',NULL),
('Análisis de Causa Raíz y Matriz de Descalce','Clasificación de causas: ubicación fantasma en backroom','Análisis de stock registrado en depósito secundario sin ubicación real','Federico Suárez','Media','2026-09-07','2026-09-09','No iniciado','0',NULL),
('Análisis de Causa Raíz y Matriz de Descalce','Clasificación de causas: merma no identificada','Análisis de mermas sin registro ni justificación documentada','Bruno Castellano','Alta','2026-09-09','2026-09-11','No iniciado','0',NULL),
('Análisis de Causa Raíz y Matriz de Descalce','Diseño del Plan de Acción Correctivo (CAP) por causa raíz','Definición de acciones correctivas priorizadas por impacto','Martina Ibáñez','Crítica','2026-09-11','2026-09-16','No iniciado','0',NULL),
-- Etapa 5: Institucionalización y Handover
('Institucionalización y Handover','Diseño del Scorecard Ejecutivo de Inventario','Tablero de indicadores para seguimiento gerencial permanente','Martina Ibáñez','Alta','2026-09-17','2026-09-19','No iniciado','0',NULL),
('Institucionalización y Handover','Presentación del Scorecard a Gerencia Cheeky','Presentación ejecutiva de resultados y CAP a Dirección','Martina Ibáñez','Crítica','2026-09-21','2026-09-21','No iniciado','0',NULL),
('Institucionalización y Handover','Definición de calendario de recurrencia de auditoría cíclica','Cronograma trimestral de auditorías cíclicas permanentes','Federico Suárez','Media','2026-09-22','2026-09-23','No iniciado','0',NULL),
('Institucionalización y Handover','Informe final y cierre de proyecto ACAI-Cheeky','Documento de cierre, lecciones aprendidas y entregables','Martina Ibáñez','Crítica','2026-09-24','2026-09-25','No iniciado','0',NULL)
) AS v(stage, activity, description, responsible, priority, start_date, end_date, status, progress, observations);

-- ---------------------------------------------------------
-- PLAN_STAGES (plan metodológico ACAI)
-- ---------------------------------------------------------
INSERT INTO plan_stages (company_id, stage, activity_id, activity, description, deliverable, estimated_duration, dependencies, completed)
SELECT c.id, v.stage, v.activity_id, v.activity, v.description, v.deliverable, v.estimated_duration, v.dependencies, v.completed::boolean
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Diagnóstico Inicial y Matriz ABC','D-1','Extracción y cruce de catálogo maestro (talle/color)','Consolidación del catálogo ERP vs. codificación de piso de venta','Catálogo maestro consolidado','3 días',NULL,'TRUE'),
('Diagnóstico Inicial y Matriz ABC','D-2','Matriz ABC y selección de muestra','Segmentación de SKUs/tiendas críticos y línea base de KPIs','Informe de diagnóstico y línea base','4 días','D-1','TRUE'),
('Diseño de Protocolo SOP y Calibración','P-1','Diseño de SOP y hoja de conteo ciego','Procedimiento estándar de auditoría cíclica de 2 horas','SOP aprobado','4 días','D-2','TRUE'),
('Diseño de Protocolo SOP y Calibración','P-2','Calibración de colectores y capacitación a auditores','Puesta a punto de dispositivos y entrenamiento del equipo','Equipo capacitado y colectores calibrados','5 días','P-1','TRUE'),
('Piloto en Tiendas Críticas','PI-1','Piloto Tienda Alto Palermo','Auditoría y análisis de descalce en primera tienda piloto','Informe de descalce Tienda 1','3 días','P-2','TRUE'),
('Piloto en Tiendas Críticas','PI-2','Piloto Tienda Unicenter','Auditoría y análisis de descalce en segunda tienda piloto','Informe de descalce Tienda 2','3 días','PI-1','FALSE'),
('Piloto en Tiendas Críticas','PI-3','Piloto Tienda DOT Baires y consolidado','Auditoría en tercera tienda y consolidado de las 3 tiendas','Informe consolidado de piloto','6 días','PI-2','FALSE'),
('Análisis de Causa Raíz y Matriz de Descalce','CR-1','Matriz de descalce y clasificación de causas','Clasificación por error de recepción, cruce POS, ubicación fantasma y merma','Matriz de causa raíz','2 semanas','PI-3','FALSE'),
('Análisis de Causa Raíz y Matriz de Descalce','CR-2','Diseño del Plan de Acción Correctivo (CAP)','Definición de acciones correctivas priorizadas por impacto monetario','CAP aprobado','1 semana','CR-1','FALSE'),
('Institucionalización y Handover','H-1','Scorecard Ejecutivo y presentación a Gerencia','Tablero de indicadores y presentación de resultados a Dirección','Scorecard aprobado','1 semana','CR-2','FALSE'),
('Institucionalización y Handover','H-2','Calendario de recurrencia e informe final','Cronograma de auditoría cíclica permanente y cierre del proyecto','Informe final de cierre','1 semana','H-1','FALSE')
) AS v(stage, activity_id, activity, description, deliverable, estimated_duration, dependencies, completed)
ON CONFLICT (company_id, activity_id) DO NOTHING;

-- ---------------------------------------------------------
-- RISKS (6)
-- ---------------------------------------------------------
INSERT INTO risks (company_id, risk, category, probability, impact, responsible, mitigation, contingency_plan, status)
SELECT c.id, v.* FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Resistencia del personal de tienda a ser auditado en horario comercial','Organizacional','Alta','Alto','Federico Suárez','Programar auditorías en horarios de menor tráfico y comunicar previamente a encargados','Reprogramar auditoría fuera de horario pico','Activo'),
('Inconsistencia de datos teóricos en el ERP de Cheeky al momento de la extracción','Tecnológico','Media','Alto','Bruno Castellano','Validar extracción con corte de operaciones (freeze) antes de cada auditoría','Recontar con nueva extracción validada','Activo'),
('Alta rotación de personal de cajas que perpetúa cruces de SKU talle/color','Organizacional','Alta','Medio','Lucía Fernández','Reforzar capacitación en POS para nuevos ingresos','Auditoría de refuerzo en tiendas con alta rotación','Activo'),
('Discrepancias entre conteo físico y colector RF por fallas de lectura de etiqueta','Tecnológico','Media','Medio','Federico Suárez','Doble conteo ciego como control cruzado','Recuento manual en SKUs con discrepancia','Mitigado'),
('Indisponibilidad de personal de tienda para acompañar la auditoría','Operativo','Media','Bajo','Lucía Fernández','Coordinar agenda con una semana de anticipación','Reprogramar con encargado suplente','Activo'),
('Resistencia a implementar el Plan de Acción Correctivo por sobrecarga operativa de tiendas','Organizacional','Media','Alto','Martina Ibáñez','Priorizar CAP por impacto monetario e involucrar a Gerencia desde el diseño','Escalamiento a Dirección de Cheeky','Activo')
) AS v(risk, category, probability, impact, responsible, mitigation, contingency_plan, status);

-- ---------------------------------------------------------
-- MINUTES (3)
-- ---------------------------------------------------------
INSERT INTO minutes (company_id, meeting_date, meeting_type, participants, topic, decisions, actions, responsible, commitment_date, status)
SELECT c.id, v.meeting_date::date, v.meeting_type, v.participants, v.topic, v.decisions, v.actions, v.responsible, v.commitment_date::date, v.status
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('2026-08-01','Kickoff','Martina Ibáñez, Federico Suárez, Lucía Fernández, Bruno Castellano','Arranque del proyecto ACAI-Cheeky','Se aprueba alcance, cronograma de 8 semanas y las 3 tiendas piloto (Alto Palermo, Unicenter, DOT Baires)','Enviar catálogo maestro ERP y accesos a colectores RF','Bruno Castellano','2026-08-04','Cerrada'),
('2026-08-22','Revisión de Piloto','Federico Suárez, Lucía Fernández','Revisión de resultados del piloto en Tienda Alto Palermo','Se detecta 8% de descalce monetario neto, mayormente por cruce de talle/color en POS; se ajusta protocolo de conteo en percheros','Ajustar hoja de conteo ciego para separar por variante antes del piloto en Unicenter','Federico Suárez','2026-08-24','Cerrada'),
('2026-09-02','Presentación Preliminar','Martina Ibáñez, Lucía Fernández, Bruno Castellano','Presentación preliminar de hallazgos de causa raíz del piloto','Se prioriza el Plan de Acción Correctivo sobre errores de recepción en muelle','Convocar a Jefe de Recepción y Logística a la próxima etapa de análisis','Martina Ibáñez','2026-09-05','En curso')
) AS v(meeting_date, meeting_type, participants, topic, decisions, actions, responsible, commitment_date, status);

-- ---------------------------------------------------------
-- ACTIONS (6, algunas originadas en minutas)
-- ---------------------------------------------------------
INSERT INTO actions (company_id, action_name, description, stage, responsible, priority, start_date, commitment_date, status, progress, origin, origin_minute_id)
SELECT c.id, v.action_name, v.description, v.stage, v.responsible, v.priority, v.start_date::date, v.commitment_date::date, v.status, v.progress::decimal, v.origin,
  (SELECT id FROM minutes m WHERE m.company_id = c.id ORDER BY m.id LIMIT 1 OFFSET (v.minute_offset::int - 1))
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Enviar catálogo maestro ERP y accesos a colectores RF','Exportación de maestro de artículos y credenciales de acceso RF','Diagnóstico Inicial y Matriz ABC','Bruno Castellano','Alta','2026-08-01','2026-08-04','Cerrada','100','Minuta','1'),
('Ajustar hoja de conteo ciego para separar por variante talle/color','Rediseño del formato de conteo tras hallazgos de Alto Palermo','Piloto en Tiendas Críticas','Federico Suárez','Alta','2026-08-22','2026-08-24','Cerrada','100','Minuta','2'),
('Convocar a Jefe de Recepción y Logística Cheeky a la etapa de causa raíz','Incorporación de un referente de recepción al análisis','Análisis de Causa Raíz y Matriz de Descalce','Martina Ibáñez','Media','2026-09-02','2026-09-05','En curso','40','Minuta','3'),
('Solicitar reporte de mermas de los últimos 6 meses a Loss Prevention','Insumo para la clasificación de causas de merma no identificada','Análisis de Causa Raíz y Matriz de Descalce','Bruno Castellano','Alta','2026-09-01','2026-09-08','No iniciada','0','Gestión de riesgos',NULL),
('Coordinar agenda de auditoría en tiendas con encargados suplentes','Mitigación del riesgo de indisponibilidad de personal de tienda','Piloto en Tiendas Críticas','Lucía Fernández','Media','2026-08-20','2026-08-27','En curso','50','Gestión de riesgos',NULL),
('Preparar propuesta de calendario de recurrencia trimestral','Diseño de la cadencia de auditoría cíclica post-implementación','Institucionalización y Handover','Federico Suárez','Media','2026-09-10','2026-09-20','No iniciada','0','Manual',NULL)
) AS v(action_name, description, stage, responsible, priority, start_date, commitment_date, status, progress, origin, minute_offset);

-- ---------------------------------------------------------
-- KPIS (8 indicadores de auditoría cíclica de inventario)
-- ---------------------------------------------------------
INSERT INTO kpis (company_id, category, indicator, unit, initial_value, target_value, current_value, responsible)
SELECT c.id, v.category, v.indicator, v.unit, v.initial_value::decimal, v.target_value::decimal, v.current_value::decimal, v.responsible
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Precisión de Inventario','Exactitud de Registro de Inventario (IRA)','%','82.0','96.0','85.0','Federico Suárez'),
('Tiempos','Tiempo medio de relevamiento por sucursal','min','165','120','148','Federico Suárez'),
('Financiero','% de Descalce Monetario Neto','%','6.8','1.5','5.4','Bruno Castellano'),
('Backroom','Ratio de Ubicaciones Fantasma en Backroom','%','12.0','2.0','9.5','Bruno Castellano'),
('Calidad POS','Errores de Lectura por Cruce de Talle/Color en POS','%','9.5','2.0','7.8','Lucía Fernández'),
('Cumplimiento','% de Cumplimiento del Plan de Acción Correctivo (CAP)','%','0','90','15','Martina Ibáñez'),
('Recepción','Mermas no identificadas en muelle de recepción','%','4.2','1.0','3.6','Bruno Castellano'),
('Servicio','Quiebres de Stock Falsos (Stock Fantasma)','%','11.0','3.0','8.9','Lucía Fernández')
) AS v(category, indicator, unit, initial_value, target_value, current_value, responsible);

-- ---------------------------------------------------------
-- BEFORE_AFTER (5)
-- ---------------------------------------------------------
INSERT INTO before_after (company_id, area, indicator, unit, initial_value, final_value, observations)
SELECT c.id, v.area, v.indicator, v.unit, v.initial_value::decimal, NULLIF(v.final_value,'')::decimal, v.observations
FROM (SELECT id FROM companies WHERE slug = 'cheeky') c
CROSS JOIN (VALUES
('Operaciones','Tiempo de paro para conteo físico anual','horas/año','24','','Objetivo proyectado: 0h con conteo cíclico permanente, sin cierre de tienda'),
('Inventario','Exactitud de Registro de Inventario (IRA)','%','82.0','','Objetivo proyectado: 96%, medición final al cierre del proyecto'),
('Ventas','Pérdida mensual por ventas canceladas por stock fantasma','USD/mes','42000','','Reducción proyectada de ~70% tras implementación del CAP'),
('Recepción','Mermas no identificadas en muelle de recepción','%','4.2','','Medición final tras institucionalización del protocolo'),
('Backroom','Ubicaciones fantasma en backroom','%','12.0','','Medición final tras el primer ciclo de recurrencia trimestral')
) AS v(area, indicator, unit, initial_value, final_value, observations);

COMMIT;
