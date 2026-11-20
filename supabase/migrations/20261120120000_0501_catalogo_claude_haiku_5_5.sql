-- 0501 — Claude Haiku 5.5 no catálogo de modelos e na tabela de custo
--
-- O Haiku 5.5 ficou de fora das duas tabelas: `ai_models` (o que a tela de escolha
-- do agente oferece) e `ai_pricing` (o que `lib/ai/cost.ts` usa para somar o gasto).
-- Sem a linha em `ai_models` o dono do negócio não escolhe o modelo pela tela; sem
-- a linha em `ai_pricing` o gasto dele não entra na soma do orçamento — o mesmo
-- defeito que o cabeçalho de `lib/agent-engine/edge/llm/pricing.ts` descreve. O
-- `pricing.ts` ganhou a linha no mesmo commit (os dois caminhos de custo precisam
-- concordar).
--
-- PREÇO conferido na tabela oficial (platform.claude.com/docs/en/about-claude/pricing,
-- lida em 2026-11-20), faixa de prompt até 100 mil tokens por requisição:
--   entrada US$ 0,10 · saída US$ 0,50 · leitura de cache US$ 0,01 ·
--   escrita de cache 5 min US$ 0,125 · 1 h US$ 0,20  (por milhão de tokens).
-- Acima de 100 mil tokens por requisição TODAS as tarifas são 5× (0,50 / 2,50). Nem
-- `ai_models` nem `ai_pricing` modelam faixa por tamanho de prompt; um agente de
-- atendimento fica muito abaixo disso. Quem alimentar o modelo com contexto longo
-- (documentos inteiros) terá o gasto SUBESTIMADO por esta linha.
--
-- ID `claude-haiku-5-5`: é o que o Claude Code reporta ao chamar o modelo. NÃO foi
-- conferido em `GET https://api.anthropic.com/v1/models` (sem chave Anthropic nesta
-- máquina) — confira antes de anunciar; id errado só falha na hora da chamada.
--
-- `context_window` e `released_at` ficam NULL de propósito (doutrina da 0104): dado
-- que eu não conferi não entra em coluna que a tela mostra.
--
-- Não muda o modelo PADRÃO de nenhum provedor. Preço em CENTAVOS por milhão de
-- tokens, a unidade já usada nas duas tabelas. Idempotente (`on conflict do update`).

insert into public.ai_models
  (provider, model_id, display_name, description,
   input_price_per_million_cents, output_price_per_million_cents, supports_tools)
values
  ('anthropic', 'claude-haiku-5-5', 'Claude Haiku 5.5',
   'Rápido e barato, bom para atendimento e classificação. Preço até 100 mil tokens por requisição ($0,10/$0,50 por milhão); acima disso todas as tarifas são 5×.',
   10, 50, true)
on conflict (provider, model_id) do update set
  display_name = excluded.display_name,
  description = excluded.description,
  input_price_per_million_cents = excluded.input_price_per_million_cents,
  output_price_per_million_cents = excluded.output_price_per_million_cents,
  supports_tools = excluded.supports_tools;

insert into public.ai_pricing
  (model, prompt_cents_per_million_tokens, completion_cents_per_million_tokens, notes)
values
  ('claude-haiku-5-5', 10, 50,
   'catálogo 0501 — platform.claude.com/docs/en/about-claude/pricing, 2026-11-20; faixa até 100k tokens/requisição, acima 5×')
on conflict (model) do update set
  prompt_cents_per_million_tokens = excluded.prompt_cents_per_million_tokens,
  completion_cents_per_million_tokens = excluded.completion_cents_per_million_tokens,
  notes = excluded.notes,
  superseded_at = null;
