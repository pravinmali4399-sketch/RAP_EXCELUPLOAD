@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'View for scales price'
@Metadata.allowExtensions: true
define view entity ZPM_I_SCALESPRICE
  as select from zpm_price_scale
  association to parent ZPM_I_SALES_PRICE as _Parent on $projection.SalesPriceUuid = _Parent.uuid
{
  key id               as Id,
      sales_price_uuid as SalesPriceUuid,
      minimum_quantity as MinimumQuantity,
      unit             as Unit,
      scale_price      as ScalePrice,
      currency,
      @Semantics.user.createdBy: true
      created_by       as CreatedBy,

      @Semantics.systemDateTime.createdAt: true
      created_at       as CreatedAt,

      @Semantics.user.lastChangedBy: true
      last_changed_by  as LastChangedBy,

      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at  as LastChangedAt,
      _Parent
}
