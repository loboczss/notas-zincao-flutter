-- Corrige permissão da aba de produtos:
-- somente usuários com role = 'admin' podem inserir/editar/excluir em bd_estoque_geral.
-- Execute este script no Supabase SQL Editor (ambiente de produção).

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
      and lower(trim(coalesce(p.role, ''))) = 'admin'
      and p.deleted_at is null
  );
$$;

alter table public.bd_estoque_geral enable row level security;
alter table public.bd_estoque_geral force row level security;

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
using (public.is_admin())
with check (public.is_admin());

create policy p_bd_estoque_geral_delete_admin
on public.bd_estoque_geral
for delete
to authenticated
using (public.is_admin());

revoke all on table public.bd_estoque_geral from anon;
grant select on table public.bd_estoque_geral to authenticated;
grant insert, update, delete on table public.bd_estoque_geral to authenticated;
