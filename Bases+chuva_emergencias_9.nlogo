globals [
  num-gotas-por-tick    ;; quantidade de gotas por tick
  num-gotas-criadas     ;; número de gotas já criadas
  num-gotas-total       ;; número total de gotas a serem criadas
  x-inicial-gotas       ;; posição inicial das gotas
  x-final-gotas         ;; posição final das gotas
  passo-gotas           ;; incremento horizontal das gotas

  emergencias-niveis-gravidade
  emergencias-total-existentes
  emergencias-total-executadas
  emergencias-quantidade-consumidores-afetados
  emergencias-consumidor-hora-interrompidos

  custo-kilowatthora-reais
  emergencias-kilowatthora-perdidos
  emergencias-kilowatthora-reais

  equipes-custo-hora-total
  equipes-total-horas

  em-contingencia?
  contingencia-duracao
]

breed [ impactos impacto ]
breed [ bases base ]
breed [ equipes equipe ]
breed [ emergencias emergencia ]

bases-own [
  base-sigla
  base-principal?
  base-lista-emergencias
  base-lista-equipes
  ;base-regiao-lista-emergencias-pendentes
  base-quantidade-extra-equipes
  base-vizinhos-a-um-salto

  base-quantidade-emergencia-por-equipe
  base-precisa-apoio?
  base-quant-recebendo-equipes-apoio ; parametro para 2
]

equipes-own [
  equipe-codigo
  equipe-base-original-codigo
  equipe-base-original-objeto

  equipe-disponivel?
  equipe-em-intervalo?
  equipe-em-deslocamento?
  equipe-em-execucao?
  equipe-em-retorno?
  equipe-em-final-turno?

  equipe-momento-chegada-emergencia
  equipe-emergencia-em-atendimento-codigo
  equipe-emergencia-em-atendimento-objeto

  equipe-intervalo-entre-jornadas
  equipe-tempo-turno-normal
  equipe-tempo-turno-realizado
  equipe-tempo-ocioso
]

emergencias-own [
  emergencia-codigo
  emergencia-base-atendimento
  emergencia-tipo
  emergencia-gravidade
  emergencia-distancia-equipe
  emergencia-em-atendimento?
  emergencia-executada?
]

impactos-own [
  ticks-created
]

