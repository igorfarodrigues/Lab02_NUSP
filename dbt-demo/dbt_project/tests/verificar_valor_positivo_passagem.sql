-- Teste Singular: Verifica se existem registros com valor negativo ou zerado de passagem
-- Regra de negócio: O valor de toda passagem deve ser maior que zero
-- O DBT considera o teste falho se a query retornar QUALQUER linha

select
    ticket_no,
    flight_id,
    fare_conditions,
    amount
from {{ ref('fact_ticket_flight') }}
where amount <= 0
