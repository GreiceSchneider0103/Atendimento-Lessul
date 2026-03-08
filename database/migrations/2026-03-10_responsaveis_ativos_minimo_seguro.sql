-- Lista mínima segura de responsáveis para atendente/supervisor/admin
-- Objetivo: alimentar filtros e atribuição sem expor e-mail/dados sensíveis.

CREATE OR REPLACE FUNCTION public.fn_responsaveis_ativos()
RETURNS TABLE(value UUID, label TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF public.fn_meu_perfil() IN ('atendente','supervisor','admin') THEN
    RETURN QUERY
    SELECT p.id, p.nome
    FROM public.perfis p
    WHERE p.ativo = TRUE
    ORDER BY p.nome;
  END IF;

  RETURN;
END;
$$;

GRANT EXECUTE ON FUNCTION public.fn_responsaveis_ativos() TO authenticated;
