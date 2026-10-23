/* Linha do tempo interativa — profzabot.com.br
   Sem dependências. Sem JS a página continua legível: o trilho rola e
   "como se mediu" abre no próprio cartão. */
(function () {
  'use strict';

  var raiz = document.documentElement;
  function medeLargura() {
    // largura útil sem a barra de rolagem vertical, para o bloco de largura total
    raiz.style.setProperty('--ldt-vw', raiz.clientWidth + 'px');
  }
  medeLargura();
  window.addEventListener('resize', medeLargura);

  var suave = window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth';
  var celular = window.matchMedia('(max-width: 719px)');
  var SVG = 'http://www.w3.org/2000/svg';

  document.querySelectorAll('.ldt').forEach(iniciar);

  function iniciar(ldt) {
    var trilho = ldt.querySelector('.ldt-trilho');
    var grade = ldt.querySelector('.ldt-grade');
    var svg = ldt.querySelector('.ldt-arcos');
    var evs = Array.prototype.slice.call(ldt.querySelectorAll('.ldt-ev'));
    var pontos = Array.prototype.slice.call(ldt.querySelectorAll('.ldt-ponto'));
    var dialogo = ldt.querySelector('.ldt-dialogo');
    var corpo = ldt.querySelector('.ldt-dialogo-corpo');
    var porId = {};
    evs.forEach(function (e) { porId[e.id] = e; e.classList.add('ativo'); });
    var pontoDe = {};
    pontos.forEach(function (p) { pontoDe[p.dataset.alvo] = p; });

    /* ---------- navegação ---------- */
    function margem() { return parseFloat(getComputedStyle(grade).paddingLeft) || 16; }

    function irPara(id, destacar) {
      var el = porId[id];
      if (!el) return false;
      if (el.offsetParent === null && ldt.dataset.filtro) filtrar('');   // escondido pelo filtro
      trilho.scrollTo({ left: el.offsetLeft - margem(), behavior: suave });
      if (destacar) {
        evs.forEach(function (e) { e.classList.remove('alvo'); });
        el.classList.add('alvo');
        setTimeout(function () { el.classList.remove('alvo'); }, 2200);
      }
      return true;
    }

    ldt.querySelectorAll('.ldt-seta').forEach(function (b) {
      b.addEventListener('click', function () {
        var passo = Math.max(trilho.clientWidth * 0.85, 300);
        trilho.scrollBy({ left: passo * Number(b.dataset.dir), behavior: suave });
      });
    });

    pontos.forEach(function (p) {
      p.addEventListener('click', function () { irPara(p.dataset.alvo, true); });
    });

    // links internos (ano, previsão, confirmação): rolam o trilho sem pular a página
    ldt.addEventListener('click', function (ev) {
      var a = ev.target.closest('a[href^="#"]');
      if (!a || !ldt.contains(a)) return;
      var id = decodeURIComponent(a.getAttribute('href').slice(1));
      if (!porId[id]) return;
      ev.preventDefault();
      history.replaceState(null, '', '#' + id);
      irPara(id, true);
    });

    function pelaUrl() {
      var id = decodeURIComponent(location.hash.slice(1));
      if (!porId[id]) return;
      ldt.scrollIntoView({ block: 'start' });
      // espera o layout das figuras antes de posicionar o trilho
      requestAnimationFrame(function () { irPara(id, true); });
    }
    window.addEventListener('hashchange', pelaUrl);
    if (document.readyState === 'complete') pelaUrl();
    else window.addEventListener('load', pelaUrl);

    /* ---------- arrastar com o mouse ---------- */
    var arr = null, suprimeClique = false;
    trilho.addEventListener('pointerdown', function (ev) {
      if (ev.pointerType !== 'mouse' || ev.button !== 0) return;
      if (ev.target.closest('button, summary, a, input, .ldt-mais-corpo')) return;
      arr = { x: ev.clientX, s: trilho.scrollLeft, moveu: false };
    });
    window.addEventListener('pointermove', function (ev) {
      if (!arr) return;
      var dx = ev.clientX - arr.x;
      if (!arr.moveu && Math.abs(dx) > 5) { arr.moveu = true; ldt.classList.add('arrastando'); }
      if (arr.moveu) { trilho.scrollLeft = arr.s - dx; ev.preventDefault(); }
    });
    window.addEventListener('pointerup', function () {
      if (arr && arr.moveu) {
        ldt.classList.remove('arrastando');
        suprimeClique = true;
        setTimeout(function () { suprimeClique = false; }, 0);
      }
      arr = null;
    });
    trilho.addEventListener('click', function (ev) {
      if (suprimeClique) { ev.preventDefault(); ev.stopPropagation(); }
    }, true);

    /* ---------- filtros por família ---------- */
    var botoes = Array.prototype.slice.call(ldt.querySelectorAll('.ldt-filtro'));
    function filtrar(fam) {
      botoes.forEach(function (b) { b.setAttribute('aria-pressed', String(b.dataset.familia === fam)); });
      if (fam) ldt.dataset.filtro = fam; else delete ldt.dataset.filtro;
      evs.forEach(function (e) {
        var fs = (e.dataset.familias || '').split(' ');
        var ok = !fam || e.classList.contains('ldt-fim') || fs.indexOf(fam) >= 0;
        e.classList.toggle('ativo', ok);
        if (pontoDe[e.id]) pontoDe[e.id].classList.toggle('apagado', !ok);
      });
      desenharArcos();
      if (celular.matches) trilho.scrollTo({ left: 0 });
      else {
        var primeiro = evs.filter(function (e) { return e.classList.contains('ativo'); })[0];
        if (primeiro && fam) irPara(primeiro.id, false);
      }
    }
    botoes.forEach(function (b) {
      b.addEventListener('click', function () { filtrar(b.dataset.familia); });
    });

    /* ---------- arcos da previsão à observação ---------- */
    function desenharArcos() {
      while (svg.firstChild) svg.removeChild(svg.firstChild);
      if (celular.matches) return;
      var faixa = parseFloat(getComputedStyle(ldt).getPropertyValue('--arcos')) || 68;
      var base = faixa + 7;            // topo dos marcadores
      svg.setAttribute('width', grade.scrollWidth);
      svg.setAttribute('height', base + 2);
      var xs = {};
      evs.forEach(function (e) { xs[e.id] = e.offsetLeft + 9; });

      evs.forEach(function (t) {
        if (!t.dataset.confirma) return;
        var falsas = (t.dataset.falsa || '').split(' ');
        t.dataset.confirma.split(' ').forEach(function (id) {
          var alvo = porId[id];
          if (!alvo) return;
          var x1 = xs[t.id], x2 = xs[id], falsa = falsas.indexOf(id) >= 0;
          var h = Math.min(faixa - 22, 16 + (x2 - x1) / 60);
          var meio = (x1 + x2) / 2;
          var apagado = !(t.classList.contains('ativo') && alvo.classList.contains('ativo'));
          var cls = (falsa ? 'falsa' : '') + (apagado ? ' apagado' : '');

          var p = document.createElementNS(SVG, 'path');
          p.setAttribute('d', 'M' + x1 + ' ' + base + ' Q ' + meio + ' ' + (base - 2 * h) + ' ' + x2 + ' ' + base);
          p.setAttribute('class', cls);
          svg.appendChild(p);

          // rótulo: no meio dos arcos curtos; nos longos, perto das duas pontas,
          // para que seja lido junto da previsão e junto da observação
          var anos = Number(alvo.dataset.ano) - Number(t.dataset.ano);
          var rotulo = falsa ? 'engano' : (anos + (anos === 1 ? ' ano' : ' anos'));
          var dx = x2 - x1;
          var ts = dx <= 700 ? [0.5] : [150 / dx, 1 - 150 / dx];
          ts.forEach(function (u) {
            var tx = document.createElementNS(SVG, 'text');
            tx.setAttribute('x', x1 + dx * u);
            tx.setAttribute('y', base - 4 * h * u * (1 - u) - 6);
            tx.setAttribute('class', cls);
            tx.textContent = rotulo;
            svg.appendChild(tx);
          });
        });
      });
    }
    var espera;
    function redesenhar() { clearTimeout(espera); espera = setTimeout(desenharArcos, 120); }
    window.addEventListener('resize', redesenhar);
    if (celular.addEventListener) celular.addEventListener('change', redesenhar);
    if (document.fonts && document.fonts.ready) document.fonts.ready.then(desenharArcos);
    desenharArcos();

    /* ---------- régua: marca o que está à vista ---------- */
    if ('IntersectionObserver' in window) {
      var io = new IntersectionObserver(function (entradas) {
        entradas.forEach(function (en) {
          var p = pontoDe[en.target.id];
          if (p) p.classList.toggle('visivel', en.isIntersecting);
        });
      }, { root: trilho, threshold: 0.6 });
      evs.forEach(function (e) { io.observe(e); });
    }

    /* ---------- diálogo: "como se mediu" e figura ampliada ---------- */
    function abrir(conteudo, imagem) {
      corpo.innerHTML = '';
      corpo.appendChild(conteudo);
      dialogo.classList.toggle('imagem', !!imagem);
      if (typeof dialogo.showModal === 'function') dialogo.showModal();
      else dialogo.setAttribute('open', '');
      dialogo.scrollTop = 0;
    }
    function fechar() {
      if (typeof dialogo.close === 'function') dialogo.close(); else dialogo.removeAttribute('open');
    }
    ldt.querySelector('.ldt-fechar').addEventListener('click', fechar);
    dialogo.addEventListener('click', function (ev) { if (ev.target === dialogo) fechar(); });

    ldt.querySelectorAll('.ldt-mais > summary').forEach(function (s) {
      s.addEventListener('click', function (ev) {
        if (typeof dialogo.showModal !== 'function') return;   // sem <dialog>, abre no cartão
        ev.preventDefault();
        var card = s.closest('.ldt-card');
        var frag = document.createDocumentFragment();
        var ano = card.querySelector('.ldt-ano').cloneNode(true);
        ano.removeAttribute('href');
        var rot = document.createElement('div');
        rot.className = 'ldt-rotulo';
        rot.textContent = s.textContent;
        var tit = document.createElement('h3');
        tit.textContent = card.querySelector('.ldt-tit').textContent;
        frag.appendChild(ano);
        frag.appendChild(tit);
        frag.appendChild(rot);
        frag.appendChild(s.nextElementSibling.cloneNode(true));
        dialogo.style.setProperty('--cor', getComputedStyle(card).getPropertyValue('--cor'));
        abrir(frag, false);
      });
    });

    ldt.querySelectorAll('.ldt-fig img').forEach(function (img) {
      img.addEventListener('click', function () {
        var fig = document.createElement('figure');
        fig.style.margin = '0';
        var g = document.createElement('img');
        g.src = img.dataset.grande || img.currentSrc || img.src;
        g.alt = img.alt;
        fig.appendChild(g);
        var cap = img.parentNode.querySelector('figcaption');
        if (cap) fig.appendChild(cap.cloneNode(true));
        abrir(fig, true);
      });
    });
  }
})();
