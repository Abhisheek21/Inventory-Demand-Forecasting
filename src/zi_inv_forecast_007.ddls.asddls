@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Inventory Forecast Root'

@Metadata.ignorePropagatedAnnotations: true



define root view entity ZI_INV_FORECAST_007

as select from zinv_master_007

composition [0..*] of ZI_INV_DEMAND_007 as _Demand

{

key product_id,

product_name,

category,

current_stock,

reorder_level,


_Demand

}
 