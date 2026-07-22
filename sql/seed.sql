-- CDI Consultoría — seed.sql
-- Datos de demo: proyecto de consultoría logística en almacenes e inventarios.
-- Ejecutar después de schema.sql.

BEGIN;

UPDATE config SET
  project_name = 'Optimización de Almacenes e Inventarios — Planta Norte',
  client_name  = 'Distribuidora Andina S.A.',
  start_date   = '2026-02-02',
  end_date     = '2026-07-10',
  status       = 'En proceso',
  updated_at   = now()
WHERE id = 1;

-- ---------------------------------------------------------
-- TASKS (30 tareas, 5 etapas)
-- ---------------------------------------------------------
INSERT INTO tasks (stage, activity, description, responsible, priority, start_date, end_date, status, progress, observations) VALUES
('Diagnóstico','Kickoff y relevamiento inicial','Reunión de arranque, alcance y objetivos','Gustavo Zaltzman','Alta','2026-02-02','2026-02-04','Finalizado',100,'Firmado acta de inicio'),
('Diagnóstico','Relevamiento de layout de almacén','Medición y planos de la planta actual','Equipo CDI','Media','2026-02-05','2026-02-10','Finalizado',100,NULL),
('Diagnóstico','Análisis de flujo de recepción','Mapeo del proceso de recepción de mercadería','Equipo CDI','Alta','2026-02-05','2026-02-12','Finalizado',100,NULL),
('Diagnóstico','Análisis de flujo de picking','Observación en piso del proceso de picking','Equipo CDI','Alta','2026-02-10','2026-02-17','Finalizado',100,NULL),
('Diagnóstico','Relevamiento de sistemas actuales','WMS/ERP existentes, integraciones','Analista TI','Media','2026-02-10','2026-02-14','Finalizado',100,NULL),
('Diagnóstico','Entrevistas a responsables de área','Recepción, picking, despacho, inventarios','Gustavo Zaltzman','Media','2026-02-12','2026-02-18','Finalizado',100,NULL),
('Diagnóstico','Informe de diagnóstico','Documento consolidado con hallazgos','Gustavo Zaltzman','Crítica','2026-02-18','2026-02-24','Finalizado',100,'Aprobado por cliente'),
('Diseño','Definición de estrategia de slotting','Reglas de ubicación por rotación ABC','Consultor Senior','Alta','2026-02-25','2026-03-05','Finalizado',100,NULL),
('Diseño','Rediseño de layout de almacén','Nuevo layout optimizado por flujo','Consultor Senior','Crítica','2026-02-25','2026-03-10','Finalizado',100,NULL),
('Diseño','Diseño de proceso de recepción','Nuevo flujo con control de calidad','Equipo CDI','Media','2026-03-05','2026-03-12','Finalizado',100,NULL),
('Diseño','Diseño de proceso de picking','Picking por oleadas y rutas optimizadas','Equipo CDI','Alta','2026-03-10','2026-03-18','En proceso',80,NULL),
('Diseño','Definición de política de inventario','Puntos de reorden, stock de seguridad','Consultor Senior','Media','2026-03-12','2026-03-20','En proceso',70,NULL),
('Diseño','Especificación funcional de WMS','Requerimientos para nuevo sistema','Analista TI','Alta','2026-03-15','2026-03-25','En proceso',60,NULL),
('Diseño','Presentación de diseño a dirección','Validación ejecutiva del nuevo modelo','Gustavo Zaltzman','Crítica','2026-03-26','2026-03-27','No iniciado',0,'Depende de tareas anteriores'),
('Implementación','Selección de proveedor de WMS','Evaluación de alternativas de mercado','Analista TI','Alta','2026-03-28','2026-04-10','No iniciado',0,NULL),
('Implementación','Reconfiguración física de racks','Ejecución del nuevo layout','Contratista Obra','Crítica','2026-04-01','2026-04-20','No iniciado',0,NULL),
('Implementación','Recodificación de ubicaciones','Etiquetado y codificación de bins','Equipo CDI','Media','2026-04-15','2026-04-25','No iniciado',0,NULL),
('Implementación','Implementación de WMS — parametrización','Configuración del sistema seleccionado','Analista TI','Crítica','2026-04-20','2026-05-10','No iniciado',0,NULL),
('Implementación','Migración de datos maestros','SKUs, ubicaciones, stock inicial','Analista TI','Alta','2026-05-05','2026-05-15','No iniciado',0,NULL),
('Implementación','Integración WMS-ERP','Interfaces de intercambio de datos','Analista TI','Crítica','2026-05-10','2026-05-22','No iniciado',0,NULL),
('Implementación','Piloto en zona controlada','Prueba en una sección del almacén','Equipo CDI','Alta','2026-05-20','2026-05-30','No iniciado',0,NULL),
('Implementación','Ajustes post-piloto','Correcciones según resultados del piloto','Equipo CDI','Media','2026-05-30','2026-06-05','No iniciado',0,NULL),
('Capacitación','Diseño de plan de capacitación','Contenidos y cronograma de formación','Consultor Senior','Media','2026-05-15','2026-05-20','No iniciado',0,NULL),
('Capacitación','Capacitación a supervisores','Formación de líderes de turno','Consultor Senior','Alta','2026-06-01','2026-06-05','No iniciado',0,NULL),
('Capacitación','Capacitación a operarios','Formación en piso, por turnos','Consultor Senior','Alta','2026-06-05','2026-06-15','No iniciado',0,NULL),
('Capacitación','Manual de procedimientos','Documentación final de procesos','Equipo CDI','Media','2026-06-10','2026-06-18','No iniciado',0,NULL),
('Cierre','Go-live general','Puesta en marcha en todo el almacén','Gustavo Zaltzman','Crítica','2026-06-20','2026-06-22','No iniciado',0,NULL),
('Cierre','Acompañamiento post go-live','Soporte en sitio primeras semanas','Equipo CDI','Alta','2026-06-22','2026-07-02','No iniciado',0,NULL),
('Cierre','Medición de resultados','Comparativa antes/después e indicadores','Consultor Senior','Alta','2026-07-02','2026-07-07','No iniciado',0,NULL),
('Cierre','Informe final y cierre de proyecto','Documento de cierre y lecciones aprendidas','Gustavo Zaltzman','Crítica','2026-07-07','2026-07-10','No iniciado',0,NULL);