to setup
  clear-all

  set emergencias-kilowatthora-perdidos 0
  set emergencias-kilowatthora-reais 0
  set custo-kilowatthora-reais 0.570

  set em-contingencia? false
  set contingencia-duracao 0

  set equipes-total-horas 0

  set equipes-custo-hora-padrao 80 ; R$ 80
  set equipes-custo-hora-total 0

  set emergencias-total-existentes 0
  set emergencias-total-executadas 0
  set emergencias-consumidor-hora-interrompidos 0
  set emergencias-quantidade-consumidores-afetados 0
  set emergencias-niveis-gravidade [["Risco" 5000] ["Rede" 600] ["VIP" 200] ["Individual" 10]]

  criar-bases-predefinidas
  conectar-bases
  gravar-vizinhos

  set num-gotas-por-tick 1          ;; inicializa com 1 gota por tick
  set num-gotas-total 750            ;; número total de gotas a serem criadas
  set x-inicial-gotas min-pxcor      ;; posição inicial das gotas (esquerda)
  set x-final-gotas max-pxcor        ;; posição final das gotas (direita)
  set passo-gotas (x-final-gotas - x-inicial-gotas) / num-gotas-total  ;; calcula o incremento horizontal
  resize-world 0 80 0 55             ;; define o tamanho da tela

  if contingencia-modo-apoio = "ApoioVizinhoAjudaExtra" [
    ;; Se necessário, defina a quantidade extra de equipes móveis para bases específicas
    ask bases with [base-sigla = "FOZ"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
    ask bases with [base-sigla = "CEL"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
    ask bases with [base-sigla = "LJS"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
    ask bases with [base-sigla = "GVA"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
    ask bases with [base-sigla = "PGO"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
    ask bases with [base-sigla = "CTC"] [
      set base-quantidade-extra-equipes 5  ;; altere conforme necessário
    ]
  ]

  criar-equipes-iniciais

  ask bases [
    let base-atual self
    let conexoes [base-vizinhos-a-um-salto] of base-atual
    print (word "Vizinhos da base " [base-sigla] of base-atual ": " conexoes)
  ]


  reset-ticks
end

to criar-equipes-iniciais
  ask bases [
    let total-equipes equipes-quantidade-padrao + base-quantidade-extra-equipes
    let codigo-base base-sigla
    hatch-equipes total-equipes [
      set color blue
      set breed equipes
      set shape "car"
      set color blue
      set equipe-base-original-codigo codigo-base
      set equipe-base-original-objeto myself

      set equipe-disponivel? true
      set equipe-em-deslocamento? false
      set equipe-em-execucao? false
      set equipe-em-retorno? false
      set equipe-em-final-turno? false

      ;set equipe-intervalo-entre-jornadas 660 ; 11h
      set equipe-tempo-turno-normal equipe-turno-horas * 60
      set equipe-tempo-turno-realizado 0

      set size 1

      let codigo-equipe (word random 10 random 10 random 10 random 10)
      let codigo-final (word codigo-base "-" codigo-equipe)
      set equipe-codigo codigo-final

      create-link-with myself [set color white] ; Cria uma linha branca ligando a equipe à sua base
      setxy (pxcor) (pycor) ; Define a posição inicial afastada da base
      set label (word "")
    ]
  ]
end

to go

  if ticks mod 1 = 0 [
    if num-gotas-criadas < num-gotas-total [
      create-rainimpactos 0.5 1 1
    ]
    if num-gotas-criadas < num-gotas-total [
      create-rainimpactos 0 0.5 4
    ]
  ]

  ask impactos [
    let age ticks - ticks-created

    ifelse age > 300 [
      die
    ] [
      ifelse age > 250 [
        set color 81
      ] [
        ifelse age > 200 [
          set color 83
        ] [
          ifelse age > 150 [
            set color 85
          ] [
            if age > 100 [
              set color 87
            ]
          ]
        ]
      ]
    ]
  ]

  ; duracao da contingencia
  ifelse count emergencias > 100 [
    set em-contingencia? true
  ][
    set em-contingencia? false
  ]

  if em-contingencia? [

    set contingencia-duracao contingencia-duracao + 1

    ; calculo do CHI
    ask emergencias [
      let consumidores-minuto-afetados emergencias-consumidores / 60
      set emergencias-consumidor-hora-interrompidos emergencias-consumidor-hora-interrompidos + consumidores-minuto-afetados

      let emergencias-kilowatthora-minuto emergencias-consumidores * (1 / 60)
      set emergencias-kilowatthora-perdidos emergencias-kilowatthora-perdidos + emergencias-kilowatthora-minuto
      set emergencias-kilowatthora-reais emergencias-kilowatthora-perdidos * custo-kilowatthora-reais
    ]; calculo do CHI
    ask emergencias [
      let consumidores-minuto-afetados emergencias-consumidores / 60
      set emergencias-consumidor-hora-interrompidos emergencias-consumidor-hora-interrompidos + consumidores-minuto-afetados

      let emergencias-kilowatthora-minuto emergencias-consumidores * (1 / 60)
      set emergencias-kilowatthora-perdidos emergencias-kilowatthora-perdidos + emergencias-kilowatthora-minuto
      set emergencias-kilowatthora-reais emergencias-kilowatthora-perdidos * custo-kilowatthora-reais
    ]

    ; calculo equipes horas
    ask equipes [
      if not equipe-disponivel? [
        set equipes-total-horas equipes-total-horas + 1

        let equipe-custo-minuto equipes-custo-hora-padrao / 60
        set equipes-custo-hora-total equipes-custo-hora-total + equipe-custo-minuto
      ]
    ]
  ]

  ask equipes [

    set equipe-tempo-turno-realizado equipe-tempo-turno-realizado + 1

    if equipe-disponivel? [
      set equipe-tempo-ocioso equipe-tempo-ocioso + 1
    ]

    if equipe-tempo-turno-realizado > equipe-tempo-turno-normal [
      set equipe-em-final-turno? true
    ]
    if equipe-tempo-ocioso > 30 [
      set equipe-em-retorno? true
    ]

    if equipe-em-retorno? [
       equipe-retornar-base-ociosidade self equipe-base-original-objeto
    ]
    if equipe-em-final-turno? [
       equipe-retornar-base-fim-turno self equipe-base-original-objeto
    ]
    if equipe-disponivel? [
       equipe-designar-emergencia self equipe-base-original-objeto
    ]
    if equipe-em-deslocamento? [
       set equipe-tempo-ocioso 0
       equipe-deslocar-para-emergencia self equipe-emergencia-em-atendimento-objeto
    ]
    if equipe-em-execucao? [
       equipe-executar-emergencia self equipe-emergencia-em-atendimento-objeto
    ]

    ;let nearest-bases min-one-of bases [distance myself]
    ;create-link-with nearest-bases [set color white]

    if equipe-em-deslocamento? [
      set color orange ; equipe em atendimento
    ]
    if equipe-em-execucao? [
      set color red ; equipe sem emergencia
    ]
    if equipe-disponivel? [
      set color blue ; equipe sem emergencia
    ]
    ;set label equipe-tempo-turno-realizado

  ]

  criar-emergencias
  calcular-quantidade-emergencia-por-equipe

  ; EMERGENCIAS - Remoção
  let emergencias_a_remover []
  ask emergencias [
    if emergencia-executada? [
      set emergencias_a_remover lput self emergencias_a_remover
    ]
  ]
  foreach emergencias_a_remover [
    emerge ->
    let emergencia_remover emerge
    ask emergencia_remover [
      die
    ]
  ]

  tick
end


to calcular-quantidade-emergencia-por-equipe
  ask bases [
    let codigo-base base-sigla
    let emergencias-pendentes emergencias with [emergencia-base-atendimento = codigo-base]

    if any? emergencias-pendentes [
      let quantidade-equipes count equipes with [equipe-base-original-codigo = codigo-base]
      let quantidade-emergencias count emergencias-pendentes
      ifelse quantidade-equipes > 0 [
        let quantidade-emergencia-por-equipe quantidade-emergencias / quantidade-equipes
        set base-quantidade-emergencia-por-equipe quantidade-emergencia-por-equipe
        ;print(word codigo-base " " quantidade-emergencias " / " quantidade-equipes " = " quantidade-emergencia-por-equipe)
      ][
        ;set base-quantidade-emergencia-por-equipe quantidade-emergencias
        ;print(word codigo-base " Erro div " quantidade-emergencias)
      ]
    ]

    ; calcular necessidade de apoio
    ifelse base-quantidade-emergencia-por-equipe > 3 [
      set base-precisa-apoio? true
    ][
      set base-precisa-apoio? false
    ]
  ]
end



to equipe-designar-emergencia [equipe-atual equipe-base]
  let codigo-equipe [equipe-codigo] of equipe-atual
  let base-vizinhos [base-vizinhos-a-um-salto] of equipe-base
  let equipe-base-sigla [base-sigla] of equipe-base
  let base-precisa-ajuda [base-precisa-apoio?] of equipe-base

  let emergencias-ordenadas []
  let emergencias-ordenadas-final []
  ask emergencias [
    let distancia_inteira round distance equipe-atual
    let sigla-base [emergencia-base-atendimento] of self
    set emergencia-distancia-equipe distancia_inteira

    if contingencia-modo-apoio = "Isolado" [
      if sigla-base = equipe-base-sigla [
        set emergencias-ordenadas lput self emergencias-ordenadas
      ]
    ]
    if contingencia-modo-apoio = "ApoioVizinho" [
      if member? sigla-base base-vizinhos [
        set emergencias-ordenadas lput self emergencias-ordenadas
      ]
    ]
    if contingencia-modo-apoio = "ApoioVizinhoAjuda" [
      ifelse sigla-base = equipe-base-sigla [
         set emergencias-ordenadas lput self emergencias-ordenadas
      ][
        if member? sigla-base base-vizinhos [
          let base-com-sigla one-of bases with [base-sigla = sigla-base]
          if base-com-sigla != nobody [
            let precisa-apoio? [base-precisa-apoio?] of base-com-sigla
            if precisa-apoio? [
              let base-equipes-apoio [base-quant-recebendo-equipes-apoio] of base-com-sigla
              if base-equipes-apoio <= contingencia-equipes-apoiando [
                 set emergencias-ordenadas lput self emergencias-ordenadas
              ]
            ]
          ]
        ]
      ]
    ]
    if contingencia-modo-apoio = "ApoioVizinhoAjudaExtra" [
      ifelse sigla-base = equipe-base-sigla [
         set emergencias-ordenadas lput self emergencias-ordenadas
      ][
        if member? sigla-base base-vizinhos [
          let base-com-sigla one-of bases with [base-sigla = sigla-base]
          if base-com-sigla != nobody [
            let precisa-apoio? [base-precisa-apoio?] of base-com-sigla
            if precisa-apoio? [
              let base-equipes-apoio [base-quant-recebendo-equipes-apoio] of base-com-sigla
              if base-equipes-apoio <= contingencia-equipes-apoiando [
                 set emergencias-ordenadas lput self emergencias-ordenadas
              ]
            ]
          ]
        ]
      ]
    ]
    if contingencia-modo-apoio = "ApoioVizinhoAjudaFB" [
      ifelse sigla-base = equipe-base-sigla [
         set emergencias-ordenadas lput self emergencias-ordenadas
      ][
        if member? sigla-base base-vizinhos [
          let base-com-sigla one-of bases with [base-sigla = sigla-base]
          if base-com-sigla != nobody [
            let precisa-apoio? [base-precisa-apoio?] of base-com-sigla
            ;if precisa-apoio? [
              let base-equipes-apoio [base-quant-recebendo-equipes-apoio] of base-com-sigla
              if base-equipes-apoio <= contingencia-equipes-apoiando [
                 set emergencias-ordenadas lput self emergencias-ordenadas
              ]
            ;]
          ]
        ]
      ]
    ]
    if contingencia-modo-apoio = "Proximidade" [
      if distancia_inteira < 8 [
         set emergencias-ordenadas lput self emergencias-ordenadas
      ]
    ]
    if contingencia-modo-apoio = "Completo" [
      if distancia_inteira < 25 [
        set emergencias-ordenadas lput self emergencias-ordenadas
      ]
    ]
  ]

  ; Ordenar a lista de emergências com base nas distâncias calculadas
  set emergencias-ordenadas-final sort-by [[em1 em2] -> [emergencia-distancia-equipe] of em1 < [emergencia-distancia-equipe] of em2] emergencias-ordenadas

  foreach emergencias-ordenadas-final [
    emer ->
    let codigo-emergencia [emergencia-codigo] of emer
    let distancia-emergencia [emergencia-distancia-equipe] of emer
  ]



  ;  foreach emergencias-ordenadas [
;    emer ->
;      let codigo-emergencia [emergencia-codigo] of emer
;      let distancia-emergencia [emergencia-distancia-equipe] of emer
;  ]
;
;  ; Ordenar a lista de emergências com base nas distâncias calculadas
;  let emergencias-ordenadas-distancias sort-by [[em1 em2] -> [emergencia-distancia-equipe] of em1 < [emergencia-distancia-equipe] of em2] emergencias-ordenadas
;
;  foreach emergencias-ordenadas-distancias [
;    emer ->
;      let codigo-emergencia [emergencia-codigo] of emer
;      let distancia-emergencia [emergencia-distancia-equipe] of emer
;  ]

  ; Ordenar por prioridade
;  let emergencias-ordenadas-gravidade sort-by [[em1 em2] -> [emergencia-gravidade] of em1 > [emergencia-gravidade] of em2] emergencias-ordenadas-distancias

  equipe-designar equipe-atual emergencias-ordenadas-final
end

to equipe-designar [equipe-atual emergencias-ordenadas]
  let equipe-base-sigla [equipe-base-original-codigo] of equipe-atual
  foreach emergencias-ordenadas [
    emer ->
      let emergencia-atual emer
      let emer-em-atendimento? [emergencia-em-atendimento?] of emer
      if not emer-em-atendimento? [
        let sigla-base [emergencia-base-atendimento] of emer
        if equipe-base-sigla != sigla-base [
          let base-encontrada one-of bases with [base-sigla = sigla-base]
          ask base-encontrada [
            set base-quant-recebendo-equipes-apoio base-quant-recebendo-equipes-apoio + 1
          ]
        ]
        ask equipe-atual [
          let codigo-emergencia [emergencia-codigo] of emergencia-atual
          face emergencia-atual
          set equipe-disponivel? false
          set equipe-em-deslocamento? true
          set equipe-emergencia-em-atendimento-codigo codigo-emergencia
          set equipe-emergencia-em-atendimento-objeto emergencia-atual
        ]
        ask emergencia-atual [
          set emergencia-em-atendimento? true
        ]
        stop
      ]
  ]
end


to equipe-deslocar-para-emergencia [equipe-atual equipe-emergencia]
  let emergencia-atual equipe-emergencia
  let direcao-towards-emergencia towards emergencia-atual
  let distancia 0.1
  let deslocamento-x distancia * cos direcao-towards-emergencia
  let deslocamento-y distancia * sin direcao-towards-emergencia
  let distan distance emergencia-atual
  ifelse distan <= 1 [
    set equipe-momento-chegada-emergencia ticks
    set equipe-em-deslocamento? false
    set equipe-em-execucao? true
  ] [
    fd distancia
    create-link-with emergencia-atual [set color 45]
  ]
end

to equipe-executar-emergencia [equipe-atual equipe-emergencia]
  let emergencia-atual equipe-emergencia
  let tempo-espera emergencia-execucao-minutos
  if ticks - equipe-momento-chegada-emergencia >= tempo-espera [
    ask links with [end1 = equipe-atual or end2 = emergencia-atual] [ die ]
    ask emergencia-atual [
      set emergencia-executada? true
      set emergencias-total-executadas emergencias-total-executadas + 1
    ]
    ask equipe-atual [
      set equipe-em-execucao? false
      set equipe-disponivel? true
    ]
  ]
end

to equipe-retornar-base-ociosidade [equipe-atual equipe-base]
  let base-equipe equipe-base
  let distan distance base-equipe
  ifelse distan <= 0 [
    ask equipe-atual [
      set equipe-tempo-ocioso 0
      set equipe-disponivel? true
      set equipe-em-intervalo? false
      set equipe-em-deslocamento? false
      set equipe-em-execucao? false
      set equipe-em-retorno? false
    ]
  ] [
    let direcao-towards-base 0
    if distan > 0 [
      set direcao-towards-base towards base-equipe
    ]
    set heading direcao-towards-base
    fd 0.1
    create-link-with base-equipe [set color 125]
  ]
end

to equipe-retornar-base-fim-turno [equipe-atual equipe-base]
  let base-equipe equipe-base
  let distan distance base-equipe
  ifelse distan <= 2 [
    die
  ] [
    let direcao-towards-base 0
    if distan > 0 [
      set direcao-towards-base towards base-equipe
    ]
    set heading direcao-towards-base
    fd 0.1
    create-link-with base-equipe [set color 125]
  ]
end



to criar-emergencias
  ;; Percorre todos os impactos
  ask impactos [
    ;; Verifica se o impacto não tem uma emergência associada
    if not any? emergencias-on patch-here [
      ;; Procura as bases mais próximas do impacto dentro do raio de 10 patches
      let nearest-bases bases in-radius 10
      ;; Se houver pelo menos três bases próximas
      if count nearest-bases >= 3 [
        ;; Ordena as bases pelo menor valor de distância em relação ao impacto
        let sorted-bases sort-on [distance myself] nearest-bases
        ;; Seleciona as três bases mais próximas
        let base1 item 0 sorted-bases
        let base2 item 1 sorted-bases
        let base3 item 2 sorted-bases
        ;; Cria uma emergência no local do impacto
        hatch-emergencias 1 [
          set breed emergencias
          set shape "flag"
          set color red
          set heading 0
          set size 0.4

          set emergencia-em-atendimento? false
          set emergencia-executada? false

          set emergencias-total-existentes emergencias-total-existentes + 1
          set emergencias-quantidade-consumidores-afetados emergencias-quantidade-consumidores-afetados + emergencias-consumidores

          let gravidade random-gravidade
          set emergencia-tipo item 0 gravidade
          set emergencia-gravidade item 1 gravidade

          if emergencia-tipo = "Risco" [ set size 1 set color red ]
          if emergencia-tipo = "Rede" [ set size 1 set color violet ]
          if emergencia-tipo = "VIP" [ set size 0.8 set color orange ]
          if emergencia-tipo = "Individual" [ set size 0.6 set color 19 ]

          set emergencia-distancia-equipe 0

;          if show_labels? [
;            set label (word emergencia-codigo "-" emergencia-tipo)
;          ]

          ;; Adiciona as bases à lista de bases de atendimento da emergência
          ;set emergencia-bases-atendimento (list [base-sigla] of base1 [base-sigla] of base2 [base-sigla] of base3)
          ;; Adiciona a emergência à lista de pendências das bases de atendimento
          foreach (list base1 base2 base3) [
            based ->
            ask based [
              ;set base-regiao-lista-emergencias-pendentes fput myself base-regiao-lista-emergencias-pendentes
              if based = base1 [
                let sigla-base-selecionada [base-sigla] of base1
                ;print(sigla-base-selecionada)
                create-link-with myself [set color 113]

                ask myself [
                  set emergencia-base-atendimento sigla-base-selecionada
                ]
              ]
            ]
          ]

        ]
      ]
    ]
  ]
end

to-report random-gravidade
  let index random length emergencias-niveis-gravidade
  report item index emergencias-niveis-gravidade
end

to create-rainimpactos [inicio fim valor]
  let current-x x-inicial-gotas + num-gotas-criadas * passo-gotas ;; nova posição inicial das gotas
  let bottom-y min-pycor + ((max-pycor - min-pycor) * inicio) ;; 25% do caminho para cima
  let top-y min-pycor + ((max-pycor - min-pycor) * fim) ;; 75% do caminho para baixo

  let num-gotas-criadas-neste-tick 0

  while [num-gotas-criadas < num-gotas-total and num-gotas-criadas-neste-tick < num-gotas-por-tick] [
    create-impactos valor ;; cria uma nova tartaruga do tipo "impactos" (gota de chuva)
    [
      let random-y random-float (top-y - bottom-y) + bottom-y ;; Gera uma posição y aleatória dentro da região desejada
      setxy current-x random-y ;; Posiciona a gota aleatoriamente dentro da região definida
      set shape "dot"             ;; forma da gota
      set color 85              ;; cor da gota
      set size 0.5
      pen-down                    ;; coloca a caneta para baixo para que a gota fique visível
      set ticks-created ticks     ;; define a idade da gota como o tempo atual
    ]
    set num-gotas-criadas num-gotas-criadas + 1
    set num-gotas-criadas-neste-tick num-gotas-criadas-neste-tick + 1
    set current-x current-x + passo-gotas
  ]
end


to criar-bases-predefinidas
  let atributos-bases [
    ; OESTE
    ["CEL" 13 21 true]
    ["FOZ" 2 15 false]
    ["MED" 7 18 false]
    ["RZA" 12 12 false]
    ["FBL" 18 8 false]
    ["PTO" 22 6 false]
    ["LJS" 24 16 false]
    ["TDO" 11 24 false]
    ["MCR" 8 26 false]
    ; NOROESTE
    ["MGA" 29 39 true]
    ["UBA" 19 26 false]
    ["ALT" 10 34 false]
    ["UMU" 15 35 false]
    ["CMO" 25 31 false]
    ["CIT" 23 36 false]
    ["PVI" 24 43 false]
    ["LDA" 18 45 false]
    ; CENTRO-SUL
    ["PGO" 48 20 true]
    ["GVA" 34 16 false]
    ["UVI" 39 7 false]
    ["IRT" 43 15 false]
    ["SMS" 46 11 false]
    ["CTO" 50 24 false]
    ["TEL" 43 29 false]
    ; NORTE
    ["LNA" 38 40 true];
    ["CPO" 43 42 false]
    ["IBT" 47 35 false]
    ["APA" 34 37 false]
    ["SPL" 49 40 false]
    ["APG" 35 39 false]
    ["CBE" 36 41 false]
    ["IVP" 33 30 false]
    ;LESTE
    ["CTC" 55 16 true]
    ["CTS" 57 15 true]
    ["ARC" 55 13 false]
    ["COB" 59 17 false]
    ["PGA" 65 15 false]
    ["MAS" 64 12 false]
    ["SJP" 60 15 false]
    ["FRG" 58 13 false]
    ["ATM" 56 18 false]
  ]

  foreach atributos-bases [
    atributos ->
    let sigla-base item 0 atributos
    let x item 1 atributos
    let y item 2 atributos
    let principal? item 3 atributos

    crt 1 [
      set breed bases
      set shape "house"
      set color 45
      set base-principal? principal?
      ifelse base-principal? [
         set size 1.3
      ][
        set size 0.8
      ]
      let novoX x + 8
      setxy novoX y
      set base-sigla sigla-base

      set base-quantidade-emergencia-por-equipe 0
      set base-quant-recebendo-equipes-apoio 0
      set base-precisa-apoio? false

      set label (word base-sigla " __")
    ]
  ]
end

to conectar-bases
  let afinidades [
    ; OESTE
    ["FOZ" "MED" false]
    ["MED" "CEL" false]
    ["MED" "TDO" false]
    ["TDO" "MCR" false]
    ["TDO" "CEL" false]
    ["CEL" "LJS" false]
    ["LJS" "PTO" false]
    ["PTO" "FBL" false]
    ["FBL" "RZA" false]
    ["RZA" "CEL" false]
    ; CENTRO-SUL
    ["ALT" "UMU" false]
    ["UMU" "CIT" false]
    ["UBA" "CMO" false]
    ["CMO" "CIT" false]
    ["GVA" "UVI" false]
    ["TEL" "CTO" false]
    ["PGO" "CTO" false]
    ["PGO" "IRT" false]
    ["IRT" "SMS" false]
    ["UVI" "SMS" false]
    ["IRT" "UVI" false]
    ["IRT" "GVA" false]
    ; NOROESTE
    ["LDA" "PVI" false]
    ["MGA" "PVI" false]
    ["PVI" "CIT" false]
    ["MGA" "CIT" false]
    ["MGA" "CMO" false]
    ["CMO" "UBA" false]
    ; NORTE
    ["IBT" "SPL" false]
    ["SPL" "CPO" false]
    ["CPO" "LNA" false]
    ["LNA" "CBE" false]
    ["CBE" "APG" false]
    ["LNA" "APG" false]
    ["APG" "APA" false]
    ["APA" "IVP" false]
    ; LESTE
    ["CTC" "ATM" false]
    ["CTC" "CTS" false]
    ["ARC" "FRG" false]
    ["FRG" "SJP" false]
    ["PGA" "MAS" false]
    ["CTS" "FRG" false]
    ["COB" "CTS" false]
    ["COB" "PGA" false]
    ["SJP" "MAS" false]
    ["ATM" "COB" false]
    ["CTC" "ARC" false]
    ["COB" "SJP" false]
    ["CTS" "ARC" false]

    ; ENTRE REGIONAIS
    ["LJS" "GVA" true]
    ["PTO" "UVI" true]
    ["CEL" "UBA" true]
    ["MCR" "ALT" true]
    ["CMO" "IVP" true]
    ["IVP" "GVA" true]
    ["APA" "TAL" true]
    ["IBT" "TEL" true]
    ["PGO" "CTC" true]
    ["SMS" "ARC" true]
    ["IRT" "CTC" true]
    ["TEL" "APA" true]
    ["MGA" "APA" true]
    ["MGA" "LNA" true]

  ]

  foreach afinidades [
    afinidade ->
    let base1 item 0 afinidade
    let base2 item 1 afinidade
    let outra-regional? item 2 afinidade

    let base1-objeto one-of bases with [base-sigla = base1]
    let base2-objeto one-of bases with [base-sigla = base2]

    if base1-objeto != nobody and base2-objeto != nobody [
      ask base1-objeto [
        ifelse outra-regional? [
          create-link-with base2-objeto [set color 35]
        ][
          create-link-with base2-objeto [set color white]
        ]
      ]
    ]
  ]
end

to gravar-vizinhos
  ask bases [
    let conexoes base-links self
    set base-vizinhos-a-um-salto conexoes
  ]
end

to-report base-links [base-pesquisa]
  let conexoes []
  ask links with [end1 = base-pesquisa] [
    let outra-base [base-sigla] of end2
    set conexoes lput outra-base conexoes
  ]
  ask links with [end2 = base-pesquisa] [
    let outra-base [base-sigla] of end1
    set conexoes lput outra-base conexoes
  ]
  report conexoes
end


@#$#@#$#@
GRAPHICS-WINDOW
447
10
1427
691
-1
-1
12.0
1
10
1
1
1
0
0
0
1
0
80
0
55
0
0
1
ticks
30.0

BUTTON
13
280
76
313
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
85
281
148
314
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
78
148
157
205
Impactos
count impactos
17
1
14

MONITOR
332
146
434
203
Emergencias
emergencias-total-existentes
0
1
14

PLOT
15
474
420
716
Evento Severo
tempo
emergencia
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count emergencias"
"pen-1" 1.0 0 -13791810 true "" "plot count impactos"
"pen-2" 1.0 0 -14439633 true "" "plot emergencias-total-executadas"

MONITOR
17
338
119
387
Eme Executadas
emergencias-total-executadas
0
1
12

CHOOSER
10
219
190
264
contingencia-modo-apoio
contingencia-modo-apoio
"Tradicional" "Isolado" "ApoioVizinho" "ApoioVizinhoAjuda" "ApoioVizinhoAjudaExtra" "ApoioVizinhoAjudaFB" "Proximidade" "Completo"
1

MONITOR
237
339
338
388
CHI
emergencias-consumidor-hora-interrompidos
0
1
12

MONITOR
144
400
256
453
Equipes Horas
equipes-total-horas / 60
2
1
13

MONITOR
303
269
435
326
Contingencia Horas
contingencia-duracao / 60
1
1
14

MONITOR
11
148
69
205
Bases
count bases
0
1
14

MONITOR
256
145
323
202
Equipes
count equipes
0
1
14

MONITOR
265
401
352
454
Equipe R$
equipes-custo-hora-total
0
1
13

MONITOR
124
339
231
388
Clientes Afetados
emergencias-quantidade-consumidores-afetados
0
1
12

MONITOR
12
399
138
452
Equipes disponiveis
count equipes with [equipe-disponivel? = true]
17
1
13

SLIDER
237
10
434
43
emergencia-execucao-minutos
emergencia-execucao-minutos
10
120
60.0
5
1
NIL
HORIZONTAL

SLIDER
238
56
436
89
emergencias-consumidores
emergencias-consumidores
50
300
100.0
50
1
NIL
HORIZONTAL

SLIDER
238
99
436
132
equipe-turno-horas
equipe-turno-horas
8
50
50.0
1
1
NIL
HORIZONTAL

SLIDER
11
10
218
43
equipes-quantidade-padrao
equipes-quantidade-padrao
1
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
13
100
219
133
equipes-custo-hora-padrao
equipes-custo-hora-padrao
50
150
80.0
10
1
R$
HORIZONTAL

SLIDER
13
57
218
90
equipes-sobrecarga-emergencias
equipes-sobrecarga-emergencias
1
10
4.0
1
1
NIL
HORIZONTAL

MONITOR
347
339
436
388
kW/h R$
emergencias-kilowatthora-reais
2
1
12

SLIDER
219
226
434
259
contingencia-equipes-apoiando
contingencia-equipes-apoiando
0
10
3.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
