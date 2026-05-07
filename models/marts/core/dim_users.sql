-- ===========================================================================
-- dim_users.sql
-- ===========================================================================
-- CAPA: Marts/Core (Gold)
-- MATERIALIZACIÓN: table (heredada — Gold siempre table o incremental, nunca view)
--
-- OBJETIVO:
--   Dimensión de usuarios. "La fuente de verdad" sobre los usuarios para
--   toda la organización.
--
-- ENRIQUECIMIENTOS:
--   - Validación de formato de email con regex (ejemplo de transformación
--     de negocio en la capa core).
--   - Cálculo de días desde el alta del usuario.
-- ===========================================================================

with users as (

    select * from {{ ref('stg_sql_server_dbo__users') }}

),

addresses as (

    select * from {{ ref('stg_sql_server_dbo__addresses') }}

),


final as (

    select
          u.user_id
        , u.first_name
        , u.last_name
        , concat(u.first_name, ' ', u.last_name)             as full_name
        , u.email
        , coalesce(
              regexp_like(u.email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'),
              false
          )                                                  as is_valid_email_address
        , u.phone_number
        , u.address_id
        , a.address_line
        , a.zipcode::varchar(20) as zipcode
        , a.state
        , a.country
        -- En tu archivo dim_users.sql, dentro del bloque 'final':

        , to_timestamp_tz(u.created_at_utc)      as registered_at_utc
        , to_timestamp_tz(u.updated_at_utc)      as last_updated_at_utc
        , to_timestamp_tz(u.date_load)           as date_load
        -- Para el warning del number:
        , cast(datediff('day', u.created_at_utc, current_timestamp()) as number(38,0)) as days_since_registration

    from users u
    left join addresses a on u.address_id = a.address_id

)

select * from final