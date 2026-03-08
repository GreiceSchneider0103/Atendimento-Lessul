-- Ajuste RLS da auditoria para aderência ao MVP
-- Atendente, Supervisor e Admin podem ler histórico
-- Escrita segue bloqueada para usuários (apenas trigger/definer)

DROP POLICY IF EXISTS "auditoria: atendente/supervisor/admin leem" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: supervisor e admin leem" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: apenas triggers gravam" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: sem update" ON public.ticket_auditoria;
DROP POLICY IF EXISTS "auditoria: sem delete" ON public.ticket_auditoria;

CREATE POLICY "auditoria: atendente/supervisor/admin leem"
ON public.ticket_auditoria
FOR SELECT
USING (public.fn_meu_perfil() IN ('atendente','supervisor','admin'));

CREATE POLICY "auditoria: apenas triggers gravam"
ON public.ticket_auditoria
FOR INSERT
WITH CHECK (FALSE);

CREATE POLICY "auditoria: sem update"
ON public.ticket_auditoria
FOR UPDATE
USING (FALSE);

CREATE POLICY "auditoria: sem delete"
ON public.ticket_auditoria
FOR DELETE
USING (FALSE);
