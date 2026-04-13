@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inventory Forecast Projection'
@Metadata.allowExtensions: true

define root view entity ZC_INV_FORECAST_007
  provider contract transactional_query
  as projection on ZI_INV_FORECAST_007
{
  key product_id,
      product_name,
      category,
      current_stock,
      reorder_level,

      _Demand : redirected to composition child ZC_INV_DEMAND_007
}
