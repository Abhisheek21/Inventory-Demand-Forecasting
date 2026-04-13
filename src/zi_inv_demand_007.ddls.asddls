@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inventory Demand Child'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZI_INV_DEMAND_007
  as select from zinv_demand_007
  association to parent ZI_INV_FORECAST_007 as _Header
    on $projection.product_id = _Header.product_id
{
  key demand_id,
      product_id,
      demand_date,
      quantity_sold,

      _Header
}
