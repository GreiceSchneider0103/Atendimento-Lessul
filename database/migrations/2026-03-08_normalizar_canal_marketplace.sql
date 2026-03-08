-- Normalização de canal_marketplace (legado + proteção futura)

CREATE OR REPLACE FUNCTION public.fn_normalizar_canal_marketplace(v TEXT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  n TEXT;
BEGIN
  IF v IS NULL OR BTRIM(v) = '' THEN
    RETURN NULL;
  END IF;

  n := LOWER(REPLACE(BTRIM(v), ' ', '_'));

  IF n IN ('mercado_livre','mercadolivre','mercado-livre') THEN
    RETURN 'mercado_livre';
  ELSIF n = 'shopee' THEN
    RETURN 'shopee';
  ELSIF n = 'magalu' THEN
    RETURN 'magalu';
  ELSIF n = 'amazon' THEN
    RETURN 'amazon';
  ELSIF n = 'site' THEN
    RETURN 'site';
  END IF;

  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.fn_normalizar_ticket_canal_marketplace()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.canal_marketplace := public.fn_normalizar_canal_marketplace(NEW.canal_marketplace);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tickets_normalizar_canal_marketplace ON public.tickets;
CREATE TRIGGER trg_tickets_normalizar_canal_marketplace
BEFORE INSERT OR UPDATE OF canal_marketplace ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_normalizar_ticket_canal_marketplace();

-- Migração de legado (normaliza variações textuais já existentes)
UPDATE public.tickets
SET canal_marketplace = public.fn_normalizar_canal_marketplace(canal_marketplace)
WHERE canal_marketplace IS NOT NULL;

-- Constraint para evitar novas divergências
ALTER TABLE public.tickets
  DROP CONSTRAINT IF EXISTS ck_tickets_canal_marketplace;

ALTER TABLE public.tickets
  ADD CONSTRAINT ck_tickets_canal_marketplace
  CHECK (
    canal_marketplace IS NULL
    OR canal_marketplace IN ('mercado_livre','shopee','magalu','amazon','site')
  );
