-- ============================================================
-- MVP — Sistema Interno de Tickets de Reclamação
-- Schema PostgreSQL / Supabase — versão compatível com Appsmith
-- ============================================================

create extension if not exists pgcrypto;

-- ============================================================
-- 0. LIMPEZA CONTROLADA (idempotente)
-- ============================================================
DROP VIEW IF EXISTS public.vw_tickets CASCADE;
DROP TABLE IF EXISTS public.ticket_auditoria CASCADE;
DROP TABLE IF EXISTS public.tickets CASCADE;
DROP TABLE IF EXISTS public.perfis CASCADE;

DROP TYPE IF EXISTS public.empresa_enum CASCADE;
DROP TYPE IF EXISTS public.status_reclamacao_enum CASCADE;
DROP TYPE IF EXISTS public.motivo_enum CASCADE;
DROP TYPE IF EXISTS public.resolucao_enum CASCADE;
DROP TYPE IF EXISTS public.status_ticket_enum CASCADE;
DROP TYPE IF EXISTS public.perfil_enum CASCADE;

-- ============================================================
-- 1. ENUMS
-- ============================================================
CREATE TYPE public.empresa_enum AS ENUM ('lessul','ms_decor','viva_vida','movelbento','modifika');
CREATE TYPE public.status_reclamacao_enum AS ENUM ('afetando','nao_afetando','removida');
CREATE TYPE public.motivo_enum AS ENUM ('desistencia','defeito_fabricacao','produto_incorreto','faltando_itens','produto_danificado','problema');
CREATE TYPE public.resolucao_enum AS ENUM ('assistencia','devolucao','reembolso','resolvido');
CREATE TYPE public.status_ticket_enum AS ENUM ('aberto','concluido','aguardando_cliente','aguardando_devolucao','aguardando_assistencia','aguardando_marketplace');
CREATE TYPE public.perfil_enum AS ENUM ('atendente','supervisor','admin');

