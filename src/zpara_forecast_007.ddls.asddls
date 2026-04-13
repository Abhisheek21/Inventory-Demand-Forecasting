@EndUserText.label: 'Forecast Parameters'
define abstract entity ZPARA_FORECAST_007
{
  @EndUserText.label: 'Forecast Percentage (%)'
  forecast_percent : abap.int4;
  
  @EndUserText.label: 'Reason for Adjustment'
  forecast_reason  : abap.char(50);
}
