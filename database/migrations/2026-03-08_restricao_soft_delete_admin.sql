-- Restrição de ação sensível: apenas admin pode inativar/reativar tickets

CREATE OR REPLACE FUNCTION public.fn_validar_edicao_ticket()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF public.fn_meu_perfil() = 'atendente' THEN
    IF (NEW.valor_reembolso IS DISTINCT FROM OLD.valor_reembolso)
       OR (NEW.valor_coleta IS DISTINCT FROM OLD.valor_coleta)
       OR (NEW.prazo_conclusao IS DISTINCT FROM OLD.prazo_conclusao)
       OR (NEW.empresa IS DISTINCT FROM OLD.empresa)
       OR (NEW.responsavel IS DISTINCT FROM OLD.responsavel)
    THEN
      RAISE EXCEPTION 'Perfil atendente não pode alterar campos sensíveis';
    END IF;
  END IF;

  IF NEW.ativo IS DISTINCT FROM OLD.ativo
     AND public.fn_meu_perfil() <> 'admin'
  THEN
    RAISE EXCEPTION 'Apenas admin pode alterar o status ativo/inativo do ticket';
  END IF;

  RETURN NEW;
END;
$$;