-- ============================================================
-- 2. TABELAS
-- ============================================================
CREATE TABLE public.perfis (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  nome        TEXT NOT NULL,
  email       TEXT NOT NULL,
  perfil      public.perfil_enum NOT NULL DEFAULT 'atendente',
  ativo       BOOLEAN NOT NULL DEFAULT TRUE,
  criado_em   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE public.tickets (
  id                   BIGSERIAL PRIMARY KEY,
  nome_cliente         TEXT NOT NULL,
  cpf                  TEXT,
  uf                   CHAR(2),
  data_compra          DATE,
  numero_venda         TEXT,
  link_pedido          TEXT,
  canal_marketplace    TEXT,
  empresa              public.empresa_enum NOT NULL,
  produto              TEXT,
  sku                  TEXT,
  fabricante           TEXT,
  transportadora       TEXT,
  status_reclamacao    public.status_reclamacao_enum,
  data_reclamacao      DATE,
  motivo               public.motivo_enum,
  detalhes_cliente     TEXT,
  resolucao            public.resolucao_enum,
  valor_reembolso      NUMERIC(12,2) NOT NULL DEFAULT 0,
  valor_coleta         NUMERIC(12,2) NOT NULL DEFAULT 0,
  custos_totais        NUMERIC(12,2)
    GENERATED ALWAYS AS (COALESCE(valor_reembolso,0) + COALESCE(valor_coleta,0)) STORED,
  status_ticket        public.status_ticket_enum NOT NULL DEFAULT 'aberto',
  prazo_conclusao      DATE,
  responsavel          UUID REFERENCES public.perfis(id),
  mes_reclamacao       SMALLINT GENERATED ALWAYS AS (EXTRACT(MONTH FROM data_reclamacao)::SMALLINT) STORED,
  ano_reclamacao       SMALLINT GENERATED ALWAYS AS (EXTRACT(YEAR FROM data_reclamacao)::SMALLINT) STORED,
  criado_por           UUID REFERENCES public.perfis(id),
  criado_em            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  atualizado_por       UUID REFERENCES public.perfis(id),
  atualizado_em        TIMESTAMPTZ,
  ativo                BOOLEAN NOT NULL DEFAULT TRUE
);

ALTER TABLE public.tickets
  ADD CONSTRAINT ck_tickets_canal_marketplace
  CHECK (
    canal_marketplace IS NULL
    OR canal_marketplace IN ('mercado_livre','shopee','magalu','amazon','site')
  );

CREATE TABLE public.ticket_auditoria (
  id            BIGSERIAL PRIMARY KEY,
  ticket_id     BIGINT NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  acao          TEXT NOT NULL,
  campo         TEXT,
  valor_antigo  TEXT,
  valor_novo    TEXT,
  usuario_id    UUID REFERENCES public.perfis(id),
  usuario_nome  TEXT,
  data_hora     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================================
-- 3. VIEW COM SLA
-- ============================================================
CREATE OR REPLACE VIEW public.vw_tickets AS
SELECT
  t.*,
  CASE
    WHEN t.status_ticket = 'concluido' THEN 'concluido'
    WHEN t.prazo_conclusao IS NOT NULL
      AND CURRENT_DATE > t.prazo_conclusao
      AND t.status_ticket <> 'concluido' THEN 'atrasado'
    ELSE 'no_prazo'
  END AS sla_status
FROM public.tickets t;

-- ============================================================
-- 4. INDEXES
-- ============================================================
CREATE INDEX idx_tickets_empresa         ON public.tickets(empresa);
CREATE INDEX idx_tickets_status_ticket   ON public.tickets(status_ticket);
CREATE INDEX idx_tickets_canal           ON public.tickets(canal_marketplace);
CREATE INDEX idx_tickets_responsavel     ON public.tickets(responsavel);
CREATE INDEX idx_tickets_data_reclamacao ON public.tickets(data_reclamacao);
CREATE INDEX idx_tickets_prazo           ON public.tickets(prazo_conclusao);
CREATE INDEX idx_auditoria_ticket_id     ON public.ticket_auditoria(ticket_id);

-- ============================================================
-- 5. TRIGGERS
-- ============================================================
CREATE OR REPLACE FUNCTION public.fn_set_atualizado_em()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.atualizado_em := NOW();
  RETURN NEW;
END;
$$;

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

CREATE TRIGGER trg_tickets_normalizar_canal_marketplace
BEFORE INSERT OR UPDATE OF canal_marketplace ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_normalizar_ticket_canal_marketplace();

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

CREATE TRIGGER trg_tickets_validar_identidade
BEFORE INSERT OR UPDATE ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_validar_identidade_ticket();

CREATE TRIGGER trg_tickets_atualizado_em
BEFORE UPDATE ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_set_atualizado_em();

CREATE OR REPLACE FUNCTION public.fn_auditoria_insert()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  usr_nome TEXT;
BEGIN
  SELECT nome INTO usr_nome FROM public.perfis WHERE id = NEW.criado_por;

  INSERT INTO public.ticket_auditoria
    (ticket_id, acao, campo, valor_antigo, valor_novo, usuario_id, usuario_nome)
  VALUES
    (NEW.id, 'INSERT', NULL, NULL, 'Ticket criado', NEW.criado_por, usr_nome);

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tickets_auditoria_insert
AFTER INSERT ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_insert();

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

CREATE TRIGGER trg_tickets_auditoria_update
AFTER UPDATE ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_auditoria_update();

-- Bloqueio de campos sensíveis para atendente
CREATE OR REPLACE FUNCTION public.fn_meu_perfil()
RETURNS TEXT LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT perfil::TEXT FROM public.perfis WHERE id = auth.uid();
$$;

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

CREATE TRIGGER trg_validar_edicao_ticket
BEFORE UPDATE ON public.tickets
FOR EACH ROW EXECUTE FUNCTION public.fn_validar_edicao_ticket();

-- ============================================================
-- 6. RLS
-- ============================================================
ALTER TABLE public.tickets          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ticket_auditoria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.perfis           ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "perfis: leitura própria" ON public.perfis;
DROP POLICY IF EXISTS "perfis: admin gerencia" ON public.perfis;
DROP POLICY IF EXISTS "tickets: todos leem ativos" ON public.tickets;
DROP POLICY IF EXISTS "tickets: criar" ON public.tickets;
DROP POLICY IF EXISTS "tickets: editar" ON public.tickets;
DROP POLICY IF EXISTS "tickets: sem delete fisico" ON public.tickets;
DROP POLICY IF EXISTS "auditoria: atendente/supervisor/admin leem" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: supervisor e admin leem" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: apenas triggers gravam" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: sem update" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: sem delete" ON public.ticket_auditoria;

CREATE POLICY "perfis: leitura própria" ON public.perfis FOR SELECT USING (id = auth.uid());
CREATE POLICY "perfis: admin gerencia" ON public.perfis FOR ALL USING (public.fn_meu_perfil() = 'admin');

CREATE POLICY "tickets: todos leem ativos" ON public.tickets FOR SELECT USING (ativo = TRUE);
CREATE POLICY "tickets: criar" ON public.tickets FOR INSERT WITH CHECK (public.fn_meu_perfil() IN ('atendente','supervisor','admin'));
CREATE POLICY "tickets: editar" ON public.tickets FOR UPDATE USING (public.fn_meu_perfil() IN ('atendente','supervisor','admin'));
CREATE POLICY "tickets: sem delete fisico" ON public.tickets FOR DELETE USING (FALSE);

CREATE POLICY "auditoria: atendente/supervisor/admin leem" ON public.ticket_auditoria FOR SELECT USING (public.fn_meu_perfil() IN ('atendente','supervisor','admin'));
CREATE POLICY "auditoria: apenas triggers gravam" ON public.ticket_auditoria FOR INSERT WITH CHECK (FALSE);
CREATE POLICY "auditoria: sem update" ON public.ticket_auditoria FOR UPDATE USING (FALSE);
CREATE POLICY "auditoria: sem delete" ON public.ticket_auditoria FOR DELETE USING (FALSE);
