-- Corrige a baixa de estoque para retirada feita por admin ou colaborador.
-- Execute este script no Supabase SQL Editor no ambiente alvo.

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
      and lower(trim(coalesce(p.role, ''))) in ('admin', 'colaborador')
      and p.deleted_at is null
  );
$$;

alter table public.bd_estoque_geral enable row level security;
alter table public.bd_estoque_geral force row level security;

drop policy if exists p_bd_estoque_geral_update_admin on public.bd_estoque_geral;

create policy p_bd_estoque_geral_update_admin
on public.bd_estoque_geral
for update
to authenticated
using (public.is_admin_or_colaborador())
with check (public.is_admin_or_colaborador());

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