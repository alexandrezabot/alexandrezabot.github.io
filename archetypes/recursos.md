---
title: "{{ replace .File.ContentBaseName "-" " " | title }}"
description: ""
date: {{ .Date }}
tipo: "Simulação"
# sim: true embute static/recursos/<slug>/sim/index.html na página
sim: true
# estado inicial da simulação embutida, se ela aceitar parâmetros (ex.: "vista=terra&exag=1")
sim_params: ""
tags: []
# cursos UFSC: link para a aula em vídeo. Cursos particulares: só o nome, sem link.
aulas:
  - curso: ""
    aula: ""
    link: ""
    video: ""
---

Contexto do fenômeno em um ou dois parágrafos.

Como usar os controles.

## Para explorar

1. 
2. 
3. 
