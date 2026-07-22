// Fórmulas de KPIs de auditorías cíclicas — usadas tanto por el backend (cálculo
// autoritativo al guardar) como por el frontend (Optimistic UI antes de confirmar
// con el servidor). Un solo archivo para que ambos lados no puedan divergir.
(function (root, factory) {
  if (typeof module === 'object' && module.exports) {
    module.exports = factory();
  } else {
    root.AuditKpis = factory();
  }
})(typeof self !== 'undefined' ? self : this, function () {
  function round2(n) {
    return Math.round((Number(n) || 0) * 100) / 100;
  }

  function computeAuditKpis(input) {
    const totalSkus = Number(input.total_skus_counted) || 0;
    const exactSkus = Number(input.exact_skus) || 0;
    const theoreticalVal = Number(input.total_theoretical_val) || 0;
    const physicalVal = Number(input.total_physical_val) || 0;
    const ghostLocations = Number(input.ghost_locations_count) || 0;
    const posCrossErrors = Number(input.pos_cross_errors_count) || 0;

    return [
      {
        kpi_category: 'Precisión',
        kpi_name: 'IRA % (Exactitud de Inventario)',
        calculated_value: round2(totalSkus > 0 ? (exactSkus / totalSkus) * 100 : 0)
      },
      {
        kpi_category: 'Financiero',
        kpi_name: 'Descalce Monetario %',
        calculated_value: round2(theoreticalVal !== 0 ? (Math.abs(physicalVal - theoreticalVal) / theoreticalVal) * 100 : 0)
      },
      {
        kpi_category: 'Ubicaciones',
        kpi_name: 'Ubicaciones Fantasma %',
        calculated_value: round2(totalSkus > 0 ? (ghostLocations / totalSkus) * 100 : 0)
      },
      {
        kpi_category: 'Calidad',
        kpi_name: 'Errores de Cruce POS %',
        calculated_value: round2(totalSkus > 0 ? (posCrossErrors / totalSkus) * 100 : 0)
      }
    ];
  }

  return { computeAuditKpis };
});
