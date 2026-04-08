-- MIGRAÇÃO COMPLETA DO ESTOQUE + RLS
-- Objetivo:
-- 1) Estruturar tabela de estoque com campos obrigatórios (incluindo quantidade)
-- 2) Garantir integridade (constraints e índices)
-- 3) Criar RLS com escrita SOMENTE para admin
-- 4) Criar função atômica de baixa de estoque

-- ============================================================
-- 1) ESTRUTURA
-- ============================================================

create sequence if not exists public.bd_estoque_geral_idproduto_seq;

alter sequence public.bd_estoque_geral_idproduto_seq
  owned by public.bd_estoque_geral."IDPRODUTO";

alter table public.bd_estoque_geral
  alter column "IDPRODUTO" set default nextval('public.bd_estoque_geral_idproduto_seq');

update public.bd_estoque_geral
set "IDPRODUTO" = nextval('public.bd_estoque_geral_idproduto_seq')
where "IDPRODUTO" is null;

alter table public.bd_estoque_geral
  add column if not exists "TIPOPRODUTO" text,
  add column if not exists "QUANTIDADEESTOQUE" numeric(14,3) not null default 0,
  add column if not exists "CRIADOEM" timestamptz not null default now(),
  add column if not exists "ATUALIZADOEM" timestamptz not null default now();

alter table public.bd_estoque_geral
  alter column "IDPRODUTO" set not null,
  alter column "DESCRICAO" set not null,
  alter column "EMBALAGEMSAIDA" set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_bd_estoque_geral_quantidade_nao_negativa'
  ) then
    alter table public.bd_estoque_geral
      add constraint ck_bd_estoque_geral_quantidade_nao_negativa
      check ("QUANTIDADEESTOQUE" >= 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_bd_estoque_geral_descricao_nao_vazia'
  ) then
    alter table public.bd_estoque_geral
      add constraint ck_bd_estoque_geral_descricao_nao_vazia
      check (length(trim("DESCRICAO")) > 0);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'ck_bd_estoque_geral_embalagem_nao_vazia'
  ) then
    alter table public.bd_estoque_geral
      add constraint ck_bd_estoque_geral_embalagem_nao_vazia
      check (length(trim("EMBALAGEMSAIDA")) > 0);
  end if;
end $$;

create unique index if not exists ux_bd_estoque_geral_idproduto
  on public.bd_estoque_geral ("IDPRODUTO");

create index if not exists idx_bd_estoque_geral_descricao
  on public.bd_estoque_geral ("DESCRICAO");

create index if not exists idx_bd_estoque_geral_tipo
  on public.bd_estoque_geral ("TIPOPRODUTO");

create or replace function public.trg_bd_estoque_geral_atualizado_em()
returns trigger
language plpgsql
as $$
begin
  new."ATUALIZADOEM" := now();
  return new;
end;
$$;

drop trigger if exists trg_bd_estoque_geral_atualizado_em on public.bd_estoque_geral;

create trigger trg_bd_estoque_geral_atualizado_em
before update on public.bd_estoque_geral
for each row
execute function public.trg_bd_estoque_geral_atualizado_em();

-- ============================================================
-- 2) FUNÇÕES DE SEGURANÇA / PERFIL
-- ============================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.auth_uid = auth.uid()
      and lower(coalesce(p.role, '')) = 'admin'
  );
$$;

create or replace function public.is_admin_or_colaborador()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles p
    where p.auth_uid = auth.uid()
      and lower(coalesce(p.role, '')) in ('admin', 'colaborador')
  );
$$;

-- ============================================================
-- 3) RLS (ADMIN E COLABORADOR PODEM BAIXAR ESTOQUE)
-- ============================================================

alter table public.bd_estoque_geral enable row level security;

drop policy if exists p_bd_estoque_geral_select_auth on public.bd_estoque_geral;
drop policy if exists p_bd_estoque_geral_insert_admin on public.bd_estoque_geral;
drop policy if exists p_bd_estoque_geral_update_admin on public.bd_estoque_geral;
drop policy if exists p_bd_estoque_geral_delete_admin on public.bd_estoque_geral;

create policy p_bd_estoque_geral_select_auth
on public.bd_estoque_geral
for select
to authenticated
using (true);

create policy p_bd_estoque_geral_insert_admin
on public.bd_estoque_geral
for insert
to authenticated
with check (public.is_admin());

create policy p_bd_estoque_geral_update_admin
on public.bd_estoque_geral
for update
to authenticated
using (public.is_admin_or_colaborador())
with check (public.is_admin_or_colaborador());

create policy p_bd_estoque_geral_delete_admin
on public.bd_estoque_geral
for delete
to authenticated
using (public.is_admin());

revoke all on table public.bd_estoque_geral from anon;
grant select on table public.bd_estoque_geral to authenticated;
grant insert, update, delete on table public.bd_estoque_geral to authenticated;

-- ============================================================
-- 4) BAIXA ATÔMICA DE ESTOQUE
-- ============================================================

create or replace function public.baixar_estoque_produto(
  p_id_produto bigint,
  p_quantidade_solicitada numeric
)
returns table (
  quantidade_retirada numeric,
  estoque_restante numeric
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_estoque_atual numeric := 0;
  v_retirada numeric := 0;
begin
  if not public.is_admin_or_colaborador() then
    raise exception 'Sem permissão para baixar estoque';
  end if;

  if p_id_produto is null then
    raise exception 'IDPRODUTO é obrigatório';
  end if;

  if p_quantidade_solicitada is null or p_quantidade_solicitada <= 0 then
    return query
    select 0::numeric,
           coalesce((
             select e."QUANTIDADEESTOQUE"
             from public.bd_estoque_geral e
             where e."IDPRODUTO" = p_id_produto
             limit 1
           ), 0::numeric);
    return;
  end if;

  select coalesce(e."QUANTIDADEESTOQUE", 0)
    into v_estoque_atual
  from public.bd_estoque_geral e
  where e."IDPRODUTO" = p_id_produto
  for update;

  if not found then
    raise exception 'Produto % não encontrado no estoque', p_id_produto;
  end if;

  v_retirada := least(v_estoque_atual, p_quantidade_solicitada);

  update public.bd_estoque_geral
  set "QUANTIDADEESTOQUE" = greatest(v_estoque_atual - v_retirada, 0)
  where "IDPRODUTO" = p_id_produto;

  return query
  select
    v_retirada,
    greatest(v_estoque_atual - v_retirada, 0);
end;
$$;

revoke all on function public.baixar_estoque_produto(bigint, numeric) from public;
grant execute on function public.baixar_estoque_produto(bigint, numeric) to authenticated;