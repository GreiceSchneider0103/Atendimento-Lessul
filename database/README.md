# Database layout

- `database/bootstrap/`: scripts de provisionamento inicial (ambiente novo), idempotentes e não destrutivos.
- `database/migrations/`: evolução incremental para ambientes existentes.

## Como usar
1. **Ambiente novo**: execute `database/bootstrap/001_mvp_bootstrap.sql`.
2. **Ambiente existente**: execute apenas `database/migrations/*.sql` na ordem.

## Regras
- Bootstrap não deve conter `DROP` destrutivo como caminho padrão.
- Migrations não devem assumir banco vazio.
