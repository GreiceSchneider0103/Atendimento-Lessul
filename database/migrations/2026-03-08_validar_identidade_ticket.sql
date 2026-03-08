-- Validação de identidade para operações de tickets
-- Garante mapeamento consistente Appsmith user -> perfis/auth.users

CREATE OR REPLACE FUNCTION public.fn_validar_identidade_ticket()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP = 'INSERT' AND NEW.criado_por IS NULL THEN
    RAISE EXCEPTION 'Usuário autenticado inválido: criado_por obrigatório';
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.atualizado_por IS NULL THEN
    RAISE EXCEPTION 'Usuário autenticado inválido: atualizado_por obrigatório';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tickets_validar_identidade ON public.tickets;
CREATE TRIGGER trg_tickets_validar_identidade
BEFORE INSERT OR UPDATE ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_validar_identidade_ticket();