-- ---------------------------------------------------------
-- PLAN_STAGES (plan metodológico CDI)
-- ---------------------------------------------------------
INSERT INTO plan_stages (stage, activity_id, activity, description, deliverable, estimated_duration, dependencies, completed) VALUES
('Diagnóstico','D-1','Kickoff del proyecto','Reunión de arranque y alineación de expectativas','Acta de inicio','3 días',NULL,TRUE),
('Diagnóstico','D-2','Relevamiento operativo','Levantamiento de procesos actuales in situ','Informe de relevamiento','2 semanas','D-1',TRUE),
('Diagnóstico','D-3','Diagnóstico integral','Consolidación de hallazgos y brechas','Informe de diagnóstico','1 semana','D-2',TRUE),
('Diseño','E-1','Diseño de solución logística','Layout, slotting y procesos objetivo','Documento de diseño','3 semanas','D-3',TRUE),
('Diseño','E-2','Especificación de sistema','Requerimientos funcionales de WMS','Especificación funcional','2 semanas','E-1',FALSE),
('Diseño','E-3','Validación ejecutiva','Presentación y aprobación del diseño','Acta de aprobación','2 días','E-2',FALSE),
('Implementación','I-1','Adecuación física','Obra civil y reconfiguración de racks','Almacén reconfigurado','3 semanas','E-3',FALSE),
('Implementación','I-2','Implementación de WMS','Parametrización, migración e integración','Sistema en producción','5 semanas','I-1',FALSE),
('Implementación','I-3','Piloto controlado','Prueba en zona acotada y ajustes','Informe de piloto','2 semanas','I-2',FALSE),
('Capacitación','C-1','Formación de equipos','Capacitación a supervisores y operarios','Personal certificado','3 semanas','I-2',FALSE),
('Cierre','Z-1','Puesta en marcha','Go-live general del nuevo modelo','Almacén operativo','3 días','I-3',FALSE),
('Cierre','Z-2','Cierre y resultados','Medición de KPIs y cierre formal','Informe final','1 semana','Z-1',FALSE);

-- ---------------------------------------------------------
-- RISKS
-- ---------------------------------------------------------
INSERT INTO risks (risk, category, probability, impact, responsible, mitigation, contingency_plan, status) VALUES
('Resistencia al cambio del personal de piso','Organizacional','Alta','Alto','Consultor Senior','Plan de comunicación y capacitación temprana','Refuerzo de acompañamiento en piso durante go-live','Activo'),
('Demoras en la obra civil de racks','Operativo','Media','Alto','Contratista Obra','Cronograma con holguras y seguimiento semanal','Reprogramar go-live parcial por zonas','Activo'),
('Errores en migración de datos maestros','Tecnológico','Media','Alto','Analista TI','Pruebas de migración en ambiente de staging','Rollback a datos previos y reintento controlado','Activo'),
('Falta de disponibilidad del proveedor de WMS','Proveedores','Baja','Alto','Analista TI','Contrato con SLA y penalidades definidas','Activar proveedor alternativo preseleccionado','Activo'),
('Interrupción de operaciones durante el piloto','Operativo','Media','Medio','Equipo CDI','Piloto en horario de baja demanda','Plan de reversión inmediata a proceso anterior','Mitigado');

