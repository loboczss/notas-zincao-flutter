-- Corrige visibilidade do autor das notas entre usuarios.
--
-- Sintoma: campo "Por:" aparece apenas para o proprio usuario e para terceiros fica "—".
-- Causa: o app resolve owner_user_id -> profiles.nome; se o RLS de profiles
--        permite apenas ler o proprio perfil, os nomes dos outros nao chegam.
--
-- Este patch abre leitura da tabela profiles para usuarios autenticados.
-- Ajuste nomes de policies antigas se no seu banco forem diferentes.

begin;

alter table if exists public.profiles enable row level security;

-- Remove policy antiga de leitura "apenas proprio perfil" (nomes comuns).
drop policy if exists "profiles_select_own" on public.profiles;
drop policy if exists "p_profiles_select_own" on public.profiles;
drop policy if exists "Users can view own profile" on public.profiles;

-- Garante uma policy de leitura para usuarios autenticados.
create policy "profiles_select_authenticated"
on public.profiles
for select
to authenticated
using (true);

commit;

-- Teste rapido no SQL Editor (logado como usuario comum via JWT da aplicacao):
-- select auth.uid(), auth.role();
-- select auth_uid, nome from public.profiles limit 20;
