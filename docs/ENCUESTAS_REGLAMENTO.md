# Integración Encuestas → Reglamento (A-05…A-08)

AyB consume la API de Encuestas (Laravel) para métricas semanales de cumplimiento.
El vínculo establecimiento ↔ survey se resuelve por **nombre normalizado**
(`establecimientos.nombre` AyB ≈ `surveys.title` Encuestas, solo `status=active`).

Ejemplo: `Silvia` ↔ `Restaurante Silvia` → ambos normalizan a `silvia`.

## Variables `.env`

```env
ENCUESTAS_API_URL=http://127.0.0.1:8000/api/v1
ENCUESTAS_API_TOKEN=<token Sanctum>
ENCUESTAS_SURVEY_MAP=
ENCUESTAS_TIMEOUT_SECONDS=15
```

- Match principal: `GET /surveys?status=active` + comparación de nombres.
- `ENCUESTAS_SURVEY_MAP` es override opcional (`silvia:3`); dejar vacío en producción normal.
- El token **nunca** va en código.

## Endpoints usados

1. `GET {ENCUESTAS_API_URL}/surveys?status=active`  
   Lista surveys activos `{ id, title, status }` para resolver el match.
2. `GET {ENCUESTAS_API_URL}/restaurants/{survey_id}/compliance-metrics?week_start=&week_end=`  
   Métricas de la semana.

## Mapeo de métricas

| Código | Campo API | Regla (ya en BD) |
|--------|-----------|------------------|
| A-05 | `satisfaction_pct` | incumple si `< 85` |
| A-06 | `recommendation_pct` | incumple si `< 90` |
| A-07 | `negative_comments_weekday` | incumple si `>= 10` |
| A-08 | `negative_comments_weekend` | incumple si `>= 15` |

## Cómo probar en UI

1. Encuestas con `GET /api/v1/surveys?status=active` implementado.
2. AyB local con `.env` (URL + token).
3. Abrir reunión pendiente de **Silvia**.
4. Al cargar se resuelve survey por nombre y se rellenan A-05…A-08.
5. Guardar evaluación.

Archivos: `app/services/encuestas_client.py`, `reglamento_controller.py`, `reunion_detalle.html`.

---