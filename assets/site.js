/* ============================================================
   MATHASILV's LAB — JS compartilhado
   Expõe window.Site com helpers usados pelas páginas.
   ============================================================ */
(function () {
  "use strict";

  function esc(s) {
    return String(s == null ? "" : s)
      .replace(/&/g, "\x26amp;")
      .replace(/</g, "\x26lt;")
      .replace(/>/g, "\x26gt;")
      .replace(/"/g, "\x26quot;")
      .replace(/'/g, "\x26#39;");
  }

  // Preenche os campos "last modified" e data do marquee, se existirem.
  function initFooterDates() {
    var lm = document.getElementById("last-mod");
    if (lm) lm.textContent = document.lastModified;
    var md = document.getElementById("marquee-date");
    if (md) md.textContent = new Date().toLocaleDateString().toUpperCase();
  }

  // Lightbox simples — procura por um #lightbox no DOM e registra handlers.
  // images com [data-lightbox] abrem nele quando clicadas.
  function initLightbox() {
    var lb = document.getElementById("lightbox");
    if (!lb) return;
    var lbImg = lb.querySelector("img");
    var lbInfo = lb.querySelector("#lightbox-info");

    function open(src, caption) {
      if (lbImg) lbImg.src = src;
      if (lbInfo) lbInfo.textContent = caption || "";
      lb.style.display = "flex";
    }
    function close() { lb.style.display = "none"; }

    window.Site = window.Site || {};
    window.Site.openLightbox = open;
    window.Site.closeLightbox = close;

    lb.addEventListener("click", close);
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape") close();
    });

    // Delegação: qualquer <img data-lightbox="caption"...> dispara o lightbox.
    document.addEventListener("click", function (e) {
      var t = e.target.closest("img[data-lightbox]");
      if (!t) return;
      e.preventDefault();
      open(t.src, t.getAttribute("data-lightbox") || t.alt || "");
    });
  }

  var Site = {
    esc: esc,
    initFooterDates: initFooterDates,
    initLightbox: initLightbox,
    init: function () {
      initFooterDates();
      initLightbox();
    }
  };

  window.Site = Site;
  if (document.readyState !== "loading") Site.init();
  else document.addEventListener("DOMContentLoaded", Site.init);
})();