-- ---------------------------------------------------------
-- MINUTES
-- ---------------------------------------------------------
INSERT INTO minutes (meeting_date, meeting_type, participants, topic, decisions, actions, responsible, commitment_date, status) VALUES
('2026-02-02','Kickoff','Gustavo Zaltzman, Gerente de Operaciones, Equipo CDI','Arranque del proyecto','Se aprueba alcance y cronograma general','Enviar plan detallado de relevamiento','Gustavo Zaltzman','2026-02-05','Cerrada'),
('2026-02-24','Revisión de diagnóstico','Gustavo Zaltzman, Dirección, Consultor Senior','Presentación de hallazgos','Se aprueba el diagnóstico y se avanza a diseño','Iniciar etapa de diseño de solución','Consultor Senior','2026-02-25','Cerrada'),
('2026-03-20','Seguimiento de diseño','Consultor Senior, Analista TI, Gerente de Operaciones','Avance de diseño de procesos y WMS','Se solicita adelantar especificación funcional de WMS','Priorizar especificación de WMS sobre política de inventario','Analista TI','2026-03-25','En curso');

-- ---------------------------------------------------------
-- ACTIONS (algunas originadas en minutas)
-- ---------------------------------------------------------
INSERT INTO actions (action_name, description, stage, responsible, priority, start_date, commitment_date, status, progress, origin, origin_minute_id) VALUES
('Enviar plan detallado de relevamiento','Cronograma detallado de visitas y entrevistas','Diagnóstico','Gustavo Zaltzman','Alta','2026-02-02','2026-02-05','Cerrada',100,'Minuta',1),
('Iniciar etapa de diseño de solución','Kickoff interno de la etapa de diseño','Diseño','Consultor Senior','Alta','2026-02-25','2026-02-25','Cerrada',100,'Minuta',2),
('Priorizar especificación de WMS','Adelantar especificación funcional sobre otras tareas de diseño','Diseño','Analista TI','Crítica','2026-03-20','2026-03-25','En curso',60,'Minuta',3),
('Contactar proveedores alternativos de WMS','Sondeo de mercado como respaldo ante riesgo de proveedor','Diseño','Analista TI','Media','2026-03-15','2026-03-30','No iniciada',0,'Gestión de riesgos',NULL);

-- ---------------------------------------------------------
-- KPIS (10 indicadores logísticos)
-- ---------------------------------------------------------
INSERT INTO kpis (category, indicator, unit, initial_value, target_value, current_value, responsible) VALUES
('Precisión de Inventario','Exactitud de Inventario (ERI)','%',82.0,98.0,85.5,'Consultor Senior'),
('Productividad','Unidades por Hora (UPH) — Picking','uds/h',45,75,52,'Equipo CDI'),
('Tiempos','Tiempo promedio de recepción','min/pallet',38,15,32,'Equipo CDI'),
('Tiempos','Tiempo de ciclo de picking','min/pedido',22,10,19,'Equipo CDI'),
('Calidad','Tasa de errores de picking','%',3.2,0.5,2.6,'Consultor Senior'),
('Ocupación','Utilización de espacio de almacén','%',61,85,66,'Consultor Senior'),
('Costos','Costo operativo por pedido','USD',4.80,3.00,4.40,'Gerente de Operaciones'),
('Servicio','Nivel de servicio (OTIF)','%',88,97,90,'Gerente de Operaciones'),
('Productividad','Rotación de inventario','veces/año',6.2,9.0,6.8,'Consultor Senior'),
('Tiempos','Tiempo de ciclo de inventario (cycle count)','días',30,7,22,'Equipo CDI');

-- ---------------------------------------------------------
-- BEFORE_AFTER
-- ---------------------------------------------------------
INSERT INTO before_after (area, indicator, unit, initial_value, final_value, observations) VALUES
('Inventario','Exactitud de Inventario (ERI)','%',82.0,NULL,'Medición final pendiente hasta cierre de proyecto'),
('Picking','Unidades por Hora (UPH)','uds/h',45,NULL,'Se medirá tras estabilización post go-live'),
('Recepción','Tiempo promedio de recepción','min/pallet',38,NULL,NULL),
('Almacenamiento','Utilización de espacio','%',61,NULL,NULL),
('Servicio al cliente','Nivel de servicio (OTIF)','%',88,NULL,NULL);

-- ---------------------------------------------------------
-- TEAM MEMBERS
-- ---------------------------------------------------------
INSERT INTO team_members (name, role, email, color) VALUES
('Gustavo Zaltzman','Director de Proyecto','gustavo.zaltzman@cdiconsultoria.com','#1e3a5f'),
('Consultor Senior','Consultor Senior de Logística','consultor.senior@cdiconsultoria.com','#38a169'),
('Analista TI','Analista de Sistemas','analista.ti@cdiconsultoria.com','#d69e2e'),
('Equipo CDI','Equipo de Campo','equipo@cdiconsultoria.com','#4a5568'),
('Gerente de Operaciones','Sponsor del Cliente','operaciones@cliente.com','#2c5282')
ON CONFLICT (email) DO NOTHING;

COMMIT;
