{% macro get_flight_duration(departure_column, arrival_column) %}
    -- Calcula a duração em minutos, retornando NULL se algum campo for nulo
    CASE
        WHEN {{ departure_column }} IS NOT NULL AND {{ arrival_column }} IS NOT NULL
        THEN EXTRACT(EPOCH FROM ({{ arrival_column }} - {{ departure_column }})) / 60
        ELSE NULL
    END
{% endmacro %}
