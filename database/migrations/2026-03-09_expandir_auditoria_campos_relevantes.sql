CREATE OR REPLACE FUNCTION public.fn_auditoria_update()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  usr_nome TEXT;
BEGIN
  SELECT nome INTO usr_nome FROM public.perfis WHERE id = NEW.atualizado_por;

  IF OLD.nome_cliente IS DISTINCT FROM NEW.nome_cliente THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','nome_cliente',OLD.nome_cliente,NEW.nome_cliente,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.status_ticket IS DISTINCT FROM NEW.status_ticket THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','status_ticket',OLD.status_ticket::TEXT,NEW.status_ticket::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.status_reclamacao IS DISTINCT FROM NEW.status_reclamacao THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','status_reclamacao',OLD.status_reclamacao::TEXT,NEW.status_reclamacao::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.motivo IS DISTINCT FROM NEW.motivo THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','motivo',OLD.motivo::TEXT,NEW.motivo::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.resolucao IS DISTINCT FROM NEW.resolucao THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','resolucao',OLD.resolucao::TEXT,NEW.resolucao::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.valor_reembolso IS DISTINCT FROM NEW.valor_reembolso THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','valor_reembolso',OLD.valor_reembolso::TEXT,NEW.valor_reembolso::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.valor_coleta IS DISTINCT FROM NEW.valor_coleta THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','valor_coleta',OLD.valor_coleta::TEXT,NEW.valor_coleta::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.prazo_conclusao IS DISTINCT FROM NEW.prazo_conclusao THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','prazo_conclusao',OLD.prazo_conclusao::TEXT,NEW.prazo_conclusao::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.responsavel IS DISTINCT FROM NEW.responsavel THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','responsavel',OLD.responsavel::TEXT,NEW.responsavel::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.empresa IS DISTINCT FROM NEW.empresa THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','empresa',OLD.empresa::TEXT,NEW.empresa::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.produto IS DISTINCT FROM NEW.produto THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','produto',OLD.produto,NEW.produto,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.canal_marketplace IS DISTINCT FROM NEW.canal_marketplace THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','canal_marketplace',OLD.canal_marketplace,NEW.canal_marketplace,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.numero_venda IS DISTINCT FROM NEW.numero_venda THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','numero_venda',OLD.numero_venda,NEW.numero_venda,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.cpf IS DISTINCT FROM NEW.cpf THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','cpf',OLD.cpf,NEW.cpf,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.uf IS DISTINCT FROM NEW.uf THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','uf',OLD.uf::TEXT,NEW.uf::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.sku IS DISTINCT FROM NEW.sku THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','sku',OLD.sku,NEW.sku,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.fabricante IS DISTINCT FROM NEW.fabricante THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','fabricante',OLD.fabricante,NEW.fabricante,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.transportadora IS DISTINCT FROM NEW.transportadora THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','transportadora',OLD.transportadora,NEW.transportadora,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.data_compra IS DISTINCT FROM NEW.data_compra THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','data_compra',OLD.data_compra::TEXT,NEW.data_compra::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.data_reclamacao IS DISTINCT FROM NEW.data_reclamacao THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','data_reclamacao',OLD.data_reclamacao::TEXT,NEW.data_reclamacao::TEXT,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.link_pedido IS DISTINCT FROM NEW.link_pedido THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','link_pedido',OLD.link_pedido,NEW.link_pedido,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.detalhes_cliente IS DISTINCT FROM NEW.detalhes_cliente THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','detalhes_cliente',OLD.detalhes_cliente,NEW.detalhes_cliente,NEW.atualizado_por,usr_nome);
  END IF;
  IF OLD.ativo IS DISTINCT FROM NEW.ativo THEN
    INSERT INTO public.ticket_auditoria(ticket_id,acao,campo,valor_antigo,valor_novo,usuario_id,usuario_nome)
    VALUES(NEW.id,'UPDATE','ativo',OLD.ativo::TEXT,NEW.ativo::TEXT,NEW.atualizado_por,usr_nome);
  END IF;

  RETURN NEW;
END;
$$;
