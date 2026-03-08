![](https://raw.githubusercontent.com/appsmithorg/appsmith/release/static/appsmith_logo_primary.png)

This app is built using Appsmith. Turn any datasource into an internal app in minutes. Appsmith lets you drag-and-drop components to build dashboards, write logic with JavaScript objects and connect to any API, database or GraphQL source.

![](https://raw.githubusercontent.com/appsmithorg/appsmith/release/static/images/integrations.png)

### [Github](https://github.com/appsmithorg/appsmith) • [Docs](https://docs.appsmith.com/?utm_source=github&utm_medium=social&utm_content=appsmith_docs&utm_campaign=null&utm_term=appsmith_docs) • [Community](https://community.appsmith.com/) • [Tutorials](https://github.com/appsmithorg/appsmith/tree/update/readme#tutorials) • [Youtube](https://www.youtube.com/appsmith) • [Discord](https://discord.gg/rBTTVJp)

##### You can visit the application using the below link

###### [![](https://assets.appsmith.com/git-sync/Buttons.svg) ](https://lessul.appsmith.com/applications/69aae622087fd62d13c0ed07/pages/69aae622087fd62d13c0ed09) [![](https://assets.appsmith.com/git-sync/Buttons2.svg)](https://lessul.appsmith.com/applications/69aae622087fd62d13c0ed07/pages/69aae622087fd62d13c0ed09/edit)

---

## Revisão técnica do MVP (tickets de reclamação)

Foram aplicados ajustes para alinhar os filtros da tela principal com os mesmos valores de enum usados no cadastro e no banco (snake_case), evitando divergências em buscas e dashboards.

### Ajustes aplicados

- Filtros da página principal (`Page1`) padronizados para enums:
  - `empresa`: `lessul`, `ms_decor`, `viva_vida`, `movelbento`, `modifika`
  - `status_ticket`: `aberto`, `concluido`, `aguardando_cliente`, `aguardando_devolucao`, `aguardando_assistencia`, `aguardando_marketplace`
  - `status_reclamacao`: `afetando`, `nao_afetando`, `removida`
  - `motivo`: `desistencia`, `defeito_fabricacao`, `produto_incorreto`, `faltando_itens`, `produto_danificado`, `problema`
- `canal_marketplace` padronizado em todo o app para valores canônicos:
  - `mercado_livre`, `shopee`, `magalu`, `amazon`, `site`
- Consulta `listar_tickets` revisada para usar os mesmos valores de filtro e sanitizar melhor a busca por nome.
- Script SQL completo de referência adicionado em `database/mvp_schema.sql` com:
  - tabelas `tickets`, `ticket_auditoria` e `perfis`
  - enums padronizados
  - campos automáticos (`sla_status`, `mes_reclamacao`, `ano_reclamacao`)
  - trigger de auditoria automática por campo
  - view `vw_tickets`
  - RLS com políticas por perfil (atendente/supervisor/admin)
  - bloqueio de edição de campos sensíveis para atendente via trigger

### Como aplicar schema no Supabase

1. Abra o **SQL Editor** no projeto Supabase.
2. Rode o conteúdo de `database/mvp_schema.sql`.
3. Garanta que os IDs de usuários autenticados também existam em `public.perfis` para resolver os responsáveis e permissões.
4. Para o usuário admin inicial, insira/atualize o campo `perfil` em `public.perfis` para `admin`.


### Correções de compatibilidade aplicadas (hotfix)

- Schema alinhado com `perfis(email, ativo, criado_em)` e `ticket_auditoria(usuario_id, usuario_nome)` para compatibilidade com as queries administrativas e de auditoria.
- Query `Page1/criar_tickets` corrigida (erro de sintaxe em `motivo_enum`) e adaptada para inserção inline via `tbl_tickets.newRow`.
- Queries de auditoria ajustadas para exibir nome de usuário via `COALESCE(a.usuario_nome, p.nome)` com `LEFT JOIN perfis`.
- Query `dash_cards` simplificada para **um único SELECT** de cards.
- Fonte de identidade padronizada para `appsmith.user.idToken.sub` no create ticket da página `criar_ticket`.


### Módulos visuais adicionados nesta etapa

- Página `dashboard` com cards de KPI e visões por status/empresa/motivo.
- Página `kanban` com colunas (aberto, aguardando, concluído) para acompanhamento operacional.
- Página `admin` com visão de usuários/perfil para operação administrativa.
- Botões de navegação rápida na `Page1` para os novos módulos.

> Se não aparecer no Appsmith publicado, acione **Git Sync → Pull** no workspace da aplicação e publique novamente.
