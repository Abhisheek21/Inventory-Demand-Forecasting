@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Inventory Demand Projection'
@Metadata.allowExtensions: true

define view entity ZC_INV_DEMAND_007
  as projection on ZI_INV_DEMAND_007
{
  key demand_id,
      product_id,
      demand_date,
      quantity_sold,

      _Header : redirected to parent ZC_INV_FORECAST_007
}
