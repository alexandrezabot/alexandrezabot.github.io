---
title: "O paradoxo de Fermi por Monte Carlo"
description: "Nove fatores incertos sorteados milhares de vezes. A conta com valores médios prevê 100 civilizações em toda galáxia, mas uma em cada cinco galáxias sorteadas sai vazia."
date: 2026-06-22
tipo: "Simulação"
sim: true
sim_params: ""
aliases: ["/fermi/"]
tags: ["paradoxo de Fermi", "equação de Drake", "vida no Universo", "estatística"]
aulas:
  - curso: "Imersão A Era das Bioassinaturas"
    aula: "aula 1, Vida no contexto cósmico e o método da busca"
    link: ""
    video: ""
---

Em 1950, num almoço em Los Alamos, Enrico Fermi fez a pergunta que ficou com o nome dele. Se a galáxia tem tantas estrelas e tanto tempo, onde estão as outras civilizações? Onze anos depois, Frank Drake escreveu a estimativa como um produto de fatores, da taxa de formação de estrelas até a longevidade das civilizações. Quando cada fator recebe um valor central razoável, o produto dá uma galáxia povoada, e o silêncio do céu passa a parecer um paradoxo.

Em 2018, Anders Sandberg, Eric Drexler e Toby Ord mostraram que o problema está no uso de valores centrais. Nós não conhecemos esses fatores com precisão, e alguns deles têm incerteza de muitas ordens de grandeza. Para apresentar o argumento, os autores usam um modelo de brinquedo, que é o desta simulação. São 100 bilhões de estrelas e nove fatores, cada um sorteado entre 0 e 0.2. O valor médio de cada fator é 0.1, e o produto dos valores médios multiplicado pelo número de estrelas dá exatamente 100 civilizações por galáxia.

Cada clique em Sortear 1 cria uma galáxia. As nove barras mostram os fatores sorteados, e embaixo aparecem o produto deles e o número esperado de civilizações, λ. O número final é sorteado a partir de λ, porque uma galáxia com λ = 0.5 pode ter zero, uma ou duas civilizações. Os botões Rodar 1000 e Rodar 100 mil repetem o sorteio muitas vezes. O quadro da direita acumula a fração de galáxias vazias e a média de civilizações, e o histograma embaixo mostra como os resultados se distribuem.

## Para explorar

1. Antes de rodar, pense na conta pontual. Se cada galáxia tem 100 civilizações, quantas galáxias vazias você espera encontrar? Depois sorteie algumas galáxias, uma por vez.
2. Rode 100 mil galáxias. A média fica perto de 100, igual à conta pontual, e mesmo assim cerca de 21% das galáxias saem vazias. Como as duas coisas podem ser verdade ao mesmo tempo? Olhe o histograma para responder.
3. Neste modelo cada fator varia entre 0 e 0.2. Na análise completa do artigo, os fatores ligados à origem da vida têm incerteza muito maior que essa. O que você espera que aconteça com a fração de galáxias vazias?

O modelo vem de Sandberg, Drexler e Ord, *Dissolving the Fermi Paradox*, publicado em 2018 no [arXiv:1806.02404](https://arxiv.org/abs/1806.02404).
