# Seguridad Multi-Tenant

Este documento describe las medidas de seguridad implementadas para asegurar el aislamiento de datos entre compañías.

## Principios de Seguridad

1. **Todos los recursos pertenecen a una compañía**: Cada registro (User, Chain, ChainType, etc.) debe tener una relación directa o indirecta con `Company`.

2. **Acceso solo a través de `current_company`**: Todos los controladores deben usar `current_company` para filtrar y crear recursos.

3. **Validación en múltiples capas**: 
   - Controladores: Filtran por `current_company` antes de cualquier operación
   - Modelos: Validaciones de `uniqueness` con scope de `company_id`
   - Base de datos: Foreign keys y constraints

## Implementación por Recurso

### Users
- ✅ `UsersController`: Usa `current_company.users.build` y `current_company.users.find`
- ✅ `User` model: `belongs_to :company` con validación de `uniqueness` por `company_id`

### Chains
- ✅ `ChainsController`: Usa `current_company.chains.build` y `current_company.chains.find`
- ✅ `Chain` model: `belongs_to :company` con validación de `uniqueness` por `company_id`

### ChainTypes
- ✅ `ChainTypesController`: Valida que la cadena pertenezca a `current_company` antes de crear/actualizar
- ✅ `ChainType` model: `belongs_to :chain` (que a su vez pertenece a `company`)
- ✅ Validación de `uniqueness` por `chain_id` (cada cadena puede tener tipos únicos)

## Buenas Prácticas

1. **Nunca usar `.new` directamente**: Siempre construir a través de la asociación de la compañía
   ```ruby
   # ❌ MAL
   @chain = Chain.new(chain_params)
   
   # ✅ BIEN
   @chain = current_company.chains.build(chain_params)
   ```

2. **Validar relaciones indirectas**: Para recursos que pertenecen a otros recursos (como ChainType → Chain → Company), validar que la cadena pertenezca a la compañía actual.

3. **Usar `find` con scope de compañía**: Nunca usar `Model.find(params[:id])` directamente
   ```ruby
   # ❌ MAL
   @chain = Chain.find(params[:id])
   
   # ✅ BIEN
   @chain = current_company.chains.find(params[:id])
   ```

## Rakes para Datos de Industria

Para ayudar a nuevos usuarios a tener datos iniciales, se pueden crear rakes que inserten datos de ejemplo específicos de la industria. Estos rakes deben:

1. **Solicitar confirmación de compañía**: Asegurar que el usuario confirme a qué compañía se agregarán los datos
2. **Validar permisos**: Solo administradores pueden ejecutar estos rakes
3. **Ser idempotentes**: Poder ejecutarse múltiples veces sin duplicar datos
4. **Usar transacciones**: Asegurar que todos los datos se creen o ninguno

### Ejemplo de estructura para rakes futuros:

```ruby
# lib/tasks/seed_industry_data.rake
namespace :db do
  namespace :seed do
    desc "Seed datos de industria para una compañía"
    task industry_data: :environment do
      # Solicitar ID de compañía
      # Validar que existe
      # Crear cadenas, tipos, etc. asociados a esa compañía
    end
  end
end
```
